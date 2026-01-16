--[[
    TransportBy = 66, --主动技点选触发格子移动，如果第一个点选位置有单个怪那么也传送。
]]
---@class SkillEffectCalc_TransportByRange: Object
_class("SkillEffectCalc_TransportByRange", Object)
SkillEffectCalc_TransportByRange = SkillEffectCalc_TransportByRange

function SkillEffectCalc_TransportByRange:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalc_TransportByRange
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TransportByRange:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamTransportByRange
    local paramSkillEffect = skillEffectCalcParam.skillEffectParam
    local targetIDs =     skillEffectCalcParam.targetEntityIDs
    local range = skillEffectCalcParam:GetCenterPos()
    local result = self:_CalcTransportEnvListByRange(paramSkillEffect,range,targetIDs)
    return { result }
end

function SkillEffectCalc_TransportByRange:_GetNextPos(i,pos,dirType)
    local nextPos = nil
    if dirType ==DirectionType.Up then
        nextPos = Vector2(pos.x, pos.y+i)
    elseif dirType ==DirectionType.Down then
        nextPos = Vector2(pos.x, pos.y-i)
    elseif dirType ==DirectionType.Left then
        nextPos = Vector2(pos.x-i, pos.y)
    elseif dirType ==DirectionType.Right then
        nextPos = Vector2(pos.x+i, pos.y)
    end
    return nextPos
end

function SkillEffectCalc_TransportByRange:GridGetNextPos(pos,dirType)
    local max
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    local nextPos = nil
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        max = utilScopeCalcSvc:GetCurBoardMaxY()
    elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
        max = utilScopeCalcSvc:GetCurBoardMaxX()
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for i = 1, max do
        local tmpPos = self:_GetNextPos(i,pos,dirType)
        local pieceType =utilDataSvc:GetPieceType(tmpPos)
        if not utilScopeSvc:IsValidPiecePos(tmpPos) then
            return tmpPos
        end
        if pieceType and  pieceType ~=PieceType.None and
                utilDataSvc:IsPosCanConvertGridElement(tmpPos)  then
            return tmpPos
        end
    end
    return nextPos
end

function SkillEffectCalc_TransportByRange:GetNextPos(pos,dirType)
    local max
    ---@type UtilScopeCalcServiceShare
    local utilScopeCalcSvc = self._world:GetService("UtilScopeCalc")
    local nextPos = nil
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        max = utilScopeCalcSvc:GetCurBoardMaxY()
    elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
        max = utilScopeCalcSvc:GetCurBoardMaxX()
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    for i = 1, max do
        local tmpPos = self:_GetNextPos(i,pos,dirType)
        local pieceType =utilDataSvc:GetPieceType(tmpPos)
        if not utilScopeSvc:IsValidPiecePos(tmpPos) then
            return tmpPos
        end
        if pieceType and  pieceType ~=PieceType.None then
            return tmpPos
        end
    end
    return nextPos
end

---@param effectParam SkillEffectTransportParam
function SkillEffectCalc_TransportByRange:_CalcTransportEnvListByRange(effectParam,pickUpList,targetIDs)
    local isPickUp = effectParam:IsPickUp()
    local isTransportTarget = effectParam:IsTransportTarget()
    ---@type SkillEffectResultTransportByRange
    local result = SkillEffectResultTransportByRange:New()
    local range,dirType,edgeBegin,edgeEnd,invalidPos,totalRange
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    if isPickUp then
        edgeEnd = {}
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        range,dirType,edgeBegin,invalidPos,totalRange =utilScopeSvc:CalcRangeByPickUpPosList(pickUpList)
        ---@type UtilDataServiceShare
        local utilDataSvc =  self._world:GetService("UtilData")
        for i, v in ipairs(range) do
            local nextPos = self:GridGetNextPos(v,dirType)
            local pieceType =utilDataSvc:GetPieceType(v)
            ---会出棋盘的格子
            if not boardServiceLogic:IsValidPiecePos(nextPos) then
                table.insert(edgeEnd,v)
            end
            local pieceData =TransportByRangePieceData:New(v,pieceType,nextPos)
            result:AddPieceData(pieceData)
        end
        result:SetTransportDir(dirType)
        result:SetEdge(edgeBegin,edgeEnd)
        result:SetResetGridPosList(invalidPos)
        result:SetOutlineRange(totalRange)
    end
    local targetData={}
    if isTransportTarget then
        local targetID =targetIDs[1]
        local targetEntity = self._world:GetEntityByID(targetID)
        -- 免疫 强制位移（及牵引的强制效果）
        ---@type BuffLogicService
        local buffLogicSvc = self._world:GetService("BuffLogic")
        if targetEntity and not buffLogicSvc:CheckForceMoveImmunity(targetEntity) then
            local pos = targetEntity:GetGridPosition()
            local bodyAreaCount = targetEntity:BodyArea():GetAreaCount()
            if bodyAreaCount ==1 then
                local nextPos = self:GetNextPos(pos,dirType)
                ---@type UtilDataServiceShare
                local utilDataSvc = self._world:GetService("UtilData")
                if utilDataSvc:IsMonsterCanTel2TargetPos(targetEntity,nextPos) then
                    result:AddTargetData(targetID,pos,nextPos)
                    ---@type TriggerService
                    local triggerSvc =self._world:GetService("Trigger")
                    triggerSvc:Notify(NTTransportEachMoveEnd:New(targetEntity, pos, nextPos))
                end

            end
        end
    end
    return result
end


--触发机关
---@param result SkillEffectTransportResult
function SkillEffectCalc_TransportByRange:_TriggerTraps(result, traps, triggerEntity)
    --机关不能触发机关
    if triggerEntity:HasTrapID() then
        return
    end

    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")

    for _, e in ipairs(traps) do
        if e:HasTrapID() then
            local triggerTraps, triggerResults = trapSvc:CalcTrapTriggerSkill(e, triggerEntity)
            if triggerTraps then
                for i, trap in ipairs(triggerTraps) do
                    local skillResult = triggerResults[i]
                    result:AddTrapSkillResult(trap:GetID(), skillResult, triggerEntity:GetID())
                end
            end
        end
    end
end