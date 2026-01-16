---@class UIAircraftItemSmeltController : UIController
_class("UIAircraftItemSmeltController", UIController)
UIAircraftItemSmeltController = UIAircraftItemSmeltController

function UIAircraftItemSmeltController:OnShow(uiParams)
    self:InitWidget()
    self:InitDataUpdater()
    ---@type RoleModule
    self._roleModule = self:GetModule(RoleModule)
    ---@type MissionModule
    self._missionModule = self:GetModule(MissionModule)
    ---@type AircraftModule
    self._airModule = self:GetModule(AircraftModule)
    ---@type AircraftSmeltRoom
    self._smeltRoom = self._airModule:GetSmeltRoom()
    --原子剂折扣
    self._atomDiscount = self._smeltRoom:AtomDiscount()

    ---@type UICommonTopButton
    local topWidget = self.topButton:SpawnObject("UICommonTopButton")
    topWidget:SetData(
        function()
            self:CloseDialog()
        end,
        function()
            self:ShowDialog("UIHelpController", "UIAircraftSmeltRoom")
        end,
        function()
            --Loading回主界面
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftLeaveAircraft)
            GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Aircraft_Exit, "UI")
        end
    )

    --熔炼室QA_跳转熔炼室可以直接打开界面 2023.3.20 曾祥生
    if GameGlobal.UIStateManager():IsShow("UIItemGetPathController") then
        GameGlobal.UIStateManager():CloseDialog("UIItemGetPathController")
    end

    --一级页签
    local tab1s = Cfg.cfg_aircraft_smelt_tab1 {}
    table.sort(
        tab1s,
        function(a, b)
            return a.Index < b.Index
        end
    )
    self.tabs:SpawnObjects("UIAircraftSmeltTab", #tab1s)
    ---@type table<number,UIAircraftSmeltTab>
    self._1stTabWidgets = {}
    local _1stWidgets = self.tabs:GetAllSpawnList()
    local tab1Click = function(id)
        self:OnTypeChanged(id)
    end
    local _count = #tab1s
    for i = 1, _count do
        local widget = _1stWidgets[i]
        local data = tab1s[_count - i + 1]
        widget:SetData(data, tab1Click)
        self._1stTabWidgets[data.ID] = widget
    end

    --排序后的一级页签ID
    self._tab1IDs = {}
    for i, cfg in ipairs(tab1s) do
        self._tab1IDs[i] = cfg.ID
    end

    --顶条物品id
    self._topTipID = {}
    for i, cfg in ipairs(tab1s) do
        local id = cfg.ID
        local toptips = {}
        for i, asset in ipairs(cfg.TopTips) do
            toptips[i] = asset
        end
        self._topTipID[id] = toptips
    end

    self:OpenJump(uiParams[1], uiParams[2])
    self:AttachEvent(GameEventType.AircraftOnAtomChanged, self.OnAtomChanged)
    self:AttachEvent(GameEventType.AircraftOnFireFlyChanged, self.OnFireflyChanged)
end

function UIAircraftItemSmeltController:OnHide()
    if self.d_dataUpdater then
        GameGlobal.Timer():CancelEvent(self.d_dataUpdater)
        self.d_dataUpdater = nil
    end
end

--打开指定素材
function UIAircraftItemSmeltController:OpenJump(goodsId, targetNum, jumpFromSelf)
    if goodsId then
        local jumpID = goodsId

        local targetCfg
        local allCfgs = Cfg.cfg_item_smelt {}
        for _, cfg in pairs(allCfgs) do
            if cfg.Output[1] == jumpID then
                targetCfg = cfg
                break
            end
        end
        if not targetCfg then
            AirError("找不到跳转ID:", jumpID)
        end
        local targetTab2Cfg = Cfg.cfg_aircraft_smelt_tab2[targetCfg.Tab]
        --先跳到指定的1级页签
        self:OnTypeChanged(targetTab2Cfg.Tab1)

        if self._1stTabWidgets[self._tab1]:UIType() == SmeltRoomUIType.Resolve then
            --策划口头约定，分解材料不支持从获取途径跳转 2021.7.5 靳策
            -- self._resolve:JumpTo(targetCfg.ID)
            AirError("策划配置错误, 分解材料不支持跳转：", jumpID)
        elseif self._1stTabWidgets[self._tab1]:UIType() == SmeltRoomUIType.Compond then
            self._compound:JumpTo(targetCfg.ID, targetNum, jumpFromSelf)
        elseif self._1stTabWidgets[self._tab1]:UIType() == SmeltRoomUIType.Camp then
            self._camp:JumpTo(targetCfg.ID)
        end
    else
        --正常打开默认页签
        self:OnTypeChanged(self._tab1IDs[1])
    end
end

function UIAircraftItemSmeltController:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.topButton = self:GetUIComponent("UISelectObjectPath", "TopButton")
    ---@type UICustomWidgetPool
    self.topCurrency = self:GetUIComponent("UISelectObjectPath", "TopCurrency")
    -- --generated end--

    self.tabs = self:GetUIComponent("UISelectObjectPath", "Tabs")

    ---@type UICustomWidgetPool
    self._compoundLoader = self:GetUIComponent("UISelectObjectPath", "Compound")
    ---@type UICustomWidgetPool
    self._resolveLoader = self:GetUIComponent("UISelectObjectPath", "Resolve")
    ---@type UICustomWidgetPool
    self._campLoader = self:GetUIComponent("UISelectObjectPath", "Camp")
    ---@type UICustomWidgetPool
    self._selectInfo = self:GetUIComponent("UISelectObjectPath", "SelectInfo")
end

--一级页签改变
function UIAircraftItemSmeltController:OnTypeChanged(tabID)
    if self._tab1 == tabID then
        return
    end

    if self._tab1 then
        self._1stTabWidgets[self._tab1]:Cancel()
    end
    self._tab1 = tabID
    self._1stTabWidgets[self._tab1]:Select()

    local uiType = self._1stTabWidgets[self._tab1]:UIType()

    if uiType == SmeltRoomUIType.Resolve then
        --分解
        if not self._resolve then
            ---@type UIAircraftResolve
            self._resolve = self._resolveLoader:SpawnObject("UIAircraftResolve")
        end
        if self._compound then
            self._compound:SetShow(false)
        end
        if self._camp then
            self._camp:SetShow(false)
        end
        self._resolve:SetData(
            self._tab1,
            function(id, pos)
                self:ShowSelectInfo(id, pos)
            end
        )
        self._resolve:SetShow(true)
    elseif uiType == SmeltRoomUIType.Compond then
        --合成
        if not self._compound then
            ---@type UIAircraftCompound
            self._compound = self._compoundLoader:SpawnObject("UIAircraftCompound")
        end

        if self._resolve then
            self._resolve:SetShow(false)
        end
        if self._camp then
            self._camp:SetShow(false)
        end
        self._compound:SetData(self._tab1)
        self._compound:SetShow(true)
    elseif uiType == SmeltRoomUIType.Camp then
        --势力
        if self._resolve then
            self._resolve:SetShow(false)
        end
        if self._compound then
            self._compound:SetShow(false)
        end
        if not self._camp then
            ---@type UIAircraftCamp
            self._camp = self._campLoader:SpawnObject("UIAircraftCamp")
        end
        self._camp:SetData(self._tab1)
        self._camp:SetShow(true)
    else
        Log.exception("Tab1类型错误:", self._tab1)
    end

    ---@type UICurrencyMenu
    self._topTips = self.topCurrency:SpawnObject("UICurrencyMenu")
    self._topTips:SetData(self._topTipID[self._tab1])
    ---@type UICurrencyItem
    local atom = self._topTips:GetItemByTypeId(RoleAssetID.RoleAssetAtom)
    if atom then
        atom:SetAddCallBack(
            function()
                self:ShowDialog("UISmeltAtomExchangeController")
            end
        )
        self:OnAtomChanged()
    end
    ---@type UICurrencyItem
    local firefly = self._topTips:GetItemByTypeId(RoleAssetID.RoleAssetFirefly)
    if firefly then
        firefly:CloseAddBtn()
        self:OnFireflyChanged()
    end
end

function UIAircraftItemSmeltController:OnAtomChanged()
    ---@type UICurrencyItem
    local atom = self._topTips:GetItemByTypeId(RoleAssetID.RoleAssetAtom)
    if atom then
        atom:SetText(math.floor(self._roleModule:GetAtom()) .. "/" .. math.floor(self._smeltRoom:GetStorageMax()))
    end
end

function UIAircraftItemSmeltController:OnFireflyChanged()
    ---@type UICurrencyItem
    local firefly = self._topTips:GetItemByTypeId(RoleAssetID.RoleAssetFirefly)
    if firefly then
        firefly:SetText(self._airModule:GetFirefly() .. "/" .. math.floor(self._airModule:GetMaxFirefly()))
    end
end

function UIAircraftItemSmeltController:ShowSelectInfo(id, pos)
    if not self._itemTips then
        ---@type UISelectInfo
        self._itemTips = self._selectInfo:SpawnObject("UISelectInfo")
    end
    self._itemTips:SetData(id, pos)
end

function UIAircraftItemSmeltController:InitDataUpdater()
    --不进船则开启这个计时器
    local airController =  GameGlobal.UIStateManager():GetController("UIAircraftController") 
    if airController then
        return
    end
    ---@type AircraftModule
    local airModule = GameGlobal.GetModule(AircraftModule)
    local d_curFireFly = math.floor(airModule:GetFirefly())
    local d_atom = GameGlobal.GetModule(RoleModule):GetAtom()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)

    self.d_dataUpdater =
        GameGlobal.Timer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()            
            if (roleModule == nil) or (airModule == nil) or (airModule:GetAircraftInfo() == nil) then
                -- 如果玩家与服务器断开连接返回主界面的时候 有可能会先初始化Module然后再调用OnHide导致找不到数据的情况
                return
            end
            --萤火
            local curFire = math.floor(airModule:GetFirefly())
            if curFire ~= d_curFireFly then
                d_curFireFly = curFire
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnFireFlyChanged)
            end
            
            --原子剂
            if airModule:GetSmeltRoom() then
                local count = roleModule:GetAtom()
                if count ~= d_atom then
                    d_atom = count
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnAtomChanged)
                end
            end
        end
    )
end

--region----------------------------------------------------------------------------------enums
---@class AirItemErrorCode 材料错误码
local AirItemErrorCode = {
    None = 0,
    Zero = 1 << 1, --材料数量为0
    NotEnough = 1 << 2, --材料不足以合成
    SNotEnough = 1 << 3, --特殊材料（货币）不足
    FireflyOverflow = 1 << 4, --分解后萤盏超上限
}
_enum("AirItemErrorCode", AirItemErrorCode)
--endregion
