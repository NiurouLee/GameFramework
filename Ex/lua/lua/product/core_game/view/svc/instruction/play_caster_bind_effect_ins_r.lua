require("base_ins_r")
---@class PlayCasterBindEffectInstruction: BaseInstruction
_class("PlayCasterBindEffectInstruction", BaseInstruction)
PlayCasterBindEffectInstruction = PlayCasterBindEffectInstruction

function PlayCasterBindEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._scale = tonumber(paramList["scale"]) or 1

    local randomRotate = paramList["randomRotate"] --随机朝向
    if randomRotate then
        self._randomRotate = tonumber(randomRotate)
    else
        self._randomRotate = nil
    end

    self._forcePlayOnSkillHolder = tonumber(paramList.forcePlayOnSkillHolder) == 1
end

---@param casterEntity Entity
function PlayCasterBindEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local e = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() and (not self._forcePlayOnSkillHolder) then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        e = cSuperEntity:GetSuperEntity()
    end

    ---@type Entity
    local effect = world:GetService("Effect"):CreateEffect(self._effectID, e)

    if effect and self._scale ~= 1 then
        YIELD(TT)

        if self._randomRotate then 
            ---以格子为中心 随机方向偏移
            local randomDir = Vector2(math.random(0, self._randomRotate), math.random(0, self._randomRotate))
            effect:SetDirection(randomDir)
        end

        ---@type UnityEngine.Transform
        local trajectoryObject = effect:View():GetGameObject()
        local transWork = trajectoryObject.transform
        local scaleData = Vector3.New(self._scale, self._scale, self._scale)
        ---@type DG.Tweening.Sequence
        local sequence = transWork:DOScale(scaleData, 0)
    end
end

function PlayCasterBindEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
