require("base_ins_r")
---@class PlaySummonDeadTrapInstruction: BaseInstruction
_class("PlaySummonDeadTrapInstruction", BaseInstruction)
PlaySummonDeadTrapInstruction = PlaySummonDeadTrapInstruction

function PlaySummonDeadTrapInstruction:Constructor(paramList)
    self._trapID = tonumber(paramList["trapID"])
    self._effectID = tonumber(paramList["effectID"])
    self._interval = tonumber(paramList["interval"])

    self._materialAnim = tonumber(paramList["materialAnim"])
end

function PlaySummonDeadTrapInstruction:GetCacheResource()
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
function PlaySummonDeadTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillSummonTrapEffectResult[]
    local trapResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.SummonTrap)
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
    end
end

---@param world MainWorld
---@param result SkillSummonTrapEffectResult
function PlaySummonDeadTrapInstruction:_ShowTrapFromSummonTrap(TT, world, result)
    local posSummon = result:GetPos()
    local dirSummon = result:GetDir()
    local trapID = result:GetTrapID()

    local entityIDList = result:GetTrapIDList()
    if #entityIDList == 0 then
        return
    end

    local trapEntity
    for _, entityID in ipairs(entityIDList) do
        local eTrap = world:GetEntityByID(entityID)
        ---@type TrapIDComponent
        local cTrap = eTrap:TrapID()
        -- Log.info(self._className, "component=", cTrap ~= nil, " cmpt trapID=", cTrap:GetTrapID(), " hasDeadMark=",eTrap:HasDeadMark())
        if cTrap and cTrap:GetTrapID() == trapID then
            self:_ShowTrap(TT, world, eTrap, posSummon, dirSummon)
        end
    end
end

---@param world MainWorld
---@param trapEntity Entity
---@param posSummon Vector2
---@param dirSummon Vector2
function PlaySummonDeadTrapInstruction:_ShowTrap(TT, world, trapEntity, posSummon, dirSummon)
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

    if self._materialAnim then
        trapEntity:PlayMaterialAnim(self._materialAnim)
    end
end
