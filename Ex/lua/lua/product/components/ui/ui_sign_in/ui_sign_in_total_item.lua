--[[
    累计每一条item
]]
---@class UISignInTotalItem:UICustomWidget
_class("UISignInTotalItem", UICustomWidget)
UISignInTotalItem = UISignInTotalItem

function UISignInTotalItem:OnShow(uiParam)
    self:GetComponents()
    self:AttachEvent(GameEventType.OnTotalAwardGot, self.OnGetTotalAward)
end

---@param data UITotalAwardData
function UISignInTotalItem:SetData(data, currentTotalDay, normalCallback, getAwardCallback)
    self._data = data
    self._currentTotalDay = currentTotalDay
    self._normalCallback = normalCallback
    self._getAwardCallback = getAwardCallback
    self:_OnValue()
end

--刷新
function UISignInTotalItem:OnGetTotalAward(days, data)
    if self._data.DayCount == days then
        self._data = data
        self:_OnValue()
    end
end

function UISignInTotalItem:GetComponents()
    self._awardPool = self:GetUIComponent("UISelectObjectPath", "awardPool")
    self._dayCount = self:GetUIComponent("UILocalizationText", "dayCount")
    self._dayTips = self:GetUIComponent("UILocalizationText", "dayTips")

    self._got = self:GetGameObject("got")
    self._get = self:GetGameObject("get")
    self._not_finish = self:GetGameObject("not_finish")
end
function UISignInTotalItem:_OnValue()
    local dayCount = self._data.DayCount
    self._dayCount:SetText(dayCount)
    self._dayTips:SetText(StringTable.Get("str_sign_in_total_day_count_tips", dayCount))

    local getState = 0
    if self._data.Got then
        getState = 3
    else
        if self._currentTotalDay < self._data.DayCount then
            getState = 1
        else
            getState = 2
        end
    end
    self._got:SetActive(getState == 3)
    self._get:SetActive(getState == 2)
    self._not_finish:SetActive(getState == 1)

    local awards = self._data.Items
    self._awardPool:SpawnObjects("UISignInTotalAwardsItem", #awards)
    ---@type UISignInTotalAwardsItem[]
    local items = self._awardPool:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetData(
            i,
            awards[i],
            function(matid, pos)
                self._normalCallback(matid, pos)
            end,
            false
        )
    end
end

function UISignInTotalItem:getOnClick(go)
    if self._getAwardCallback then
        self._getAwardCallback(self._data.DayCount)
    end
end
