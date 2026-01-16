require("ui_side_enter_item_fixed_time")

---@class UIActivitySummonGiftSideEnter:UISideEnterItem_FixedTime
_class("UIActivitySummonGiftSideEnter", UISideEnterItem_FixedTime)
UIActivitySummonGiftSideEnter = UIActivitySummonGiftSideEnter

function UIActivitySummonGiftSideEnter:OnShow()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._Refresh)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnCampaignComponentStepChange)
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._OnCampaignClose)
end

function UIActivitySummonGiftSideEnter:OnHide()
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._Refresh)
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnCampaignComponentStepChange)
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._OnCampaignClose)
end

function UIActivitySummonGiftSideEnter:_OnCampaignComponentStepChange(id)
    if id == -1 then
        self:_CheckPoint()
    end
end

function UIActivitySummonGiftSideEnter:_OnCampaignClose(id)
    if id == -1 then
        local isOpen = self:_CheckOpen()
        if not isOpen then
            self._setShowCallback(false)
        end
    end
end

---------------------------------------------------------------------------------
--region virtual function

function UIActivitySummonGiftSideEnter:_CheckOpen(TT)
    -- 检查活动是否开启，决定是否显示
    local bg, ed = self._btnCfg.BeginTime, self._btnCfg.EndTime
    local isOpen = UISideEnterItem_FixedTime.CheckOpen(bg, ed)

    -- 检查解锁
    local roleModule = GameGlobal.GetModule(RoleModule)
    local isUnlock = roleModule:CheckModuleUnlock(GameModuleID.MD_Gamble)

    if isOpen and isUnlock then
        ---@type GambleModule
        local gambleModule = GameGlobal.GetModule(GambleModule)
        local ack = gambleModule:ApplyAllPoolInfo(TT)
    end

    return isOpen and isUnlock
end

function UIActivitySummonGiftSideEnter:_CalcRed()
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    local red = gambleModule:HasFreeDraw_Multi()
    return red
end

--endregion
