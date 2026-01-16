--BhvFiniteTimeLoop循环执行 
--注意，子节点中的行为时间长度，必须小于Interval，以保证可以执行希望的循环次数


--[[------------------------------------------------------------------------------------------
    静态配置节点：CheckValid
]]--------------------------------------------------------------------------------------------

---@param nodeCfg table
function CustomNodeConfigStatic.Check_BhvFiniteTimeLoop(nodeCfg)
    if nodeCfg.Node then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("BhvFiniteTimeLoop", CustomNodeConfigStatic.Check_BhvFiniteTimeLoop)


--[[------------------------------------------------------------------------------------------
    运行时节点： BhvFiniteTimeLoop
]]--------------------------------------------------------------------------------------------

---@class BhvFiniteTimeLoop:FiniteTimeBhv
_class( "BhvFiniteTimeLoop", FiniteTimeBhv )
BhvFiniteTimeLoop = BhvFiniteTimeLoop

function BhvFiniteTimeLoop:Constructor()
    self.Node = nil
    self.IsFinished = false
    self.RemainTimeToNextExcute = nil
end

-- CustoNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustoNodeContext
function BhvFiniteTimeLoop:InitializeNode(cfg, context)
    BhvFiniteTimeLoop.super.InitializeNode(self, cfg, context)
    local logic = context.Logic
    self.Node = logic:CreateNode(cfg.Node, context)
    self.Node:Deactivate()
    self.Interval = self:Parse(cfg.Interval)
    local duration = self:Parse(cfg.Duration)
    self:InitDuration(duration)
end


function BhvFiniteTimeLoop:Activate()
    BhvFiniteTimeLoop.super.Activate(self)
    if self.Node then
        self.Node:Activate()
    end
end


function BhvFiniteTimeLoop:Deactivate()
    BhvFiniteTimeLoop.super.Deactivate(self)
    self.Node:Deactivate()
end


function BhvFiniteTimeLoop:Destroy()
    self.Node:Destroy()
    BhvFiniteTimeLoop.super.Destroy(self)
end


function BhvFiniteTimeLoop:Reset()
    BhvFiniteTimeLoop.super.Reset(self)
    self.IsFinished = false
    self.RemainTimeToNextExcute = nil
    local duration = self:Parse(self.Config.Duration)
    self:InitDuration(duration)
    self.Node:Reset()
end


function BhvFiniteTimeLoop:OnUpdate(dt)
    if not self.RemainTimeToNextExcute then
        self.RemainTimeToNextExcute = self.Interval
    else
        self.RemainTimeToNextExcute = self.RemainTimeToNextExcute - dt
    end
    
    if  self.RemainTimeToNextExcute <=0 then
        if self.Node:CanStop() == false then
            Log.fatal("BhvFiniteTimeLoop node duration longer than Interval Type=", self.Logic.CustomLogicType, " id=", self.Logic.CustomLogicID)
            dump(self.Config)
            Log.fatal(Log.traceback())
        else
            self.Node:Reset()
            self.RemainTimeToNextExcute = self.Interval + self.RemainTimeToNextExcute
        end
    end
    self.Node:Update(dt);
end


function BhvFiniteTimeLoop:CanStop()
    return BhvFiniteTimeLoop.super.CanStop(self) and self.Node:CanStop()
end


-- this: 
--//////////////////////////////////////////////////////////
function BhvFiniteTimeLoop:CollectInterfaceInChildren(interfaceList, funcName)
    CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, self.Node)
end
