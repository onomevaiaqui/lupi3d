local models=dofile("models.lua")
local total=0
for name,m in pairs(models) do
    assert(#m.v%4==0 and #m.f%4==0,"invalid flat mesh stride")
    local groups={}
    for i=1,#m.v,4 do
        for k=0,2 do assert(m.v[i+k]==m.v[i+k],"nonfinite vertex") end
        groups[m.v[i+3]]=true
    end
    for i=1,#m.f,4 do
        local a,b,c=(m.f[i]-1)*4+1,(m.f[i+1]-1)*4+1,(m.f[i+2]-1)*4+1
        assert(a>=1 and c>=1 and b>=1 and a<=#m.v and b<=#m.v and c<=#m.v,"invalid index")
        assert(m.v[a+3]==m.v[b+3] and m.v[b+3]==m.v[c+3],"face crosses articulated parts")
        local ux,uy,uz=m.v[b]-m.v[a],m.v[b+1]-m.v[a+1],m.v[b+2]-m.v[a+2]
        local vx,vy,vz=m.v[c]-m.v[a],m.v[c+1]-m.v[a+1],m.v[c+2]-m.v[a+2]
        local area2=(uy*vz-uz*vy)^2+(uz*vx-ux*vz)^2+(ux*vy-uy*vx)^2
        assert(area2>1e-16,"degenerate face")
        assert(m.f[i+3]>=0 and m.f[i+3]<32,"invalid palette index")
    end
    if name=="knight" then
        for g=0,4 do assert(groups[g],"missing body/limb group") end
        assert(#m.f/4<=450,"character triangle budget")
    end
    total=total+#m.f/4*(name=="tree" and 4 or name=="rock" and 3 or name=="knight" and 1 or 0)
end
assert(total+18<1000,"scene geometry budget")
print("PASS: mesh indices, articulation groups, face areas, palette and scene budget ("..(total+18).." input triangles)")
