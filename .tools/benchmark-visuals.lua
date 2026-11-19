-- Optional module directory allows comparison with a preserved checkout.
package.path=(arg[1] or '.')..'/?.lua;'..package.path
require('config').save_dir='.build/benchmark-no-saves/'
local capture=false;local area=0
ui=setmetatable({trisfill=function(ax,ay,bx,by,cx,cy)if capture then area=area+math.abs((bx-ax)*(cy-ay)-(by-ay)*(cx-ax))/2 end end},{__index=function()return function()end end})
require 'game'
local function scene(id,view)
 math.randomseed(91);Game.startRace(id);local r=Game.race
 if view>0 then
  for j,c in ipairs(r.cars)do
   local progress=view*r.track.segments/3+(j-1)*0.45
   local x,z,yaw,_,y=r.track.sample(progress);local lane=((j-1)%3-1)*2.5
   c.x,c.z,c.y,c.yaw=x+math.cos(yaw)*lane,z-math.sin(yaw)*lane,y,yaw
   if view==2 and j>1 then c.respawn=1 end
  end
  r.countdown=0;r.time=4
 end
end
local totals={triangles=0,vertices=0,dropped=0,max=0}
capture=true
for id=1,15 do for view=0,2 do
 scene(id,view);Game.draw();local R=require 'renderer'
 totals.triangles=totals.triangles+R.triangles;totals.vertices=totals.vertices+R.vertices
 totals.dropped=totals.dropped+R.dropped;totals.max=math.max(totals.max,R.triangles)
end end
capture=false
local times={}
for trial=1,3 do
 scene(5,0);collectgarbage('collect');local now=os.clock();for i=1,1800 do Game.draw()end;times[trial]=os.clock()-now
end
table.sort(times)
print(string.format('triangles=%d vertices=%d projected_area=%d dropped=%d max_per_view=%d median_draw_seconds=%.3f',totals.triangles,totals.vertices,math.floor(area),totals.dropped,totals.max,times[2]))
