local cfg=require "config"
local level=require "level"
local colors=require "colors"
local gun=require "gun"
local sin,cos,abs,floor,ceil,sqrt=math.sin,math.cos,math.abs,math.floor,math.ceil,math.sqrt
local PI=math.pi
local columns=cfg.columns
assert(columns>=24 and columns<=160 and 480%columns==0,"columns must divide 480")
local strip=480/columns
local projection=240/cfg.camera_plane
local horizon=124
local wallDepth,views,ordered={},{},{}
Game={x=level.spawn.x,z=level.spawn.z,y=0,vy=0,yaw=0,grounded=true,phase=0,
    targets={},hits=0,shots=0,cooldown=0,flash=0,hit_flash=0,fps=cfg.fallback_fps,draw_calls=0}
for i,p in ipairs(level.targets) do
    Game.targets[i]={x=p[1],z=p[2],radius=0.42,alive=true,id=i}
    views[i]={target=Game.targets[i]}
end
local sprite
if colors.native and type(ui.spr)=="function" then
    local ok=pcall(require,"sprites")
    if ok and Sprites and Sprites.img and Sprites.img.gun then
        local candidate=Sprites.img.gun
        if candidate.width==72 and candidate.height==96 then sprite=candidate end
    end
end
Game.native_weapon=sprite~=nil
local function held(key)
    if key==nil then return false end
    local v=ui.btn(key,0)
    return v==true or (type(v)=="number" and v>0)
end
-- Bounded DDA through a small grid. Returns distance along the supplied ray.
function Game.raycast(x,z,dx,dz)
    if abs(dx)+abs(dz)<0.000001 then return 99,1,0,0 end
    local mx,mz=floor(x),floor(z)
    if level.cell(mx,mz)>0 then return 0.05,1,0,0 end
    local deltaX=abs(dx)>0.000001 and abs(1/dx) or 1e12
    local deltaZ=abs(dz)>0.000001 and abs(1/dz) or 1e12
    local stepX,stepZ=dx<0 and -1 or 1,dz<0 and -1 or 1
    local sideX=(dx<0 and x-mx or mx+1-x)*deltaX
    local sideZ=(dz<0 and z-mz or mz+1-z)*deltaZ
    for _=1,level.width+level.height+4 do
        local distance,side
        if sideX<sideZ then mx=mx+stepX;distance=sideX;sideX=sideX+deltaX;side=0
        else mz=mz+stepZ;distance=sideZ;sideZ=sideZ+deltaZ;side=1 end
        local wall=level.cell(mx,mz)
        if wall>0 then
            local coordinate=side==0 and z+distance*dz or x+distance*dx
            return math.max(distance,0.05),wall,side,coordinate-floor(coordinate)
        end
    end
    return 99,1,0,0
end
function Game.reset_targets()
    for _,t in ipairs(Game.targets) do t.alive=true end
    Game.hits,Game.shots,Game.cooldown,Game.flash,Game.hit_flash=0,0,0,0,0
end
function Game.shoot()
    if Game.cooldown>0.000001 then return 0 end
    Game.cooldown=cfg.shot_interval;Game.flash=0.085;Game.shots=Game.shots+1
    local dx,dz=sin(Game.yaw),cos(Game.yaw)
    local limit=Game.raycast(Game.x,Game.z,dx,dz)
    local best,nearest=nil,limit
    for _,t in ipairs(Game.targets) do if t.alive then
        local tx,tz=t.x-Game.x,t.z-Game.z
        local along=tx*dx+tz*dz
        local across=tx*dz-tz*dx
        if along>0 and abs(across)<=t.radius then
            local entry=along-sqrt(t.radius*t.radius-across*across)
            if entry>0 and entry<nearest then nearest=entry;best=t end
        end
    end end
    if best then
        best.alive=false;Game.hits=Game.hits+1;Game.hit_flash=0.18
        return best.id
    end
    return 0
