_class("UIChaptersItem", UICustomWidget)
UIChaptersItem = UIChaptersItem

function UIChaptersItem:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.grassData = self.mCampaign:GetGraveRobberData()
end

function UIChaptersItem:OnShow()
    self._rect = self:GetUIComponent("RectTransform", "rect")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._imgBGMask = self:GetGameObject("imgBGMask")
    self._imgRed = self:GetGameObject("imgRed")
    self.imgGrass = self:GetGameObject("imgGrass")
    self:AttachEvent(GameEventType.GrassClose, self.FlushGrass)
end
function UIChaptersItem:OnHide()
    self:DetachEvent(GameEventType.GrassClose, self.FlushGrass)
end

---@param chapter DiscoveryChapter
---@param curChapter DiscoveryChapter 大地图当前显示的章节
function UIChaptersItem:Flush(chapter, curChapter)
    self._chapter = chapter
    self._curChapter = curChapter
    self._txtName:SetText(chapter.index_name .. StringTable.Get("str_common_colon") .. chapter.name)
    self._imgBGMask:SetActive(chapter.id ~= curChapter.id)
    if chapter.id == curChapter.id then
        local color = Color(141 / 255, 133 / 255, 122 / 255)
        self._txtName.color = color
    else
        self._txtName.color = Color.white
    end
    --红点
    local module = self:GetModule(MissionModule)
    ---@type DiscoveryData
    local data = module:GetDiscoveryData()
    ---@type ChapterAwardData
    local chapterAwardData = data.chapterAwardData
    ---@type ChapterAwardChapter
    local chapterAward = chapterAwardData:GetChapterAwardChapterByChapterId(chapter.id)
    self._imgRed:SetActive(chapterAward and chapterAward:CanCollect() or false)
    self:FlushGrass()
end
function UIChaptersItem:FlushGrass()
    local canPlay = self.grassData:IsChapterCanPlay(self._chapter.id)
    -- self.imgGrass:SetActive(canPlay)
    self.imgGrass:SetActive(false) --为了统一适配隐藏图标，活动如果重开需要重新考虑适配 靳策修改
end

function UIChaptersItem:imgBGOnClick(go)
    if self._chapter.id ~= self._curChapter.id then --所点击的不是当前显示的章节，才刷
        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushChapter, self._chapter.id)
    end
    GameGlobal.UIStateManager():CloseDialog("UIChapters")
end
