--[[
    逻辑与PlaySkillScopeForwardPhase类似，但当前只给卡莲使用，计算边缘特效只考虑了单列
]]
require "play_skill_phase_base_r"

_class("PlaySkillScopeForwardTransformNoAttackPhase", PlaySkillPhaseBase)
---@class PlaySkillScopeForwardTransformNoAttackPhase:PlaySkillPhaseBase
PlaySkillScopeForwardTransformNoAttackPhase = PlaySkillScopeForwardTransformNoAttackPhase

function PlaySkillScopeForwardTransformNoAttackPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseScopeForwardTransformParam
    local scopeForwardParam = phaseParam
    local gridEffectIDs = scopeForwardParam:GetGridEffectIDs()
    local bestEffectTime = scopeForwardParam:GetBestEffectTime()
    local gridIntervalTime = scopeForwardParam:GetGridIntervalTime()
    local hasDamage = scopeForwardParam:HasDamage()
    local hasConvert = scopeForwardParam:HasConvert()
    local hitAnimationName = scopeForwardParam:GetHitAnimationName()
    local hitEffectID = scopeForwardParam:GetHitEffectID()
    local effectDirection = scopeForwardParam:GetEffectDirection()
    local effectIgnore = scopeForwardParam:GetEffectIgnore()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ConvertGridElement)
    local targetGridType = convertResult:GetTargetElementType()
    local gridDataArray = convertResult:GetTargetGridArray()
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local pickUpGridPos = pickUpGridArray[1]

    local targetGirdList, f, maxGridCount = InnerGameSortGridHelperRender:SortGridWithCenterPos(gridDataArray, pickUpGridPos)


    local bottom = 0
    local top = 0

    local castPos = pickUpGridPos
    --获取上下边缘的格子相对纵向坐标
    for _, _gridPos in ipairs(gridDataArray) do
        local deltaY = _gridPos.y - castPos.y
        if deltaY > 0 and deltaY > top then
            top = deltaY
        elseif deltaY < 0 and deltaY < bottom then
            bottom = deltaY
        end
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    local tConvertInfo = {}

    local tidHitTask = {}
    for i = 1, maxGridCount do
        for dir = 1, 9 do
            local t = targetGirdList[dir]
            if #(t.gridList) >= i then
                local gridPos = t.gridList[i]
                if i > effectIgnore then
                    local effID, dir, scale = self:_CalculateEffect(castPos, gridPos, scopeForwardParam, top, bottom)
                        local needConvert = gridDataArray and table.icontains(gridDataArray, gridPos)
                        if not scopeForwardParam:IsNeedRotateEff() then
                            dir = nil
                        end
                        --方法里考虑了特效缩放
                        GameGlobal.TaskManager():CoreGameStartTask(
                                self._SingleGridEffectTranform,
                                self,
                                effID,
                                gridPos,
                                bestEffectTime,
                                targetGridType,
                                dir,
                                scale,
                                needConvert
                        )
                        local nOldGridType = PieceType.None
                        local gridEntity = pieceService:FindPieceEntity(gridPos)
                        ---@type PieceComponent
                        local pieceCmpt = gridEntity:Piece()
                        nOldGridType = pieceCmpt:GetPieceType()

                        local convertInfo = NTGridConvert_ConvertInfo:New(gridPos, nOldGridType, targetGridType)
                        table.insert(tConvertInfo, convertInfo)
                end

            end
        end
        if i ~= maxGridCount then
            YIELD(TT, gridIntervalTime)
        end
    end
    local finishDelayTime = scopeForwardParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)

    if #tConvertInfo > 0 then
        ---@type PlayBuffService
        local svcPlayBuff = self._world:GetService("PlayBuff")

        local notify = NTGridConvert:New(casterEntity, tConvertInfo)
        notify:SetConvertEffectType(SkillEffectType.ConvertGridElement)
        notify.__attackPosMatchRequired = true
        svcPlayBuff:PlayBuffView(TT, notify)
    end
end

---@param phaseParam SkillPhaseScopeForwardTransformParam
function PlaySkillScopeForwardTransformNoAttackPhase:_CalculateEffect(castPos, gridPos, phaseParam, topEdge, bottomEdge)
    local effID = nil
    local dir = nil
    local scale = nil

    local deltaPos = gridPos - castPos

    --方向
    dir = Vector2.Normalize(deltaPos)

    --层数，决定缩放
    local layer = math.max(math.abs(deltaPos.x), math.abs(deltaPos.y))
    local scaleStart = phaseParam:GetEffectStart()
    local scaleDefault = phaseParam:GetDefaultScale()
    local layerScale = phaseParam:GetLayerScale()
    local scaleN = 0
    if layer >= scaleStart then
        scaleN = scaleDefault + (layer - scaleStart) * layerScale
    else
        scaleN = scaleDefault
    end
    scale = Vector3(scaleN,scaleN, scaleN)

    --特效
    if deltaPos.y == topEdge and topEdge > 0 then
        --上边缘
        effID = phaseParam:GetGridEdgeEffect()
    elseif deltaPos.y == bottomEdge and bottomEdge < 0 then
        --下边缘
        effID = phaseParam:GetGridEdgeEffect()
    else
        --中间格子，间隔播放特效
        local effs = phaseParam:GetGridEffectIDs()
        local gridCount = #effs
        local effIdx = deltaPos.y % gridCount
        if effIdx == 0 then
            effIdx = gridCount
        end
        effID = effs[effIdx]
    end

    return effID, dir, scale
end

--转色特效带旋转和缩放
function PlaySkillScopeForwardTransformNoAttackPhase:_SingleGridEffectTranform(
        TT,
        gridEffectID,
        gridPos,
        bestEffectTime,
        targetGridType,
        dir,
        scale,
        needConvert)
    local effEntity = self._world:GetService("Effect"):CreateTransformEffect(gridEffectID, gridPos, dir, scale)

    if not needConvert then
        return
    end

    YIELD(TT, bestEffectTime)
    --执行转色
    ---@type BoardServiceRender
    local boardService = self._world:GetService("BoardRender")

    boardService:ReCreateGridEntity(targetGridType, gridPos, false)

    YIELD(TT)

    ---@type PieceServiceRender
    local piece_service = self._world:GetService("Piece")
    if piece_service then
        piece_service:RefreshPieceAnim()
    end
end
