require "play_skill_phase_base_r"
--@class PlaySkillSquareRingPhase: Object
_class("PlaySkillConvertElementPhase", PlaySkillPhaseBase)
PlaySkillConvertElementPhase = PlaySkillConvertElementPhase

function PlaySkillConvertElementPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseConvertElementParam
    local convertElementParam = phaseParam
    local gridEffectID = convertElementParam:GetGridEffectID()
    local bestEffectTime = convertElementParam:GetBestEffectTime()
    local finishDelayTime = convertElementParam:GetFinishDelayTime()
    local notifyPreview = convertElementParam:GetNotifyPreview()

    local convertSource = SkillEffectType.ConvertGridElement
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillManualConvertGridElementEffectResult
    local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
    if not convertResult then -- 我悟了，直接设计成加参数配置好了
        convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ManualConvert)
        convertSource = SkillEffectType.ManualConvert
    end
    if not convertResult then
        return
    end
    local gridData = convertResult:GetTargetGridArray()
    local targetGridType = convertResult:GetTargetElementType()

    local tConvertInfo = {}

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---@type PlaySkillService
    local playSkillService = self._world:GetService("PlaySkill")

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()

    local tnConvertTaskID = {}

    for k, pos in pairs(gridData) do
        local oldGridType = PieceType.None
        local gridEntity = pieceService:FindPieceEntity(pos)
        ---@type PieceComponent
        local pieceCmpt = gridEntity:Piece()
        oldGridType = pieceCmpt:GetPieceType()
        local convertInfo = NTGridConvert_ConvertInfo:New(pos, oldGridType, targetGridType)
        table.insert(tConvertInfo, convertInfo)

        local tid =
            GameGlobal.TaskManager():CoreGameStartTask(
            self:SkillService()._SingleGridEffect,
            self:SkillService(),
            gridEffectID,
            pos,
            bestEffectTime,
            targetGridType
        )

        --刷新预览层数据
        if notifyPreview == 1 then
            env:SetPieceType(pos, targetGridType)
        end

        table.insert(tnConvertTaskID, tid)
    end

    YIELD(TT, finishDelayTime)
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")

    while not TaskHelper:GetInstance():IsAllTaskFinished(tnConvertTaskID) do
        YIELD(TT)
    end

    local nt = NTGridConvert:New(casterEntity, tConvertInfo)
    nt:SetConvertEffectType(convertSource)

    svcPlayBuff:PlayBuffView(TT, nt)
end
