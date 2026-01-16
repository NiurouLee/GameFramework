require("sp_base_inst")
_class("SkillPreviewPlayRotateCasterGhostInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayRotateCasterGhostInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayRotateCasterGhostInstruction = SkillPreviewPlayRotateCasterGhostInstruction

function SkillPreviewPlayRotateCasterGhostInstruction:Constructor(params)
    self.DirCount = tonumber(params.DirCount) or 2
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayRotateCasterGhostInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = casterEntity:GetOwnerWorld()
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    --找到ghost
    ---@type Entity
    local ghost = previewPickUpComponent:GetRotateGhost()

    --当前的反射面方向
    local curDir = previewPickUpComponent:GetReflectDir()
    --下个反射面方向
    local nxtDir = ReflectDirectionType.Heng
    if not curDir then
        nxtDir = ReflectDirectionType.Heng
    elseif self.DirCount == 2 then
        if curDir == ReflectDirectionType.Heng then
            nxtDir = ReflectDirectionType.Shu
        elseif curDir == ReflectDirectionType.Shu then
            nxtDir = ReflectDirectionType.Heng
        end
    elseif self.DirCount == 4 then
        if curDir == ReflectDirectionType.Heng then
            nxtDir = ReflectDirectionType.Na
        elseif curDir == ReflectDirectionType.Na then
            nxtDir = ReflectDirectionType.Shu
        elseif curDir == ReflectDirectionType.Shu then
            nxtDir = ReflectDirectionType.Pie
        elseif curDir == ReflectDirectionType.Pie then
            nxtDir = ReflectDirectionType.Heng
        end
    end

    local casterPos = casterEntity:GetGridPosition()
    local centerPos = previewContext:GetPickUpPos()
    local tarPos = CalcReflectPos(casterPos, centerPos, nxtDir)
    --旋转ghost朝向反射目标点
    ghost:SetDirection(tarPos - centerPos)
    --记录反射面的方向
    previewPickUpComponent:SetReflectDir(nxtDir)
    previewPickUpComponent:SetReflectPos(tarPos)
    --重新计算技能范围
    local skillPreviewConfigData = previewContext:GetConfigData()
    ---@type SkillPreviewScopeParam
    local scopeParam = skillPreviewConfigData:GetPreviewScopeParam()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    local scopeResult = previewActiveSkillService:CalcScopeResult(scopeParam, casterEntity)
    previewContext:SetScopeResult(scopeResult:GetAttackRange())
    ---重新计算技能目标
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, scopeParam:GetScopeTargetType(), scopeResult)
    previewContext:SetTargetEntityIDList(targetIDList)
end
