-- Close-up preview from the actual game mesh and renderer.
local m=require "car"
local isRival=arg[1]=="rival"
local R=require "renderer"
local commands={"rect,0,0,480,270,14"}
ui={trisfill=function(...) commands[#commands+1]="tri,"..table.concat({...},",") end}
local camera={x=-3,y=2.4,z=-4,yaw=math.atan(3,4),pitch=-math.atan(2/5)}
R.begin(camera);R.submit({x=0,y=0,z=0,mesh=isRival and m.rival or m});R.flush()
commands[#commands+1]="rect,0,0,480,20,10"
commands[#commands+1]="text,12,6,15,"..(isRival and "ADVERSARIO / 32 TRIANGULOS" or "FUSQUINHA / 82 TRIANGULOS")
commands[#commands+1]="rect,0,228,480,270,10"
commands[#commands+1]="text,12,240,9,MALHA XYZ REAL / SEM SOMBRA NO SOLO"
local name=isRival and "view-rival" or "view-car"
local f=assert(io.open(".tools/"..name..".csv","w"));f:write(table.concat(commands,"\n"));f:close()
