---@class SkillEffectCalc_RotateToPickup: SkillEffectCalc_Base

_class("SkillEffectCalc_RotateToPickup", SkillEffectCalc_Base)
SkillEffectCalc_RotateToPickup = SkillEffectCalc_RotateToPickup

function SkillEffectCalc_RotateToPickup:CalculateOnSingleTarget(skillEffectCalcParam, targetID)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = casterEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        Log.error(self._className, "施法者没有ActiveSkillPickupComponent")
        return
    end

    local pickupPosArray = pickupComponent:GetAllValidPickUpGridPos()
    if #pickupPosArray == 0 then
        Log.error(self._className, "没有点选位置记录")
        return
    end

    ---@type SkillEffectParamRotateToPickup
    local sep = skillEffectCalcParam.skillEffectParam
    local pickUpIndex = sep:GetPickupIndex()
    local selectedPickupPos = pickupPosArray[pickUpIndex]

    if not selectedPickupPos then
        return {}
    end

    local currentPos = casterEntity:GetGridPosition()
    local posNew = selectedPickupPos
    
    local dirNew = selectedPickupPos - currentPos
    if sep:IsUseOriDir() then
        dirNew = Vector2.Normalize(dirNew)
    else
        if dirNew.x > 0 then
            dirNew.x = 1
        elseif dirNew.x < 0 then
            dirNew.x = -1
        end
    
        if dirNew.y > 0 then
            dirNew.y = 1
        elseif dirNew.y < 0 then
            dirNew.y = -1
        end
    end

    local result = SkillEffectResultRotateToPickup:New(dirNew)
    return result
end
