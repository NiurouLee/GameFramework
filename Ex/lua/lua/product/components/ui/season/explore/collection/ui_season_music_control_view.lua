--
---@class UISeasonMusicControlView : UICustomWidget
_class("UISeasonMusicControlView", UICustomWidget)
UISeasonMusicControlView = UISeasonMusicControlView
--初始化
function UISeasonMusicControlView:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UISeasonMusicControlView:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.cover = self:GetUIComponent("RawImageLoader", "cover")
    ---@type RollingText
    self.nameText = self:GetUIComponent("RollingText", "nameText")
    ---@type RollingText
    self.authorText = self:GetUIComponent("RollingText", "authorText")
    ---@type RollingText
    self.mainMusicText = self:GetUIComponent("RollingText", "MainMusicText")
    ---@type UnityEngine.GameObject
    self.pauseBtnGo = self:GetGameObject("pauseBtn")
    ---@type UnityEngine.GameObject
    self.resumeBtnGo = self:GetGameObject("resumeBtn")
    --generated end--
end

function UISeasonMusicControlView:GetCfg()
    return self._cfg
end


function UISeasonMusicControlView:Pause()
    self._playState = UISeasonExploreHelper.playingStatePause
end


function UISeasonMusicControlView:Resume()
    self._playState = UISeasonExploreHelper.playingStatePlaying
end

function UISeasonMusicControlView:SetMainMusicName(txt)
    self.mainMusicText:RefreshText(txt)
end


--设置数据
function UISeasonMusicControlView:SetData(preClickCb, nextClickCb, pauseClickCb, resumeClickCb, setMainClickCb)
    self._preClickCb = preClickCb
    self._nextClickCb = nextClickCb
    self._pauseClickCb = pauseClickCb
    self._resumeClickCb = resumeClickCb
    self._setMainClickCb = setMainClickCb
    self._roleModule = GameGlobal.GetModule(RoleModule)
end

function UISeasonMusicControlView:Play(index, cfg)
    self._index = index
    self._cfg = cfg
    self._playState = UISeasonExploreHelper.playingStatePlaying
    self:RefreshUI()

    self._roleModule:UI_MusicOnclick(Cfg.cfg_role_music[self._cfg.ID])
end

--刷新UI
function UISeasonMusicControlView:RefreshUI()
    self.cover:LoadImage(self._cfg.Icon)
    self.nameText:RefreshText(StringTable.Get(self._cfg.Name))
    self.authorText:RefreshText(StringTable.Get(self._cfg.Author))
    self:RefreshPlayState()
end

function UISeasonMusicControlView:RefreshPlayState()
   self.pauseBtnGo:SetActive(self._playState ~= UISeasonExploreHelper.playingStatePause)
   self.resumeBtnGo:SetActive(self._playState == UISeasonExploreHelper.playingStatePause)
end


--按钮点击
function UISeasonMusicControlView:PauseBtnOnClick(go)
    self._playState = UISeasonExploreHelper.playingStatePause
    AudioHelperController.PauseBGM()
    self:RefreshPlayState()
    if self._pauseClickCb then
        self._pauseClickCb(self._index, self._cfg)
    end
end

--按钮点击
function UISeasonMusicControlView:ResumeBtnOnClick(go)
    self._playState = UISeasonExploreHelper.playingStatePlaying
    AudioHelperController.UnpauseBGM()
    self:RefreshPlayState()
    if self._resumeClickCb then
        self._resumeClickCb(self._index, self._cfg)
    end
end

--按钮点击
function UISeasonMusicControlView:LastBtnOnClick(go)
    if self._preClickCb then
        self._preClickCb(self._index, self._cfg)
    end
end

--按钮点击
function UISeasonMusicControlView:NextBtnOnClick(go)
    if self._nextClickCb then
        self._nextClickCb(self._index, self._cfg)
    end
end

--按钮点击
function UISeasonMusicControlView:SetMainOnClick(go)
    if self._setMainClickCb then
        self._setMainClickCb(self._index, self._cfg)
    end
end
