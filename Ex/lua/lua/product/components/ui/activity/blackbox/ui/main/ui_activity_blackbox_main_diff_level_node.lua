require "ui_activity_diff_level_node"

---@class UIActivityBlackBoxMainDiffLevelNode : UIActivityDiffLevelNode
_class("UIActivityBlackBoxMainDiffLevelNode", UIActivityDiffLevelNode)
UIActivityBlackBoxMainDiffLevelNode = UIActivityBlackBoxMainDiffLevelNode
function UIActivityBlackBoxMainDiffLevelNode:OnInit()
    self._bIsSelect = false
    self._selectAnim = self:GetUIComponent("Animation", "Select")
    self._select = self:GetGameObject("Select")
    self._selectImg = self:GetUIComponent("RawImageLoader","Select")
    self._normalImg = self:GetUIComponent("RawImageLoader","Normal")
    self._lockImg = self:GetUIComponent("RawImageLoader","Lock")

    --[1]奖杯颜色 [2]关卡名颜色
    self._unSelectColor = {Color(164/255,129/255,35/255,1),Color(139/255,92/255,32/255,1)}
    self._selectColor = {Color(37/255,34/255,31/255,1),Color(40/255,26/255,6/255,1)}
    self._bossUnSelectColor = {Color(221/255,173/255,138/255,1),Color(221/255,173/255,138/255,1)}
    self._bossSelectColor = {Color(254/255,205/255,128/255,1),Color(254/255,205/255,128/255,1)}
end

---@param data UIActivityDiffLevelData
function UIActivityBlackBoxMainDiffLevelNode:SetData(data,campaign,cb)
    ---@type UIActivityDiffLevelData
    self._data = data
    self._campaign = campaign
    self._onClick = cb
    self._go:SetActive(true)
    self._rectTransform.anchorMax = Vector2(0, 0.5)
    self._rectTransform.anchorMin = Vector2(0, 0.5)
    self._rectTransform.sizeDelta = Vector2.zero
    self._rectTransform.anchoredPosition = self._data:GetPosition()
    self.name:SetText(self._data:GetNodeName())
    if self._data:IsOpen() then
        self._lock:SetActive(false)
        self._iconLoader:LoadImage(self._data:GetOpenIcon())
    else
        self._lock:SetActive(true)
        self._iconLoader:LoadImage(self._data:GetUnOpenIcon())
        self._unLockTips:SetText(self._data:GetLockTips())
    end
    self:RefreshCupInfo()

    local levelCfg = self._data:GetLevelCfg()
    local compId = levelCfg.ComponentID
    local cfg = Cfg.cfg_blackbox_main{ ComponentID = compId }[1]
    self._lockImg:LoadImage(cfg.CommonLock)
    if levelCfg.Type == 1 then
        self._normalImg:LoadImage(cfg.CommonNormal)
        self._selectImg:LoadImage(cfg.CommonSelect)
    elseif levelCfg.Type == 2 then
        self._normalImg:LoadImage(cfg.BossNormal)
        self._selectImg:LoadImage(cfg.BossSelect)
    end

    self:SetSelect(false)
end

function UIActivityBlackBoxMainDiffLevelNode:SetSelect(bIsSelect)
    self._bIsSelect = bIsSelect
    
    local levelCfg = self._data:GetLevelCfg()
    if levelCfg.Type == 1 then
        --普通关
        self.name.color = self._bIsSelect and self._selectColor[2] or self._unSelectColor[2]
        self._cupNum.color = self._bIsSelect and self._selectColor[1] or self._unSelectColor[1]
    else
        self.name.color = self._bIsSelect and self._bossSelectColor[2] or self._bossUnSelectColor[2]
        self._cupNum.color = self._bIsSelect and self._bossSelectColor[1] or self._bossUnSelectColor[1]
    end

    if bIsSelect then
        self._selectAnim:Play("uieff_UIActivityBlackBoxMainNode_select")
    else
        self._selectAnim:Play("uieff_UIActivityBlackBoxMainNode_out")
    end
end

function UIActivityBlackBoxMainDiffLevelNode:BtnOnClick()
    --检查关卡是否开启
    if not self._campaign:CheckComponentOpen(ECampaignDiffcultyWeekTowerComponentID.ECAMPAIGN_WEEK_TOWER_DIFFICULT_MISSION) then
        local result = self._campaign:CheckComponentOpenClientError(ECampaignDiffcultyWeekTowerComponentID.ECAMPAIGN_WEEK_TOWER_DIFFICULT_MISSION)
        self._campaign:CheckErrorCode(result)
        return
    end

    if not self._data:IsOpen() then
        local lockTip = self._data:GetLockTipsNoST()
        local s = StringTable.Get(lockTip,self._data:GetLastNodeName())
        ToastManager.ShowToast(s)
        return
    end
    self._onClick(self._data,self)
end

function UIActivityBlackBoxMainDiffLevelNode:GetDiffLevelID()
    return self._data._missionId
end