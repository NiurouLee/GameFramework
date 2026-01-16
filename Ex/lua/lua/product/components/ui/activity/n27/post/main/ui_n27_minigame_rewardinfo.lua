--
---@class UIN27MiniGameRewardInfo : UICustomWidget
_class("UIN27MiniGameRewardInfo", UICustomWidget)
UIN27MiniGameRewardInfo = UIN27MiniGameRewardInfo

---@class RewardState
local RewardState =
{
    HadReceive = 1, 
    NotReceive = 2,
    NotReach = 3
}
_enum("RewardState", RewardState)

function UIN27MiniGameRewardInfo:Constructor()
    self._rewards = nil
end
function UIN27MiniGameRewardInfo:OnShow(uiParams)
    self._bgState = 
    {
        [1] = "n27_yz_xxg_btndi05",
        [2] = "n27_yz_xxg_btndi04",
        [3] = "n27_yz_xxg_btndi03",
    }

    self.stringColor = 
    {
        [1] = Color(78 / 255, 72 / 255, 70 / 255),
        [2] = Color(250 / 255, 178 / 255, 54 / 255),
    }
    self:InitWidget()
end
function UIN27MiniGameRewardInfo:InitWidget()
    --generated--
    ---@type UILocalizationText
    self._info = self:GetUIComponent("UILocalizationText", "info")
    self._num = self:GetUIComponent("UILocalizationText", "num")
    ---@type UnityEngine.UI.Image
    self._stateBg = self:GetUIComponent("Image", "bg")
    self._reward = self:GetUIComponent("UISelectObjectPath", "Reward")
    self._redPoint = self:GetGameObject("RedPoint")
    self._mask = self:GetGameObject( "mask")
    self._atlas = self:GetAsset("UIN27PostStation.spriteatlas", LoadType.SpriteAtlas)
    self._animation = self:GetUIComponent("Animation","anim")
    self._anima = self:GetGameObject( "anim")
    --generated end--
end

function UIN27MiniGameRewardInfo:PlayAni()
    local aniIn = "uieff_UIN27MiniGameRewardInfo_in"
    self._anima:SetActive(true)
    self._animation:Play(aniIn)
end 

function UIN27MiniGameRewardInfo:ReceiveBtnOnClick()
    if self.rewardState == RewardState.NotReceive then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN27MinigameRewardItemReceived, self._targetId)
    end
end

function UIN27MiniGameRewardInfo:SetData(targetId , mission_info,cfg)
    local rewards
    self._targetId = targetId
    local targetcfg  = Cfg.cfg_component_post_station_game_mission_target{ ID = targetId}
    rewards = targetcfg[1].Rewards
    local count = table.count(rewards)
    if count > 0 then
        self._reward:SpawnObjects("UIN27MiniGameRewardItem", count)
        self._rewards = self._reward:GetAllSpawnList()
        for i = 1, #self._rewards do
            self._rewards[i]:SetData(
                rewards[i],
                mission_info
            )
        end
    end
    
    self._info:SetText(StringTable.Get(targetcfg[1].Desc))
    self:_ReceiveRewardBtnState(mission_info)
end

function UIN27MiniGameRewardInfo:_ReceiveRewardBtnState(mission_info)
    self._redPoint:SetActive(false)
    self.rewardState = self:_CheckRewardState(mission_info)
    self._mask:SetActive(self.rewardState == RewardState.HadReceive)
    self._stateBg.sprite = self._atlas:GetSprite(self._bgState[self.rewardState])
    if self.rewardState == RewardState.NotReach then
        self._info.color = Color.New(78 / 255, 72 / 255, 70 / 255, 255/255)
    end
    if self.rewardState == RewardState.NotReceive then
        self._redPoint:SetActive(true)
    end
end

function UIN27MiniGameRewardInfo:_ShowRewardTips(id, pos)
    self._tips:SetData(id, pos)
end

function UIN27MiniGameRewardInfo:_CheckRewardState(missionInfo)
    self.rewardState = RewardState.NotReach
    if not missionInfo then 
        return  self.rewardState
    end 

    if missionInfo.can_get_target_list then
        for key, value in pairs(missionInfo.can_get_target_list) do
            if value == self._targetId then
                self.rewardState = RewardState.NotReceive
                break
            end 
        end
    end 

    if missionInfo.already_get_target_list then
        for key, value in pairs(missionInfo.already_get_target_list) do
            if value == self._targetId then
                self.rewardState = RewardState.HadReceive
                break
            end 
        end
    end 
    return self.rewardState 
end





