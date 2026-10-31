local M={
    width=14,height=14,
    rows={
        "11111111111111",
        "10000000000001",
        "10000000000001",
        "10000000000001",
        "10022000033001",
        "10020000003001",
        "10020000003001",
        "10000000000001",
        "10000011000001",
        "10000011000001",
        "10000000000001",
        "10000000000001",
        "10000000000001",
        "11111111111111",
    },
    spawn={x=6.5,z=2.5,yaw=0},
    targets={{6.5,6.5},{1.7,5.5},{11.8,5.5},{4.5,10.5},{10.5,10.5},{6.5,12.0}},
}
function M.cell(x,z)
    if x<0 or z<0 or x>=M.width or z>=M.height then return 1 end
    return M.rows[z+1]:byte(x+1)-48
end
function M.free(x,z,radius)
    for cz=math.floor(z-radius),math.floor(z+radius) do
        for cx=math.floor(x-radius),math.floor(x+radius) do
            if M.cell(cx,cz)>0 then
                local dx=x-math.max(cx,math.min(x,cx+1))
                local dz=z-math.max(cz,math.min(z,cz+1))
                if dx*dx+dz*dz<radius*radius then return false end
            end
        end
    end
    return true
end
return M
