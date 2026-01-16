require("base_ins_r")
---选卡模块 光灵头像添加卡牌buff图标
---@class PlayUIAddFeatureCardBuffInstruction: BaseInstruction
_class("PlayUIAddFeatureCardBuffInstruction", BaseInstruction)
PlayUIAddFeatureCardBuffInstruction = PlayUIAddFeatureCardBuffInstruction

function PlayUIAddFeatureCardBuffInstruction:Constructor(paramList)
    self._toTeamLeader = paramList["toTeamLeader"]
    self._toTeamTail = paramList["toTeamTail"]
    self._cardBuffType = tonumber(paramList["cardBuffType"])
    self._waitTime = tonumber(paramList["waitTime"]) or 3500
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayUIAddFeatureCardBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
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
    world:EventDispatcher():Dispatch(GameEventType.FeaturePetUIAddCardBuff, playerPstid, self._cardBuffType)
    YIELD(TT, self._waitTime)
end
