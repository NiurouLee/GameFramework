require "homelandpet_behavior_base"

---@class HomelandPetBehaviorFurnitureInvite:HomelandPetBehaviorBase
_class("HomelandPetBehaviorFurnitureInvite", HomelandPetBehaviorBase)
HomelandPetBehaviorFurnitureInvite = HomelandPetBehaviorFurnitureInvite

function HomelandPetBehaviorFurnitureInvite:Constructor(behaviorType, pet)
    HomelandPetBehaviorFurnitureInvite.super.Constructor(self, behaviorType, pet)
    ---@type HomelandPetInviteManager
    self._petInviteManager = self._homelandClient:GetHomelandPetInviteManager()
    self._petManager = self._homelandClient:PetManager()
    ---@type HomelandPetComponentMove
    self._moveComponent = self:GetComponent(HomelandPetComponentType.Move)
    ---@type HomelandPetComponentInteractionAnimation
    self._animationComponent = self:GetComponent(HomelandPetComponentType.InteractionAnimation)
    ---@type InteractPoint
    self._interactPoint = nil

end

function HomelandPetBehaviorFurnitureInvite:Enter()
    HomelandPetBehaviorFurnitureInvite.super.Enter(self)
    ---@type HomeBuilding
    local building =  self._petInviteManager:GetOperateBuilding()
    if building == nil then
        self._pet:GetPetBehavior():RandomBehavior()
        return
    end

    ---@type InteractPoint
    self._interactPoint = building:GetPetInteractPoint()
    if self._interactPoint then
        ---@type UnityEngine.Transform
        local targetTransform = building:GetInteractTransform(self._interactPoint:GetIndex())
        if not self._petManager:MainCharacterInteracting(building, targetTransform) then
            self._moveComponent:SetTarget(targetTransform.position)
            if targetTransform.childCount > 0 then
                -- local cfgArchitecture = Cfg.cfg_item_architecture[building:GetBuildId()]
                -- local cfgBuildingPet = self:_GetInteractionCfg(cfgArchitecture.Interaction)
                -- if cfgBuildingPet then
                --     self._animationComponent:Play(cfgBuildingPet, building, self._interactPoint, targetTransform, targetTransform:GetChild(0), self._cfgBehaviorLib.InteractLoopTime)
                -- else
                --     self._pet:GetPetBehavior():RandomBehavior()
                --     return
                -- end
            end
            self._interactPoint:SetInteractObject(self._pet)
            self._pet:SetInteractingBuilding(building)
        else
            self._pet:GetPetBehavior():RandomBehavior()
        end
    else
        self._pet:GetPetBehavior():RandomBehavior()
    end
end
function HomelandPetBehaviorFurnitureInvite:Exit()
    HomelandPetBehaviorFurnitureInvite.super.Exit(self)
    HomelandPetBehaviorInteractingFurniture.super.Exit(self)
    if self._interactPoint then
        self._interactPoint:SetInteractObject(nil)
        self._interactPoint = nil
    end
    self._pet:SetInteractingBuilding(nil)
end
function HomelandPetBehaviorFurnitureInvite:CanInterrupt()
    return true
end

---@return cfg_homeland_building_pet
function HomelandPetBehaviorFurnitureInvite:_GetInteractionCfg(interactions)
    local cfg = nil
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    local finishEventList = homelandModule:GetHomeLandEventInfo().finish_event_list
    for _, id in pairs(interactions) do
        if self:_IsUnLock(self._pet:TemplateID(), id, finishEventList) then
            local cfgBuildingPet = Cfg.cfg_homeland_building_pet[id]
            if cfgBuildingPet then
                if not cfgBuildingPet.petIDs or 
                table.icontains(cfgBuildingPet.petIDs, self._pet:TemplateID()) or 
                table.icontains(cfgBuildingPet.petIDs, self._pet:SkinID()) then
                    cfg = cfgBuildingPet
                    break
                end
            end
        end
    end
    return cfg
end
---@param petID number
---@param id cfg_homeland_building_pet
function HomelandPetBehaviorFurnitureInvite:_IsUnLock(petID, id, finishEventList)
    -- local cfgs = Cfg.cfg_homeland_event{PetID = petID}
    -- if not cfgs then
    --     return true
    -- end
    -- for _, cfg in pairs(cfgs) do
    --     if cfg.RewardsInteractID and table.icontains(cfg.RewardsInteractID, id) then
    --         for eventID, eventTime in pairs(finishEventList) do
    --             if eventID == cfg.ID then
    --                 return true
    --             end
    --         end
    --         return false
    --     end
    -- end
    return true
end

