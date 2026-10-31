package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local keys,palette,commands={},{},{}
local capture=false
local rectangles=0
local function record(...) if capture then commands[#commands+1]=table.concat({...},",") end end
ui={btn=function(k) return keys[k] or 0 end,
palset=function(i,c) assert(i>=0 and i<256 and c>=0 and c<32768);palette[i]=c end,
camera=function() end,clip=function() end,cls=function(c) record("rect",0,0,480,270,c) end,
rectfill=function(a,b,c,d,e)
    assert(a==math.floor(a) and b==math.floor(b) and c==math.floor(c) and d==math.floor(d))
    assert(a>=0 and c<=480 and b>=0 and d<=270 and a<c and b<d,"invalid native rectangle")
    assert(e>=0 and e<32);rectangles=rectangles+1;record("rect",a,b,c,d,e)
end,
print=function(s,x,y,c) record("text",x,y,c,s) end,
trisfill=function() error("FPS must not call the native triangle rasterizer") end}
local level=require "level"
require "game"
local function reset(x,z)
    keys={};Game.x,Game.z,Game.y,Game.vy,Game.yaw=x or level.spawn.x,z or level.spawn.z,0,0,0
    Game.grounded=true;Game.phase=0;Game.step(0)
end
for _,row in ipairs(level.rows) do assert(#row==level.width) end
assert(level.free(Game.x,Game.z,0.18),"spawn inside a wall")
for _,t in ipairs(Game.targets) do assert(level.free(t.x,t.z,0.42),"target inside wall") end
assert(math.abs(Game.raycast(Game.x,Game.z,0,1)-5.5)<0.00001,"forward DDA distance")
assert(Game.shoot()==1 and Game.hits==1 and not Game.targets[1].alive,"initial target hit")
assert(Game.shoot()==0 and Game.shots==1,"shot cooldown")
Game.cooldown=0;Game.yaw=math.pi/2;assert(Game.shoot()==0,"off-axis shot should miss")
Game.reset_targets();Game.yaw=0
for i,t in ipairs(Game.targets) do t.alive=i==6 end
assert(Game.shoot()==0 and Game.targets[6].alive,"shot must not cross a wall")
Game.flash=0;Game.targets[6].alive=false;Game.draw();local emptyCalls=Game.draw_calls
Game.targets[6].alive=true;Game.draw()
assert(Game.draw_calls==emptyCalls,"occluded target must not be drawn through the wall")
Game.reset_targets()
Game.targets[1].x,Game.targets[1].z=6.5,4.5
Game.targets[2].x,Game.targets[2].z=6.5,6.5
for i=3,#Game.targets do Game.targets[i].alive=false end
assert(Game.shoot()==1,"nearest target first")
Game.cooldown=0;assert(Game.shoot()==2,"second target after near target is removed")
for i,p in ipairs(level.targets) do Game.targets[i].x,Game.targets[i].z=p[1],p[2] end
Game.reset_targets();reset()
keys[BTN_F]=true
for _=1,60 do Game.step(1/60) end
keys={};Game.step(0)
assert(Game.shots>=4 and Game.shots<=5 and Game.hits==1,"SNES Y automatic fire / rate limit")
keys[BTN_G]=true;Game.step(0);assert(Game.shots==0 and Game.hits==0,"SNES A resets targets")
for _,fps in ipairs({10,15,30,60,120}) do
    reset();keys[UP]=true
    for _=1,fps do Game.step(1/fps) end
    assert(math.abs(Game.z-(level.spawn.z+4.2))<0.00001,"FPS-independent forward movement")
    for _=1,fps*2 do Game.step(1/fps) end
    assert(Game.z<8 and level.free(Game.x,Game.z,0.18),"wall collision / no tunneling")
    reset();keys[BTN_Z]=true;local apex=0
    for _=1,fps*2 do Game.step(1/fps);apex=math.max(apex,Game.y) end
    assert(apex>0.93 and apex<0.99 and Game.y==0 and Game.grounded,"jump height and landing")
    Game.step(1/fps);assert(Game.y==0,"holding B must not repeat jump")
end
reset();keys[UP],keys[RIGHT]=true,true;Game.step(1/60)
assert(math.abs(math.sqrt((Game.x-level.spawn.x)^2+(Game.z-level.spawn.z)^2)-0.07)<0.00001,"diagonal speed")
reset();keys[BTN_Q]=true
for _=1,300 do Game.step(1/30);Game.draw() end
keys={};Game.step(0);local yaw=Game.yaw;Game.step(1/30);assert(Game.yaw==yaw,"L release")
keys[BTN_E]=true
for _=1,300 do Game.step(1/30);Game.draw() end
keys={};Game.step(0)
local maxCalls=0
collectgarbage("collect");local base=collectgarbage("count");local start=os.clock()
for _,p in ipairs({{6.5,2.5},{1.5,2.5},{11.5,2.5},{4.5,10.5},{10.5,10.5}}) do
    Game.x,Game.z=p[1],p[2]
    for _,height in ipairs({0,0.97}) do
        Game.y=height
        for degree=-180,175,5 do
            Game.yaw=degree*math.pi/180;Game.draw();maxCalls=math.max(maxCalls,Game.draw_calls)
        end
    end
end
local elapsed=os.clock()-start
collectgarbage("collect");local retained=collectgarbage("count")
assert(retained<512 and retained-base<16,"unexpected FPS heap growth")
reset();Game.reset_targets();capture=true;Game.draw();capture=false
local fallbackCalls=Game.draw_calls
local out=assert(io.open(".tools/frame.csv","w"));out:write(table.concat(commands,"\n"));out:close()
out=assert(io.open(".tools/palette.csv","w"));for i=0,31 do out:write(i,",",palette[i],"\n") end;out:close()
-- Exercise the native sprite route and the codec's potentially reordered palette.
local own=require("colors").palette
package.loaded.main=nil;package.loaded.colors=nil;package.loaded.palette=nil
package.preload.palette=function() Palette={};for i=1,#own do Palette[i]=own[#own+1-i] end;return Palette end
package.preload.sprites=function() Sprites={img={gun={path="img/gun",width=72,height=96}}};return Sprites end
local spriteCalls=0
ui.spr=function(s,x,y) assert(s.width==72 and s.height==96);spriteCalls=spriteCalls+1 end
require "main"
assert(Game.native_weapon and require("colors").native,"native weapon / generated palette route not active")
for i,c in ipairs(own) do assert(Palette[require("colors").index[i-1]+1]==c,"palette remapping mismatch") end
Game.draw();assert(spriteCalls==1 and Game.draw_calls<=fallbackCalls-140,"native sprite must replace rectangle fallback")
print(string.format("PASS: map, bounded DDA, hits/misses, wall occlusion, nearest target, Y fire, A reset, L/R holds, B jump and collision at 10/15/30/60/120 FPS; zero native triangles\nLua heap %.1f KiB; max fallback draw calls %d; native spawn draw calls %d; local Lua %.3f ms/frame",retained,maxCalls,Game.draw_calls,elapsed/720*1000))
