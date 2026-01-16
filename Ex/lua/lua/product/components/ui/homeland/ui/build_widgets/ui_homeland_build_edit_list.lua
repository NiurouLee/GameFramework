-- 列表类别
--- @class BuildEditListType
local BuildEditListType = {
    BT_Default = 1,       --默认建造
    BT_MakeMovie = 2,    --拍电影建造
}
_enum("BuildEditListType", BuildEditListType)


---@class UIHomelandBuildEditList:UICustomWidget
_class("UIHomelandBuildEditList", UICustomWidget)
UIHomelandBuildEditList = UIHomelandBuildEditList

function UIHomelandBuildEditList:Constructor()
    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
    ---@type HomelandClient
    self.homelandClient = self.mUIHomeland:GetClient()
    ---@type HomeBuildManager
    self.homeBuildManager = self.homelandClient:BuildManager()
    self.mItem = GameGlobal.GetModule(ItemModule)

    ---@type Item[]
    self.list = {} --筛选后的建筑道具集合

    self.curFilterId = 0 --当前打开的一级页签
    self.curFilterChildId = 100 --当前打开的二级页签
    self.doDragBuildingIntoScene = false

    ---@type table<number, boolean>
    self.newFilters = {} --当前需要显示new的页签
    self.allFilterID = 100 --"全部"页签ID

    ---缓存
    ---@type table<number, number>
    self._tplIDSubTypeCache = {} --todo:liws-

    ---@type table<number, number>
    self.filterID2SubType = {}
    self.filterID2SubType[UIHomelandBuildEdit.MainBuildingFilterID] = ArchitectureSubType.White_Tower
    self.filterID2SubType[UIHomelandBuildEdit.MuseumFilterID] = ArchitectureSubType.Museum
    self.filterID2SubType[UIHomelandBuildEdit.ShopFilterID] = ArchitectureSubType.Shop
    self.filterID2SubType[UIHomelandBuildEdit.WishingPoolFilterID] = ArchitectureSubType.Wishing_Pool
end

function UIHomelandBuildEditList:OnShow(uiParam)

    self.arrange = self:GetGameObject("arrange")
    self.noItem = self:GetGameObject("noItem")

    self.goList = self:GetGameObject("goList")
    ---@type UnityEngine.RectTransform
    self.rectList = self:GetUIComponent("RectTransform", "goList")
    ---@type UICustomWidgetPool
    self.tabs1 = self:GetUIComponent("UISelectObjectPath", "tabs1")
    ---@type UICustomWidgetPool
    self.tabs2 = self:GetUIComponent("UISelectObjectPath", "tabs2")
    self.goDragItem = self:GetGameObject("dragItem")
    self.goDragItem:SetActive(false)
    ---@type UICustomWidgetPool
    self.poolDragItem = self:GetUIComponent("UISelectObjectPath", "dragItem")
    ---@type UnityEngine.RectTransform
    self.dragItem = self:GetUIComponent("RectTransform", "dragItem")

    self:AttachEvent(GameEventType.HomelandBuildFilterTab1, self.HomelandBuildFilterTab1)
    self:AttachEvent(GameEventType.HomelandBuildFilterTab2, self.HomelandBuildFilterTab2)
    self:AttachEvent(GameEventType.HomelandRefreshBuildFilterNew, self.OnItemNewClear)
    self:AttachEvent(GameEventType.HomelandShowHideDragItem, self.HomelandShowHideDragItem)
    self:AttachEvent(GameEventType.DragBuildingIntoScene, self.DragBuildingIntoScene)

   -- self:HomeBuildOnSelectBuilding()
   -- self:OnOpenRotate(false)
end

