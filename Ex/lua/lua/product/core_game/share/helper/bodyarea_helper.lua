--[[------------------------------------------------------------------------------------------
    BodyAreaHelper：对目标区域的一些通用算法的包装，只能操作postion
    
    Q:为什么本文件中的函数不放到BodyAreaComponent里？
    A:正常情况下，组件数据的操作应该放到组件。但由于局外也需要范围计算，局外访问不了上述组件

    Helper对象应当足够内聚，只包含某一个状态行为
    1.这种辅助对象，逻辑表现都会用到，所以禁止访问world、Entity等可能会导致逻辑表现越界的情况
    2.职责单一比较容易维护
    3.无状态数据
]] --------------------------------------------------------------------------------------------

---@class BodyAreaHelper: Object
_class("BodyAreaHelper", Object)
BodyAreaHelper = BodyAreaHelper

function BodyAreaHelper.IsPosInBodyArea(bodyArea, pos)
    for i, v in ipairs(bodyArea) do
        if v.x == pos.x and v.y == pos.y then
            return true
        end
    end
end

function BodyAreaHelper.GetBodyAreaLeft(area)
    local x = area[1].x
    for i = 2, #area do
        if x > area[i].x then
            x = area[i].x
        end
    end
    return x
end

function BodyAreaHelper.GetBodyAreaRight(area)
    local x = area[1].x
    for i = 2, #area do
        if x < area[i].x then
            x = area[i].x
        end
    end
    return x
end

function BodyAreaHelper.GetBodyAreaUp(area)
    local y = area[1].y
    for i = 2, #area do
        if y < area[i].y then
            y = area[i].y
        end
    end
    return y
end

function BodyAreaHelper.GetBodyAreaDown(area)
    local y = area[1].y
    for i = 2, #area do
        if y > area[i].y then
            y = area[i].y
        end
    end
    return y
end