---@class UIN26HardLevelItem:UICustomWidget
_class("UIN26HardLevelItem", UICustomWidget)
UIN26HardLevelItem = UIN26HardLevelItem

function UIN26HardLevelItem:Constructor(uiview)
    ---@type UIView
    self._view = uiview
    self:OnShow()
end

function UIN26HardLevelItem:OnShow()
    self._normal = self._view:GetUIComponent("Image", "normal")
    self._pass = self._view:GetUIComponent("Image", "pass")
    self._close = self._view:GetUIComponent("Image", "close")
    self._name = self._view:GetUIComponent("UILocalizationText", "name")
    self._localPos = self._view.transform.localPosition:Clone()

    self._titleBg = self._view:GetUIComponent("Image", "TitleBg")
    self._lockimg = self._view:GetUIComponent("Image", "lockimg")
    self._hadimg = self._view:GetUIComponent("Image", "hadimg")
end

---@protected
---隐藏的时候，这里可以处理事件的注销
function UIN26HardLevelItem:OnHide()
end

---@param passInfo cam_mission_info
function UIN26HardLevelItem:SetData(idx, cfg, passInfo, cur, atlas)
    local levelCfg = UIN26HardLevel.LevelCfg[idx]
    self._normal.sprite = atlas:GetSprite(levelCfg.normal)
    self._titleBg.sprite = atlas:GetSprite(levelCfg.click)
    self._lockimg.sprite = atlas:GetSprite(levelCfg.close)
    self._hadimg.sprite = atlas:GetSprite(levelCfg.close)

    if idx < cur then
        --已通关
        if not passInfo then
            Log.exception("没有通关信息：", idx)
        end
        self._pass.gameObject:SetActive(true)
        self._close.gameObject:SetActive(false)
    elseif idx > cur then
        --未通关
        self._pass.gameObject:SetActive(false)
        self._close.gameObject:SetActive(true)
    else
        --当前关
        self._normal.gameObject:SetActive(true)
        self._pass.gameObject:SetActive(false)
        self._close.gameObject:SetActive(false)
    end

    local missionCfg = Cfg.cfg_campaign_mission[cfg.CampaignMissionId]
    self._name:SetText(StringTable.Get(missionCfg.Name))
end

function UIN26HardLevelItem:LocalPosition()
    return self._localPos
end

function UIN26HardLevelItem:Anim_Pass()
   
end

function UIN26HardLevelItem:Anim_Open()
  
end

function UIN26HardLevelItem:SetActive(bShow)
    self._view.gameObject:SetActive(bShow)
end 

