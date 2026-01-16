--[[
    SwitchBodyAreaByTargetPos = 143, --根据目标位置旋转BodyArea
]]

require('switch_body_area_dir_type')

_class("SkillEffectCalc_SwitchBodyAreaByTargetPos", Object)
---@class SkillEffectCalc_SwitchBodyAreaByTargetPos: Object
SkillEffectCalc_SwitchBodyAreaByTargetPos = SkillEffectCalc_SwitchBodyAreaByTargetPos

function SkillEffectCalc_SwitchBodyAreaByTargetPos:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SwitchBodyAreaByTargetPos:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    local targetID = false
    if table.count(targetIDList) >= 1 then
        targetID = targetIDList[1]
    end
    if not targetID or targetID == -1  then
        Log.fatal("Need Target SkillID",skillEffectCalcParam:GetSkillID())
    end
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    ---@type SkillEffectSwitchBodyAreaByTargetPosParam
    local param = skillEffectCalcParam:GetSkillEffectParam()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local type = param:GetType()
    ---@type Vector2
    local newBodyArea
    local newDir
    ---@type SwitchBodyAreaDirType
    local switchBodyType = SwitchBodyAreaDirType.None
    if type == SwitchBodyAreaType.TailFlick then
        newDir,newBodyArea,switchBodyType = utilScopeSvc:GetTailFlickSwitchBodyArea(casterEntity,targetEntity)
    elseif type == SwitchBodyAreaType.CounterAttack then
        newDir,newBodyArea,switchBodyType = utilScopeSvc:GetCounterAttackSwitchBodyArea(casterEntity,targetEntity)
    elseif type == SwitchBodyAreaType.ByCasterDir then
        newDir,newBodyArea = self:RefreshBodyAreaByCasterDir(casterEntity)
    elseif type == SwitchBodyAreaType.AfterTransformation then
        newDir,newBodyArea = self:GetValidBodyAreaAfterTransformation(casterEntity)
    elseif type == SwitchBodyAreaType.CoffinMusume then
        newDir, newBodyArea, switchBodyType = self:GetCoffinMusumeBodyArea(casterEntity, targetEntity)
    end
    local casterPos = casterEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()
    local oldBodyAreaPos = casterPos + bodyArea[1]
    ---@type SkillEffectSwitchBodyAreaByTargetPosResult
    local result = SkillEffectSwitchBodyAreaByTargetPosResult:New(newDir,newBodyArea,switchBodyType,oldBodyAreaPos, bodyArea)
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local _, blockFlag =sBoard:RemoveEntityBlockFlag(casterEntity, casterPos)
    --local oldDir = casterEntity:GetGridDirection()
    --Log.debug(self._className, "grid direction changed: entity ", casterEntity:GetID(), " oldDir=", tostring(oldDir), " newDir=", tostring(newDir))
    casterEntity:SetGridDirection(newDir)
    casterEntity:ReplaceBodyArea(newBodyArea)
    sBoard:SetEntityBlockFlag(casterEntity,casterPos,blockFlag)
    return { result }
end
---@param casterEntity Entity
function SkillEffectCalc_SwitchBodyAreaByTargetPos:RefreshBodyAreaByCasterDir(casterEntity)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local dirType =utilScopeSvc:GetEntityDirType(casterEntity)
    ---@type Vector2
    local bodyArea = utilScopeSvc:GetNewBodyAreaByDirType(dirType)
    ---@type Vector2
    local dir = casterEntity:GetGridDirection()
    return dir, { Vector2(0,0),bodyArea }
end

---@param casterEntity Entity
function SkillEffectCalc_SwitchBodyAreaByTargetPos:GetValidBodyAreaAfterTransformation(casterEntity)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local casterPos = casterEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = casterEntity:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()
    local bodyAreaPos = casterPos + bodyArea[1]
    if utilScopeSvc:IsValidPiecePos(bodyAreaPos) then
        ---@type Vector2
        local dir = utilScopeSvc:GetVectorDirByBodyArea(casterEntity)
        return dir,bodyArea
    end
    local retDir
    local retBodyArea={Vector2(0,0)}
    ---@type DirectionType[]
    local dirTypeList = {DirectionType.Up,DirectionType.Right,DirectionType.Down,DirectionType.Left}
    for i, dirType in ipairs(dirTypeList) do
        local area = utilScopeSvc:GetNewBodyAreaByDirType(dirType)
        if utilScopeSvc:IsValidPiecePos(casterPos+area) then
            retDir = utilScopeSvc:GetDirByDirType(dirType)
            table.insert(retBodyArea,area)
            return retDir,retBodyArea
        end
    end


