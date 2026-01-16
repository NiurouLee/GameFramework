--[[
    AbsorbTrapsAndDamageByPickupTarget = 139, --根据点选对象选择是否吸收机关并造成伤害
]]
---@class SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget: Object
_class("SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget", Object)
SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget = SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget

function SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget:DoSkillEffectCalculator(skillEffectCalcParam)
    if not self:_CanAbsorb(skillEffectCalcParam) then
        return
    end

    ---@type SkillEffectAbsorbTrapsAndDamageByPickupTargetParam
    local param = skillEffectCalcParam.skillEffectParam

    local attackCount = 1
    local trapID = param:GetTrapID()
    local trapEntityIDs = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        local isTargetTrap = true
        isTargetTrap = isTargetTrap and (not e:HasDeadMark()) --存活机关
        isTargetTrap = isTargetTrap and (e:TrapID():GetTrapID() == trapID) -- 指定机关
        --region 从属判定
        --配置上保证了被选中的机关一定有SummonerComponent，因此不考虑没有该组件的机关
        --注：这里没有SummonerComponent时的结果与SkillEffectCalc_Teleport不一致
        isTargetTrap = isTargetTrap and (e:HasSummoner())
        if isTargetTrap then
            local summonerID = e:Summoner():GetSummonerEntityID()
            local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
            if summonerID == skillEffectCalcParam.casterEntityID then
                isTargetTrap = true
            elseif casterEntity:HasPet() then
                --[[
                    修改前代码是只判断机关是不是施法者自己的
                    但N24加入的阿克希亚也可以召唤别人的机关，并需要被认为是施法者的
                    考虑到该判断原先的目的是防止吸收【被世界boss化的光灵】和【黑拳赛的对方光灵】所属机关
                    这里添加判断：当施法者是光灵时，自己队伍内的其他光灵召唤的机关，也视为施法者自己召唤的
                ]]
                local eTeam = casterEntity:Pet():GetOwnerTeamEntity()
                local summonerID = e:Summoner():GetSummonerEntityID()
                local pets = eTeam:Team():GetTeamPetEntities()
                local isTeamPetSummoner = false
                for _, ePet in ipairs(pets) do
                    if ePet:GetID() == summonerID then
                        isTeamPetSummoner = true
                        break
                    end
                end
                isTargetTrap = isTeamPetSummoner
            end
        end
        --endregion

        if isTargetTrap then
            table.insert(trapEntityIDs, e:GetID())
        end
    end
    local trapCount = #trapEntityIDs
    attackCount = attackCount + trapCount

    local basePercent = param:GetBasePercent()
    local addPercent = param:GetAddPercent()
    local limitPercent = param:GetLimitPercent()
    local curFormulaID = param:GetFormulaID()
    if curFormulaID == nil then
        curFormulaID = 100
    end
    

    --计算伤害对象范围
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local casterGridPos = casterEntity:GetGridPosition()
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local targetType = param:GetDamageTargetType()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeResult
    local damageScopeResult =
        scopeCalculator:ComputeScopeRange(
        param:GetDamageScopeType(),
        param:GetDamageScopeParam(),
        casterGridPos,
        casterBodyArea,
        casterEntity:GridLocation():GetGridDir(),
        targetType
    )

    --获取伤害对象并计算伤害
    local targetArray = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, damageScopeResult)
    ---去重
    targetArray = table.unique(targetArray)
    --考虑体型的取距离最近的位置，返回的参数中pos已是多格怪距离施法位置最近的格子
    local targetDisArray = utilScopeSvc:SortMonstersListByPos(casterGridPos, targetArray, true)
    
    local skillDamageResArray = {}
    for i = 1, attackCount do
        if #targetDisArray == 0 then
            break
        end

        ---@type Entity
        local targetEntity = targetDisArray[1].monster_e
        local targetPos = targetDisArray[1].pos
        --计算目标与施法者位置的圈数【未考虑施法者身形，光灵雨森专用，若给多格怪使用，需扩展】
        local disX = math.abs(casterGridPos.x - targetPos.x)
        local disY = math.abs(casterGridPos.y - targetPos.y)
        local disRingCount = math.max(disX, disY) - 1
        --根据圈数，计算攻击加成（递增或衰减）
        local curAdd = addPercent * disRingCount
        if limitPercent and math.abs(curAdd) > math.abs(limitPercent) then
            curAdd = limitPercent
        end
        local curPercent = basePercent * (1 + curAdd)

        local skillDamageParam =
            SkillDamageEffectParam:New(            
            {
                percent = {curPercent},
                formulaID = curFormulaID,
                damageStageIndex = 1
            }
        )

        local nTotalDamage, listDamageInfo =
            self._skillEffectService:ComputeSkillDamage(
            casterEntity,
            casterEntity:GetGridPosition(),
            targetEntity,
            targetPos,
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.AbsorbTrapsAndDamageByPickupTarget,
            1
        )

        ---@type DamageInfo
        local damageInfo = listDamageInfo[1]
        local damageInfoArray = {damageInfo}
        local serDamage =
            self._skillEffectService:NewSkillDamageEffectResult(
            targetPos,
            targetEntity:GetID(),
            damageInfo:GetDamageValue(),
            damageInfoArray
        )
        table.insert(skillDamageResArray, serDamage)

        local currentHP = targetEntity:Attributes():GetCurrentHP()
        if currentHP <= 0 then
            table.remove(targetDisArray, 1)
        end
    end

    local result = SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:New(trapEntityIDs, skillDamageResArray)
    local btsvc = self._world:GetService("Battle")
    if btsvc:IsFinalAttack() then
        result:SetFinalAttackIndex(#skillDamageResArray)
    end

    return result
end

function SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget:_CanAbsorb(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    --根据技能上下文，若瞬移成功则表示可以吸收机关
    ---@type SkillEffectResult_Teleport
    local skillResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.Teleport)
    if skillResult then
        return true
    end

    return false
end
