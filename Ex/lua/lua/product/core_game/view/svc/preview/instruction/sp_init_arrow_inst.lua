require("sp_base_inst")
---范围内目标MaterialAnim
_class("SkillPreviewInitArrowInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewInitArrowInstruction: SkillPreviewBaseInstruction
SkillPreviewInitArrowInstruction = SkillPreviewInitArrowInstruction

function SkillPreviewInitArrowInstruction:Constructor(params)
    self._number = params["Number"]
    self._showOutGrid = false
    if params["ShowOutGrid"] and params["ShowOutGrid"] == "true" then
        self._showOutGrid = true
    end
    self._skillPreviewCenterType = tonumber(params["SkillPreviewCenterType"]) or 1 --显示箭头的中心，不写默认1队伍
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewInitArrowInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()

    local centerPos =casterEntity:GridLocation().Position
    if self._skillPreviewCenterType == SkillPreviewCenterType.PickUp then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        ---@type Vector2[]
        local scopeGridList = previewPickUpComponent:GetAllValidPickUpGridPos()
        centerPos = scopeGridList[1]
    end

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    if self._number == "4" then
        previewActiveSkillService:ShowFourPickUpArrow(self._showOutGrid, centerPos)
    elseif self._number == "8" then
        previewActiveSkillService:ShowEightPickUpArrow(self._showOutGrid, centerPos)
    end
end

---技能预览中心类型
--- @class SkillPreviewCenterType
local SkillPreviewCenterType = {
    Team = 1, ---队伍
    PickUp = 2, ---点选坐标
    MAX = 99
}
_enum("SkillPreviewCenterType", SkillPreviewCenterType)
