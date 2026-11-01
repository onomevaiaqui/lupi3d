-- Emulate the firmware's custom require with no public package/IO/GC libraries.
local loader=loadfile
local loaded={}
require=function(name)
    if loaded[name]~=nil then return loaded[name] end
    local chunk=assert(loader(".build/race-3d-release/"..name..".lua"))
    local result=chunk();if result==nil then result=true end
    loaded[name]=result;return result
end
package=nil;io=nil;os=nil;debug=nil;collectgarbage=nil;sfx=nil;music=nil
LEFT,RIGHT,UP,DOWN,BTN_Z,BTN_G,BTN_X,BTN_F,BTN_Q,BTN_E=4,2,1,3,7,11,6,9,5,8
local keys={};local triangles=0
ui={btn=function(k) return keys[k] or false end,palset=function() end,camera=function() end,clip=function() end,cls=function() end,rectfill=function() end,print=function() end,trisfill=function() triangles=triangles+1 end}
require "game";update(0);assert(Game.state=="menu")
keys={[BTN_Z]=true};Game.step(0);assert(Game.state=="select")
assert(require("save").status=="SAVE INDISPONIVEL")
keys={};Game.step(0)
for i=1,3 do
    triangles=0;Game.startRace(i);update(0)
    assert(triangles>0 and #Game.race.cars==4)
    Game.race.finished=true;Game.race.place=1;Game.result();Game.draw()
end
assert(require("save").wins()==3 and require("save").canContinue())
Game.state="menu";Game.menu=2;keys={[BTN_Z]=true};Game.step(0)
assert(Game.state=="select","in-session Continue works even when disk save unavailable")
print("PASS: restricted firmware loader without package/io/os/debug/collectgarbage/sfx: boot, New Game, 3 tracks, results and session Continue")
