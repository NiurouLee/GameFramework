require "play_skill_phase_base_r"

_class("PlaySkillScopeForwardNoAttackPhase", PlaySkillPhaseBase)
---@class PlaySkillScopeForwardNoAttackPhase: PlaySkillPhaseBase
PlaySkillScopeForwardNoAttackPhase = PlaySkillScopeForwardNoAttackPhase

function PlaySkillScopeForwardNoAttackPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseScopeForwardParam
    local scopeForwardParam = phaseParam
    local gridEffectID = scopeForwardParam:GetGridEffectID()
    local bestEffectTime = scopeForwardParam:GetBestEffectTime()
    local gridIntervalTime = scopeForwardParam:GetGridIntervalTime()
    local hasConvert = scopeForwardParam:HasConvert()
    local effectDirection = scopeForwardParam:GetEffectDirection()


    ---@type  Vector2
    local castPos = casterEntity:GridLocation().Position

    --支持 反向、根据点击格子数反向
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    ---@type SkillConvertGridElementEffectResult
    local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
    local targetGridType = convertResult:GetTargetElementType()
    local gridDataArray = convertResult:GetTargetGridArray()
    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local pickUpGridPos = pickUpGridArray[1]



    local targetGirdList, f, maxGridCount = InnerGameSortGridHelperRender:SortGridWithCenterPos(gridDataArray, pickUpGridPos)


    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    local tConvertInfo = {}
    local tnConvertTaskID = {}
    local tidHitTask = {}

    for i = 1, maxGridCount do
        for dir = 1, 9 do
            local t = targetGirdList[dir]
            local gridIndex = i
            if gridIndex > 0 and #(t.gridList) >= gridIndex then
                local gridPos = t.gridList[gridIndex]
                local oldGridType = PieceType.None
                local gridEntity = pieceService:FindPieceEntity(gridPos)
                ---@type PieceComponent
                local pieceCmpt = gridEntity:Piece()
                oldGridType = pieceCmpt:GetPieceType()

                local convertInfo = NTGridConvert_ConvertInfo:New(gridPos, oldGridType, targetGridType)
                table.insert(tConvertInfo, convertInfo)
                local tid = GameGlobal.TaskManager():CoreGameStartTask(
                        self:SkillService()._SingleGridEffect,
                        self:SkillService(),
                        gridEffectID,
                        gridPos,
                        bestEffectTime,
                        targetGridType
                )
                table.insert(tnConvertTaskID, tid)
            end
        end
        if i ~= maxGridCount then
            YIELD(TT, gridIntervalTime)
        end
    end
    local finishDelayTime = scopeForwardParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
    --通知出现水格子表现
    local playSkillService = self._world:GetService("PlaySkill")
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")

    while not TaskHelper:GetInstance():IsAllTaskFinished(tnConvertTaskID) do
        YIELD(TT)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(tidHitTask) do
        YIELD(TT)
    end

    local nt = NTGridConvert:New(casterEntity, tConvertInfo)
    nt:SetConvertEffectType(SkillEffectType.ConvertGridElement)

    svcPlayBuff:PlayBuffView(TT, nt)
end