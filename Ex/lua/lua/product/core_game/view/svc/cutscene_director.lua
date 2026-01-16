--[[------------------------------------------------------------------------------------------
    CutsceneDirector：局内3D剧情播放器
]] --------------------------------------------------------------------------------------------

---@class CutsceneDelayType
_class("CutsceneDirector", Object)
CutsceneDirector = CutsceneDirector

function CutsceneDirector:Constructor(world)
    self._world = world
    self._phaseIndex = 0
    self._delayInfo = {}
end

function CutsceneDirector:NextPhaseIndex(phaseArray)
    if self._phaseIndex < #phaseArray then
        self._phaseIndex = self._phaseIndex + 1
        return self._phaseIndex
    end
end

function CutsceneDirector:CurPhaseIndex()
    return self._phaseIndex
end

function CutsceneDirector:CreateDelayInfo(index)
    self._delayInfo[index] = CutscenePhaseTime:New()
    return self._delayInfo[index]
end

function CutsceneDirector:DoPlayCutscenePhase(TT, cutSceneConfigID)
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type CutsceneConfigData
    local cursceneData = configSvc:GetCutsceneConfig(cutSceneConfigID)
    ---@type CutscenePhaseParam[]
    local phaseArray = cursceneData:GetCutscenePhaseArray()

    local phaseTaskIDArray = {}

    while self:NextPhaseIndex(phaseArray) do
        local phaseIndex = self:CurPhaseIndex()
        ---@type CutscenePhaseParam
        local phaseData = phaseArray[phaseIndex]
        if phaseData == nil then
            Log.fatal("phase end ---------- phaseIndex= " .. phaseIndex)
            break
        end

        while not self:_CheckPhaseCanStart(phaseArray, phaseIndex) do
            YIELD(TT)
        end

        ---@type CutscenePhaseTime
        local timeData = self:CreateDelayInfo(phaseIndex)

        ---目前只有指令化类型
        ---@type CutsceneInstructionParam
        local insParam = phaseData:GetPhaseParam()

        local taskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                self:DoCutsceneInstruction(TT, insParam)
            end
        )
        table.insert(phaseTaskIDArray, taskID)
    end

    --等待启动的所有协程都结束
    while not TaskHelper:GetInstance():IsAllTaskFinished(phaseTaskIDArray) do
        YIELD(TT)
    end

    ---@type CutsceneServiceRender
    local cutsceneSvc = self._world:GetService("Cutscene")
    cutsceneSvc:ResetSkyBoxColor()
end

function CutsceneDirector:_CheckPhaseCanStart(phaseArray, phaseIndex)
    local timeData = self._delayInfo[phaseIndex]
    if (timeData ~= nil) then
        return false
    end

    ---@type CutscenePhaseParam
    local phaseData = phaseArray[phaseIndex]
    local delayfromPhase = phaseData:GetDelayFromPhase() or 0
    local delayTime = phaseData:GetDelayMS()
    local delayType = phaseData:GetDelayType()
    local curTick = GameGlobal:GetInstance():GetCurrentTime()
    if delayfromPhase <= 0 then
        return true
    end

    if (delayfromPhase == phaseIndex) then
        Log.error("[skill] delayfromPhase == phaseIndex " .. phaseIndex)
    end
    ---@type CutscenePhaseTime
    local prePhaseRundata = self._delayInfo[delayfromPhase]
    if (prePhaseRundata == nil) then
        return false
    end
    if (delayType == CutsceneDelayType.AfterStart) then
        if (curTick - prePhaseRundata.StartTick >= delayTime) then
            return true
        else
            return false
        end
    elseif (delayType == CutsceneDelayType.AfterEnd) then
        if (prePhaseRundata.EndTick > 0 and curTick - prePhaseRundata.EndTick >= delayTime) then
            return true
        else
            return false
        end
    else
        Log.error("[skill] error delaytype")
    end
end

---@param instructionParam CutsceneInstructionParam
function CutsceneDirector:DoCutsceneInstruction(TT, instructionParam)
    ---@type CutscenePhaseContext
    local phaseContext = CutscenePhaseContext:New(self._world)

    local insArray = instructionParam:GetInstructionSet()
    local insIndex = 1
    local insSetCount = table.count(insArray)
    while insIndex > 0 and insIndex <= insSetCount do
        ---@type CutsceneBaseInstruction
        local instruction = insArray[insIndex]

        Log.debug("play cutscene instruction start:", instruction._className)
        local nextInsLabel = instruction:DoInstruction(TT, phaseContext)
        --Log.debug("play skill instruction finish:",instruction._className)
        if nextInsLabel then
            insIndex = self:_CalcNextLabel(insArray, nextInsLabel)
        else
            insIndex = insIndex + 1
        end
    end

    local phaseTaskList = phaseContext:GetPhaseTaskList()
    while not TaskHelper:GetInstance():IsAllTaskFinished(phaseTaskList) do
        YIELD(TT)
    end
end

function CutsceneDirector:_CalcNextLabel(insArray, nextInsLabel)
    --Log.fatal("nextInsLabel:>>>>>>>>>>>>>>>>>>>>>>>>",nextInsLabel)
    if nextInsLabel == InstructionConst.PhaseEnd then
        return -1
    else
        ---查找下一个phaseindex
        for k, v in ipairs(insArray) do
            ---@type CutsceneBaseInstruction
            local ins = v
            local insLabel = ins:GetInstructionLabel()
            if insLabel ~= nil and insLabel == nextInsLabel then
                return k
            end
        end
    end

    Log.fatal("instruction label not match:", nextInsLabel)
    return -1
end
