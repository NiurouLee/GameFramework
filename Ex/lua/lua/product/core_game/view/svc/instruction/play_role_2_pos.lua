require("base_ins_r")
---表现上把角色移动到固定位置并显示
---@class PlayRole2PosInstruction: BaseInstruction
_class("PlayRole2PosInstruction", BaseInstruction)
PlayRole2PosInstruction = PlayRole2PosInstruction

function PlayRole2PosInstruction:Constructor(paramList)
    self._posX = tonumber(paramList["posX"]) or 0
    self._posY = tonumber(paramList["posY"]) or 0
end

---@param casterEntity Entity
function PlayRole2PosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    casterEntity:SetViewVisible(true)
    local posNew = Vector2(self._posX, self._posY)
    casterEntity:SetLocationHeight(0)
    casterEntity:SetPosition(posNew + casterEntity:GetGridOffset())
end