end
local frame=0
local jumpHeld,resetHeld=false,false
local function timestep()
    if frame%15==0 then
        Game.fps=cfg.fallback_fps;Game.reported_fps=nil
        if type(ui.stat)=="function" then
            local ok,fps=pcall(ui.stat,7)
            if ok and type(fps)=="number" and fps==fps and fps>=5 and fps<=240 then
                Game.fps=fps;Game.reported_fps=fps
            end
        end
    end
    frame=frame+1
    return math.min(1/Game.fps,1/8)
end
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),1/8))
    local l,r,shootKey,resetKey=BTN_Q,BTN_E,BTN_F,BTN_G
    if cfg.controller=="lupinho" then l,r,shootKey,resetKey=BTN_F,BTN_G,BTN_Q,BTN_X end
    local turn=(held(r) and 1 or 0)-(held(l) and 1 or 0)
    Game.yaw=Game.yaw+turn*cfg.camera_speed*dt
    if Game.yaw>=PI then Game.yaw=Game.yaw-2*PI elseif Game.yaw< -PI then Game.yaw=Game.yaw+2*PI end
    local jump=held(BTN_Z)
    if jump and not jumpHeld and Game.grounded then Game.vy=cfg.jump_speed;Game.grounded=false end
    jumpHeld=jump
    local forward=(held(UP) and 1 or 0)-(held(DOWN) and 1 or 0)
    local side=(held(RIGHT) and 1 or 0)-(held(LEFT) and 1 or 0)
    local norm=(forward~=0 and side~=0) and 0.70710678118655 or 1
    local sx,cz=sin(Game.yaw),cos(Game.yaw)
    local dx=(sx*forward+cz*side)*norm*cfg.speed*dt
    local dz=(cz*forward-sx*side)*norm*cfg.speed*dt
    local oldX,oldZ=Game.x,Game.z
    local steps=math.max(1,ceil(dt*60))
    local subdt=dt/steps
    for _=1,steps do
        if forward~=0 or side~=0 then
            if level.free(Game.x+dx/steps,Game.z,0.18) then Game.x=Game.x+dx/steps end
            if level.free(Game.x,Game.z+dz/steps,0.18) then Game.z=Game.z+dz/steps end
        end
        Game.y=Game.y+Game.vy*subdt-0.5*cfg.gravity*subdt*subdt
        Game.vy=Game.vy-cfg.gravity*subdt
        if Game.y<=0 and Game.vy<=0 then Game.y,Game.vy,Game.grounded=0,0,true else Game.grounded=false end
    end
    Game.moving=abs(Game.x-oldX)+abs(Game.z-oldZ)>0.00001
    if Game.moving then Game.phase=(Game.phase+12*dt)%(2*PI) else Game.phase=0 end
    Game.cooldown=math.max(0,Game.cooldown-dt)
    Game.flash=math.max(0,Game.flash-dt);Game.hit_flash=math.max(0,Game.hit_flash-dt)
    local reset=held(resetKey)
    if reset and not resetHeld then Game.reset_targets() end
    resetHeld=reset
    if held(shootKey) then Game.shoot() end
end
-- Native rectangles only. End coordinates are exclusive, as in ui.rectfill.
local function rect(x1,y1,x2,y2,color)
    x1=math.max(0,floor(x1));x2=math.min(480,ceil(x2))
    y1=math.max(20,floor(y1));y2=math.min(228,ceil(y2))
    if x2>x1 and y2>y1 then
        ui.rectfill(x1,y1,x2,y2,colors.index[color])
        Game.draw_calls=Game.draw_calls+1
    end