---@param listType BuildEditListType
function UIHomelandBuildEditList:Init(camera, listType)
    if self._isInit then
        return
    end
    self._isInit = true
    self.listType = listType
    self.camera = camera

    if self.listType == BuildEditListType.BT_MakeMovie then
        local fatherBuild = MoviePrepareData:GetInstance():GetFatherBuild()
        local fatherBuildId = fatherBuild:GetBuildId()
        local cfg = Cfg.cfg_item_father_architecture[fatherBuildId]
        if cfg then
            self._freeAreaBlackList = cfg.FreeAreaBlackList
        else
            self._freeAreaBlackList = {}
        end
    end

    ---@type UnityEngine.UI.ScrollRect
    self._sr = self:GetUIComponent("ScrollRect", "sv")
    ---@param ui UIHomelandBuildEditItem
    self._svHelper =
        H3DScrollViewHelper:New(
        self,
        "sv",
        "UIHomelandBuildEditItem",
        function(index, ui)
            ui:Init(self.camera, self.listType)
            ui:SetDragItem(self.goDragItem, self.poolDragItem, self.dragItem)
            local itemId = self.list[index]:GetTemplateID()
            local isBlack = self:IsBuildItemInFreeAreaBlack(itemId)
            ui:Flush(itemId, isBlack)
            return ui
        end,
        nil,
        nil
    )
    self._svHelper:SetCalcScale(false)
    self._svHelper:SetEndSnappingCallback(nil)
    self._svHelper:SetItemPassSnapPosCallback(nil)
end


function UIHomelandBuildEditList:OnHide()
    self._svHelper:Dispose()
    self:DetachEvent(GameEventType.HomelandBuildFilterTab1, self.HomelandBuildFilterTab1)
    self:DetachEvent(GameEventType.HomelandBuildFilterTab2, self.HomelandBuildFilterTab2)
    self:DetachEvent(GameEventType.HomelandRefreshBuildFilterNew, self.OnItemNewClear)
    self:DetachEvent(GameEventType.HomelandShowHideDragItem, self.HomelandShowHideDragItem)
    self:DetachEvent(GameEventType.DragBuildingIntoScene, self.DragBuildingIntoScene)
end

function UIHomelandBuildEditList:FlushArrange()
    self:FlushTabNews()
    self:FlushTabs1()
    self:FlushTabs2()
    self:FlushList()
end

function UIHomelandBuildEditList:OnItemNewClear()
    self:FlushTabNews()

    local filters = UIHomelandBuildEdit.GetBuildFilters()
    ---@type UIHomelandBuildEditTab1[]
    local uis = self.tabs1:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = filters[i]
        if item then
            ui:SetNew(self.newFilters[item.id])
        end
    end

    local filter = UIHomelandBuildEdit.GetBuildFilterById(self.curFilterId)
    ---@type UIHomelandBuildEditTab2[]
    local uis = self.tabs2:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = filter.children[i]
        if item then
            ui:SetNew(self.newFilters[item.id])
        end
    end
end

function UIHomelandBuildEditList:FlushTabNews()
    self.newFilters = {}

    local listAll = self.mItem:GetItemListBySubType(ItemSubType.ItemSubType_Architecture)
    for _, item in ipairs(listAll) do
        local tplId = item:GetTemplateID()
        if UIHomelandBuildEdit.CanBuildingMove(tplId) and self.homeBuildManager:GetBuildCount(tplId) > 0 then
            if item:IsNewOverlay() then
                local filter = UIHomelandBuildEdit.GetBuildingFilter(tplId)
                if not filter then
                    Log.exception("建筑" .. tplId .. "缺少Filter配置")
                end
                for _, filterID in ipairs(filter) do
                    self.newFilters[filterID] = true
                end
            end
        end
    end

    local parentFilters = {}
    for filter, _ in pairs(self.newFilters) do
        local cfgFilter = Cfg.cfg_homeland_filter {Filter = filter}
        if cfgFilter and #cfgFilter > 0 and cfgFilter[1].Parent then
            parentFilters[cfgFilter[1].Parent] = true
        else
            local parentBuildingCfg = Cfg.cfg_item_father_architecture[filter]
            if parentBuildingCfg then
                parentFilters[UIHomelandBuildEdit.CompositeBuildingID] = true
            end
        end
    end
    table.append(self.newFilters, parentFilters)
end

