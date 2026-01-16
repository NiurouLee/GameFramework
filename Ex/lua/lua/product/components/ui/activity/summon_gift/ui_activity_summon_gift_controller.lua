--- @class UIActivitySummonGiftController:UISideEnterCenterContentBase
_class("UIActivitySummonGiftController", UISideEnterCenterContentBase)
UIActivitySummonGiftController = UIActivitySummonGiftController

--region help
function UIActivitySummonGiftController:_SetRemainingTime(widgetName, descId, endTime, customTimeStr)
    ---@type UIActivityCommonRemainingTime
    local obj = UIWidgetHelper.SpawnObject(self, widgetName, "UIActivityCommonRemainingTime")

    if customTimeStr then
        obj:SetCustomTimeStr_Common_1()
    end
    -- obj:SetExtraRollingText()
    -- obj:SetExtraText("txtDesc", nil, extraId)
    obj:SetAdvanceText(descId)

    obj:SetData(
        endTime,
        nil,
        nil
    )
end

--endregion

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivitySummonGiftController:DoInit(params)
    local cfg = self:_GetCfg()
    local isOpen = cfg and UISideEnterItem_FixedTime.CheckOpen(cfg.BeginTime, cfg.EndTime)

    if not isOpen then
        --- @type CampaignModule
        local campaign_module = GameGlobal.GetModule(CampaignModule)
        -- campaign_module:ShowErrorToast(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED, true)
        campaign_module:CheckErrorCode(CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_CAMPAIGN_FINISHED, -1)
    end
end

--
function UIActivitySummonGiftController:DoShow(uiParams)
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    local red = gambleModule:HasFreeDraw_Multi()
    UIWidgetHelper.SetNewAndReds(self, 0, red, "", "_red")

    local cfg = self:_GetCfg()
    local loginModule = GameGlobal.GetModule(LoginModule)
    local endTime = loginModule:GetTimeStampByTimeStr(cfg.EndTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
    self:_SetRemainingTime("_timePool_Main", "", endTime)
end

function UIActivitySummonGiftController:_GetCfg()
    local cfgs = Cfg.cfg_main_side_enter {}
    for _, v in pairs(cfgs) do
        if v.MainUI == self:GetName() then
            return v
        end
    end
end

--
function UIActivitySummonGiftController:_GetPrizePoolId()
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    ---@type PrizePoolInfo[]
    local pools = gambleModule:GetPrizePools()
    for _, pool in ipairs(pools) do
        if pool.mul_remain_free_count > 0 then
            return pool.prize_pool_id
        end
    end
    return nil
end

--region Event Callback

--
function UIActivitySummonGiftController:GotoBtnOnClick(go)
    ---@type UIJumpModule
    local jumpModule = GameGlobal.GetModule(QuestModule).uiModule

    local jumpParams = self:_GetPrizePoolId()
    jumpModule:SetJumpUIData(UIJumpType.UI_JumpDraw, { jumpParams })
    jumpModule:Jump()
end

function UIActivitySummonGiftController:DoHide()
end

function UIActivitySummonGiftController:DoDestroy()
end

--
function UIActivitySummonGiftController:ShowBtnOnClick(go)
    self:CloseDialog()
end

--
function UIActivitySummonGiftController:CloseBtnOnClick(go)
    self:CloseDialog()
end

--endregion
