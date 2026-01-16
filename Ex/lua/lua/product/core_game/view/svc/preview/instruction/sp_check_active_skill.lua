require("sp_base_inst")

_class("SkillPreviewCheckActiveSkillInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewCheckActiveSkillInstruction : SkillPreviewBaseInstruction
SkillPreviewCheckActiveSkillInstruction = SkillPreviewCheckActiveSkillInstruction

function SkillPreviewCheckActiveSkillInstruction:Constructor(params)
    self._skillID = tonumber(params.skillID)
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewCheckActiveSkillInstruction:DoInstruction(TT, casterEntity, previewContext)
    local world = previewContext:GetWorld()
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    ---@type Entity
	local renderBoardEntity = world:GetRenderBoardEntity()
	---@type PickUpTargetComponent
	local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local checkSkillID = self._skillID
    if not checkSkillID then
        checkSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    end
    local resultCommon, tmp, commonReason = utilData:CheckActiveSkillCastCondition(casterEntity:PetPstID():GetPstID(), checkSkillID)
    local fin = resultCommon

    --报错提示部分和原先的逻辑要兼容
    local presentReason
    if not resultCommon then
        presentReason = commonReason
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleUIRefreshActiveSkillCastButtonState, fin, presentReason)
end
