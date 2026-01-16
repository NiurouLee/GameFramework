--[[
    AlphaThrowTrap = 153, --阿尔法主动技1：阿尔法收集光灵位置十字范围内的机关或贝塔进行攻击并击退或击晕光灵
]]
---@class SkillEffectCalc_AlphaThrowTrap: Object
_class("SkillEffectCalc_AlphaThrowTrap", Object)
SkillEffectCalc_AlphaThrowTrap = SkillEffectCalc_AlphaThrowTrap

function SkillEffectCalc_AlphaThrowTrap:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type RideServiceLogic
    self._rideSvc = self._world:GetService("RideLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AlphaThrowTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    --计算光灵最大十字范围内的机关、被骑乘的机关对象ID、被骑乘的怪物对象ID
    local trapEntityIDs, trapMountID, monsterMountID = self:CalcTrapAndMonster(skillEffectCalcParam)
    if #trapEntityIDs == 0 and not monsterMountID then
        return
    end

    --伤害计算
    local damageRes = self:CalcDamageResult(skillEffectCalcParam, trapEntityIDs, monsterMountID)

    --骑乘机关，则解除骑乘
    if trapMountID then
        self._rideSvc:RemoveRide(skillEffectCalcParam.casterEntityID, trapMountID)
    end

    --骑乘贝塔
    if monsterMountID then
        --在贝塔瞬移的技能效果中解除，此时不能解除，抽射贝塔时需要骑乘状态
    end

    local result = SkillEffectAlphaThrowTrapResult:New(trapEntityIDs, trapMountID, monsterMountID, damageRes)
    return result
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AlphaThrowTrap:CalcTrapAndMonster(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local mountEntityID = nil
    if casterEntity:HasRide() then
        ---@type RideComponent
        local rideCmpt = casterEntity:Ride()
        mountEntityID = rideCmpt:GetMountID()
    end

    ---@type SkillEffectAlphaThrowTrapParam
    local effectParam = skillEffectCalcParam.skillEffectParam

    --取光灵位置最大十字范围
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    local centerPos = teamEntity:GetGridPosition()
    local bodyArea = teamEntity:BodyArea():GetArea()
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local maxLen = boardSvc:GetCurBoardMaxLen()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local skillCalc = utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeResult
    local scopeRes = skillCalc:ComputeScopeRange(
        SkillScopeType.Cross,
        { maxLen },
        centerPos,
        bodyArea
    )
    local posList = scopeRes:GetAttackRange()

    --检测范围内的机关
    local trapMountID = nil
    local trapID = effectParam:GetTrapID()
    local trapEntityIDs = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, trapEntity in ipairs(trapGroup:GetEntities()) do
        if not trapEntity:HasDeadMark() and trapEntity:TrapID():GetTrapID() == trapID and
            table.icontains(posList, trapEntity:GetGridPosition())
        then
            local trapEntityID = trapEntity:GetID()
            table.insert(trapEntityIDs, trapEntityID)
            if mountEntityID == trapEntityID then
                trapMountID = trapEntityID
            end
        end
    end

    --检测怪物，存在的话，下坐骑是在扔贝塔的瞬移效果内实现
    local monsterMountID = nil
    if not trapMountID then
        local monsterClassID = effectParam:GetMonsterClassID()
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if monsterClassID == monsterEntity:MonsterID():GetMonsterClassID() and
                mountEntityID == monsterEntity:GetID()
            then
                local bodyArea = monsterEntity:BodyArea():GetArea()
                local pos = monsterEntity:GetGridPosition()
                for _, bodyPos in ipairs(bodyArea) do
                    local curPos = pos + bodyPos
                    if table.icontains(posList, curPos) then
                        monsterMountID = mountEntityID
                        break
                    end
                end
            end
        end
    end

    return trapEntityIDs, trapMountID, monsterMountID
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@param trapEntityIDs number[]
---@param monsterMountID number
---@return SkillDamageEffectResult
function SkillEffectCalc_AlphaThrowTrap:CalcDamageResult(skillEffectCalcParam, trapEntityIDs, monsterMountID)
    ---@type SkillEffectAlphaThrowTrapParam
    local param = skillEffectCalcParam.skillEffectParam
    local basePercent = param:GetBasePercent()
    local afterPercent = param:GetAfterPercent()
    local curFormulaID = param:GetFormulaID()
    if curFormulaID == nil then
        curFormulaID = 2
    end

    --攻击次数
    local attackCount = #trapEntityIDs
    if monsterMountID then
        attackCount = attackCount + 1
    end

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local defenderEntity = self._world:Player():GetLocalTeamEntity()
    local defenderPos = defenderEntity:GetGridPosition()

    --多段伤害
    local percentList = { basePercent }
    local curPercent = basePercent * afterPercent
    for i = 2, attackCount do
        table.insert(percentList, curPercent)
    end
    local skillDamageParam = SkillDamageEffectParam:New(
        {
            percent = percentList,
            formulaID = curFormulaID,
            damageStageIndex = 1
        }
    )

    local nTotalDamage, listDamageInfo = self._skillEffectService:ComputeSkillDamage(
        casterEntity,
        casterEntity:GetGridPosition(),
        defenderEntity,
        defenderPos,
        skillEffectCalcParam.skillID,
        skillDamageParam,
        SkillEffectType.AlphaThrowTrap,
        1
    )

    local damageRes = self._skillEffectService:NewSkillDamageEffectResult(
        defenderPos,
        defenderEntity:GetID(),
        nTotalDamage,
        listDamageInfo
    )
    return damageRes
end

---@param skillEffectCalcParam SkillEffectCalcParam
---@return SkillBuffEffectResult
function SkillEffectCalc_AlphaThrowTrap:CalcAddBuffResult(skillEffectCalcParam)
    local skillID = skillEffectCalcParam:GetSkillID()
    local attackRange = skillEffectCalcParam:GetSkillRange()
    ---@type SkillEffectAlphaThrowTrapParam
    local param = skillEffectCalcParam.skillEffectParam
    local buffID = param:GetBuffID()

    --攻击者和被击者
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local defenderEntity = self._world:Player():GetLocalTeamEntity()

    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    ---@type SkillBuffEffectResult
    local buffResult = SkillBuffEffectResult:New(defenderEntity:GetID())

    local cfgNewBuff = Cfg.cfg_buff[buffID]
    if cfgNewBuff then
        triggerSvc:Notify(NTEachAddBuffStart:New(skillID, casterEntity, defenderEntity, attackRange))
        local buff = buffLogicService:AddBuff(
            buffID,
            defenderEntity,
            { casterEntity = casterEntity }
        )
        local seqID
        if buff then
            seqID = buff:BuffSeq()
            buffResult:AddBuffResult(seqID)
        end
        triggerSvc:Notify(NTEachAddBuffEnd:New(skillID, casterEntity, defenderEntity, attackRange, buffID, seqID))
    end

    return buffResult
end
