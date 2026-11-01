-- Low-poly view-space weapon: genuine XYZ cuboids, no weapon sprite.
local G=require "geometry"
local m=G.mesh()
G.append(m,G.box(0.20,0.12,0.34,11,26,12),0,-0.13,0.77)
G.append(m,G.box(0.10,0.055,0.34,10,11,12),0,-0.0425,1.11)
G.append(m,G.box(0.04,0.04,0.13,14,30,14),0,-0.025,0.80)
G.append(m,G.box(0.14,0.15,0.14,10,26,11),0,-0.265,0.72)
G.append(m,G.box(0.22,0.09,0.16,13,29,13),0.025,-0.205,0.61)
-- The grip is slightly to the right, the muzzle aligned with the crosshair.
for i=1,#m.v,3 do m.v[i]=m.v[i]+0.09*(1.28-m.v[i+2])/0.68 end
m.flash={v={0.08,-0.03,1.31,-0.08,-0.03,1.31,0,0.07,1.31,0,-0.13,1.31,0,-0.03,1.34,0,-0.03,1.28},
    f={1,3,5,8,3,2,5,8,2,4,5,8,4,1,5,8,3,1,6,15,2,3,6,8,4,2,6,15,1,4,6,8}}
return m
