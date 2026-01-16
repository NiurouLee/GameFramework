---@class UIHomelandMainBtnsCampaignEnter:UICustomWidget
_class("UIHomelandMainBtnsCampaignEnter", UICustomWidget)
UIHomelandMainBtnsCampaignEnter = UIHomelandMainBtnsCampaignEnter

function UIHomelandMainBtnsCampaignEnter:OnShow()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._Refresh)
end

function UIHomelandMainBtnsCampaignEnter:OnHide()
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._Refresh)

    -- self._timeEvent = UIActivityHelper.CancelTimerEvent(self._timeEvent)
end

function UIHomelandMainBtnsCampaignEnter:SetData(root)
    self._infos = {}
    self._root_open = false
    self._pool_open = false

    self._root = root
    self:_SetRootOpen(false)

    self._pool = self:GetGameObject("_pool")
    self:_SetPoolOpen(false)

    self:_Start_Refresh()
end

--region data

function UIHomelandMainBtnsCampaignEnter:_Start_Refresh()
    self:StartTask(
        function(TT)
            self._infos = self:_GetInfos(TT)
            self:_SetEnterItems(self._infos)

            -- self._timeEvent = UIActivityHelper.StartTimerEvent(self._timeEvent,
            --     function()
            --         self:_SetEnterItems(self._infos)
            --     end
            -- )
        end
    )
end

function UIHomelandMainBtnsCampaignEnter:_Refresh()
    self:_SetNewAndReds()
end

function UIHomelandMainBtnsCampaignEnter:_GetInfos(TT)
    local tb = {}

    local cfgs = self:_GetCfgs()
    for _, v in ipairs(cfgs) do
        if v.Type == 1 then
            if self:_CheckOpen_Campaign(TT, v.CampaignType) then
                table.insert(tb, v)
            end
        elseif v.Type == 2 then
            if self:_CheckOpen_CampaignComponent(TT, v.CampaignType, v.ComponentID) then
                table.insert(tb, v)
            end
        elseif v.Type == 3 then
            if self:_CheckOpen_Custom(v.TimeStart, v.TimeStop) then
                table.insert(tb, v)
            end
        end
    end
    return tb
end

function UIHomelandMainBtnsCampaignEnter:_GetCfgs()
    local tb = {}
    local cfgs = Cfg.cfg_homeland_enter {}
    for _, v in pairs(cfgs) do
        if v.IsActive then
            table.insert(tb, v)
        end
    end
    return tb
end

function UIHomelandMainBtnsCampaignEnter:_CheckOpen_Campaign(TT, campaignType)
    ---@type UIActivityCampaign
    local campaign = self:_LoadCampaign(TT, campaignType)
    if not campaign:CheckCampaignOpen() then
        return false
    end
    return true
end

function UIHomelandMainBtnsCampaignEnter:_CheckOpen_CampaignComponent(TT, campaignType, componentId)
    ---@type UIActivityCampaign
    local campaign = self:_LoadCampaign(TT, campaignType)
    if not campaign:CheckCampaignOpen() then
        return false
    end
    if componentId and not campaign:CheckComponentOpen(componentId) then
        return false
    end
    return true
end

function UIHomelandMainBtnsCampaignEnter:_CheckOpen_Custom(start, stop)
    --- @type SvrTimeModule
    local svrTimeModule = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)

    --- @type LoginModule
    local loginModule = GameGlobal.GetModule(LoginModule)
    local beginTime = loginModule:GetTimeStampByTimeStr(beginTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
    local endTime = loginModule:GetTimeStampByTimeStr(endTime, Enum_DateTimeZoneType.E_ZoneType_GMT)

    if beginTime <= curTime and curTime < endTime then
        return true
    end
    return false
end

--endregion

--region campaign

-- 加载活动信息
function UIHomelandMainBtnsCampaignEnter:_LoadCampaign(TT, campaignType)
    local res = AsyncRequestRes:New()

    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    campaign:LoadCampaignInfo(TT, res, campaignType)

    return campaign
end

--endregion

--region UI

function UIHomelandMainBtnsCampaignEnter:_SetRootOpen(show)
    show = (#self._infos > 0) and show or false
    self._root_open = show
    self._root:SetActive(show)
end

function UIHomelandMainBtnsCampaignEnter:_SetPoolOpen(show)
    show = (#self._infos > 0) and show or false
    show = (self._root_open) and show or false
    self._pool_open = show
    self._pool:SetActive(show)
end

function UIHomelandMainBtnsCampaignEnter:_SetEnterItems(infos)
    local objs = UIWidgetHelper.SpawnObjects(self, "_pool", "UIHomelandMainBtnsCampaignItem", #infos)
    for i, v in ipairs(objs) do
        ---@type UIActivityCampaign
        local campaign = UIActivityCampaign:New()
        campaign:LoadCampaignInfo_Local(infos[i].CampaignType)
        v:SetData(campaign, infos[i])
    end
    self:_SetRootOpen(true)
    self:_SetPoolOpen(self._pool_open)

    self._objs = objs
    self:_SetNewAndReds()
end

function UIHomelandMainBtnsCampaignEnter:_SetNewAndReds()
    if not self._objs then
        return
    end

    local new = 0
    local red = 0
    for i, v in ipairs(self._objs) do
        local n, r = v:SetNewAndReds()
        new = new + n
        red = red + r
    end

    UIWidgetHelper.SetNewAndReds(self, new, red, "_new", nil, "_redCount", "_redCountTxt")
end

--endregion

--region Event

function UIHomelandMainBtnsCampaignEnter:BtnOnClick(go)
    self:_SetPoolOpen(not self._pool_open)
end

--endregion
