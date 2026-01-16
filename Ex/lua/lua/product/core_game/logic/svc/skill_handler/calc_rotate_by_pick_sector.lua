--[[
    Rotate = 12, --旋转
]]
---@class SkillEffectCalc_RotateByPickSector: Object
_class("SkillEffectCalc_RotateByPickSector", Object)
SkillEffectCalc_RotateByPickSector = SkillEffectCalc_RotateByPickSector

function SkillEffectCalc_RotateByPickSector:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_RotateByPickSector:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = casterEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        Log.error(self._className, "施法者没有ActiveSkillPickupComponent")
        return
    end

    local pickupPosArray = pickupComponent:GetAllValidPickUpGridPos()
    if #pickupPosArray < 2 then
        Log.error(self._className, "没有足够点选位置记录")
        return
    end

    ---@type SkillEffectParamRotateByPickSector
    local sep = skillEffectCalcParam.skillEffectParam
    local absRotateAngle = sep:GetAbsRotateAngle()

    local curPos = casterEntity:GetGridPosition()
    local curDir = casterEntity:GetGridDirection()

    local mainDirPos = pickupPosArray[1]
    local expandDirPos = pickupPosArray[2]
    local mainDir = mainDirPos - curPos
    local expandDir = expandDirPos - mainDirPos
    local mainDirVec3 = Vector3(mainDir.x,mainDir.y,0)
    local expandDirVec3 = Vector3(expandDir.x,expandDir.y,0)
    local crossRes = Vector3.Cross(mainDirVec3, expandDirVec3)
    local angleDirFlag = 0
    if crossRes.z > 0 then--逆时针
        angleDirFlag = -1
    elseif crossRes.z < 0 then --顺时针
        angleDirFlag = 1
    end
    local finalRotateAngle = absRotateAngle * angleDirFlag
    local curDirV3 = Vector3(curDir.x,0,curDir.y)
    local endRotation = Quaternion.Euler(0, finalRotateAngle, 0)
    local dirNewV3 = endRotation * curDirV3
    local dirNew = Vector2(dirNewV3.x,dirNewV3.z)
    table.insert(results, SkillEffectResult_RotateByPickSector:New(finalRotateAngle, dirNew))

    return results
end
