local G=require 'geometry';local colors=require 'colors';local models=require('car').models
local tracks=require 'track';local S=require 'scenery'
assert(#colors.palette==36)
local function valid(mesh)
 assert(#mesh.v%3==0 and #mesh.f%4==0)
 for _,n in ipairs(mesh.v)do assert(n==n and math.abs(n)<1000)end
 for i=1,#mesh.f,4 do
  for j=0,2 do local v=mesh.f[i+j];assert(v>=1 and v<=#mesh.v/3 and v%1==0)end
  assert(mesh.f[i+3]>=0 and mesh.f[i+3]<#colors.palette)
 end
end
local expected={82,86,94,104,100,158}
for i,m in ipairs(models)do valid(m.mesh);assert(#m.mesh.f/4==expected[i],'Car polygon budget changed')end
assert(S.tree~=S.broadleaf and S.broadleaf~=S.palm and S.scrub~=S.broadleaf)
for _,mesh in ipairs({S.tree,S.broadleaf,S.palm,S.scrub})do valid(mesh);assert(#mesh.f/4<=20)end
local limits={12,8,12,10,12,11,12,11,12,12,12,12,12,12,12}
for id=1,15 do
 local t=tracks.new(id);assert(#t.decor<=limits[id] and #t.trees<=6)
 assert(t.theme[2]==2 and t.theme[4]==7)
 for _,p in ipairs(t.parts)do valid(p.mesh);valid(p.trim.mesh)end
 for _,p in ipairs(t.markings)do valid(p.mesh)end
 for _,p in ipairs(t.decor)do
  valid(p.mesh);local _,d=t.locate(p.x,p.z);assert(d>(t.halfWidth+2)^2)
 end
 for _,p in ipairs(t.trees)do valid(p.basic);valid(p.detailMesh)end
 valid(t.finish.mesh)
end
-- Exercise all courses, both detail modes, with six cars near the camera.
local triangles=0
ui=setmetatable({trisfill=function()triangles=triangles+1 end},{__index=function()return function()end end})
require 'game'
for id=1,15 do for _,detail in ipairs({true,false})do
 Game.detail=detail;Game.startRace(id);Game.race.countdown=0
 for view=0,2 do
  for i,c in ipairs(Game.race.cars)do
   local progress=view*Game.race.track.segments/3+(i-1)*0.35
   c.x,c.z,c.yaw,_,c.y=Game.race.track.sample(progress)
  end
  Game.draw();assert(Game.dropped==0,'Triangle pool overflow')
 end
end end
assert(triangles>0)
print('PASS: 36-color materials, original car polygon budgets, country vegetation, roadside placement and object limits, 90 six-car views in both detail modes, no triangle drops')
