--
---@class UISeasonCgCollectionCell : UICustomWidget
_class("UISeasonCgCollectionCell", UICustomWidget)
UISeasonCgCollectionCell = UISeasonCgCollectionCell
--初始化
function UISeasonCgCollectionCell:OnShow(uiParams)
    self:InitWidget()
    self._bookModule = GameGlobal.GetModule(BookModule)
end
--获取ui组件
function UISeasonCgCollectionCell:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.txtLock = self:GetUIComponent("UILocalizationText", "txtLock")
    ---@type UnityEngine.GameObject
    self.lock = self:GetGameObject("lock")
    ---@type UnityEngine.GameObject
    self.unlock = self:GetGameObject("unlock")
    ---@type RawImageLoader
    self.imgCg = self:GetUIComponent("RawImageLoader", "imgCg")
    ---@type UILocalizationText
    self.txtCgName = self:GetUIComponent("UILocalizationText", "txtCgName")
    ---@type UnityEngine.GameObject
    self.new = self:GetGameObject("new")
    --generated end--
end
--设置数据
function UISeasonCgCollectionCell:SetData(cfg, index, clickCb)
    self.index = index
    self.clickCb = clickCb
    self._cfg = cfg
    local a, isUnLock = self._bookModule:GetSeasonStory(cfg)
    self._isUnlock = isUnLock or false
    self.lock:SetActive(not isUnLock)
    self.unlock:SetActive(isUnLock)
    if isUnLock then
        self.imgCg:LoadImage(cfg.Preview)
        self.txtCgName:SetText(StringTable.Get(cfg.name))
        self:_RefreshNew()
    else
        self.txtLock:SetText(StringTable.Get(cfg.UnLockDes))
        self.new:SetActive(false)
    end
end
--按钮点击
function UISeasonCgCollectionCell:CgBtnOnClick(go)
    if self.clickCb then
        self.clickCb(self.index, self._isUnlock)
    end
    if self._isUnlock then
        UISeasonExploreHelper.SetCgAsClicked(self._cfg.ID)
        self:_RefreshNew()
    end
end

function UISeasonCgCollectionCell:_RefreshNew()
    local isNew = not UISeasonExploreHelper.IsCgHasClicked(self._cfg.ID)
    self.new:SetActive(isNew)
end
