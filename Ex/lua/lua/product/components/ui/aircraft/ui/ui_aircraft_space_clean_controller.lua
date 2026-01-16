--[[
    清理空间不再弹窗，已经废弃 2020-7-27
]]
---@class UIAircraftSpaceCleanController : UIController
_class("UIAircraftSpaceCleanController", UIController)
UIAircraftSpaceCleanController = UIAircraftSpaceCleanController
function UIAircraftSpaceCleanController:OnShow(uiParams)
    self.spaceId = uiParams[1]
    ---@type AircraftModule
    self.airData = GameGlobal.GameLogic():GetModule(AircraftModule)

    self:InitWidget()
    ---@type UIAircraftTopBarItem
    self.topBarWidget = self.topbar:SpawnObject("UIAircraftTopBarItem")
    self.topBarWidget:SetData(false, nil, nil, nil, true)

    --与AirRoomType枚举对应，主控室不可清理
    local roomTexts = {
        [2] = {name = "str_aircraft_powerroom_name", des = "str_aircraft_powerroom_clean_des"},
        [3] = {name = "str_aircraft_maze_name", des = "str_aircraft_maze_name_clean_des"},
        [4] = {name = "str_aircraft_resourceroom_name", des = "str_aircraft_resourceroom_clean_des"},
        [5] = {name = "str_aircraft_prismroom_name", des = "str_aircraft_prismroom_clean_des"},
        [6] = {name = "str_aircraft_towerroom_name", des = "str_aircraft_towerroom_clean_des"},
        [7] = {name = "str_aircraft_evilcaptureroom_name", des = "str_aircraft_evilcaptureroom_clean_des"},
        [8] = {name = "str_aircraft_evilresearchroom_name", des = "str_aircraft_evilresearchroom_clean_des"},
        [100] = {name = "str_aircraft_aisle_name", des = "str_aircraft_aisle_clean_des"}
    }

    --房间类型，目前只支持1种
    local roomType = self.airData:GetBuildType(self.spaceId)[1]
    local texts = roomTexts[roomType]
    self.title.text = string.format(StringTable.Get("str_aircraft_clean_titile"), StringTable.Get(texts.name))
    self.desc.text = StringTable.Get(texts.des)

    --房间类型图标(清理)
    local icon = nil
    local room_cfg = Cfg.cfg_aircraft_room {}
    for id, room_cfg in pairs(room_cfg) do
        if room_cfg.Level == 1 then
            if room_cfg.RoomType == roomType then
                icon = room_cfg.RoomTypeIcon1
            end
        end
    end

    self.bgLoader:LoadImage(icon)

    --mats
    ---@type table<UnityEngine.GameObject,UIItemsWidget>
    self._matWidgets = {}
    self.mats = self.airData:GetCleanCost(self.spaceId)

    self.matsScrollView:InitListView(
        #self.mats,
        function(_scrollView, _index)
            return self:NewMatItem(_scrollView, _index)
        end
    )

    if #self.mats <= 4 then
        self:GetUIComponent("ScrollRect", "MatScrollView").enabled = false
        self.matsScrollView.enabled = false
        local rect = self:GetUIComponent("RectTransform", "MatContent")
        rect.anchorMin = Vector2(0, 0)
        rect.anchorMax = Vector2(1, 1)
        rect.offsetMin = Vector2(0, 0)
        rect.offsetMax = rect.parent:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta
        self.matContent.enabled = true
    end

    --firefly
    self:RefreshFirefly()
end
--genarated
function UIAircraftSpaceCleanController:InitWidget()
    self.matsScrollView = self:GetUIComponent("UIDynamicScrollView", "MatScrollView")
    self.textAddFireflyFrom = self:GetUIComponent("UILocalizationText", "TextAddFireflyFrom")
    self.textAddFireflyTo = self:GetUIComponent("UILocalizationText", "TextAddFireflyTo")
    self.topbar = self:GetUIComponent("UISelectObjectPath", "Topbar")
    self.title = self:GetUIComponent("UILocalizationText", "TextRoomTitle")
    self.desc = self:GetUIComponent("UILocalizationText", "TextRoomDes")
    self.bgLoader = self:GetUIComponent("RawImageLoader", "ImageWindow")
    self.matContent = self:GetUIComponent("HorizontalLayoutGroup", "MatContent")
