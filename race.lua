local cfg=require "config"
local tracks=require "track"
local mesh=require "car"
local combat=require "combat"
local audio=require "audio"
local pace=1.15
local Race={names={"Lino","Carol","Lucas"}}
function Race.new(id,modelId,parts)
    modelId=modelId or 1
    local track=tracks.new(id)
    local r={track=track,id=id,cars={},time=0,countdown=3,finished=false,place=0,grid={}}
    local models={modelId}
    for id=1,#mesh.models do if id~=modelId then models[#models+1]=id end end
    local form={8.8,9.6,10.4}
    for i=#form,2,-1 do local j=math.random(i);form[i],form[j]=form[j],form[i] end
    for i=1,#Race.names+1 do
        local grid=-(1.6+(i-1)*2.4)/track.parts[track.segments].length
        local progress=grid%track.segments
        local x,z,yaw,_,y=track.sample(progress)
        local lane=i%2==1 and -2.35 or 2.35
        x,z=x+math.cos(yaw)*lane,z-math.sin(yaw)*lane
        r.grid[i]={x=x,y=y+0.025,z=z,yaw=yaw,radius=2}
        local model=mesh.models[models[i]]
        r.cars[i]={lane=lane,targetLane=i==4 and 0 or lane,player=i==1,x=x,y=y,z=z,yaw=yaw,speed=0,progress=progress,laps=0,
            nextGate=0,offroad=false,done=false,model=model,mesh=model.mesh,radius=2,
            hp=100,respawn=0,stun=0,nitro=0,cooldown=0,ammo=0,weapon=nil,
            total=grid,aiSpeed=(form[i-1] or 0)*pace,decision=0}
    end
    r.player=r.cars[1]
    if parts then
        local base=r.player.model
        r.player.model={
            accel=base.accel*(1+parts[1]*0.12),speed=base.speed*(1+parts[1]*0.05),
            steer=base.steer*(1+parts[2]*0.10),grass=base.grass*(1+parts[2]*0.08)
        }
        r.player.maxHP=100+parts[3]*20
        r.player.hp=r.player.maxHP
    end
    r.combat=combat.new(track)
    audio.play("red")
    return r
end
local function progressPlayer(r)
    local p=r.player
    local previous=p.progress
    local track=r.track
    local progress,distance=track.locate(p.x,p.z,previous)
    p.progress=progress;p.offroad=distance>track.halfWidth^2
    local _,_,_,_,height=track.sample(progress)
    p.y=height

    -- Grass slows the car, but the shoulders still count for lap validation.
    local inCorridor=distance<=(track.halfWidth+2.5)^2
    local departure=p.leftCorridor
    local anchor=departure or previous
    if not inCorridor then
        p.leftCorridor=anchor
    else
        p.leftCorridor=nil
    end
    local advance=(progress-anchor)%track.segments
    local skipped=advance>=math.max(4,math.ceil(track.segments*0.12))
        and advance<=track.segments*0.60
    local shortcut=p.nextGate>0 and inCorridor and departure~=nil and skipped
        and p.respawn==0 and not p.done
    if shortcut then
        p.laps,p.nextGate,p.shortcutNotice=0,0,2.5
    end

    -- Resume a short excursion at the same gate, or at the next adjacent gate.
    local maxAdvance=departure and 2 or 1
    if not p.done and p.respawn==0 and inCorridor and not shortcut
        and advance>0 and advance<=maxAdvance then
        for gate=math.floor(anchor)+1,math.floor(anchor+advance) do
            if gate%track.segments~=p.nextGate%track.segments then break end
            if p.nextGate>0 and p.nextGate%track.segments==0 then
                p.laps=p.laps+1
                if p.laps>=track.laps then p.done=true;r.finished=true end
            end
            p.nextGate=p.nextGate+1
            if p.done then break end
        end
    end
    if p.nextGate==0 then
        p.total=-((track.segments-progress)%track.segments)
    else
        local last=p.nextGate-1
        local fraction=progress-last%track.segments
        p.total=last+(fraction>=0 and fraction<1 and fraction or 0)
    end
end
local function position(r)
    local n=1
    for i=2,#r.cars do if r.cars[i].done or r.cars[i].total>r.player.total then n=n+1 end end
    return n
