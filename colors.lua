local cfg=require "config"
local rgb={{0,0,0},{23,28,38},{48,48,42},{62,62,51},{105,106,102},{146,148,137},{63,94,102},{172,48,42},{232,180,63},{224,216,182},{44,48,52},{91,100,104},{156,165,161},{125,87,64},{124,156,58},{240,208,103}}
local M={palette={},index={}}
for shade=0,1 do for _,c in ipairs(rgb) do
    local factor=shade==0 and 1 or 0.68
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
