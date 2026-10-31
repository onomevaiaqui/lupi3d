local cfg=require "config"
local rgb={{0,0,0},{23,28,38},{48,48,42},{62,62,51},{105,106,102},{146,148,137},{63,94,102},{172,48,42},{232,180,63},{224,216,182},{44,48,52},{91,100,104},{156,165,161},{125,87,64},{124,156,58},{240,208,103}}
local M={palette={},index={},native=false}
local wanted={}
for shade=0,1 do for _,c in ipairs(rgb) do
    local factor=shade==0 and 1 or 0.68
    local r,g,b=math.floor(c[1]*factor/8),math.floor(c[2]*factor/8),math.floor(c[3]*factor/8)
    M.palette[#M.palette+1]=b*1024+g*32+r
    wanted[#M.palette]={math.floor(c[1]*factor),math.floor(c[2]*factor),math.floor(c[3]*factor)}
    M.index[#M.palette-1]=#M.palette-1
end end
-- The official codec may reorder colors. Resolve indices by BGR555 value,
-- sharing its palette with the native gun sprite rather than overwriting it.
local ok=pcall(require,"palette")
if ok and type(Palette)=="table" and #Palette>=8 and #Palette<=256 then
    local lookup,indices={},{}
    for i=1,#Palette do lookup[Palette[i]]=i-1 end
    for i=1,#M.palette do
        indices[i-1]=lookup[M.palette[i]]
        if indices[i-1]==nil then
            -- ImageMagick's depth-5 conversion may round a channel upward.
            -- Find the nearest generated color rather than disabling the sprite.
            local best,bestDistance=0,math.huge
            for j,p in ipairs(Palette) do
                local r,g,b=p%32,math.floor(p/32)%32,math.floor(p/1024)%32
                r=r*8+math.floor(r/4);g=g*8+math.floor(g/4);b=b*8+math.floor(b/4)
                local c=wanted[i]
                local distance=(r-c[1])^2+(g-c[2])^2+(b-c[3])^2
                if distance<bestDistance then best,bestDistance=j-1,distance end
            end
            indices[i-1]=best
        end
    end
    M.palette=Palette;M.index=indices;M.native=true
end
function M.register()
    for i,c in ipairs(M.palette) do
        if cfg.platform=="hardware" then c=(c%32)*1024+(math.floor(c/32)%32)*32+math.floor(c/1024)%32 end
        ui.palset(i-1,c)
    end
end
return M
