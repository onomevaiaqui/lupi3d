local cfg=require "config"
-- Cool concrete, warm targets and brighter upper faces. Same 32-entry budget.
local rgb={{0,0,0},{96,144,176},{55,70,76},{63,80,84},{104,125,132},{154,176,180},{63,121,143},{208,64,40},{248,176,48},{232,232,208},{16,28,40},{73,100,118},{176,200,208},{160,94,56},{112,168,72},{248,224,144}}
local M={palette={},index={}}
for shade=0,1 do for _,c in ipairs(rgb) do
    local factor=shade==0 and 1 or 0.78
    local r,g,b=math.floor(c[1]*factor/8),math.floor(c[2]*factor/8),math.floor(c[3]*factor/8)
    M.palette[#M.palette+1]=b*1024+g*32+r
    M.index[#M.palette-1]=#M.palette-1
end end
function M.register()
    for i,c in ipairs(M.palette) do
        if cfg.platform=="hardware" then c=(c%32)*1024+(math.floor(c/32)%32)*32+math.floor(c/1024)%32 end
        ui.palset(i-1,c)
    end
end
return M
