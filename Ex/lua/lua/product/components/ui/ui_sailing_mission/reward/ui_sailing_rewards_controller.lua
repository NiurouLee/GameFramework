--
---@class UISailingRewardsController : UIController
_class("UISailingRewardsController", UIController)
UISailingRewardsController = UISailingRewardsController

---@param res AsyncRequestRes
function UISailingRewardsController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end
--初始化
function UISailingRewardsController:OnShow(uiParams)
    self:InitWidget()
    self:_InitScrollPos()
    self:AddListener()
end
function UISailingRewardsController:OnHide()
    self._matRes = {}
end
--获取ui组件
function UISailingRewardsController:InitWidget()
    ---@type SailingMissionModule
    self._module = self:GetModule(SailingMissionModule)
    self._petModule = self:GetModule(PetModule)
    self._curSelectedCfgID = -1

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
        false
    )
    ---@type UICustomWidgetPool
    --local s = self:GetUIComponent("UISelectObjectPath", "_itemInfo")
    ---@type UISelectInfo
    --self._tips = s:SpawnObject("UISelectInfo")
    ---@type UnityEngine.GameObject
    self.uISailingRewardsController = self:GetGameObject("UISailingRewardsController")

    ---@type UIDynamicScrollView
    self._rewardList = self:GetUIComponent("UIDynamicScrollView", "RewardsListView")
    self._rewardListRect = self:GetUIComponent("RectTransform", "RewardsListView")
    ---@type UnityEngine.RectTransform
    self._rewardContentRect = self:GetUIComponent("RectTransform", "Content")
    self._scrollRect = self:GetUIComponent("ScrollRect", "RewardsListView")
    self._scrollRect.onValueChanged:AddListener(
        function()
            self:OnScrollRectChange()
        end
    )
    ---@type UnityEngine.RectTransform
    self._rewardViewportRect = self:GetUIComponent("RectTransform", "Viewport")
    ---@type UnityEngine.UI.Button
    self._collectAllBtn = self:GetUIComponent("Button", "CollectAllRewardsBtn")
    self._rewardsTitleTmp = self:GetUIComponent("UILocalizedTMP", "RewardsTitle")
    self._matRes = {}
    self:SetFontMat( self._rewardsTitleTmp ,"sailing_reward_title_mat.mat") 
    self._moreTipsGo = self:GetGameObject("MoreTipsArea")
    self._moreTipsGo:SetActive(false)
    self._isMoreTipsShowing = false
    self._moreTipsAreaOffSet = 120

    --generated end--
    self:_InitData()
    self:_InitRewardList()
    self:_InitBanner()
    self:CheckCollectAllRewardsBtnState()
end
function UISailingRewardsController:SetFontMat(lable,resname) 
    local res  = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    table.insert(self._matRes ,res)
    if not res  then 
        return 
    end 
    local obj  = res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end 
function UISailingRewardsController:OnScrollRectChange()
    if self._totalShowCount then
        local cellHeight = 101 + 10 --高度加间距
        local curY = self._rewardContentRect.localPosition.y
        --local showAreaHeight = self._rewardViewportRect.sizeDelta.y
        local showAreaHeight = self._rewardViewportRect.rect.height
        --local totalHeight = self._totalShowCount * cellHeight - 50
        local totalHeight = self._rewardContentRect.sizeDelta.y - 50
        
        if (showAreaHeight + curY) >= totalHeight then
            self:_ShowMoreTips(true)
        else
            self:_ShowMoreTips(false)
        end
    end
end
function UISailingRewardsController:_ShowMoreTips(bShow)
    if self._hasMoreCell then
        if self._isMoreTipsShowing ~= bShow then
            self._isMoreTipsShowing = bShow
            self._moreTipsGo:SetActive(bShow)
        end
    end
end
function UISailingRewardsController:AddListener()
    self:AttachEvent(GameEventType.SailingOnProgressRewardCellSelect, self.OnSailingOnProgressRewardCellSelect)
    self:AttachEvent(GameEventType.OnUIGetItemCloseInQuest, self.OnUIGetItemCloseInQuest)--UIActivityHelper.ShowUIGetRewards 结束后会发这个
    self:AttachEvent(GameEventType.SailingOnProgressRewardBannerClick, self.OnSailingOnProgressRewardBannerClick)--UIActivityHelper.ShowUIGetRewards 结束后会发这个
end
function UISailingRewardsController:_InitScrollPos()
    local firstItemIndex = self:_GetFirstShowItemIndex()
    if firstItemIndex < 0 then
        firstItemIndex = 0
    end
    self:_MoveScrollToItemIndex(firstItemIndex)
end
function UISailingRewardsController:_MoveScrollToItemIndex(itemIndex)
    self._rewardList:MovePanelToItemIndex(itemIndex, 0)
    self._rewardList:FinishSnapImmediately()
