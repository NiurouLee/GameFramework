require("base_ins_r")
---@class PlayCasterAttachmentVisibleInstruction: BaseInstruction
_class("PlayCasterAttachmentVisibleInstruction", BaseInstruction)
PlayCasterAttachmentVisibleInstruction = PlayCasterAttachmentVisibleInstruction

function PlayCasterAttachmentVisibleInstruction:Constructor(paramList)
    self._visible = tonumber(paramList["visible"])
end

---@param casterEntity Entity
function PlayCasterAttachmentVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type boolean
    local isShow = self._visible == 1

    casterEntity:SetAttachmentVisible(isShow)
end
