require("base_ins_r")
_class("PlayCreateCasterGhostInstruction", BaseInstruction)
---@class PlayCreateCasterGhostInstruction: BaseInstruction
PlayCreateCasterGhostInstruction = PlayCreateCasterGhostInstruction

function PlayCreateCasterGhostInstruction:Constructor(params)
    self._type = params["Type"]
    self._prefab = params["Prefab"]
    self._anim = params["Anim"] or "AtkUltPreview"
    self._disableAlpha = (tonumber(params["DisableAlpha"] or 0) == 1) or false
    self._bornEffectID = tonumber(params["BornEffectID"])
end

function PlayCreateCasterGhostInstruction:GetCacheResource()
    local t = {}
    if self._bornEffectID and self._bornEffectID > 0 and Cfg.cfg_effect[self._bornEffectID] then
        table.insert(t, {Cfg.cfg_effect[self._bornEffectID].ResPath, 1})
    end
    return t
end

---指令的具体执行
---@param casterEntity Entity 施法者
function PlayCreateCasterGhostInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")
    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    if not renderPickUpComponent then
        return
    end

    if self._type == "Scope" then
        local scopeList = phaseContext:GetScopeResult()
        for _, pos in pairs(scopeList) do
            entitySvc:CreateGhost(pos, casterEntity, self._anim, self._prefab)
        end
    elseif self._type == "PickUp" then
        local pickUpPos = renderPickUpComponent:GetLastPickUpGridPos()
        local ghostEntity = entitySvc:CreateGhost(pickUpPos, casterEntity, self._anim, self._prefab)
    elseif self._type == "PickUpRotate" then
        local pickUpPos = renderPickUpComponent:GetLastPickUpGridPos()
        local ghostEntity = entitySvc:CreateGhost(pickUpPos, casterEntity, self._anim, self._prefab, self._disableAlpha)
        renderPickUpComponent:SetRotateGhost(ghostEntity)
        local reflectPos = renderPickUpComponent:GetReflectPos()
        if reflectPos then
            --旋转ghost朝向反射目标点
            ghostEntity:SetDirection(reflectPos - pickUpPos)
        end
        if self._bornEffectID then
            ---@type EffectService
            local effSvc = world:GetService("Effect")
            effSvc:CreateEffect(self._bornEffectID, ghostEntity)
        end
    end
end
