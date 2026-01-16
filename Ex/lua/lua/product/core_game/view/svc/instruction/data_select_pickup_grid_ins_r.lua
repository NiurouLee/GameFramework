require("base_ins_r")
---选择一个选中的格子
---@class DataSelectPickupGridInstruction: BaseInstruction
_class("DataSelectPickupGridInstruction", BaseInstruction)
DataSelectPickupGridInstruction = DataSelectPickupGridInstruction

function DataSelectPickupGridInstruction:Constructor(paramList)
    self._gridIndex = tonumber(paramList["gridIndex"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function DataSelectPickupGridInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    --local skillViewID = self:GetSkillViewID(casterEntity)
    local pickUpType = self:_GetPickUpType(casterEntity)

    ---@type RenderPickUpComponent
    local renderPickUpComponent = casterEntity:RenderPickUpComponent()
    ---@type Vector2[]
    local scopeGridList = renderPickUpComponent:GetAllValidPickUpGridPos()
    phaseContext:SetCurGridPos(scopeGridList[self._gridIndex])
end

function DataSelectPickupGridInstruction:_GetPickUpType(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)

    return skillConfigData:GetSkillPickType()
end
