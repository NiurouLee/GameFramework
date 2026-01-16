require("sp_base_inst")
_class("SkillPreviewPlayPickColorAnimInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayPickColorAnimInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayPickColorAnimInstruction = SkillPreviewPlayPickColorAnimInstruction

function SkillPreviewPlayPickColorAnimInstruction:Constructor(params)
    self._anim = params.Anim
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayPickColorAnimInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    ---@type MainWorld
    self._world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    local allPickUpPos = previewPickUpComponent:GetAllValidPickUpGridPos()
    local pickUpPieceType = {}

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local pieceTypeList = {}
    for k, pos in pairs(allPickUpPos) do
        local pieceType = utilDataSvc:GetPieceType(pos)
        if not table.icontains(pieceTypeList, pieceType) then
            table.insert(pieceTypeList, pieceType)
        end
    end
    local gridList = utilDataSvc:GetPiecePosByType(pieceTypeList)
    previewActiveSkillService:DoConvert(gridList, self._anim, "Dark")
end
