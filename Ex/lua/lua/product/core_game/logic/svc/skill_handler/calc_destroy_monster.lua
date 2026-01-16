require("calc_base")

---@class SkillEffectCalc_DestroyMonster
_class("SkillEffectCalc_DestroyMonster", SkillEffectCalc_Base)
SkillEffectCalc_DestroyMonster = SkillEffectCalc_DestroyMonster

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DestroyMonster:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectDestroyMonsterParam
    local effectParam = skillEffectCalcParam.skillEffectParam
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local destroyType = effectParam:GetDestroyType()
    ---@type Group
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    ---@type Entity[]
    local Entities = monsterGroup:GetEntities()
    local resultArray = {}
    if destroyType == SkillEffectDestroyMonsterType.Self then
        if casterEntity:HasMonsterID() then
            table.insert(resultArray, SkillEffectDestroyMonsterResult:New(casterEntity:GetID()))
        end
    elseif destroyType == SkillEffectDestroyMonsterType.MySummonMonster then
        for i, e in ipairs(Entities) do
            if e:HasSummoner() and e:GetSummonerEntity() == casterEntity then
                table.insert(resultArray, SkillEffectDestroyMonsterResult:New(e:GetID()))
            end
        end
    elseif destroyType == SkillEffectDestroyMonsterType.InRangeSpecificClass then
        local monsterClassIdDic = effectParam:GetMonsterClassIdDic()
        ---@type UtilDataServiceShare
        local utilSvc = self._world:GetService("UtilData")
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        for _, pos in ipairs(skillEffectCalcParam.skillRange) do
            local entity = utilSvc:GetMonsterAtPos(pos)
            if entity then
                local nMonsterID = entity:MonsterID():GetMonsterID()
                local nMonsterClassID = monsterConfigData:GetMonsterClassID(nMonsterID)
                if monsterClassIdDic[nMonsterClassID] then
                    table.insert(resultArray, SkillEffectDestroyMonsterResult:New(entity:GetID()))
                end
            end
        end
    elseif destroyType == SkillEffectDestroyMonsterType.TargetMonster then
        local targetIds = skillEffectCalcParam:GetTargetEntityIDs()
        if targetIds then
            if type(targetIds) == "table" then
                for _, targetId in ipairs(targetIds) do
                    table.insert(resultArray, SkillEffectDestroyMonsterResult:New(targetId))
                end
            else
                table.insert(resultArray, SkillEffectDestroyMonsterResult:New(targetIds))
            end
        end
    end
    return resultArray
end
