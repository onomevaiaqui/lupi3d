local G=require "geometry"
local audio=require "audio"
local C={}
local function itemMesh(color)
    local m={v={-0.4,0.5,0,0,0.5,0.4,0.4,0.5,0,0,0.5,-0.4,0,1.15,0,0,0.1,0},f={}}
    m.f={1,5,2,color,2,5,3,color,3,5,4,color,4,5,1,color,2,6,1,color,3,6,2,color,4,6,3,color,1,6,4,color}
    return m
end
local meshes={shot=itemMesh(8),mine=itemMesh(7),nitro=itemMesh(6)}
local mineMesh=G.box(0.55,0.12,0.55,7,23,8)
local traceMesh=G.mesh()
G.quad(traceMesh,{-0.035,0,0},{-0.035,0,10},{0.035,0,10},{0.035,0,0},15)
function C.new(track)
    local c={pickups={},mines={},traces={},track=track}
    local kinds={"shot","mine","nitro","shot","mine","nitro","shot","nitro"}
    for i,kind in ipairs(kinds) do
        local x,z=track.sample((i-0.3)*track.segments/8)
        c.pickups[i]={kind=kind,x=x,y=0,z=z,mesh=meshes[kind],radius=1,cooldown=0}
    end
    for i=1,8 do c.mines[i]={active=false,mesh=mineMesh,radius=1,y=0.12} end
    for i=1,4 do c.traces[i]={active=false,mesh=traceMesh,radius=11,y=0.65} end
    return c
end
function C.collect(car,kind)
    if kind=="nitro" then car.nitro=5
    else car.weapon=kind;car.ammo=kind=="shot" and 3 or 2 end
    if car.player then audio.play("pickup") end
end
local function damage(car,amount)
    if car.respawn>0 or car.done then return end
    car.hp=math.max(0,car.hp-amount);car.speed=car.speed*0.45;car.stun=0.55
    if car.player then audio.play("hit") end
    if car.hp==0 then car.respawn=2;car.weapon=nil;car.ammo=0;car.nitro=0;car.speed=0 end
end
C.damage=damage
function C.fire(c,car,cars)
    if car.ammo<=0 or car.cooldown>0 or car.respawn>0 or car.done then return false end
    if car.weapon=="shot" then
        local dx,dz=math.sin(car.yaw),math.cos(car.yaw)
        local nearest,best=15,nil
        for _,other in ipairs(cars) do if other~=car and other.respawn==0 and not other.done then
            local x,z=other.x-car.x,other.z-car.z
            local along=x*dx+z*dz;local side=x*dz-z*dx
            if along>0 and along<nearest and math.abs(side)<0.85 then nearest,best=along,other end
        end end
        if best then damage(best,35) end
        for _,t in ipairs(c.traces) do if not t.active then
            t.active=true;t.x=car.x;t.z=car.z;t.yaw=car.yaw;t.ttl=0.09;break
        end end
        if car.player then audio.play("shot") end
    elseif car.weapon=="mine" then
        local free
        for _,m in ipairs(c.mines) do if not m.active then free=m;break end end
        if not free then return false end
        free.active=true;free.owner=car;free.x=car.x-math.sin(car.yaw)*1.6;free.z=car.z-math.cos(car.yaw)*1.6
        free.ttl=18;free.arm=0.5
        if car.player then audio.play("mine") end
    else return false end
    car.ammo=car.ammo-1;car.cooldown=0.35
    return true
end
function C.step(c,cars,dt)
    for _,p in ipairs(c.pickups) do p.cooldown=math.max(0,p.cooldown-dt) end
    for _,car in ipairs(cars) do
        car.nitro=math.max(0,car.nitro-dt);car.cooldown=math.max(0,car.cooldown-dt);car.stun=math.max(0,car.stun-dt)
        if car.respawn>0 then
            car.respawn=math.max(0,car.respawn-dt)
            if car.respawn==0 then car.hp=100;car.stun=0;car.speed=0 end
        elseif not car.done then
            for _,p in ipairs(c.pickups) do
                local x,z=p.x-car.x,p.z-car.z
                if p.cooldown==0 and x*x+z*z<3.4 then C.collect(car,p.kind);p.cooldown=9;break end
            end
        end
    end
    for _,m in ipairs(c.mines) do if m.active then
        m.ttl=m.ttl-dt;m.arm=math.max(0,m.arm-dt)
        if m.ttl<=0 then m.active=false
        elseif m.arm==0 then
            for _,car in ipairs(cars) do if car.respawn==0 and not car.done then
                local x,z=car.x-m.x,car.z-m.z
                if x*x+z*z<1.3 then damage(car,50);m.active=false;break end
            end end
        end
    end end
    for _,t in ipairs(c.traces) do if t.active then t.ttl=t.ttl-dt;if t.ttl<=0 then t.active=false end end end
end
return C
