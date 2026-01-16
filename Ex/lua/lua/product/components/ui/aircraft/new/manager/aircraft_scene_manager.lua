---@class AircraftSceneManager 空间及建筑数据管理及交互处理
_class("AircraftSceneManager", Object)
AircraftSceneManager = AircraftSceneManager

function AircraftSceneManager:Constructor(main)
    ---@type AircraftMain
    self._main = main
    self._input = self._main:Input()
    ---@type AircraftModule
    self._aircraftModule = GameGlobal.GetModule(AircraftModule)

    ---@type table<int, AircraftRoom> 房间类列表 key为空间ID
    self.roomTable = {}
    ---@type table<AirRestAreaType, AircraftRoom> 以娱乐区枚举索引的房间列表
    self._restRoomTable = {}

    ---@type table<int,AircraftRoom3DUI> 房间ui列表
    self.uiTable = {}

    ---@type table<UnityEngine.GameObject> 场景中房间的GameObject集合（按顺序）
    self.roomGoTable = {}

    ---@type UnityEngine.Transform 房间内与模型对齐的ui父物体
    self.roomUIRoot = nil
    ---@type UnityEngine.Camera
    self.roomUICamera = nil
    ---@type UIView
    self.pressSliderView = nil
    ---@type UnityEngine.UI.Slider
    self.pressSlider = nil
    self.sliderRequest = nil

    --点击的房间
    self._clickRoom = nil

    --宿舍出口，世界坐标
    self._leavePoint = UnityEngine.GameObject.Find("LogicRoot").transform:Find("Exit").position
end

function AircraftSceneManager:Init()
    local sceneRoot = UnityEngine.GameObject.Find("LogicRoot")
    self.rootReq = ResourceManager:GetInstance():SyncLoadAsset("AircraftRoot.prefab", LoadType.GameObject)
    self.root = self.rootReq.Obj
    self.root.transform:SetParent(sceneRoot.transform, true)
    self.root:SetActive(true)
    self.root.transform.position = Vector3(0, 0, 0)

    --设置点击文本canvas的camera
    local uiCamera = UnityEngine.GameObject.Find("UICamera"):GetComponent("Camera")
    ---@type UnityEngine.Canvas
    local talkCanvas = self.root.transform:Find("AircraftTalkCanvas").gameObject:GetComponent("Canvas")
    talkCanvas.worldCamera = uiCamera

    self.roomUIRoot = self.root.transform:Find("RoomUI/RoomUICanvas")
    self.roomUICamera = self.root.transform:Find("RoomUI/RoomUICamera"):GetComponent("Camera")

    self.doors = {}
    local doorParent = UnityEngine.GameObject.Find("door")

    if doorParent then
        for i = 0, doorParent.transform.childCount - 1 do
            local hasDoor = Cfg.cfg_aircraft_space[i + 1].Mat
            if hasDoor then
                local doorTrans = doorParent.transform:GetChild(i)
                self.doors[i + 1] = AircraftSpaceDoor:New(i + 1, doorTrans)
            end
        end
    end
    local roomParent = UnityEngine.GameObject.Find("fj")
    if roomParent then
        for i = 0, roomParent.transform.childCount - 1 do
            self.roomGoTable[i + 1] = roomParent.transform:GetChild(i).gameObject
        end
    end

    --3dUI的父节点
    self.canvasRoot = UnityEngine.GameObject.Find("Aircraft3DUICanvas").transform
    self.uiScale = 0.03

    self:RefreshSpaces()

    --娱乐房间
    ---@type table<number,AircraftBoard>
    self._boards = {}
    local root = UnityEngine.GameObject.Find("BoardNavMeshRoot").transform
    local oversize = root:Find("oversize")
    for i = 1, 4 do
        local navi = root:GetChild(i - 1)
        local os = oversize:GetChild(i - 1)
        self._boards[i] = AircraftBoard:New(navi.gameObject, i, os)
    end

    self._showRoomUI = false

    --打开实时阴影 暂时不再使用实时光
    --HelperProxy:GetInstance():SetShowMuskActive(true)

    AirLog("AircraftSceneManager Init Done")
end

function AircraftSceneManager:GetRoomTable()
    return self.roomTable
end

function AircraftSceneManager:GetInteractionRoot()
    return self._interactionTextRoot
end
function AircraftSceneManager:GetInteractionPos()
    return self._interactionPos
end
function AircraftSceneManager:GetInteractionText()
    return self._interactionText
end
function AircraftSceneManager:Dispose()
    if self.sliderRequest then
        self.sliderRequest:Dispose()
    end

    if self.roomTable then
        for _, room in pairs(self.roomTable) do
            room:Dispose()
        end
    end
    if self.doors then
        for _, door in pairs(self.doors) do
            door:Dispose()
        end
    end

    if self.uiTable then
        for _, ui in pairs(self.uiTable) do
            ui:OnDestroy()
        end
    end

    --关闭实时阴影 暂时不再使用实时光
    --HelperProxy:GetInstance():SetShowMuskActive(false)
