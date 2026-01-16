--[[
    Teleport = 8, ---瞬移    
]]
---@class SkillEffectCalc_TeleportAndSummonTrapAndSummonTrap: Object
_class("SkillEffectCalc_TeleportAndSummonTrap", Object)
SkillEffectCalc_TeleportAndSummonTrap = SkillEffectCalc_TeleportAndSummonTrap

function SkillEffectCalc_TeleportAndSummonTrap:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TeleportAndSummonTrap:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    self._trapPosList ={}
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type AttributesComponent
    local attrCmpt = casterEntity:Attributes()
    local hp = attrCmpt:GetCurrentHP()
    local maxHP = attrCmpt:CalcMaxHp()
    local hpPercent = hp / maxHP
    ---@type SkillEffectParamTeleportAndSummonTrap
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()
    local telePortCount = effectParam:GetTeleportCountByHPPercent(hpPercent)
    if telePortCount == 0 then
        return results
    end
    ---@type table<number,Vector2[]>
    local gridAreaList = effectParam:GetGridAreaArray()
    local tmpList = {}
    for i, _ in ipairs(gridAreaList) do
        table.insert(tmpList,i)
    end
    ---@type RandomServiceLogic
    local randomServiceLogic = self._world:GetService("RandomLogic")
    for i = 1, telePortCount do
        local index = randomServiceLogic:LogicRand(1, #tmpList)
        local randAreaIndex =tmpList[index]
        Log.debug("TeleportIndex:",randAreaIndex)
        local result = self:_CalculateSingleTarget(skillEffectCalcParam,i==telePortCount,randAreaIndex)
        if result then
            table.insert(results, result)
        end
        table.removev(tmpList,randAreaIndex)
    end

    return results
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_TeleportAndSummonTrap:_CalculateSingleTarget(skillEffectCalcParam,isLast,randAreaIndex)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type SkillEffectParamTeleportAndSummonTrap
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()
    local trapCount = effectParam:GetTrapCount()
    ---@type table<number,Vector2[]>
    local gridAreaList = effectParam:GetGridAreaArray()
    local trapSvc = self._world:GetService("TrapLogic")
    ---@type RandomServiceLogic
    local randomServiceLogic = self._world:GetService("RandomLogic")
    local tempGridList = {}
    local teleportGridList = {}
    local gridArea = gridAreaList[randAreaIndex]
    for i, pos in ipairs(gridArea) do
        table.insert(tempGridList, pos:Clone())
        table.insert(teleportGridList, pos:Clone())
    end
    if teleportGridList =={} then
        Log.fatal("teleportGridList is empty Index:",randAreaIndex)
    end
    local bFind = false
    ----@type MonsterIDComponent
    local monsterIDCmpt = casterEntity:MonsterID()
    local utilDataSvc = self._world:GetService("UtilData")

    local teleportPos
    while not bFind or (#tempGridList == 0) do
        local index = randomServiceLogic:LogicRand(1, #teleportGridList)
        local pos = teleportGridList[index]
        table.remove(teleportGridList, index)
        if not utilDataSvc:IsPosBlock(pos, monsterIDCmpt:GetMonsterBlockData()) then
            teleportPos = pos
            bFind = true
        end
    end

    local trapID = effectParam:GetTrapID()
    local trapPosList = {}
    while trapCount > 0 or (#tempGridList == 0) do
        local index = randomServiceLogic:LogicRand(1, #tempGridList)
        local pos = tempGridList[index]
        table.remove(tempGridList, index)
        if trapSvc:CanSummonTrapOnPos(pos, trapID) and not table.Vector2Include(self._trapPosList,pos) then
            table.insert(trapPosList, pos)
            table.insert(self._trapPosList,pos)
            trapCount= trapCount - 1
        end
    end
    if isLast then
        local pos = teleportPos
        if trapSvc:CanSummonTrapOnPos(pos, trapID) and not table.Vector2Include(self._trapPosList,pos) then
            table.insert(trapPosList, pos)
            table.insert(self._trapPosList,pos)
        end
    end
    local result = SkillEffectTeleportAndSummonTrapResult:New(trapPosList,teleportPos)
    return result
end