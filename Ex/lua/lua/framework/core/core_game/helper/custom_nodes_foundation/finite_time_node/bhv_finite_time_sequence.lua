--FTBhvSequence 顺序执行 行为队列 (所有行为都是有限时间会结束的)
require "abstract_bhv_finite_time"

--[[------------------------------------------------------------------------------------------
    静态配置节点：CheckValid
]]--------------------------------------------------------------------------------------------

---@param nodeCfg table
function CustomNodeConfigStatic.Check_FTBhvSequence(nodeCfg)
    if nodeCfg.Nodes then 
        return true 
    end
    return false
end
CustomNodeConfigStatic.AddChecker("FTBhvSequence", CustomNodeConfigStatic.Check_FTBhvSequence)


--[[------------------------------------------------------------------------------------------
    运行时节点： FTBhvSequence
]]--------------------------------------------------------------------------------------------

---@class FTBhvSequence:FiniteTimeBhv
_class( "FTBhvSequence", FiniteTimeBhv )
FTBhvSequence = FTBhvSequence

function FTBhvSequence:Constructor()
    self.mBehaviorSeq = ArrayList:New()
    self.mCurBhvIndex = 1
end

-- CustomNode: 
--//////////////////////////////////////////////////////////
---@param cfg table
---@param context CustomNodeContext
function FTBhvSequence:InitializeNode(cfg, context)
    FTBhvSequence.super.InitializeNode(self, cfg, context)
    self.mCurBhvIndex = 1
    self.mBehaviorSeq:Clear()

    local nodeCfgList = cfg.Nodes
    local logic = context.Logic
    for i = 1, #nodeCfgList do
        local nodeCfg = nodeCfgList[i]
        local subbhv = logic:CreateNode(nodeCfg, context)
        CLHelper.Assert(subbhv)
        subbhv:Deactivate()
        self.mBehaviorSeq:PushBack(subbhv)
    end
end


function FTBhvSequence:Activate()
    FTBhvSequence.super.Activate(self)
    self:ActivateCurBhv()
end


function FTBhvSequence:Deactivate()
    FTBhvSequence.super.Deactivate(self)
    self:DeactivateCurBhv()
end


function FTBhvSequence:Destroy()
    local nodes = self.mBehaviorSeq
    for i=1, nodes:Size() do
        nodes:GetAt(i):Destroy()
    end
    self.mBehaviorSeq:Clear()
    FTBhvSequence.super.Destroy(self)
end


function FTBhvSequence:Reset()
    FTBhvSequence.super.Reset(self)
    self.mCurBhvIndex = 1
    
    local totalDuration = 0
    local nodes = self.mBehaviorSeq
    for i=1, nodes:Size() do
        local node = nodes:GetAt(i)
        node:Reset()
        if node.GetDuration then
            totalDuration = totalDuration + node:GetDuration()
        end
    end
    self:InitDuration(totalDuration)
end

function FTBhvSequence:IsDurationEnd()
    if self.mCurBhvIndex >= self.mBehaviorSeq:Size() then
       return true
    end
    return false
end


function FTBhvSequence:Update(dt)
    FTBhvSequence.super.Update(self, dt)

    local nodes = self.mBehaviorSeq
    local nodesSize = nodes:Size()
    if nodesSize == 0 then
        return
    end

    local dt_overplus = dt
    for i = 1, nodesSize do
        local curIndex = self.mCurBhvIndex
        if  curIndex > nodesSize then
            break
        end
        if dt_overplus <= 0 then
            break
        end

        local curBhv = nodes:GetAt(curIndex)
        local curDur = curBhv:GetDuration()
        curBhv:Update(dt_overplus)

        --内部的节点行为,可能销毁整个逻辑
        if  not self:IsActive() then
            break
        end

        dt_overplus = dt_overplus - curDur
        if curBhv:IsDurationEnd() then
            --进行下一个行为
            self:DeactivateCurBhv()
            self.mCurBhvIndex = curIndex + 1
            self:ActivateCurBhv()
        end

    end
end


-- this: 
--//////////////////////////////////////////////////////////
function FTBhvSequence:CollectInterfaceInChildren(interfaceList, funcName)
    local nodes = self.mBehaviorSeq
    for i=1, nodes:Size() do
        local node = nodes:GetAt(i)
        CustomNodeStatic.TraverseCollectInterface(interfaceList, funcName, node)
    end
end


function FTBhvSequence:ActivateCurBhv()
    local curIndex = self.mCurBhvIndex
    local nodes = self.mBehaviorSeq
    if curIndex >= 1 and curIndex <= nodes:Size() then
        nodes:GetAt(curIndex):Activate()
    end
end

function FTBhvSequence:DeactivateCurBhv()
    local curIndex = self.mCurBhvIndex
    local nodes = self.mBehaviorSeq
    if curIndex >= 1 and curIndex <= nodes:Size() then
        nodes:GetAt(curIndex):Deactivate()
    end
end