end

function UIAircraftSpaceCleanController:OnHide()
    if self.fireflyTimer then
        GameGlobal.Timer():CancelEvent(self.fireflyTimer)
        self.fireflyTimer = nil
    end
end

function UIAircraftSpaceCleanController:RefreshFirefly()
    local firefly = math.floor(self.airData:GetFirefly())
    local ceiling = math.floor(self.airData:GetMaxFirefly())

    local added = math.floor(self.airData:GetAddFirefly(self.spaceId))
    self.textAddFireflyFrom.text =
        string.format("<color=#ffffff>%s</color><color=#de6615>/</color><color=#b1b1b1>%s</color>", firefly, ceiling)
    self.textAddFireflyTo.text =
        string.format(
        "<color=#00ffcc>%s</color><color=#de6615>/</color><color=#b1b1b1>%s</color>",
        firefly + added,
        ceiling + added
    )

    --萤火不满
    if firefly < ceiling then
        if self.fireflyTimer then
            GameGlobal.Timer():CancelEvent(self.fireflyTimer)
            self.fireflyTimer = nil
        end
        self.fireflyTimer =
            GameGlobal.Timer():AddEventTimes(
            1000,
            TimerTriggerCount.Infinite,
            function()
                local firefly = math.floor(self.airData:GetFirefly())
                local ceiling = math.floor(self.airData:GetMaxFirefly())

                local added = math.floor(self.airData:GetAddFirefly(self.spaceId))
                self.textAddFireflyFrom.text =
                    string.format(
                    "<color=#ffffff>%s</color><color=#de6615>/</color><color=#b1b1b1>%s</color>",
                    firefly,
                    ceiling
                )
                self.textAddFireflyTo.text =
                    string.format(
                    "<color=#00ffcc>%s</color><color=#de6615>/</color><color=#b1b1b1>%s</color>",
                    firefly + added,
                    ceiling + added
                )
                if firefly < ceiling then
                    if self.fireflyTimer then
                        GameGlobal.Timer():CancelEvent(self.fireflyTimer)
                        self.fireflyTimer = nil
                    end
                end
            end
        )
    else
        if self.fireflyTimer then
            GameGlobal.Timer():CancelEvent(self.fireflyTimer)
            self.fireflyTimer = nil
        end
    end
end

function UIAircraftSpaceCleanController:NewMatItem(_scrollView, _index)
    if _index < 0 then
        return nil
    end
    local item = _scrollView:NewListViewItem("mat")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    ---@type UIItemsWidget
    local mat = rowPool:SpawnObject("UIItemsWidget")
    local matData = self.mats[_index + 1]
    local id = matData[1]
    local need = matData[2]
    mat:SetData(
        id,
        need,
        function(_id, pos)
            self:OnMatClick(_id, pos)
        end,
        false
    )
    self._matWidgets[item.gameObject] = mat
    return item
end

function UIAircraftSpaceCleanController:ButtonCancelOnClick(go)
    self:CloseDialog()
end

function UIAircraftSpaceCleanController:ButtonLevelDownOnClick(go)
    local enough = true
    for go, widget in pairs(self._matWidgets) do
        if go.activeSelf then
            if not widget:IsMatEnough() then
                enough = false
                widget:ShakeAndHighlight()
            end
        end
    end
    if not enough then
        return
    end

    GameGlobal.TaskManager():StartTask(self.RequestClean, self)
end

function UIAircraftSpaceCleanController:RequestClean(TT)
    self:Lock(self:GetName())
    local result = self.airData:RequestCleanSpace(TT, self.spaceId)
    self:UnLock(self:GetName())
    if result:GetSucc() then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRequestDataAndRefreshMainUI)
        self:CloseDialog()
    else
        ToastManager.ShowToast(self.airData:GetErrorMsg(result:GetResult()))
    end
end

function UIAircraftSpaceCleanController:OnMatClick(matId, pos)
    self:ShowDialog("UIItemGetPathController", matId)
end
