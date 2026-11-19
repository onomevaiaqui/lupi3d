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
G.quad(S.tree,{0.18,0,0.18},{0.18,1.4,0.18},{-0.18,1.4,0.18},{-0.18,0,0.18},13)
G.quad(S.tree,{-0.18,0,0.18},{-0.18,1.4,0.18},{-0.18,1.4,-0.18},{-0.18,0,-0.18},29)
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
-- Country vegetation replaces the old tree slots; it never adds extra objects.
S.broadleaf={v={-1.4,2.5,-1.4,1.4,2.5,-1.4,1.4,2.5,1.4,-1.4,2.5,1.4,0,3.8,0,0,1.35,0},
    f={1,5,2,14,2,5,3,30,3,5,4,14,4,5,1,30,2,6,1,30,3,6,2,14,4,6,3,30,1,6,4,14}}
G.quad(S.broadleaf,{-0.17,0,-0.17},{-0.17,1.9,-0.17},{0.17,1.9,-0.17},{0.17,0,-0.17},13)
G.quad(S.broadleaf,{0.17,0,-0.17},{0.17,1.9,-0.17},{0.17,1.9,0.17},{0.17,0,0.17},29)
G.quad(S.broadleaf,{0.17,0,0.17},{0.17,1.9,0.17},{-0.17,1.9,0.17},{-0.17,0,0.17},13)
G.quad(S.broadleaf,{-0.17,0,0.17},{-0.17,1.9,0.17},{-0.17,1.9,-0.17},{-0.17,0,-0.17},29)
S.palm=G.mesh()
G.quad(S.palm,{-0.13,0,-0.13},{-0.08,3.1,-0.08},{0.18,3.1,-0.08},{0.13,0,-0.13},13)
G.quad(S.palm,{0.13,0,-0.13},{0.18,3.1,-0.08},{0.18,3.1,0.18},{0.13,0,0.13},29)
G.quad(S.palm,{0.13,0,0.13},{0.18,3.1,0.18},{-0.08,3.1,0.18},{-0.13,0,0.13},13)
G.quad(S.palm,{-0.13,0,0.13},{-0.08,3.1,0.18},{-0.08,3.1,-0.08},{-0.13,0,-0.13},29)
for i,d in ipairs({{1,0},{0,1},{-1,0},{0,-1}}) do
    local dx,dz=d[1],d[2];local px,pz=dz*0.40,-dx*0.40
    G.quad(S.palm,{0.05,3.12,0.05},{dx*0.9-px,3.3,dz*0.9-pz},
        {dx*2.4,2.65,dz*2.4},{dx*0.9+px,3.3,dz*0.9+pz},i%2==0 and 14 or 30)
end
for _,mesh in ipairs({S.tree,S.broadleaf,S.palm}) do
    for i=4,#mesh.f,4 do
        if mesh.f[i]==14 then mesh.f[i]=34 elseif mesh.f[i]==30 then mesh.f[i]=33 end
    end
end
S.scrub=G.mesh()
for i=1,#S.broadleaf.v,3 do
    S.scrub.v[i]=S.broadleaf.v[i]*0.9
    S.scrub.v[i+1]=S.broadleaf.v[i+1]*0.65
    S.scrub.v[i+2]=S.broadleaf.v[i+2]*0.9
end
for i,value in ipairs(S.broadleaf.f) do
    S.scrub.f[i]=i%4==0 and (value==34 and 14 or value==33 and 30 or value) or value
end
local countryHouses,countryRocks,countryFences,lowPlants={},{},{},{}
-- One shared landmark per country. Reused at a few safe roadside locations.
local landmarks={}
local function landmark(boxes)
    local mesh=G.mesh()
    for _,box in ipairs(boxes) do
        local w,h,d,x,y,z,color=table.unpack(box)
        G.append(mesh,G.box(w,h,d,color,color%16+16,color),x,y,z)
    end
    return mesh
end
landmarks[4]=landmark({{0.36,3.1,0.36,0,1.55,0,13},{2.8,0.55,0.35,0,2.55,0,14},
    {1.45,0.26,0.38,0,2.55,0.02,8}})
