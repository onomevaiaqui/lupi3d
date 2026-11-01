local cfg=require "config"
local colors=require "colors"
local track=require "track"
local renderer=require "renderer"
local sin,cos,abs=math.sin,math.cos,math.abs
Game={x=-3,z=-28,yaw=math.pi/2,speed=0,time=0,laps=0,checkpoint=3,best=nil,lap_start=0,finished=false,triangles=0}
local car={x=0,y=0,z=0,mesh=require "car"}
local camera={x=0,y=2.8,z=0,yaw=0,pitch=-0.30}
local frame=0
local function held(k) if k==nil then return false end local v=ui.btn(k,0);return v==true or type(v)=="number" and v>0 end
local function timestep()
    if frame%15==0 then
        Game.fps=cfg.fallback_fps;Game.reported_fps=nil
        if type(ui.stat)=="function" then local ok,f=pcall(ui.stat,7);if ok and type(f)=="number" and f==f and f>=5 and f<=240 then Game.fps=f;Game.reported_fps=f end end
    end
    frame=frame+1;return math.min(1/(Game.fps or cfg.fallback_fps),0.125)
end
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),0.125))
    local gas,brake=BTN_Z,BTN_G
    if cfg.controller=="lupinho" then brake=BTN_X end
    if Game.finished then Game.speed=math.max(0,Game.speed-cfg.brake*dt);return end
    Game.time=Game.time+dt
    local steps=math.max(1,math.ceil(dt*60));local h=dt/steps
    for _=1,steps do
        local r=track.radius(Game.x,Game.z)
        Game.offroad=r<track.inner or r>track.outer
        local accel=held(brake) and -cfg.brake or held(gas) and cfg.acceleration or -1.8
        if Game.offroad then accel=accel-5 end
        local cap=Game.offroad and 5 or cfg.top_speed
        Game.speed=math.max(0,math.min(cfg.top_speed,Game.speed+accel*h))
        if Game.speed>cap then Game.speed=math.max(cap,Game.speed-9*h) end
        local steer=(held(RIGHT) and 1 or 0)-(held(LEFT) and 1 or 0)
        Game.yaw=(Game.yaw+steer*cfg.steering*math.min(Game.speed/5,1)*h+math.pi)%(2*math.pi)-math.pi
        Game.x=Game.x+sin(Game.yaw)*Game.speed*h;Game.z=Game.z+cos(Game.yaw)*Game.speed*h
        if abs(Game.x)>45 or abs(Game.z)>50 then Game.x=math.max(-45,math.min(45,Game.x));Game.z=math.max(-50,math.min(50,Game.z));Game.speed=0 end
        local sector=math.floor(track.phase(Game.x,Game.z)/(math.pi/2))
        if not Game.offroad then
            if sector==Game.checkpoint+1 and sector<=3 then Game.checkpoint=sector
            elseif sector==0 and Game.checkpoint==3 then
                if Game.started then
                    Game.laps=Game.laps+1;local lap=Game.time-Game.lap_start
                    Game.best=Game.best and math.min(Game.best,lap) or lap
                    if Game.laps>=3 then Game.finished=true end
                end
                Game.started=true;Game.lap_start=Game.time;Game.checkpoint=0
            end
        end
    end
end
local function text(s,x,y,c) ui.print(s,x,y,colors.index[c]) end
function Game.draw()
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270);ui.cls(colors.index[1])
    camera.x=Game.x-sin(Game.yaw)*4.8;camera.z=Game.z-cos(Game.yaw)*4.8;camera.yaw=Game.yaw
    car.x,car.z,car.yaw=Game.x,Game.z,Game.yaw
    renderer.begin(camera)
    renderer.submit(track.ground);renderer.flush()
    renderer.submit(track.road);renderer.flush()
    renderer.submit(track.finish);renderer.flush()
    renderer.submit(car);renderer.flush()
    Game.triangles,Game.dropped=renderer.triangles,renderer.dropped
    ui.rectfill(0,0,480,20,colors.index[10]);ui.rectfill(0,228,480,270,colors.index[10])
    text("OVAL 3D 2.1 / FUSQUINHA",10,6,15)
    text("TRI "..Game.triangles,285,6,9);text(Game.reported_fps and "FPS "..math.floor(Game.reported_fps+0.5) or "FPS --",390,6,9)
    text(string.format("%03d KM/H   VOLTAS %d/3   TEMPO %.1f",math.floor(Game.speed*6+0.5),Game.laps,Game.time),12,235,15)
    text("B: ACELERA  A: FREIA  ESQUERDA/DIREITA: VIRA",12,255,9)
    if Game.finished then text("CHEGADA!",205,100,15)
    elseif Game.offroad then text("GRAMA",215,210,8) end
end
