---@class UIMapNodeNextPart:UIMapNodeBasePart
_class("UIMapNodeNextPart", UIMapNodeBasePart)
UIMapNodeNextPart = UIMapNodeNextPart

function UIMapNodeNextPart:Constructor()
    UIMapNodeNextPart.super.Constructor(self)
    ---@type MissionModule
    self.mMission = self:GetModule(MissionModule)
    self.data = self.mMission:GetDiscoveryData()
end

function UIMapNodeNextPart:OnShow()
    UIMapNodeNextPart.super.OnShow(self)
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
end

---@overload
function UIMapNodeNextPart:GetUIComponentStar()
end
---@overload
function UIMapNodeNextPart:FlushStar()
end

---@overload
---@param nextChapter table cfg_discovery 中的 nextChapter
function UIMapNodeNextPart:Init(nextChapter, notPlayAnimation)
    self.nextChapter = nextChapter
    self.notPlayAnimation = notPlayAnimation
    self:InitPos()
    self.eff:SetActive(false)

    local chapter = self.data:GetChapterByChapterId(nextChapter.chapterId)
    if chapter then
        self.txtName:SetText(chapter.name or "")
    else
        self.txtName:SetText(StringTable.Get("str_discovery_coming_soon"))
    end
end
---@overload
function UIMapNodeNextPart:InitPos()
    self.rectTransform.anchorMax = self.vec0_5
    self.rectTransform.anchorMin = self.vec0_5
    self.rectTransform.sizeDelta = Vector2.zero
    self.rectTransform.anchoredPosition = self.nextChapter.pos
end

---@overload
function UIMapNodeNextPart:Flush()
    self:FlushState()
    self:Animation()
end
---@overload
function UIMapNodeNextPart:FlushState()
    local curChapter = self.data:GetCurPosChapter()
    local isComplete = curChapter:IsComplete()
    self.root:SetActive(isComplete)
end

---@overload
---@private
function UIMapNodeNextPart:ClickItem()
    local chapter = self.data:GetChapterByChapterId(self.nextChapter.chapterId)
    if chapter then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushChapter, self.nextChapter.chapterId)
    else
        ToastManager.ShowToast(StringTable.Get("str_discovery_coming_soon_hint"))
    end
end

---@overload
function UIMapNodeNextPart:Animation()
end

---@overload
function UIMapNodeNextPart:Highlight(isHighlight, nodeId)
end