local andes=G.mesh()
for _,peak in ipairs({{-1.15,2.6},{0.75,3.5}}) do
    local x,h=table.unpack(peak)
    for _,side in ipairs({-1,1}) do
        local a,b,c={x-side*1.35,0,side*0.55},{x,0,-side*0.9},{x,h,0}
        local snowA={a[1]*0.28+x*0.72,h*0.72,a[3]*0.28}
        local snowB={x,h*0.72,b[3]*0.28}
        G.quad(andes,a,b,snowB,snowA,side==1 and 11 or 27)
        G.quad(andes,snowA,snowB,c,c,9)
        G.quad(andes,snowA,snowB,b,a,side==1 and 27 or 11)
        G.quad(andes,c,c,snowB,snowA,12)
    end
end
landmarks[1]=andes
landmarks[2]=landmark({{2.9,1.65,2.0,0,0.825,0,9},{3.24,0.26,2.35,0,1.78,0,7},
    {3.24,0.16,2.35,0,1.56,0,1}})
landmarks[3]=landmark({{0.56,3.4,0.56,0,1.7,0,9},{0.78,0.45,0.78,0,0.225,0,1},
    {0.45,0.52,0.45,0,3.47,0,9}})
local rio=landmark({{0.92,0.7,0.92,0,0.35,0,11},{0.48,2.6,0.42,0,1.95,0,9},
    {2.7,0.32,0.42,0,2.83,0,9},{0.43,0.46,0.42,0,3.42,0,9}})
local itaipu=landmark({{4.4,1.45,1.9,0,0.725,0,11},{4.5,0.18,0.44,0,1.5,-0.56,12},
    {0.45,1.35,0.22,-1.35,0.67,-1,6},{0.45,1.35,0.22,0,0.67,-1,6},{0.45,1.35,0.22,1.35,0.67,-1,6}})
local liberdade=landmark({{0.3,2.4,0.35,-1,1.2,0,7},{0.3,2.4,0.35,1,1.2,0,7},
    {2.6,0.22,0.44,0,1.9,0,7},{3,0.22,0.65,0,2.45,0,29},
    {0.25,0.39,0.25,-0.55,1.56,0,8},{0.25,0.39,0.25,0.55,1.56,0,8}})
local harbor=landmark({{3.1,0.55,1.15,0,0.5,0,6},{1.6,0.5,0.85,0,1,0,9},
    {0.24,0.5,0.24,-0.4,1.5,0,7}})
local monument=landmark({{2.8,0.45,1.5,0,0.225,0,12},{0.48,2.8,0.55,0,1.6,0,9},
    {1.1,0.16,0.22,0.48,2.65,0,1}})
local cityFeature={rio,liberdade,itaipu,andes,andes,harbor,S.quarryRock,harbor,
    landmarks[2],S.house,harbor,S.quarryRock,landmarks[3],monument,andes}
