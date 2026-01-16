require "play_skill_phase_base_r"

_class("PlaySkillTrainResetElementPhase", PlaySkillPhaseBase)
---@class PlaySkillTrainResetElementPhase: Object
PlaySkillTrainResetElementPhase = PlaySkillTrainResetElementPhase

function PlaySkillTrainResetElementPhase:PlayFlight(TT, casterEntity, phaseParam)
    ---@type SkillPhaseTrainResetElementParam
    local effectParam = phaseParam
    local gridEffectID = effectParam:GetGridEffectID()
    local bestEffectTime = effectParam:GetBestEffectTime()
    local gridIntervalTime = effectParam:GetGridIntervalTime()

        ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")
    ---@type  UnityEngine.Vector2
    local castPos = casterEntity:GridLocation().Position
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    -- local targetGridType = nil
    ---@type SkillEffectResult_ResetGridElement
    local resetResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    ---@type SkillEffectResult_ResetGridData[]
    local resetDataArray = resetResult:GetResetGridData()
    -- local convertGridPosList = convertResult:GetTargetGridArray()---convertResult:GetSkillEffectScopeResult() --selectSingleDirectionComponent:GetConvertGridPosArray()

    ---@type HitBackType
    local directType = renderPickUpComponent:GetLastPickUpDirection() -- selectSingleDirectionComponent:GetDirectType()
    ---@type table<number, SkillEffectResult_ResetGridData[]>
    local gridPosList = self:_SortGridByDirection(resetDataArray, directType)

    local beginIndex, endIndex, step = self:_GetStepAndBegin(directType)

    local tConvertInfo = {}

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")
    ---@type PlaySkillService
    local svcPlaySkill = self._world:GetService("PlaySkill")
    for index = beginIndex, endIndex, step do
        local dataList = gridPosList[index]
        if dataList then
            for _, data in pairs(dataList) do
                local pos = {
                    x = data.m_nX,
                    y = data.m_nY
                }
                local nOldGridType = PieceType.None
                local gridEntity = pieceService:FindPieceEntity(pos)
                ---@type PieceComponent
                local pieceCmpt = gridEntity:Piece()
                nOldGridType = pieceCmpt:GetPieceType()

                local pos = Vector2.New(data.m_nX, data.m_nY)
                local targetGridType = data.m_nNewElementType
                --Log.fatal("pos:", tostring(pos))
                GameGlobal.TaskManager():CoreGameStartTask(
                    self:SkillService()._SingleGridEffect,
                    self:SkillService(),
                    gridEffectID,
                    pos,
                    bestEffectTime,
                    targetGridType
                )
                
                --洗机关，直接删除
                local flushTraps = resetResult:GetFlushTrapsAt(pos)
                for _, trap in ipairs(flushTraps) do
                    trapServiceRender:DestroyTrap(TT,trap)
                end
                local convertInfo = NTGridConvert_ConvertInfo:New(pos, nOldGridType, targetGridType)
                table.insert(tConvertInfo, convertInfo)
            end
        end
        if index ~= endIndex then
            YIELD(TT, gridIntervalTime)
        end
    end


    if #tConvertInfo > 0 then
        local notify = NTGridConvert:New(casterEntity, tConvertInfo)
        notify:SetConvertEffectType(SkillEffectType.ResetGridElement)
        notify.__attackPosMatchRequired = true
        svcPlayBuff:PlayBuffView(TT, notify)
    end

    local finishDelayTime = effectParam:GetFinishDelayTime()
    YIELD(TT, finishDelayTime)
end

---@param resetGridArray SkillEffectResult_ResetGridData[]
---@return table<number, SkillEffectResult_ResetGridData>
function PlaySkillTrainResetElementPhase:_SortGridByDirection(resetGridArray, directionType)
    ---@type table
    local girdList = {}
    if directionType == HitBackDirectionType.Up or directionType == HitBackDirectionType.Down then
        for _, data in pairs(resetGridArray) do
            local posY = data.m_nY
            if not girdList[posY] then
                girdList[posY] = {}
            end
            table.insert(girdList[posY], data)
        end
    elseif directionType == HitBackDirectionType.Left or directionType == HitBackDirectionType.Right then
        for _, data in pairs(resetGridArray) do
            local posX = data.m_nX
            if not girdList[posX] then
                girdList[posX] = {}
            end
            table.insert(girdList[posX], data)
        end
    end
    return girdList
end

function PlaySkillTrainResetElementPhase:_GetStepAndBegin(directionType)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local maxLen = utilData:GetCurBoardMaxLen()
    if directionType == HitBackDirectionType.Down or directionType == HitBackDirectionType.Left then
        --return 1,10,1
        return maxLen, 1, -1
    elseif directionType == HitBackDirectionType.Up or directionType == HitBackDirectionType.Right then
        --return 9,1,-1
        return 1, maxLen+1, 1
    end
end
