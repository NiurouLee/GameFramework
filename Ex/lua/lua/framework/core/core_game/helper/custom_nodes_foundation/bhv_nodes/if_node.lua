--IF If节点：条件 + true行为 + false行为  true和false行为为可选项，至少有一个


--[[------------------------------------------------------------------------------------------
    静态配置节点：CheckValid
]]--------------------------------------------------------------------------------------------

---@param nodeCfg table
function CustomNodeConfigStatic.Check_IF(nodeCfg)
    if not nodeCfg.Condition then 
        return false 
    end

    if not nodeCfg.TrueBhv and not nodeCfg.FalseBhv then
        return false
    end
    return true
end
CustomNodeConfigStatic.AddChecker("IF", CustomNodeConfigStatic.Check_IF)


--[[------------------------------------------------------------------------------------------
    运行时节点： IF
]]--------------------------------------------------------------------------------------------

---@class IF:HasBeginBhv
_class( "IF", HasBeginBhv )
IF = IF

function IF:Constructor()
    self.TrueBhv = nil
    self.FalseBhv = nil
    self.Condition = nil
    self.IsConditionReached = false
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function IF:InitializeNode(cfg, context)
    IF.super.InitializeNode(self, cfg, context)
    local logic = context.Logic
    self.Condition = logic:CreateNode(cfg.Condition, context)
    self.Condition:Deactivate()
    if cfg.TrueBhv then
        self.TrueBhv = logic:CreateNode(cfg.TrueBhv, context)
        self.TrueBhv:Deactivate()
    end
    if cfg.FalseBhv then
        self.FalseBhv = logic:CreateNode(cfg.FalseBhv, context)
        self.FalseBhv:Deactivate()
    end
    CLHelper.Assert(self.TrueBhv or self.FalseBhv)
end


function IF:Activate()
    IF.super.Activate(self)
    self.Condition:Activate()
    self.IsConditionReached = self.Condition:IsConditionReached()
    if self.IsConditionReached then
        if self.TrueBhv then
            self.TrueBhv:Activate()
        end
    else
        if self.FalseBhv then
            self.FalseBhv:Activate()
        end
    end
end


function IF:Deactivate()
    IF.super.Deactivate(self)
    self.Condition:Deactivate()
    if self.TrueBhv then
        self.TrueBhv:Deactivate()
    end

    if self.FalseBhv then
        self.FalseBhv:Deactivate()
    end
end


function IF:Destroy()
    self.Condition:Destroy()
    if self.TrueBhv then
        self.TrueBhv:Destroy()
    end

    if self.FalseBhv then
        self.FalseBhv:Destroy()
    end
    IF.super.Destroy(self)
end


function IF:Reset()
    IF.super.Reset(self)
    self.Condition:Reset()
    if self.TrueBhv then
        self.TrueBhv:Reset()
    end

    if self.FalseBhv then
        self.FalseBhv:Reset()
    end
    self.IsConditionReached = false
end

function IF:OnBegin()
    self.IsConditionReached = self.Condition:IsConditionReached()
    self:ChangeActiveState(self.IsConditionReached)
end
function IF:OnUpdate(dt)
    self:UpdateBhv(self.IsConditionReached, dt)
end

function IF:CanStop()
    if self.IsConditionReached then
        if self.TrueBhv and self.TrueBhv.CanStop and self.TrueBhv:CanStop() ==false then
            return false
        end
    else
        if self.FalseBhv and self.FalseBhv.CanStop and self.FalseBhv:CanStop() == false then
            return false
        end
    end
    return true
end


-- this: 
--//////////////////////////////////////////////////////////
function IF:CollectInterfaceInChildren(interfaceList, funcName)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.Condition)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.TrueBhv)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.FalseBhv)
end

function IF:ChangeActiveState(is_true)
    if is_true then
        if self.TrueBhv then
            self.TrueBhv:Activate()
        end
        if self.FalseBhv then
            self.FalseBhv:Deactivate()
        end
    else
        if self.TrueBhv then
            self.TrueBhv:Deactivate()
        end
        if self.FalseBhv then
            self.FalseBhv:Activate()
        end
    end
end

function IF:UpdateBhv(is_true,dt)
    if is_true then
        if self.TrueBhv then
            self.TrueBhv:Update(dt)
        end
    else
        if self.FalseBhv then
            self.FalseBhv:Update(dt)
        end
    end
end