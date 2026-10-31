package.path=".build/fps-release/?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E,BTN_Z,BTN_X=4,2,1,3,9,11,5,8,7,6
local spriteCalls=0
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
spr=function(s,x,y)
    local file=assert(io.open(s.path,"rb"));local data=file:read("*a");file:close()
    assert(#data==s.width*s.height)
    for i=1,#data do assert(data:byte(i)<#Palette,"bitmap index outside palette") end
    spriteCalls=spriteCalls+1
end}
package.preload.sprites=function()
    Sprites={img={gun={path=".build/fps-release/img/gun",width=72,height=96}}};return Sprites
end
require "game"
assert(Game.native_weapon,"built game must use native weapon sprite")
update(0);assert(spriteCalls==1)
print("PASS: built release loads game.lua, generated palette and native weapon bitmap")
