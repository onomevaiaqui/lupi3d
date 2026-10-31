local cfg = require "config"
local colors = require "colors"
local models = require "models"
local platform = require "platform"
local sin,cos,sqrt,floor = math.sin,math.cos,math.sqrt,math.floor
local characterFrames=cfg.cached_character and cfg.detail=="fast" and require "character_frames" or nil
local cacheX,cacheY,cacheZ
if characterFrames then cacheX,cacheY,cacheZ=characterFrames.xbase,characterFrames.ybase,characterFrames.zbase end
Game = {x=0,z=0,yaw=0,facing=0,phase=0,moving=false,triangles=0,dropped=0,culled=0}
Game.y,Game.vy,Game.grounded=0,0,true
Game.platform=platform
Game.profile_mode=0
local profileNames={"COMPLETO","CENARIO","PERSONAGEM","BASE"}
local objects,obstacles = {},{}
local function instance(mesh,x,z,scale,radius)
    local obj={mesh=mesh,x=x,z=z,scale=scale,px={},py={},pz={},sx={},sy={}}
    if mesh==models.tree then
        if cfg.detail=="fast" then obj.mesh=models.tree_far
        else obj.nearMesh=mesh; obj.farMesh=models.tree_far end
    elseif mesh==models.rock and cfg.detail=="fast" then obj.mesh=models.rock_fast end
    objects[#objects+1]=obj
    if radius then obstacles[#obstacles+1]={x=x,z=z,r=radius} end
    return obj
end
instance(models.tree,-4.8,4.2,0.9,0.55)
instance(models.tree,4.6,4.8,0.8,0.55)
instance(models.tree,-5.5,-3.8,0.85,0.55)
instance(models.tree,5.0,-4.2,0.75,0.55)
instance(models.rock,-2.5,1.8,1.5,0.7)
instance(models.rock,3.2,0.0,1.8,0.8)
instance(models.rock,1.2,5.8,1.3,0.6)
instance(platform.mesh,platform.x,platform.z,1)
local hero=instance(cfg.detail=="fast" and models.knight_fast or models.knight,0,0,0.65)
local ground={v={},f={}}
local zmin,zmax=cfg.detail=="fast" and 0 or -1,cfg.detail=="fast" and 0 or 1
for x=-1,1 do for z=zmin,zmax do
    local n=#ground.v/4
    local x0,z0=x*5-2.5,cfg.detail=="fast" and -7.5 or z*5-2.5
    local length=cfg.detail=="fast" and 15 or 5
    for _,p in ipairs({{x0,z0},{x0+5,z0},{x0+5,z0+length},{x0,z0+length}}) do
        ground.v[#ground.v+1]=p[1]; ground.v[#ground.v+1]=0
        ground.v[#ground.v+1]=p[2]; ground.v[#ground.v+1]=0
    end
    local c=x==0 and 4 or (2+(x+z)%2)
    for _,i in ipairs({n+1,n+3,n+2,c,n+1,n+4,n+3,c}) do ground.f[#ground.f+1]=i end
end end
local floorobj={mesh=ground,x=0,z=0,scale=1,px={},py={},pz={},sx={},sy={}}
local pool,list={},{}
for i=1,cfg.max_triangles do pool[i]={} end
local count=0
local function held(button)
    if button==nil then return false end
    local v=ui.btn(button,0)
    return v==true or (type(v)=="number" and v>0)
end
local function overPlatform(x,z)
    local dx=x-math.max(platform.xmin,math.min(x,platform.xmax))
    local dz=z-math.max(platform.zmin,math.min(z,platform.zmax))
    return dx*dx+dz*dz<0.23^2
end
local function free(x,z)
    if math.abs(x)>cfg.limit or math.abs(z)>cfg.limit then return false end
    for _,o in ipairs(obstacles) do
        if (x-o.x)^2+(z-o.z)^2<(o.r+0.23)^2 then return false end
    end
    if Game.y<platform.height-0.00001 and overPlatform(x,z) then return false end
    return true
end
local timingFrames=0
local profileHeld=false
local jumpHeld=false
Game.fps=cfg.fallback_fps
local function timestep()
    if timingFrames%15==0 then
        Game.fps=cfg.fallback_fps
        Game.reported_fps=nil
        if type(ui.stat)=="function" then
            local ok,fps=pcall(ui.stat,7)
            if ok and type(fps)=="number" and fps==fps and fps>=5 and fps<=240 then
                Game.fps=fps
                Game.reported_fps=fps
            end
        end
    end
    timingFrames=timingFrames+1
    return math.min(1/Game.fps,1/8)
end
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),1/8))
    local l,r,profileKey=BTN_Q,BTN_E,BTN_F
    if cfg.controller=="lupinho" then l,r,profileKey=BTN_F,BTN_G,BTN_Q end
    local profileButton=held(profileKey)
    if profileButton and not profileHeld then
        Game.profile_mode=(Game.profile_mode+1)%4
        Game.reported_fps=nil
        timingFrames=0
    end
    profileHeld=profileButton
    local jump=held(BTN_Z)
    if jump and not jumpHeld and Game.grounded then
        Game.vy=cfg.jump_speed
        Game.grounded=false
    end
    jumpHeld=jump
    local turn=(held(r) and 1 or 0)-(held(l) and 1 or 0)
    Game.yaw=(Game.yaw+turn*cfg.camera_speed*dt)%(math.pi*2)
    local forward=(held(UP) and 1 or 0)-(held(DOWN) and 1 or 0)
    local side=(held(RIGHT) and 1 or 0)-(held(LEFT) and 1 or 0)
    local len=sqrt(forward*forward+side*side)
    local ox,oz=Game.x,Game.z
    local dx,dz=0,0
    if len>0 then
        dx=(sin(Game.yaw)*forward+cos(Game.yaw)*side)/len*cfg.speed*dt
        dz=(cos(Game.yaw)*forward-sin(Game.yaw)*side)/len*cfg.speed*dt
        Game.facing=math.atan(dx,dz)
    end
    -- Movement and gravity share short substeps, including at low FPS.
    local steps=math.max(1,math.ceil(dt*60))
    local sx,sz,subdt=dx/steps,dz/steps,dt/steps
    for _=1,steps do
        if len>0 then
            if free(Game.x+sx,Game.z) then Game.x=Game.x+sx end
            if free(Game.x,Game.z+sz) then Game.z=Game.z+sz end
        end
        local oldY=Game.y
        -- Analytic displacement avoids jump-height drift between update rates.
        Game.y=Game.y+Game.vy*subdt-0.5*cfg.gravity*subdt*subdt
        Game.vy=Game.vy-cfg.gravity*subdt
        local support=0
        if oldY>=platform.height-0.00001 and overPlatform(Game.x,Game.z) then support=platform.height end
        if Game.vy<=0 and Game.y<=support then
            Game.y,Game.vy,Game.grounded=support,0,true
        else Game.grounded=false end
    end
    Game.moving=math.abs(Game.x-ox)+math.abs(Game.z-oz)>0.00001
    if Game.moving and Game.grounded then Game.phase=(Game.phase+8.4*cfg.speed/2.7*dt)%(math.pi*2) else Game.phase=0 end
end
local cy,sy,cx,cz
local cp,sp=cos(0.45),sin(0.45)
local limbSin,limbCos={},{}
local function project(obj)
    local v=obj.mesh.v
    -- Cancel shared vertical movement before adding local vertex coordinates.
    -- This keeps the cached character projection identical at every jump height.
    local offsetY=(obj.y or 0)-Game.y-3.55
    local cf,sf
    if obj==hero then cf,sf=cos(Game.facing),sin(Game.facing) end
    for i=1,#v,4 do
        local x,y,z=v[i],v[i+1],v[i+2]
        if obj==hero then
            local g=v[i+3]
            if g>0 then
                local pivot=g<=2 and 0.48 or 1.10
                local dy=y-pivot
                y=pivot+dy*limbCos[g]-z*limbSin[g]; z=dy*limbSin[g]+z*limbCos[g]
            end
            x,z=x*cf+z*sf,-x*sf+z*cf
        end
        x=x*obj.scale+obj.x-cx
        y=y*obj.scale+offsetY
        z=z*obj.scale+obj.z-cz
        local depth=x*sy+z*cy
        local k=(i+3)/4
        obj.px[k]=x*cy-z*sy
        obj.py[k]=y*cp+depth*sp
        obj.pz[k]=depth*cp-y*sp
        if obj.pz[k]>=0.25 then
            local scale=250/obj.pz[k]
            obj.sx[k]=240+obj.px[k]*scale
            obj.sy[k]=135-obj.py[k]*scale
        end
    end
end
local function store(ax,ay,bx,by,dx,dy,color,depth)
    if count>=cfg.max_triangles then Game.dropped=Game.dropped+1; return end
    -- Validate the actual integer geometry sent to the native rasterizer.
    -- A valid floating triangle may collapse or reverse winding after flooring.
    ax,ay,bx,by,dx,dy=floor(ax),floor(ay),floor(bx),floor(by),floor(dx),floor(dy)
    if ax<0 then ax=0 elseif ax>479 then ax=479 end
    if bx<0 then bx=0 elseif bx>479 then bx=479 end
    if dx<0 then dx=0 elseif dx>479 then dx=479 end
    if ay<20 then ay=20 elseif ay>246 then ay=246 end
    if by<20 then by=20 elseif by>246 then by=246 end
    if dy<20 then dy=20 elseif dy>246 then dy=246 end
    local area=(bx-ax)*(dy-ay)-(by-ay)*(dx-ax)
    if area==0 then return end
    if area<0 then bx,by,dx,dy=dx,dy,bx,by end
    count=count+1
    local t=pool[count]
    t[1],t[2],t[3],t[4],t[5],t[6]=ax,ay,bx,by,dx,dy
    t[7],t[8]=color,depth
    list[count]=t
end
-- The native rasterizer loops over off-screen pixels before rejecting them.
-- Clip to the visible world rectangle before calling ui.trisfill.
local screenX,screenY,outX,outY={},{},{},{}
local function queue(ax,ay,bx,by,dx,dy,color,depth)
    if (ax<0 and bx<0 and dx<0) or (ax>479 and bx>479 and dx>479)
        or (ay<20 and by<20 and dy<20) or (ay>246 and by>246 and dy>246) then return end
    if ax>=0 and ax<=479 and bx>=0 and bx<=479 and dx>=0 and dx<=479
        and ay>=20 and ay<=246 and by>=20 and by<=246 and dy>=20 and dy<=246 then
        store(ax,ay,bx,by,dx,dy,color,depth)
        return
    end
    screenX[1],screenY[1],screenX[2],screenY[2],screenX[3],screenY[3]=ax,ay,bx,by,dx,dy
    local n=3
    for edge=1,4 do
        local horizontal=edge<=2
        local boundary=edge==1 and 0 or edge==2 and 479 or edge==3 and 20 or 246
        local greater=edge==1 or edge==3
        local m=0
        local prev=n
        for i=1,n do
            local p=horizontal and screenX[prev] or screenY[prev]
            local q=horizontal and screenX[i] or screenY[i]
            local insideP=greater and p>=boundary or (not greater and p<=boundary)
            local insideQ=greater and q>=boundary or (not greater and q<=boundary)
            if insideP~=insideQ then
                local t=(boundary-p)/(q-p)
                m=m+1
                outX[m]=screenX[prev]+(screenX[i]-screenX[prev])*t
                outY[m]=screenY[prev]+(screenY[i]-screenY[prev])*t
                if horizontal then outX[m]=boundary else outY[m]=boundary end
            end
            if insideQ then m=m+1; outX[m]=screenX[i]; outY[m]=screenY[i] end
            prev=i
        end
        screenX,outX=outX,screenX; screenY,outY=outY,screenY
        n=m
        if n<3 then return end
    end
    for i=2,n-1 do
        store(screenX[1],screenY[1],screenX[i],screenY[i],screenX[i+1],screenY[i+1],color,depth)
    end
end
local function submit(ax,ay,az,bx,by,bz,dx,dy,dz,color)
    queue(240+ax*250/az,135-ay*250/az,240+bx*250/bz,135-by*250/bz,240+dx*250/dz,135-dy*250/dz,color,(az+bz+dz)/3)
end
-- Sutherland-Hodgman clipping against the near plane. Reused scratch arrays.
local ix,iy,iz,ox,oy,oz={},{},{},{},{},{}
local function emit(obj)
    local f=obj.mesh.f
    for i=1,#f,4 do
        local a,b,c=f[i],f[i+1],f[i+2]
        local ax,ay,az=obj.px[a],obj.py[a],obj.pz[a]
        local bx,by,bz=obj.px[b],obj.py[b],obj.pz[b]
        local cx,cy,cz=obj.px[c],obj.py[c],obj.pz[c]
        local ux,uy,uz=bx-ax,by-ay,bz-az
        local vx,vy,vz=cx-ax,cy-ay,cz-az
        local facing=(uy*vz-uz*vy)*ax+(uz*vx-ux*vz)*ay+(ux*vy-uy*vx)*az
        if facing>=0 then
            Game.culled=Game.culled+1
        elseif az>=0.25 and bz>=0.25 and cz>=0.25 then
            -- Usual path: perspective divide already done once per vertex.
            queue(obj.sx[a],obj.sy[a],obj.sx[b],obj.sy[b],obj.sx[c],obj.sy[c],f[i+3],(az+bz+cz)/3)
        elseif az>=0.25 or bz>=0.25 or cz>=0.25 then
            ix[1],iy[1],iz[1]=ax,ay,az
            ix[2],iy[2],iz[2]=bx,by,bz
            ix[3],iy[3],iz[3]=cx,cy,cz
            local n=0
            for k=1,3 do
                local prev=k==1 and 3 or k-1
                local a,b=iz[prev]>=0.25,iz[k]>=0.25
                if a~=b then
                    local t=(0.25-iz[prev])/(iz[k]-iz[prev])
                    n=n+1; ox[n]=ix[prev]+(ix[k]-ix[prev])*t; oy[n]=iy[prev]+(iy[k]-iy[prev])*t; oz[n]=0.25
                end
                if b then n=n+1; ox[n]=ix[k]; oy[n]=iy[k]; oz[n]=iz[k] end
            end
            local color=f[i+3]
            for k=2,n-1 do submit(ox[1],oy[1],oz[1],ox[k],oy[k],oz[k],ox[k+1],oy[k+1],oz[k+1],color) end
        end
    end
end
local function farfirst(a,b) return a[8]>b[8] end
local function flush(packed)
    for i=#list,count+1,-1 do list[i]=nil end
    table.sort(list,farfirst)
    -- Merge the already sorted character with the sorted world, preserving occlusion.
    local cursor=1
    local a,b,c,d,e,f,color,z
    local size=packed and #packed or 0
    if size>0 then
        a,b,c,d,e,f,color,z=string.byte(packed,1,8)
        z=z+cacheZ
        cursor=9
    end
    for i=1,count do
        local t=list[i]
        while z and z>=t[8]*32 do
            ui.trisfill(a+cacheX,b+cacheY,c+cacheX,d+cacheY,e+cacheX,f+cacheY,color)
            if cursor<=size then
                a,b,c,d,e,f,color,z=string.byte(packed,cursor,cursor+7)
                z=z+cacheZ
                cursor=cursor+8
            else z=nil end
        end
        if Game.capture_triangle then Game.capture_triangle(t) end
        ui.trisfill(t[1],t[2],t[3],t[4],t[5],t[6],t[7])
    end
    while z do
        ui.trisfill(a+cacheX,b+cacheY,c+cacheX,d+cacheY,e+cacheX,f+cacheY,color)
        if cursor<=size then
            a,b,c,d,e,f,color,z=string.byte(packed,cursor,cursor+7)
            z=z+cacheZ
            cursor=cursor+8
        else z=nil end
    end
    Game.triangles=Game.triangles+count
    if packed then Game.triangles=Game.triangles+floor(#packed/8) end
    count=0
end
function Game.draw()
    Game.triangles,Game.dropped,Game.culled=0,0,0
    for i=1,#colors do ui.palset(i-1,colors[i]) end
    ui.camera(0,0); ui.clip(0,0,480,270); ui.cls(1)
    if Game.profile_mode<2 then ui.rectfill(0,135,480,270,2) end
    cy,sy=cos(Game.yaw),sin(Game.yaw)
    if not characterFrames and (Game.profile_mode==0 or Game.profile_mode==2) then
        local angle=sin(Game.phase)*0.32
        local sa,ca=sin(angle),cos(angle)
        limbSin[1],limbSin[2],limbSin[3],limbSin[4]=sa,-sa,-sa,sa
        for g=1,4 do limbCos[g]=ca end
    end
    cx,cz=Game.x-sy*5.5,Game.z-cy*5.5
    hero.x,hero.y,hero.z=Game.x,Game.y,Game.z
    -- Ground first: avoids average-depth sorting a large floor over a foot.
    if Game.profile_mode<2 then project(floorobj); emit(floorobj); flush() end
    local packed
    if characterFrames and (Game.profile_mode==0 or Game.profile_mode==2) then
        local angle=(Game.facing-Game.yaw)%(math.pi*2)
        local direction=floor(angle*characterFrames.angles/(math.pi*2)+0.5)%characterFrames.angles
        local pose=floor(Game.phase*characterFrames.poses/(math.pi*2)+0.5)%characterFrames.poses
        packed=characterFrames.data[characterFrames.lookup[direction*characterFrames.poses+pose+1]]
    end
    for _,obj in ipairs(objects) do
        if (obj==hero and not packed and (Game.profile_mode==0 or Game.profile_mode==2)) or (obj~=hero and Game.profile_mode<2) then
        if obj.farMesh then
            local distance2=(obj.x-cx)^2+(obj.z-cz)^2
            if distance2>8.5^2 then obj.mesh=obj.farMesh
            elseif distance2<7.5^2 then obj.mesh=obj.nearMesh end
        end
        project(obj); emit(obj)
        end
    end
    flush(packed)
    ui.rectfill(0,0,480,20,11)
    ui.print("LUPI 3D / "..profileNames[Game.profile_mode+1],10,6,15)
    ui.print("TRI "..Game.triangles,280,6,15)
    if cfg.show_stats then
        ui.print(Game.reported_fps and ("FPS "..floor(Game.reported_fps+0.5)) or "FPS --",380,6,15)
    end
    ui.rectfill(0,247,480,270,11)
    ui.print("CRUZ: ANDAR  L/R: CAMERA  B: PULAR  Y: PERFIL",10,254,15)
end
