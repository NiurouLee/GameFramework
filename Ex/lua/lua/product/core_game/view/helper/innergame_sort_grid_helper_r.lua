--InnerGameSortGridHelper

---@class InnerGameSortGridHelperRender: Singleton
_class("InnerGameSortGridHelperRender", Singleton)
InnerGameSortGridHelperRender = InnerGameSortGridHelperRender

---获得对应格子和方向的边缘坐标
---@param pos Vector2
---@param direction string
---@return Vector2
function InnerGameSortGridHelperRender:_GetGridEdgePos(pos, direction)
    if pos == nil then
        return nil
    end
    local gridRadius = 0.5
    local edge = gridRadius * Mathf.Sin(Mathf.Rad(45))
    local ret = Vector2(0, 0)
    if direction == "Up" then
        ret.x = pos.x
        ret.y = pos.y + gridRadius
    elseif direction == "Bottom" then
        ret.x = pos.x
        ret.y = pos.y - gridRadius
    elseif direction == "Left" then
        ret.x = pos.x - gridRadius
        ret.y = pos.y
    elseif direction == "Right" then
        ret.x = pos.x + gridRadius
        ret.y = pos.y
    elseif direction == "LeftUp" then
        ret.x = pos.x - gridRadius
        ret.y = pos.y + gridRadius
    elseif direction == "RightUp" then
        ret.x = pos.x + gridRadius
        ret.y = pos.y + gridRadius
    elseif direction == "LeftBottom" then
        ret.x = pos.x - gridRadius
        ret.y = pos.y - gridRadius
    elseif direction == "RightBottom" then
        ret.x = pos.x + gridRadius
        ret.y = pos.y - gridRadius
    end
    return ret
end

---已casterPos为中,排序GridList,返回各个方向最远距离的格子,和各个方向的格子列表
---@param gridList Vector2[]
---@param castPos Vector2
function InnerGameSortGridHelperRender:SortGrid(gridList, castPos)
    ---棋盘在x,z平面,这里是已z为上-z为下,x为右,-x为左来定义方
    local leftup = nil
    local leftbottom = nil
    local rightbottom = nil
    local rightup = nil
    local up = nil
    local bottom = nil
    local right = nil
    local left = nil
    local maxLength = 0
    local leftUpList = {}
    local leftBottomList = {}
    local rightBottomList = {}
    local rightUpList = {}
    local upList = {}
    local bottomList = {}
    local rightList = {}
    local leftList = {}
    local maxGridCount = 0
    for i, pos in pairs(gridList) do
        --local pos = posList[1]
        local dis = pos - castPos
        if (math.abs(dis.x) > maxLength) then
            maxLength = math.abs(dis.x)
        end
        if (math.abs(dis.y) > maxLength) then
            maxLength = math.abs(dis.y)
        end
        if dis.x > 0 and dis.y < 0 then
            table.insert(rightBottomList, pos)
            if rightbottom == nil or rightbottom.x < pos.x then
                rightbottom = pos
            end
        elseif dis.x < 0 and dis.y < 0 then
            table.insert(leftBottomList, pos)
            if leftbottom == nil or leftbottom.x > pos.x then
                leftbottom = pos
            end
        elseif dis.x < 0 and dis.y > 0 then
            table.insert(leftUpList, pos)
            if leftup == nil or leftup.x > pos.x then
                leftup = pos
            end
        elseif dis.x > 0 and dis.y > 0 then
            table.insert(rightUpList, pos)
            if rightup == nil or rightup.x < pos.x then
                rightup = pos
            end
        elseif dis.x > 0 and dis.y == 0 then
            table.insert(rightList, pos)
            if right == nil or right.x < pos.x then
                right = pos
            end
        elseif dis.x < 0 and dis.y == 0 then
            table.insert(leftList, pos)
            if left == nil or left.x > pos.x then
                left = pos
            end
        elseif dis.x == 0 and dis.y < 0 then
            table.insert(bottomList, pos)
            if bottom == nil or bottom.y > pos.y then
                bottom = pos
            end
        elseif dis.x == 0 and dis.y > 0 then
            table.insert(upList, pos)
            if up == nil or up.y < pos.y then
                up = pos
            end
        end
    end

    --Y升序
    local cmpAscY = function(pos1, pos2)
        return pos1.y < pos2.y
    end
    local cmpDesY = function(pos1, pos2)
        return pos1.y > pos2.y
    end
    local cmpAscX = function(pos1, pos2)
        return pos1.x < pos2.x
    end
    local cmpDesX = function(pos1, pos2)
        return pos1.x > pos2.x
    end

    --按照方向不同排序,都是按照离施法者的距离由小到大排序
    table.sort(upList, cmpAscY)
    table.sort(bottomList, cmpDesY)
    table.sort(rightList, cmpAscX)
    table.sort(leftList, cmpDesX)
    table.sort(leftUpList, cmpAscY)
    table.sort(rightUpList, cmpAscY)
    table.sort(leftBottomList, cmpDesY)
    table.sort(rightBottomList, cmpDesY)

    --取最长的方向有多少个格子
    local GetMaxGridCount = function(table, maxGridCount)
        if #table > maxGridCount then
            maxGridCount = #table
        end
        return maxGridCount
    end
    maxGridCount = GetMaxGridCount(upList, maxGridCount)
    maxGridCount = GetMaxGridCount(bottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftBottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightBottomList, maxGridCount)

    local targets = {
        {
            gridpos = leftup,
            gridEdgePos = self:_GetGridEdgePos(leftup, "LeftUp"),
            direction = Vector2(-1, 1),
            gridList = leftUpList,
            strDirection = "LeftUp"
        },
        {
            gridpos = leftbottom,
            gridEdgePos = self:_GetGridEdgePos(leftbottom, "LeftBottom"),
            direction = Vector2(-1, -1),
            gridList = leftBottomList,
            strDirection = "LeftBottom"
        },
        {
            gridpos = rightbottom,
            gridEdgePos = self:_GetGridEdgePos(rightbottom, "RightBottom"),
            direction = Vector2(1, -1),
            gridList = rightBottomList,
            strDirection = "RightBottom"
        },
        {
            gridpos = rightup,
            gridEdgePos = self:_GetGridEdgePos(rightup, "RightUp"),
            direction = Vector2(1, 1),
            gridList = rightUpList,
            strDirection = "RightUp"
        },
        {
            gridpos = up,
            gridEdgePos = self:_GetGridEdgePos(up, "Up"),
            direction = Vector2(0, 1),
            gridList = upList,
            strDirection = "Up"
        },
        {
            gridpos = bottom,
            gridEdgePos = self:_GetGridEdgePos(bottom, "Bottom"),
            direction = Vector2(0, -1),
            gridList = bottomList,
            strDirection = "Bottom"
        },
        {
            gridpos = right,
            gridEdgePos = self:_GetGridEdgePos(right, "Right"),
            direction = Vector2(1, 0),
            gridList = rightList,
            strDirection = "Right"
        },
        {
            gridpos = left,
            gridEdgePos = self:_GetGridEdgePos(left, "Left"),
            direction = Vector2(-1, 0),
            gridList = leftList,
            strDirection = "Left"
        }
        --{gridpos = up, gridList = upList, strDirection = "Up"},
        --{gridpos = bottom, gridList = bottomList, strDirection = "Bottom"},
        --{gridpos = right, gridList = rightList, strDirection = "Right"},
        --{gridpos = left, gridList = leftList, strDirection = "Left"},
        --{gridpos = leftup, gridList = leftUpList, strDirection = "LeftUp"},
        --{gridpos = rightup, gridList = rightUpList, strDirection = "RightUp"},
        --{gridpos = leftbottom, gridList = leftBottomList, strDirection = "LeftBottom"},
        --{gridpos = rightbottom, gridList = rightBottomList, strDirection = "RightBottom"}
    }
    return targets, maxLength, maxGridCount
