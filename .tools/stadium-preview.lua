-- Isometric inspection of the same stadium meshes, without gameplay camera culling.
local cfg=require "config";cfg.save_dir=".tools/"
local Race=require "race"
local G=require "geometry"
local R=require "renderer"
local S=require "stadium"
local id=tonumber(arg[1]) or 2
local race=Race.new(id);local T=race.track
local commands={"rect,0,0,480,270,10"}
ui={trisfill=function(...) commands[#commands+1]="tri,"..table.concat({...},",") end}
R.begin({x=-60,y=96,z=-72,yaw=math.atan(60,72),pitch=-math.atan(96/math.sqrt(60*60+72*72))})
local floor=G.mesh();G.quad(floor,{-55,-0.05,-46},{-55,-0.05,46},{55,-0.05,46},{55,-0.05,-46},14)
R.submit({x=0,y=0,z=0,mesh=floor});R.flush()
local function submit(o,mesh)
    R.submit({x=o.x,y=o.y or 0,z=o.z,yaw=o.yaw,mesh=mesh or o.mesh})
end
for _,p in ipairs(T.parts) do if not p.raised then submit(p);submit(p.trim) end end
R.flush()
for _,m in ipairs(T.markings) do if m.y<0.05 then submit(m) end end
submit(T.finish);R.flush()
for _,p in ipairs(T.parts) do if p.raised then submit(p);submit(p.trim);submit(p.bridge) end end
for _,m in ipairs(T.markings) do if m.y>=0.05 then submit(m) end end
for _,o in ipairs(T.decor) do submit(o) end
for _,o in ipairs(T.stadium) do submit(o) end
for _,o in ipairs(T.trees) do submit(o,S.tree) end
for _,o in ipairs(T.stadiumTrees) do submit(o) end
for _,o in ipairs(race.cars) do submit(o) end
R.flush()
assert(R.dropped==0,"overview triangle pool exhausted")
commands[#commands+1]="rect,0,0,480,20,10"
commands[#commands+1]="text,12,6,15,ESTADIO 6.0 / VISTA GERAL XYZ / "..R.triangles.." TRI"
local out=assert(io.open(".tools/view-stadium"..id..".csv","w"));out:write(table.concat(commands,"\n"));out:close()
print("Stadium overview "..id..": "..R.triangles.." triangles, no drops")
