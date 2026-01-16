---@class UIPetSortAndFilter : UICustomWidget
_class("UIPetSortAndFilter", UICustomWidget)
UIPetSortAndFilter = UIPetSortAndFilter
function UIPetSortAndFilter:OnShow(uiParams)
    self:InitWidget()

    UIPetSortContext.CreateInstance()
    UIPetSortContext.Instance:SetViceElement(true)
end

function UIPetSortAndFilter:OnHide()
    UIPetSortContext.ClearInstance()
end

function UIPetSortAndFilter:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.sortBtns = self:GetUIComponent("UISelectObjectPath", "sortBtns")
    ---@type UICustomWidgetPool
    self.filterPanel = self:GetUIComponent("UISelectObjectPath", "filterPanel")
    --generated end--
    self._curSortStateIcon = self:GetUIComponent("Image", "btnFiltrate")
    self._atlas = self:GetAsset("UIHomelandDomitory.spriteatlas", LoadType.SpriteAtlas)

    self._clearBtn = self:GetGameObject("btnClear")
end

---@param sortKey string 配置key
---@param defaultSortType PetSortType 默认排序类型
---@param defaultSortOrder PetSortOrder 默认排列顺序
---@param btnCount number 右上角默认显示的按钮数量n，去前n个
function UIPetSortAndFilter:SetData(sortKey, defaultSortType, defaultSortOrder, btnCount, onChange)
    local sortFilterCfg = UISortFilterCfg[sortKey]
    local sortCfg = {}
    for idx, value in ipairs(sortFilterCfg.Sort) do
        sortCfg[idx] = Cfg.cfg_client_pet_sort[value]
    end
    local filterCfg = {}
    for tag, filters in pairs(sortFilterCfg.Filter) do
        local cfgs = {}
        for idx, value in ipairs(filters) do
            cfgs[idx] = Cfg.cfg_client_pet_filter[value]
        end
        filterCfg[tag] = cfgs
    end
    self._sortCfg = sortCfg
    self._filterCfg = filterCfg

    self._sortType = defaultSortType
    self._sortOrder = defaultSortOrder
    self._onChange = onChange
    self._filterParams = {} --默认不筛选

    ---@type table<number, UIDomitorySortBtn>
    self._sortBtns = self.sortBtns:SpawnObjects("UIDomitorySortBtn", btnCount)
    for i = 1, btnCount do
        self._sortBtns[i]:SetData(
            i,
            self._sortCfg[i],
            self._sortType,
            self._sortOrder,
            function(idx)
                self:changeParams(idx)
            end,
            UIPetSortContext.Instance:CurElement()
        )
    end
    self:ResetCleatBtn()
end
function UIPetSortAndFilter:btnFiltrateOnClick(go)
    self._curSortStateIcon.sprite = self._atlas:GetSprite("n17_dorm_list_btn2")
    if self._sortFilter == nil then
        ---@type UIDomitorySortFilter
        self._sortFilter = self.filterPanel:SpawnObject("UIDomitorySortFilter")
    end
    self._sortFilter:SetData(
        self._sortType,
        self._sortOrder,
        self._filterParams,
        self._sortCfg,
        self._filterCfg,
        function(sortType, sortOrder, filterParams)
            self:OnSortFilterChanged(sortType, sortOrder, filterParams)
        end,
        function()
            self:OnCloseFilterPanel()
        end
    )
    self._sortFilter:GetGameObject():SetActive(true)
end

function UIPetSortAndFilter:changeParams(idx)
    local tp = self._sortCfg[idx].Type
    if tp == PetSortType.Element then
        local element = UIPetSortContext.Instance:CurElement()
        if element == ElementType.ElementType_Blue then
            self._sortType = PetSortType.WaterFirst
        elseif element == ElementType.ElementType_Red then
            self._sortType = PetSortType.FireFirst
        elseif element == ElementType.ElementType_Green then
            self._sortType = PetSortType.SenFirst
        elseif element == ElementType.ElementType_Yellow then
            self._sortType = PetSortType.ElectricityFirst
        end
        self._sortOrder = PetSortOrder.Descending --默认降序
    else
        if self._sortType == tp then
            --顺序反转
            if self._sortOrder == PetSortOrder.Ascending then
                self._sortOrder = PetSortOrder.Descending
            elseif self._sortOrder == PetSortOrder.Descending then
                self._sortOrder = PetSortOrder.Ascending
            end
        else
            self._sortType = tp
            self._sortOrder = PetSortOrder.Descending --默认降序
        end
    end

    --刷新顶部排序按钮状态
    for i = 1, #self._sortBtns do
        self._sortBtns[i]:Flush(self._sortType, self._sortOrder, UIPetSortContext.Instance:CurElement())
    end
    self:ResetCleatBtn()

    self._onChange(self._filterParams, self._sortType, self._sortOrder)
end

function UIPetSortAndFilter:OnSortFilterChanged(sortType, sortOrder, filterParams)
    self._sortType = sortType
    self._sortOrder = sortOrder
    self._filterParams = filterParams

    --刷新顶部排序按钮状态
    for i = 1, #self._sortBtns do
        self._sortBtns[i]:Flush(self._sortType, self._sortOrder, UIPetSortContext.Instance:CurElement())
    end
    self:ResetCleatBtn()

    self._onChange(self._filterParams, self._sortType, self._sortOrder)
end

function UIPetSortAndFilter:OnCloseFilterPanel()
    self:ResetCleatBtn()
    if not next(self._filterParams) then
        self._curSortStateIcon.sprite = self._atlas:GetSprite("n17_dorm_list_btn1")
    end
end

function UIPetSortAndFilter:BtnClearOnClick()
    self._filterParams = {}
    UIPetSortContext.Instance:SetViceElement(true)
    self:ResetCleatBtn()
    self._sortFilter:ClearFilters()

    if not self._sortFilter:IsShow() then
        self._curSortStateIcon.sprite = self._atlas:GetSprite("n17_dorm_list_btn1")
    end

    self._onChange(self._filterParams, self._sortType, self._sortOrder)
end

function UIPetSortAndFilter:ResetCleatBtn()
    self._clearBtn:SetActive(next(self._filterParams) ~= nil)
end
