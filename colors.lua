local cfg=require "config"
-- Shared material palette: neutral asphalt, vivid paint, dark glass and warm earth.
-- Preserve the original 32 indices; four terrain/foliage colors avoid camouflage.
local rgb={{8,11,16},{72,160,208},{43,47,55},{51,55,63},{144,153,160},{192,201,208},{40,132,176},{224,56,40},{248,184,32},{240,239,220},{16,24,40},{112,119,120},{192,208,216},{168,116,64},{88,148,56},{248,216,152}}
local M={palette={},index={}}
for shade=0,1 do for _,c in ipairs(rgb) do
    local factor=shade==0 and 1 or 0.84
    local r,g,b=math.floor(c[1]*factor/8),math.floor(c[2]*factor/8),math.floor(c[3]*factor/8)
    M.palette[#M.palette+1]=b*1024+g*32+r
    M.index[#M.palette-1]=#M.palette-1
end end
for _,c in ipairs({{112,152,72},{30,86,44},{60,126,68},{158,155,93}}) do
    local r,g,b=math.floor(c[1]/8),math.floor(c[2]/8),math.floor(c[3]/8)
    M.palette[#M.palette+1]=b*1024+g*32+r
    M.index[#M.palette-1]=#M.palette-1
end
function M.register()
    for i,c in ipairs(M.palette) do
        if cfg.platform=="hardware" then c=(c%32)*1024+(math.floor(c/32)%32)*32+math.floor(c/1024)%32 end
        ui.palset(i-1,c)
    end
end
return M
