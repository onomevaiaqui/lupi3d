-- Full XYZ projection, backface culling, near-plane clipping and triangle rasterization.
local cfg=require "config"
local colors=require "colors"
local floor,sin,cos=math.floor,math.sin,math.cos
local projection=cfg.projection
local NEAR=0.12
local R={triangles=0,culled=0,dropped=0,vertices=0,input_triangles=0}
local pool,list={},{}
for i=1,cfg.max_triangles do pool[i]={} end
local count=0
local camera,cy,sy,cp,sp
function R.begin(state)
    camera=state
    cy,sy=cos(state.yaw),sin(state.yaw)
    cp,sp=cos(state.pitch or 0),sin(state.pitch or 0)
    R.triangles,R.culled,R.dropped,R.vertices,R.input_triangles=0,0,0,0,0
    count=0
end
local function project(obj,view)
    if not obj.px then obj.px,obj.py,obj.pz,obj.sx,obj.sy={},{},{},{},{} end
    local v=obj.mesh.v
    local oc,os
    if obj.yaw then oc,os=cos(obj.yaw),sin(obj.yaw) end
    R.vertices=R.vertices+#v/3
    R.input_triangles=R.input_triangles+#obj.mesh.f/4
    for i=1,#v,3 do
        local x,y,z=v[i],v[i+1]+obj.y,v[i+2]
        if oc then x,z=x*oc+z*os,-x*os+z*oc end
        x,z=x+obj.x,z+obj.z
        if not view then
            x,y,z=x-camera.x,y-camera.y-cfg.eye_height,z-camera.z
            local depth=x*sy+z*cy
            x=x*cy-z*sy
            y,z=y*cp-depth*sp,y*sp+depth*cp
        end
        local k=(i+2)/3
        obj.px[k],obj.py[k],obj.pz[k]=x,y,z
        if z>=NEAR then local s=projection/z;obj.sx[k]=240+x*s;obj.sy[k]=124-y*s end
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
    for edge=1,4 do
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
        local ax,ay,az=obj.px[a],obj.py[a],obj.pz[a]
        local bx,by,bz=obj.px[b],obj.py[b],obj.pz[b]
        local cx,cy,cz=obj.px[c],obj.py[c],obj.pz[c]
        local ux,uy,uz=bx-ax,by-ay,bz-az
        local vx,vy,vz=cx-ax,cy-ay,cz-az
        local facing=(uy*vz-uz*vy)*ax+(uz*vx-ux*vz)*ay+(ux*vy-uy*vx)*az
        if facing>=0 then
            R.culled=R.culled+1
        elseif az>=NEAR and bz>=NEAR and cz>=NEAR then
            -- Usual path: perspective divide already done once per vertex.
            queue(obj.sx[a],obj.sy[a],obj.sx[b],obj.sy[b],obj.sx[c],obj.sy[c],f[i+3],(az+bz+cz)/3)
        elseif az>=NEAR or bz>=NEAR or cz>=NEAR then
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
    end
end

local function farfirst(a,b) return a[8]>b[8] end
function R.submit(obj,view)
    if not view and obj.radius then
        local dx,dy,dz=obj.x-camera.x,obj.y-camera.y-cfg.eye_height,obj.z-camera.z
        local forward=dx*sy+dz*cy
        local depth=dy*sp+forward*cp
        local height=dy*cp-forward*sp
        local side=dx*cy-dz*sy
        local r=obj.radius
        if depth< -r or depth>(cfg.draw_distance or 38)+r
            or math.abs(side)>math.max(0,depth)*240/projection+r*1.5
            or height>math.max(0,depth)*104/projection+r*1.5
            or height< -math.max(0,depth)*103/projection-r*1.5 then return end
    end
    project(obj,view);emit(obj)
end
function R.flush()
    for i=#list,count+1,-1 do list[i]=nil end
    table.sort(list,farfirst)
    for i=1,count do
        local t=list[i]
        ui.trisfill(t[1],t[2],t[3],t[4],t[5],t[6],colors.index[t[7]])
    end
    R.triangles=R.triangles+count
    count=0
end
return R
