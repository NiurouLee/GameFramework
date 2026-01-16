_class("ChangePetTeamOrderCalculator", Object)
---@class ChangePetTeamOrderCalculator : Object
ChangePetTeamOrderCalculator = ChangePetTeamOrderCalculator

---@param world MainWorld
function ChangePetTeamOrderCalculator:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_ChangePetTeamOrder
function ChangePetTeamOrderCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local generalEffectCalc = GeneralEffectCalculator:New(self._world)
    local finalScopeFilterParam = effectParam:GetScopeFilterParam()
    ---@type SkillScopeResult
    local scopeResult = generalEffectCalc:_CalcSkillEffectScopeResult(casterEntity, effectParam, finalScopeFilterParam)
    local targetIDs = generalEffectCalc:_CalcSkillEffectTargetList(casterEntity, scopeResult, effectParam)

    local t = {}
    for _, entityID in ipairs(targetIDs) do
        local entity = self._world:GetEntityByID(entityID)
        local result = self:CalculateOneTarget(casterEntity, effectParam, entity)
        if result then
            skillEffectResultContainer:AddEffectResult(result)
            table.insert(t, result)
        end
    end
    return t
end

function ChangePetTeamOrderCalculator:CalculateOneTarget(casterEntity, effectParam, targetEntity)
    ---@type Entity
    local eTarget = targetEntity
    if eTarget:HasSuperEntity() then
        eTarget = targetEntity:GetSuperEntity()
    end

    if not eTarget:HasPetPstID() then
        return
    end

    if eTarget:PetPstID():IsHelpPet() then
        return
    end

    ---@type TeamComponent
    local cTeam = eTarget:Pet():GetOwnerTeamEntity():Team()
    local tOldTeamOrder = cTeam:CloneTeamOrder()
    local nHelpPetPstID = cTeam:GetHelpPetPstID()

    local eTeam = eTarget:Pet():GetOwnerTeamEntity()
    local cTeam = eTeam:Team()

    -- 把除了施法者和助战以外的顺序保存下来
    local nTargetPetPstID = eTarget:PetPstID():GetPstID()
    local tTeamOrder = {}
    local tDead = {}
    for k, v in ipairs(cTeam:GetTeamOrder()) do
        ---@type Entity
        local e = cTeam:GetPetEntityByPetPstID(v)

        if nHelpPetPstID and (nHelpPetPstID == v) then
            goto CONTINUE
        end

        if nTargetPetPstID == v then
            goto CONTINUE
        end

        if e:HasPetDeadMark() then
            table.insert(tDead, v)
            goto CONTINUE
        end

        table.insert(tTeamOrder, v)

        ::CONTINUE::
    end

    -- 根据参数将施法者放在新的位置上
    if effectParam:GetTargetOrder() == ChangePetTeamOrderTargetOrder.TeamLeader then
        table.insert(tTeamOrder, 1, nTargetPetPstID)
    elseif effectParam:GetTargetOrder() == ChangePetTeamOrderTargetOrder.TeamTail then
        table.insert(tTeamOrder, nTargetPetPstID)

        -- 修改成被动触发的技能效果解除诅咒
        --local eNewTeamLeader = cTeam:GetPetEntityByPetPstID(tTeamOrder[1])
        --if eNewTeamLeader:BuffComponent():HasFlag(BuffFlags.SealedCurse) then
        --    local index, cleanPstID
        --    for i, pstID in ipairs(tTeamOrder) do
        --        if pstID == nTargetPetPstID then
        --            goto CONTINUE
        --        end
        --        local e = cTeam:GetPetEntityByPetPstID(pstID)
        --        if (not e:BuffComponent():HasFlag(BuffFlags.SealedCurse)) and (not e:HasPetDeadMark()) then
        --            cleanPstID = pstID
        --            index = i
        --            break
        --        end
        --
        --        ::CONTINUE::
        --    end
        --    if cleanPstID then
        --        table.remove(tTeamOrder, index)
        --        table.insert(tTeamOrder, 1, cleanPstID)
        --    else
        --        -- 本次操作将导致一个被诅咒光灵成为队长，且没有找到下一个有效的队长时，本次操作不生效
        --        -- 解除诅咒buff没有比较快的做法，和策划讨论后决定如此处理
        --        return
        --    end
        --end
    end

    -- 最后把助战放进新的序列中
    if nHelpPetPstID then
        local e = cTeam:GetPetEntityByPetPstID(nHelpPetPstID)
        if e:HasPetDeadMark() then
            table.appendArray(tTeamOrder, tDead)
            table.insert(tTeamOrder, nHelpPetPstID)
        else
            table.insert(tTeamOrder, nHelpPetPstID)
            table.appendArray(tTeamOrder, tDead)
        end
    else
        table.appendArray(tTeamOrder, tDead)
    end

    local result = SkillEffectResult_ChangePetTeamOrder:New(eTarget:GetID(), tOldTeamOrder, tTeamOrder)
    return result
end
