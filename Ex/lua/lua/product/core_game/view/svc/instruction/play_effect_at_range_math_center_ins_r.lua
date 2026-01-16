require("base_ins_r")

---@class PlayEffectAtRangeMathCenterInstruction: BaseInstruction
_class("PlayEffectAtRangeMathCenterInstruction", BaseInstruction)
PlayEffectAtRangeMathCenterInstruction = PlayEffectAtRangeMathCenterInstruction

function PlayEffectAtRangeMathCenterInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])

    self._pickUpIndex = tonumber(paramList["pickUpIndex"])

    self._dirX = 0
    self._dirY = 1
    if paramList["dirX"] then
        self._dirX = tonumber(paramList["dirX"])
    end
    if paramList["dirY"] then
        self._dirY = tonumber(paramList["dirY"])
    end

    self._dirOnPickup = tonumber(paramList["dirOnPickup"]) == 0
end

---@param casterEntity Entity
function PlayEffectAtRangeMathCenterInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local gridDataArray = scopeResult:GetAttackRange()
    local minX = 9
    local minY = 9
    local maxX = 0
    local maxY = 0
    for _, v2 in ipairs(gridDataArray) do
        if v2.x < minX then
            minX = v2.x
        end
        if v2.x > maxX then
            maxX = v2.x
        end
        if v2.y < minY then
            minY = v2.y
        end
        if v2.y > maxY then
            maxY = v2.y
        end
    end
    local v2Center = Vector2.New(0.5 * (minX + maxX), 0.5 * (minY + maxY))
    --播放特效
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local effectService = world:GetService("Effect")
    effectService:CreateWorldPositionEffect(self._effectID, v2Center)
end

function PlayEffectAtRangeMathCenterInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