end
Race.position=position
function Race.opponentOrder(r)
    local ids={}
    for i=1,#r.cars-1 do ids[i]=i end
    table.sort(ids,function(a,b)
        local first,second=r.cars[a+1],r.cars[b+1]
        if first.finishOrder or second.finishOrder then
            return (first.finishOrder or #r.cars)<(second.finishOrder or #r.cars)
        end
        if first.total==second.total then return a<b end
        return first.total>second.total
    end)
    return table.concat(ids)
end
local function moveSide(car,x,z)
    car.x,car.z=car.x+x,car.z+z
    if not car.player then
        car.lane=math.max(-4.1,math.min(4.1,car.lane+x*math.cos(car.yaw)-z*math.sin(car.yaw)))
    end
end
local function collide(r)
    for i=1,#r.cars-1 do
        local a=r.cars[i]
        if a.respawn==0 and not a.done then
            for j=i+1,#r.cars do
                local b=r.cars[j]
                if b.respawn==0 and not b.done and math.abs(a.y-b.y)<1.2 then
                    local dx,dz=b.x-a.x,b.z-a.z
                    local d2=dx*dx+dz*dz
                    if d2<2.45^2 then
                        local distance=math.sqrt(d2)
                        local nx,nz=1,0
                        if distance>0.001 then nx,nz=dx/distance,dz/distance end
                        local push=(2.45-distance)/2
                        moveSide(a,-nx*push,-nz*push)
                        moveSide(b,nx*push,nz*push)
                        local closing=(math.sin(a.yaw)*a.speed-math.sin(b.yaw)*b.speed)*nx
                            +(math.cos(a.yaw)*a.speed-math.cos(b.yaw)*b.speed)*nz
                        if closing>0.5 and a.bump==0 and b.bump==0 then
                            a.speed=a.speed*0.72;b.speed=b.speed*0.82
                            a.bump,b.bump=0.22,0.22
                        end
                    end
                end
            end
        end
    end
end
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
    r.player.shortcutNotice=math.max(0,(r.player.shortcutNotice or 0)-dt)
    r.sliding=input.brake and input.steer~=0
    local steps=math.max(1,math.ceil(dt*40));local h=dt/steps
    for _=1,steps do
        local p=r.player
        progressPlayer(r)
        if p.respawn==0 and not p.done then
            local boost=p.nitro>0 and 1.1 or 1
            local model=p.model
            local accel=input.brake and -cfg.brake or input.gas and model.accel*boost*pace or -1.8
            if p.offroad then accel=accel-5 end
            local cap=p.offroad and model.grass*pace or model.speed*boost*pace
            p.speed=math.max(0,math.min(model.speed*boost*pace,p.speed+accel*h))
            if p.speed>cap then p.speed=math.max(cap,p.speed-9*h) end
            if p.stun>0 then p.speed=math.min(p.speed,4) end
            p.yaw=(p.yaw+input.steer*model.steer*math.min(p.speed/5,1)*h+math.pi)%(2*math.pi)-math.pi
            p.x=p.x+math.sin(p.yaw)*p.speed*h;p.z=p.z+math.cos(p.yaw)*p.speed*h
            if math.abs(p.x)>r.track.bound or math.abs(p.z)>r.track.bound then p.x=math.max(-r.track.bound,math.min(r.track.bound,p.x));p.z=math.max(-r.track.bound,math.min(r.track.bound,p.z));p.speed=0 end
            progressPlayer(r)
        end
        for _,car in ipairs(r.cars) do car.bump=math.max(0,(car.bump or 0)-h) end
        for i=2,#r.cars do
            local car=r.cars[i]
            if not car.done and car.respawn==0 then
                local boost=car.nitro>0 and 1.1 or 1
                car.speed=car.aiSpeed*boost*(car.stun>0 and 0.4 or car.bump>0 and 0.72 or 1)
                local _,_,_,length=r.track.sample(car.total)
                car.total=car.total+car.speed*h/length
                car.progress=car.total%r.track.segments;car.laps=math.max(0,math.floor(car.total/r.track.segments))
                local x,z,yaw,_,height=r.track.sample(car.progress)
                if car.total>0 then
                    car.lane=car.lane+(car.targetLane-car.lane)*math.min(1,h*0.6)
                end
                car.x,car.z,car.yaw,car.y=x+math.cos(yaw)*car.lane,z-math.sin(yaw)*car.lane,yaw,height
                if car.laps>=r.track.laps then
                    r.finishedOpponents=(r.finishedOpponents or 0)+1
                    car.finishOrder=r.finishedOpponents;car.done=true;car.speed=0
                end
            end
        end
        collide(r)
        combat.step(r.combat,r.cars,h)
        if p.respawn>0 then p.x,p.z,p.yaw=r.track.sample(p.progress) end
        if r.finished then break end
    end
    if input.select then combat.select(r.player) end
    if input.fire then combat.fire(r.combat,r.player,r.cars) end
    -- AI decisions are limited to four evaluations/second per opponent.
    for i=2,#r.cars do
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
