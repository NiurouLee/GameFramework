--[[
    N34坦克的炮台转向指令

    拒绝承诺该指令可复用于其他单位。尝试复用即理解并同意承担一切后果。
]]
require("base_ins_r")

---@class TankTowerLookAtDamageTargetInstruction: BaseInstruction
_class("TankTowerLookAtDamageTargetInstruction", BaseInstruction)
TankTowerLookAtDamageTargetInstruction = TankTowerLookAtDamageTargetInstruction

function TankTowerLookAtDamageTargetInstruction:Constructor(paramList)
    self._time = tonumber(paramList.time)
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function TankTowerLookAtDamageTargetInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    local v3TargetRenderLocation = targetEntity:Location():GetPosition()

    local cEffectHolder = casterEntity:EffectHolder()
    local efx = cEffectHolder:GetEffectList(BattleConst.Tank2002901TowerEffectKey)[1]
    local timeInSecond = self._time * 0.001

    ---@type DG.Tweening.Tweener
    local tweener = efx:View():GetGameObject().transform:DOLookAt(v3TargetRenderLocation, timeInSecond):SetEase(DG.Tweening.Ease.InOutSine)
    YIELD(TT, self._time)
    if not tweener:IsComplete() then
        tweener:Complete()
    end
end
