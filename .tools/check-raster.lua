-- Validate the integer triangles that reach the native rasterizer.
package.path="./?.lua;"..package.path
local bad,thin,negative,total=0,0,0,0
local degrees=0
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
trisfill=function(ax,ay,bx,by,cx,cy)
    assert(ax>=0 and ax<=479 and bx>=0 and bx<=479 and cx>=0 and cx<=479,"raster X outside viewport")
    assert(ay>=20 and ay<=246 and by>=20 and by<=246 and cy>=20 and cy<=246,"raster Y outside viewport")
    local width=math.max(ax,bx,cx)-math.min(ax,bx,cx)
    local height=math.max(ay,by,cy)-math.min(ay,by,cy)
    assert(width<=160 and height<=128 and width*height<=16384,"native triangle exceeds edge budget")
    total=total+1
    local cross=(bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
    if cross==0 then
        bad=bad+1
        if bad<=8 then print(string.format("DEGENERATE yaw=%.3f: (%d,%d) (%d,%d) (%d,%d)",degrees,ax,ay,bx,by,cx,cy)) end
    elseif cross<0 then negative=negative+1 end
    if math.abs(cross)<=2 then thin=thin+1 end
end}
require "main"
Game.profile_mode=1
for _,sign in ipairs({-1,1}) do
    for angle=1,900 do
        degrees=sign*angle/10
        Game.yaw=(degrees*math.pi/180)%(math.pi*2)
        Game.draw()
        assert(Game.dropped==0,"native subdivision exceeds triangle pool")
    end
end
for _,position in ipairs({{0,0},{-7,-7},{7,-7},{7,7},{-7,7}}) do
    Game.x,Game.z=position[1],position[2]
    for _,height in ipairs({0,0.55,1.522}) do
        Game.y=height
        for angle=0,359 do
            degrees=angle
            Game.yaw=angle*math.pi/180
            Game.draw()
            assert(Game.dropped==0,"native subdivision exceeds triangle pool")
        end
    end
end
print(string.format("Native integer triangles: %d; zero-area: %d; inverted: %d; tiny: %d",total,bad,negative,thin))
assert(bad==0 and negative==0,"degenerate/inverted triangles reach the native rasterizer")
