---@class UIDiffNodeNext:UIDiffNodeBase
_class("UIDiffNodeNext", UIDiffNodeBase)
UIDiffNodeNext = UIDiffNodeNext

---@overload
function UIDiffNodeNext:GetComponents()
    self._go = self:GetGameObject()
    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")
    self._texName = self:GetUIComponent("UILocalizationText", "txtName")
end
---@overload
function UIDiffNodeNext:SetInfo()
    local chapterID = self._node:ChapterID()
    local tips
    self._nextChapterID = self._uiModule:GetNextChapterID(chapterID)
    --如果右下一章显示章节名，否则显示即将开启
    if self._nextChapterID then
        local cfg = Cfg.cfg_difficulty_mission_chapter_desc[self._nextChapterID]
        local cName = cfg.Name
        tips = cName
    else
        tips = "str_discovery_coming_soon"
    end
    self._texName:SetText(StringTable.Get(tips))
end
---@overload
function UIDiffNodeNext:ClickItem()
    if self._nextChapterID then
        if self._callback then
            self._callback(self._node)
        end
    end
end
