---@class UIS1ExchangeBtn:UICustomWidget
_class("UIS1ExchangeBtn", UICustomWidget)
UIS1ExchangeBtn = UIS1ExchangeBtn

function UIS1ExchangeBtn:OnShow()
    self._constBtnName = self:GetName() -- 通用按钮名字 LocalDB 用
    self:_AttachEvents()
end

function UIS1ExchangeBtn:OnHide()
    self:_DetachEvents()
end

function UIS1ExchangeBtn:SetData(seasonId, component, delay)
    self._seasonId = seasonId
    ---@type ExchangeItemComponent
    self._component = component

    local isOpen = component and component:ComponentIsOpen()

    self._state = isOpen and 1 or 2
    self:_SetState(self._state)

    self:_PlayAnim(delay)
    self:_Refresh()
end

function UIS1ExchangeBtn:_PlayAnim(delay, callback)
    if delay ~= nil then
        local animName, duration = "uieff_UIS1_ExchangeBtn", 600
        UIWidgetHelper.PlayAnimationInSequence(self, "_anim", nil, animName, delay, duration, callback, true)
    end
end

function UIS1ExchangeBtn:_Refresh()
    if self._component == nil then
        return
    end
    
    local id1, id2 = self._component:GetCostItemId(true), self._component:GetCostItemId(false)
    self:_SetIconText(id1, "_icon1", "_text1", "_text1s")
    self:_SetIconText(id2, "_icon2", "_text2", "_text2s")

    self:_CheckPoint()
end

function UIS1ExchangeBtn:_SetState(state)
    self:GetGameObject("_lock"):SetActive(state == 2)
    local alpha = (state == 2) and 0.5 or 1
    local obj = self:GetUIComponent("CanvasGroup", "_alphaGroup")
    obj.alpha = alpha
end

function UIS1ExchangeBtn:_SetIconText(itemId, widgetIcon, widgetText1, widgetText2)
    local atlasName = "UICommon.spriteatlas"
    local spriteName = "toptoon_" .. itemId

    UIWidgetHelper.SetImageSprite(self, widgetIcon, atlasName, spriteName)
    UIWidgetHelper.SetItemCount(self, itemId, widgetText1)
    UIWidgetHelper.SetItemCount(self, itemId, widgetText2)
end

--region CheckPoint

function UIS1ExchangeBtn:_CalcNew()
    -- local _debug = true
    -- if _debug then
    --     UISeasonLocalDBHelper.SeasonBtn_Delete(self._constBtnName, "New")
    -- end

    local isNew = not UISeasonLocalDBHelper.SeasonBtn_Has(self._constBtnName, "New")
    return isNew
end

function UIS1ExchangeBtn:_CalcRed()
    local isRed = self._component and self._component:HaveRedPoint()
    return isRed
end

function UIS1ExchangeBtn:_CheckPoint()
    local new = self:_CalcNew()
    local red = self:_CalcRed()
    UIWidgetHelper.SetNewAndReds(self, new, red, "_new", "_red")
end

--endregion

--region Event

function UIS1ExchangeBtn:BtnOnClick()
    Log.info("UIS1ExchangeBtn:BtnOnClick")
    
    ---@type SeasonModule
    local seasonModule = GameGlobal.GetModule(SeasonModule)
    if seasonModule:CheckSeasonClose_ShowClientError(self._seasonId) then
        return
    end

    if self._state == 2 then
        ToastManager.ShowToast(StringTable.Get("str_season_s1_main_btn_over"))
        return
    end

    UISeasonLocalDBHelper.SeasonBtn_Set(self._constBtnName, "New")
    self:_CheckPoint()

    UISeasonHelper.ShowCurSeasonExchange()
end

--endregion

--region AttachEvent

function UIS1ExchangeBtn:_AttachEvents()
    --注册体力值更新的回调
    self:AttachEvent(GameEventType.ItemCountChanged, self._Refresh)
end

function UIS1ExchangeBtn:_DetachEvents()
    self:DetachEvent(GameEventType.ItemCountChanged, self._Refresh)
end

--endregion