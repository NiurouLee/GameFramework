--[[------------------------------------------------------------------------------------------
    CutsceneConfigData : 剧情指令配置数据
]] --------------------------------------------------------------------------------------------

_class("CutsceneConfigData", Object)
---@class CutsceneConfigData: Object
CutsceneConfigData = CutsceneConfigData

CutscenePhaseType = {
    Instruction = 0, --指令类型
}

function CutsceneConfigData:Constructor()
    self._phaseDataArray = {}

    self._viewParamDic = {}
    self._viewParamDic[CutscenePhaseType.Instruction] = CutsceneInstructionParam
end

---解析技能配置数据
---@param cutsceneID number 剧情ID
function CutsceneConfigData:ParseCutsceneConfig(cutsceneID)
    ---先清空
    self._phaseDataArray = {}

    local phaseRawDataArray = self:_GetPhaseRawDataArray(cutsceneID)
    local phaseCount = phaseRawDataArray and phaseRawDataArray:Size() or 0
    for i = 1, phaseCount do
        local phaseRawData = phaseRawDataArray:GetAt(i)
        ---@type CutscenePhaseParam 
        local onePhaseData = self:_ParseOnePhaseRawData(phaseRawData)
        self._phaseDataArray[#self._phaseDataArray + 1] = onePhaseData
    end

    return self._phaseDataArray
end

---提取解析后的数据
function CutsceneConfigData:GetCutscenePhaseArray()
    return self._phaseDataArray
end

---提取所有的phase配置数据
function CutsceneConfigData:_GetPhaseRawDataArray(cutsceneID)
    local rawDataArray = ArrayList:New()

    local cutsceneTableName = "cfg_cutscene_" .. cutsceneID

    local fileExist = ResourceManager:GetInstance():HasLua(cutsceneTableName)
    if not fileExist then
        Log.warn("cannot find cutscene:", cutsceneTableName)
        return nil
    end

    local cutsceneList = table.cloneconf(Cfg[cutsceneTableName]())
    table.sort(
        cutsceneList,
        function(a, b)
            return a.ViewPhase < b.ViewPhase
        end
    )

    for k, v in ipairs(cutsceneList) do
        rawDataArray:Insert(v, k)
    end
    return rawDataArray
end

---解析单个phase的数据
function CutsceneConfigData:_ParseOnePhaseRawData(phaseRawData)
    if not phaseRawData then 
        return
    end

    local phaseClass = self._viewParamDic[phaseRawData.PhaseType]
    if not phaseClass then
        Log.fatal("parse cutscene phase error, phase type = ", phaseRawData.PhaseType)
        return
    end

    ---@type CutsceneInstructionParam
    local insParam = phaseClass:New(phaseRawData.PhaseParam)

    ---@type CutscenePhaseParam Phase数据，包括指令数据
    local phaseParam = CutscenePhaseParam:New(phaseRawData.DelayType, 
        phaseRawData.DelayFromPhase, phaseRawData.DelayMS, insParam)
    return phaseParam
end
