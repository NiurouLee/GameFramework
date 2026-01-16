---n20 魔方BOSS 技能1 专用表现

require("base_ins_r")
---@class PlayRubikMultiLaserEffectInstruction: BaseInstruction
_class("PlayRubikMultiLaserEffectInstruction", BaseInstruction)
PlayRubikMultiLaserEffectInstruction = PlayRubikMultiLaserEffectInstruction

function PlayRubikMultiLaserEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
end

---@param casterEntity Entity
function PlayRubikMultiLaserEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local attackRange = scopeResult:GetAttackRange()

    local rangLengthList = {}
    for _, pos in pairs(attackRange) do
        if not rangLengthList[pos.x] then
            --默认长度加1  可以打到阻挡格子的中央
            rangLengthList[pos.x] = 0.5
        end
        local newValue = rangLengthList[pos.x] + 1
        --超出屏幕
        if newValue == 7.5 then
            newValue = 20
        end
        rangLengthList[pos.x] = newValue
    end

    ---@type EffectService
    local effectService = world:GetService("Effect")

    local effectPos = Vector3(-4, 0, 3.5)
    for i = 1, 7 do
        local workPos = effectPos + Vector3((i - 1), 0, 0)
        ---@type Entity
        local effect = effectService:CreateWorldPositionEffect(self._effectID, workPos)

        ---@type UnityEngine.Transform
        local effectObject = effect:View():GetGameObject()
        effectObject.transform.localEulerAngles = Vector3(0, 180, 0)

        local length = rangLengthList[i] or 0
        local laser = GameObjectHelper.FindChild(effectObject.transform, "mesh_jiguang")
        laser.transform:DOScale(Vector3(1, 1, length), 0)
    end
end

function PlayRubikMultiLaserEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 7})
    end
    return t
end
