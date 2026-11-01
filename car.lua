-- Original low-poly compact car inspired by the classic Beetle silhouette.
local G=require "geometry"
local m=G.mesh()
local function box(w,h,d,x,y,z,f,s,t) G.append(m,G.box(w,h,d,f,s,t),x,y,z) end
box(1.25,0.38,2.35,0,0.52,0,8,24,15)
box(1.08,0.18,0.66,0,0.76,0.77,8,24,15)
-- Rounded cabin: connected cross sections make a faceted curved roof.
local sections={{-0.94,0.73,0.48},{-0.56,1.15,0.49},{0.05,1.33,0.43},{0.51,1.12,0.46},{0.78,0.75,0.48}}
for i=1,#sections-1 do
    local a,b=sections[i],sections[i+1]
    G.quad(m,{-a[3],a[2],a[1]},{-b[3],b[2],b[1]},{b[3],b[2],b[1]},{a[3],a[2],a[1]},(i==1 or i==4) and 6 or 15)
    G.quad(m,{-0.55,0.72,a[1]},{-0.55,0.72,b[1]},{-b[3],b[2],b[1]},{-a[3],a[2],a[1]},i==2 and 6 or 24)
    G.quad(m,{0.55,0.72,b[1]},{0.55,0.72,a[1]},{a[3],a[2],a[1]},{b[3],b[2],b[1]},i==2 and 6 or 8)
end
for _,x in ipairs({-0.66,0.66}) do for _,z in ipairs({-0.75,0.75}) do
    box(0.25,0.32,0.60,x,0.57,z,8,24,15) -- fender
    box(0.21,0.45,0.43,x,0.29,z,0,10,10) -- tire
end end
box(1.30,0.09,0.10,0,0.38,-1.23,12,11,9)
box(1.30,0.09,0.10,0,0.38,1.23,12,11,9)
-- Tail lamps and headlights are mesh faces, not sprites.
for _,x in ipairs({-0.44,0.44}) do
    G.quad(m,{x-0.09,0.48,-1.178},{x-0.09,0.62,-1.178},{x+0.09,0.62,-1.178},{x+0.09,0.48,-1.178},7)
    G.quad(m,{x+0.10,0.51,1.178},{x+0.10,0.67,1.178},{x-0.10,0.67,1.178},{x-0.10,0.51,1.178},9)
end
return m
