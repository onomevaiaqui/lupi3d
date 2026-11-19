-- Full XYZ projection, backface culling, near-plane clipping and triangle rasterization.
local cfg=require "config"
local colors=require "colors"
local floor,sin,cos=math.floor,math.sin,math.cos
local projection=cfg.projection
local NEAR=0.12
local R={triangles=0,culled=0,dropped=0,vertices=0,input_triangles=0,cached_vertices=0,cache_builds=0,objects=0,rejected=0,early_rejected=0}
local pool,list={},{}
for i=1,cfg.max_triangles do pool[i]={} end
local count=0
local camera,cy,sy,cp,sp
local viewEpoch,lastYaw,lastPitch=0,nil,nil
function R.begin(state)
    camera=state
    if lastYaw~=state.yaw or lastPitch~=(state.pitch or 0) then
        lastYaw,lastPitch=state.yaw,state.pitch or 0;viewEpoch=viewEpoch+1
        cy,sy=cos(lastYaw),sin(lastYaw);cp,sp=cos(lastPitch),sin(lastPitch)
    end
    R.triangles,R.culled,R.dropped,R.vertices,R.input_triangles=0,0,0,0,0
    R.cached_vertices,R.cache_builds=0,0
    R.objects,R.rejected,R.early_rejected=0,0,0
    count=0
end
-- Prepared local vertices retain XYZ geometry; only perspective/translation repeat.
-- Cache ownership follows each scene object, so previous courses can be collected.
local function prepare(obj,state,cy,sy,cp,sp)
    local caches=obj.viewCaches
    if not caches then caches={};obj.viewCaches=caches end
    local mesh=obj.mesh
    local cached=caches[mesh]
    if cached and cached.yaw==obj.yaw and cached.cameraYaw==state.yaw and cached.pitch==(state.pitch or 0) then
        cached.epoch=lastYaw==state.yaw and lastPitch==(state.pitch or 0) and viewEpoch or nil
        return cached
    end
    local v=mesh.v
    cached={yaw=obj.yaw,cameraYaw=state.yaw,pitch=state.pitch or 0,epoch=lastYaw==state.yaw and lastPitch==(state.pitch or 0) and viewEpoch or nil}
    local oc,os
    if obj.yaw then oc,os=cos(obj.yaw),sin(obj.yaw) end
    local minx,miny,minz,maxx,maxy,maxz=math.huge,math.huge,math.huge,-math.huge,-math.huge,-math.huge
    for i=1,#v,3 do
        local x,y,z=v[i],v[i+1],v[i+2]
        if oc then x,z=x*oc+z*os,-x*os+z*oc end
        local forward=x*sy+z*cy
        cached[i],cached[i+1],cached[i+2]=x*cy-z*sy,y*cp-forward*sp,y*sp+forward*cp
        local a,b,c=cached[i],cached[i+1],cached[i+2]
        if a<minx then minx=a end;if a>maxx then maxx=a end
        if b<miny then miny=b end;if b>maxy then maxy=b end
        if c<minz then minz=c end;if c>maxz then maxz=c end
    end
    cached.minx,cached.miny,cached.minz,cached.maxx,cached.maxy,cached.maxz=minx,miny,minz,maxx,maxy,maxz
    caches[mesh]=cached
    R.cache_builds=R.cache_builds+1
    return cached
end
function R.prepare(obj,state)
    if not cfg.cache_static_geometry then return end
    state=state or camera
    if state.yaw==lastYaw and (state.pitch or 0)==lastPitch then return prepare(obj,state,cy,sy,cp,sp) end
    return prepare(obj,state,cos(state.yaw),sin(state.yaw),cos(state.pitch or 0),sin(state.pitch or 0))
end
-- Projection is consumed before the next object is submitted.
local px,py,pz,sx,syScreen={},{},{},{},{}
local function projectCached(obj,v,side,height,depth)
    R.vertices=R.vertices+#v/3
    R.cached_vertices=R.cached_vertices+#v/3
    R.input_triangles=R.input_triangles+#obj.mesh.f/4
    local k=0
    if depth+v.minz>=NEAR then
        -- The whole cached object is in front of the near plane. Only depth
        -- and screen positions are consumed by emit; XYZ scratch is unnecessary.
        for i=1,#v,3 do
            local z=v[i+2]+depth;local scale=projection/z;k=k+1
            pz[k]=z;sx[k]=240+(v[i]+side)*scale;syScreen[k]=124-(v[i+1]+height)*scale
        end
        return
    end
    for i=1,#v,3 do
        local x,y,z=v[i]+side,v[i+1]+height,v[i+2]+depth
        k=k+1
        px[k],py[k],pz[k]=x,y,z
        if z>=NEAR then local s=projection/z;sx[k]=240+x*s;syScreen[k]=124-y*s end
    end
