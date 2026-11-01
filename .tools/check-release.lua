package.path=".build/race-3d-release/?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_Z,BTN_G,BTN_X=4,2,1,3,7,11,6
local triangles=0
ui={btn=function() return false end,palset=function() end,camera=function() end,clip=function() end,cls=function() end,rectfill=function() end,print=function() end,trisfill=function() triangles=triangles+1 end}
require "game";update(0)
assert(triangles>0 and triangles==Game.triangles)
assert(#require("car").v>0 and require("track").segments==24)
print("PASS: built race loads XYZ track and car, "..triangles.." native triangles at start")
