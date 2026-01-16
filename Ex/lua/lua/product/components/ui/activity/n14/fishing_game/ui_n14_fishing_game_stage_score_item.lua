---@class UIN14FishingScoreItem : UICustomWidget
_class("UIN14FishingScoreItem", UICustomWidget)
UIN14FishingScoreItem = UIN14FishingScoreItem


function UIN14FishingScoreItem:Constructor()
    self._rewards = nil
end
function UIN14FishingScoreItem:OnShow(uiParams)
    self:InitWidget()
end
function UIN14FishingScoreItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.score = self:GetUIComponent("UILocalizationText", "score")
    ---@type UnityEngine.UI.Image
    self._receiveBtn = self:GetUIComponent("Image", "receiveBtn")
    self._reward = self:GetUIComponent("UISelectObjectPath", "Reward")
    self._scoreTypeText = self:GetUIComponent("UILocalizationText" , "scoreTypeText")
    self._scoreOutLine = self:GetUIComponent("Outline" , "scoreTypeText")
    self._atlas = self:GetAsset("UIN14FishingGame.spriteatlas", LoadType.SpriteAtlas)
    self._redPoint = self:GetGameObject("RedPoint")
    self._receiveBtnGo =  self:GetGameObject("uieff_receiveBtn")
    --generated end--
end
function UIN14FishingScoreItem:receiveBtnOnClick()
    if self.rewardState == FishingGameRewardState.NotReceive then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN14FishingGameRewardItemReceived, self.socreType)
    end
end

function UIN14FishingScoreItem:RefreshRewards(scoretype , mission_info , cfg)
    self.socreType = scoretype
    local rewards
    self._current_stage_cfg = cfg
    if scoretype == ScoreType.B then
        rewards = self._current_stage_cfg.ScoreBReward
        self.score.text = cfg.Score[1]
        self._scoreTypeText.text = "B"
        self._scoreOutLine.effectColor = Color(61/255 , 221/255 , 255/255)
    elseif scoretype == ScoreType.A then
        rewards = self._current_stage_cfg.ScoreAReward
        self.score.text = cfg.Score[2]
        self._scoreTypeText.text = "A"
        self._scoreOutLine.effectColor = Color(255/255 , 125/255 , 61/255)
    elseif scoretype == ScoreType.S then
        rewards = self._current_stage_cfg.ScoreSReward
        self.score.text = cfg.Score[3]
        self._scoreTypeText.text = "S"
        self._scoreOutLine.effectColor = Color(255/255 , 255/255 , 61/255)
    end
    local count = table.count(rewards)
        if count > 0 then
            self._reward:SpawnObjects("UIN14FishingGameRewardItem", count)
            self._rewards = self._reward:GetAllSpawnList()
            for i = 1, #self._rewards do
                self._rewards[i]:SetData(
                    rewards[i],
                    scoretype,
                    mission_info
                )
            end
        end
    self:_ReceiveRewardBtnState(mission_info , scoretype)
end

function UIN14FishingScoreItem:_ReceiveRewardBtnState(mission_info, scoretype)
    self._redPoint:SetActive(false)
    self.rewardState = FishingGameRewardState.NotReach
    if mission_info.mission_grade < scoretype then
        self.rewardState = FishingGameRewardState.NotReach
    else
        if mission_info.reward_mask & scoretype == 0 then
            self.rewardState = FishingGameRewardState.NotReceive
        else
            self.rewardState = FishingGameRewardState.HasReceive
        end
    end
    if self.rewardState == FishingGameRewardState.NotReach then
        self._receiveBtn.sprite = self._atlas:GetSprite("n14_fish_btn_receive1")
    elseif self.rewardState == FishingGameRewardState.HasReceive then
        self._receiveBtn.sprite = self._atlas:GetSprite("pass_jiangli_icon3")
    elseif self.rewardState == FishingGameRewardState.NotReceive then
        self._receiveBtn.sprite = self._atlas:GetSprite("n14_fish_btn_receive2")
        self._redPoint:SetActive(true)
    end
    self._receiveBtnGo:SetActive(self.rewardState == FishingGameRewardState.NotReceive)
end

function UIN14FishingScoreItem:_ShowRewardTips(id, pos)
    self._tips:SetData(id, pos)
end