end

function AircraftSceneManager:GetRoomBySpaceID(id)
    return self.roomTable[id]
end

function AircraftSceneManager:GetRoomGoSpaceID(id)
    return self.roomGoTable[id]
end

function AircraftSceneManager:RefreshSpaces()
    for i = 1, #self.roomGoTable do
        --预留房间不处理
        if Cfg.cfg_aircraft_space[i].BuildType[1] ~= AirRoomType.EmptySpace then
            ---@type AircraftRoomBase
            local roomData = self._aircraftModule:GetRoom(i)
            if roomData then
                if self.roomTable[i] then
                    -- self.roomTable[i]:RefreshPets()
                    --房间刷新
                    -- self:RefreshRoom(i, roomData)
                    --不在这里处理房间刷新
                else
                    local floor = Cfg.cfg_aircraft_space[i].Floor
                    local room = AircraftRoom:New(self.roomGoTable[i], roomData, floor)
                    self.roomTable[i] = room
                    local area = room:Area()
                    --工作区房间没有area
                    if area then
                        if self._restRoomTable[area] then
                            Log.exception("[AircraftScene] 娱乐区房间区域类型冲突：", area)
                            return
                        end
                        self._restRoomTable[area] = room
                    end
                end
            end
            if self.uiTable[i] then
                self:RefreshUI(i)
            else
                self.uiTable[i] = self:CreateUI(i)
            end
        end
    end
end

--刷新房间，只有4个休闲区房间升级会用到
---@param logicData AircraftRoomBase
function AircraftSceneManager:RefreshRoom(spaceID)
    local logicData = self._aircraftModule:GetRoom(spaceID)
    ---@type AircraftRoom
    local room = self.roomTable[spaceID]
    if self._aircraftModule:IsAmusementRoom(room:LogicRoomType()) then
        local state = self.uiTable[spaceID]:GetState()
        AirLog("刷新娱乐区房间：", spaceID, "，当前状态：", state, "，等级：", logicData:Level())
        if state == AirUIState.RestAreaRoom and logicData:Level() > 1 then
            -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "BuildRestRoom")
            --房间楼层不会变
            local floor = room:Floor()
            local area = room:Area()
            room:Dispose()
            local newRoom = AircraftRoom:New(self.roomGoTable[spaceID], logicData, floor)
            self.roomTable[spaceID] = newRoom

            local pets =
                self._main:GetPets(
                function(p)
                    ---@type AircraftPet
                    local pet = p
                    if pet:GetWanderingArea() == area or pet:GetMovingTargetArea() == area then
                        return true
                    else
                        return false
                    end
                end
            )
            for _, pet in ipairs(pets) do
                self._main:RandomActionForPet(pet)
            end
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "BuildRestRoom")
        end
    end
end

function AircraftSceneManager:GetBoards()
    return self._boards
end
function AircraftSceneManager:GetPointHolderByArea(area)
    if area == AirRestAreaType.Board3 then
        return self:GetBoard3():PointHolder()
    elseif area == AirRestAreaType.Board4 then
        return self:GetBoard4():PointHolder()
    else
        local room = self:GetRoomByArea(area)
        if room == nil then
            Log.exception("###room is nil ! id --> ", area)
        end
        return self:GetRoomByArea(area):GetPointHolder()
    end
end

-- 聚集点
function AircraftSceneManager:GetGatherPointHolderByArea(area)
    if area == AirRestAreaType.Board3 then
        return self:GetBoard3():GatherPointHolder()
    elseif area == AirRestAreaType.Board4 then
        return self:GetBoard4():GatherPointHolder()
    else
        return self:GetRoomByArea(area):GetGatherPointHolder()
    end
end

-- 剧情点
function AircraftSceneManager:GetRandomStoryPointHolderByArea(area)
    if area == AirRestAreaType.Board3 then
        return self:GetBoard3():RandomStoryPointHolder()
    elseif area == AirRestAreaType.Board4 then
        return self:GetBoard4():RandomStoryPointHolder()
    else
        return self:GetRoomByArea(area):GetRandomStoryPointHolder()
    end
end

--区域是否占满
function AircraftSceneManager:AreaIsFull(area)
    --3、4层甲板永远不会满
    if area == AirRestAreaType.Board3 or area == AirRestAreaType.Board4 then
        return false
    else
        if self:GetRoomByArea(area) == nil then
            Log.exception("[AircraftScene] 区域类型错误：", area)
        end
        return self:GetRoomByArea(area):IsWanderingPetFull()
    end
end

---@param pet  AircraftPet
---@param area AirRestAreaType
---星灵进入区域散步
function AircraftSceneManager:PetEnterAreaWandering(pet, area)
    -- local curArea = pet:GetWanderingArea()
    local id = pet:TemplateID()
    -- if curArea then
    --     if curArea == AirRestAreaType.Board3 or curArea == AirRestAreaType.Board4 then
    --     else
    --         self:GetRoomByArea(curArea):PetLeaveWandering(id)
    --     end
    -- end
    pet:SetWanderingArea(area)
    if area == AirRestAreaType.Board3 or area == AirRestAreaType.Board4 then
    else
        self:GetRoomByArea(area):PetEnterWandering(id)
    end