end
function UISailingRewardsController:_GetFirstShowItemIndex()
    local cellIndex = 1
    local canReceiveIndex = -1
    local lastReceivedIndex = -1
    for index, value in ipairs(self._data.cells) do
        ---@type DSailingProgressRewardsCell
        if value:CanReceive() then
            canReceiveIndex = index
            break
        elseif value:IsReceived() then
            lastReceivedIndex = index
        end
    end
    if canReceiveIndex > 0 then
        cellIndex = canReceiveIndex
    elseif lastReceivedIndex > 0 then
        cellIndex = lastReceivedIndex
    end
    return cellIndex - 1
end
function UISailingRewardsController:_GetItemIndexByCfgID(cfgID)
    local cellIndex = 1
    for index, value in ipairs(self._data.cells) do
        ---@type DSailingProgressRewardsCell
        if value._cfgID == cfgID then
            cellIndex = index
            break
        end
    end
    return cellIndex - 1
end
function UISailingRewardsController:ShowItemInfo(matid, pos)
    --self._tips:SetData(matid, pos)
    local showPet = true
    UIWidgetHelper.SetAwardItemTips(self, "_itemInfo", matid, pos,showPet)
end
function UISailingRewardsController:CheckCollectAllRewardsBtnState()
    local cfgIDList = {}
    local cfgs = Cfg.cfg_sailing_reward{}
    local progress = self._module:GetHistoryProgress()
    local receivedRewardList = self._module:GetReceivedReward()
    local dicReceivedReward = {}
    for _, v in ipairs(receivedRewardList) do
        dicReceivedReward[v] = v
    end
    for cfgID, v in ipairs(cfgs) do
        if progress >= v.ExplorationProgress and dicReceivedReward[v.ID] == nil then
            table.insert(cfgIDList,cfgID)
        end
    end
    if #cfgIDList > 0 then
        self._collectAllBtn.interactable = true
    else
        self._collectAllBtn.interactable = false
    end
end
function UISailingRewardsController:CollectAllRewardsBtnOnClick(go)
    local cfgIDList = {}
    local cfgs = Cfg.cfg_sailing_reward{}
    local progress = self._module:GetHistoryProgress()
    local receivedRewardList = self._module:GetReceivedReward()
    local dicReceivedReward = {}
    for _, v in ipairs(receivedRewardList) do
        dicReceivedReward[v] = v
    end
    for cfgID, v in ipairs(cfgs) do
        if progress >= v.ExplorationProgress and dicReceivedReward[v.ID] == nil then
            table.insert(cfgIDList,cfgID)
        end
    end
    if #cfgIDList > 0 then
        self:GetReward(cfgIDList)
    else
    end
end
function UISailingRewardsController:_CalcTotalShowCount()
    --显示条数
    local totalShowCount = 0
    local chapterID = self._module:GetChallengeLayerID()
    local allChapter = Cfg.cfg_sailing_layer{}
    for k, v in pairs(allChapter) do
        if v.ID <= chapterID then
            local cfgMissionList = v.SailingMissionList
            local countMission = #cfgMissionList
            totalShowCount = totalShowCount + countMission
        end
    end
    local extraCellCount = 0
    local customCfg = Cfg.cfg_sailing_reward_custom[1]
    if customCfg then
        if customCfg.ExtraCellCount then
            extraCellCount = customCfg.ExtraCellCount
        end
    end
    totalShowCount = totalShowCount + extraCellCount
    return totalShowCount
end
function UISailingRewardsController:_InitData()
    self._data = {}
    self._data.cells = {}
    if self._module then
        self._totalShowCount = self:_CalcTotalShowCount()
        local cfgs = Cfg.cfg_sailing_reward{}
        local progress = self._module:GetHistoryProgress()
        local receivedRewardList = self._module:GetReceivedReward()
        local dicReceivedReward = {}
        for _, v in ipairs(receivedRewardList) do
            dicReceivedReward[v] = v
        end
        for index, v in ipairs(cfgs) do
            if index > self._totalShowCount then
                self._hasMoreCell = true
                break
            end
            local state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
            if progress >= v.ExplorationProgress then
                if dicReceivedReward[v.ID] == nil then
                    --已解锁 未领取
                    state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV
                else
                    --已领取
                    state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED
                end
            else
                --未解锁
                state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
            end
            local isSpecial = false
            if v.IsSpecial and (v.IsSpecial == 1) then
                isSpecial = true
            end
            local cellData = DSailingProgressRewardsCell:New()
            cellData._state = state
            cellData._isSpecial = isSpecial
            cellData._progressNum = v.ExplorationProgress
            cellData._cfgID = v.ID
            cellData._items = {}
            for rewardIndex, rewardValue in ipairs(v.Rewards) do
                local itemInfo = RoleAsset:New()
                itemInfo.assetid = rewardValue[1]
                itemInfo.count = rewardValue[2]
                table.insert(cellData._items, itemInfo)
            end
            table.insert(self._data.cells, cellData)
        end
        table.sort(
            self._data.cells,
            function(e1, e2)
                return e1._progressNum < e2._progressNum
            end
        )
    end