end

---已casterPos为中,排序GridList,返回各个方向最远距离的格子,和各个方向的格子列表
---@param gridList Vector2[]
---@param centerPos Vector2
function InnerGameSortGridHelperRender:SortGridWithCenterPos(gridList, centerPos)
    ---棋盘在x,z平面,这里是已z为上-z为下,x为右,-x为左来定义方
    local leftup = nil
    local leftbottom = nil
    local rightbottom = nil
    local rightup = nil
    local up = nil
    local bottom = nil
    local right = nil
    local left = nil
    local center = nil
    local maxLength = 0
    local leftUpList = {}
    local leftBottomList = {}
    local rightBottomList = {}
    local rightUpList = {}
    local upList = {}
    local bottomList = {}
    local rightList = {}
    local leftList = {}
    local maxGridCount = 0
    for i, pos in pairs(gridList) do
        --local pos = posList[1]
        local dis = pos - centerPos
        if (math.abs(dis.x) > maxLength) then
            maxLength = math.abs(dis.x)
        end
        if (math.abs(dis.y) > maxLength) then
            maxLength = math.abs(dis.y)
        end
        if dis.x > 0 and dis.y < 0 then
            table.insert(rightBottomList, pos)
            if rightbottom == nil or rightbottom.x < pos.x then
                rightbottom = pos
            end
        elseif dis.x < 0 and dis.y < 0 then
            table.insert(leftBottomList, pos)
            if leftbottom == nil or leftbottom.x > pos.x then
                leftbottom = pos
            end
        elseif dis.x < 0 and dis.y > 0 then
            table.insert(leftUpList, pos)
            if leftup == nil or leftup.x > pos.x then
                leftup = pos
            end
        elseif dis.x > 0 and dis.y > 0 then
            table.insert(rightUpList, pos)
            if rightup == nil or rightup.x < pos.x then
                rightup = pos
            end
        elseif dis.x > 0 and dis.y == 0 then
            table.insert(rightList, pos)
            if right == nil or right.x < pos.x then
                right = pos
            end
        elseif dis.x < 0 and dis.y == 0 then
            table.insert(leftList, pos)
            if left == nil or left.x > pos.x then
                left = pos
            end
        elseif dis.x == 0 and dis.y < 0 then
            table.insert(bottomList, pos)
            if bottom == nil or bottom.y > pos.y then
                bottom = pos
            end
        elseif dis.x == 0 and dis.y > 0 then
            table.insert(upList, pos)
            if up == nil or up.y < pos.y then
                up = pos
            end
        else
            center = pos
        end
    end

    --Y升序
    local cmpAscY = function(pos1, pos2)
        return pos1.y < pos2.y
    end
    local cmpDesY = function(pos1, pos2)
        return pos1.y > pos2.y
    end
    local cmpAscX = function(pos1, pos2)
        return pos1.x < pos2.x
    end
    local cmpDesX = function(pos1, pos2)
        return pos1.x > pos2.x
    end

    --按照方向不同排序,都是按照离施法者的距离由小到大排序
    table.sort(upList, cmpAscY)
    table.sort(bottomList, cmpDesY)
    table.sort(rightList, cmpAscX)
    table.sort(leftList, cmpDesX)
    table.sort(leftUpList, cmpAscY)
    table.sort(rightUpList, cmpAscY)
    table.sort(leftBottomList, cmpDesY)
    table.sort(rightBottomList, cmpDesY)

    --取最长的方向有多少个格子
    local GetMaxGridCount = function(table, maxGridCount)
        if #table > maxGridCount then
            maxGridCount = #table
        end
        return maxGridCount
    end
    maxGridCount = GetMaxGridCount(upList, maxGridCount)
    maxGridCount = GetMaxGridCount(bottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightUpList, maxGridCount)
    maxGridCount = GetMaxGridCount(leftBottomList, maxGridCount)
    maxGridCount = GetMaxGridCount(rightBottomList, maxGridCount)
    if center then
        maxGridCount = GetMaxGridCount({center}, maxGridCount)
    end

    local targets = {
        {
            gridpos = leftup,
            gridEdgePos = self:_GetGridEdgePos(leftup, "LeftUp"),
            direction = Vector2(-1, 1),
            gridList = leftUpList,
            strDirection = "LeftUp"
        },
        {
            gridpos = leftbottom,
            gridEdgePos = self:_GetGridEdgePos(leftbottom, "LeftBottom"),
            direction = Vector2(-1, -1),
            gridList = leftBottomList,
            strDirection = "LeftBottom"
        },
        {
            gridpos = rightbottom,
            gridEdgePos = self:_GetGridEdgePos(rightbottom, "RightBottom"),
            direction = Vector2(1, -1),
            gridList = rightBottomList,
            strDirection = "RightBottom"
        },
        {
            gridpos = rightup,
            gridEdgePos = self:_GetGridEdgePos(rightup, "RightUp"),
            direction = Vector2(1, 1),
            gridList = rightUpList,
            strDirection = "RightUp"
        },
        {
            gridpos = up,
            gridEdgePos = self:_GetGridEdgePos(up, "Up"),
            direction = Vector2(0, 1),
            gridList = upList,
            strDirection = "Up"
        },
        {
            gridpos = bottom,
            gridEdgePos = self:_GetGridEdgePos(bottom, "Bottom"),
            direction = Vector2(0, -1),
            gridList = bottomList,
            strDirection = "Bottom"
        },
        {
            gridpos = right,
            gridEdgePos = self:_GetGridEdgePos(right, "Right"),
            direction = Vector2(1, 0),
            gridList = rightList,
            strDirection = "Right"
        },
        {
            gridpos = left,
            gridEdgePos = self:_GetGridEdgePos(left, "Left"),
            direction = Vector2(-1, 0),
            gridList = leftList,
            strDirection = "Left"
        },
        {
            gridpos = center,
            gridEdgePos = center,
            direction = Vector2(0, 0),
            gridList = { center },
            strDirection = "Center"
        }
        --{gridpos = up, gridList = upList, strDirection = "Up"},
        --{gridpos = bottom, gridList = bottomList, strDirection = "Bottom"},
        --{gridpos = right, gridList = rightList, strDirection = "Right"},
        --{gridpos = left, gridList = leftList, strDirection = "Left"},
        --{gridpos = leftup, gridList = leftUpList, strDirection = "LeftUp"},
        --{gridpos = rightup, gridList = rightUpList, strDirection = "RightUp"},
        --{gridpos = leftbottom, gridList = leftBottomList, strDirection = "LeftBottom"},
        --{gridpos = rightbottom, gridList = rightBottomList, strDirection = "RightBottom"}
    }
    return targets, maxLength, maxGridCount
end
