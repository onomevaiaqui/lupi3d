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
    keys={};Game.x,Game.z,Game.yaw,Game.speed=-3,-28,math.pi/2,0
    Game.time,Game.laps,Game.checkpoint,Game.lap_start=0,0,3,0
    Game.started,Game.finished,Game.best=false,false,nil
end
for _,fps in ipairs({10,15,26,30,60,120}) do
    reset();keys[BTN_Z]=true
    for _=1,fps do Game.step(1/fps) end
    assert(math.abs(Game.speed-7)<0.001,"B acceleration must be time based")
    assert(Game.started and Game.laps==0,"first crossing starts the race without awarding a lap")
    keys[BTN_G]=true
    for _=1,fps do Game.step(1/fps) end
    assert(Game.speed==0,"A brake must override B and stop")
end
reset();keys[RIGHT]=true;Game.step(0.1);assert(Game.yaw==math.pi/2,"no steering while stopped")
Game.speed=5;Game.step(0.1);assert(Game.yaw>math.pi/2,"right steering")
local rightYaw=Game.yaw;keys={[LEFT]=true};Game.step(0.1);assert(Game.yaw<rightYaw,"left steering")
reset();Game.x,Game.z,Game.speed=0,0,12;keys[BTN_Z]=true
for _=1,60 do Game.step(1/60) end
assert(Game.offroad and Game.speed<6,"grass must slow the car")
reset();Game.speed=0
local function gate(phase)
    local a=math.pi-phase;Game.x,Game.z=math.sin(a)*track.a,math.cos(a)*track.b;Game.step(0)
end
gate(0.1);assert(Game.started and Game.laps==0)
gate(0.1);assert(Game.laps==0,"stationary finish must not count")
for lap=1,3 do
    gate(1.7);gate(3.3);gate(4.9);gate(0.1);assert(Game.laps==lap,"ordered oval checkpoints")
end
assert(Game.finished and Game.best~=nil,"three lap finish")
reset();gate(0.1);gate(4.9);gate(0.1);assert(Game.laps==0,"reverse crossing must not count")
-- Drive a complete race through the same throttle/steering inputs.
reset()
for _=1,6000 do
    local a=math.atan(Game.x/track.a,Game.z/track.b)-0.18
    local heading=math.atan(math.sin(a)*track.a-Game.x,math.cos(a)*track.b-Game.z)
    local error=(heading-Game.yaw+math.pi)%(2*math.pi)-math.pi
    keys={[BTN_Z]=true,[LEFT]=error< -0.02,[RIGHT]=error>0.02}
    Game.step(1/30)
    if Game.finished then break end
end
assert(Game.finished and Game.laps==3,"oval must be drivable for three laps with real inputs")
local maxTriangles=0
collectgarbage("collect");local start=os.clock();local views=0
for i=0,95 do
    local a=i*2*math.pi/96;Game.x,Game.z=math.sin(a)*track.a,math.cos(a)*track.b
    for _,offset in ipairs({-1,0,1}) do
        Game.yaw=-a+math.pi/2+offset;Game.draw();views=views+1
        assert(Game.triangles>0 and Game.dropped==0);maxTriangles=math.max(maxTriangles,Game.triangles)
    end
end
local elapsed=os.clock()-start
reset();capture=true;Game.draw();capture=false
local out=assert(io.open(".tools/frame.csv","w"));out:write(table.concat(commands,"\n"));out:close()
out=assert(io.open(".tools/palette.csv","w"));for i=0,31 do out:write(i,",",palette[i],"\n") end;out:close()
collectgarbage("collect")
print(string.format("PASS: B throttle, A brake priority, steering, grass slowdown, ordered checkpoints, 3 laps, 10/15/26/30/60/120 FPS physics; %d 3D camera views, max %d triangles, heap %.1f KiB, local Lua %.3f ms/view (not hardware)",views,maxTriangles,collectgarbage("count"),elapsed/views*1000))