end

---棺材娘专属逻辑，参见https://wiki.h3d.com.cn/pages/viewpage.action?pageId=74768251
---@param casterEntity Entity
---@param targetEntity Entity
function SkillEffectCalc_SwitchBodyAreaByTargetPos:GetCoffinMusumeBodyArea(casterEntity, targetEntity)
    local casterGridCenterPos = casterEntity:GetGridPosition()
    local targetPos = targetEntity:GetGridPosition()
    local relative = targetPos - casterGridCenterPos

    local oldGridDir = casterEntity:GetGridDirection()
    local oldBodyArea = casterEntity:BodyArea():GetArea()

    -- 向量统一旋转至施法者面向(0, -1)的情况，统一判断转向的相对方向
    if oldGridDir == Vector2.up then
        relative = Vector2.New(relative.x * (-1), relative.y * (-1))
    elseif oldGridDir == Vector2.left then
        relative = Vector2.New(relative.y * (-1), relative.x)
    elseif oldGridDir == Vector2.right then
        relative = Vector2.New(relative.y, relative.x * (-1))
    end

    local newGridDir = oldGridDir
    local newBodyArea = {}
    local dirType = SwitchBodyAreaDirType.None

    --以下判断条件需对照wiki的图片
    if (relative.x <= 1 and relative.x >= -1) and (relative.y < 0) then
        return oldGridDir, oldBodyArea, SwitchBodyAreaDirType.None
    elseif (relative.x > 0) and (relative.y <= 1 and relative.y >= -1) then
        for _, v2 in ipairs(oldBodyArea) do
            table.insert(newBodyArea, Vector2.New(v2.y * (-1), v2.x))
        end
        newGridDir = Vector2.New(oldGridDir.y * (-1), oldGridDir.x)
        dirType = SwitchBodyAreaDirType.Left
    elseif (relative.x < 0) and (relative.y <= 1 and relative.y >= -1) then
        for _, v2 in ipairs(oldBodyArea) do
            table.insert(newBodyArea, Vector2.New(v2.y, v2.x * (-1)))
        end
        newGridDir = Vector2.New(oldGridDir.y, oldGridDir.x * (-1))
        dirType = SwitchBodyAreaDirType.Right
    else
        for _, v2 in ipairs(oldBodyArea) do
            table.insert(newBodyArea, Vector2.New(v2.x * (-1), v2.y * (-1)))
        end
        newGridDir = Vector2.New(oldGridDir.x * (-1), oldGridDir.y * (-1))
        dirType = SwitchBodyAreaDirType.Turn
    end

    if self._world:RunAtClient() and HelperProxy:GetInstance():IsDebug() then
        local casterPos = casterEntity:GetGridPosition()
        local oldBodyAreaStrTable = {}
        for _, v2 in ipairs(oldBodyArea) do
            table.insert(oldBodyAreaStrTable, (v2 + casterPos):IntegerStr())
        end
        local newBodyAreaStrTable = {}
        for _, v2 in ipairs(newBodyArea) do
            table.insert(newBodyAreaStrTable, (v2 + casterPos):IntegerStr())
        end
        Log.info("[CoffinMusume] switch body from : ", table.concat(oldBodyAreaStrTable), " to ", table.concat(newBodyAreaStrTable))
        Log.info("[CoffinMusume] oldGridDir = ", tostring(oldGridDir), " newGridDir = ", tostring(newGridDir), " dirType = ", GetEnumKey("SwitchBodyAreaDirType", dirType))
    end

    return newGridDir, newBodyArea, dirType
end
