require("base_ins_r")
---@class PlaySummonTrapBySummonEveryThingInstruction: BaseInstruction
_class("PlaySummonTrapBySummonEveryThingInstruction", BaseInstruction)
PlaySummonTrapBySummonEveryThingInstruction = PlaySummonTrapBySummonEveryThingInstruction

function PlaySummonTrapBySummonEveryThingInstruction:Constructor(paramList)
    self._trapID = tonumber(paramList["trapID"])
    self._effectID = tonumber(paramList["effectID"])

    self._interval = tonumber(paramList["interval"])
end

function PlaySummonTrapBySummonEveryThingInstruction:GetCacheResource()
    local t = {}
    if self._trapID then
        local cfgTrap = Cfg.cfg_trap[self._trapID]
        if cfgTrap then
            table.insert(t, {cfgTrap.ResPath, 1})
        end
    end
    if self._effectID then
        local cfgfx = Cfg.cfg_effect[self._effectID]
        if cfgfx then
            table.insert(t, {cfgfx.ResPath, 1})
        end
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlaySummonTrapBySummonEveryThingInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResult_SummonEverything[]
    local summonResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonEverything)
    if summonResultArray then
        for i = 1, #summonResultArray do
            ---@type SkillEffectResult_SummonEverything
            local summonRes = summonResultArray[i]
            ---@type SkillEffectEnum_SummonType
            local summonType = summonRes:GetSummonType()
            local summonTrapID = summonRes:GetSummonID()
            if summonType == SkillEffectEnum_SummonType.Trap and self._trapID == summonTrapID then
                self:_ShowTrapFromSummonEverything(TT, world, summonRes)
            end
        end
    end
end

---@param summonRes SkillEffectResult_SummonEverything
function PlaySummonTrapBySummonEveryThingInstruction:_ShowTrapFromSummonEverything(TT, world, summonRes)
    local summonMonsterData = summonRes:GetTrapData()
    local posSummon = summonRes:GetSummonPos()
    local summonTrapID = summonRes:GetSummonID()
    ---@type Entity
    local trapEntity = world:GetEntityByID(summonMonsterData.m_entityWorkID)
    if not trapEntity then
        Log.error(self._className, "trap not found: ", tostring(posSummon), " id=", summonTrapID)
        return
    end
    self:_ShowTrap(TT, world, trapEntity, posSummon)
end

---@param world MainWorld
---@param summonRes SkillEffectResult_SummonEverything
function PlaySummonTrapBySummonEveryThingInstruction:_ShowTrap(TT, world, trapEntity, posSummon)
    trapEntity:SetPosition(posSummon)
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)

    if self._effectID and self._effectID > 0 then
        local effectService = world:GetService("Effect")
        effectService:CreateWorldPositionDirectionEffect(self._effectID, posSummon)
    end
end