end

-- function AircraftSceneManager:GetFurnitureByType(type)
--     for _, room in pairs(self.roomTable) do
--         local fur = room:GetFurniture(type)
--         if fur then
--             return fur
--         end
--     end
-- end

-- function AircraftSceneManager:GetFurnitureByID(id)
--     for _, room in pairs(self.roomTable) do
--         local fur = room:GetFurnitureByID(id)
--         if fur then
--             return fur
--         end
--     end
-- end

--获取4个休息区房间
function AircraftSceneManager:GetAllRestRoom()
    return {
        self:GetRoomByArea(AirRestAreaType.RestRoom),
        self:GetRoomByArea(AirRestAreaType.CoffeeHouse),
        self:GetRoomByArea(AirRestAreaType.Bar),
        self:GetRoomByArea(AirRestAreaType.EntertainmentRoom)
    }
end
----------------------------------------------------------------
function AircraftSceneManager:ClickRoom(spaceId, room, state, focus, callback)
    if self._clickRoom == nil then
        self._clickRoom = spaceId
        self._focusRoom = nil
        self.uiTable[spaceId]:EnterRoom()

        --风船系统QA_领取材料逻辑修改
        if
            state == AirUIState.RoomIdle or state == AirUIState.RoomStopWork or state == AirUIState.RestAreaRoom or
                state == AirUIState.CanCollectAward or
                state == AirUIState.HaveNewTask or
                state == AirUIState.CollectAward or
                state == AirUIState.RestAreaRoomLock
         then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
            self._showRoomUI = true
        end
    else
        if self._clickRoom == spaceId then
            if self._focusRoom == nil then
                if focus and room then
                    self._focusRoom = spaceId
                    AirLog("点击聚焦到房间：", spaceId)
                    self._main:FocusRoom(self.roomTable[spaceId], callback)
                    if not self._showRoomUI and state ~= AirUIState.RestAreaRoomLock then
                        --特殊处理，未解锁的娱乐区房间可以聚焦，但不显示ui
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
                        self._showRoomUI = true
                    end
                end
            else
                if not self._showRoomUI and state ~= AirUIState.RestAreaRoomLock then
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
                    self._showRoomUI = true
                end
            end
        else
            self.uiTable[self._clickRoom]:ExitRoom()
            self._clickRoom = spaceId
            self._focusRoom = nil
            self.uiTable[self._clickRoom]:EnterRoom()

            --风船系统QA_领取材料逻辑修改
            if
                state == AirUIState.RoomIdle or state == AirUIState.RoomStopWork or state == AirUIState.RestAreaRoom or
                    state == AirUIState.CanCollectAward or
                    state == AirUIState.HaveNewTask or
                    state == AirUIState.CollectAward
             then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
                self._showRoomUI = true
            elseif state == AirUIState.RestAreaRoomLock then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
                self._showRoomUI = true
            end
        end
    end
    self:_refresh3duiAlpha()
end

function AircraftSceneManager:_refresh3duiAlpha()
    for _, ui in pairs(self.uiTable) do
        if ui:Selected() then
            ui:WholeShow()
        else
            ui:HalfShow()
        end
    end
end

function AircraftSceneManager:_showAll3Dui()
    for _, ui in pairs(self.uiTable) do
        ui:WholeShow()
    end
end

function AircraftSceneManager:CreateUI(spaceID)
    local state = self:GetUIState(spaceID)
    local roomGo = self.roomGoTable[spaceID]
    local roomData = self._aircraftModule:GetRoom(spaceID)

    ---@type UnityEngine.BoxCollider
    local box = roomGo:GetComponent(typeof(UnityEngine.BoxCollider))
    local pos = roomGo.transform.position + box.center - roomGo.transform.forward * (box.size.z / 2)
    -- pos.z = -8
    local size = box.size
    local req = ResourceManager:GetInstance():SyncLoadAsset("RoomUIBase.prefab", LoadType.GameObject)
    req.Obj.transform:SetParent(self.canvasRoot)
    req.Obj.transform.position = pos
    req.Obj.transform.localScale = Vector3(1, 1, 1)
    req.Obj:SetActive(true)
    local rect = req.Obj:GetComponent(typeof(UnityEngine.RectTransform))
    rect.sizeDelta = Vector2(size.x / self.uiScale, size.y / self.uiScale)
    rect.eulerAngles = roomGo.transform.eulerAngles

    local room = AircraftRoom3DUI:New(req, roomGo)
    room:Show(roomData, state, spaceID)
    return room
end

