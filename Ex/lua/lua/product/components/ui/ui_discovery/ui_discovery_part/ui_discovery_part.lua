---@class UIDiscoveryPart:UIController
_class("UIDiscoveryPart", UIController)
UIDiscoveryPart = UIDiscoveryPart

function UIDiscoveryPart:Constructor()
    self.module = self:GetModule(MissionModule)
    self.data = self.module:GetDiscoveryData()
    -- self.module:InitDiscoveryData()
    ---@type tabl<number,UIDiscoveryPartChaperItem>
    self._items = {}
end

function UIDiscoveryPart:OnShow(uiParams)
    self.chapterId = uiParams[1]
    local sectionCur = self.data:GetDiscoverySectionByChapterId(self.chapterId)

    local len = table.count(self.data.sections)
    -- ---@type UICustomWidgetPool
    -- local content = self:GetUIComponent("UISelectObjectPath", "Content")
    -- content:SpawnObjects("UIDiscoveryPartItem", len)
    -- ---@type UIDiscoveryPartItem[]
    -- local items = content:GetAllSpawnList()
    -- for i, ui in ipairs(items) do
    --     local section = self.data.sections[i]
    --     ui:Flush(section.id, sectionCur.id)
    -- end

    self._onTimeup = function(item, idx)
        self.module:InitDiscoveryData()
        self.data = self.module:GetDiscoveryData()
        item:SetShow(idx, self.data.sections[idx], self._onTimeup)
    end

    self._nextBtn = self:GetUIComponent("Image", "Next")
    self._lastBtn = self:GetUIComponent("Image", "Last")

    self._scroll =
        H3DScrollViewHelper:New(
        self,
        "sv",
        "UIDiscoveryPartChaperItem",
        function(idx, item)
            self:_OnShowItem(idx, item)
        end,
        function(idx, item)
            self:_OnHideItem(idx, item)
        end
    )
    ---@type UnityEngine.RectTransform
    local area = self:GetUIComponent("RectTransform", "SafeArea")
    self._scroll:Init(len, sectionCur.id, Vector2(area.rect.width, 830))
    -- self._scroll:SetCalcScale(true) --把这个打开oncenter回调才生效
    self._scroll:SetGroupChangedCallback(
        function(idx, item)
            self:_OnCenterItem(idx + 1, item)
        end
    )
    self._scroll:SetValueChangedCallback(
        function(group, value, contentSize, itemSize)
            self:_OnValueChanged(group + 1, value, contentSize, itemSize)
        end
    )

    self._max = len
    self._curIdx = sectionCur.id

    if len > 1 then
        local indexer = self:GetUIComponent("UISelectObjectPath", "Indexer")
        ---@type UIDiscoveryPartIndexer[]
        self._indexer = indexer:SpawnObjects("UIDiscoveryPartIndexer", len)
        self._indexer[self._curIdx]:Select(true)
    end
    if self._curIdx <= 1 then
        self._lastBtn.color = Color(1, 1, 1, 0.3)
    end
    if self._curIdx >= self._max then
        self._nextBtn.color = Color(1, 1, 1, 0.3)
    end

    self._enterBtn = self:GetUIComponent("CanvasGroup", "EnterBtn")
    self._active = true
end

function UIDiscoveryPart:OnHide()
    self._scroll:Dispose()
    self._active = false
end

function UIDiscoveryPart:BgOnClick(go)
    self:CloseDialog()
end

---@param item UIDiscoveryPartChaperItem
function UIDiscoveryPart:_OnShowItem(idx, item)
    item:SetShow(idx, self.data.sections[idx], self._onTimeup)
    self._items[idx] = item
end
---@param item UIDiscoveryPartChaperItem
function UIDiscoveryPart:_OnHideItem(idx, item)
    item:SetHide(idx, self.data.sections[idx])
    self._items[idx] = nil
end
---@param item UIDiscoveryPartChaperItem
function UIDiscoveryPart:_OnCenterItem(idx, item)
    if self._curIdx then
        self._indexer[self._curIdx]:Select(false)
    end
    self._curIdx = idx
    self._indexer[self._curIdx]:Select(true)
    if self._curIdx > 1 then
        self._lastBtn.color = Color(1, 1, 1, 1)
    else
        self._lastBtn.color = Color(1, 1, 1, 0.3)
    end

    if self._curIdx < self._max then
        self._nextBtn.color = Color(1, 1, 1, 1)
    else
        self._nextBtn.color = Color(1, 1, 1, 0.3)
    end
end

function UIDiscoveryPart:LastOnClick()
    if self._curIdx <= 1 then
        ToastManager.ShowToast(StringTable.Get("str_chapter_section_begin"))
        return
    end
    self._scroll:MovePanelToIndex(self._curIdx - 1)
    if self._curIdx - 1 <= 1 then
        self._lastBtn.color = Color(1, 1, 1, 0.3)
    end
end
function UIDiscoveryPart:NextOnClick()
    if self._curIdx >= self._max then
        ToastManager.ShowToast(StringTable.Get("str_chapter_section_end"))
        return
    end
    self._scroll:MovePanelToIndex(self._curIdx + 1)
    if self._curIdx + 1 >= self._max then
        self._nextBtn.color = Color(1, 1, 1, 0.3)
    end
end

function UIDiscoveryPart:_OnValueChanged(group, value, contentSize, itemSize)
    local di = (contentSize - itemSize)
    --分母不能等于零
    if di <= 0 then
        return
    end
    local rate = itemSize / (contentSize - itemSize)
    if rate <= 0 then
        return
    end
    local centerRate = group * rate - 0.5 * rate
    local distance = value - centerRate
    local a = math.abs(distance) / (rate * 0.5) + 0.05

    a = 1.0 - a * 2
    if a < 0 then
        a = 0
    elseif a > 1 then
        a = 1
    end

    if self._items[group]:IsLock() then
        a = 0
    end

    self._enterBtn.alpha = a
end

function UIDiscoveryPart:EnterBtnOnClick()
    self:StartTask(self._OnEnter, self)
end

function UIDiscoveryPart:_OnEnter(TT)
    local section = self.data:GetDiscoverySectionBySectionId(self._curIdx)
    local state, chapterId = section:State()
    if state == nil then
        return
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundUIBattleStart)
    self:Lock("PlayEnterAnim")
    self._items[self._curIdx]:PlayEnterAnim()
    YIELD(TT, 600)
    if not self._active then
        return
    end
    self:UnLock("PlayEnterAnim")

    if state == DiscoveryStageState.CanPlay then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushChapter, chapterId)
    elseif state == DiscoveryStageState.Nomal then
        local maxPassChapter = -1
        for cId, b in pairs(section.chapterIds) do
            if b and cId > maxPassChapter then
                maxPassChapter = cId
            end
        end
        if maxPassChapter < 1 then
            maxPassChapter = 1
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushChapter, maxPassChapter)
    else
        ToastManager.ShowToast(StringTable.Get("str_discovery_section_" .. section.id .. "_unlock_condition"))
    end
    if GameGlobal.UIStateManager():IsShow("UIChapters") then
        GameGlobal.UIStateManager():CloseDialog("UIChapters")
    end
    self:CloseDialog()
end
