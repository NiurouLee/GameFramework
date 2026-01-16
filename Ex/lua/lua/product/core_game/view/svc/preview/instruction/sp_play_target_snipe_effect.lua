require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewPlayTargetSnipeEffectInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayTargetSnipeEffectInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayTargetSnipeEffectInstruction = SkillPreviewPlayTargetSnipeEffectInstruction
---构造
function SkillPreviewPlayTargetSnipeEffectInstruction:Constructor(params)
    --self._effectID = params["EffectID"]

end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayTargetSnipeEffectInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type  MainWorld
    local world = previewContext:GetWorld()
    local targetIDList = previewContext:GetTargetEntityIDList()
    targetIDList = table.unique(targetIDList)
    local effectEntityList = {}
    local effectSvc = world:GetService("Effect")
    ----@type RenderBattleService
    local renderBattleService = world:GetService("RenderBattle")
    local element = casterEntity:Element():GetPrimaryType()
    local previewIndex = previewContext:_GetPreviewIndex()
    for _, id in pairs(targetIDList) do
        local entity = world:GetEntityByID(id)
        if entity and entity:HasTeam() then
            entity = entity:GetTeamLeaderPetEntity()
        end
        local effectEntity = effectSvc:CreateEffect(BattleConst.ChainSkillSnipeEffectID, entity, true)
        renderBattleService:PlaySnipeEffectAnimation(effectEntity,element)
        table.insert(effectEntityList,effectEntity)
    end
    GameGlobal.TaskManager():CoreGameStartTask(self._PlaySnipeEffect,self,effectEntityList,element,world,previewIndex)
end
---刷新动画
---@param world MainWorld
function SkillPreviewPlayTargetSnipeEffectInstruction:_PlaySnipeEffect(TT,effectList,element,world,previewIndex)
    ----@type RenderBattleService
    local renderBattleService = world:GetService("RenderBattle")
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    while true do
        YIELD(TT,1000)

        local newPreviewIndex = previewActiveSkillService:GetPreviewIndex()
        if newPreviewIndex ~= previewIndex then
            return
        end

        for i, effectEntity in ipairs(effectList) do
            renderBattleService:PlaySnipeEffectAnimation(effectEntity,element)
            ---renderBattleService:PlayAnimation(effectEntity, {self._snipeEffectList[element]})
        end
    end
end