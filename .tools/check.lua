-- Run from repository root: lua .tools/check.lua
package.path="./?.lua;"..package.path
local yaml=assert(io.open("lupi.yaml","r"),"lupi.yaml must be at repository root")
local metadata=yaml:read("*a"); yaml:close()
assert(metadata:match("public:%s*true"),"game must be public")
local entry=assert(io.open("game.lua","r"),"game.lua must be at repository root"); entry:close()
LEFT,RIGHT,UP,DOWN=4,2,1,3
BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z=9,11,5,8,7
local keys,palette,commands={},{},{}
local capture=false
local function record(...)
    if capture then commands[#commands+1]=table.concat({...},",") end
end
local function finite(n) assert(type(n)=="number" and n==n and math.abs(n)<1000000,"invalid coordinate") end
ui={
    btn=function(k) return keys[k] or 0 end, -- tests numeric zero as released
    palset=function(i,c) assert(i>=0 and i<256 and c>=0 and c<32768);palette[i]=c end,
    camera=function() end,clip=function() end,
    cls=function(c) record("rect",0,0,480,270,c) end,
    rectfill=function(a,b,c,d,e) record("rect",a,b,c,d,e) end,
    print=function(s,x,y,c) record("text",x,y,c,s) end,
    trisfill=function(a,b,c,d,e,f,g)
        for _,n in ipairs({a,b,c,d,e,f}) do finite(n) end
        assert(a>=0 and a<=479 and c>=0 and c<=479 and e>=0 and e<=479,"unclipped X reaches native rasterizer")
        assert(b>=20 and b<=246 and d>=20 and d<=246 and f>=20 and f<=246,"unclipped Y reaches native rasterizer")
        assert(g>=0 and g<32)
        record("tri",a,b,c,d,e,f,g)
    end,
}
require "game"
local function step(n) for _=1,n do update() end end
local start=collectgarbage("count")
step(1); assert(Game.x==0 and Game.z==0,"released input moves player")
Game.x,Game.z=1.8,-5
keys[UP]=true; step(60); keys={}
assert(math.abs(Game.z+0.8)<0.0001 and Game.moving,"forward movement")
keys[DOWN]=255; step(60); keys={}
assert(math.abs(Game.z+5)<0.0001,"backward movement")
Game.x,Game.z=0,-5
keys[UP],keys[RIGHT]=true,true; step(1); keys={}
assert(math.abs(math.sqrt(Game.x^2+(Game.z+5)^2)-0.070)<0.0001,"diagonal normalization")
Game.x,Game.z=0,0
keys[BTN_E]=true; step(63); keys={}
assert(Game.yaw>1.5 and Game.yaw<1.6,"R shoulder camera")
keys[UP]=true; step(20); keys={}
assert(Game.x>0.65,"camera-relative forward")
local yaw=Game.yaw
keys[BTN_Q]=true; step(20); keys={}; assert(Game.yaw<yaw,"L shoulder camera")
Game.x,Game.z,Game.yaw=0,0,0
keys[DOWN]=true; step(500); keys={}
assert(Game.z>=-7 and Game.z< -6.9,"arena boundary")
Game.x,Game.z,Game.yaw=3.2,-2,0
keys[UP]=true; step(120); keys={}
assert(Game.z<-1,"rock collision")
-- Exercise the emulator mapping independently from the default SNES controls.
local config=require "config"
config.controller="lupinho"
keys[BTN_G]=true; local before=Game.yaw; step(1); keys={}
assert(Game.yaw>before,"emulator R shoulder")
keys[BTN_F]=true; step(1); keys={}
assert(math.abs(Game.yaw-before)<0.0001,"emulator L shoulder")
config.controller="snes"
-- Equal real-time displacement and camera rotation at different update rates.
for _,fps in ipairs({10,15,30,60,120}) do
    Game.x,Game.z,Game.yaw,Game.phase=0,-5,0,0
    keys[UP]=true
    for _=1,fps do Game.step(1/fps) end
    keys={}
    assert(math.abs(Game.z+0.8)<0.0001,"time-based walking varies with FPS")
    Game.x,Game.z,Game.yaw=0,0,0
    keys[BTN_E]=true
    for _=1,fps do Game.step(1/fps) end
    keys={}
    assert(math.abs(Game.yaw-1.5)<0.0001,"time-based camera varies with FPS")
end
ui.stat=function(option) assert(option==7); return 30 end
for _=1,15 do Game.step() end
Game.x,Game.z,Game.yaw=0,-5,0
keys[UP]=true
for _=1,30 do Game.step() end
keys={}
assert(math.abs(Game.z+0.8)<0.0001,"FPS stat is not used for movement")
ui.stat=function() error("unsupported statistic") end
for _=1,15 do Game.step() end
assert(Game.fps==60,"unsupported FPS stat must fall back safely")
ui.stat=nil
-- Diagnostic input: one transition per press; BASE submits no triangles.
for mode=1,4 do
    keys[BTN_F]=true
    Game.step(); Game.step()
    assert(Game.profile_mode==mode%4,"profile button must trigger once per press")
    assert(Game.y==0,"SNES Y profile input must not trigger a jump")
    keys={}; Game.step(); Game.draw()
    if mode==3 then assert(Game.triangles==0,"BASE mode must not draw geometry")
    else assert(Game.triangles>0,"diagnostic mode unexpectedly blank") end
end
-- Walk through full gait cycles while viewing every side of the articulated mesh.
for direction=0,7 do
    for pose=0,15 do
        Game.yaw=direction*math.pi/4
        Game.facing=(7-direction)*math.pi/4
        Game.phase=pose*math.pi/8
        Game.draw()
        assert(Game.dropped==0,"walking pose exceeds triangle pool")
        assert(Game.culled>0,"backface culling is inactive")
        assert(Game.triangles<500,"scene exceeds optimized draw budget")
    end
end
-- Camera near objects and arena corners: near-plane clipping must remain finite.
for _,p in ipairs({{-7,-7},{7,-7},{7,7},{-7,7},{3.2,1.1}}) do
    Game.x,Game.z=p[1],p[2]
    for angle=0,350,10 do
        Game.yaw=angle*math.pi/180; update()
        assert(Game.dropped==0,"clipped geometry exceeds pool")
    end
end
Game.x,Game.z,Game.yaw=0,0,0
collectgarbage("collect")
local base=collectgarbage("count")
local peak,maxtris=base,0
local t=os.clock()
for i=1,360 do
    Game.yaw=i*math.pi/180
    update()
    assert(Game.dropped==0,"triangle capacity exceeded")
    maxtris=math.max(maxtris,Game.triangles)
    peak=math.max(peak,collectgarbage("count"))
end
local elapsed=os.clock()-t
collectgarbage("collect")
local final=collectgarbage("count")
assert(final<1024,"Lua heap exceeds 1 MiB budget")
assert(final-base<32,"persistent heap growth")
print(string.format("PASS: movement, diagonals, shoulders, collision, boundary, viewport clipping, 10/15/30/60/120 Hz timing, FPS API fallback, profile modes, 360 camera angles, 128 gait/view combinations\nLua heap %.1f KiB; observed peak %.1f KiB; retained growth %.1f KiB\nMax triangles/frame %d; desktop Lua %.2f ms/frame (not hardware timing)",final,peak,final-base,maxtris,elapsed/360*1000))
Game.x,Game.z,Game.yaw=0,0,0
capture=true; update(); capture=false
local out=assert(io.open(".tools/frame.csv","w"));out:write(table.concat(commands,"\n"));out:close()
out=assert(io.open(".tools/palette.csv","w"))
for i=0,31 do out:write(i,",",palette[i],"\n") end; out:close()
if arg[1]=="views" then
    for i=0,7 do
        Game.x,Game.z,Game.yaw,Game.facing=0,0,i*math.pi/4,0
        Game.phase=math.pi/2
        commands={}; capture=true; Game.draw(); capture=false
        out=assert(io.open(".tools/view"..i..".csv","w"));out:write(table.concat(commands,"\n"));out:close()
    end
end
if arg[1]=="jump_views" then
    for _,scene in ipairs({{"jump",0,1.0,0.9},{"platform",0,3.2,0.55}}) do
        Game.x,Game.z,Game.y,Game.yaw,Game.facing,Game.phase=scene[2],scene[3],scene[4],0,0,0
        commands={};capture=true;Game.draw();capture=false
        out=assert(io.open(".tools/"..scene[1]..".csv","w"));out:write(table.concat(commands,"\n"));out:close()
    end
end
