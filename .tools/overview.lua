-- Top-down verification of the actual XYZ track geometry (not a map substitute).
local id=tonumber(arg[1]) or 2
local T=require("track").new(id)
local R=require "renderer"
local colors=require "colors"
local commands={}
ui={trisfill=function(...) commands[#commands+1]="tri,"..table.concat({...},",") end}
commands[1]="rect,0,0,480,270,14"
R.begin({x=0,y=105,z=0,yaw=0,pitch=-math.pi/2})
for _,p in ipairs(T.parts) do
    p.radius=nil;p.trim.radius=nil;R.submit(p);R.submit(p.trim)
end
R.flush();T.finish.radius=nil;R.submit(T.finish);R.flush()
for _,t in ipairs(T.trees) do t.radius=nil;R.submit(t) end
R.flush()
commands[#commands+1]="text,12,6,9,"..T.name.." / "..math.floor(T.length).." UNIDADES / 3D XYZ"
local out=assert(io.open(".tools/view-track"..id..".csv","w"));out:write(table.concat(commands,"\n"));out:close()
