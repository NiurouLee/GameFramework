---@class UIMapNodeItemNextChapter:UIMapNodeItemBase
_class("UIMapNodeItemNextChapter", UIMapNodeItemBase)
UIMapNodeItemNextChapter = UIMapNodeItemNextChapter

function UIMapNodeItemNextChapter:Constructor()
    UIMapNodeItemNextChapter.super.Constructor(self)
    ---@type MissionModule
    self._module = self:GetModule(MissionModule)
    self._data = self._module:GetDiscoveryData()
    self._nextChapter = nil
end

function UIMapNodeItemNextChapter:OnHide()
    self._nextChapter = nil
end
---@overload
function UIMapNodeItemNextChapter:GetUIComponentStar()
end

---@overload
function UIMapNodeItemNextChapter:Init(nextChapterData, notPlayAnimation)
    self._nextChapter = nextChapterData
    self._notPlayAnimation = notPlayAnimation
    self._rectTransform.anchorMax = self._vec0_5
    self._rectTransform.anchorMin = self._vec0_5
    self._rectTransform.sizeDelta = Vector2(100, 100)
    self._rectTransform.anchoredPosition = self._nextChapter.pos
    self.eff:SetActive(false)

    local chapter = self._data:GetChapterByChapterId(self._nextChapter.chapterId)
    if chapter then
        self.txtTip.text = chapter.name or ""
    else
        self.txtTip.text = StringTable.Get("str_discovery_coming_soon")
    end
end

---@overload
function UIMapNodeItemNextChapter:Flush()
    self:FlushState()
    self:Animation()
end
---@overload
function UIMapNodeItemNextChapter:FlushState()
    local curChapter = self._data:GetCurPosChapter()
    local isComplete = curChapter:IsComplete()
    self._root:SetActive(isComplete)
end
---@overload
function UIMapNodeItemNextChapter:FlushStar()
end

--region OnClick
---@overload
function UIMapNodeItemNextChapter:ClickItem()
    local chapter = self._data:GetChapterByChapterId(self._nextChapter.chapterId)
    if chapter then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushChapter, self._nextChapter.chapterId)
    else
        ToastManager.ShowToast(StringTable.Get("str_discovery_coming_soon_hint"))
    end
end
--endregion

---@overload
function UIMapNodeItemNextChapter:Animation()
    if self:IsFirstShow() then --可激活的路点，首次出现，需要等路点光效表现完才展开
        self:SaveIsFirstShow()
    end
    self:PlayTipAnim()
end
---@overload
function UIMapNodeItemNextChapter:Highlight(isHighlight, chapterId)
end

---@overload
function UIMapNodeItemNextChapter:GetTipAnimName()
    return "uieff_UINormNodeNext_in"
end

---@overload
function UIMapNodeItemNextChapter:GetTip()
    if self._nextChapter then
        return self._tipRoot
    end
end

---@return boolean 是否是第一次显示
function UIMapNodeItemNextChapter:IsFirstShow()
    local playerPrefsKey = self:GetPstId() .. "DiscoveryNextChapterIsFirstShow" .. self._nextChapter.chapterId
    local isFirst = UnityEngine.PlayerPrefs.GetInt(playerPrefsKey, 0)
    return isFirst == 0
end

function UIMapNodeItemNextChapter:SaveIsFirstShow()
    local playerPrefsKey = self:GetPstId() .. "DiscoveryNextChapterIsFirstShow" .. self._nextChapter.chapterId
    UnityEngine.PlayerPrefs.SetInt(playerPrefsKey, 1)
end

---@private
function UIMapNodeItemNextChapter:GetPstId()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return roleModule:GetPstId()
end
