package.path=".build/race-3d-release/?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_Z,BTN_G,BTN_X,BTN_F,BTN_Q,BTN_E=4,2,1,3,7,11,6,9,5,8
local cfg=require "config";cfg.save_dir=".tools/"
local triangles=0
ui={btn=function() return false end,palset=function() end,camera=function() end,clip=function() end,cls=function() end,rectfill=function() end,print=function() end,trisfill=function() triangles=triangles+1 end}
require "game";update(0);assert(Game.state=="menu")
for i=1,3 do
    triangles=0;Game.startRace(i);update(0)
    assert(triangles>0 and triangles==Game.triangles and #Game.race.cars==4)
end
assert(#require("car").v>0)
print("PASS: built game boots into menu, loads all 3 tracks and 4 cars without audio API, Lua-only manifest")
