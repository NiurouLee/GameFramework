--[[
    普攻连线，光灵可以穿过怪物脚下
]]
_class("BuffViewSetChainAcrossMonster", BuffViewBase)
---@class BuffViewSetChainAcrossMonster : BuffViewBase
BuffViewSetChainAcrossMonster = BuffViewSetChainAcrossMonster

function BuffViewSetChainAcrossMonster:PlayView(TT)
    ---@type BuffResultSetChainAcrossMonster
    local result = self._buffResult

    local remove = result:GetRemove()
    local moveEffect = result:GetMoveEffect()

    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()

    ---@type RenderChainPathComponent
    local renderChainPathComponent = renderBoardEntity:RenderChainPath()
    renderChainPathComponent:SetChainAcrossMonster(remove == 0)
    renderChainPathComponent:SetChainAcrossMonsterMoveEffect(moveEffect)
end

--是否匹配参数
function BuffViewSetChainAcrossMonster:IsNotifyMatch(notify)
    ---@type BuffResultSetChainAcrossMonster
    local result = self._buffResult
    return true
end
