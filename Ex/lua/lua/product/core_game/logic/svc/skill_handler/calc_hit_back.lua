--[[
    HitBack = 3, --击退(或拉回)
]]
_class("SkillEffectCalc_HitBack", Object)
---@class SkillEffectCalc_HitBack: Object
---@field New fun():SkillEffectCalc_HitBack
SkillEffectCalc_HitBack = SkillEffectCalc_HitBack

function SkillEffectCalc_HitBack:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_HitBack:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    ---@type SkillHitBackEffectParam
    local enableByPickNum = skillEffectCalcParam.skillEffectParam:GetEnableByPickNum()
    if enableByPickNum then
        local checkNum = tonumber(enableByPickNum)
        ---@type Entity
        local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
        ---@type ActiveSkillPickUpComponent
        local component = attacker:ActiveSkillPickUpComponent()
        if component then
            local curPickNum = component:GetAllValidPickUpGridPosCount()
            if curPickNum ~= checkNum then
                return
            end
        end
    end

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.insert(results, result)
        end
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_HitBack:_CalculateSingleTarget(skillEffectCalcParam, targetID)
    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    --没有伤害会击退，有伤害且伤害为0就没有击退
    ---@type SkillContextComponent
    local ctx = attacker:SkillContext()
    if ctx:HasDamageInfoFor(targetID) and (not ctx:IsEntityDamaged(targetID)) then
        Log.debug("SkillEffectCalcService:HitBackEffect() no hitback for damge==0!!")
        return
    end

    local defender = self._world:GetEntityByID(targetID)
    if not defender then
        return
    end

    ---@type BuffLogicService
    local BuffLogicSvc = self._world:GetService("BuffLogic")
    if not BuffLogicSvc:CheckCanBeHitBack(defender) then
        return
    end

    ---@type SkillHitBackEffectParam
    local skillHitBackEffectParam = skillEffectCalcParam.skillEffectParam
    local checkBuffEffect = skillHitBackEffectParam:GetCheckBuffEffect()
    --如果配置了击退需要buff  但是目标身上没有这个buff  则返回
    if checkBuffEffect and not defender:BuffComponent():HasBuffEffect(checkBuffEffect) then
        return
    end

    ---@type HitBackCalcType
    local calcType = skillHitBackEffectParam:GetCalcType()
    local beAttackEntityID = targetID
    local hitbackDistance = skillHitBackEffectParam:GetDistance()
    local hitbackDirType = skillHitBackEffectParam:GetDirType()
    local excludeCasterPos = skillHitBackEffectParam:ExcludeCasterPos()
    local extraParam = skillHitBackEffectParam:GetExtraParam()
    local bUseCasterPos = skillHitBackEffectParam:GetForceUseCasterPos()
    local notCalcBomb = skillHitBackEffectParam:GetNotCalcBomb()
    local ignorePathBlock = skillHitBackEffectParam:GetIgnorePathBlock()
    local backupDirectionPlan = skillHitBackEffectParam:GetBackupDirectionPlan()
    local interactType = skillHitBackEffectParam:GetInteractType()

    local skillConfigData = self._configService:GetSkillConfigData(skillEffectCalcParam.skillID)
    local pickType = skillConfigData:GetSkillPickType()

    local attackerPos = attacker:GridLocation().Position
    --技能预览没有传施法坐标 默认使用逻辑坐标。如果传了施法坐标 要使用传的
    if bUseCasterPos then
    else
        if skillEffectCalcParam.attackPos then
            attackerPos = skillEffectCalcParam.attackPos
        end
    end

    local ignorePlayerBlock = skillHitBackEffectParam:GetIgnorePlayerBlock()
    local targetLocationCenter = defender:GridLocation():Center()
    local targetBodyArea = defender:BodyArea()

    if pickType == SkillPickUpType.DirectionInstruction then
        ---@type ActiveSkillPickUpComponent
        local component = attacker:ActiveSkillPickUpComponent()
        if component then
            hitbackDirType = component:GetLastPickUpDirection()
        end
    elseif pickType == SkillPickUpType.Instruction then
        ---@type ActiveSkillPickUpComponent
        local component = attacker:ActiveSkillPickUpComponent()
        if component then
            if bUseCasterPos then
            else
                attackerPos = component:GetLastPickUpGridPos()
            end
        end
    end
    if hitbackDirType == HitBackDirectionType.SpecifyXCoordinate then
        ---@type UtilCalcServiceShare
        local utilCalcSvc = self._world:GetService("UtilCalc")
        local dir, distance = utilCalcSvc:_CalcHitBack2SpecifyXCoordinate(defender, extraParam)
        if dir.x == -1 then
            hitbackDirType = HitBackDirectionType.Left
        elseif dir.x == 1 then
            hitbackDirType = HitBackDirectionType.Right
        else
            hitbackDirType = HitBackDirectionType.EightDir
        end
        hitbackDistance = distance
    end

    if calcType == HitBackCalcType.Delay then
        ---对于延迟结算的击退，要返回击退参数，延迟击退不需要考虑击退过程中触发陷阱
        return SkillDelayHitBackEffectResult:New(
            skillEffectCalcParam.casterEntityID,
            beAttackEntityID,
            hitbackDistance,
            hitbackDirType,
            attackerPos,
            skillEffectCalcParam.gridPos,
            targetLocationCenter,
            targetBodyArea
        )
    end

    local type = skillHitBackEffectParam:GetType()
    ---@type Entity 提取攻击者数据
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local attackerDir = attacker:GridLocation().Direction
    local attackerBodyArea = attacker:BodyArea()

    local extraBlockPos = {}
    if skillHitBackEffectParam:IsCasterPosAsBlock() then
        for _, body in ipairs(attackerBodyArea:GetArea()) do
            table.insert(extraBlockPos, attackerPos + body)
        end
    end

    ---@type Vector2[]
    local skillRange = skillEffectCalcParam.skillRange
    ---@type SkillHitBackEffectResult
    local hitBackEffectResult =
        self._skillEffectService:CalcHitbackEffectResult(
        attackerPos,
        attackerDir,
        attackerBodyArea,
        beAttackEntityID,
        hitbackDirType,
        type,
        hitbackDistance,
        calcType,
        ignorePlayerBlock,
        excludeCasterPos,
        attacker,
        skillRange,
        notCalcBomb,
        ignorePathBlock,
        backupDirectionPlan,
        interactType,
        skillHitBackEffectParam:GetSkillType(),
        extraBlockPos
    )

    local eLocalTeam = self._world:Player():GetLocalTeamEntity()
    if defender:HasTeam() then
        if eLocalTeam:GetID() == defender:GetID() then
            self._world:BattleStat():AddPlayerSkillHitCount(skillEffectCalcParam.skillID)
        end
    elseif defender:HasPet() then
        local eTeam = defender:Pet():GetOwnerTeamEntity()
        if eTeam:GetID() == eLocalTeam:GetID() then
            self._world:BattleStat():AddPlayerSkillHitCount(skillEffectCalcParam.skillID)
        end
    end

    return hitBackEffectResult
end
