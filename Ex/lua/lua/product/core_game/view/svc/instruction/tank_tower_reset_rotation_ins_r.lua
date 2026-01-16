--[[
    N34坦克的炮台转向指令

    拒绝承诺该指令可复用于其他单位。尝试复用即理解并同意承担一切后果。
]]
require("base_ins_r")

_class("TankTowerResetRotationInstruction", BaseInstruction)
---@class TankTowerResetRotationInstruction: BaseInstruction
TankTowerResetRotationInstruction = TankTowerResetRotationInstruction

function TankTowerResetRotationInstruction:Constructor(paramList)
    self._time = tonumber(paramList.time)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function TankTowerResetRotationInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    local casterPos = casterEntity:GetRenderGridPosition()
    local casterDir = casterEntity:GetRenderGridDirection()
    local casterOffset = casterEntity:GridLocation():GetDamageOffset()
    local lookAtPos = casterPos + casterDir + casterOffset

    ---@type BoardServiceRender
    local BoardServiceRender = world:GetService("BoardRender")
    local v3Forward = BoardServiceRender:GridPos2RenderPos(lookAtPos)

    local cEffectHolder = casterEntity:EffectHolder()
    local efx = cEffectHolder:GetEffectList(BattleConst.Tank2002901TowerEffectKey)[1]
    local timeInSecond = self._time * 0.001

    ---@type DG.Tweening.Tweener
    local tweener = efx:View():GetGameObject().transform:DOLookAt(v3Forward, timeInSecond):SetEase(DG.Tweening.Ease.InOutSine)
    YIELD(TT, self._time)
    if not tweener:IsComplete() then
        tweener:Complete()
    end
end
