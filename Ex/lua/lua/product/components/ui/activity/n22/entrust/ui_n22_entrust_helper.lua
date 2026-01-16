--[[
    活动辅助类
]]
---@class UIN22EntrustHelper:Object
_class("UIN22EntrustHelper", Object)
UIN22EntrustHelper = UIN22EntrustHelper

function UIN22EntrustHelper.GetLevelIndex(component, entrustid)
    local tb = component:GetAllLevelId()
    local rtb = table.reverse(tb)
    return rtb[entrustid]
end

--region Calc UIN22EntrustLevelController anim info

function UIN22EntrustHelper.CalcNodeInfo(showEnterAnim, component, levelId)
    local startId = component:FindEventStart(levelId)

    local all = component:GetAllOpenEvents(levelId)
    local tb_out = {}
    for _, nodeId in ipairs(all) do
        local time = 267 -- uieff_UIN22EntrustLevel_Node_in 播放时间
        local isPlay, delay
        if showEnterAnim then
            isPlay, delay = UIN22EntrustHelper._CalcNodeInfo_EnterAnim(component, nodeId, startId)
        else
            isPlay, delay = UIN22EntrustHelper._CalcNodeInfo_NewNode(component, nodeId, startId)
        end

        tb_out[nodeId] = { -- TB_Node
            ["isPlay"] = isPlay,
            ["delay"] = delay,
            ["time"] = time
        }
    end

    return tb_out
end

-- 进场动效，node 以起点为中心，向外按照 speed 扩展显示
function UIN22EntrustHelper._CalcNodeInfo_EnterAnim(component, nodeId, startId)
    local speed = 5 -- 除数不能为 0
    local posStart = component:GetEventPointPos(startId)
    local pos = component:GetEventPointPos(nodeId)
    local dis = Vector2.Distance(pos, posStart)
    local delay = dis / speed
    
    return true, delay
end

-- 新出现点的动效
function UIN22EntrustHelper._CalcNodeInfo_NewNode(component, nodeId, startId)
    local playTime = 300 --线段缩放时间

    local key = component:GetEntrustEventNewKey(nodeId)

    -- 只有新出现点会播放
    local isPlay = (nodeId ~= startId) and (LocalDB.GetInt(key, 0) == 0)
    LocalDB.SetInt(key, 1)

    -- 新出现的点距离已出现的点肯定只有一个距离（一个线段的时间）
    local delay = isPlay and (1 * playTime) or 0

    return isPlay, delay
end

-- 根据点出现的顺序，计算线出现的时间和位置
function UIN22EntrustHelper.CalcLineInfo(showEnterAnim, component, levelId, tb_node)
    local viLine = {} -- 防止重复的 line
    local tb_out = {}
    local openLines = component:GetOpenEventLine(levelId)
    for _, lineid in ipairs(openLines) do
        if not viLine[lineid] then
            viLine[lineid] = true
            UIN22EntrustHelper._CalcLineInfo(showEnterAnim, component, lineid, tb_node, tb_out)
        end
    end

    return tb_out
end

function UIN22EntrustHelper._CalcLineInfo(showEnterAnim, component, lineid, tb_node, tb_out)
    local leftEventId, rightEventId = component:GetLineConecctEvents(lineid)
    -- TB_Node
    local leftNode, rightNode = tb_node[leftEventId], tb_node[rightEventId]
    if not leftNode or not rightNode then
        Log.exception("UIN22EntrustHelper.CalcLineInfo() line[", lineid, "] can't find node")
    end

    -- 计算方向，由先出现的点伸向后出现的点，如果与配置中相反，dir 设置为 false
    local dir = (not rightNode.isPlay and leftNode.isPlay) or (rightNode.delay < leftNode.delay)
    local posList = component:GetLinePosWithDirection(lineid, dir)

    -- 计算播放时间
    local sumTime
    if showEnterAnim then
        sumTime = math.abs(leftNode.delay - rightNode.delay)
    else
        sumTime = 333 -- 线段伸缩动效时间
    end

    local isPlay = leftNode.isPlay or rightNode.isPlay
    local startTime = math.min(leftNode.delay, rightNode.delay) + leftNode.time / 2
    local oneTime = math.floor(sumTime / #posList)
    for i, pos in ipairs(posList) do -- 如果有途经点，拆成小线段
        local delay = startTime + (i - 1) * oneTime -- 开始时间 0ms 间隔时间 time

        table.insert(tb_out, { -- TB_Line
            ["id"] = lineid,
            ["from"] = pos[1],
            ["to"] = pos[2],
            ["isPlay"] = isPlay,
            ["delay"] = delay,
            ["time"] = oneTime
        })
    end
end

-- Player 动效
function UIN22EntrustHelper.CalcPlayerInfo(isMove, showEnterAnim, node)
    local isPlay, anim, delay
    if isMove then -- 移动
        isPlay = true
        anim = "uieff_UIN22EntrustLevel_Player_in01"
        delay = 0
    elseif showEnterAnim then -- 进场
        isPlay = true
        anim = "uieff_UIN22EntrustLevel_Player_in"
        delay = node.delay + node.time
    else -- 新节点
        isPlay = false
        anim = "uieff_UIN22EntrustLevel_Player_in01"
        delay = 0
    end
    local time = 333

    local tb_out = { -- TB_Player
        ["isPlay"] = isPlay,
        ["anim"] = anim,
        ["delay"] = delay,
        ["time"] = time
    }
    return tb_out
end

--endregion