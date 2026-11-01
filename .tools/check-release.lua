package.path=".build/fps-3d-release/?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local triangles=0
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
spr=function() error("weapon must be 3D") end,
trisfill=function() triangles=triangles+1 end}
require "game"
update(0)
assert(triangles>0 and triangles==Game.triangles)
assert(#require("gun").v>0 and #require("geometry").box(1,1,1,1,2,3).f==48)
print("PASS: built 3D game loads all geometry and renders "..triangles.." native triangles without sprites")
