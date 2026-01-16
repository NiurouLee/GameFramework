---@class UIMonsterPassiveInfo : UICustomWidget
_class("UIMonsterPassiveInfo", UICustomWidget)
UIMonsterPassiveInfo = UIMonsterPassiveInfo

function UIMonsterPassiveInfo:OnShow()
    ---@type UnityEngine.RectTransform
    self._rectTransform = self:GetGameObject():GetComponent("RectTransform")

    self.buttonClose = self:GetUIComponent("Button", "buttonClose")
    ---@type UnityEngine.UI.ScrollRect
    self._scrollView = self:GetUIComponent("ScrollRect", "ScrollView")
    self._scrollView.gameObject:SetActive(false)
    ---@type UICustomWidgetPool
    self._pool = self:GetUIComponent("UISelectObjectPath", "Content")
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "Canvas")

    self._contentRect = self:GetUIComponent("RectTransform", "Content")
    self._scrollRect = self:GetUIComponent("RectTransform", "ScrollView")
    ---@type UnityEngine.RectTransform
    self._viewportRect = self:GetUIComponent("RectTransform", "Viewport")
    ---@type UnityEngine.RectTransform
    --self._maskRect = self:GetUIComponent("RectTransform", "Mask")
    -----@type UnityEngine.RectTransform
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._contentRect)

    self:SetCanvasShow(false)

    self._maxCount = 4
end

function UIMonsterPassiveInfo:OnHide()
end

function UIMonsterPassiveInfo:Init(entityid, tplId)
    self._entityId = entityid
    self._tplId = tplId --怪物ID
    self._totalCount = 0
    self._passiveSkillInfos = {}

    ---@type MonsterConfigData
    local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
    local passiveSkillInfos = monsterConfigData:GetMonsterPassiveInfo(tplId)
    local hasPassiveSkillInfo = monsterConfigData:IsHasPassiveSkillInfo(tplId)
    if not hasPassiveSkillInfo then
        return
    end

    self._totalCount = #passiveSkillInfos
    self._passiveSkillInfos = passiveSkillInfos
    if self._totalCount == 0 then
        return
    end
    self._passiveSkillInfos = passiveSkillInfos
    --self._contentRect.anchoredPosition = Vector2(0, 0)

    self:SetCanvasShow(true)

    self:_InitListView()
    self._scrollView.gameObject:SetActive(true)

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._contentRect)
    ---刷两次不会闪
    if self._contentRect.sizeDelta.y< 488 then
        self._scrollRect.sizeDelta = Vector2(self._scrollRect.sizeDelta.x, self._contentRect.sizeDelta.y+40)
    else
        self._scrollRect.sizeDelta = Vector2(self._scrollRect.sizeDelta.x, 528)
    end
    GameGlobal.TaskManager():CoreGameStartTask(function(TT)
        YIELD(TT)
        if self._contentRect.sizeDelta.y< 488 then
            self._scrollRect.sizeDelta = Vector2(self._scrollRect.sizeDelta.x, self._contentRect.sizeDelta.y+40)
        else
            self._scrollRect.sizeDelta = Vector2(self._scrollRect.sizeDelta.x, 528)
        end
    end )
end

function UIMonsterPassiveInfo:SetCanvasShow(show)
    if self._canvasGroup then
        self._canvasGroup.alpha = show and 1 or 0
        self._canvasGroup.blocksRaycasts = show
    end
end

function UIMonsterPassiveInfo:_InitListView()
    if self._totalCount == 0 then
        return
    end
    ---@type UIMonsterPassiveInfoItem[]
    local arr = self._pool:SpawnObjects("UIMonsterPassiveInfoItem", self._totalCount)

    --local arr = self._pool:GetAllSpawnList()
    for idx, item in ipairs(arr) do
        local infos =self._passiveSkillInfos[idx]
        if infos then
            --item:Enable(true)
            item:Init(infos.type,infos.skillName,infos.skillDesc)
        else
            --item:Enable(false)
        end
    end
end

function UIMonsterPassiveInfo:buttonCloseOnClick()
    GameGlobal.GameRecorder():RecordAction(
            GameRecordAction.UIInput,
            {ui = "UIMonsterPassiveInfo", input = "buttonCloseOnClick", args = {}}
    )
    self:SetCanvasShow(false)
end
