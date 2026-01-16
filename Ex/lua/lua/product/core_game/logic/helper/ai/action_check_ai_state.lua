--[[
    ActionCheckAIState 获得当前的状态
--]] 
require "action_is_base"
_class("ActionCheckAIState", ActionIsBase)
---@class ActionCheckAIState:ActionIsBase
ActionCheckAIState = ActionCheckAIState


function ActionCheckAIState:OnUpdate()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local curState = aiCmpt:GetAITreeState()

    return AINewNodeStatus.Other + curState
end
