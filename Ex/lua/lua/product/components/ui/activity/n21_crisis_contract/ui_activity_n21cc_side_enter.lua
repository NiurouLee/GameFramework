---@class UIActivityN21CCSideEnter:UICustomWidget
_class("UIActivityN21CCSideEnter", UICustomWidget)
UIActivityN21CCSideEnter = UIActivityN21CCSideEnter

function UIActivityN21CCSideEnter:OnShow(uiParams)
    self:_AttachEvents()
end

function UIActivityN21CCSideEnter:OnHide()
    self:_DetachEvents()
end

---------------------------------------------------
-- 侧边栏独立入口，通过 UIMainLobbySideEnterLoader 加载
-- 需要在这里把数据加载好，计算出是否显示
-- 任何时候都需要使用 setShowCallback 设置入口开关
-- 当 new red 发生变化时，调用  setNewRedCallback
function UIActivityN21CCSideEnter:OnSideEnterLoad(TT, setShowCallback, setNewRedCallback)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    ---@type UIActivityN21CCConst
    self._activityConst = UIActivityN21CCConst:New()
    self._activityConst:LoadData(TT, res)
    self._setShowCallback = setShowCallback
    self._setNewRedCallback = setNewRedCallback

    -- 获取活动是否开启
    local isOpen = self._campaign:CheckCampaignOpen()

    -- 检查活动是否开启，决定是否显示
    if isOpen then
        self._setShowCallback(true)

        self:_CheckPoint()
    end
end

-- 需要提供入口图片
---@return string
function UIActivityN21CCSideEnter:GetSideEnterRawImage()
    local cfg = Cfg.cfg_campaign[self._campaign._id]
    return cfg and cfg.SideEnterIcon
end

---------------------------------------------------

-- 调用早于 OnSideEnterLoad
function UIActivityN21CCSideEnter:SetData(campaign, callback)
    ---@type UIActivityCampaign
    self._campaign = campaign
    self._callback = callback

    self:_SetBg()
end

function UIActivityN21CCSideEnter:_SetBg()
    local cfg = Cfg.cfg_campaign[self._campaign._id]
    local sideEnterIcon = cfg and cfg.SideEnterIcon
    UIWidgetHelper.SetRawImage(self, "bg", sideEnterIcon)
end

function UIActivityN21CCSideEnter:BtnOnClick()
    self._callback()
end

--region AttachEvent
--
function UIActivityN21CCSideEnter:_AttachEvents()
    self:AttachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._OnCampaignClose)
    self:AttachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:AttachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

--
function UIActivityN21CCSideEnter:_DetachEvents()
    self:DetachEvent(GameEventType.AfterUILayerChanged, self._OnAfterUILayerChanged)
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._OnCampaignClose)
    self:DetachEvent(GameEventType.CampaignComponentStepChange, self._OnComponentStepChange)
    self:DetachEvent(GameEventType.QuestUpdate, self._OnQuestUpdate)
end

--
function UIActivityN21CCSideEnter:_OnComponentStepChange(campaign_id, component_id, component_step)
    if self._campaign and self._campaign._id == campaign_id then
        self:_CheckPoint()
    end
end

--
function UIActivityN21CCSideEnter:_OnQuestUpdate()
    self:_CheckPoint()
end

--
function UIActivityN21CCSideEnter:_CheckPoint()
    local isShowNew = self._activityConst:IsShowEntryNew()
    local isShowRed = self._activityConst:IsShowEntryRed()
    local new = isShowNew and 1 or 0
    local red = isShowRed and 1 or 0
    UIWidgetHelper.SetNewAndReds(self, new, red, "new", "red")
    if self._setNewRedCallback then
        self._setNewRedCallback(new, red) -- 通知 Loader
    end
end

-- 界面变更
function UIActivityN21CCSideEnter:_OnAfterUILayerChanged()
    self:_CheckPoint()
end

-- 活动关闭
function UIActivityN21CCSideEnter:_OnCampaignClose(id)
    if self._campaign._id == id then
        self._setShowCallback(false)
    end
end

--endregion
