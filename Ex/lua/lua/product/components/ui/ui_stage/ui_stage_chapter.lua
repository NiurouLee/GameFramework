---@class UIStageChapter:UICustomWidget
_class("UIStageChapter", UICustomWidget)
UIStageChapter = UIStageChapter

function UIStageChapter:OnShow()
    ---@type UILocalizationText
    self._txtTitleIdx = self:GetUIComponent("UILocalizationText", "txtTitleIdx")
    ---@type UILocalizationText
    self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    self._chapterName = self:GetUIComponent("UILocalizationText", "chapterName")
end

function UIStageChapter:Flush(titleIdx, title, desc, chapterName, isBetween)
    titleIdx = titleIdx or ""
    title = title or ""
    self._txtTitleIdx:SetText(titleIdx .. title)

    desc = desc or ""
    self._txtDesc:SetText(desc)

    local showChapterName = chapterName or ""
    self._chapterName:SetText(showChapterName)

    if isBetween then
        self._chapterName.color = Color(156 / 255, 115 / 255, 185 / 255, 1)
        self._txtTitleIdx.color = Color(163 / 255, 158 / 255, 170 / 255, 1)
        self._txtDesc.color = Color(134 / 255, 134 / 255, 134 / 255, 1)
    end
end
