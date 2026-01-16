---class Aircraft3DUIManager 风船主界面3dUI管理模块
_class("Aircraft3DUIManager", Object)
Aircraft3DUIManager = Aircraft3DUIManager

function Aircraft3DUIManager:Constructor()
    self.canvasRoot = UnityEngine.GameObject.Find("Aircraft3DUICanvas").transform
    ---@type AircraftModule
    self.aircraftModule = GameGlobal.GetModule(AircraftModule)
    self.scale = 0.03

    ---@type table<int,AircraftRoom3DUI> 所有3dui集合
    self.uiDic = {}

    --是否显示3dui
    self._isShow = true
end

function Aircraft3DUIManager:Dispose()
    for _, ui in pairs(self.uiDic) do
        ui:OnDestroy()
    end
end

function Aircraft3DUIManager:RefreshUI(spaceId, roomData, roomGo)
    --当前不显示则不刷新逻辑
    -- if not self._isShow then
    --     return
    -- end

    ---@type AircraftRoom3DUI
    local ui = self.uiDic[spaceId]
    ---@type AirUIState
    local state = self:GetUIState(spaceId)
    if ui then
        -- if ui:GetState() == state then
        --     ui:Refresh(roomData, state)
        -- else
        --     ui:OnDestroy()
        --     ui = self:CreateUI(state, roomGo)
        --     ui:Show(roomData, state, spaceId)
        --     self.uiDic[spaceId] = ui
        -- end
        -- local l_uiState = ui:GetState()
        -- if (l_uiState == AirUIState.RoomUpgrading or l_uiState == AirUIState.RoomDegrading) and state == AirUIState.RoomIdle then
        --     GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftPlayOpenDoor, spaceId)
        -- end
        --不管状态是否改变，都只刷新
        ui:Refresh(roomData, state)
    else
        -- if roomData then
        -- end
        ui = self:CreateUI(state, roomGo)
        ui:Show(roomData, state, spaceId)
        self.uiDic[spaceId] = ui
    end
end

---@param roomGo GameObject
---@return ResRequest
function Aircraft3DUIManager:LoadUIAsset(roomGo)
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
    rect.sizeDelta = Vector2(size.x / self.scale, size.y / self.scale)
    rect.eulerAngles = roomGo.transform.eulerAngles
    return req
end

function Aircraft3DUIManager:GetState(idx)
    return self.uiDic[idx]:GetState()
end

function Aircraft3DUIManager:OnEnterRoom(spaceID)
    self.uiDic[spaceID]:EnterRoom()
end

function Aircraft3DUIManager:OnExitRoom(spaceID)
    self.uiDic[spaceID]:ExitRoom()
end

---@param roomData AircraftRoomBase
function Aircraft3DUIManager:CreateUI(state, roomGo)
    local uiReq = self:LoadUIAsset(roomGo)
    return AircraftRoom3DUI:New(uiReq, roomGo)
end

function Aircraft3DUIManager:IsShow()
    return self._isShow
end

function Aircraft3DUIManager:SetUIActive(active)
    self.canvasRoot.gameObject:SetActive(active)
    self._isShow = active
end

function Aircraft3DUIManager:GetUIIndex(_uiGo)
    for i = 1, #self.uiViews do
        if self.uiViews[i] == _uiGo then
            return i
        end
    end
    return nil
end

---@param _idx number 空间ID
function Aircraft3DUIManager:GetUIState(_idx)
    ---@type AircraftSpace
    local spaceData = self.aircraftModule:GetSpaceInfo(_idx)
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
            return AirUIState.SpaceNotOpen
        end
    else
        local spaceState = spaceData.space_status

        ---@type AircraftRoomBase
        local roomData = self.aircraftModule:GetRoom(_idx)

        local isAisle = buildType == AirRoomType.AisleRoom
        if isAisle then
            --过道
            if spaceState == SpaceState.SpaceStateNeedClean then
                --未清理的空间，需要判断连通性
                if self:CanConnectToSpace(_idx) then
                    return AirUIState.AisleUnclean
                else
                    return AirUIState.AisleNotOpen
                end
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
            --普通空间
            if spaceState == SpaceState.SpaceStateNeedClean then
                --未清理的空间，需要判断连通性
                if self:CanConnectToSpace(_idx) then
                    return AirUIState.SpaceUnclean
                else
                    return AirUIState.SpaceNotOpen
                end
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
                elseif
                    roomType == AirRoomType.MazeRoom or roomType == AirRoomType.PrismRoom or
                        roomType == AirRoomType.TowerRoom
                 then
                    if roomData:CanCollectAward() then
                        return AirUIState.CollectAward
                    elseif roomData:HasNewTask() then
                        return AirUIState.HaveNewTask
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

function Aircraft3DUIManager:CanConnectToSpace(spaceID)
    -- local cfg = Cfg.cfg_aircraft_space[spaceID]
    -- for _, neighborID in ipairs(cfg.AdjacentID) do
    --     local room = self.aircraftModule:GetRoom(neighborID)
    --     --任意邻接空间可用则可连通
    --     if room and room:RoomId() > 0 then
    --         return true
    --     end
    -- end
    -- return false
    return true
end

function Aircraft3DUIManager:GetBtnGuide(spaceId)
    return self.uiDic[spaceId]:GetBtnGuide()
end