function UIHomelandBuildEditList:FlushTabs1()
    --data
    local filters = UIHomelandBuildEdit.GetBuildFilters()
    --ui
    local len = table.count(filters)
    self.tabs1:SpawnObjects("UIHomelandBuildEditTab1", len)
    ---@type UIHomelandBuildEditTab1[]
    local uis = self.tabs1:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = filters[i]
        if item then
            ui:Flush(item.id)
            ui:SetNew(self.newFilters[item.id])
            ui:ShowHideFilter(self.curFilterId)
            if item.id == 4 then
                self._specialTag = ui
            end
        end
    end
end
function UIHomelandBuildEditList:FlushTabs2()
    local filter = UIHomelandBuildEdit.GetBuildFilterById(self.curFilterId)
    local len = table.count(filter.children)
    self.tabs2:SpawnObjects("UIHomelandBuildEditTab2", len)
    ---@type UIHomelandBuildEditTab2[]
    local uis = self.tabs2:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local item = filter.children[i]
        if item then
            ui:Flush(filter.id, item.id, self.filterID2SubType)
            ui:SetNew(self.newFilters[item.id])
            ui:HomelandBuildFilterTab2(self.curFilterId, self.curFilterChildId)
            if item.id == 403 then
                self._specialLand = ui
            end
        end
    end
end
function UIHomelandBuildEditList:FlushList()
    if self.curFilterId == self.ChangeSkinFilterID then
        self.noItem:SetActive(false)
       -- self:FlushSkins()
        return
    end

    local listAll = self.mItem:GetItemListBySubType(ItemSubType.ItemSubType_Architecture)
    self.list = {}
    local parentList = {}
    --筛选
    for _, item in ipairs(listAll) do
        local tplId = item:GetTemplateID()
        local isParent = self:GetSubType(tplId) == ArchitectureSubType.Father_Architecture
        --可摆放数量大于0并且是可摆放建筑
        if (isParent or self.homeBuildManager:GetBuildCount(tplId) > 0) and UIHomelandBuildEdit.CanBuildingMove(tplId) then
            local filter = UIHomelandBuildEdit.GetBuildingFilter(tplId)
            for _, filterID in ipairs(filter) do
                if filterID == self.curFilterChildId or self.curFilterChildId == self.allFilterID then --筛选标记
                    if isParent and self.curFilterChildId ~= self.allFilterID then
                        table.insert(parentList, item)
                    else
                        table.insert(self.list, item)
                    end
                    break
                end
            end
        end
    end

    --排序
    table.sort(
        self.list,
        ---@param a Item
        ---@param b Item
        function(a, b)
            local aNew = a:IsNewOverlay()
            local bNew = b:IsNewOverlay()
            if aNew and not bNew then
                return true
            elseif not aNew and bNew then
                return false
            end
            local ta = a:GetTemplate()
            local tb = b:GetTemplate()
            if ta.BagSortIndex == tb.BagSortIndex then
                return ta.ID < tb.ID
            end
            return ta.BagSortIndex > tb.BagSortIndex
        end
    )

    for _, item in ipairs(parentList) do
        table.insert(self.list, 1, item)
    end
    self._firstItem = nil
    self._svHelper:Dispose()
    self._svHelper:SetItemName("UIHomelandBuildEditItem")
    self._svHelper:SetShowFunction(
        function(index, ui)
            ui:Init(self.camera, self.listType)
            ui:SetDragItem(self.goDragItem, self.poolDragItem, self.dragItem)
            local itemId = self.list[index]:GetTemplateID()
            local isBlack = self:IsBuildItemInFreeAreaBlack(itemId)
            ui:Flush(itemId, isBlack)
            if not self._firstItem then
                self._firstItem = ui
            end
            return ui
        end
    )
    local len = table.count(self.list)
    self._svHelper:Init(len, 0, Vector2(0, 0))
    self._sr.horizontalNormalizedPosition = 0
    self.noItem:SetActive(len == 0)
end

function UIHomelandBuildEditList:GetSubType(tplID)
    if self._tplIDSubTypeCache[tplID] then
        return self._tplIDSubTypeCache[tplID]
    end

    local cfg = Cfg.cfg_item_architecture[tplID]
    if not cfg then
        return
    end

    self._tplIDSubTypeCache[tplID] = cfg.SubType
    return cfg.SubType
