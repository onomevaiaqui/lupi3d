local cfg=require "config"
local level=require "level"
local colors=require "colors"
local gun=require "gun"
local renderer=require "renderer"
local geometry=require "geometry"
local sin,cos,abs,floor,ceil=math.sin,math.cos,math.abs,math.floor,math.ceil
local PI=math.pi
local horizon=124
Game={x=level.spawn.x,z=level.spawn.z,y=0,vy=0,yaw=0,pitch=0,grounded=true,phase=0,
    targets=level.targets,hits=0,shots=0,cooldown=0,flash=0,hit_flash=0,fps=cfg.fallback_fps,triangles=0}
local weapon={mesh=gun,x=0,y=0,z=0}
local flashMesh={mesh=gun.flash,x=0,y=0,z=0}
function Game.reset_targets()
    for _,t in ipairs(Game.targets) do t.alive=true end
    Game.hits,Game.shots,Game.cooldown,Game.flash,Game.hit_flash=0,0,0,0,0
end
local function held(key)
    if key==nil then return false end
    local v=ui.btn(key,0)
    return v==true or (type(v)=="number" and v>0)
end
function Game.shoot()
    if Game.cooldown>0.000001 then return 0 end
    Game.cooldown=cfg.shot_interval;Game.flash=0.085;Game.shots=Game.shots+1
    local cp=cos(Game.pitch)
    local dx,dy,dz=sin(Game.yaw)*cp,sin(Game.pitch),cos(Game.yaw)*cp
    local eye=Game.y+cfg.eye_height
    local nearest=level.ray(Game.x,eye,Game.z,dx,dy,dz)
    local best
    for _,t in ipairs(Game.targets) do if t.alive then
        local distance=geometry.rayBox(level.targetBox(t),Game.x,eye,Game.z,dx,dy,dz,nearest)
        if distance and distance<nearest then nearest=distance;best=t end
    end end
    if best then best.alive=false;Game.hits=Game.hits+1;Game.hit_flash=0.18;return best.id end
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
            if level.free(Game.x+dx/steps,Game.y,Game.z,0.18,cfg.player_height) then Game.x=Game.x+dx/steps end
            if level.free(Game.x,Game.y,Game.z+dz/steps,0.18,cfg.player_height) then Game.z=Game.z+dz/steps end
        end
        Game.y,Game.vy,Game.grounded=level.vertical(Game.x,Game.z,Game.y,Game.vy,subdt,0.18,cfg.player_height,cfg.gravity)
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

local function rect(x1,y1,x2,y2,color)
    ui.rectfill(x1,y1,x2,y2,colors.index[color])
end
function Game.draw()
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270)
    ui.cls(colors.index[1])
    renderer.begin(Game)
    renderer.submit(level.floor);renderer.flush()
    for _,obj in ipairs(level.objects) do renderer.submit(obj) end
    for _,target in ipairs(Game.targets) do if target.alive then renderer.submit(target) end end
    renderer.flush()
    weapon.x=Game.moving and sin(Game.phase)*0.003 or 0
    weapon.y=Game.flash>0 and -0.006 or 0
    weapon.z=Game.flash>0 and -0.025 or 0
    renderer.submit(weapon,true);renderer.flush()
    if Game.flash>0 then renderer.submit(flashMesh,true);renderer.flush() end
    Game.triangles,Game.dropped=renderer.triangles,renderer.dropped
    local cross=Game.hit_flash>0 and 14 or 15
    rect(234,horizon-1,239,horizon+1,cross);rect(242,horizon-1,247,horizon+1,cross)
    rect(239,horizon-6,242,horizon-2,cross);rect(239,horizon+3,242,horizon+7,cross)
    rect(0,0,480,20,10)
    ui.print("FPS 3D 1.2 / ESTANDE",10,6,colors.index[15])
    ui.print("TRI "..Game.triangles,285,6,colors.index[9])
    ui.print(Game.reported_fps and ("FPS "..floor(Game.reported_fps+0.5)) or "FPS --",390,6,colors.index[9])
    rect(0,228,480,270,10)
    ui.print("ALVOS "..Game.hits.."/"..#Game.targets.."   TIROS "..Game.shots,12,236,colors.index[15])
    if Game.hits==#Game.targets then ui.print("TODOS ACERTADOS! A: REARMAR",205,236,colors.index[14]) end
    ui.print("CRUZ: MOVER  L/R: VIRAR  B: PULAR  Y: ATIRAR  A: ALVOS",12,255,colors.index[9])
end
