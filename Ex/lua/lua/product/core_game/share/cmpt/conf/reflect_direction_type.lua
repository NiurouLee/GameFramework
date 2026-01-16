--米字形4个反射方向
ReflectDirectionType = {
    Heng = 1, --横 0°
    Shu = 2, --竖 90°
    Pie = 3, --撇 45°
    Na = 4 --捺 135°
}

---@param srcPos Vector2 源点
---@param centerPos Vector2 源点和反射面的交点
---@param reflectType ReflectDirectionType 反射面的方向
---@return Vector2 源点反射后的对称点
function CalcReflectPos(srcPos, centerPos, reflectType)
    local tarPos = Vector2(srcPos.x, srcPos.y)
    if srcPos == centerPos then
        return tarPos
    end

    if reflectType == ReflectDirectionType.Heng then
        local dir = centerPos - srcPos
        tarPos.x = centerPos.x + dir.x
        return tarPos
    elseif reflectType == ReflectDirectionType.Shu then
        local dir = centerPos - srcPos
        tarPos.y = centerPos.y + dir.y
        return tarPos
    elseif reflectType == ReflectDirectionType.Na then
        --平移到0点轴对称映射，然后平移回来
        local orignal = srcPos - centerPos
        orignal.x, orignal.y = orignal.y, orignal.x
        tarPos = orignal + centerPos
        return tarPos
    elseif reflectType == ReflectDirectionType.Pie then
        local orignal = srcPos - centerPos
        orignal.x, orignal.y = -orignal.y, -orignal.x
        tarPos = orignal + centerPos
        return tarPos
    end
end