end
local function project(obj,view,side,height,depth)
    local v=obj.mesh.v
    R.vertices=R.vertices+#v/3
    R.input_triangles=R.input_triangles+#obj.mesh.f/4
    local oc,os=1,0
    if obj.yaw then oc,os=cos(obj.yaw),sin(obj.yaw) end
    local k=0
    if view then
        for i=1,#v,3 do
            local x,y,z=v[i]*oc+v[i+2]*os+obj.x,v[i+1]+obj.y,-v[i]*os+v[i+2]*oc+obj.z
            k=k+1;px[k],py[k],pz[k]=x,y,z
            if z>=NEAR then local scale=projection/z;sx[k]=240+x*scale;syScreen[k]=124-y*scale end
        end
        return
    end
    if not side then
        local dx,dy,dz=obj.x-camera.x,obj.y-camera.y-cfg.eye_height,obj.z-camera.z
        local forward=dx*sy+dz*cy
        side,height,depth=dx*cy-dz*sy,dy*cp-forward*sp,dy*sp+forward*cp
    end
    -- Fuse object yaw with camera yaw once per object, not once per vertex.
    local xx,xz=oc*cy+os*sy,os*cy-oc*sy
    local zx,zz=oc*sy-os*cy,os*sy+oc*cy
    local r=obj.mesh.cullRadius
    if r and depth-r>=NEAR then
        for i=1,#v,3 do
            local vx,vy,vz=v[i],v[i+1],v[i+2]
            local forward=vx*zx+vz*zz
            local z=vy*sp+forward*cp+depth;local scale=projection/z;k=k+1
            pz[k]=z;sx[k]=240+(vx*xx+vz*xz+side)*scale;syScreen[k]=124-(vy*cp-forward*sp+height)*scale
        end
        return
    end
    for i=1,#v,3 do
        local vx,vy,vz=v[i],v[i+1],v[i+2]
        local forward=vx*zx+vz*zz
        local x,y,z=vx*xx+vz*xz+side,vy*cp-forward*sp+height,vy*sp+forward*cp+depth
        k=k+1;px[k],py[k],pz[k]=x,y,z
        if z>=NEAR then local scale=projection/z;sx[k]=240+x*scale;syScreen[k]=124-y*scale end
    end
end
local function store(ax,ay,bx,by,dx,dy,color,depth)
    if count>=cfg.max_triangles then R.dropped=R.dropped+1; return end
    -- Validate the actual integer geometry sent to the native rasterizer.
    -- A valid floating triangle may collapse or reverse winding after flooring.
    ax,ay,bx,by,dx,dy=floor(ax),floor(ay),floor(bx),floor(by),floor(dx),floor(dy)
    if ax<0 then ax=0 elseif ax>479 then ax=479 end
    if bx<0 then bx=0 elseif bx>479 then bx=479 end
    if dx<0 then dx=0 elseif dx>479 then dx=479 end
    if ay<20 then ay=20 elseif ay>227 then ay=227 end
    if by<20 then by=20 elseif by>227 then by=227 end
    if dy<20 then dy=20 elseif dy>227 then dy=227 end
    local area=(bx-ax)*(dy-ay)-(by-ay)*(dx-ax)
    if area==0 then return end
    if area<0 then bx,by,dx,dy=dx,dy,bx,by end
    count=count+1
    local t=pool[count]
    t[1],t[2],t[3],t[4],t[5],t[6]=ax,ay,bx,by,dx,dy
    t[7],t[8]=color,depth
    list[count]=t
