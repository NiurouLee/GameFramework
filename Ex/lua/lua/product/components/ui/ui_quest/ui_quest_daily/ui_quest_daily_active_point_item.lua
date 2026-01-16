---@class UIQuestDailyActivePointItem:UICustomWidget
_class("UIQuestDailyActivePointItem", UICustomWidget)
UIQuestDailyActivePointItem = UIQuestDailyActivePointItem

function UIQuestDailyActivePointItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIQuest.spriteatlas", LoadType.SpriteAtlas)
    self._module = GameGlobal.GetModule(QuestModule)
    if self._module == nil then
        Log.fatal("###[quest] error --> QuestModule is nil !")
    end
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:AttachEvent(GameEventType.RolePropertyChanged, self._OnValue)
end

function UIQuestDailyActivePointItem:SetData(index, points, currentPoint, posX, callback, refrenshCb)
    self:_GetComponents()

    self._index = index
    self._points = points
    self._point = self._points[self._index].VigPoint
    self._rewards = self._points[self._index].Reward
    self._state = 0
    self._currentPoint = currentPoint
    self._posX = posX
    self._callback = callback
    self._refrenshCb = refrenshCb

    self:_OnValue()
end

function UIQuestDailyActivePointItem:OnHide()
    self:DetachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)
    self:DetachEvent(GameEventType.RolePropertyChanged, self._OnValue)
end

function UIQuestDailyActivePointItem:_GetComponents()
    self._rect = self:GetUIComponent("RectTransform", "rect")

    self._img = self:GetUIComponent("Image", "img")

    self._pointTex = self:GetUIComponent("UILocalizationText", "pointTex")

    self._line = self:GetUIComponent("RectTransform", "line")
end

function UIQuestDailyActivePointItem:_OnValue()
    if not self._index then
        return
    end
    self._rect.anchoredPosition = Vector2(self._posX, 0)

    -- local width = 0
    -- if self._index == 1 then
    --     width = self._point * 6.6 + 250
    -- else
    --     local gaps = (self._point - self._points[self._index - 1].VigPoint)
    --     width = gaps * 6.6
    -- end
    -- self._line.sizeDelta = Vector2(width, 3)

    local get = self._module:IsGotVigorousReward(self._index)
    if get then
        self._state = 2
    else
        if self._currentPoint < self._point then
            self._state = 0
        else
            self._state = 1
        end
    end
    --活跃度的领取状态 0-未达到，1-未领取，2-已领取
    if self._state <= 0 then
        self._img.sprite = self._atlas:GetSprite("task_richang_icon4")
        self._pointTex.color = Color(91 / 255, 91 / 255, 91 / 255, 1)
    elseif self._state == 1 then
        self._img.sprite = self._atlas:GetSprite("task_richang_icon7")
        self._pointTex.color = Color(1, 1, 1, 1)
    elseif self._state == 2 then
        self._img.sprite = self._atlas:GetSprite("task_richang_icon6")
        self._pointTex.color = Color(1, 1, 1, 1)
    end

    self._pointTex:SetText(self._point)
end

function UIQuestDailyActivePointItem:GetActiveState()
    return (self._state == 1)
end

function UIQuestDailyActivePointItem:bgOnClick()
    --活跃度的领取状态 0-未达到，1-未领取，2-已领取
    if self._state == 0 then
        local cfg = Cfg.cfg_vigorous_reward[self._index]
        if cfg == nil then
            Log.fatal("[quest] error --> cfg_vigorous_reward is nil ! index --> " .. self._index)
            return
        end
        local rewards = {}
        for i = 1, table.count(cfg.Reward) do
            rewards[i] = {}
            rewards[i].assetid = cfg.Reward[i][1]
            rewards[i].count = cfg.Reward[i][2]
        end

        local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
        local loginModule = GameGlobal.GetModule(LoginModule)

        --检查是否在活动内
        local extraAward = cfg.ExtraReward
        if extraAward then
            local cfg_extras = Cfg.cfg_vigorous_extra_reward{}
            for i = 1, #extraAward do
                local extraAwardID = extraAward[i]
                local cfg_extra = cfg_extras[extraAwardID]
                --判断时间内
                local startTimeStr = cfg_extra.StartTime
                local endTimeStr = cfg_extra.EndTime
                local nowTime = svrTimeModule:GetServerTime()*0.001
                local startTime = loginModule:GetTimeStampByTimeStr(startTimeStr,Enum_DateTimeZoneType.E_ZoneType_ServerTimeZone)
                local endTime = loginModule:GetTimeStampByTimeStr(endTimeStr,Enum_DateTimeZoneType.E_ZoneType_ServerTimeZone)
                if nowTime >= startTime and nowTime < endTime then
                    local reward = cfg_extra.Reward
                    if reward then
                        for j = 1, #reward do
                            local key = #rewards+1
                            rewards[key] = {}
                            rewards[key].assetid = reward[j][1]
                            rewards[key].count = reward[j][2]
                        end
                    end
                end
            end
        end

        self:ShowDialog("UIQuestAwardsInfoController", rewards, "str_quest_base_active_awards")
    elseif self._state == 1 then
        if self._callback then
            self._callback(self._index)
        end
    elseif self._state == 2 then
        ToastManager.ShowToast(StringTable.Get("str_quest_base_dayli_tips_awards_got"))
    end
end
