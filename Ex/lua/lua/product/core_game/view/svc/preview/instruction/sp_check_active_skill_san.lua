require("sp_base_inst")

_class("SkillPreviewCheckActiveSkillSanInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewCheckActiveSkillSanInstruction : SkillPreviewBaseInstruction
SkillPreviewCheckActiveSkillSanInstruction = SkillPreviewCheckActiveSkillSanInstruction

function SkillPreviewCheckActiveSkillSanInstruction:Constructor(params)
    self._skillID = tonumber(params.skillID)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewCheckActiveSkillSanInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    local resultCommon, _, commonReason = utilData:CheckActiveSkillCastCondition(casterEntity:PetPstID():GetPstID(), self._skillID)
    ---@type FeatureServiceRender
    local rsvcFeature = world:GetService("FeatureRender")
    local result, reason = rsvcFeature:IsActiveSkillCanCastInPreview(casterEntity, self._skillID, previewContext)

    local fin = resultCommon and result

    --报错提示部分和原先的逻辑要兼容
    local presentReason
    if (not resultCommon) or (not result) then
        presentReason = commonReason or reason
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleUIRefreshActiveSkillCastButtonState, fin, presentReason)
end
