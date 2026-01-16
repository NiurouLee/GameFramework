--[[
    播放技能表现
]]
_class("BuffViewCastSkillWithChainCount", BuffViewBase)
---@class BuffViewCastSkillWithChainCount:BuffViewBase
BuffViewCastSkillWithChainCount = BuffViewCastSkillWithChainCount

function BuffViewCastSkillWithChainCount:PlayView(TT, notify)
    ---@type Entity
    local entity = self._entity

    ---@type BuffResultCastSkillWithChainCount
    local result = self._buffResult
    local entityID = result:GetEntityID()
    local petEntity = self._world:GetEntityByID(entityID)

    ---@type BuffViewComponent
    local buffView = petEntity:BuffView()
    buffView:SetBuffValue("AgentChainEntityID", entity:GetID())
end
