local config = require "config"
local rgb = {
    {0,0,0}, {133,184,198}, {87,127,103}, {107,145,105},
    {181,164,124}, {199,183,143}, {110,78,55}, {63,111,75},
    {90,139,82}, {125,137,140}, {159,169,165}, {37,46,58},
    {180,194,198}, {215,224,214}, {53,99,132}, {245,237,210},
}
local palette = {}
for shade=0,1 do
    for _,c in ipairs(rgb) do
        local factor = shade==0 and 1 or 0.76
        local r=math.floor(c[1]*factor/255*31+0.5)
        local g=math.floor(c[2]*factor/255*31+0.5)
        local b=math.floor(c[3]*factor/255*31+0.5)
        palette[#palette+1] = config.platform=="hardware" and (r*1024+g*32+b) or (b*1024+g*32+r)
    end
end
return palette
