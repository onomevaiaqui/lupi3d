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
spr=function() error("3D weapon must not use a sprite") end,
trisfill=function(a,b,c,d,e,f,color)
    assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479)
    assert(b>=20 and b<=227 and d>=20 and d<=227 and f>=20 and f<=227)
    assert((c-a)*(f-b)-(d-b)*(e-a)>0,"degenerate/inverted native triangle")
    assert(color>=0 and color<32)
    submitted=submitted+1;record("tri",a,b,c,d,e,f,color)
end}
local level=require "level"
local cfg=require "config"
require "game"
local function reset(x,z,y,yaw)
    keys={};Game.x,Game.z,Game.y,Game.vy,Game.yaw,Game.pitch=x or 6.5,z or 2.5,y or 0,0,yaw or 0,0
    Game.grounded=true;Game.phase=0;Game.step(0)
end
assert(Game.shoot()==1 and Game.hits==1,"initial 3D target hit")
assert(Game.shoot()==0 and Game.shots==1,"shot cooldown")
Game.cooldown=0;Game.yaw=math.pi/2;assert(Game.shoot()==0,"off-axis 3D shot must miss")
Game.reset_targets();reset()
for i,t in ipairs(Game.targets) do t.alive=i==6 end
assert(Game.shoot()==0 and Game.targets[6].alive,"cover must block the far target")
Game.y=0.8;Game.cooldown=0
assert(Game.shoot()==6,"elevated ray must pass over low cover and hit the raised target")
Game.reset_targets();reset(11.8,3.3)
assert(Game.shoot()==0 and Game.targets[3].alive,"ground-level ray must miss elevated volume")
Game.y=0.6;Game.cooldown=0;assert(Game.shoot()==3,"jump-height ray must hit elevated volume")
Game.reset_targets();reset()
local old1,old2=Game.targets[1].z,Game.targets[2].x
Game.targets[1].z=4.5;Game.targets[2].x=6.5
for i=3,#Game.targets do Game.targets[i].alive=false end
assert(Game.shoot()==1,"nearest XYZ volume first")
Game.targets[1].z=old1;Game.targets[2].x=old2
Game.reset_targets();reset();keys[BTN_F]=true
for _=1,60 do Game.step(1/60) end
keys={};Game.step(0);assert(Game.shots>=4 and Game.shots<=5 and Game.hits==1,"SNES Y shooting")
keys[BTN_G]=true;Game.step(0);assert(Game.hits==0 and Game.shots==0,"A rearms targets")
for _,fps in ipairs({10,15,30,60,120}) do
    reset(5.5,2.5);keys[UP]=true
    for _=1,fps do Game.step(1/fps) end
    assert(math.abs(Game.z-6.7)<0.00001,"frame-rate independent movement")
    reset(2,2.5);keys[LEFT]=true
    for _=1,fps*2 do Game.step(1/fps) end
    assert(Game.x>=1.18-0.00001,"solid 3D wall collision")
    reset(5.5,2.5);keys[BTN_Z]=true;local apex=0
    for _=1,fps*2 do Game.step(1/fps);apex=math.max(apex,Game.y) end
    assert(apex>0.93 and apex<0.99 and Game.y==0 and Game.grounded,"jump and floor landing")
    Game.step(1/fps);assert(Game.y==0,"B hold must not repeat jump")
    reset(6.6,10.75);keys[BTN_Z]=true;apex=0
    for _=1,fps do Game.step(1/fps);apex=math.max(apex,Game.y) end
    assert(apex>0.55 and apex<=0.60001,"overhead beam must stop the player's head")
    reset(12.3,8.25,0,-math.pi/2);keys[UP],keys[BTN_Z]=true,true
    local landed=false
    for i=1,fps*2 do Game.step(1/fps);if i>1 and Game.grounded and Game.y==0.55 then landed=true;break end end
    assert(landed,"jump must land on the raised 3D platform")
    keys={};for _=1,fps do Game.step(1/fps) end
    assert(Game.y==0.55,"platform top must support player")
end
reset();keys[BTN_Q]=true
for _=1,180 do Game.step(1/30);Game.draw();assert(Game.dropped==0) end
keys={};Game.step(0);local yaw=Game.yaw;Game.step(1/30);assert(Game.yaw==yaw,"L release")
keys[BTN_E]=true
for _=1,180 do Game.step(1/30);Game.draw();assert(Game.dropped==0) end
keys={};Game.step(0)
local maxTriangles=0
local viewCount=0
collectgarbage("collect");local baseline=collectgarbage("count");local start=os.clock()
for _,p in ipairs({{6.5,2.5},{1.5,2.5},{11.5,2.5},{3.5,10.8},{10.5,10.8},{9.7,8.25},{6.6,10.75}}) do
    Game.x,Game.z=p[1],p[2]
    for _,height in ipairs({0,0.97,1.522}) do
        Game.y=height
        for degree=-180,175,5 do
            Game.yaw=degree*math.pi/180;Game.draw()
            viewCount=viewCount+1
            assert(Game.triangles>0 and Game.dropped==0,"missing or overflowing 3D geometry")
            maxTriangles=math.max(maxTriangles,Game.triangles)
        end
    end
end
local elapsed=os.clock()-start
collectgarbage("collect");local retained=collectgarbage("count")
assert(retained<1024 and retained-baseline<32,"unexpected 3D heap growth")
reset();Game.reset_targets();capture=true;Game.draw();capture=false
local out=assert(io.open(".tools/frame.csv","w"));out:write(table.concat(commands,"\n"));out:close()
out=assert(io.open(".tools/palette.csv","w"));for i=0,31 do out:write(i,",",palette[i],"\n") end;out:close()
print(string.format("PASS: true XYZ perspective and native triangles; 3D shot occlusion/height, elevated targets, ceiling collision, platform landing, SNES controls and movement at 10/15/30/60/120 FPS\n%d camera views; Lua heap %.1f KiB; maximum %d native triangles/frame; local Lua %.3f ms/frame; no weapon sprites",viewCount,retained,maxTriangles,elapsed/viewCount*1000))
