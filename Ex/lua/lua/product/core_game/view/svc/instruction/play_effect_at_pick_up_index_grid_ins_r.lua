require("base_ins_r")

---@class PlayEffectAtPickUpIndexGridInstruction: BaseInstruction
_class("PlayEffectAtPickUpIndexGridInstruction", BaseInstruction)
PlayEffectAtPickUpIndexGridInstruction = PlayEffectAtPickUpIndexGridInstruction

function PlayEffectAtPickUpIndexGridInstruction:Constructor(paramList)
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
function PlayEffectAtPickUpIndexGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local oriEntity = casterEntity
    if casterEntity:HasSuperEntity() and casterEntity:EntityType():IsSkillHolder() then
        ---@type SuperEntityComponent
        local cSuperEntity = casterEntity:SuperEntityComponent()
        oriEntity = cSuperEntity:GetSuperEntity()
    end

    ---@type MainWorld
    local world = oriEntity:GetOwnerWorld()
    ---@type EffectService
    local sEffect = world:GetService("Effect")
    local dir = Vector2(self._dirX, self._dirY)

    ---@type RenderPickUpComponent
    local renderPickUpComponent = oriEntity:RenderPickUpComponent()
    if not renderPickUpComponent then
        return
    end
    local pickUpGridArray = renderPickUpComponent:GetAllValidPickUpGridPos()
    local v2PickupPos = pickUpGridArray[self._pickUpIndex]

    if self._dirOnPickup then
        dir = v2PickupPos - oriEntity:GetGridPosition()
    end

    local effectEntity = sEffect:CreateWorldPositionDirectionEffect(self._effectID, v2PickupPos, dir)
end

function PlayEffectAtPickUpIndexGridInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._effectID].ResPath, 1 })
    end
    return t
end
