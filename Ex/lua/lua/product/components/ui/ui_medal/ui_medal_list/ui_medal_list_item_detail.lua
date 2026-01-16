--
---@class UIMedalListItemDetail : UICustomWidget
_class("UIMedalListItemDetail", UICustomWidget)
UIMedalListItemDetail = UIMedalListItemDetail
--初始化
function UIMedalListItemDetail:OnShow(uiParams)
    self:InitWidget()
    self._atlas = self:GetAsset("UIMedal.spriteatlas", LoadType.SpriteAtlas)
    self._disCoveryData = GameGlobal.GetModule(MissionModule):GetDiscoveryData()
end
--获取ui组件
function UIMedalListItemDetail:InitWidget()
    ---@type UnityEngine.UI.Image
    self.medalIcon = self:GetUIComponent("Image", "medalIcon")
    ---@type UILocalizationText
    self.medalName = self:GetUIComponent("UILocalizationText", "medalName")
    ---@type UnityEngine.GameObject
    self.noReceive = self:GetGameObject("noReceive")
    ---@type UILocalizationText
    self.txtProgressStatus = self:GetUIComponent("UILocalizationText", "txtProgressStatus")
    ---@type UILocalizationText
    self.txUnlockDesc = self:GetUIComponent("UILocalizationText", "txUnlockDesc")
    ---@type UILocalizationText
    self.txtProgressDetail = self:GetUIComponent("UILocalizationText", "txtProgressDetail")
    ---@type UnityEngine.RectTransform
    self.progressImageRt = self:GetUIComponent("RectTransform", "progressImage")
    ---@type UILocalizationText
    self.txtMedalDesc = self:GetUIComponent("UILocalizationText", "txtMedalDesc")
    ---@type UnityEngine.GameObject
    self.receiveIcon = self:GetGameObject("receiveIcon")
    ---@type UnityEngine.GameObject
    self.progress = self:GetGameObject("progress")
    ---@type UnityEngine.Animation
    self._ani = self:GetUIComponent("Animation", "_ani")
end

--设置数据
---@param itemData  UIMedalItemData
function UIMedalListItemDetail:SetData(itemData)
    local isRecevie = itemData:IsReceive()
    self.noReceive:SetActive(not isRecevie)
    self.receiveIcon:SetActive(isRecevie)
    self.progress:SetActive(false)
    local cfgMedal = itemData:GetTempl()
    local cfgItem = itemData:GetTemplateItem()
    self.medalIcon.sprite = self._atlas:GetSprite(cfgMedal.Icon)
    self.medalIcon:SetNativeSize()
    self.medalName:SetText(StringTable.Get(cfgItem.Name))
    self.txtMedalDesc:SetText(StringTable.Get(cfgItem.RpIntro))
    --txtProgressStatus
    if isRecevie then
        self.txtProgressStatus:SetText(StringTable.Get("str_medal_unlocked")) --已解锁
        self.txUnlockDesc:SetText(StringTable.Get(cfgMedal.GetPathDesc))
    else
        if itemData:IsFunctionLock() then
            self.txtProgressStatus:SetText(StringTable.Get("str_medal_lock")) --功能未解锁
            self.txUnlockDesc:SetText(StringTable.Get(cfgMedal.UnlockDesc))
       else
            self.txtProgressStatus:SetText(StringTable.Get("str_medal_progress")) --解锁进度
            self.txUnlockDesc:SetText(StringTable.Get(cfgMedal.GetPathDesc))
            local showProgress = cfgMedal.IsAutoTake
            self.progress:SetActive(showProgress)
            if showProgress then
                --进度条数据，从服务器获取
                local p, curInfo, totalInfo = itemData:GetProgress()
                self.progressImageRt.localScale = Vector3(p,1,1)
                local strTable = {}
                table.insert(strTable,"<color=#ffffff/>")
                table.insert(strTable,curInfo)
                table.insert(strTable,"</color>/")
                table.insert(strTable,totalInfo)
                self.txtProgressDetail:SetText(table.concat(strTable))
            end
        end
    end

    self._ani:Play("uieff_UIMedalListItemDetail_in")
end
