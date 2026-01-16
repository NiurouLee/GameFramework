require("base_ins_r")
---@class PlaySummonTrapInstruction: BaseInstruction
_class("PlaySummonTrapInstruction", BaseInstruction)
PlaySummonTrapInstruction = PlaySummonTrapInstruction

function PlaySummonTrapInstruction:Constructor(paramList)
    self._trapID = tonumber(paramList["trapID"])
    self._effectID = tonumber(paramList["effectID"])

    self._interval = tonumber(paramList["interval"])

    self._hackWait = tonumber(paramList["hackWait"])

    self._waitFinish = tonumber(paramList["waitFinish"])
end

function PlaySummonTrapInstruction:GetCacheResource()
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
function PlaySummonTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    if not skillEffectResultContainer then
        Log.error("PlaySummonTrap: result container is nil")
        return
    end

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
                break
            end
        end
    end
    ---@type SkillSummonTrapEffectResult[]
    local trapResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonTrap)
    local trapResultArrayCount = 0
    if trapResultArray then
        for i = 1, #trapResultArray do
            local result = trapResultArray[i]
            local summonTrapID = result:GetTrapID()
            if summonTrapID == self._trapID then
                local index = i
                GameGlobal.TaskManager():CoreGameStartTask(
                    function()
                        if self._interval then
                            YIELD(TT, (index - 1) * self._interval)
                        end
                        self:_ShowTrapFromSummonTrap(TT, world, result)
                    end
                )
            end
        end
        trapResultArrayCount = #trapResultArray
    end

    if self._waitFinish == 1 and trapResultArrayCount > 0 and self._interval then
        YIELD(TT, trapResultArrayCount * self._interval)
    end
end

---@param summonRes SkillEffectResult_SummonEverything
function PlaySummonTrapInstruction:_ShowTrapFromSummonEverything(TT, world, summonRes)
    local summonMonsterData = summonRes:GetTrapData()
    local posSummon = summonRes:GetSummonPos()
    ---@type Entity
    local trapEntity = world:GetEntityByID(summonMonsterData.m_entityWorkID)

    self:_ShowTrap(TT, world, trapEntity, posSummon)
end

---@param world MainWorld
---@param result SkillSummonTrapEffectResult
function PlaySummonTrapInstruction:_ShowTrapFromSummonTrap(TT, world, result)
    local posSummon = result:GetPos()
    local dirSummon = result:GetDir()
    local trapID = result:GetTrapID()

    local entityIDList = result:GetTrapIDList()
    if #entityIDList == 0 then
        return
    end

    for _, entityID in ipairs(entityIDList) do
        local eTrap = world:GetEntityByID(entityID)
        ---@type TrapIDComponent
        local cTrap = eTrap:TrapID()
        -- Log.info(self._className, "component=", cTrap ~= nil, " cmpt trapID=", cTrap:GetTrapID(), " hasDeadMark=",eTrap:HasDeadMark())
        if cTrap and cTrap:GetTrapID() == trapID and not eTrap:HasDeadMark() then
            self:_ShowTrap(TT, world, eTrap, posSummon, dirSummon)
        end
    end
end

---@param world MainWorld
---@param summonRes SkillEffectResult_SummonEverything
function PlaySummonTrapInstruction:_ShowTrap(TT, world, trapEntity, posSummon)
    if self._hackWait then
        ---MSG55411，连续给gameobject设置active标记，会导致第一个动画无法播放
        ---没有找到具体原因，临时处理下
        YIELD(TT)
    end
    trapEntity:SetPosition(posSummon)

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)

    if self._effectID and self._effectID > 0 then
        local effectService = world:GetService("Effect")
        effectService:CreateWorldPositionDirectionEffect(self._effectID, posSummon)
    end
end

---@param world MainWorld
---@param trapEntity Entity
---@param posSummon Vector2
---@param dirSummon Vector2
function PlaySummonTrapInstruction:_ShowTrap(TT, world, trapEntity, posSummon, dirSummon)
    trapEntity:SetPosition(posSummon)
    if dirSummon then
        trapEntity:SetDirection(dirSummon)
    end
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)

    if self._effectID and self._effectID > 0 then
        local effectService = world:GetService("Effect")
        effectService:CreateWorldPositionDirectionEffect(self._effectID, posSummon, dirSummon)
    end
end