end
-- The native rasterizer loops over off-screen pixels before rejecting them.
-- Clip to the visible world rectangle before calling ui.trisfill.
local screenX,screenY,outX,outY={},{},{},{}
local function queue(ax,ay,bx,by,dx,dy,color,depth)
    if (ax<0 and bx<0 and dx<0) or (ax>479 and bx>479 and dx>479)
        or (ay<20 and by<20 and dy<20) or (ay>227 and by>227 and dy>227) then return end
    if ax>=0 and ax<=479 and bx>=0 and bx<=479 and dx>=0 and dx<=479
        and ay>=20 and ay<=227 and by>=20 and by<=227 and dy>=20 and dy<=227 then
        store(ax,ay,bx,by,dx,dy,color,depth)
        return
    end
    screenX[1],screenY[1],screenX[2],screenY[2],screenX[3],screenY[3]=ax,ay,bx,by,dx,dy
    local n=3
    -- Intersections cannot escape a boundary already containing all three vertices.
    local needed=((ax<0 or bx<0 or dx<0) and 1 or 0)
        | ((ax>479 or bx>479 or dx>479) and 2 or 0)
        | ((ay<20 or by<20 or dy<20) and 4 or 0)
        | ((ay>227 or by>227 or dy>227) and 8 or 0)
    for edge=1,4 do
        if needed & (1 << (edge-1))~=0 then
            local horizontal=edge<=2
            local boundary=edge==1 and 0 or edge==2 and 479 or edge==3 and 20 or 227
            local greater=edge==1 or edge==3
            local m=0
            local prev=n
            for i=1,n do
                local p=horizontal and screenX[prev] or screenY[prev]
                local q=horizontal and screenX[i] or screenY[i]
                local insideP=greater and p>=boundary or (not greater and p<=boundary)
                local insideQ=greater and q>=boundary or (not greater and q<=boundary)
                if insideP~=insideQ then
                    local t=(boundary-p)/(q-p)
                    m=m+1
                    outX[m]=screenX[prev]+(screenX[i]-screenX[prev])*t
                    outY[m]=screenY[prev]+(screenY[i]-screenY[prev])*t
                    if horizontal then outX[m]=boundary else outY[m]=boundary end
                end
                if insideQ then m=m+1; outX[m]=screenX[i]; outY[m]=screenY[i] end
                prev=i
            end
            screenX,outX=outX,screenX; screenY,outY=outY,screenY
            n=m
            if n<3 then return end
        end
    end
    for i=2,n-1 do
        store(screenX[1],screenY[1],screenX[i],screenY[i],screenX[i+1],screenY[i+1],color,depth)
    end
end
local function submit(ax,ay,az,bx,by,bz,dx,dy,dz,color)
    queue(240+ax*projection/az,124-ay*projection/az,240+bx*projection/bz,124-by*projection/bz,240+dx*projection/dz,124-dy*projection/dz,color,(az+bz+dz)/3)
end
-- Sutherland-Hodgman clipping against the near plane. Reused scratch arrays.
local ix,iy,iz,ox,oy,oz={},{},{},{},{},{}
local function emit(obj)
    local f=obj.mesh.f
    for i=1,#f,4 do
        local a,b,c=f[i],f[i+1],f[i+2]
        local az,bz,cz=pz[a],pz[b],pz[c]
        if az>=NEAR and bz>=NEAR and cz>=NEAR then
            local x1,y1,x2,y2,x3,y3=sx[a],syScreen[a],sx[b],syScreen[b],sx[c],syScreen[c]
            if (x2-x1)*(y3-y1)-(y2-y1)*(x3-x1)>0 then
                queue(x1,y1,x2,y2,x3,y3,f[i+3],(az+bz+cz)/3)
            else
                R.culled=R.culled+1
            end
        elseif az>=NEAR or bz>=NEAR or cz>=NEAR then
            -- A triangle crossing the near plane has no complete screen projection.
            local ax,ay=px[a],py[a]
            local bx,by=px[b],py[b]
            local cx,cy=px[c],py[c]
            local ux,uy,uz=bx-ax,by-ay,bz-az
            local vx,vy,vz=cx-ax,cy-ay,cz-az
            local facing=(uy*vz-uz*vy)*ax+(uz*vx-ux*vz)*ay+(ux*vy-uy*vx)*az
            if facing>=0 then
                R.culled=R.culled+1
                goto nextFace
            end
            ix[1],iy[1],iz[1]=ax,ay,az
            ix[2],iy[2],iz[2]=bx,by,bz
            ix[3],iy[3],iz[3]=cx,cy,cz
            local n=0
            for k=1,3 do
                local prev=k==1 and 3 or k-1
                local a,b=iz[prev]>=NEAR,iz[k]>=NEAR
                if a~=b then
                    local t=(NEAR-iz[prev])/(iz[k]-iz[prev])
                    n=n+1; ox[n]=ix[prev]+(ix[k]-ix[prev])*t; oy[n]=iy[prev]+(iy[k]-iy[prev])*t; oz[n]=NEAR
                end
                if b then n=n+1; ox[n]=ix[k]; oy[n]=iy[k]; oz[n]=iz[k] end
            end
            local color=f[i+3]
            for k=2,n-1 do submit(ox[1],oy[1],oz[1],ox[k],oy[k],oz[k],ox[k+1],oy[k+1],oz[k+1],color) end
        end
        ::nextFace::
    end
