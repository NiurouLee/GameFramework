
--[[------------------------------------------------------------------------------------------
    静态配置节点：Check_CustomBehaviorStateNode
]]--------------------------------------------------------------------------------------------
---@param cfg table
function CustomNodeConfigStatic.Check_CustomBehaviorStateNode(cfg)
    if cfg.CustomBehavior and cfg.GoalState then 
        return true 
    end

    if cfg.Transitions then
        return false
    end
    return false
end
CustomNodeConfigStatic.AddChecker("CustomBehaviorStateNode", CustomNodeConfigStatic.Check_CustomBehaviorStateNode)


--[[------------------------------------------------------------------------------------------
  运行时节点: CustomBehaviorStateNode 自定义行为节点，需要完整的运行完所有自定义行为，才会转移到后续节点
  因此这个节点 ，不允许定义Transition字段（关于这一点，暂时还没想好，也许以后有需求，需要在自定义行为进行中转换状态）
  目前，状态机的全局状态转移，还是会生效的
]]--------------------------------------------------------------------------------------------

---@class CustomBehaviorStateNode:StateNode
_class( "CustomBehaviorStateNode", StateNode )
CustomBehaviorStateNode = CustomBehaviorStateNode

function CustomBehaviorStateNode:Constructor()
    self.CustomBehavior = nil
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function CustomBehaviorStateNode:InitializeNode(cfg, context)
    CustomBehaviorStateNode.super.InitializeNode(self, cfg, context)
    self.GoalState = self:Parse(cfg.GoalState)
    local logic = context.Logic
    local nodeCfg = cfg.CustomBehavior
    self.CustomBehavior = logic:CreateNode(nodeCfg, context)
    self.CustomBehavior:Deactivate()
end


function CustomBehaviorStateNode:Destroy()
    self.CustomBehavior:Destroy()
    CustomBehaviorStateNode.super.Destroy(self)
end

function CustomBehaviorStateNode:Activate()
    CustomBehaviorStateNode.super.Activate(self)
    if self.CustomBehavior then
        self.CustomBehavior:Activate()
    end
end


function CustomBehaviorStateNode:Deactivate()
    CustomBehaviorStateNode.super.Deactivate(self)
    if self.CustomBehavior then
        self.CustomBehavior:Deactivate()
    end
end

-- this:
--//////////////////////////////////////////////////////////

function CustomBehaviorStateNode:Enter()
    CustomBehaviorStateNode.super.Enter(self)
end

function CustomBehaviorStateNode:Exit()
    CustomBehaviorStateNode.super.Exit(self)
    self.CustomBehavior:Reset()
end

function CustomBehaviorStateNode:CheckTransitions()
    if self.CustomBehavior:CanStop() then
        return self.GoalState
    end
    return nil
end

function CustomBehaviorStateNode:Update(dt)
    self.CustomBehavior:Update(dt)
end

function CustomBehaviorStateNode:CollectInterfaceInChildren(interfaceList, funcName)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.CustomBehavior)
end