end
local function farther(a,b) return a.depth>b.depth end
local function drawTargets(fx,fz,rx,rz,eye)
    local n=0
    for i,t in ipairs(Game.targets) do if t.alive then
        local dx,dz=t.x-Game.x,t.z-Game.z
        local depth=dx*fx+dz*fz
        if depth>0.15 then
            local v=views[i]
            v.depth=depth;v.screen=240+(dx*rx+dz*rz)*projection/depth
            v.radius=0.42*projection/depth
            v.cy=horizon-(0.85-eye)*projection/depth
            if v.screen+v.radius>0 and v.screen-v.radius<480 then n=n+1;ordered[n]=v end
        end
    end end
    for i=#ordered,n+1,-1 do ordered[i]=nil end
    table.sort(ordered,farther)
    for _,v in ipairs(ordered) do
        local radius=v.radius
        local first=math.max(1,floor((v.screen-radius*1.06)/strip)+1)
        local last=math.min(columns,floor((v.screen+radius*1.06)/strip)+1)
        for i=first,last do
            if v.depth<wallDepth[i] then
                local x1=(i-1)*strip
                local x=(x1+strip/2-v.screen)/radius
                local ax=abs(x)
                if ax<1.06 then
                    local half=sqrt(1.06*1.06-x*x)*radius
                    rect(x1,v.cy-half,x1+strip,v.cy+half,10)
                end
                if ax<1 then
                    local half=sqrt(1-x*x)*radius
                    rect(x1,v.cy-half,x1+strip,v.cy+half,9)
                end
                if ax<0.7 then
                    local half=sqrt(0.49-x*x)*radius
                    rect(x1,v.cy-half,x1+strip,v.cy+half,7)
                end
                if ax<0.28 then
                    local half=sqrt(0.0784-x*x)*radius
                    rect(x1,v.cy-half,x1+strip,v.cy+half,8)
                end
                if ax<0.1 then rect(x1,v.cy+radius,x1+strip,horizon+eye*projection/v.depth,11) end
            end
        end
    end
end
local function drawWeapon()
    local bob=Game.moving and floor(sin(Game.phase)*2) or 0
    local recoil=Game.flash>0 and 4 or 0
    local x,y=217+bob,132+recoil
    if sprite then
        ui.spr(sprite,x,y,false);Game.draw_calls=Game.draw_calls+1
    else
        local r=gun.rects
        for i=1,#r,5 do rect(x+r[i]*3,y+r[i+1]*3,x+(r[i]+r[i+2])*3,y+(r[i+1]+r[i+3])*3,r[i+4]) end
    end
    if Game.flash>0 then
        rect(229+bob,118,251+bob,136,8)
        rect(235+bob,111,245+bob,140,15)
        rect(226+bob,123,254+bob,129,15)
    end
end
function Game.draw()
    Game.draw_calls=0
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270)
    ui.cls(colors.index[1])
    rect(0,horizon,480,228,2);rect(0,195,480,228,3)
    local fx,fz=sin(Game.yaw),cos(Game.yaw)
    local rx,rz=fz,-fx
    local eye=cfg.eye_height+Game.y
    for i=1,columns do
        local offset=(2*(i-0.5)/columns-1)*cfg.camera_plane
        local distance,wall,side,fraction=Game.raycast(Game.x,Game.z,fx+rx*offset,fz+rz*offset)
        wallDepth[i]=distance
        local top=horizon-(cfg.wall_height-eye)*projection/distance
        local bottom=horizon+eye*projection/distance
        local color=wall==2 and 13 or wall==3 and 6 or 5
        if side==0 or distance>7 then color=color+16 end
        if fraction<0.06 or fraction>0.94 then color=10 end
        rect((i-1)*strip,top,i*strip,bottom,color)
    end
    drawTargets(fx,fz,rx,rz,eye)
    drawWeapon()
    local cross=Game.hit_flash>0 and 14 or 15
    rect(234,horizon-1,239,horizon+1,cross);rect(242,horizon-1,247,horizon+1,cross)
    rect(239,horizon-6,242,horizon-2,cross);rect(239,horizon+3,242,horizon+7,cross)
    ui.rectfill(0,0,480,20,colors.index[10])
    ui.print("LUPI FPS 1.1 / ESTANDE",10,6,colors.index[15])
    ui.print(Game.reported_fps and ("FPS "..floor(Game.reported_fps+0.5)) or "FPS --",390,6,colors.index[9])
    ui.rectfill(0,228,480,270,colors.index[10])
    ui.print("ALVOS "..Game.hits.."/"..#Game.targets.."   TIROS "..Game.shots,12,236,colors.index[15])
    if Game.hits==#Game.targets then ui.print("TODOS ACERTADOS! A: REARMAR",205,236,colors.index[14]) end
    ui.print("CRUZ: MOVER  L/R: VIRAR  B: PULAR  Y: ATIRAR  A: ALVOS",12,255,colors.index[9])
end