function AircraftSceneManager:RefreshUI(spaceID)
    ---@type AircraftRoomBase
    local roomData = self._aircraftModule:GetRoom(spaceID)
    local state = self:GetUIState(spaceID)
    self.uiTable[spaceID]:Refresh(roomData, state)
end

function AircraftSceneManager:RefreshOneRoomUI(spaceId)
    local roomData = self._aircraftModule:GetRoom(spaceId)
    local state = self:GetUIState(spaceId)
    self.uiTable[spaceId]:Refresh(roomData, state)
end

function AircraftSceneManager:Update(deltaTimeMS)
    local drag = self._input:GetDrag()
    local zoom = self._input:GetScale()
    if drag or zoom then
        self:ClearCurrentRoom()
    end
    --滑屏结束交互bug12308,缩放不会
    if drag then
        self._main:StopInteraction()
    end

    -- if self.roomTable then
    --     for _, room in pairs(self.roomTable) do
    --         room:Update(deltaTimeMS)
    --     end
    -- end
end

function AircraftSceneManager:ClearCurrentRoom()
    if self._clickRoom then
        self.uiTable[self._clickRoom]:ExitRoom()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)
        self._showRoomUI = false
        self._clickRoom = nil
        self._focusRoom = nil
        self:_showAll3Dui()
    elseif self._focusRoom then
        self.uiTable[self._focusRoom]:ExitRoom()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)
        self._showRoomUI = false
        self._clickRoom = nil
        self._focusRoom = nil
        self:_showAll3Dui()
    end
end

--在房间内收集奖励，返回是否有奖励可领取
function AircraftSceneManager:TryCollectAwardInRoom(spaceID)
    local id = spaceID
    if id ~= nil and id >= 1 then
        local roomType = self._aircraftModule:GetRoom(id):GetRoomType()
        local count = 0
        if roomType == AirRoomType.MazeRoom then
            count = math.floor(self._aircraftModule:GetLightStorage())
        elseif roomType == AirRoomType.TowerRoom then
            count = math.floor(self._aircraftModule:GetHeartAmberCount())
        elseif roomType == AirRoomType.PrismRoom then
            count = math.floor(self._aircraftModule:GetPhysicStorage())
        end
        if count >= 1 then
            GameGlobal.TaskManager():StartTask(
                function(TT)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "RequestCollectAsset")
                    local result, msg = self._aircraftModule:RequestCollectAsset(TT, id)
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "RequestCollectAsset")
                    if result:GetSucc() then
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftTryRefreshRoomUI, id)
                        self:RefreshOneRoomUI(id)
                        GameGlobal.UIStateManager():ShowDialog("UIGetItemController", msg.asset)
                    else
                        ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(result:GetResult()))
                    end
                end
            )
            return true
        end
    end
    return false
end


function AircraftSceneManager:SelectRoom(id, focus, param)
    if not self.uiTable[id] then
        return
    end

    --播放点击房间音效
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)

    local room = self.roomTable[id]

    local state = self.uiTable[id]:GetState()
    if state == AirUIState.AisleNotOpen then
    elseif state == AirUIState.AisleUnbuild then
        Log.exception("[Aircraft] 严重错误，过道没有未建造状态")
    elseif state == AirUIState.AisleUnclean then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftCleanSpace, id)
    elseif state == AirUIState.Aisle then
    elseif state == AirUIState.SpaceNotOpen then
        --点到了未建造的房间
        GameGlobal.UIStateManager():ShowDialog("UIAircraftRoomUnLockTipsController", id)
    elseif state == AirUIState.SpaceUnbuild then
        --房间不再有未建造状态
        -- Log.exception("严重错误：11月12号中午以后客户端不再处理房间的未建造状态，在此之前的账号不再可用，申请新的账号或等待清库")
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftBuildRoom, id)
    elseif state == AirUIState.SpaceUnclean then
        --点击未清理房间，直接弹出建造弹窗
        self:ClickRoom(id, room, state, focus)
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftCleanSpace, id)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftBuildRoom, id)
    elseif state == AirUIState.RoomBuilding then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSpeedUp, id, AircraftRoomOperation.BuildSpeedUp)
    elseif state == AirUIState.RoomIdle or state == AirUIState.CanCollectAward or state == AirUIState.HaveNewTask then
        self:ClickRoom(id, room, state, focus)
    elseif state == AirUIState.RoomStopWork then
        self:ClickRoom(id, room, state, focus)
    elseif state == AirUIState.RoomUpgrading then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSpeedUp, id, AircraftRoomOperation.UpgradeSpeedUp)
    elseif state == AirUIState.EvilClearing then
        ToastManager.ShowToast(StringTable.Get("str_toast_manager_evil_spirits_in_purification"))
    elseif state == AirUIState.EvilClearEnd then
        ToastManager.ShowToast(StringTable.Get("str_toast_manager_evil_spirits_in_purification_complete"))
    elseif state == AirUIState.SpaceCleaning then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSpeedUp, id, AircraftRoomOperation.CleanSpeedUp)
    elseif state == AirUIState.RoomDegrading then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSpeedUp, id, AircraftRoomOperation.DegradeSpeedUp)
    elseif state == AirUIState.RestAreaRoom then
        self:ClickRoom(id, room, state, focus)
    elseif state == AirUIState.RestAreaRoomLock then
        --锁定也能点
        self:ClickRoom(id, room, state, focus)
    elseif state == AirUIState.RoomTearing then
        self:ClickRoom(id, room, state, focus)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftSpeedUp, id, AircraftRoomOperation.DegradeSpeedUp)
    elseif state == AirUIState.CollectAward then
        self:ClickRoom(id, room, state, focus)
    --风船系统QA_领取材料逻辑修改
    -- --领取奖励状态在最后处理
    -- GameGlobal.TaskManager():StartTask(
    --     function(TT)
    --         local result, msg = self._aircraftModule:RequestCollectAsset(TT, id)
    --         if result:GetSucc() then
    --             GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftTryRefreshRoomUI, id)
    --             --刷新整个房间数据
    --             self:RefreshOneRoomUI(id)
    --             GameGlobal.UIStateManager():ShowDialog("UIGetItemController", msg.asset)
    --             --导航栏接受事件
    --             GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshNavMenuData)
    --         else
    --             ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(result:GetResult()))
    --         end
    --     end
    -- )
    end
