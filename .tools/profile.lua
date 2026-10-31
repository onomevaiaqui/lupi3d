-- Geometry workload only: projected triangle area estimates rasterizer work,
-- including pixels rejected by fb_set after the native scanline loop visits them.
package.path="./?.lua;"..package.path
LEFT,RIGHT,UP,DOWN,BTN_F,BTN_G,BTN_Q,BTN_E=4,2,1,3,9,11,5,8
local tri,area,maxcoord=0,0,0
ui={btn=function() return false end,palset=function() end,camera=function() end,
clip=function() end,cls=function() end,rectfill=function() end,print=function() end,
trisfill=function(ax,ay,bx,by,cx,cy,color)
    assert(ax>=0 and ax<=479 and bx>=0 and bx<=479 and cx>=0 and cx<=479,"unclipped raster X")
    assert(ay>=20 and ay<=246 and by>=20 and by<=246 and cy>=20 and cy<=246,"unclipped raster Y")
    tri=tri+1
    area=area+math.abs((bx-ax)*(cy-ay)-(by-ay)*(cx-ax))/2
    maxcoord=math.max(maxcoord,math.abs(ax),math.abs(ay),math.abs(bx),math.abs(by),math.abs(cx),math.abs(cy))
end}
require "game"
local maxtri,maxarea,worstx,worstz,worstyaw=0,0,0,0,0
local start=os.clock()
for _,p in ipairs({{0,0},{-7,-7},{7,-7},{7,7},{-7,7}}) do
    Game.x,Game.z=p[1],p[2]
    for degrees=0,355,5 do
        Game.yaw=degrees*math.pi/180
        tri,area=0,0
        Game.draw()
        maxtri=math.max(maxtri,tri)
        if area>maxarea then maxarea,worstx,worstz,worstyaw=area,p[1],p[2],degrees end
    end
end
print(string.format("max_triangles=%d; max_projected_area=%.0f px; max_absolute_coordinate=%d; worst=(%d,%d,%d deg); Lua %.3f ms/frame",maxtri,maxarea,maxcoord,worstx,worstz,worstyaw,(os.clock()-start)/360*1000))
