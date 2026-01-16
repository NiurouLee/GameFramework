require("base_ins_r")
---@class PlayGridRangeConvertInstruction: BaseInstruction
_class("PlayGridRangeConvertInstruction", BaseInstruction)
PlayGridRangeConvertInstruction = PlayGridRangeConvertInstruction

function PlayGridRangeConvertInstruction:Constructor(paramList)
    self._dataSource = tonumber(paramList["dataSource"])
    self._dataSourceHigher = tonumber(paramList["dataSourceHigher"])
    self._userData = 0
    if paramList["userData"] then
        self._userData = tonumber(paramList["userData"])
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayGridRangeConvertInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local scopeGridRange = phaseContext:GetScopeGridRange()
    if not scopeGridRange then
        if EDITOR then
            Log.exception("No scopeGridRange")
        end
        return InstructionConst.PhaseEnd
    end

    local maxScopeRangeCount = phaseContext:GetMaxRangeCount()
    if not maxScopeRangeCount then
        if EDITOR then
            Log.exception("No maxScopeRangeCount")
        end
        return InstructionConst.PhaseEnd
    end

    local curScopeGridRangeIndex = phaseContext:GetCurScopeGridRangeIndex()
    if curScopeGridRangeIndex > maxScopeRangeCount then
        return
    end

    --执行转色
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PieceServiceRender
    local pieceService = world:GetService("Piece")
    ---@type PlayBuffService
    local svcPlayBuff = world:GetService("PlayBuff")

    local tConvertInfo = {}
    local notifyBuff = true --转色是否通知buff

    for _, range in pairs(scopeGridRange) do
        if range then
            local posList = range[curScopeGridRangeIndex]
            if posList then
                for __, pos in pairs(posList) do
                    local nOldGridType = PieceType.None
                    local gridEntity = pieceService:FindPieceEntity(pos)

                    if gridEntity then
                        ---@type PieceComponent
                        local pieceCmpt = gridEntity:Piece()
                        nOldGridType = pieceCmpt:GetPieceType()

                        local nNewGridType = nil
                        local flushTraps = {} --需要洗掉的机关

                        --从技能结果中取得转色信息
                        nNewGridType, flushTraps, notifyBuff =
                            self:_GetConvertSkillResult(world, skillEffectResultContainer, pos, self._dataSource)
                        --更高优先级的转色技能结果
                        if self._dataSourceHigher then
                            local nNewGridTypeHigher =
                                self:_GetConvertSkillResult(
                                world,
                                skillEffectResultContainer,
                                pos,
                                self._dataSourceHigher
                            )
                            if nNewGridTypeHigher then
                                nNewGridType = nNewGridTypeHigher
                            end
                        end

                        --转色
                        self:_Convert(world, pos, nNewGridType, flushTraps, casterEntity, TT)

                        local convertInfo = NTGridConvert_ConvertInfo:New(pos, nOldGridType, nNewGridType)
                        table.insert(tConvertInfo, convertInfo)

                        --显示机关
                        ---@type TrapServiceRender
                        local trapServiceRender = world:GetService("TrapRender")
                        if SkillEffectType.ResetGridElement == self._dataSource then
                            --消除棱镜
                            pieceService:RemovePrismAt(pos)
                            ---@type SkillEffectResult_ResetGridElement
                            local skillResultArray =
                                skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
                            if skillResultArray then
                                local trapEntityID = skillResultArray:GetSummontTrapEntityID(pos)
                                if trapEntityID then
                                    local trapEntity = world:GetEntityByID(trapEntityID)
                                    if trapEntity then
                                        -- trapEntity:SetPosition(pos)
                                        trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
                                    end
                                end
                            end
                        end
                        if SkillEffectType.AddGridEffect == self._dataSource then
                            ---@type SkillAddGridEffectResult
                            local skillResult =
                                skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AddGridEffect)
                            if skillResult then
                                local trapEntityID = skillResult:GetSummontTrapEntityID(pos)
                                if trapEntityID then
                                    local trapEntity = world:GetEntityByID(trapEntityID)
                                    if trapEntity then
                                        trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
                                    end
                                end
                            end
                        end
                        if SkillEffectType.ExChangeGridColor == self._dataSource then
                            ---@type SkillEffectExchangeGridColorResult
                            local skillResultArray =
                                skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ExChangeGridColor)
                            if skillResultArray then
                                local trapEntityID = skillResultArray:GetSummonTrapEntityID(pos)
                                if trapEntityID then
                                    local trapEntity = world:GetEntityByID(trapEntityID)
                                    if trapEntity then
                                        -- trapEntity:SetPosition(pos)
                                        trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
                                    end
                                end
                            end
                        end

                        if SkillEffectType.ConvertOccupiedGridElement == self._dataSource then
                            ---@type SkillEffectConvertOccupiedGridElementResult[]
                            local skillResultArray =
                                skillEffectResultContainer:GetEffectResultByArrayAll(
                                SkillEffectType.ConvertOccupiedGridElement
                            )
                            self:_ShowTrapAtPos_ConvertOccupiedGridElement(TT, world, skillResultArray, pos)
                        end
                    end
                end
            end
        end
    end

    if #tConvertInfo > 0 and notifyBuff then
        local notify = NTGridConvert:New(casterEntity, tConvertInfo)
        notify:SetConvertEffectType(self._dataSource)
        notify.__attackPosMatchRequired = true
        svcPlayBuff:PlayBuffView(TT, notify)
    end
    if SkillEffectType.ExChangeGridColor == self._dataSource then
        local notify = NTExChangeGridColor:New()
        svcPlayBuff:PlayBuffView(TT, notify)
    end
