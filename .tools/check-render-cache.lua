local cfg=require 'config';cfg.save_dir='.build/render-test-no-saves/'
ui=setmetatable({},{__index=function()return function()end end})
require 'game';local R=require 'renderer'
for id=1,15 do
 Game.startRace(id)
 for _,detail in ipairs({true,false,true})do
  Game.detail=detail;Game.draw()
  assert(R.cached_vertices>0 and R.cache_builds==0,'Unwarmed static projection cache')
  assert(R.dropped==0)
 end
end
local mesh=require('car').models[1].mesh
local obj={x=0,y=0,z=8,yaw=0,mesh=mesh}
local cam={x=0,y=2,z=0,yaw=0,pitch=-0.1}
R.begin(cam);R.prepare(obj,cam);R.begin(cam);R.submit(obj);assert(R.cache_builds==0)
obj.x=1;R.begin(cam);R.submit(obj);assert(R.cache_builds==0,'Translation must reuse local cache')
obj.yaw=0.2;R.begin(cam);R.submit(obj);assert(R.cache_builds==1,'Yaw must rebuild cache')
cam.yaw=0.3;R.begin(cam);R.submit(obj);assert(R.cache_builds==1,'Camera yaw must invalidate cache')
cam.pitch=-0.2;R.begin(cam);R.submit(obj);assert(R.cache_builds==1,'Camera pitch must invalidate cache')
obj.mesh=require('car').models[2].mesh;R.begin(cam);R.submit(obj);assert(R.cache_builds==1,'Changed mesh must have its own cache')
cfg.cache_static_geometry=false;R.begin(cam);R.submit(obj);assert(R.cached_vertices==0,'Disabled cache must use general projection');cfg.cache_static_geometry=true
local samples={}
for pass=1,3 do
 for id=1,15 do Game.startRace(id);Game.draw()end
 Game.startRace(5);Game.draw();collectgarbage('collect');samples[pass]=collectgarbage('count')
end
assert(samples[3]-samples[1]<16,'Cache retained old courses')
print('PASS: cache prewarming for 15 tracks/both detail modes, translation reuse, yaw/pitch/mesh invalidation, disabled fallback and bounded scene lifetime')
