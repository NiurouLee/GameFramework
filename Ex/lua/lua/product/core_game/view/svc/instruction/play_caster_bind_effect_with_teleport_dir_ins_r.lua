require("base_ins_r")
---@class PlayCasterBindEffectWithTeleportDirInstruction: BaseInstruction
_class("PlayCasterBindEffectWithTeleportDirInstruction", BaseInstruction)
PlayCasterBindEffectWithTeleportDirInstruction = PlayCasterBindEffectWithTeleportDirInstruction

function PlayCasterBindEffectWithTeleportDirInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._stageIndex = tonumber(paramList.stageIndex) or 1
end

---@param casterEntity Entity
function PlayCasterBindEffectWithTeleportDirInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_Teleport
    local teleportResult = routineComponent:GetEffectResultByArray(SkillEffectType.Teleport, self._stageIndex)

    if not teleportResult then
        return
    end

    local posOld = teleportResult:GetPosOld()
    local posNew = teleportResult:GetPosNew()

    if posOld == posNew then
        return
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type Entity
    local effect = world:GetService("Effect"):CreateEffect(self._effectID, casterEntity)

    YIELD(TT)

    local dir
    if posOld.x == posNew.x and posOld.y > posNew.y then
        -- effect:SetDirection(Vector2(0, -1))
        dir = true
    elseif posOld.x > posNew.x and posOld.y == posNew.y then
        -- effect:SetDirection(Vector2(0, -1))
        dir = true
    end

    if dir then
        local cView = effect:View()
        local tran = cView.ViewWrapper.Transform
        local endRotation = Quaternion.Euler(0, 180, 0)
        local tweener = tran:DOLocalRotateQuaternion(endRotation, 0)
    end
end

function PlayCasterBindEffectWithTeleportDirInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