end

---@param spaceGO table<number,UnityEngine.RaycastHit>
function AircraftSceneManager:ClickSpace(results)
    --星灵
    ---@type AircraftPet
    local clickPet = nil
    --房间
    local clickRoom = nil
    --奖励物
    local awardObject = nil
    --熔炼炉
    local clickSmelt = nil
    local petpoint = nil
    local clickTactic = nil
    for i = 1, #results do
        local collider = results[i].collider
        local pet = self._main:GetPetByCollider(collider)
        if pet then
            petpoint = results[i].point
            clickPet = pet
            break
        end
    end

    --如果没有点击到星灵，则优先判定是否点击了熔炼炉
    if not clickPet then
        for i = 1, #results do
            local name = results[i].transform.name
            if name == "smelt" then
                --点到了熔炼炉
                clickSmelt = true
            end
        end
    end
    if not clickPet then
        for i = 1, #results do
            local name = results[i].transform.name
            if name == "tactic" then
                --点到了战术室
                clickTactic = true
            end
        end
    end

    local clickBookShelf = false
    --如果没有点击到星灵，则判定是否点击了书架
    if not clickPet then
        for i = 1, #results do
            local name = results[i].transform.name
            if name == "BookShelf" then
                --点到了熔炼炉
                clickBookShelf = true
            end
        end
    end

    local clicDispatchTaskMap = false
    --如果没有点击到星灵，则判定是否点击了派遣室任务地图
    if not clickPet then
        for i = 1, #results do
            local name = results[i].transform.name
            if name == "DispatchTaskMap" then
                --点到了派遣室任务地图
                clicDispatchTaskMap = true
            end
        end
    end
    local clickAward = false
    --如果没有点击到星灵，则判定是否点击了房间领奖区域
    if not clickPet then
        for i = 1, #results do
            local name = results[i].transform.name
            if name == "award" then
                --点到了派遣室任务地图
                clickAward = true
            end
        end
    end

    local id = 0
    for _, hit in ipairs(results) do
        local go = hit.transform.gameObject
        local _id = table.ikey(self.roomGoTable, go)
        if _id ~= nil and _id > 0 then
            id = _id
            break
        end
    end
    if id > 0 then
        clickRoom = id
        local ui = self.uiTable[id]
        if ui then
            for _, hit in ipairs(results) do
                local go = hit.transform.gameObject
                if ui:IsAwardObject(go) then
                    awardObject = go
                    break
                end
            end
        else
            clickRoom = nil
        end
    end

    local triggerGuide = false
    if clickRoom then
        local ui = self.uiTable[clickRoom]
        if ui then
            local state = ui:GetState()
            if state == AirUIState.RoomIdle or state == AirUIState.RestAreaRoom then
                --已经解锁的房间才触发引导
                local guideModule = GameGlobal.GetModule(GuideModule)
                if not guideModule:GuideInProgress() then
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.GuideRoomEnter,
                        clickRoom,
                        function(guide)
                            triggerGuide = guide
                        end
                    )
                end
            end
        end
    end
    --是否聚焦到房间
    local focus = true
    --是否选中房间
    local select = false
    local selectPet = false
    --点击一次可能点击到房间、房间内的领取奖励按钮和星灵，需要处理它们的关系
    if triggerGuide then
        focus = true
        self._main:StopInteraction()
        self:SelectRoom(id, focus)
        self:SelectRoom(id, focus)
        AirLog("点击到触发新手引导的房间:", id)
        return
    elseif clickRoom and not awardObject and not clickPet then
        --只点到了房间
        select = true
        focus = true
        selectPet = false
        self._main:StopInteraction()
        AirLog("只点击到房间，spaceID:", clickRoom)
    elseif not clickRoom and not awardObject and clickPet then
        --只点到了星灵
        select = false
        focus = false
        selectPet = true
        AirLog("只点击到星灵：", clickPet:TemplateID())
    elseif clickRoom and awardObject and not clickPet then
        --房间和奖励
        select = true
        focus = true
        selectPet = false
        local state = self.uiTable[id]:GetState()
        if state ~= AirUIState.CollectAward then
            --当前房间不可从外部领取奖励，但点中了房间内的领取按钮
            self:TryCollectAwardInRoom(id)
        end
        self._main:StopInteraction()
        AirLog("点击到房间和房间内的奖励，spaceID：", clickRoom)
    elseif clickRoom and not awardObject and clickPet then
        selectPet = true
        --房间和星灵
        local state = self.uiTable[id]:GetState()
        if state < AirUIState.SpaceUnbuild then
            select = false
            focus = false
        else
            select = true
            focus = false
        end
        AirLog("点击到房间和星灵，spaceID:", clickRoom, "，petID:", clickPet:TemplateID())
    elseif clickRoom and awardObject and clickPet then
        selectPet = true
        --全点到了
        local state = self.uiTable[id]:GetState()
        if state ~= AirUIState.CollectAward then
            if self:TryCollectAwardInRoom(id) then
                selectPet = false
            end
        end
        if state < AirUIState.SpaceUnbuild then
            select = false
        else
            select = true
        end
        --聚焦星灵与聚焦房间一定不共存
        focus = not selectPet
        AirLog("点击到房间、星灵和奖励，spaceID:", clickRoom, "，petID:", clickPet:TemplateID())
    elseif not clickRoom and not awardObject and not clickPet then
        --啥都没点到
        --取消房间选中 @lixuesen 风船系统QA_点击非房间区域取消选中
        self:ClearCurrentRoom()
        return
    else
        Log.exception("[AircraftScene] 点击结果错误：room", clickRoom, ", award:", awardObject, ", pet:", clickPet)
    end

    if selectPet then
        self._main:OnClickPet(clickPet, petpoint)
    else
        if clickSmelt then
            GameGlobal.UIStateManager():ShowDialog("UIAircraftItemSmeltController")
        elseif clickTactic then
            GameGlobal.UIStateManager():ShowDialog("UIAircraftTactic")
        elseif clickBookShelf then
            GameGlobal.UIStateManager():ShowDialog("UIBookController")
        elseif clicDispatchTaskMap then
            GameGlobal.UIStateManager():ShowDialog("UIDispatchMapController")
        elseif clickAward then
            local state = self.uiTable[id]:GetState()

            if state == AirUIState.CollectAward then
                Log.debug("###[ClickAward] clickAward")
                --风船系统QA_领取材料逻辑修改
                -- --领取奖励状态在最后处理
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "clickAward")
                GameGlobal.TaskManager():StartTask(
                    function(TT)
                        local result, msg = self._aircraftModule:RequestCollectAsset(TT, id)
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "clickAward")
                        if result:GetSucc() then
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftTryRefreshRoomUI, id)
                            --刷新整个房间数据
                            self:RefreshOneRoomUI(id)
                            GameGlobal.UIStateManager():ShowDialog("UIGetItemController", msg.asset)
                            --导航栏接受事件
                            GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshNavMenuData)
                        else
                            ToastManager.ShowToast(self._aircraftModule:GetErrorMsg(result:GetResult()))
                        end
                    end
                )
            end
        end
    end
    if clickRoom == nil or not select then
        return
    end

    if selectPet then
        local id = clickPet:TemplateID()
        if not self._main:IsRandomStoryPet(id) and not self._main:IsGiftPet(id) and not self._main:HasVisitGift(id) then
            self:SelectRoom(id, focus)
        end
    else
        self:SelectRoom(id, focus)
    end
