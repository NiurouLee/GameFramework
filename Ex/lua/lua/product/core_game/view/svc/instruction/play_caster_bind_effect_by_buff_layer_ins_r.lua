require("base_ins_r")
---@class PlayCasterBindEffectByBuffLayerInstruction: BaseInstruction
_class("PlayCasterBindEffectByBuffLayerInstruction", BaseInstruction)
PlayCasterBindEffectByBuffLayerInstruction = PlayCasterBindEffectByBuffLayerInstruction

function PlayCasterBindEffectByBuffLayerInstruction:Constructor(paramList)
    local strIDList = string.split(paramList["effectIDList"], "|")
    local strLayerList = string.split(paramList["layerCountList"], "|")
    self._effectIDList = {}
    for _, value in ipairs(strIDList) do
        table.insert(self._effectIDList, tonumber(value))
    end
    self._buffLayerCountList = {}
    for _, value in ipairs(strLayerList) do
        table.insert(self._buffLayerCountList, tonumber(value))
    end
    if #self._effectIDList ~= #self._buffLayerCountList then
        Log.fatal("PlayCasterBindEffectByBuffLayer: count error.")
    end
end

function PlayCasterBindEffectByBuffLayerInstruction:GetCacheResource()
    local t = {}
    if self._effectIDList then
        for i, eff in ipairs(self._effectIDList) do
            table.insert(t, { Cfg.cfg_effect[eff].ResPath, 1 })
        end
    end
    return t
end

---@param casterEntity Entity
function PlayCasterBindEffectByBuffLayerInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillDamageEffectResult
    local damageResult = routineComponent:GetEffectResultByArray(SkillEffectType.Damage)

    if not damageResult then
        return
    end

    local layerCount = damageResult:GetBuffLayerCountForDamage()
    local effectID = self._effectIDList[1]
    for index, value in ipairs(self._buffLayerCountList) do
        if layerCount >= value then
            effectID = self._effectIDList[index]
        end
    end

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectSvc = world:GetService("Effect")

    effectSvc:CreateEffect(effectID, casterEntity)
end
