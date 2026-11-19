-- Desktop Lua CPU only: native rasterizer time and real console FPS are excluded.
package.path=(arg[1] or '.')..'/?.lua;'..package.path
local cfg=require 'config';cfg.save_dir='.build/benchmark-no-saves/';cfg.stagger_ai_decisions=false
ui=setmetatable({},{__index=function()return function()end end})
require 'game';local Race=require 'race';local R=require 'renderer'
local times={}
for trial=1,5 do
 collectgarbage('collect');local start=os.clock()
 for run=1,30 do
  math.randomseed(run);local r=Race.new(8,1,{1,1,1},'TESTE');r.countdown=0
  local input={gas=true,brake=false,steer=0}
  for i=1,400 do
   input.brake=i%90<8;input.steer=i%200<100 and 0.35 or -0.35
   Race.step(r,0.025,input)
  end
 end
 times[trial]=os.clock()-start
end
table.sort(times);local physics=times[3]
local draws={};local vertices,triangles,early=0,0,0
for trial=1,5 do
 math.randomseed(91);Game.startRace(8);Game.draw();collectgarbage('collect')
 local start=os.clock()
 for frame=1,1800 do Game.draw()end
 draws[trial]=os.clock()-start
 vertices,triangles,early=R.vertices,R.triangles,R.early_rejected or 0
end
table.sort(draws)
print(string.format('median_physics_seconds=%.3f median_draw_seconds=%.3f vertices=%d triangles=%d early_rejected=%d',physics,draws[3],vertices,triangles,early))
