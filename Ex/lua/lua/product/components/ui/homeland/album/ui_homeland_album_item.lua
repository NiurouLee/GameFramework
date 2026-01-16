---@class UIHomelandAlbumItem : UICustomWidget
_class("UIHomelandAlbumItem", UICustomWidget)
UIHomelandAlbumItem = UIHomelandAlbumItem

function UIHomelandAlbumItem:OnShow(uiParams)
    self:InitWidget()
    self._color = {}
    self._color.valid = Color(88/255, 87/255, 87/255)
    self._color.inValid = Color(158 / 255, 158 / 255, 158 / 255)
end
function UIHomelandAlbumItem:InitWidget()
    --generated--
    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.play = self:GetGameObject("play")
    ---@type RollingText
    self.nameText = self:GetUIComponent("RollingText", "nameText")
    ---@type RollingText
    self.authorText = self:GetUIComponent("RollingText", "authorText")
    --generated end--
    ---@type UnityEngine.GameObject
    self.lock = self:GetGameObject("lock")
    ---@type UILocalizationText
    self.duration = self:GetUIComponent("UILocalizationText", "duration")
    ---@type UnityEngine.Animation
    self.playing = self:GetUIComponent("Animation", "playing")
    ---@type UnityEngine.AnimationState
    self._playingState = self.playing:get_Item("uieff_Album_Playing")

    self._nameText = self:GetUIComponent("Text", "nameText")
    self._authorText = self:GetUIComponent("Text", "authorText")
    self._durationText = self:GetUIComponent("Text", "duration")
end
function UIHomelandAlbumItem:SetData(cfg, index, isLock, onClick, select, playing, isPause)
    self._cfg = cfg
    self._index = index
    self._isLock = isLock
    self._onClick = onClick
    self._cfgId = cfg.ID

    self.nameText:RefreshText(StringTable.Get(cfg.Name))
    self.authorText:RefreshText(StringTable.Get(cfg.Author))
    self.duration:SetText(UIHomelandBgmHelper.FormatTime(cfg.Duration))

    self.select:SetActive(select)

    if playing then
        self.duration.gameObject:SetActive(false)
        self.playing.gameObject:SetActive(true)
        self.play:SetActive(false)
        if isPause then
            self.playing:Stop()

            self._playingState.enabled = true
            self._playingState.normalizedTime = 0
            self.playing:Sample()
            self._playingState.enabled = false
        else
            self.playing:Play()
        end
    else
        self.playing.gameObject:SetActive(false)
        if select then
            self.play:SetActive(true)
            self.duration.gameObject:SetActive(false)
        else
            self.play:SetActive(false)
            self.duration.gameObject:SetActive(true)
        end
    end

    self.lock:SetActive(isLock)
    if isLock then
        self._nameText.color = self._color.inValid
        self._authorText.color = self._color.inValid
        self._durationText.color = self._color.inValid
    else
        self._nameText.color = self._color.valid
        self._authorText.color = self._color.valid
        self._durationText.color = self._color.valid
    end
end

function UIHomelandAlbumItem:itemOnClick(go)
    if self._isLock then
        ToastManager.ShowToast(StringTable.Get(self._cfg.UnLockDes))
    else
        self._onClick(self._index)
    end
end
