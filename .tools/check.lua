package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local keys,palette,commands={},{},{}
local capture=false
local submitted=0
local function record(...) if capture then commands[#commands+1]=table.concat({...},",") end end
ui={btn=function(k) return keys[k] or 0 end,
palset=function(i,c) assert(i>=0 and i<32 and c>=0 and c<32768);palette[i]=c end,
camera=function() end,clip=function() end,cls=function(c) record("rect",0,0,480,270,c) end,
rectfill=function(a,b,c,d,e) assert(a>=0 and c<=480 and b>=0 and d<=270);record("rect",a,b,c,d,e) end,
print=function(s,x,y,c) record("text",x,y,c,s) end,
spr=function() error("car must use XYZ triangles") end,
trisfill=function(a,b,c,d,e,f,color)
    assert(a==math.floor(a) and b==math.floor(b) and c==math.floor(c) and d==math.floor(d) and e==math.floor(e) and f==math.floor(f))
    assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479)
    assert(b>=20 and b<=227 and d>=20 and d<=227 and f>=20 and f<=227)
    assert((c-a)*(f-b)-(d-b)*(e-a)>0,"invalid native triangle")
    assert(color>=0 and color<32);submitted=submitted+1;record("tri",a,b,c,d,e,f,color)
end}
require "game"
local track=require "track"
local function reset()
    keys={};Game.progress=track.segments-0.35
    Game.x,Game.z,Game.yaw=track.sample(Game.progress);Game.speed=0
    Game.time,Game.laps,Game.checkpoint,Game.lap_start=0,0,3,0
    Game.started,Game.finished,Game.best=false,false,nil
    Game.rival.progress=0.6;Game.countdown=0
end
for _,fps in ipairs({10,15,24,26,30,60,120}) do
    reset();keys[BTN_Z]=true
    for _=1,fps do Game.step(1/fps);Game.draw() end
    assert(math.abs(Game.speed-7)<0.001,"time based acceleration")
    keys[BTN_G]=true
    for _=1,fps do Game.step(1/fps);Game.draw() end
    assert(Game.speed==0,"brake overrides throttle")
end
reset();keys[RIGHT]=true;local startYaw=Game.yaw;Game.step(0.1);assert(math.abs(Game.yaw-startYaw)<1e-8)
Game.speed=5;Game.step(0.1);assert(Game.yaw>startYaw)
local rightYaw=Game.yaw;keys={[LEFT]=true};Game.step(0.1);assert(Game.yaw<rightYaw)
reset();Game.x,Game.z,Game.speed=45,30,12;keys[BTN_Z]=true
for _=1,60 do Game.step(1/60) end
assert(Game.offroad and Game.speed<6)
for _,tree in ipairs(track.trees) do local _,d=track.locate(tree.x,tree.z);assert(d>(track.halfWidth+1.45)^2,"tree canopy must clear the road") end
local p0,d0=track.locate(0,0,0);local p1,d1=track.locate(0,0,24)
assert((p0<0.01 or p0>47.99) and math.abs(p1-24)<0.01 and d0<1e-8 and d1<1e-8,"crossing must preserve route branch")
reset()
local function gate(p)
    Game.x,Game.z=track.sample(p);Game.progress=p;Game.step(0)
end
gate(0.1);assert(Game.started and Game.laps==0)
for lap=1,3 do gate(12.2);gate(24.2);gate(36.2);gate(0.1);assert(Game.laps==lap) end
assert(Game.finished)
reset();gate(0.1);gate(36.2);gate(0.1);assert(Game.laps==0,"reverse must not award laps")
reset()
for i=1,15000 do
    local target=Game.progress+1.15
    local x,z=track.sample(target)
    local heading=math.atan(x-Game.x,z-Game.z)
    local error=(heading-Game.yaw+math.pi)%(2*math.pi)-math.pi
    keys={[BTN_Z]=true,[LEFT]=error< -0.02,[RIGHT]=error>0.02}
    Game.step(1/30)
    if Game.finished then break end
end
assert(Game.finished and Game.laps==3,"figure eight must be drivable for three laps")
assert(Game.rival.progress>track.segments,"rival must progress independently")
-- Countdown locks both vehicles and clock; reset is edge-triggered on Y.
reset();Game.reset();keys={[BTN_Z]=true}
local sx,sz,rp=Game.x,Game.z,Game.rival.progress
for _=1,60 do Game.step(1/30) end
assert(Game.countdown>0 and Game.speed==0 and Game.time==0 and Game.x==sx and Game.z==sz and Game.rival.progress==rp)
for _=1,31 do Game.step(1/30) end
assert(Game.countdown==0)
Game.step(1/30);assert(Game.speed>0 and Game.time>0 and Game.rival.progress>rp)
keys={[BTN_F]=true};Game.step(1/30)
assert(Game.countdown==3 and Game.speed==0 and Game.laps==0 and Game.time==0 and Game.rival.progress==0.6)
Game.step(0.1);assert(Game.countdown<3,"holding Y must not continually reset countdown")
keys={};Game.step(0);Game.finished=true;keys={[BTN_F]=true};Game.step(0)
assert(not Game.finished and Game.countdown==3,"Y restart must work after finish")
keys={};Game.step(0)
local maxTriangles=0
collectgarbage("collect");local start=os.clock();local views=0
for i=0,95 do
    Game.progress=i*track.segments/96
    local yaw;Game.x,Game.z,yaw=track.sample(Game.progress)
    -- Include rival visible alongside player and crossing views.
    Game.rival.x,Game.rival.z,Game.rival.yaw=track.sample(Game.progress+1.2)
    for _,offset in ipairs({-1,0,1}) do
        Game.yaw=yaw+offset;Game.draw();views=views+1
        assert(Game.triangles>0 and Game.dropped==0);maxTriangles=math.max(maxTriangles,Game.triangles)
    end
end
local elapsed=os.clock()-start
Game.reset();keys={};capture=true;Game.draw();capture=false
local out=assert(io.open(".tools/frame.csv","w"));out:write(table.concat(commands,"\n"));out:close()
out=assert(io.open(".tools/palette.csv","w"));for i=0,31 do out:write(i,",",palette[i],"\n") end;out:close()
collectgarbage("collect")
print(string.format("PASS: throttle/brake/steering, fractional HUD, grass, branch-aware crossing, countdown locks, Y restart, ordered checkpoints and 3 drivable laps; %d views, max %d triangles, Lua heap %.1f KiB, local %.3f ms/view (not console FPS)",views,maxTriangles,collectgarbage("count"),elapsed/views*1000))
print(string.format("Track length %.1f units; player car %d triangles, rival %d triangles, 8 trees",track.length,#require("car").f/4,#require("car").rival.f/4))