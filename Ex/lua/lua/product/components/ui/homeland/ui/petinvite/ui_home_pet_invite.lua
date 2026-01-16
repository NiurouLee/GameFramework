---@class UIHomePetInvite:UIController
_class("UIHomePetInvite", UIController)
UIHomePetInvite = UIHomePetInvite

function UIHomePetInvite:Constructor()
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    self._homelandClient = homeLandModule:GetClient()
    ---@type HomelandPetInviteManager
    self._inviteManager =  self._homelandClient:GetHomelandPetInviteManager()
    self._curSelectIndex = 1 --当前选中的交互点
end

function UIHomePetInvite:LoadDataOnEnter(TT, res, uiParams)
    self.firstIn = true
end 

function UIHomePetInvite:OnShow(uiParams)
    ---@type HomeBuilding
    self._building = uiParams[1]
    self._inviteItemId = uiParams[2]
    self:GetComponent()
    self:_AttachEvents()
end

function UIHomePetInvite:OnHide()
    self._preSelectedInvitePoint = nil
    self:_DetachEvents()
end

function UIHomePetInvite:GetComponent()
    self._atlas = self:GetAsset("UIHomelandInvite.spriteatlas", LoadType.SpriteAtlas)
    self._invitegroup = self:GetUIComponent("UISelectObjectPath","groups")
    self._rectTrans = self:GetUIComponent("RectTransform","groups")
    self._dynamicList = self:GetUIComponent("UIDynamicScrollView","caninvitepar")
   
    self._nonepet = self:GetGameObject("nonepet")
    self._nonepet2Go = self:GetGameObject("nonepet2")
    self._addGo = self:GetGameObject("add")
    self._nonepetGroup = self:GetUIComponent("UISelectObjectPath","nonepet")
    self._noneinvite = self:GetGameObject("noneinvite")

    self._titleText = self:GetUIComponent("UILocalizationText", "titleText")
    self._curinvitepetcountText = self:GetUIComponent("UILocalizationText", "curinvitepetcount")
    self._buttonState = self:GetUIComponent("Image", "buttonState")
    -- 绑点Id
    self._inviteItemId = 1 
    self._inviteManager:SetOperateBuilding(self._building, self._inviteItemId )
    self._isinit = false 
    self._uianimBoCG = self:GetUIComponent("CanvasGroup", "bottom")
    self._uianimInCG = self:GetUIComponent("CanvasGroup", "invitepar")
    self:RefreshUI()
    self:RefreshInvitePoint()
    self:PlayAni()
end

function  UIHomePetInvite:RefreshUI() 
    -- 状态变化
    self._buttonState.raycastTarget = false 
    self._buttonState.sprite =  self._atlas:GetSprite("N17_hudong_btn02")
    if self._inviteManager:HaveChange() then 
        self._buttonState.raycastTarget = true  
        self._buttonState.sprite =  self._atlas:GetSprite("N17_hudong_btn01")
    end 
    self:RefreshTitleInfo()
    self:RefreshInvitedGroup() 
    self:RefreshCanInvitedList() 

    self.firstIn = false 
end  

function  UIHomePetInvite:RefreshTitleInfo() 
    local cfg = Cfg.cfg_item_architecture[self._building:GetArchitecture().asset_id]
    self._titleText:SetText(StringTable.Get(cfg.Name))
end  

