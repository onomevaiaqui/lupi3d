package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local cfg=require "config";cfg.save_dir=".tools/"
local keys,palette,commands={},{},{}
local capture=false
local drawCalls,area=0,0
local function record(...) if capture then commands[#commands+1]=table.concat({...},",") end end
local sounds=0
sfx={fx=function(id,note,pan) assert(id==0 and note>=0 and note<=127 and pan==0.5);sounds=sounds+1 end}
ui={btn=function(k) return keys[k] or 0 end,
palset=function(i,c) assert(i>=0 and i<32 and c>=0 and c<32768);palette[i]=c end,
camera=function() end,clip=function() end,cls=function(c) record("rect",0,0,480,270,c) end,
rectfill=function(a,b,c,d,e) assert(a>=0 and c<=480 and b>=0 and d<=270);record("rect",a,b,c,d,e) end,
print=function(s,x,y,c) assert(type(s)=="string");record("text",x,y,c,s) end,
trisfill=function(a,b,c,d,e,f,color)
    assert(a==math.floor(a) and b==math.floor(b) and c==math.floor(c) and d==math.floor(d) and e==math.floor(e) and f==math.floor(f))
    assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479)
    assert(b>=20 and b<=227 and d>=20 and d<=227 and f>=20 and f<=227)
    assert((c-a)*(f-b)-(d-b)*(e-a)>0,"invalid native triangle")
    assert(color>=0 and color<32);drawCalls=drawCalls+1;area=area+((c-a)*(f-b)-(d-b)*(e-a))/2
    record("tri",a,b,c,d,e,f,color)
end}
local Race=require "race"
local C=require "combat"
local tracks=require "track"
local function input() return {gas=false,brake=false,fire=false,steer=0} end
for id=1,3 do
    local r=Race.new(id);assert(#r.cars==4)
    local sx,sz=r.player.x,r.player.z
    for _=1,60 do Race.step(r,1/30,{gas=true,brake=false,fire=true,steer=1}) end
    assert(r.countdown>0 and r.player.speed==0 and r.time==0 and r.player.x==sx and r.player.z==sz)
    for _,fps in ipairs({10,15,24,30,60,120}) do
        r=Race.new(id);r.countdown=0
        for _=1,fps do Race.step(r,1/fps,{gas=true,brake=false,fire=false,steer=0}) end
        assert(math.abs(r.player.speed-7)<0.001,"time based acceleration")
        for _=1,fps do Race.step(r,1/fps,{gas=true,brake=true,fire=false,steer=0}) end
        assert(r.player.speed==0,"brake must override throttle")
    end
    r=Race.new(id);r.countdown=0
    -- A complete race through the actual player controls on every layout.
    for _=1,15000 do
        local p=r.player;local x,z=r.track.sample(p.progress+1.15)
        local heading=math.atan(x-p.x,z-p.z)
        local error=(heading-p.yaw+math.pi)%(2*math.pi)-math.pi
        Race.step(r,1/30,{gas=true,brake=false,fire=false,steer=error< -0.02 and -1 or error>0.02 and 1 or 0})
        if r.finished then break end
    end
    assert(r.finished and r.player.laps==3,"track "..id.." must be drivable")
    assert(r.place>=1 and r.place<=4)
    print("PASS: track "..id.." complete race, "..string.format("%.1f",r.time).." seconds, place "..r.place)
end
local r=Race.new(2);r.countdown=0
local p0,d0=r.track.locate(0,0,0);local p1,d1=r.track.locate(0,0,24)
assert((p0<0.01 or p0>47.99) and math.abs(p1-24)<0.01 and d0<1e-8 and d1<1e-8)
-- Ordered gates prevent reverse crossings and permit true first-place completion.
local gateRace=Race.new(1);gateRace.countdown=0
local function gate(progress)
    local p=gateRace.player;p.x,p.z=gateRace.track.sample(progress);p.progress=progress
    Race.step(gateRace,0,input())
end
gate(0.1);gate(gateRace.track.segments-0.1);gate(0.1);assert(gateRace.player.laps==0)
for lap=1,3 do
    gate(gateRace.track.segments/4+0.1);gate(gateRace.track.segments/2+0.1);gate(gateRace.track.segments*3/4+0.1);gate(0.1)
end
assert(gateRace.finished and gateRace.place==1)
-- Controlled combat: nearest target, ammunition, cooldown and respawn.
local p,a,b=r.cars[1],r.cars[2],r.cars[3]
p.x,p.z,p.yaw=0,0,0;a.x,a.z=0,5;b.x,b.z=0,9;r.cars[4].x=30
C.collect(p,"shot");assert(p.ammo==3)
for i=1,3 do assert(C.fire(r.combat,p,r.cars));assert(not C.fire(r.combat,p,r.cars));C.step(r.combat,r.cars,0.36) end
assert(p.ammo==0 and a.respawn>0 and b.hp==100)
assert(not C.fire(r.combat,p,r.cars))
C.step(r.combat,r.cars,2.1);assert(a.hp==100 and a.respawn==0)
C.collect(p,"mine");assert(p.ammo==2)
for _=1,2 do
    p.cooldown=0;assert(C.fire(r.combat,p,r.cars))
    local m;for _,q in ipairs(r.combat.mines) do if q.active then m=q;break end end
    a.x,a.z=m.x,m.z;p.x=10
    C.step(r.combat,r.cars,0.6);p.x=0
end
assert(p.ammo==0 and a.respawn>0,"two mines must exhaust pickup and destroy target")
C.collect(p,"nitro");assert(p.nitro==5)
r=Race.new(1);r.countdown=0;C.collect(r.player,"nitro")
for _=1,110 do Race.step(r,1/30,{gas=true,brake=false,fire=false,steer=0}) end
-- Straight-line acceleration test uses a fresh car away from items and track turns.
r=Race.new(1);r.countdown=0;C.collect(r.player,"nitro");Race.step(r,0.1,{gas=true,brake=false,fire=false,steer=0})
assert(math.abs(r.player.speed-0.77)<0.001,"nitro adds exactly ten percent acceleration")
local A=require "audio";local old=sfx;sfx=nil;A.play("shot");sfx={fx=function() error("unavailable") end};A.play("shot");sfx=old;A.error=false;A.play("menu")
assert(sounds>0)
require "game"
local Save=require "save"
local function tap(key)
    keys={};Game.step(0);keys={[key]=true};Game.step(0);keys={};Game.step(0)
end
assert(Game.state=="menu")
Game.menu=2;tap(BTN_Z);assert(Game.state=="menu","Continue must be disabled before first victory");Game.menu=1
tap(BTN_Z);assert(Game.state=="select" and Save.wins()==0)
for id=1,3 do
    Game.startRace(id);assert(#Game.race.cars==4)
    keys={[BTN_F]=true};Game.step(0);assert(Game.race.countdown==3)
    Game.step(0.1);assert(Game.race.countdown<3,"holding Y must not reset repeatedly")
    keys={};Game.step(0)
end
Game.race.finished=true;Game.race.place=1;Game.result();assert(Game.state=="result" and Save.canContinue())
Game.startRace(2);Game.race.place=1;Game.result();assert(Save.wins()==2)
Game.state="menu";Game.menu=2;tap(BTN_Z);assert(Game.state=="select","Continue after first victory")
-- R fires, A only brakes, Y restarts and preserves championship progress.
Game.startRace(1);Game.race.countdown=0;C.collect(Game.race.player,"shot")
tap(BTN_E);assert(Game.race.player.ammo==2)
tap(BTN_G);assert(Game.race.player.ammo==2)
tap(BTN_F);assert(Game.race.countdown==3 and Save.wins()==2)
-- Turning the car must not rotate the world camera.
Game.startRace(2);Game.draw()
local part=Game.race.track.parts[1]
local sx,sy=part.sx[1],part.sy[1]
Game.race.player.yaw=Game.race.player.yaw+1.1;Game.draw()
assert(part.sx[1]==sx and part.sy[1]==sy,"top-down world orientation must remain fixed when car turns")
local maxTriangles,maxArea=0,0
local start=os.clock();local views=0
for id=1,3 do
    Game.startRace(id)
    local rr=Game.race
    for i=0,63 do
        local progress=i*rr.track.segments/64
        rr.player.x,rr.player.z,rr.player.yaw=rr.track.sample(progress)
        for j=2,4 do rr.cars[j].x,rr.cars[j].z,rr.cars[j].yaw=rr.track.sample(progress+(j-1)*0.6) end
        for _,offset in ipairs({-0.7,0,0.7}) do
            local yaw=rr.player.yaw;rr.player.yaw=yaw+offset
            drawCalls,area=0,0;Game.draw();views=views+1
            assert(Game.dropped==0 and Game.triangles>0 and Game.triangles==drawCalls)
            maxTriangles=math.max(maxTriangles,drawCalls);maxArea=math.max(maxArea,area)
            rr.player.yaw=yaw
        end
    end
end
-- All pooled mines, shots and nearby cars active together must remain in budget.
Game.startRace(2)
local rr=Game.race;local p=rr.player
for i,m in ipairs(rr.combat.mines) do m.active=true;m.x=p.x+(i%3-1);m.z=p.z+i*0.6 end
for i,t in ipairs(rr.combat.traces) do t.active=true;t.x=p.x+i*0.2;t.z=p.z+2;t.yaw=p.yaw end
Game.draw();assert(Game.dropped==0 and Game.triangles<384)
local stressTriangles=Game.triangles
local elapsed=os.clock()-start
local function frame(name)
    commands={};capture=true;Game.draw();capture=false
    local out=assert(io.open(".tools/"..name..".csv","w"));out:write(table.concat(commands,"\n"));out:close()
end
Game.state="menu";frame("view-menu")
Game.state="select";frame("view-select")
Game.startRace(2);frame("frame")
local out=assert(io.open(".tools/palette.csv","w"));for i=0,31 do out:write(i,",",palette[i],"\n") end;out:close()
collectgarbage("collect")
print(string.format("PASS: 4 cars, items 3 shots/2 mines, 10%% nitro, damage/respawn, sound API, menus, Continue, distinct wins, R/A/Y controls; %d views, max %d triangles, max projected area %.0f px, heap %.1f KiB, local %.3f ms/view (not console FPS)",views,maxTriangles,maxArea,collectgarbage("count"),elapsed/views*1000))
print("All effects stress: "..stressTriangles.." triangles; no dropped triangles")
for _,slot in ipairs({0,1}) do os.remove(".tools/rally-save-"..slot..".dat") end
