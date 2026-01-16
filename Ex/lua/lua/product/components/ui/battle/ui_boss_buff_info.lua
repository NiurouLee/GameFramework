---@class UIBossBuffInfo : UICustomWidget
_class("UIBossBuffInfo", UICustomWidget)
UIBossBuffInfo = UIBossBuffInfo

function UIBossBuffInfo:OnShow()
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

    self:SetCanvasShow(false)

    self._maxCount = 5
end

function UIBossBuffInfo:OnHide()
end

function UIBossBuffInfo:Init(entityid, tplId, hpBarType)
    self._entityId = entityid
    self._tplId = tplId --怪物ID
    self._totalCount = 0

    local arr = {}

    --精英
    self._eliteIDArray = {}
    if hpBarType == HPBarType.EliteBoss or hpBarType == HPBarType.EliteMonster then
        -- ---@type MonsterConfigData
        -- local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
        -- self._eliteIDArray = monsterConfigData:GetEliteIDArray(tplId) or {}
        self._eliteIDArray = BattleStatHelper.GetEliteIDArray(entityid, tplId)
        -- self._eliteIDArray = {1001, 1002}
        table.appendArray(arr, self._eliteIDArray)
    end

    --buff
    self._buffArray = InnerGameHelperRender.GetUIBuffViewArray(entityid, false)
    table.appendArray(arr, self._buffArray)

    self._showArray = arr or {}
    self._totalCount = #self._showArray

    if self._totalCount == 0 then
        return
    end

    self._contentRect.anchoredPosition = Vector2(0, 0)

    self:SetCanvasShow(true)

    self:_InitListView()
    self._scrollView.gameObject:SetActive(true)

    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._contentRect)

    local scrollRectHeight = self._scrollRect.sizeDelta.y
    local contentRectHeight = self._contentRect.sizeDelta.y

    if contentRectHeight > scrollRectHeight then
        self._scrollView.enabled = true
    else
        self._scrollView.enabled = false
    end
end

function UIBossBuffInfo:SetCanvasShow(show)
    if self._canvasGroup then
        self._canvasGroup.alpha = show and 1 or 0
        self._canvasGroup.blocksRaycasts = show
    end
end

function UIBossBuffInfo:_InitListView()
    self._pool:SpawnObjects("UIBossBuffItem", self._totalCount)
    ---@type UIBossBuffItem[]
    local arr = self._pool:GetAllSpawnList()
    for idx, item in ipairs(arr) do
        local eliteCount = table.count(self._eliteIDArray)
        if idx <= eliteCount then
            item:InitElite(idx, self._eliteIDArray[idx])
        else
            item:InitBuff(idx, self._buffArray[idx - eliteCount])
        end
    end
end

function UIBossBuffInfo:buttonCloseOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBossBuffInfo", input = "buttonCloseOnClick", args = {} }
    )
    self:SetCanvasShow(false)
end
