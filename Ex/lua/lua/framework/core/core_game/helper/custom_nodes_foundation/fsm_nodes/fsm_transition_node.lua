--[[------------------------------------------------------------------------------------------
    静态配置节点：Check_FsmTransitionNode
]]--------------------------------------------------------------------------------------------
---@param cfg table
function CustomNodeConfigStatic.Check_FsmTransitionNode(cfg)
    if cfg.TrueState and cfg.Condition then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("FsmTransitionNode", CustomNodeConfigStatic.Check_FsmTransitionNode)


--[[------------------------------------------------------------------------------------------
  运行时节点: FsmTransitionNode 状态转换节点
]]--------------------------------------------------------------------------------------------

---@class FsmTransitionNode:CustomNode
_class( "FsmTransitionNode", CustomNode )
FsmTransitionNode = FsmTransitionNode

function FsmTransitionNode:Constructor()
    self.TrueState = nil
    self.FalseState = nil --条件不满足，会转向什么状态，不填就是不转换状态
    self.Condition = nil
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function FsmTransitionNode:InitializeNode(cfg, context)
    FsmTransitionNode.super.InitializeNode(self, cfg, context)
    self.TrueState = cfg.TrueState
    self.FalseState = cfg.FalseState
    self.CheckInterval = self:Parse(cfg.CheckInterval) -- 条件检查间隔，对于某些计算量比较大的条件检查，不能每帧都做
    self.LastCheckTime = nil

    local cnd_node = cfg.Condition
    local logic = context.Logic
    self.Condition = logic:CreateNode(cnd_node, context)
    self.Condition:Deactivate()
end


function FsmTransitionNode:Destroy()
    self.Condition:Destroy()
    FsmTransitionNode.super.Destroy(self)
end

function FsmTransitionNode:Reset()
    self.Condition:Reset()
end

function FsmTransitionNode:Activate()
    FsmTransitionNode.super.Activate(self)
    self.Condition:Activate()
end

function FsmTransitionNode:Deactivate()
    FsmTransitionNode.super.Deactivate(self)
    self.Condition:Deactivate()
end

-- this:
--//////////////////////////////////////////////////////////

function FsmTransitionNode:CheckTransitions()
    if not self.CheckInterval then
        return self:_InnerCheckTransition()
    else
        local now = TimeService:GetInstance().CurTime
        if not self.LastCheckTime or now - self.LastCheckTime >= self.CheckInterval then
            self.LastCheckTime = now
            return self:_InnerCheckTransition()
        else
            return nil
        end
    end
end

function FsmTransitionNode:_InnerCheckTransition()
    local next_state = nil
    if self.Condition:IsConditionReached() then
        next_state = self.TrueState
    else
        next_state = self.FalseState
    end
    if next_state then
        Log.debug("Condition Reached :", self.Condition._className)
    end
    return next_state
end

function FsmTransitionNode:Update(dt)
    self.Condition:Update(dt)
end

function FsmTransitionNode:CollectInterfaceInChildren(interfaceList, funcName)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.Condition)
end