end

---@param _idx number 空间ID
function AircraftSceneManager:GetUIState(_idx)
    ---@type AircraftSpace
    local spaceData = self._aircraftModule:GetSpaceInfo(_idx)
    local buildType = Cfg.cfg_aircraft_space[_idx].BuildType[1]

    if spaceData == nil then
        --空间未开放，区分过道
        -- local configData = Cfg.cfg_aircraft_space {ID = _idx}[1]
        -- local buildType = self.configTypes[_idx][1]
        if buildType == nil then
            Log.fatal("[aircraft] space idx error: ", _idx)
            return nil
        end
        if buildType == AirRoomType.AisleRoom then
            --过道
            return AirUIState.AisleNotOpen
        else
            local unlockTime = Cfg.cfg_aircraft_space[_idx].UnlockTime
            if unlockTime then
                local now = GetSvrTimeNow()
                local time =
                    GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(
                    unlockTime,
                    Enum_DateTimeZoneType.E_ZoneType_GMT
                )
                if now < time then
                    return AirUIState.SpaceClosed
                end
            end
            return AirUIState.SpaceNotOpen
        end
    else
        local spaceState = spaceData.space_status

        ---@type AircraftRoomBase
        local roomData = self._aircraftModule:GetRoom(_idx)

        local isAisle = buildType == AirRoomType.AisleRoom
        if isAisle then
            --过道
            if spaceState == SpaceState.SpaceStateNeedClean then
                return AirUIState.AisleUnclean
            elseif spaceState == SpaceState.SpaceStateCleaning then
                Log.exception("[Aircraft] 严重错误，过道状态为清理中")
            elseif spaceState == SpaceState.SpaceStateEmpty then
                return AirUIState.AisleUnbuild
            elseif spaceState == SpaceState.SpaceStateFull then
                return AirUIState.Aisle
            else
                Log.fatal("[aircraft] space state error: ", "Idx: ", _idx, " SpaceState: ", spaceState)
                return nil
            end
        else
            local unlockTime = Cfg.cfg_aircraft_space[_idx].UnlockTime
            if unlockTime then
                local now = GetSvrTimeNow()
                local time =
                    GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(
                    unlockTime,
                    Enum_DateTimeZoneType.E_ZoneType_GMT
                )
                if now < time then
                    return AirUIState.SpaceClosed
                end
            end

            if buildType == AirRoomType.DispatchRoom then
                if roomData and roomData:HasCompleteTask() then
                    return AirUIState.CanCollectAward
                end
                if roomData and roomData:HasNewTask() then
                    return AirUIState.HaveNewTask
                end
            end

            --普通空间
            if spaceState == SpaceState.SpaceStateNeedClean then
                return AirUIState.SpaceUnclean
            elseif spaceState == SpaceState.SpaceStateCleaning then
                return AirUIState.SpaceCleaning
            elseif spaceState == SpaceState.SpaceStateBuilding then
                return AirUIState.RoomBuilding
            elseif spaceState == SpaceState.SpaceStateEmpty then
                return AirUIState.SpaceUnbuild
            elseif spaceState == SpaceState.SpaceStateUpgrading then
                return AirUIState.RoomUpgrading
            elseif spaceState == SpaceState.SpaceStateDegrading then
                if roomData:Level() <= 1 then
                    return AirUIState.RoomTearing
                else
                    return AirUIState.RoomDegrading
                end
            elseif spaceState == SpaceState.SpaceStateFull then
                --idle 状态
                local roomType = roomData:GetRoomType()
                if roomType == AirRoomType.PurifyRoom then
                    --对恶鬼净化室做处理，判断净化中和净化完成
                    local purityState = roomData:PurifyStatus()
                    if purityState == PurifyRoomStatus.EVIL_WITHOUT_PURIFY or purityState == PurifyRoomStatus.NO_EVIL then
                        return AirUIState.RoomIdle
                    elseif purityState == PurifyRoomStatus.PURIFING then
                        return AirUIState.EvilClearing
                    elseif purityState == PurifyRoomStatus.WAITING_COLLECT_AWARD then
                        return AirUIState.EvilClearEnd
                    else
                        Log.fatal("[aircraft] purify room state error: state-->", purityState)
                        return nil
                    end
                elseif self._aircraftModule:IsAmusementRoom(roomType) then
                    if roomData:Level() > 1 then
                        return AirUIState.RestAreaRoom
                    else
                        return AirUIState.RestAreaRoomLock
                    end
                elseif
                    roomType == AirRoomType.MazeRoom or roomType == AirRoomType.PrismRoom or
                        roomType == AirRoomType.TowerRoom
                 then
                    if roomData:CanCollectOutside() then
                        return AirUIState.CollectAward
                    else
                        return AirUIState.RoomIdle
                    end
                else
                    return AirUIState.RoomIdle
                end
            else
                Log.fatal("[aircraft] space state error: ", "Idx: ", _idx, " state: ", spaceState)
                return nil
            end
        end
    end
