require("base_ins_r")
---@class WaitInstruction: BaseInstruction
_class("WaitInstruction", BaseInstruction)
WaitInstruction = WaitInstruction

function WaitInstruction:Constructor(paramList)
    self._waitTime = tonumber(paramList["waitTime"])
end

---@param casterEntity Entity
function WaitInstruction:DoInstruction(TT,casterEntity,phaseContext)
    if self._waitTime > 0 then 
        YIELD(TT,self._waitTime)
    else
        YIELD(TT)
    end
end
