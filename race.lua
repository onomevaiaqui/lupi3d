local cfg=require "config"
local tracks=require "track"
local mesh=require "car"
local combat=require "combat"
local audio=require "audio"
local Race={}
local enemyMeshes={}
for i,color in ipairs({7,6,14}) do
    local m={v=mesh.rival.v,f={}}
    for j,n in ipairs(mesh.rival.f) do
        if j%4==0 then if n==7 then n=color elseif n==23 then n=color+16 end end
        m.f[j]=n
    end
    enemyMeshes[i]=m
end
function Race.new(id)
    local track=tracks.new(id)
    local r={track=track,id=id,cars={},time=0,countdown=3,finished=false,place=0}
    for i=1,4 do
        local progress=i==1 and track.segments-0.35 or 0.2+(i-2)*0.6
        local x,z,yaw=track.sample(progress)
        r.cars[i]={player=i==1,x=x,y=0,z=z,yaw=yaw,speed=0,progress=progress,laps=0,
            started=i~=1,checkpoint=3,done=false,mesh=i==1 and mesh or enemyMeshes[i-1],radius=2,
            hp=100,respawn=0,stun=0,nitro=0,cooldown=0,ammo=0,weapon=nil,
            total=i==1 and -0.35 or progress,aiSpeed=9.1+(i-2)*0.7,decision=0}
    end
    r.player=r.cars[1];r.combat=combat.new(track)
    audio.play("red")
    return r
end
local function progressPlayer(r)
    local p=r.player
    local progress,distance=r.track.locate(p.x,p.z,p.progress)
    p.progress=progress;p.offroad=distance>r.track.halfWidth^2
    local sector=math.floor(progress/(r.track.segments/4))
    if not p.offroad then
        if sector==p.checkpoint+1 and sector<=3 then p.checkpoint=sector
        elseif sector==0 and p.checkpoint==3 then
            if p.started then p.laps=p.laps+1 end
            p.started=true;p.checkpoint=0
            if p.laps>=3 then p.done=true;r.finished=true end
        end
    end
    p.total=(p.started and p.laps*r.track.segments or -r.track.segments)+p.progress
end
local function position(r)
    local n=1
    for i=2,4 do if r.cars[i].done or r.cars[i].total>r.player.total then n=n+1 end end
    return n
end
Race.position=position
function Race.step(r,dt,input)
    if r.finished then return end
    if r.countdown>0 then
        local previous=r.countdown
        r.countdown=math.max(0,r.countdown-dt)
        if previous>1 and r.countdown<=1 then audio.play("red") end
        if previous>0 and r.countdown==0 then audio.play("green") end
        return
    end
    r.time=r.time+dt
    local steps=math.max(1,math.ceil(dt*40));local h=dt/steps
    for _=1,steps do
        local p=r.player
        progressPlayer(r)
        if p.respawn==0 and not p.done then
            local boost=p.nitro>0 and 1.1 or 1
            local accel=input.brake and -cfg.brake or input.gas and cfg.acceleration*boost or -1.8
            if p.offroad then accel=accel-5 end
            local cap=p.offroad and 5 or cfg.top_speed*boost
            p.speed=math.max(0,math.min(cfg.top_speed*boost,p.speed+accel*h))
            if p.speed>cap then p.speed=math.max(cap,p.speed-9*h) end
            if p.stun>0 then p.speed=math.min(p.speed,4) end
            p.yaw=(p.yaw+input.steer*cfg.steering*math.min(p.speed/5,1)*h+math.pi)%(2*math.pi)-math.pi
            p.x=p.x+math.sin(p.yaw)*p.speed*h;p.z=p.z+math.cos(p.yaw)*p.speed*h
            if math.abs(p.x)>55 or math.abs(p.z)>55 then p.x=math.max(-55,math.min(55,p.x));p.z=math.max(-55,math.min(55,p.z));p.speed=0 end
            progressPlayer(r)
        end
        for i=2,4 do
            local car=r.cars[i]
            if not car.done and car.respawn==0 then
                local boost=car.nitro>0 and 1.1 or 1
                car.speed=car.aiSpeed*boost*(car.stun>0 and 0.4 or 1)
                local _,_,_,length=r.track.sample(car.total)
                car.total=car.total+car.speed*h/length
                car.progress=car.total%r.track.segments;car.laps=math.floor(car.total/r.track.segments)
                car.x,car.z,car.yaw=r.track.sample(car.progress)
                if car.laps>=3 then car.done=true;car.speed=0 end
            end
        end
        combat.step(r.combat,r.cars,h)
        if p.respawn>0 then p.x,p.z,p.yaw=r.track.sample(p.progress) end
        if r.finished then break end
    end
    if input.fire then combat.fire(r.combat,r.player,r.cars) end
    -- AI decisions are limited to four evaluations/second per opponent.
    for i=2,4 do
        local c=r.cars[i];c.decision=c.decision-dt
        if c.decision<=0 and not c.done then
            c.decision=0.25
            if c.weapon=="mine" then
                for _,other in ipairs(r.cars) do if other~=c then
                    local dx,dz=other.x-c.x,other.z-c.z
                    if dx*dx+dz*dz<100 and dx*math.sin(c.yaw)+dz*math.cos(c.yaw)<0 then combat.fire(r.combat,c,r.cars);break end
                end end
            elseif c.weapon=="shot" then
                for _,other in ipairs(r.cars) do if other~=c then
                    local dx,dz=other.x-c.x,other.z-c.z
                    if dx*dx+dz*dz<225 and dx*math.sin(c.yaw)+dz*math.cos(c.yaw)>0 then combat.fire(r.combat,c,r.cars);break end
                end end
            end
        end
    end
    r.place=position(r)

    if r.finished then audio.play(r.place==1 and "win" or "lose") end
end
return Race
