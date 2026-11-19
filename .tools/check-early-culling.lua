local cfg=require 'config'
local commands
ui={trisfill=function(...)commands[#commands+1]=table.concat({...},',')end}
local R=require 'renderer'
local meshes={}
for _,m in ipairs(require('car').models)do meshes[#meshes+1]=m.mesh end
local S=require 'scenery'
for _,mesh in ipairs({S.tree,S.blockBirch,S.blockCabin,S.house,S.flame,S.blast})do meshes[#meshes+1]=mesh end
local camera={x=0,y=0,z=0,yaw=0,pitch=0}
local function draw(obj,cached,culling)
 cfg.cache_static_geometry=cached;cfg.early_culling=culling
 commands={};R.begin(camera)
 if cached then R.prepare(obj,camera) end
 R.submit(obj);R.flush();assert(R.dropped==0)
 return table.concat(commands,';'),R.early_rejected,R.vertices
end
math.randomseed(138)
local rejections=0
for i=1,4000 do
 camera.x,camera.y,camera.z=math.random()*8-4,math.random()*5,math.random()*8-4
 camera.yaw,camera.pitch=math.random()*6.28-3.14,math.random()*2-1
 local obj={x=math.random()*90-45,y=math.random()*30-15,z=math.random()*90-45,
  yaw=math.random()*6.28,mesh=meshes[(i-1)%#meshes+1]}
 for _,cached in ipairs({false,true}) do
  local expected=draw(obj,cached,false)
  local actual,rejected,vertices=draw(obj,cached,true)
  assert(expected==actual,'Culling changed clipped triangles at sample '..i)
  if rejected>0 then assert(vertices==0);rejections=rejections+1 end
 end
end
assert(rejections>1000)
print('PASS: 8000 randomized cached/dynamic views, identical clipped triangles with culling on/off; '..rejections..' objects rejected before vertex projection')
