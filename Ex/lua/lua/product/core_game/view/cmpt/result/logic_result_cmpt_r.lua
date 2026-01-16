--[[------------------------------------------------------------------------------------------
    LogicResultComponent : 缓存来自逻辑层的结果数据
]] --------------------------------------------------------------------------------------------

---@class LogicResultComponent: Object
_class("LogicResultComponent", Object)

function LogicResultComponent:Constructor()
    self._logicStep = LogicStepType.Init
    self._result = {}
end

--逻辑阶段计算的最后填充一次结果
function LogicResultComponent:SetLogicResult(logicStep, result)
    if self.logicStep == logicStep then
        Log.fatal("AddLogicResult() error: duplicate logic step result! step=", logicStep)
        return
    end
    self._logicStep = logicStep
    self._result[logicStep] = result
end

--使用完成后播放器负责清空结果数据
function LogicResultComponent:ClearLogicResult()
    self._logicStep = LogicStepType.Init
    self._result = {}
end

function LogicResultComponent:GetLogicStep()
    return self._logicStep
end

--使用的时候检查一下逻辑阶段是否匹配
function LogicResultComponent:GetLogicResult(logicStep)
    if logicStep ~= self._logicStep then
        Log.info("GetLogicResult() error: logic step not match! selfstep=", self._logicStep, " step=", logicStep)
        --return
    end
    return self._result[logicStep]
end

---@return LogicResultComponent
function Entity:LogicResult()
    return self:GetComponent(self.WEComponentsEnum.LogicResult)
end

function Entity:HasLogicResult()
    return self:HasComponent(self.WEComponentsEnum.LogicResult)
end

function Entity:AddLogicResult()
    local index = self.WEComponentsEnum.LogicResult
    local component = LogicResultComponent:New()
    self:AddComponent(index, component)
end

function Entity:RemoveLogicResult()
    if self:HasLogicResult() then
        self:RemoveComponent(self.WEComponentsEnum.LogicResult)
    end
end