-- 当前交互的
function UIHomePetInvite:RefreshInvitedGroup() 
    local invitedList =  self._inviteManager:GetInvitedGroup()
    local countText = string.format("<color=#239bdb>%s</color><color=#737373>/%s</color>", 0, self._building:GetInteractingPetCountMax() )
    local cfg = self._building:GetCfg()
    local isSwimmingPool = false
    if cfg and cfg.ID == 5271001 then
        isSwimmingPool = true 
    end
    self._nonepet:SetActive(not isSwimmingPool)
    self._nonepet2Go:SetActive(isSwimmingPool)
    if invitedList == nil  or #invitedList == 0 then
        self._curinvitepetcountText:SetText(countText)
        if isSwimmingPool then
            self._addGo:SetActive(true)
            self._invitegroup:SpawnObjects("UIHomePetInviteItem",0)
        end
    else 
        local spawnCount = #invitedList
        countText = string.format("<color=#239bdb>%s</color><color=#737373>/%s</color>", spawnCount, self._building:GetInteractingPetCountMax())
        self._curinvitepetcountText:SetText (countText)
        if isSwimmingPool then
            self._addGo:SetActive(false)
            self._rectTrans.pivot = spawnCount <= 7 and Vector2(0.5, 1) or Vector2(0, 1)
            self._invitegroup:SpawnObjects("UIHomePetInviteItem",spawnCount)
            self._inviterItems  = self._invitegroup:GetAllSpawnList()
            for index, item in pairs( self._inviterItems) do
                local uiNode = self._inviterItems[index]
                uiNode:SetData(
                    index,
                    invitedList[index],
                    self._inviteManager,
                    self._atlas
                )
            end
        end
    end
end 

---刷新交互点信息
function UIHomePetInvite:RefreshInvitePoint()
    local allInvitePoints = self._building:GetAllInteractPointByType(InteractPointType.PetBuilding)
    local count = #allInvitePoints
    self._nonepet:SetActive(count > 0)
    self._nonepetGroup:SpawnObjects("UIHomePetInvitePoint", count)
    ---@type UIHomePetInvitePoint[]
    self._invitePointWidgets = self._nonepetGroup:GetAllSpawnList()
    for index, widget in ipairs(self._invitePointWidgets) do
        widget:SetData(
            self._inviteManager,
            index,
            allInvitePoints[index]:GetInteractObject(),
            function (widget)
                self:_OnSelectInvitePoint(widget)
            end
        )
    end
    self:DefaultSelect()
end

---@param widget UIHomePetInvitePoint
function UIHomePetInvite:_OnSelectInvitePoint(widget)
    if self._preSelectedInvitePoint ~= widget then
        if self._preSelectedInvitePoint then
            self._preSelectedInvitePoint:RefreshSelectImg(false)
        end
        self._preSelectedInvitePoint = widget
        self._curSelectIndex = widget:GetIndex()
        self:OnChangeInvitePoint(self._curSelectIndex)
    end
end

---点击备选列表中的光灵
---@param pet HomelandPet
function UIHomePetInvite:OnClickPet(pet)
    if self._invitePointWidgets then
        if self._invitePointWidgets[self._curSelectIndex] then
            self._invitePointWidgets[self._curSelectIndex]:SetPetInfo(pet)
            self._inviteManager:UpdateInvitedPets(self._curSelectIndex, pet)
            self:DefaultSelect()
        end
    end
end

---当前选中的交互点改变了之后刷新备选光灵，过滤掉无法交互的光灵,保留可以选中的光灵
---@param index number 当前选中的交互点索引
---@return boolean 该交互点是否限制指定光灵
---@return table 指定的哪些光灵
function UIHomePetInvite:OnChangeInvitePoint(index)
    local ids = {}
    local validCfgs = {} --可用的交互表现
    if self._building then
        local cfgBuilding = self._building:GetCfg()
        if cfgBuilding and cfgBuilding.Interaction then
            for _, value in pairs(cfgBuilding.Interaction) do
                local cfgBuildingPet = Cfg.cfg_homeland_building_pet[value]
                if cfgBuildingPet then
                    if cfgBuildingPet.InteractPointIndex then --绑定了交互点的交互表现
                        if table.icontains(cfgBuildingPet.InteractPointIndex, index) then
                            table.insert(validCfgs, cfgBuildingPet)
                        end
                    else
                        table.insert(validCfgs, cfgBuildingPet)
                    end
                end
            end
        end
    end
    if #validCfgs <= 0 then
        Log.error("该交互点没有可用的交互表现配置。", index)
    else
        for _, value in pairs(validCfgs) do
            if not value.petIDs then
                self._inviteManager:SetInteractPointLimit(false, nil)
                self._dynamicList:RefreshAllShownItem()
                return
            else
                for _, id in pairs(value.petIDs) do
                    table.insert(ids, id)
                end
            end
        end
    end
    self._inviteManager:SetInteractPointLimit(true, ids)
    self._dynamicList:RefreshAllShownItem()
