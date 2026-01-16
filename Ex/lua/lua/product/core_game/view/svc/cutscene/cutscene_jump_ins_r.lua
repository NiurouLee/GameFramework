require("cutscene_base_ins_r")
---Jump指令，如果条件满足，跳转到GOTO指定的指令
---@class CutsceneJumpInstruction: BaseInstruction
_class("CutsceneJumpInstruction", BaseInstruction)
CutsceneJumpInstruction = CutsceneJumpInstruction

function CutsceneJumpInstruction:Constructor(paramList)
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
function CutsceneJumpInstruction:DoInstruction(TT, casterEntity, phaseContext)

end
