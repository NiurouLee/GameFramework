
--[[------------------------------------------------------------------------------------------
    静态配置节点：Check_StateNode
]]--------------------------------------------------------------------------------------------
---@param cfg table
function CustomNodeConfigStatic.Check_StateNode(cfg)
    if cfg.Type then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("StateNode", CustomNodeConfigStatic.Check_StateNode)


--[[------------------------------------------------------------------------------------------
  运行时节点: StateNode
]]--------------------------------------------------------------------------------------------

---@class StateNode:CustomNode
_class( "StateNode", CustomNode )
StateNode = StateNode

function StateNode:Constructor()
    self.mStateID = ""
    self.Transition = ArrayList:New() 
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function StateNode:InitializeNode(cfg, context)
    StateNode.super.InitializeNode(self, cfg, context)
    self.mStateID = cfg.Type
    --一般情况下 用StateType作为StateID，但是，有的时候一个AI配置中可能出现多个相同Type的节点，这时就需要配置StateID来进行区分了
    if cfg.StateID then
        self.mStateID = cfg.StateID
    end
    local nodeCfgList = cfg.Transitions
    if nodeCfgList then
        local logic = context.Logic
        for i = 1, #nodeCfgList do
            local nodeCfg = nodeCfgList[i]
            local subbhv = logic:CreateNode(nodeCfg, context)
            subbhv:Deactivate()
            self.Transition:PushBack(subbhv)
        end
    end
end


function StateNode:Destroy()
    local nodes = self.Transition
    for i=1, nodes:Size() do
        nodes:GetAt(i):Destroy()
    end
    self.Transition:Clear()
    StateNode.super.Destroy(self)
end

-- this:
--//////////////////////////////////////////////////////////

function StateNode:StateID()
    return self.mStateID
end

function StateNode:Enter()
    self:Activate()
    for i = 1, self.Transition:Size() do
        local transition = self.Transition:GetAt(i)
        transition:Activate()
    end
end

function StateNode:Exit()
    self:Deactivate()
    for i = 1, self.Transition:Size() do
        local transition = self.Transition:GetAt(i)
        transition:Deactivate()
        transition:Reset()
    end
end

function StateNode:CheckTransitions()
    for i = 1, self.Transition:Size() do
        local transition = self.Transition:GetAt(i)
        local goal_state = transition:CheckTransitions()
        if goal_state then
            return goal_state
        end
    end
    return nil
end

function StateNode:Update(dt)
    for i = 1, self.Transition:Size() do
        local transition = self.Transition:GetAt(i)
        transition:Update(dt)
    end
end

function StateNode:CollectInterfaceInChildren(interfaceList, funcName)
    local nodes = self.Transition
    for i=1, nodes:Size() do
        local node = nodes:GetAt(i)
        CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, node)
    end
end
