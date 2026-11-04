local G=require "geometry"
local renderer=require "renderer"
local colors=require "colors"
local models=require("car").models
local T={}
local camera={x=0,y=2.5,z=0,yaw=0,pitch=-0.08}
local lanes={-2.1,2.1}
local function road(x1,x2,z1,z2,color,y)
    local mesh=G.mesh()
    G.quad(mesh,{x1,0,z1},{x1,0,z2},{x2,0,z2},{x2,0,z1},color)
    return {mesh=mesh,x=0,y=y or 0,z=0}
end
local asphalt=road(-4.3,4.3,0.2,60,3)
local edges={road(-4.2,-4.06,0.2,60,9,0.012),road(4.06,4.2,0.2,60,9,0.012)}
local dashMesh=road(-0.07,0.07,0,2.2,15).mesh
local dashes={}
for i=1,10 do dashes[i]={mesh=dashMesh,x=0,y=0.015,z=0} end
local function spawn(run,car,z)
    run.serial=run.serial+1
    car.oncoming=run.serial%3~=1
    car.x=lanes[car.oncoming and 1 or 2]
    car.z=z
    car.yaw=car.oncoming and math.pi or 0
    car.speed=car.oncoming and -11 or 7+(run.serial%3)*2
    car.passed=false
end
function T.new()
    local run={time=60,score=0,bonusAt=10000,gear=1,speed=0,serial=0,scroll=0,crash=0,
        player={x=lanes[2],y=0,z=5.2,mesh=models[4].mesh},traffic={}}
    for i=1,5 do
        local car={mesh=models[(i-1)%3+1].mesh,y=0}
        spawn(run,car,15+i*9)
        run.traffic[i]=car
    end
    return run
end
function T.step(run,dt,gas,steer,up,down)
    if run.time<=0 then return end
    run.time=math.max(0,run.time-dt)
    if up then run.gear=2 elseif down then run.gear=1 end
    run.crash=math.max(0,run.crash-dt)
    if run.crash==0 then
        local cap=run.gear==1 and 13 or 26
        local accel=gas and (run.gear==1 and 10 or 5) or -4
        run.speed=math.max(0,math.min(cap,run.speed+accel*dt))
        run.player.x=math.max(-3.4,math.min(3.4,run.player.x+steer*dt*5))
    end
    run.scroll=(run.scroll+run.speed*dt)%6
    run.score=run.score+run.speed*dt*7
    local far=62
    for _,car in ipairs(run.traffic) do far=math.max(far,car.z) end
    for _,car in ipairs(run.traffic) do
        local previous=car.z
        car.z=car.z+(car.speed-run.speed)*dt
        local p=run.player
        if run.crash==0 and math.min(previous,car.z)<p.z+2
            and math.max(previous,car.z)>p.z-2 and math.abs(car.x-p.x)<1.3 then
            run.speed,run.gear,run.crash=0,1,0.8
            far=far+10;spawn(run,car,far)
        elseif not car.oncoming and not car.passed and previous>=p.z and car.z<p.z then
            car.passed=true;run.score=run.score+250
        end
        if car.z<0.2 or car.z>100 then far=far+10;spawn(run,car,far) end
    end
    if run.score>=run.bonusAt then
        run.time=run.time+60;run.bonusAt=run.bonusAt+10000
    end
end
function T.draw(run)
    local c=colors.index
    ui.rectfill(0,20,479,105,c[1])
    ui.trisfill(0,105,78,58,174,105,c[11])
    ui.trisfill(278,105,396,63,479,105,c[27])
    ui.rectfill(0,105,479,227,c[14])
    camera.x=run.player.x*0.42
    renderer.begin(camera)
    renderer.submit(asphalt)
    renderer.flush()
    for _,edge in ipairs(edges) do renderer.submit(edge) end
    for i,dash in ipairs(dashes) do
        dash.z=i*6-run.scroll
        renderer.submit(dash)
    end
    renderer.flush()
    for _,car in ipairs(run.traffic) do
        if car.z>1.4 and car.z<60 then renderer.submit(car) end
    end
    if run.crash==0 or math.floor(run.crash*12)%2==0 then renderer.submit(run.player) end
    renderer.flush()
    ui.rectfill(0,0,479,19,c[10])
    ui.rectfill(0,228,479,269,c[10])
    ui.print(string.format("TURBO   %03d KM/H   MARCHA %d   TEMPO %02d   PTS %06d",
        math.floor(run.speed*8),run.gear,math.ceil(run.time),math.floor(run.score)),9,6,c[15])
    ui.print("B ACELERA  CRUZ VIRA E TROCA MARCHA  L REINICIA  Y SAI",9,243,c[9])
    if run.time<=0 then ui.print("TEMPO ESGOTADO",183,112,c[15])
    elseif run.crash>0 then ui.print("BATIDA!",213,112,c[7]) end
end
return T
