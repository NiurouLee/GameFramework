require("pick_up_policy_base")

_class("PickUpPolicy_PetVice", PickUpPolicy_Base)
---@class PickUpPolicy_PetVice: PickUpPolicy_Base
PickUpPolicy_PetVice = PickUpPolicy_PetVice

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetVice:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    --local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetVice(petEntity, activeSkillID)
    return pickPosList, atkPosList, targetIds, extraParam
end
--薇丝：先选择BOSS，没有BOSS再选择小怪。同级内优先选择有指定buff的存活目标，没有带buff的再选择血量绝对值最高的。
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetVice:_CalPickPosPolicy_PetVice(petEntity, activeSkillID )
    local targetEntity = nil
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()

    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
    else
        --先选择目标群，优先boss
        local bossEntityList = {}
        local targetEntityList = {}
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster(petEntity)
        for i, e in ipairs(monsterList) do
            local gridPos = e:GridLocation():GetGridPos()
            local bodyArea = e:BodyArea():GetArea()
            local hasCacPickPos = false
            for _, value in pairs(bodyArea) do
                local workPos = gridPos + value
                if self:_IsPosCanPick(workPos,true,true,utilSvc,extraBoardPosRange) then
                    hasCacPickPos = true
                    break
                end
            end
            --脚下有一个可以点的位置才能被
            if hasCacPickPos then
                if e:HasBoss() then
                    table.insert(bossEntityList, e)
                end
                table.insert(targetEntityList, e)
            end
        end

        if table.count(bossEntityList) > 0 then
            targetEntityList = bossEntityList
        end

        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(activeSkillID)
        local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()

        --先找有指定buff的
        for i, e in ipairs(targetEntityList) do
            ---@type BuffComponent
            local buffCmp = e:BuffComponent()
            if buffCmp then
                local buffEffect = policyParam[1]
                if buffCmp:HasBuffEffect(buffEffect) then
                    targetEntity = e
                    break
                end
            end
        end

        --找血量绝对值最高的
        if not targetEntity then
            local maxHP = 0
            for i, e in ipairs(targetEntityList) do
                local hp = e:Attributes():GetCurrentHP()
                if not targetEntity or hp > maxHP then
                    maxHP = hp
                    targetEntity = e
                end
            end
        end
    end

    if not targetEntity then
        return {}, {}, {}
    end

    local retScopeResult = {}
    local retTargetIds = {}
    local pickPos = targetEntity:GridLocation():GetGridPos()
    --如果gridPos不可以点  换一个点
    if not self:_IsPosCanPick(pickPos,true,true,utilSvc,extraBoardPosRange) then
        local bodyArea = targetEntity:BodyArea():GetArea()
        for _, value in pairs(bodyArea) do
            local workPos = pickPos + value
            local isCanPickPos = self:_IsPosCanPick(workPos,true,true,utilSvc,extraBoardPosRange)
            if isCanPickPos then
                pickPos = workPos
                break
            end
        end
    end

    retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pickPos)

    return {pickPos}, retScopeResult:GetAttackRange(), retTargetIds
end