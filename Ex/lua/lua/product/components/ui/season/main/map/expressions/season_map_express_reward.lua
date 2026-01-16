---@class SeasonMapExpressReward:SeasonMapExpressBase
_class("SeasonMapExpressReward", SeasonMapExpressBase)
SeasonMapExpressReward = SeasonMapExpressReward

function SeasonMapExpressReward:Constructor(cfg, eventPoint)
    self._content = self._cfg.Reward
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    self._rewards = {}
    self._delayShow = false
    self._time = 0
end

function SeasonMapExpressReward:Update(deltaTime)
    if self._state == SeasonExpressState.Playing then
        if self._delayShow then
            self._time = self._time - deltaTime
            if self._time <= 0 then
                self._delayShow = false
                self._seasonManager:UnLock("reward")
                UISeasonHelper.ShowUIGetRewards(self._rewards)
            end
        end
    end
end

function SeasonMapExpressReward:Dispose()
end

--播放表现内容
function SeasonMapExpressReward:Play(param)
    SeasonMapExpressReward.super.Play(self, param)
    if self._content then
        table.clear(self._rewards)
        for _, value in pairs(self._content) do
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = value[1]
            roleAsset.count = value[2]
            table.insert(self._rewards, roleAsset)
        end
        self._time = 0
        ---@type UISeasonMain
        local controller = GameGlobal.UIStateManager():GetController("UISeasonMain")
        if controller then
            local playing, time = controller:IsPlayAnimation()
            if playing then
                self._time = time * 1000
            end
        end
        self:_AddListener()
        self._delayShow = self._time > 0
        self._state = SeasonExpressState.Playing
        if self._delayShow then
            self._seasonManager:Lock("reward")
        else
            UISeasonHelper.ShowUIGetRewards(self._rewards)
        end
    end
end

function SeasonMapExpressReward:_AddListener()
    self._callBack = GameHelper:GetInstance():CreateCallback(self._OnCallBack, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnUIGetItemCloseInQuest, self._callBack)
end

function SeasonMapExpressReward:_OnCallBack()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnUIGetItemCloseInQuest, self._callBack)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.SeasonRewardShowEnd)
    self._state = SeasonExpressState.Over
    self:_Next()
end