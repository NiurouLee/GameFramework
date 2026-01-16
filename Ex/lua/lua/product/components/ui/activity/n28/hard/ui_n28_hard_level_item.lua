---@class UIN28HardLevelItem:UICustomWidget
_class("UIN28HardLevelItem", UICustomWidget)
UIN28HardLevelItem = UIN28HardLevelItem

function UIN28HardLevelItem:Constructor(uiview)
    ---@type UIView
    self._view = uiview
    self:OnShow()
end

function UIN28HardLevelItem:OnShow()
    self._normal = self._view:GetUIComponent("Image", "normal")
    self._pass = self._view:GetUIComponent("Image", "pass")
    self._close = self._view:GetUIComponent("Image", "close")
    self._lockIcon = self._view:GetUIComponent("Image", "lockIcon")
    self._passBg = self._view:GetUIComponent("Image", "passBg")
    self._name = self._view:GetUIComponent("UILocalizationText", "name")
    self._titleOutline = self._view:GetUIComponent("H3D.UGUI.CircleOutline", "name")
    self._closeCanvasGroup = self._view:GetUIComponent("CanvasGroup", "close")
    self._localPos = self._view.transform.localPosition:Clone()

    self._titleBg = self._view:GetUIComponent("Image", "TitleBg")
    self._lockimg = self._view:GetUIComponent("Image", "lockimg")
    self._hadimg = self._view:GetUIComponent("Image", "hadimg")
    self._finishTxt = self._view:GetUIComponent("UILocalizationText", "FinishedText")
    self._anim = self._view:GetUIComponent("Animation", "anim")
end

---@protected
---隐藏的时候，这里可以处理事件的注销
function UIN28HardLevelItem:OnHide()
end

---@param passInfo cam_mission_info
function UIN28HardLevelItem:SetData(idx, cfg, passInfo, cur, atlas)
    local levelCfg = UIN28HardLevel.LevelCfg[idx]

    self._normal.sprite = atlas:GetSprite(levelCfg.normal)
    self._titleBg.sprite = atlas:GetSprite(levelCfg.click)
    self._lockimg.sprite = atlas:GetSprite(levelCfg.close)
    self._hadimg.sprite = atlas:GetSprite(levelCfg.close)
    self._name.color = levelCfg.titleColor
    self._finishTxt.color = levelCfg.passTxtColor
    self._lockIcon.sprite = atlas:GetSprite(levelCfg.lock)
    self._passBg.sprite = atlas:GetSprite(levelCfg.passBg)

    if levelCfg.titleOutlineColor then
        self._titleOutline.enabled = true
        self._titleOutline.effectColor = levelCfg.titleOutlineColor
    else
        self._titleOutline.enabled = false
    end

    if idx < cur then
        --已通关
        if not passInfo then
            Log.exception("没有通关信息：", idx)
        end
        self._pass.gameObject:SetActive(true)
        self._closeCanvasGroup.alpha = 0
    elseif idx > cur then
        --未通关
        self._pass.gameObject:SetActive(false)
        self._closeCanvasGroup.alpha = 1
    else
        --当前关
        self._normal.gameObject:SetActive(true)
        self._pass.gameObject:SetActive(false)
        self._closeCanvasGroup.alpha = 0
    end

    local missionCfg = Cfg.cfg_campaign_mission[cfg.CampaignMissionId]
    self._name:SetText(StringTable.Get(missionCfg.Name))
end

function UIN28HardLevelItem:LocalPosition()
    return self._localPos
end

function UIN28HardLevelItem:Anim_Pass()
    self._anim:Play("uieff_UIN28HardLevel_Finish")
end

function UIN28HardLevelItem:Anim_Open()
    -- self._closeCanvasGroup.alpha = 1
    -- self._anim:Play("uieff_UIN28HardLevel_lock")
end

function UIN28HardLevelItem:SetActive(bShow)
    self._view.gameObject:SetActive(bShow)
end 

