--[[------------------------------------------------
    ActionCheckHasTrap 根据场上是否存在机关 返回true,false
--]] ------------------------------------------------
require "ai_node_new"
---@class ActionCheckHasTrap:AINewNode
_class("ActionCheckHasTrap", AINewNode)
ActionCheckHasTrap = ActionCheckHasTrap



---@param cfg table
---@param context CustomNodeContext
function ActionCheckHasTrap:InitializeNode(cfg, context, parentNode, configData)
    ActionCheckHasTrap.super.InitializeNode(self, cfg, context, parentNode, configData)

    self._trapID = configData[1]    
end
function ActionCheckHasTrap:OnUpdate()
    ---@type TrapServiceLogic
    local trapLogicSvc = self._world:GetService("TrapLogic")
    local trapPosList = trapLogicSvc:FindTrapPosByTrapID(self._trapID)
    if #trapPosList >0 then
        return AINewNodeStatus.Success
    else
        return AINewNodeStatus.Failure
    end
end
