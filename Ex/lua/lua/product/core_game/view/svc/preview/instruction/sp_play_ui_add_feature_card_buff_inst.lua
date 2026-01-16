require("sp_base_inst")
---选卡模块 预览 光灵头像添加卡牌buff图标
_class("SkillPreviewPlayUIAddFeatureCardBuffInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayUIAddFeatureCardBuffInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayUIAddFeatureCardBuffInstruction = SkillPreviewPlayUIAddFeatureCardBuffInstruction

function SkillPreviewPlayUIAddFeatureCardBuffInstruction:Constructor(params)
	self._toTeamLeader = params["toTeamLeader"]
    self._toTeamTail = params["toTeamTail"]
    self._cardBuffType = tonumber(params["cardBuffType"])
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayUIAddFeatureCardBuffInstruction:DoInstruction(TT,casterEntity,previewContext)
	---@type MainWorld
	self._world = previewContext:GetWorld()
	---@type MainWorld
    local world = self._world
    local teamEntity = world:Player():GetCurrentTeamEntity()
    local playerPstid = 0
    if self._toTeamLeader then
        playerPstid = teamEntity:Team():GetTeamLeaderPetPstID()
    elseif self._toTeamTail then
        ---@type TeamComponent
        local cTeam = teamEntity:Team()
        local teamOrder = cTeam:GetTeamOrder()
        local finalIndex = #teamOrder
        playerPstid = teamOrder[finalIndex]
    end
    world:EventDispatcher():Dispatch(GameEventType.FeaturePetUIPreviewAddCardBuff, playerPstid, self._cardBuffType)
end