---@class UISeasonQuestController : UIController
_class("UISeasonQuestController", UIController)
UISeasonQuestController = UISeasonQuestController

--- 用来为 Side Enter Center 活动中心中加载的活动内容Content 独立显示的窗口
function UISeasonQuestController:LoadDataOnEnter(TT, res, uiParams)
    ---@type SeasonModule
    self._seasonModule = GameGlobal.GetModule(SeasonModule)
    res = self._seasonModule:ForceRequestCurSeasonData(TT)

    ---@type CampaignQuestComponent
    local component = self._seasonModule:GetCurSeasonQuestComponent()
    local isOpen = component and component:ComponentIsOpen()
    if not isOpen then
        res:SetSucc(false)
    end

    self._seasonId = self._seasonModule:GetCurSeasonID()
end

function UISeasonQuestController:OnShow(uiParams)
    self:_SetCommonTopButton()

    local className, prefabName = GameGlobal.GetUIModule(SeasonModule):GetCurSeasonQuestContent()
    if not string.isnullorempty(className) then
        local closeFunc = function()
            self:CloseDialog()
        end
        local obj = UIWidgetHelper.SpawnObject(self, "_pool", className, prefabName)
        obj:SetData({ ownerName = self:GetName(), closeCallback = closeFunc })
        self._content = obj
    end
    
    self:AddListener()
end

function UISeasonQuestController:OnHide()
    self:DetachListener()
end

function UISeasonQuestController:_SetCommonTopButton()
    ---@type UICommonTopButton
    local obj = UIWidgetHelper.SpawnObject(self, "_backBtns", "UICommonTopButton")
    obj:SetData(
        function()
            if self._content then
                self._content:_PlayAnim(3, function()
                    self:CloseDialog()
                end)
            else
                self:CloseDialog()
            end
        end,
        function()
            UISeasonHelper.ShowSeasonHelperBook(UISeasonHelperTabIndex.Quest)
        end,
        nil,
        false
    )
end

function UISeasonQuestController:AddListener()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
end

function UISeasonQuestController:DetachListener()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self.OnActivityCloseEvent)
end

function UISeasonQuestController:OnActivityCloseEvent(id)
    if self._seasonId and self._seasonId == id then
       self:CloseDialog()
    end
end