end

--获取某个房间是否可建造，导航栏用
function AircraftSceneManager:GetRoomCanBuildForNav(spaceid)
    local canBuild = false
    ---@type AircraftRoom3DUI
    local spaceState = self.uiTable[spaceid]
    if spaceState then
        local state = spaceState:GetState()
        if state == AirUIState.SpaceUnbuild or state == AirUIState.SpaceUnclean then
            --判断材料
            local cfg_space = Cfg.cfg_aircraft_space[spaceid]
            local roomType = cfg_space.BuildType[1]

            local cfg = Cfg.cfg_aircraft_room {RoomType = roomType, Level = 1}[1]
            if cfg then
                local powerEnough = true
                local needPower = cfg.NeedPower
                if needPower then
                    local havePower = self._aircraftModule:GetPower()
                    if havePower < needPower then
                        powerEnough = false
                    end
                end

                local matEnough = true
                local needMat = cfg.Need
                if needMat then
                    for i = 1, #needMat do
                        local needMatID = needMat[i][1]
                        local needMatCount = needMat[i][2]

                        local roleModule = GameGlobal.GetModule(RoleModule)
                        local itemCount = roleModule:GetAssetCount(needMatID)
                        if itemCount < needMatCount then
                            matEnough = false
                            break
                        end
                    end
                end

                if matEnough and powerEnough then
                    canBuild = true
                end
            else
                Log.fatal(
                    "###[AircraftSceneManager] GetRoomCanBuildForNav Cfg.cfg_aircraft_room[spaceid] is nil ! id ->",
                    spaceid
                )
            end
        end
    end
    return canBuild
