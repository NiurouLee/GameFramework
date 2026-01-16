--[[------------------------------------------------
    ActionSingleTriggerTrapBeginTimes 机关每回合释放不同的技能
--]] ------------------------------------------------
require("action_single_trigger_trap_round")

---@class ActionSingleTriggerTrapBeginTimes:ActionSingleTriggerTrapRound
_class("ActionSingleTriggerTrapBeginTimes", ActionSingleTriggerTrapRound)
ActionSingleTriggerTrapBeginTimes = ActionSingleTriggerTrapBeginTimes

function ActionSingleTriggerTrapBeginTimes:Update()
    local vecSkillLists = self:GetConfigSkillList()
    if vecSkillLists then
        local nGameRound = self:GetRuntimeData("RunRoundCount") or 1
        local useRound = nGameRound % #vecSkillLists
        if useRound == 0 then
            useRound = #vecSkillLists
        end

        self._skillID = vecSkillLists[useRound]
    end

    return AINewNodeStatus.Success
end
