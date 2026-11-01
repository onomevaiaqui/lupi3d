local G={}
function G.mesh() return {v={},f={}} end
function G.quad(m,a,b,c,d,color)
    local n=#m.v/3
    for _,p in ipairs({a,b,c,d}) do for i=1,3 do m.v[#m.v+1]=p[i] end end
    for _,i in ipairs({n+1,n+2,n+3,color,n+1,n+3,n+4,color}) do m.f[#m.f+1]=i end
end
function G.box(w,h,d,front,side,top)
    local x,y,z=w/2,h/2,d/2
    return {v={-x,-y,-z,x,-y,-z,x,-y,z,-x,-y,z,-x,y,-z,x,y,-z,x,y,z,-x,y,z},
        f={5,7,6,top,5,8,7,top, 1,6,2,front,1,5,6,front,
           2,7,3,side,2,6,7,side, 3,8,4,side,3,7,8,side,
           4,5,1,side,4,8,5,side, 1,2,3,side,1,3,4,side}}
end
function G.append(out,mesh,x,y,z)
    local n=#out.v/3
    for i=1,#mesh.v,3 do out.v[#out.v+1]=mesh.v[i]+x;out.v[#out.v+1]=mesh.v[i+1]+y;out.v[#out.v+1]=mesh.v[i+2]+z end
    for i=1,#mesh.f,4 do
        out.f[#out.f+1]=mesh.f[i]+n;out.f[#out.f+1]=mesh.f[i+1]+n
        out.f[#out.f+1]=mesh.f[i+2]+n;out.f[#out.f+1]=mesh.f[i+3]
    end
end
-- Slab intersection against a full XYZ volume, not a 2D wall grid.
function G.rayBox(b,x,y,z,dx,dy,dz,limit)
    local near,far=0,limit or 1000
    if math.abs(dx)<1e-8 then if x<b.minx or x>b.maxx then return nil end
    else local a,c=(b.minx-x)/dx,(b.maxx-x)/dx;if a>c then a,c=c,a end;near=math.max(near,a);far=math.min(far,c) end
    if near>far then return nil end
    if math.abs(dy)<1e-8 then if y<b.miny or y>b.maxy then return nil end
    else local a,c=(b.miny-y)/dy,(b.maxy-y)/dy;if a>c then a,c=c,a end;near=math.max(near,a);far=math.min(far,c) end
    if near>far then return nil end
    if math.abs(dz)<1e-8 then if z<b.minz or z>b.maxz then return nil end
    else local a,c=(b.minz-z)/dz,(b.maxz-z)/dz;if a>c then a,c=c,a end;near=math.max(near,a);far=math.min(far,c) end
    if near>far or far<=0 then return nil end
    return near>0.00001 and near or far
end
return G
