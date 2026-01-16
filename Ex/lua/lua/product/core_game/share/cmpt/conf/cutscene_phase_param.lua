--[[------------------------------------------------------------------------------------------
    CutscenePhaseParam : 剧情参数
]] --------------------------------------------------------------------------------------------

---剧情延时播放类型
---@class CutsceneDelayType
local CutsceneDelayType = {
    AfterStart = 1,     
    AfterEnd = 2,       
}
CutsceneDelayType = CutsceneDelayType
_enum("CutsceneDelayType", CutsceneDelayType)

---@class CutscenePhaseTime: Object
_class("CutscenePhaseTime", Object)
CutscenePhaseTime = CutscenePhaseTime
function CutscenePhaseTime:Constructor()
    self.StartTick = GameGlobal:GetInstance():GetCurrentTime()
    self.EndTick = 0
end

---@class CutscenePhaseParam: Object
_class("CutscenePhaseParam", Object)
CutscenePhaseParam = CutscenePhaseParam

---@param phaseParam CutsceneInstructionParam
function CutscenePhaseParam:Constructor(delaytype, delayphase, delayms, phaseParam)
    self._phaseParam = phaseParam
    self._delayType = delaytype
    self._delayMS = delayms
    self._delayFromPhase = delayphase
end

---@return CutsceneInstructionParam
function CutscenePhaseParam:GetPhaseParam()
    return self._phaseParam
end

function CutscenePhaseParam:GetDelayType()
    return self._delayType
end

function CutscenePhaseParam:GetDelayMS()
    return self._delayMS
end

function CutscenePhaseParam:GetDelayFromPhase()
    return self._delayFromPhase
end

