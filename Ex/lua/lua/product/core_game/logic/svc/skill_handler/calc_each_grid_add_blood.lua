--[[
    EachGridAddBlood = 37, --根据格子数量治疗回血
]]
---@class SkillEffectCalc_EachGridAddBlood: Object
_class("SkillEffectCalc_EachGridAddBlood", Object)
SkillEffectCalc_EachGridAddBlood = SkillEffectCalc_EachGridAddBlood

function SkillEffectCalc_EachGridAddBlood:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_EachGridAddBlood:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

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
function SkillEffectCalc_EachGridAddBlood:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local entityDefender = self._world:GetEntityByID(defenderEntityID)
    if entityDefender == nil then
        Log.fatal("CalculationForeachTarget defender is null ", defenderEntityID)
        return
    end

    local posTarget = entityDefender:GridLocation():GetGridPos()
    local skillResult =
        SkillEffectResultEachGridAddBlood:New(
        skillEffectCalcParam.skillEffectParam:GetBaseAddType(),
        skillEffectCalcParam.skillEffectParam:GetBaseAddValue(),
        posTarget
    )

    --禁疗buff
    if entityDefender:HasPetPstID() or entityDefender:HasTeam() then
        local teamEntity = entityDefender
        if entityDefender:HasPet() then
            teamEntity = entityDefender:Pet():GetOwnerTeamEntity()
        end
        if teamEntity:Attributes():GetAttribute("BuffForbidCure") then
            skillResult:SetAddData(defenderEntityID, 0)
            return skillResult
        end
    end

    --计算目标方块的数量
    --获取攻击范围
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    --格子个数
    local pieceCount = 0
    if scopeResult then
        local array = scopeResult:GetAttackRange()
        if array then
            pieceCount = table.count(array)
        end
    end
    --计算加的血量
    local nAddData = 0
    local pstId = casterEntity:PetPstID():GetPstID()
    local petData = self._world.BW_WorldInfo:GetPetData(pstId)
    local attackVal = casterEntity:Attributes():GetAttack()
    --计算基础血量增加
    local baseAddType = skillEffectCalcParam.skillEffectParam:GetBaseAddType()
    local baseAddValue = skillEffectCalcParam.skillEffectParam:GetBaseAddValue()
    if AddBlood_Type.Percent == baseAddType then
        nAddData = nAddData + attackVal * baseAddValue
    elseif AddBlood_Type.AbsData == baseAddType then
        nAddData = nAddData + baseAddValue
    end
    --计算方块格子增加的血量
    local onePieceAddType = skillEffectCalcParam.skillEffectParam:GetOnePieceAddType()
    local onePieceAddValue = skillEffectCalcParam.skillEffectParam:GetOnePieceAddValue()
    if AddBlood_Type.Percent == onePieceAddType then
        nAddData = nAddData + attackVal * onePieceAddValue * pieceCount
    elseif AddBlood_Type.AbsData == onePieceAddType then
        nAddData = nAddData + onePieceAddValue * pieceCount
    end

    ---按强化格子数量额外恢复，卓娅突破3阶主动技---靳策添加
    local enhanceParam = skillEffectCalcParam.skillEffectParam:GetEnhanceGridRecoverValue()
    local enhanceCount = 0
    if enhanceParam and scopeResult then
        local array = scopeResult:GetAttackRange()
        if array and #array > 0 and enhanceParam > 0 then
            --每个强化格子额外恢复为攻击力的百分比
            local recover = attackVal * enhanceParam
            ---@type UtilDataServiceShare
            local utilSvc = self._world:GetService("UtilData")
            for _, pos in ipairs(array) do
                local traps = utilSvc:GetTrapsAtPos(pos)
                if traps and #traps > 0 then
                    for __, trap in ipairs(traps) do
                        if trap:Trap():GetTrapEffectType() ~= TrapEffectType.EnhancePiece then
                            enhanceCount = enhanceCount + 1
                        end
                    end
                end
            end
            nAddData = nAddData + enhanceCount * recover
        end
    end
    ---end---

    --回血加成系数
    local rate = entityDefender:Attributes():GetAttribute("AddBloodRate") or 0
    nAddData = nAddData * (1 + rate)
    nAddData = math.floor(nAddData)

    local logger = self._world:GetMatchLogger()
    logger:AddBloodLog(
        casterEntity:GetID(),
        {
            key = "CalcAddBlood",
            desc = "技能加血 攻击者[attacker] 被击者[defender] 加血类型[addtype] 加血量[blood]=(攻击力[attack]*基础加血量[baseAdd]+攻击力[attack]*一格加血量[gridAdd]*格子数[piececnt]+攻击力[attack]*强化加血系数[enhanceAdd]*强化格子数[enhanceCount])*(1+回血系数[rate])",
            attacker = casterEntity:GetID(),
            defender = defenderEntityID,
            baseAdd = baseAddValue,
            attack = attackVal,
            blood = nAddData,
            gridAdd = onePieceAddValue,
            piececnt = pieceCount,
            enhanceAdd = enhanceParam or 0,
            enhanceCount = enhanceCount,
            rate = rate,
            addtype = GetEnumKey("AddBlood_Type", onePieceAddType)
        }
    )
    skillResult:SetAddData(defenderEntityID, nAddData)
    return skillResult
end
