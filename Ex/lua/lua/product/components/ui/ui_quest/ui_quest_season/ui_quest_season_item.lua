---@class UIQuestSeasonItem:UICustomWidget
_class("UIQuestSeasonItem", UICustomWidget)
UIQuestSeasonItem = UIQuestSeasonItem

function UIQuestSeasonItem:OnShow(uiParams)
    ---@type ATransitionComponent
    self._transition = self:GetUIComponent("ATransitionComponent", "UIQuestSeasonItem")
    ---@type UnityEngine.CanvasGroup
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "UIQuestSeasonItem")
    self._canvasGroup.blocksRaycasts = false

    self._seasonName = self:GetUIComponent("UILocalizationText","seasonName")

    self._rect = self:GetUIComponent("UISelectObjectPath","rect")
end
function UIQuestSeasonItem:RefrenshList()
    -- body
end
function UIQuestSeasonItem:AnimatedListIntro()
end

function UIQuestSeasonItem:OnClose()
    self._transition:PlayLeaveAnimation(true)
    self._canvasGroup.blocksRaycasts = false
    if self._seasonQuest then
        self._seasonQuest:SetResponseEvent(false)
    end
end

function UIQuestSeasonItem:SetData()
    self._transition:PlayEnterAnimation(true)
    self._canvasGroup.blocksRaycasts = true
    self:_GetComponents()

    if not self._seasonQuest then
        local className, prefabName = GameGlobal.GetUIModule(SeasonModule):GetCurSeasonQuestContent()
        if not string.isnullorempty(className) then
            self._seasonQuest = UIWidgetHelper.SpawnObject(self, "rect", className, prefabName)
        end
    end
    if self._seasonQuest then
        self._seasonQuest:SetData()
        self._seasonQuest:SetResponseEvent(true)
    end

    -- local sample = GameGlobal.GetUIModule(SeasonModule):curr
    self._seasonName:SetText(StringTable.Get("str_season_title_8001"))
end

function UIQuestSeasonItem:OnHide()
end

function UIQuestSeasonItem:_GetComponents()
end

function UIQuestSeasonItem:EnterBtnOnClick(go)
    GameGlobal.GetUIModule(SeasonModule):OpenSeasonThemeUI()
end