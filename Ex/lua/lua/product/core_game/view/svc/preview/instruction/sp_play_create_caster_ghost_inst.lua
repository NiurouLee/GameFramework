require("sp_base_inst")
_class("SkillPreviewPlayCreateCasterGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCreateCasterGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCreateCasterGhostInstruction = SkillPreviewPlayCreateCasterGhostInstruction

function SkillPreviewPlayCreateCasterGhostInstruction:Constructor(params)
    self._type = params["Type"]
    self._prefab = params["Prefab"]
    self._anim = params["Anim"] or "AtkUltPreview"
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCreateCasterGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")

    if self._type == "Scope" then
        local scopeList = previewContext:GetScopeResult()
        for _, pos in pairs(scopeList) do
            entitySvc:CreateGhost(pos, casterEntity, self._anim, self._prefab)
        end
    elseif self._type == "PickUp" then
        local pickUpPos = previewContext:GetPickUpPos()
        local ghostEntity = entitySvc:CreateGhost(pickUpPos, casterEntity, self._anim, self._prefab)
    elseif self._type == "PickUpRotate" then
        local pickUpPos = previewContext:GetPickUpPos()
        local ghostEntity = entitySvc:CreateGhost(pickUpPos, casterEntity, self._anim, self._prefab)
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            previewPickUpComponent:SetRotateGhost(ghostEntity)
            local reflectPos = previewPickUpComponent:GetReflectPos()
            if reflectPos then
                --旋转ghost朝向反射目标点
                ghostEntity:SetDirection(reflectPos - pickUpPos)
            end
        end
    elseif self._type == "TeleportTargetAroundNearestCaster" then
        self:_CalcTeleportTargetAroundNearestCaster(casterEntity, previewContext)
    end
end

function SkillPreviewPlayCreateCasterGhostInstruction:_CalcTeleportTargetAroundNearestCaster(
    casterEntity,
    previewContext)
    local world = casterEntity:GetOwnerWorld()

    local pickUpPos = previewContext:GetPickUpPos()
    --不能通过在点选位置找monster的方式，因为有黑拳赛
    local targetEntity = nil
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    --黑拳赛会替换成敌方队伍
    local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster(casterEntity)
    for _, monster in ipairs(monsterList) do
        local monsterGridPos = monster:GetGridPosition()
        local bodyArea = monster:BodyArea():GetArea()
        for i, area in ipairs(bodyArea) do
            local posWork = monsterGridPos + area
            if posWork == pickUpPos then
                targetEntity = monster
                break
            end
        end
    end

    if not targetEntity then
        return
    end

    --用 Teleport.TargetAroundNearestCaster = 26, --目标周围，距离施法者(单格)最近的格子。优先十字，再一圈内的X位置。一圈都没有再扩大一圈的十字
    ---@type SkillEffectCalc_Teleport
    local SkillEffectCalc_Teleport = SkillEffectCalc_Teleport:New(world)
    local posNew = SkillEffectCalc_Teleport:_CalcTargetAroundNearestCaster(casterEntity, targetEntity:GetID())

    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")
    local ghostEntity = entitySvc:CreateGhost(posNew, casterEntity, self._anim, self._prefab)
end