end

--筛选默认选中的交互点
function UIHomePetInvite:DefaultSelect()
    if self._invitePointWidgets then
       for _, widget in ipairs(self._invitePointWidgets) do
            if not widget:GetPet() then
                widget:OnSelect()
                break
            end
       end
    end
end

-- 可交互的
function UIHomePetInvite:RefreshCanInvitedList() 
    -- test
    self._itemCountPerRow = 10
    self._canInviteList = self._inviteManager:GetNearInviteEnablePetList()
    self._dynamicListSize =  #self._canInviteList
    self._dynamicListRowSize = math.floor((self._dynamicListSize - 1) / self._itemCountPerRow + 1)
    
    if self._canInviteList ~= nil and #self._canInviteList > 0 then 
        self._noneinvite:SetActive(false)
        if not self._isinit then 
            self._dynamicList:InitListView(
                self._dynamicListRowSize,
                function(scrollView, index)
                    return self:_SpawnListItem(scrollView, index)
                end
            ) 
            self._isinit = true 
        else 
            self._dynamicList:SetListItemCount(math.ceil(#self._canInviteList/self._itemCountPerRow ))
            self._dynamicList:RefreshAllShownItem()
            self._dynamicList:MovePanelToItemIndex(0, 0)
        end 
    else 
        self._dynamicList:SetListItemCount(0)
        self._dynamicList:RefreshAllShownItem()
        self._noneinvite:SetActive(true)
    end 
end 

function UIHomePetInvite:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIHomePetInviteItemNear", self._itemCountPerRow)
    end
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._dynamicListSize then
            listItem:GetGameObject():SetActive(false)
        else
            listItem:GetGameObject():SetActive(true)
            self:_SetListItemData(listItem, itemIndex)
        end
    end
    return item
end

---@param listItem UIHomePetInviteItemNear
function UIHomePetInvite:_SetListItemData(listItem, index)
    listItem:SetData(
        index,
        self._canInviteList[index],
        self._inviteManager,
        self._atlas
    )
end

function UIHomePetInvite:_AttachEvents() 
    self:AttachEvent(GameEventType.OnPetInvitePreview,self.RefreshUI)
    self:AttachEvent(GameEventType.AfterUILayerChanged,self.PlayAni)
end 

function UIHomePetInvite:_DetachEvents()
    self:DetachEvent(GameEventType.OnPetInvitePreview,self.RefreshUI)
    self:DetachEvent(GameEventType.AfterUILayerChanged,self.PlayAni)
end

function UIHomePetInvite:BtnCloseOnClick(go)
    self._inviteManager:ClearCache()

    self.anim = self:GetUIComponent("Animation", "ani")
    self:StartTask(
        function(TT)
            local lockName = "UIHomePetInvite:BtnInviteOnClick"
            self:Lock(lockName)
            self.anim:Play("uieffanim_UIHomePetInvite_out")
            YIELD(TT,150)
            self:CloseDialog()
            self:UnLock(lockName)
        end,
        self
    ) 
 
end

function UIHomePetInvite:BtnInviteEnableOnClick(go)
    self:ShowDialog("UIHomePetInviteEnable",self._building,self._inviteItemId)
end

function UIHomePetInvite:BtnInviteOnClick(go)
    -- 发出邀请
    if not self._inviteManager:HaveChange() then 
        return 
    end 
    local tip = self._inviteManager:CheckOnSend()
    ToastManager.ShowHomeToast(StringTable.Get(tip))

    self._inviteManager:SetInvite()
    self:CloseDialog()
end

function UIHomePetInvite:PlayAni()
    self._uianimBoCG.alpha = 0
    self._uianimInCG.alpha = 0
    local anistr = self.firstIn and "uieffanim_UIHomePetInvite_show" or "uieffanim_UIHomePetInvite_in"
    self.anim = self:GetUIComponent("Animation", "ani")
    self:StartTask(
        function(TT)
            local lockName = "UIHomePetInvite:PlayAni"
            self:Lock(lockName)
            YIELD(TT)
            self.anim:Play(anistr)
            self:UnLock(lockName)
        end,
        self
    )
end