end


function UIHomelandBuildEditList:HomelandBuildFilterTab1(id)
    if self.curFilterId == id then
        return
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    if self._needSave then
        self:ConfirmExitChangeSkinMode(
            function()
                self.curFilterId = id
                local filter = UIHomelandBuildEdit.GetBuildFilterById(self.curFilterId)
                self.curFilterChildId = filter.children[1].id
                self:FlushTabs2()
                self:FlushList()
            end
        )
        return
    end
    self.curFilterId = id
    local filter = UIHomelandBuildEdit.GetBuildFilterById(self.curFilterId)

    self.curFilterChildId = filter.children[1].id
    self:FlushTabs2()
    self:FlushList()
end

function UIHomelandBuildEditList:HomelandBuildFilterTab2(id, childId)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundSwitch)
    if self._needSave then
        self:ConfirmExitChangeSkinMode(
            function()
                self.curFilterId = id
                self.curFilterChildId = childId
                self:FlushList()
            end
        )
        return
    end
    self.curFilterId = id
    self.curFilterChildId = childId
    self:FlushList()
end

function UIHomelandBuildEditList:HomelandShowHideDragItem(isShow)
    self.doDragBuildingIntoScene = false
end

function UIHomelandBuildEditList:DragBuildingIntoScene(buildingId, pointerId, pos)
    local cfg = Cfg.cfg_item_architecture[buildingId]
    if cfg.SubType == ArchitectureSubType.Father_Architecture and self.homeBuildManager:GetBuildCount(buildingId) <= 0 then
        return
    end

    if not self.doDragBuildingIntoScene and pos.y > self.rectList.rect.height then
        self.doDragBuildingIntoScene = true
        self.goDragItem:SetActive(false)
        if self._uiWidgetBuildCtrl then
            self._uiWidgetBuildCtrl:DragBuildingIntoScene(buildingId, pointerId)
        end
    end
end

function UIHomelandBuildEditList:SetUIWidgetHomelandBuildController(uiWidgetBuildCtrl)
    self._uiWidgetBuildCtrl = uiWidgetBuildCtrl
end

--region 组合建筑
function UIHomelandBuildEditList:FlushCompositeBuilding()
    local parentBuildingCfg = Cfg.cfg_item_father_architecture {}
    for _, cfg in pairs(parentBuildingCfg) do
        -- body
    end

    local buildingID = buildCfg[1].ID
    ---@type table<number, HomeBuilding>
    local buildings = self.homeBuildManager:GetBuildings()
    local curBuilding = nil
    for i = 1, #buildings do
        if buildings[i]:GetBuildId() == buildingID then
            curBuilding = buildings[i]
            break
        end
    end

    if not curBuilding then
        return
    end

    self.curBuildingSkinID = curBuilding:SkinID()
    local cfgs = Cfg.cfg_item_architecture_skin {architecture_id = curBuilding:GetBuildId()}

    self.skins = {}
    for _, cfg in ipairs(cfgs) do
        --Log.fatal(cfg.ID)
        if self.mHomeland:HasBuildSkin(cfg.ID) then
            self.skins[#self.skins + 1] = cfg
        end
    end

    --排序
    table.sort(
        self.skins,
        function(a, b)
            return a.ID < b.ID
        end
    )

    self._svHelper:Dispose()
    self._svHelper:SetItemName("UIHomelandBuildEditItemSkin")
    self._svHelper:SetShowFunction(
        function(index, ui)
            ui:Flush(self.skins[index], self.curBuildingSkinID)
            return ui
        end
    )
    self._svHelper:Init(#self.skins, 0, Vector2(0, 0))
end
--endregion 组合建筑


--指定物品是否在拍电影建筑黑名单中
---@return boolean
function UIHomelandBuildEditList:IsBuildItemInFreeAreaBlack(itemId)
    if self.listType == BuildEditListType.BT_MakeMovie then
        for _, v in pairs(self._freeAreaBlackList) do
            if v == itemId then
                return true
            end
        end
    end
    return false
end

