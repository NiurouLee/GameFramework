--
---@class UISeasonHelperController : UIController
_class("UISeasonHelperController", UIController)
UISeasonHelperController = UISeasonHelperController

--初始化
function UISeasonHelperController:OnShow(uiParams)
    local tabIndex = 1
    if uiParams then
        if uiParams[1] then
            tabIndex = tonumber(uiParams[1])
        end
    end
    self:InitWidget(tabIndex)
    self:AddListener()
end
function UISeasonHelperController:OnHide()
end
--获取ui组件
function UISeasonHelperController:InitWidget(tabIndex)
    --generated--
    ---@type UICustomWidgetPool
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        nil,
        true
    )
    ---@type UICustomWidgetPool
    self._tabPool = self:GetUIComponent("UISelectObjectPath", "Content")
    --generated end--
    self:_InitTabList(tabIndex)
    self:_InitBanner(tabIndex)
    self._curTab = 1
    if tabIndex then
        self._curTab = tabIndex
    end
end
function UISeasonHelperController:AddListener()
end

----------------------
--滚动

function UISeasonHelperController:_InitBanner(tabIndex)
    local bannerGen = self:GetUIComponent("UISelectObjectPath", "BannerRoot")
    self._bannerWidget = bannerGen:SpawnObject("UISeasonHelperBanner")
    self._bannerWidget:SetData(tabIndex)
end
function UISeasonHelperController:OnUpdate(deltaTimeMS)
    if self._bannerWidget then
        self._bannerWidget:OnUpdate(deltaTimeMS)
    end
end
function UISeasonHelperController:_InitTabList(tabIndex)
    self._cfgTab = Cfg.cfg_season_helper_tab {}
    local tabCount = #self._cfgTab
    
    self._tabPool:SpawnObjects("UISeasonHelperTab", tabCount)
    ---@type table<number,UISeasonHelperTab>
    self._tabs = self._tabPool:GetAllSpawnList()
    for i, v in ipairs(self._cfgTab) do
        self._tabs[i]:SetData(v,function(tabId) self:OnTabClick(tabId) end)
    end
    for index, tab in ipairs(self._tabs) do
        tab:OnSelectIndex(tabIndex)
    end
end
function UISeasonHelperController:OnTabClick(tabId)
    if self._curTab ~= tabId then
        self._curTab = tabId
        self._bannerWidget:SetData(tabId)
        for index, tab in ipairs(self._tabs) do
            tab:OnSelectIndex(tabId)
        end
    end
end