function S.populate(T)
    T.decor={};T.markings={}
    for i,s in ipairs(T.parts) do
        if i%3==1 and not s.raised and (T.id~=2 or s.x*s.x+s.z*s.z>100) then
            local len=s.length;local dx,dz=s.dx/len,s.dz/len;local nx,nz=-dz*0.095,dx*0.095
            local m=G.mesh();local h=math.min(1.35,len*0.3)
            for _,side in ipairs({-1,1}) do
                local offset=side*T.halfWidth/3
                local x,z=-dz*offset,dx*offset
                G.quad(m,{x-dx*h+nx,0,z-dz*h+nz},{x+dx*h+nx,0,z+dz*h+nz},
                    {x+dx*h-nx,0,z+dz*h-nz},{x-dx*h-nx,0,z-dz*h-nz},9)
            end
            T.markings[#T.markings+1]={x=s.x,y=0.01,z=s.z,radius=3,mesh=m}
        end
    end
    -- Small groups around bends and the approach to the finish, with open straights.
    local locations={0.04,0.08,0.19,0.23,0.29,0.43,0.48,0.58,0.64,0.75,0.80,0.93}
    local budget=({12,8,12,10,12,11,12,11,12,12,12,12,12,12,12})[T.id]
    for i,fraction in ipairs(locations) do
        if #T.decor>=budget then break end
        local p=fraction*T.segments;local x,z,yaw=T.sample(p)
        local _,_,nextYaw=T.sample(p+0.7)
        local turn=(nextYaw-yaw+math.pi)%(math.pi*2)-math.pi
        local side=math.abs(turn)>0.03 and (turn>0 and -1 or 1) or (i%2==0 and -1 or 1)
        local feature=(i==4 or i==9) and cityFeature[T.id]
        local offset=side*(feature and 12.5 or i%3==0 and 11 or 9.5)
        x,z=x+math.cos(yaw)*offset,z-math.sin(yaw)*offset
        local _,d=T.locate(x,z)
        if d>(T.halfWidth+2)^2 then
            local kind=T.id==4 and "rock" or T.id==7 and "rock"
                or i%5==0 and "house" or i%3==0 and "fence" or "rock"
            if (T.world==2 or T.world==4) and (i==1 or i==5) and T.id~=12 then kind="vegetation" end
            local material=kind=="vegetation" and (T.world==4 and S.palm or S.broadleaf)
                or kind=="house" and countryHouses[T.world] or kind=="fence" and countryFences[T.world]
                or countryRocks[T.world]
            T.decor[#T.decor+1]={
                x=x,y=0,z=z,yaw=kind=="house" and 0.7 or yaw,
                mesh=feature or material,
                radius=(feature or kind=="house") and 5 or kind=="vegetation" and 4 or 3,kind=kind
            }
        end
    end
    for i,tree in ipairs(T.trees) do
        local dry=T.id==7 or T.id==12 or T.id==15
        local tropical=T.id==1 and (i%3==0 and S.broadleaf or S.palm)
            or T.id==3 and (i%3==0 and S.palm or S.broadleaf) or S.broadleaf
        local mesh=dry and countryRocks[T.world] or T.world==4 and tropical
            or T.world==2 and S.broadleaf or T.world==3 and S.scrub or S.tree
        tree.basic=lowPlants[mesh] or tree.mesh
        tree.detailMesh=mesh
        if dry then tree.basic=mesh end
        -- Use both sides of the circuit; avoid moving any tree onto another branch.
        local progress=(i-0.3)*T.segments/6
        local x,z,yaw=T.sample(progress)
        local side=i%2==0 and -1 or 1
        local tx,tz=x+math.cos(yaw)*side*10.5,z-math.sin(yaw)*side*10.5
        local _,distance=T.locate(tx,tz)
        if distance>(T.halfWidth+2)^2 then tree.x,tree.z=tx,tz end
    end
end
for _,mesh in pairs(S) do
    if type(mesh)=="table" and mesh.v and mesh.f then G.weld(mesh) end
end
for _,mesh in ipairs(cityFeature) do G.weld(mesh) end
-- Material variants share welded vertex arrays. All remapping happens at load time.
local function material(base,mapping)
    local out={v=base.v,f={}}
    for i,value in ipairs(base.f) do out.f[i]=i%4==0 and (mapping[value] or value) or value end
    return out
end
for world=1,4 do
    local wall=({13,9,9,15})[world]
    local roof=world==3 and 12 or 7
    countryHouses[world]=material(S.house,{[13]=wall,[29]=wall+16,[8]=roof,[24]=roof+16,[6]=10})
    local stone=world==1 and 13 or world==2 and 13 or 11
    countryRocks[world]=material(S.rock,{[11]=stone,[27]=stone+16,[12]=world==1 and 15 or 12})
    local wood=world==1 and 13 or world==2 and 15 or 9
    countryFences[world]=material(S.fence,{[9]=wood,[25]=wood+16})
end
-- Preserve each country's silhouette in LEVE too, with twelve triangles per plant.
for _,mesh in ipairs({S.broadleaf,S.scrub,S.palm}) do
    local simple={v=mesh.v,f={}}
    for i=1,#mesh.f,4 do
        local face=(i+3)/4
        local keep=mesh==S.palm and (face<=8 or face%2==1) or mesh~=S.palm and (face<=4 or face>8)
        if keep then for j=0,3 do simple.f[#simple.f+1]=mesh.f[i+j] end end
    end
    lowPlants[mesh]=simple
end
return S
