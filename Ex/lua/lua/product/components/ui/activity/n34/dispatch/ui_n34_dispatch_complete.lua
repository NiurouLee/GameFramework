---@class UIN34DispatchComplete:UIController
_class("UIN34DispatchComplete", UIController)
UIN34DispatchComplete = UIN34DispatchComplete

function UIN34DispatchComplete:Constructor()
end

function UIN34DispatchComplete:LoadDataOnEnter(TT, res, uiParams)
    self._archId = uiParams[1]
end

function UIN34DispatchComplete:OnShow(uiParams)
    self:UIWidget()
    self:CreateRewards()
    self:FlushRewards()
end

function UIN34DispatchComplete:OnHide()
end

function UIN34DispatchComplete:BtnAnywhereOnClick(go)
    self:CloseDialog()
end

function UIN34DispatchComplete:OnShowItemInfo(reward, go)
    local deltaPosition = go.transform.position - self._safeArea.transform.position
    self:ShowDialog("UICommonItemInfo", reward, deltaPosition)
end

function UIN34DispatchComplete:UIWidget()
    self._uiWidget = self:GetUIComponent("RectTransform", "uiWidget")
    self._btnAnywhere = self:GetUIComponent("RectTransform", "btnAnywhere")
    self._rewardContent = self:GetUIComponent("UISelectObjectPath", "rewardContent")
    self._safeArea = self:GetUIComponent("RectTransform", "safeArea")
end

function UIN34DispatchComplete:CreateRewards()
    local cfg = Cfg.cfg_component_dispatch_arch[self._archId]

    self._rewards = {}
    for k, v in pairs(cfg.Rewards) do
        if #v >= 2 then
            local asset = RoleAsset:New()
            asset.assetid = v[1]
            asset.count = v[2]
            table.insert(self._rewards, asset)
        end
    end

    local assetCount = #self._rewards
    self._widgetRewards = self._rewardContent:SpawnObjects("UIN34DispatchReward", assetCount)
end

function UIN34DispatchComplete:FlushRewards()
    for k, v in pairs(self._rewards) do
        local uiWidget = self._widgetRewards[k]
        uiWidget:SetData(v)
    end
end


---@class UIN34DispatchReward:UICustomWidget
_class("UIN34DispatchReward", UICustomWidget)
UIN34DispatchReward = UIN34DispatchReward

function UIN34DispatchReward:Constructor()

end

function UIN34DispatchReward:OnShow()
    self._iconLoader = self:GetUIComponent("RawImageLoader", "imgIcon")
    self._iconImg = self:GetUIComponent("RawImage", "imgIcon")
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._txtCount = self:GetUIComponent("UILocalizationText", "txtCount")
end

function UIN34DispatchReward:OnHide()

end

function UIN34DispatchReward:ButtonOnClick(go)
    self:RootUIOwner():OnShowItemInfo(self._reward, go)
end

function UIN34DispatchReward:SetData(data)
    self._reward = data

    local cfgItem = Cfg.cfg_item[self._reward.assetid]
    if cfgItem ~= nil then
        self._iconLoader:LoadImage(cfgItem.Icon)
    end

    self._txtName.gameObject:SetActive(false)
    self._txtCount:SetText(string.format("X %d", self._reward.count))
end


