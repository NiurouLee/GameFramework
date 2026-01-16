--[[---------------------------------------------------------------
    ActionIs_AllMoveDone 检测是否所有AI的移动标记为true
--]] ---------------------------------------------------------------
require "action_is_base"
---------------------------------------------------------------
_class("ActionIs_AllMoveDone", ActionIsBase)
---@class ActionIs_AllMoveDone:ActionIsBase
ActionIs_AllMoveDone = ActionIs_AllMoveDone

function ActionIs_AllMoveDone:OnUpdate()
    local ret = self:_IsAllAIMoveDone()
    if ret then
        self:PrintLog("检所有AI移动结束！")
        return AINewNodeStatus.Success
    else
        self:PrintLog("AI移动中...")
        return AINewNodeStatus.Failure
    end
end
---------------------------------------------------------------
