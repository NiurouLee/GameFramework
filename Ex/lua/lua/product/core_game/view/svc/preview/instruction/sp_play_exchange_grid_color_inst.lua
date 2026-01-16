require("sp_base_inst")
_class("SkillPreviewPlayExchangeGridColorInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayExchangeGridColorInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayExchangeGridColorInstruction = SkillPreviewPlayExchangeGridColorInstruction

function SkillPreviewPlayExchangeGridColorInstruction:Constructor(params)
    self._effectID = tonumber(params["EffectID"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayExchangeGridColorInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    ----@type  PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local allPickUpGrid = previewPickUpComponent:GetAllValidPickUpGridPos()
    local pickUpCount = previewPickUpComponent:GetAllValidPickUpGridPosCount()
    if pickUpCount == 1 then
        previewActiveSkillService:DoConvert({allPickUpGrid[1]}, "Normal", "Dark")
    elseif pickUpCount == 2 then
        local gridType1 = utilDataSvc:GetPieceType(allPickUpGrid[1])
        local gridType2 = utilDataSvc:GetPieceType(allPickUpGrid[2])
        previewActiveSkillService:DoConvertElement(TT, {allPickUpGrid[1]}, gridType2, casterEntity)
        previewActiveSkillService:DoConvertElement(TT, {allPickUpGrid[2]}, gridType1, casterEntity)
    else
        Log.fatal("NoPickUpGrid")
    end
end
