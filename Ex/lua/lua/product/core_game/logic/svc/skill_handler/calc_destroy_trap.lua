require("calc_base")

---@class SkillEffectCalc_DestroyTrap
_class("SkillEffectCalc_DestroyTrap", SkillEffectCalc_Base)
SkillEffectCalc_DestroyTrap = SkillEffectCalc_DestroyTrap

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DestroyTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectDestroyTrapParam
    local effectParam = skillEffectCalcParam.skillEffectParam
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type Entity
    local entity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    if entity:HasSuperEntity() then
        entity = entity:GetSuperEntity()
    end
    local destroyType = effectParam:GetDestroyType()
    local stageIndex = effectParam:GetStageIndex()
    ---@type Group
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    ---@type Entity[]
    local trapEntities = trapGroup:GetEntities()
    local resultArray = {}
    if destroyType == SkillEffectDestroyTrapType.Range then
        local range = skillEffectCalcParam.skillRange or {}
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if
                cTrap and not eTrap:HasDeadMark() and effectParam:IsDestroyTrap(cTrap:GetTrapID()) and
                        self:_TrapCanDestroy(effectParam, cTrap)
                then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID,pos,stageIndex))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.Self then
        if entity:HasTrap() and not entity:HasDeadMark() then
            table.insert(resultArray, SkillEffectDestroyTrapResult:New(entity:GetID(), entity:Trap():GetTrapID()))
        end
    elseif destroyType == SkillEffectDestroyTrapType.Other then
        for _, entity in ipairs(trapEntities) do
            local cTrap = entity:Trap()
            if entity:GetID() ~= skillEffectCalcParam.casterEntityID and self:_TrapCanDestroy(effectParam, cTrap) then
                local cAttributes = entity:Attributes()
                local curHp = cAttributes:GetCurrentHP()
                if curHp then
                    cAttributes:Modify("HP", 0)
                    Log.debug("SkillEffectCalc_DestroyTrap ModifyHP =0 defender=", entity:GetID())
                end
                table.insert(resultArray, SkillEffectDestroyTrapResult:New(entity:GetID(), entity:Trap():GetTrapID()))
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.RangeExceptConfig then
        local range = skillEffectCalcParam.skillRange or {}
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if
                cTrap and not eTrap:HasDeadMark() and not effectParam:IsProtectTrap(cTrap:GetTrapID()) and
                        self:_TrapCanDestroy(effectParam, cTrap)
                then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.Sticker then
        local pos = skillEffectCalcParam.centerPos
        local array = utilSvc:GetTrapsAtPos(pos)
        local onAbyss = false
        for _, eTrap in ipairs(array) do
            if eTrap:Trap():GetTrapType() == TrapType.TerrainAbyss then
                onAbyss = true
                break
            end
        end

        local entity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
        if entity:HasTrap() and not entity:HasDeadMark() then
            table.insert(resultArray, SkillEffectDestroyTrapResult:New(entity:GetID(), entity:Trap():GetTrapID()))
        end

        --只有在深渊上才需要删除其他机关
        if onAbyss then
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if cTrap and not eTrap:HasDeadMark() and cTrap:GetTrapType() ~= TrapType.TerrainAbyss then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.RangeSelectTrapType then
        local range = skillEffectCalcParam.skillRange or {}
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if
                cTrap and not eTrap:HasDeadMark() and effectParam:IsDestroyTrapWithType(cTrap:GetTrapType()) and
                        self:_TrapCanDestroy(effectParam, cTrap)
                then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.MySummonTrap then
        for i, eTrap in ipairs(trapEntities) do
            local cTrap = eTrap:Trap()
            if eTrap:HasSummoner() and eTrap:GetSummonerEntity() == entity and self:_TrapCanDestroy(effectParam, cTrap) then
                table.insert(resultArray, SkillEffectDestroyTrapResult:New(eTrap:GetID(), eTrap:Trap():GetTrapID()))
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.RangeAll then
        local range = skillEffectCalcParam.skillRange or {}
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if cTrap and not eTrap:HasDeadMark() and self:_TrapCanDestroy(effectParam, cTrap) then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID,pos,stageIndex))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyTrapType.SelfSummonDone then
        ---@type AttributesComponent
        local attCpt = entity:Attributes()
        local summonDone = attCpt:GetAttribute("TrapSummonDone")
        if summonDone and summonDone ==1 and entity:HasTrap() then
            table.insert(resultArray, SkillEffectDestroyTrapResult:New(entity:GetID(), entity:Trap():GetTrapID()))
        end
    elseif destroyType == SkillEffectDestroyTrapType.HitBackRange then
        local targetIDs = skillEffectCalcParam.targetEntityIDs
        local targetID = targetIDs[1]
        local targetEntity = self._world:GetEntityByID(targetID)
        local range = self:CalcHitBackRange(entity,targetEntity)
        for _, pos in ipairs(range) do
            local array = utilSvc:GetTrapsAtPos(pos)
            for _, eTrap in ipairs(array) do
                local cTrap = eTrap:Trap()
                if
                cTrap and not eTrap:HasDeadMark() and effectParam:IsDestroyTrap(cTrap:GetTrapID()) and
                        self:_TrapCanDestroy(effectParam, cTrap)
                then
                    local entityID = eTrap:GetID()
                    local trapID = cTrap:GetTrapID()
                    table.insert(resultArray, SkillEffectDestroyTrapResult:New(entityID, trapID,pos,stageIndex))
                end
            end
        end
    end

    return resultArray
end
---@param entity Entity
---@param targetEntity Entity
function SkillEffectCalc_DestroyTrap:CalcHitBackRange(entity,targetEntity)
    ---@type SkillEffectResultContainer
    local routineComponent = entity:SkillContext():GetResultContainer()
    local hitDir = entity:GetGridDirection()
    local startPos = targetEntity:GetGridPosition()
    local range = {}
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local count = math.max(boardSvc:GetCurBoardMaxX(),boardSvc:GetCurBoardMaxY())
    for i = 1, count do
        local newPos = Vector2(startPos.x+i*hitDir.x,startPos.y+i*hitDir.y)
        if boardSvc:IsValidPiecePos(newPos) then
            table.insert(range,newPos)
        end
    end
    return range
end

---判断技能配置是否可以删除选中的这个机关
---@param effectParam SkillEffectDestroyTrapParam
---@param cTrap TrapComponent
function SkillEffectCalc_DestroyTrap:_TrapCanDestroy(effectParam, cTrap)
    local canDestroy = true

    --机关配置了需要特殊销毁 and 技能配置不是特殊销毁
    if cTrap and cTrap:GetSpecialDestroy() and effectParam:GetSpecial() == 0 then
        canDestroy = false
    end

    return canDestroy
end
