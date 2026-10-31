-- A small solid block, with a closed top and sides (10 triangles).
local p={x=0,z=3.2,width=2.4,depth=2.4,height=0.55}
p.xmin,p.xmax=p.x-p.width/2,p.x+p.width/2
p.zmin,p.zmax=p.z-p.depth/2,p.z+p.depth/2
local w,d,h=p.width/2,p.depth/2,p.height
p.mesh={
    v={-w,0,-d,0, w,0,-d,0, w,0,d,0, -w,0,d,0,
       -w,h,-d,0, w,h,-d,0, w,h,d,0, -w,h,d,0},
    f={5,7,6,10, 5,8,7,10,
       1,6,2,25, 1,5,6,25,
       2,7,3,9, 2,6,7,9,
       3,8,4,25, 3,7,8,25,
       4,5,1,9, 4,8,5,9}
}
return p
