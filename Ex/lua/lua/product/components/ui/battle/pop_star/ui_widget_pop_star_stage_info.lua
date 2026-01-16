---@class UIWidgetPopStarStageInfo : UICustomWidget
_class("UIWidgetPopStarStageInfo", UICustomWidget)
UIWidgetPopStarStageInfo = UIWidgetPopStarStageInfo

function UIWidgetPopStarStageInfo:OnShow()
    self._anim = self:GetUIComponent("Animation", "UIWidgetPopStarStageInfo")

    self._canvasGroup = self:GetUIComponent("CanvasGroup", "Canvas")
    self:SetCanvasShow(false)

    ---@type UnityEngine.UI.ScrollRect
    self._scrollView = self:GetUIComponent("ScrollRect", "ScrollView")
    self._scrollView.gameObject:SetActive(false)
    ---@type UnityEngine.RectTransform
    self._rtScrollView = self:GetUIComponent("RectTransform", "ScrollView")

    ---@type UICustomWidgetPool
    self._contentPool = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UnityEngine.RectTransform
    self._rtContent = self:GetUIComponent("RectTransform", "Content")
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._rtContent)
end

function UIWidgetPopStarStageInfo:OnHide()
end

function UIWidgetPopStarStageInfo:SetCanvasShow(show)
    if self._canvasGroup then
        self._canvasGroup.alpha = show and 1 or 0
        self._canvasGroup.blocksRaycasts = show
    end
end

function UIWidgetPopStarStageInfo:Init(buffIDList)
    self:SetCanvasShow(true)
    self._anim:Play("uieff_UIWidgetPopStarStageInfo_in")

    self:_InitListView(buffIDList)
    self._scrollView.gameObject:SetActive(true)

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._rtContent)

    ---刷两次不会闪
    self:_RefreshContentRT()

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT)
            self:_RefreshContentRT()
        end
    )
end

function UIWidgetPopStarStageInfo:_InitListView(buffIDList)
    local cacheCount = #buffIDList
    if cacheCount == 0 then
        cacheCount = 1
    end

    ---@type UIWidgetPopStarStageInfoItem[]
    local arr = self._contentPool:SpawnObjects("UIWidgetPopStarStageInfoItem", cacheCount)

    for idx, item in ipairs(arr) do
        if #buffIDList == 0 then
            item:Init("str_n31_popstar_battle_no_stage_buff")
        else
            local buffID = buffIDList[idx]
            local cfgBuff = ConfigServiceHelper.GetBuffConfigData(buffID)
            if cfgBuff then
                item:Init(cfgBuff:GetBuffDesc())
            end
        end
    end
end

function UIWidgetPopStarStageInfo:_RefreshContentRT()
    if self._rtContent.sizeDelta.y < 488 then
        self._rtScrollView.sizeDelta = Vector2(self._rtScrollView.sizeDelta.x, self._rtContent.sizeDelta.y + 40)
    else
        self._rtScrollView.sizeDelta = Vector2(self._rtScrollView.sizeDelta.x, 528)
    end
end

function UIWidgetPopStarStageInfo:BtnCloseOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetPopStarStageInfo", input = "BtnCloseOnClick", args = {} }
    )

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            self._anim:Play("uieff_UIWidgetPopStarStageInfo_out")
            YIELD(TT, 500)
            self:SetCanvasShow(false)
        end
    )
end
