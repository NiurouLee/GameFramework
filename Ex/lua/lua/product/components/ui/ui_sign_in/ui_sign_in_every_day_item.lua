--[[
    签到每一天item
    ]]
---@class UISignInEveryDayItem:UICustomWidget
_class("UISignInEveryDayItem", UICustomWidget)
UISignInEveryDayItem = UISignInEveryDayItem

function UISignInEveryDayItem:OnShow(uiParam)
    self:GetComponents()
end

function UISignInEveryDayItem:GetComponents()
    self._icon = self:GetUIComponent("RawImageLoader", "icon")
    self._iconImg = self:GetUIComponent("RawImage", "icon")
    self._count = self:GetUIComponent("UILocalizationText", "count")
    self._makeUp = self:GetGameObject("makeUp")
    self._got = self:GetGameObject("got")
    self._dayText = self:GetUIComponent("UILocalizationText", "dayText")
    self._good = self:GetGameObject("good")
    self._select = self:GetGameObject("select")

    self._dataRoot = self:GetGameObject("dataRoot")
    self._bgRoot = self:GetGameObject("bgRoot")

    self._getting = self:GetGameObject("getting")
    self._getting:SetActive(false)

    self._anim = self:GetUIComponent("Animation", "UISignInEveryDayItem")

    self._bg = self:GetUIComponent("Image", "bg")

    self._actBox = self:GetGameObject("actBox")
end
--
---@param data UISignInAwardData
function UISignInEveryDayItem:SetData(data, sp1, sp2, currentDay, signInCallback, normalCallback, makeUpCallback, checkActBoxCb)
    self._data = data
    self._currentDay = currentDay
    self._normalCallback = normalCallback
    self._makeUpCallback = makeUpCallback
    self._signInCallback = signInCallback
    self._checkActBoxCb = checkActBoxCb
    self._sp1 = sp1
    self._sp2 = sp2
    self:_OnValue()
end

--刷新
---@param data UISignInAwardData
function UISignInEveryDayItem:Flush(data)
    self._data = data

    self:_OnValue()
end

---补签动画
---@param data UISignInAwardData
function UISignInEveryDayItem:MakeUpAnim()
    --动画在这播
end

function UISignInEveryDayItem:ShowGetting(show)
    self._getting:SetActive(show)
end

function UISignInEveryDayItem:PlayAnim()
    -- 签到动画
    self._anim:Play("uieff_SignIn_EverydayItem_Get")
end

function UISignInEveryDayItem:_OnValue()
    self._dataRoot:SetActive(self._data ~= nil)
    self._bgRoot:SetActive(self._data == nil)

    if self._data == nil then
        return
    end
    self._good:SetActive(self._data.Good)

    self._select:SetActive(self._currentDay == self._data.Day)

    local award = self._data.Items

    local cfg_item = Cfg.cfg_item[award.assetid]
    if not cfg_item then
        Log.fatal("###[UISignInEveryDayItem] cfg_item is nil ! id --> ", award.assetid)
        return
    end
    local icon = cfg_item.Icon
    self._icon:LoadImage(icon)

    self._count:SetText(award.count)

    self._makeUp:SetActive(self._data.CanMakeUp)

    self._got:SetActive(self._data.ItemGot)

    self._dayText:SetText(self._data.Day)

    local alpha = 1
    if self._data.ItemGot then
        alpha = 0.5
    end
    self._iconImg.color = Color(1, 1, 1, alpha)

    if self._currentDay == self._data.Day then
        self._dayText.color = Color(247 / 255, 247 / 255, 247 / 255, 1)
        self._bg.sprite = self._sp1
    else
        if self._data.ItemGot then
            self._bg.sprite = self._sp2

            self._dayText.color = Color(47 / 255, 47 / 255, 47 / 255, 1)
        else
            self._bg.sprite = self._sp1

            self._dayText.color = Color(140 / 255, 140 / 255, 140 / 255, 1)
        end
    end

    local startTime,endTime = self._checkActBoxCb(self._data.Day)
    if startTime then
        self._actBox:SetActive(true)
    else
        self._actBox:SetActive(false)
    end
end

function UISignInEveryDayItem:bgOnClick(go)
    local normal = true
    if self._currentDay == self._data.Day then
        if not self._data.ItemGot then
            self._signInCallback(self._data.Day)
            normal = false
        end
    elseif self._currentDay > self._data.Day then
    else
        if not self._data.ItemGot then
            if self._data.CanMakeUp then
                if self._makeUpCallback then
                    self._makeUpCallback(self._data.Day)
                    normal = false
                end
            end
        end
    end

    if normal then
        if self._normalCallback then
            local tr = go.transform
            local pos = tr.position
            local award = self._data.Items

            self._normalCallback(award.assetid, pos)
        end
    end
end
