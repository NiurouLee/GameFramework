--[[
    普攻连线，光灵可以穿过怪物脚下
]]
_class("BuffLogicChainAcrossMonster", BuffLogicBase)
---@class BuffLogicChainAcrossMonster:BuffLogicBase
BuffLogicChainAcrossMonster = BuffLogicChainAcrossMonster

function BuffLogicChainAcrossMonster:Constructor(buffInstance, logicParam)
    self._remove = logicParam.remove or 0
    self._moveEffect = logicParam.moveEffect
end

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function BuffLogicChainAcrossMonster:DoLogic(notify)
    local notifyType = notify:GetNotifyType()
    if notifyType ~= NotifyType.PlayerEachMoveStart and notifyType ~= NotifyType.PlayerEachMoveEnd then
        return
    end

    --1是原地，队员会有一个原地移动结束
    local chainIndex = notify:GetChainIndex()
    if chainIndex == 1 then
        return
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicChainPathComponent
    local logicChainPathCmpt = teamEntity:LogicChainPath()
    local chainAcrossMonster = logicChainPathCmpt:GetChainAcrossMonster()
    if not chainAcrossMonster then
        return
    end

    local chainPosList = logicChainPathCmpt:GetLogicChainPath()
    local monsterPosList = logicChainPathCmpt:GetChainMonsterPosList()

    local entity = notify:GetNotifyEntity()

    local buffResult = nil
    if notifyType == NotifyType.PlayerEachMoveStart then
        local nextPos = notify:GetPos()
        local curChainIndex = math.max(1, chainIndex - 1)
        local curPos = chainPosList[curChainIndex]

        --准备移动，只有一种情况，变成音符
        --当前不在怪物里，下个格子在怪物里
        if not table.intable(monsterPosList, curPos) and table.intable(monsterPosList, nextPos) then
            buffResult = BuffResultChainAcrossMonster:New(entity:GetID(), notifyType, chainIndex, curPos, false)
        end
    elseif notifyType == NotifyType.PlayerEachMoveEnd then
        local curPos = notify:GetPos()
        local lastPos = notify:GetOldPos()

        --结束移动，只有一种情况，结束音符
        --当前不在怪物里，上个格子在怪物里
        if not table.intable(monsterPosList, curPos) and table.intable(monsterPosList, lastPos) then
            buffResult = BuffResultChainAcrossMonster:New(entity:GetID(), notifyType, chainIndex, curPos, true)
        end
    end

    if not buffResult then
        return
    end
    return buffResult
end
