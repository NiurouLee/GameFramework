--
---@class UIN24SpecialTaskSideEnter : UICustomWidget
_class("UIN24SpecialTaskSideEnter", UICustomWidget)
UIN24SpecialTaskSideEnter = UIN24SpecialTaskSideEnter

function UIN24SpecialTaskSideEnter:Constructor()
end

--初始化
function UIN24SpecialTaskSideEnter:OnShow(uiParams)
    self:_GetComponents()
end

--获取ui组件
function UIN24SpecialTaskSideEnter:_GetComponents()
    self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    self._red = self:GetGameObject("red")
    self._new = self:GetGameObject("new")
end

--设置数据
function UIN24SpecialTaskSideEnter:SetData()
end

--按钮点击
function UIN24SpecialTaskSideEnter:BtnOnClick(go)
    local open = self._campaign:CheckCampaignOpen()
    if not open then
        self.root:SetActive(open)
        self._setShowCallback(open)
        ToastManager.ShowToast(StringTable.Get("str_n24_specialtask_close"))
        return
    end
    self:ShowDialog("UIN24SpecialTask", 
    function ()
        local open = self._campaign:CheckCampaignOpen()
        if not open then
            self.root:SetActive(open)
            self._setShowCallback(open)
        else
            local showRedPoint = self._localProcess:GetRedPoint()
            self._red:SetActive(showRedPoint)
            self._setNewRedCallback(false, showRedPoint)
        end
    end)
end

function UIN24SpecialTaskSideEnter:OnSideEnterLoad(TT, setShowCallback, setNewRedCallback)
    self._setShowCallback = setShowCallback
    self._setNewRedCallback = setNewRedCallback
    self.root = self:GetGameObject()
    self:Lock("UIN24SpecialTaskSideEnter")
    local res = AsyncRequestRes:New()
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_SPECIAL,
        ECampaignSpecialComponentID.ECAMPAIGN_SPECIAL_QUEST
    )
    self._campaign:ReLoadCampaignInfo_Force(TT, res)
    self:UnLock("UIN24SpecialTaskSideEnter")
    if res and not res:GetSucc() then
        self.root:SetActive(false)
        self._setShowCallback(false)
        return
    end
    ---@type CCampaignSpecial
    self._localProcess = self._campaign:GetLocalProcess()
    ---@type CampaignQuestComponent
    self._questComponent = self._localProcess:GetComponent(ECampaignSpecialComponentID.ECAMPAIGN_SPECIAL_QUEST)
    self._questComponentInfo = self._questComponent:GetComponentInfo()
    if not self._questComponent:ComponentIsOpen() then
        self.root:SetActive(false)
        self._setShowCallback(false)
        return
    end
    self.root:SetActive(true)
    self._setShowCallback(true)
    local showRedPoint = self._localProcess:GetRedPoint()
    self._red:SetActive(showRedPoint)
    self._setNewRedCallback(false, showRedPoint)
end

-- 需要提供入口图片
---@return string
function UIN24SpecialTaskSideEnter:GetSideEnterRawImage()
    local cfg = Cfg.cfg_campaign[self._campaign._id]
    return cfg and cfg.SideEnterIcon
end