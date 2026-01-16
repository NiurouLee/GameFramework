require("base_ins_r")

---@class ShowHideTrapHeadInstruction: BaseInstruction
_class("ShowHideTrapHeadInstruction", BaseInstruction)
ShowHideTrapHeadInstruction = ShowHideTrapHeadInstruction

function ShowHideTrapHeadInstruction:Constructor(paramList)
    local str = paramList["isShow"] or "0"
    self._isShow = tonumber(str) == 1
end

---@param casterEntity Entity
function ShowHideTrapHeadInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    if not casterEntity:HasTrapRoundInfoRender() then
        return
    end
    local trapRound = casterEntity:TrapRoundInfoRender()
    trapRound:SetIsShow(self._isShow)
end
