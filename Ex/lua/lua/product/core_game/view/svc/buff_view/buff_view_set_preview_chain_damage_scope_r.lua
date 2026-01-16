--[[
    
]]
_class("BuffViewSetPreviewChainDamageScope", BuffViewBase)
---@class BuffViewSetPreviewChainDamageScope : BuffViewBase
BuffViewSetPreviewChainDamageScope = BuffViewSetPreviewChainDamageScope

function BuffViewSetPreviewChainDamageScope:PlayView(TT)
    ---@type BuffResultSetPreviewChainDamageScope
    local result = self._buffResult

    local entityID = result:GetEntityID()
    local skillID = result:GetSkillID()

    local reBoard = self._world:GetRenderBoardEntity()
    ---@type ChainPreviewMonsterBehaviorComponent
    local chainPreviewMonsterBehaviorCmpt = reBoard:ChainPreviewMonsterBehavior()
    if chainPreviewMonsterBehaviorCmpt then
        chainPreviewMonsterBehaviorCmpt:SetPreviewMonsterRange(entityID, skillID)
    end
end

--是否匹配参数
---@param notify NTMonsterHPCChange
function BuffViewSetPreviewChainDamageScope:IsNotifyMatch(notify)
    ---@type BuffResultSetPreviewChainDamageScope
    local result = self._buffResult
    return true
end
