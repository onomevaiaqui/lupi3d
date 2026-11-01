local cfg=require "config"
local colors=require "colors"
local track=require "track"
local renderer=require "renderer"
local mesh=require "car"
local sin,cos=math.sin,math.cos
local x,z,yaw=track.sample(track.segments-0.35)
Game={x=x,z=z,yaw=yaw,speed=0,time=0,laps=0,checkpoint=3,best=nil,lap_start=0,finished=false,triangles=0,progress=track.segments-0.35}
Game.rival={progress=0.6,laps=0,speed=10.5,x=0,y=0,z=0,mesh=mesh.rival,radius=2.5}
local car={x=0,y=0,z=0,mesh=mesh}
local camera={x=0,y=3.3,z=0,yaw=0,pitch=-0.30}
local frame=0
local restartHeld=false
local function held(k) if k==nil then return false end local v=ui.btn(k,0);return v==true or type(v)=="number" and v>0 end
local function timestep()
    if frame%15==0 then
        Game.fps=cfg.fallback_fps;Game.reported_fps=nil
        if type(ui.stat)=="function" then local ok,f=pcall(ui.stat,7);if ok and type(f)=="number" and f==f and f>=5 and f<=240 then Game.fps=f;Game.reported_fps=f end end
    end
    frame=frame+1;return math.min(1/(Game.fps or cfg.fallback_fps),0.125)
end
local function rivalStep(dt)
    local r=Game.rival
    local _,_,_,length=track.sample(r.progress)
    r.progress=r.progress+r.speed*dt/length
    r.x,r.z,r.yaw=track.sample(r.progress)
    r.laps=math.max(0,math.floor(r.progress/track.segments))
end
rivalStep(0)
function Game.reset()
    Game.progress=track.segments-0.35
    Game.x,Game.z,Game.yaw=track.sample(Game.progress)
    Game.speed,Game.time,Game.laps,Game.checkpoint,Game.lap_start=0,0,0,3,0
    Game.started,Game.finished,Game.best,Game.offroad=false,false,nil,false
    Game.countdown=3
    Game.rival.progress,Game.rival.laps=0.6,0
    rivalStep(0)
end
Game.reset()
function Game.step(dt)
    dt=math.max(0,math.min(dt or timestep(),0.125))
    local restartKey=BTN_F
    if cfg.controller=="lupinho" then restartKey=BTN_Q end
    local restart=held(restartKey)
    if restart and not restartHeld then Game.reset();restartHeld=true;return end
    restartHeld=restart
    if Game.countdown>0 then
        Game.countdown=math.max(0,Game.countdown-dt)
        return
    end
    local gas,brake=BTN_Z,BTN_G
    if cfg.controller=="lupinho" then brake=BTN_X end
    if Game.finished then Game.speed=math.max(0,Game.speed-cfg.brake*dt);return end
    Game.time=Game.time+dt
    local steps=math.max(1,math.ceil(dt*60));local h=dt/steps
    for _=1,steps do
        local progress,distance=track.locate(Game.x,Game.z,Game.progress)
        Game.progress=progress;Game.offroad=distance>track.halfWidth^2
        local accel=held(brake) and -cfg.brake or held(gas) and cfg.acceleration or -1.8
        if Game.offroad then accel=accel-5 end
        local cap=Game.offroad and 5 or cfg.top_speed
        Game.speed=math.max(0,math.min(cfg.top_speed,Game.speed+accel*h))
        if Game.speed>cap then Game.speed=math.max(cap,Game.speed-9*h) end
        local steer=(held(RIGHT) and 1 or 0)-(held(LEFT) and 1 or 0)
        Game.yaw=(Game.yaw+steer*cfg.steering*math.min(Game.speed/5,1)*h+math.pi)%(2*math.pi)-math.pi
        Game.x=Game.x+sin(Game.yaw)*Game.speed*h;Game.z=Game.z+cos(Game.yaw)*Game.speed*h
        if math.abs(Game.x)>50 or math.abs(Game.z)>45 then Game.x=math.max(-50,math.min(50,Game.x));Game.z=math.max(-45,math.min(45,Game.z));Game.speed=0 end
        local sector=math.floor(progress/(track.segments/4))
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
        rivalStep(h)
    end
end
local function text(s,x,y,c) ui.print(s,x,y,colors.index[c]) end
function Game.draw()
    colors.register();ui.camera(0,0);ui.clip(0,0,480,270);ui.cls(colors.index[1])
    -- Flat ground to the fixed chase-camera horizon: replace two huge raster triangles.
    ui.rectfill(0,31,480,228,colors.index[14])
    camera.x=Game.x-sin(Game.yaw)*6.4;camera.z=Game.z-cos(Game.yaw)*6.4;camera.yaw=Game.yaw
    car.x,car.z,car.yaw=Game.x,Game.z,Game.yaw
    renderer.begin(camera)
    for _,part in ipairs(track.parts) do
        renderer.submit(part)
        local dx,dz=part.x-Game.x,part.z-Game.z
        if dx*dx+dz*dz<400 then renderer.submit(part.trim) end
    end
    renderer.flush()
    renderer.submit(track.finish);renderer.flush()
    for _,tree in ipairs(track.trees) do renderer.submit(tree) end
    renderer.submit(Game.rival);renderer.submit(car);renderer.flush()
    Game.triangles,Game.dropped=renderer.triangles,renderer.dropped
    ui.rectfill(0,0,480,20,colors.index[10]);ui.rectfill(0,228,480,270,colors.index[10])
    text("PISTA 8 3D 3.1 / FUSQUINHA",10,6,15)
    text("TRI "..Game.triangles,285,6,9);text(Game.reported_fps and "FPS "..math.floor(Game.reported_fps+0.5) or "FPS --",390,6,9)
    local playerProgress=(Game.started and Game.laps*track.segments or -track.segments)+Game.progress
    local position=playerProgress>=Game.rival.progress and 1 or 2
    text(string.format("%03d KM/H  VOLTA %d/3  POS %d/2  %.1f S",math.floor(Game.speed*6+0.5),Game.laps,position,Game.time),12,235,15)
    text("B: GAS  A: FREIO  CRUZ: VIRA  Y: REINICIA",12,255,9)
    if Game.countdown>0 or Game.time<1 then
        ui.rectfill(190,44,290,72,colors.index[10])
        local stage=Game.countdown>1 and 1 or Game.countdown>0 and 2 or 3
        for i,c in ipairs({7,8,14}) do
            ui.rectfill(198+(i-1)*30,50,220+(i-1)*30,66,colors.index[stage==i and c or c+16])
        end
        text(stage==3 and "JA!" or stage==2 and "ATENCAO" or "PREPARE",213,78,15)
    end
    if Game.finished then text("CHEGADA!",205,100,15)
    elseif Game.offroad then text("GRAMA",215,210,8) end
end