end

function PlayGridRangeConvertInstruction:_GetConvertSkillResult(world, skillEffectResultContainer, pos, dataSource)
    local nNewGridType = nil
    local flushTraps = {} --需要洗掉的机关
    local notifyBuff = true --转色是否通知buff
    if 0 == dataSource then ---使用自定义的数据来源
        nNewGridType = self._userData or PieceType.None
    elseif SkillEffectType.ResetGridElement == dataSource then
        ---@type SkillEffectResult_ResetGridElement
        local skillResultArray = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetGridElement)
        if skillResultArray then
            -- nNewGridType = skillResultArray:FindGridData(pos)
            nNewGridType = skillResultArray:FindGridDataNew(pos)
            flushTraps = skillResultArray:GetFlushTrapsAt(pos)
        end
    elseif SkillEffectType.AddGridEffect == dataSource then
        ---@type SkillAddGridEffectResult
        local skillResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.AddGridEffect)
        if skillResult then
            nNewGridType = skillResult:GetGridConvertType(pos)
        end
        --没有转色效果
        if not nNewGridType then
            ---@type UtilDataServiceShare
            local utilDataSvc = world:GetService("UtilData")
            nNewGridType = utilDataSvc:GetPieceType(pos)
        end
    elseif SkillEffectType.ExChangeGridColor == dataSource then
        ---@type SkillEffectExchangeGridColorResult
        local skillResultArray = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ExChangeGridColor)
        if skillResultArray then
            nNewGridType = skillResultArray:FindGridData(pos)
        end
    elseif SkillEffectType.ResetSingleColorGridElement == dataSource then
        ---@type SkillEffectResultResetSingleColorGridElement
        local skillResultArray =
            skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ResetSingleColorGridElement)
        if skillResultArray then
            nNewGridType = skillResultArray:GetNewGridPieceType(pos)
            local trapIDList = skillResultArray:GetFlushTrapList()
            for _, v in ipairs(trapIDList) do
                local trapEntity = world:GetEntityByID(v)
                flushTraps[#flushTraps + 1] = trapEntity
            end
        end
    elseif SkillEffectType.ConvertGridElement == dataSource then
        ---@type SkillConvertGridElementEffectResult
        local convertResult = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.ConvertGridElement)
        if convertResult then
            for _, result in ipairs(convertResult) do
                local gridArray = result:GetTargetGridArray()
                for __, v2 in ipairs(gridArray) do
                    if v2 == pos then
                        nNewGridType = result:GetTargetElementType()
                        notifyBuff = result:GetNotifyBuff()
                        break
                    end
                end
            end
        end
    elseif SkillEffectType.ManualConvert == dataSource then
        ---@type SkillManualConvertGridElementEffectResult
        local convertResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ManualConvert)
        if convertResult then
            nNewGridType = convertResult:GetTargetElementType()
        end
    elseif SkillEffectType.ConvertOccupiedGridElement == dataSource then
        ---@type SkillEffectConvertOccupiedGridElementResult[]
        local skillResultArray =
            skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.ConvertOccupiedGridElement)
        if skillResultArray and #skillResultArray > 0 then
            for i = 1, #skillResultArray do
                ---@type SkillEffectConvertOccupiedGridElementResult
                local skillResult = skillResultArray[i]
                nNewGridType = skillResult:GetNewGridPieceType(pos)
                if nNewGridType then
                    break
                end
            end
        end
    end

    return nNewGridType, flushTraps, notifyBuff
end

function PlayGridRangeConvertInstruction:_Convert(world, gridPos, newGridType, flushTraps, casterEntity, TT)
    --洗机关，直接删除
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:PlayTrapDieSkill(TT, flushTraps)
    for _, trap in ipairs(flushTraps) do
        trapServiceRender:DestroyTrap(TT, trap)
    end

    --执行转色
    if newGridType and newGridType >= PieceType.None and newGridType <= PieceType.Any then
        ---@type BoardServiceRender
        local boardServiceR = world:GetService("BoardRender")
        ---@type Entity
        local newGridEntity = boardServiceR:ReCreateGridEntity(newGridType, gridPos)

        if newGridEntity then
            ---@type PieceServiceRender
            local pieceSvc = world:GetService("Piece")
            pieceSvc:SetPieceEntityAnimNormal(newGridEntity)
        end
    end
end

function PlayGridRangeConvertInstruction:_ShowTrapAtPos_ConvertOccupiedGridElement(TT, world, skillResultArray, pos)
    if skillResultArray and #skillResultArray > 0 then
        ---@type TrapServiceRender
        local trapServiceRender = world:GetService("TrapRender")
        for _, result in ipairs(skillResultArray) do
            ---@type SkillSummonTrapEffectResult
            local trapResults = result:GetTrapResults()
            for __, trapResult in ipairs(trapResults) do
                if pos == trapResult:GetPos() then
                    local trapIDList = trapResult:GetTrapIDList()
                    local eTrapList = {}
                    for __, eidTrap in ipairs(trapIDList) do
                        table.insert(eTrapList, world:GetEntityByID(eidTrap))
                    end
                    trapServiceRender:ShowTraps(TT, eTrapList, true)
                end
            end
        end
    end
end