end

--------------------- 跳转房间 ----------------------------
function AircraftSceneManager:GetRoomSpace(spaceId)
    for index, room in ipairs(self.roomTable) do
        local _spaceId = room._roomLogicData._spaceid
        if _spaceId == spaceId then
            return room._roomGO, index
        end
    end
    return nil, -1
end

function AircraftSceneManager:GotoSpace(spaceId)
    AirLog("新手引导触发点击房间：", spaceId)
    local roomGO = self.roomGoTable[spaceId]
    if roomGO then
        self:ClickSpace({roomGO})
    end
end

function AircraftSceneManager:GetBtnGuide(spaceId)
    AirLog("新手引导获取3dui按钮")
    return self.uiTable[spaceId]:GetBtnGuide()
end
----------------------------------------------------------------

function AircraftSceneManager:Set3DUIActive(active)
    self.canvasRoot.gameObject:SetActive(active)
    for _, ui in pairs(self.uiTable) do
        ui:SetAwardUIActive(not active)
    end
end

function AircraftSceneManager:GetDoorBySpaceID(spaceId)
    return self.doors[spaceId]
end

function AircraftSceneManager:SetOneRoomUIActive(spaceID, active)
    self.uiTable[spaceID]:SetActive(active)
end

---@return AircraftRoom
function AircraftSceneManager:GetRoomByArea(area)
    return self._restRoomTable[area]
end
---@return AircraftBoard
function AircraftSceneManager:GetBoard3()
    return self._boards[3]
end
---@return AircraftBoard
function AircraftSceneManager:GetBoard4()
    return self._boards[4]
end

function AircraftSceneManager:CurrentSelectSpaceID()
    return self._clickRoom
end

function AircraftSceneManager:ExitPointPos()
    return self._leavePoint
end

function AircraftSceneManager:SetGotoSpaceId(gotoSpaceId, param)
    AirLog("新手引导设置空间id：", gotoSpaceId)
    if gotoSpaceId and gotoSpaceId > 0 then
        self:SelectRoom(gotoSpaceId)
        self:SelectRoom(gotoSpaceId, true)

        --如果是跳转过来的，需要打开房间界面
        if param then
            local airModule = GameGlobal.GetModule(AircraftModule)
            --解锁
            ---@type aircraft_space_info
            local space = airModule:GetSpaceInfo(gotoSpaceId)
            if not space then
                ToastManager.ShowToast("Space is nil !")
                return
            end
            if space.space_status == SpaceState.SpaceStateFull then
                ---@type AircraftRoomBase
                local room = airModule:GetRoom(gotoSpaceId)
                if room then
                    if room:GetRoomType() == AirRoomType.SmeltRoom then
                        --param - 材料id
                        GameGlobal.UIStateManager():ShowDialog("UIAircraftItemSmeltController", param)
                    elseif room:GetRoomType() == AirRoomType.TacticRoom then
                        GameGlobal.UIStateManager():ShowDialog("UIAircraftTactic", param)
                    end
                end
            else
                ToastManager.ShowToast("Room is UnLock !")
            end
        end
    end
end

function AircraftSceneManager:GuideGotoSpace(spaceId)
    AirLog("新手引导聚焦到房间：", spaceId)
    self._main:FocusRoom(
        self.roomTable[spaceId],
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, spaceId)
            local triggerGuide = false
            --已经解锁的房间才触发引导
            local guideModule = GameGlobal.GetModule(GuideModule)
            if not guideModule:GuideInProgress() then
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.GuideRoomEnter,
                    spaceId,
                    function(guide)
                        triggerGuide = guide
                    end
                )
            end
        end
    )
end

--进入装扮模式前清空数据
function AircraftSceneManager:ClearBeforeDecorate()
    for _, room in pairs(self._restRoomTable) do
        room:ClearPets()
    end

    for _, room in pairs(self.roomTable) do
        room:ReleaseAllPoints()
    end

    for _, b in pairs(self._boards) do
        b:ReleaseAllPoints()
    end
end

--进入装扮模式
function AircraftSceneManager:OnStartDecorate()
    self:ClearCurrentRoom()
    self:ClearBeforeDecorate()

    for _, room in pairs(self.roomTable) do
        room:OnStartDecorate()
    end
end

--退出装扮模式
function AircraftSceneManager:OnStopDecorate()
    for _, room in pairs(self.roomTable) do
        room:OnStopDecorate()
    end
end
