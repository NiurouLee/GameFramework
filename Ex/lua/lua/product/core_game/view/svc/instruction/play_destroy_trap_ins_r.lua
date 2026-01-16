require("base_ins_r")

---@class PlayDestroyTrapInstruction: BaseInstruction
_class("PlayDestroyTrapInstruction", BaseInstruction)
PlayDestroyTrapInstruction = PlayDestroyTrapInstruction

function PlayDestroyTrapInstruction:Constructor(paramList)
    self._donotPlayDie = paramList.donotPlayDie
    self._noResult = paramList.noResult
    self._delay = 1
    if paramList.delay ~= nil then 
        self._delay = tonumber(paramList.delay)
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayDestroyTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local eTrap = casterEntity
    if eTrap:HasSuperEntity() then
        eTrap = eTrap:GetSuperEntity()
    end

    if not self._noResult then
        ---@type SkillEffectResultContainer
        local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()

        if not routineCmpt then
            return
        end

        ---@type SkillEffectDestroyTrapResult[]
        local resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.DestroyTrap)

        if not resultArray then
            return
        end

        local index = phaseContext:GetCurResultIndexByType(SkillEffectType.DestroyTrap)
        local result = resultArray[index]
        if not result then
            return
        end

        local eID = result:GetEntityID()
        eTrap = world:GetEntityByID(eID)
        if not eTrap then
            return
        end
    end

    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    if self._delay == 1 then 
        trapServiceRender:PlayTrapDieSkill(TT, {eTrap}, self._donotPlayDie)
    elseif self._delay == 0 then 
        local dieTaskID = TaskManager:GetInstance():CoreGameStartTask(
            trapServiceRender.PlayTrapDieSkill, trapServiceRender,{eTrap}, self._donotPlayDie)
        phaseContext:AddPhaseTask(dieTaskID)
    end
end
