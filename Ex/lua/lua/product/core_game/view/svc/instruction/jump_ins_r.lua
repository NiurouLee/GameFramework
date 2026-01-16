require("base_ins_r")
---Jump指令，如果条件满足，跳转到GOTO指定的指令
---@class JumpInstruction: BaseInstruction
_class("JumpInstruction", BaseInstruction)
JumpInstruction = JumpInstruction

function JumpInstruction:Constructor(paramList)
    self._condition = paramList["condition"]
    self._gotoLabel = paramList["goto"]
    local strResult = paramList["result"] --1或不配=true；其他=false
    if strResult then
        self._result = tonumber(strResult) == 1
    else
        self._result = true
    end
    self._conditionParam = paramList["param"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function JumpInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type PlaySkillService
    local playSkillService = world:GetService("PlaySkill")
    ---@type SkillViewConditionHelper
    local conditionHelper = playSkillService:GetSkillViewConditionHelper()
    local checkResult =
        conditionHelper:CheckCondition(self._condition, casterEntity, phaseContext, self._conditionParam)
    if checkResult == self._result then
        return self._gotoLabel
    end
    return nil
end