end

local function farfirst(a,b) return a[8]>b[8] end
-- Conservative plane tests: a one-pixel guard keeps clipping-edge pixels intact.
local leftNorm=math.sqrt(projection^2+241^2)
local rightNorm=math.sqrt(projection^2+240^2)
local topNorm=math.sqrt(projection^2+105^2)
local bottomNorm=math.sqrt(projection^2+104^2)
local function outsideBounds(b,x,y,z)
    local far=z+b.maxz
    return far<NEAR or projection*(x+b.maxx)+241*far<0
        or 240*far-projection*(x+b.minx)<0
        or 105*far-projection*(y+b.miny)<0
        or 104*far+projection*(y+b.maxy)<0
end
function R.prepareMesh(mesh)
    local r=mesh.cullRadius
    if not r then
        local max=0
        for i=1,#mesh.v,3 do
            local v=mesh.v;local d=v[i]^2+v[i+1]^2+v[i+2]^2
            if d>max then max=d end
        end
        r=math.sqrt(max);mesh.cullRadius=r
    end
    return r
end
local function outsideSphere(mesh,x,y,z)
    local r=mesh.cullRadius or R.prepareMesh(mesh)
    return z+r<NEAR or projection*x+241*z+r*leftNorm<0
        or 240*z-projection*x+r*rightNorm<0
        or 105*z-projection*y+r*topNorm<0
        or 104*z+projection*y+r*bottomNorm<0
end
function R.submit(obj,view)
    R.objects=R.objects+1
    local side,height,depth
    if not view and (cfg.early_culling or obj.radius or obj.viewCaches and cfg.cache_static_geometry) then
        local dx,dy,dz=obj.x-camera.x,obj.y-camera.y-cfg.eye_height,obj.z-camera.z
        local forward=dx*sy+dz*cy
        depth=dy*sp+forward*cp
        height=dy*cp-forward*sp
        side=dx*cy-dz*sy
        local r=obj.radius
        if r and (depth< -r or depth>(cfg.draw_distance or 38)+r
            or math.abs(side)>math.max(0,depth)*240/projection+r*1.5
            or height>math.max(0,depth)*104/projection+r*1.5
            or height< -math.max(0,depth)*103/projection-r*1.5) then R.rejected=R.rejected+1;return end
    end
    if not view and obj.viewCaches and cfg.cache_static_geometry then
        local cached=obj.viewCaches[obj.mesh]
        if not cached or cached.epoch~=viewEpoch or cached.yaw~=obj.yaw then cached=prepare(obj,camera,cy,sy,cp,sp) end
        if cfg.early_culling and outsideBounds(cached,side,height,depth) then
            R.rejected=R.rejected+1;R.early_rejected=R.early_rejected+1;return
        end
        projectCached(obj,cached,side,height,depth)
    else
        if not view and cfg.early_culling and outsideSphere(obj.mesh,side,height,depth) then
            R.rejected=R.rejected+1;R.early_rejected=R.early_rejected+1;return
        end
        project(obj,view,side,height,depth)
    end
    emit(obj)
end
function R.flush()
    for i=#list,count+1,-1 do list[i]=nil end
    table.sort(list,farfirst)
    local drawTriangle,index=ui.trisfill,colors.index
    for i=1,count do
        local t=list[i]
        drawTriangle(t[1],t[2],t[3],t[4],t[5],t[6],index[t[7]])
    end
    R.triangles=R.triangles+count
    count=0
end
return R
