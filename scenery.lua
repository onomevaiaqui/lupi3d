-- Original scene meshes, shared by every track. All detail is XYZ geometry.
local G=require "geometry"
local S={}
S.tree=G.mesh()
for _,tier in ipairs({{1.45,0.7,2.8},{1.05,1.7,3.7},{0.65,2.6,4.3}}) do
    local w,y,top=tier[1],tier[2],tier[3]
    local n=#S.tree.v/3
    for _,p in ipairs({{-w,y,-w},{w,y,-w},{w,y,w},{-w,y,w},{0,top,0}}) do for _,c in ipairs(p) do S.tree.v[#S.tree.v+1]=c end end
    for _,f in ipairs({1,5,2,14,2,5,3,30,3,5,4,14,4,5,1,30}) do
        local k=(#S.tree.f)%4;S.tree.f[#S.tree.f+1]=k==3 and f or f+n
    end
end
G.quad(S.tree,{-0.18,0,-0.18},{-0.18,1.4,-0.18},{0.18,1.4,-0.18},{0.18,0,-0.18},13)
G.quad(S.tree,{0.18,0,-0.18},{0.18,1.4,-0.18},{0.18,1.4,0.18},{0.18,0,0.18},29)
S.rock=G.box(2.1,1.6,1.8,11,27,12)
for i=1,#S.rock.v,3 do
    local y=S.rock.v[i+1]
    S.rock.v[i+1]=y+0.8
    if y>0 then S.rock.v[i]=S.rock.v[i]*0.62+0.2;S.rock.v[i+2]=S.rock.v[i+2]*0.65-0.1 end
end
S.quarryRock={v=S.rock.v,f={}}
for i,value in ipairs(S.rock.f) do
    S.quarryRock.f[i]=i%4==0 and ({[11]=13,[27]=29,[12]=15})[value] or value
end
S.house=G.box(3.8,2.4,3.2,13,29,13)
for i=2,#S.house.v,3 do S.house.v[i]=S.house.v[i]+1.2 end
G.quad(S.house,{-2.2,2.4,1.9},{0,3.9,1.9},{0,3.9,-1.9},{-2.2,2.4,-1.9},8)
G.quad(S.house,{0,3.9,1.9},{2.2,2.4,1.9},{2.2,2.4,-1.9},{0,3.9,-1.9},24)
local n=#S.house.v/3
for _,p in ipairs({{-1.9,2.4,-1.6},{0,3.9,-1.6},{1.9,2.4,-1.6},{1.9,2.4,1.6},{0,3.9,1.6},{-1.9,2.4,1.6}}) do for _,c in ipairs(p) do S.house.v[#S.house.v+1]=c end end
for _,f in ipairs({n+1,n+2,n+3,13,n+4,n+5,n+6,29}) do S.house.f[#S.house.f+1]=f end
G.quad(S.house,{-0.36,0,-1.608},{-0.36,1.6,-1.608},{0.36,1.6,-1.608},{0.36,0,-1.608},10)
for _,x in ipairs({-1.2,1.2}) do G.quad(S.house,{x-0.28,1.25,-1.61},{x-0.28,1.85,-1.61},{x+0.28,1.85,-1.61},{x+0.28,1.25,-1.61},6) end
S.fence=G.mesh()
local function plank(x1,y1,x2,y2)
    G.quad(S.fence,{x1,y1,0},{x1,y2,0},{x2,y2,0},{x2,y1,0},9)
    G.quad(S.fence,{x2,y1,0.06},{x2,y2,0.06},{x1,y2,0.06},{x1,y1,0.06},25)
end
for _,x in ipairs({-2,0,2}) do plank(x-0.09,0,x+0.09,1.2) end
plank(-2.15,0.4,2.15,0.53);plank(-2.15,0.9,2.15,1.03)
S.flame={v={-0.22,0.25,-1.1,0.22,0.25,-1.1,0,0.25,-2.4,0,0.55,-1.2},f={1,4,3,8,4,2,3,15,2,1,3,8}}
S.blast={v={-0.8,0.5,0,0,0.5,0.8,0.8,0.5,0,0,0.5,-0.8,0,1.9,0,0,-0.1,0},f={1,5,2,8,2,5,3,15,3,5,4,7,4,5,1,8,2,6,1,7,3,6,2,8,4,6,3,7,1,6,4,8}}
for i=1,#S.blast.f,4 do S.blast.f[i+1],S.blast.f[i+2]=S.blast.f[i+2],S.blast.f[i+1] end
-- One shared landmark per country. Reused at a few safe roadside locations.
local landmarks={}
local function landmark(boxes)
    local mesh=G.mesh()
    for _,box in ipairs(boxes) do
        local w,h,d,x,y,z,color=table.unpack(box)
        G.append(mesh,G.box(w,h,d,color,color+16,color),x,y,z)
    end
    return mesh
end
landmarks[1]=landmark({{0.36,3.1,0.36,0,1.55,0,13},{2.8,0.55,0.35,0,2.55,0,14},
    {1.45,0.26,0.38,0,2.55,0.02,8}})
landmarks[2]=landmark({{0.32,2.6,0.36,-1,1.3,0,7},{0.32,2.6,0.36,1,1.3,0,7},
    {2.65,0.24,0.42,0,2.13,0,7},{3.0,0.25,0.52,0,2.64,0,7}})
landmarks[3]=landmark({{2.9,1.65,2.0,0,0.825,0,9},{3.24,0.26,2.35,0,1.78,0,7},
    {3.24,0.16,2.35,0,1.56,0,1}})
landmarks[4]=landmark({{0.56,3.4,0.56,0,1.7,0,9},{0.78,0.45,0.78,0,0.225,0,1},
    {0.45,0.52,0.45,0,3.47,0,9}})
function S.populate(T)
    T.decor={};T.markings={}
    for i,s in ipairs(T.parts) do
        if i%3==1 and not s.raised and (T.id~=2 or s.x*s.x+s.z*s.z>100) then
            local len=s.length;local dx,dz=s.dx/len,s.dz/len;local nx,nz=-dz*0.07,dx*0.07
            local m=G.mesh();local h=math.min(1,len*0.3)
            for _,side in ipairs({-1,1}) do
                local offset=side*T.halfWidth/3
                local x,z=-dz*offset,dx*offset
                G.quad(m,{x-dx*h+nx,0,z-dz*h+nz},{x+dx*h+nx,0,z+dz*h+nz},
                    {x+dx*h-nx,0,z+dz*h-nz},{x-dx*h-nx,0,z-dz*h-nz},9)
            end
            T.markings[#T.markings+1]={x=s.x,y=0.01,z=s.z,radius=3,mesh=m}
        end
    end
    for i=1,12 do
        local p=(i-0.2)*T.segments/12;local x,z,yaw=T.sample(p)
        local offset=i%4==0 and 12 or 9
        x,z=x+math.cos(yaw)*offset,z-math.sin(yaw)*offset
        local _,d=T.locate(x,z)
        if d>(T.halfWidth+2)^2 then
            local kind=T.id==4 and "rock" or T.id==7 and "house" or T.id==9 and "fence"
                or i%6==0 and "house" or i%3==0 and "fence" or "rock"
            local feature=i%4==0 and landmarks[T.world]
            T.decor[#T.decor+1]={
                x=x,y=0,z=z,yaw=kind=="house" and 0.7 or yaw,
                mesh=feature or (T.quarry and S.quarryRock or S[kind]),
                radius=(feature or kind=="house") and 5 or 3,kind=kind
            }
        end
    end
end
return S