end
--领奖后刷新data中的state
function UISailingRewardsController:_RefreshDataState()
    local progress = self._module:GetHistoryProgress()
    local receivedRewardList = self._module:GetReceivedReward()
    local dicReceivedReward = {}
    for _, v in ipairs(receivedRewardList) do
        dicReceivedReward[v] = v
    end
    if self._data and self._data.cells then
        local cellsData = self._data.cells
        for i,cellData in ipairs(cellsData) do
            local state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
            if progress >= cellData._progressNum then
                if dicReceivedReward[cellData._cfgID] == nil then
                    --已解锁 未领取
                    state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_CAN_RECV
                else
                    --已领取
                    state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_RECVED
                end
            else
                --未解锁
                state = ECumulativeLoginRewardStatus.E_CUMULATIVE_LOGIN_REWARD_LOCK
            end
            cellData._state = state
        end
    end
end
function UISailingRewardsController:_InitRewardList()
    self._rewardList:InitListView(
        #self._data.cells,
        function(scrollview, index)
            return self:_OnGetRewardCell(scrollview, index)
        end
    )
    if self._hasMoreCell then
        local curSize = self._rewardViewportRect.sizeDelta
        self._rewardViewportRect.sizeDelta = Vector2(curSize.x,curSize.y - self._moreTipsAreaOffSet)
    end
end
function UISailingRewardsController:_OnGetRewardCell(scrollview, index)
    local item = scrollview:NewListViewItem("CellItem")
    local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        cellPool:SpawnObjects("UISailingProgressRewardsCell", 1)
    end
    local rowList = cellPool:GetAllSpawnList()
    local itemWidget = rowList[1]
    ---@type UISailingProgressRewardsCell
    if itemWidget then
        local itemIndex = index + 1
        ---@type UISailingProgressRewardsCell
        local cellData = self._data.cells[itemIndex]
        itemWidget:InitData(
            cellData,
            self._cfg_cell_data,
            function(matid, pos)
                self:ShowItemInfo(matid, pos)
            end,
            function(cfgIDList)
                self:GetReward(cfgIDList)
            end
        )
        if cellData and cellData._cfgID == self._curSelectedCfgID then
            itemWidget:SetSelected(true)
        else
            itemWidget:SetSelected(false)
        end
        if itemIndex > #self._data.cells then
            itemWidget:GetGameObject():SetActive(false)
        else
        end
    end
    --UIHelper.RefreshLayout(item:GetComponent("RectTransform"))
    return item
end
function UISailingRewardsController:OnSailingOnProgressRewardCellSelect(cfgID)
    self._curSelectedCfgID = cfgID
end
function UISailingRewardsController:OnSailingOnProgressRewardBannerClick(cfgID)
    --定位列表
    local tarItemIndex = self:_GetItemIndexByCfgID(cfgID)
    if tarItemIndex < 0 then
        tarItemIndex = 0
    end
    self:_MoveScrollToItemIndex(tarItemIndex)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SailingOnProgressRewardCellSelect, cfgID)
end
function UISailingRewardsController:GetReward(cfgIDList)
    self:Lock("UISailingRewardsController:GetReward")
    self:StartTask(self.OnGetReward, self, cfgIDList)
end
function UISailingRewardsController:OnGetReward(TT, cfgIDList)
    if self._module then
        local asyncRes,rewards = self._module:HandleReceiveRewards(TT,cfgIDList)
        self:UnLock("UISailingRewardsController:GetReward")
        if asyncRes == nil then
            return
        end
        if asyncRes:GetSucc() then
            if rewards ~= nil then
                if #rewards > 0 then
                    self:_ShowRewards(rewards, cfgIDList)
                end
            end
        else
            Log.info("UISailingRewardsController getReward fail")
        end
        self:_RefreshDataState()
        self:CheckCollectAllRewardsBtnState()
        --self:_InitScrollPos()
    end
end
function UISailingRewardsController:_ShowRewards(awards, cfgIDList)
    UIActivityHelper.ShowUIGetRewards(awards)
    self._waitRefreshGetRewards = cfgIDList
    --GameGlobal.EventDispatcher():Dispatch(GameEventType.SailingGetProgressReward, cfgIDList)
end
function UISailingRewardsController:OnUIGetItemCloseInQuest(type)
    self:_RefreshOnGetReward()
    if self._waitRefreshGetRewards then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.SailingGetProgressReward, self._waitRefreshGetRewards)
        self._waitRefreshGetRewards = nil
    end
end
function UISailingRewardsController:_RefreshOnGetReward()
end

----------------------
--滚动

function UISailingRewardsController:_InitBanner()
    local bannerGen = self:GetUIComponent("UISelectObjectPath", "BannerRoot")
    self._bannerWidget = bannerGen:SpawnObject("UISailingRewardBanner")
    self._bannerWidget:SetData()
end
function UISailingRewardsController:OnUpdate(deltaTimeMS)
    if self._bannerWidget then
        self._bannerWidget:OnUpdate(deltaTimeMS)
    end
end