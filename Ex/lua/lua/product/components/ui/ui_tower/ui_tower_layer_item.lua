---@class UITowerLayerItem : UICustomWidget
_class("UITowerLayerItem", UICustomWidget)
UITowerLayerItem = UITowerLayerItem
function UITowerLayerItem:OnShow(uiParams)
    self:InitWidget()
    self:AttachEvent(GameEventType.TowerLayerOnSelect, self.OnItemSelect)
end
function UITowerLayerItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.layerText = self:GetUIComponent("UILocalizationText", "layerText")
    ---@type UnityEngine.GameObject
    self.valid = self:GetGameObject("valid")
    ---@type UnityEngine.UI.Image
    self.invalid = self:GetGameObject("invalid")
    self.bossBG = self:GetGameObject("bossBG")
    self.lockTextUp = self:GetUIComponent("UILocalizationText", "LockTextUp")
    self.lockTextDown = self:GetUIComponent("UILocalizationText", "LockTextDown")
    ---@type UnityEngine.UI.Image
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.UI.Image
    self.cur = self:GetGameObject("cur")
    ---@type UnityEngine.UI.Image
    self.normal = self:GetGameObject("normal")
    ---@type UnityEngine.UI.Image
    self.boss = self:GetGameObject("boss")
    ---@type UnityEngine.RectTransform
    self.content = self:GetUIComponent("RectTransform", "content")
    self.tips = self:GetGameObject("Tips")
    self.reward = self:GetUIComponent("RawImageLoader","reward")
    --generated end--
end
function UITowerLayerItem:SetData(anchor, cfg, curLayer, passAll, curSelect, onSelect)
    self._onSelect = onSelect
    self._cfg = cfg
    local cfg_item = Cfg.cfg_item
    if anchor == 1 then --左
        self.content.anchoredPosition = Vector2(-136, 0)
    elseif anchor == 2 then --右
        self.content.anchoredPosition = Vector2(136, 0)
    end
    self.layerText:SetText(cfg.stage)
    self.layerText.color = Color.white

    if cfg.stage > curLayer then
        --不可达
        self.valid:SetActive(false)
        self:SetTextColor()
        self.invalid:SetActive(true)

        if cfg.RewardTip then
            self.tips:SetActive(true)
            self.reward:LoadImage(cfg_item[cfg.RewardTip].Icon)
        else
            self.tips:SetActive(false)
        end
    elseif cfg.stage < curLayer then
        --已通关
        local isBoss = cfg.BossLevel
        self.cur:SetActive(false)
        self.normal:SetActive(not isBoss)
        self.boss:SetActive(isBoss)
        self.valid:SetActive(true)
        self.invalid:SetActive(false)
        self.tips:SetActive(false)
    else
        --当前层
        if passAll then
            --通关后，最后1个路点当作已通关处理
            local isBoss = cfg.BossLevel
            self.cur:SetActive(false)
            self.normal:SetActive(not isBoss)
            self.boss:SetActive(isBoss)
            self.valid:SetActive(true)
            self.invalid:SetActive(false)
            self.tips:SetActive(false)
        else
            self.cur:SetActive(true)
            self.layerText.color = Color.black
            self.normal:SetActive(false)
            self.boss:SetActive(false)
            self.valid:SetActive(true)
            self.invalid:SetActive(false)
            if cfg.RewardTip then
                self.tips:SetActive(true)
                self.reward:LoadImage(cfg_item[cfg.RewardTip].Icon)
            else
                self.tips:SetActive(false)
            end
        end

    end
    self.select:SetActive(self._cfg.stage == curSelect)
end

function UITowerLayerItem:OnItemSelect(idx)
    self.select:SetActive(self._cfg.stage == idx)
end

function UITowerLayerItem:itemOnClick(go)
    self._onSelect(self._cfg.stage)
end

function UITowerLayerItem:SetTextColor()
    if self._cfg.BossLevel then
        self.bossBG:SetActive(true)
        self.lockTextUp.color = Color(151/255, 24/255, 24/255, 1)
        self.lockTextDown.color = Color(136/255, 21/255, 21/255, 1)
    else
        self.bossBG:SetActive(false)
        self.lockTextUp.color = Color(112/255, 112/255, 112/255, 1)
        self.lockTextDown.color = Color(112/255, 112/255, 112/255,1)
    end
end
