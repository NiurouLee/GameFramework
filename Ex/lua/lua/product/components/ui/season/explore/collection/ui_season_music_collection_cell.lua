--
---@class UISeasonMusicCollectionCell : UICustomWidget
_class("UISeasonMusicCollectionCell", UICustomWidget)
UISeasonMusicCollectionCell = UISeasonMusicCollectionCell

function UISeasonMusicCollectionCell:Constructor()
end

--初始化
function UISeasonMusicCollectionCell:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonMusicCollectionCell:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.new = self:GetGameObject("new")
    ---@type UILocalizationText
    self.txtLock = self:GetUIComponent("UILocalizationText", "txtLock")
    ---@type UnityEngine.GameObject
    self.lock = self:GetGameObject("lock")
    ---@type UnityEngine.GameObject
    self.unlock = self:GetGameObject("unlock")
    ---@type RawImageLoader
    self.imgMusic = self:GetUIComponent("RawImageLoader", "imgMusic")
    ---@type UILocalizationText
    self.txtMusicName = self:GetUIComponent("UILocalizationText", "txtMusicName")
    ---@type UILocalizationText
    self.txtAuthorName = self:GetUIComponent("UILocalizationText", "txtAuthorName")
    ---@type UnityEngine.GameObject
    self.playingObj = self:GetGameObject("playingObj")
    ---@type UnityEngine.GameObject
    self.pauseObj = self:GetGameObject("pauseObj")
    --generated end--
end
--设置数据
function UISeasonMusicCollectionCell:SetData(cfg, index, playingIndex, pauseIndex, clickCb)
    self._roleModule = GameGlobal.GetModule(RoleModule)
    self.idx = index
    self.clickCb = clickCb
    self._cfg = cfg
    self._isPlaying = playingIndex == index
    self._isPause = pauseIndex == index
    self.isUnlock = not self._roleModule:UI_CheckMusicLock(cfg)
    self.lock:SetActive(not self.isUnlock)
    self.unlock:SetActive(self.isUnlock)

    self.txtMusicName:SetText(StringTable.Get(cfg.Name))
    self.txtAuthorName:SetText(StringTable.Get( cfg.Author))
    self.imgMusic:LoadImage(cfg.Icon)

    if not self.unlock then
        self.txtLock:SetText(StringTable.Get(cfg.UnLockDes))
        self.new:SetActive(false)
    else
        self:_RefreshNew()
    end

    self:RefreshPlayUI()
end

--按钮点击
function UISeasonMusicCollectionCell:ItemBtnOnClick(go)
    if  self.unlock then
        UISeasonExploreHelper.SetMusicAsClicked(self._cfg.ID)
        self:_RefreshNew()
    end

    if self.clickCb then
        self.clickCb(self.idx, self.isUnlock)
    end
end

function UISeasonMusicCollectionCell:RefreshPlayUI()
    self.playingObj:SetActive(self._isPlaying)
    self.pauseObj:SetActive(self._isPause)
end

function UISeasonMusicCollectionCell:_RefreshNew()
    local isNew = not UISeasonExploreHelper.IsMusicHasClicked(self._cfg.ID)
    self.new:SetActive(isNew)
end