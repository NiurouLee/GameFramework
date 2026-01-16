--[[
    风船家具，目前家具属于区域而不是房间
]]
---@class AircraftFurniture:Object
_class("AircraftFurniture", Object)
AircraftFurniture = AircraftFurniture
function AircraftFurniture:Constructor(req, go, floor, area)
    --所属区域
    self._area = area

    --分配1个实例id，用于区分家具
    self._instanceID = GridHelper.CreateFurnitureInstanceID()

    self._pets = {}

    ---@type table<number,AircraftFurniturePoint>
    self._points = {}

    --动态加载的家具会传入ResRequest，房间自带的家具不需要加载，传入GameObject
    if req then
        go = req.Obj
        self._req = req
    end
    ---@type UnityEngine.GameObject
    self._go = go
    go:SetActive(true)
    go.layer = AircraftLayer.Furniture

    self._transform = go.transform

    ---@type UnityEngine.AI.NavMeshObstacle
    local obs = self._go:GetComponent(typeof(UnityEngine.AI.NavMeshObstacle))
    if obs == nil then
        AirLog("家具没有NavMeshObstacle组件：", self._go.name)
    else
        obs.carving = true
    end

    --家具需要明确自己在哪一层
    self._floor = floor

    local grids = nil
    for i = self._transform.childCount - 1, 0, -1 do
        local child = self._transform:GetChild(i)
        if string.find(child.name, "F_Grid=") then
            grids = child
            break
        end
    end

    if grids then
        local localPos = grids.localPosition:Clone()
        self._offset = Vector2(localPos.x / GridHelper.SIZE, localPos.z / GridHelper.SIZE)
        self._offset.x = GridHelper.ToFloat(GridHelper.ToInt(self._offset.x))
        self._offset.y = GridHelper.ToFloat(GridHelper.ToInt(self._offset.y))
        self._gridAreaParent = grids
    end

    self:Init()
    --阴影组件
    -- if self._hasModel then
    --     GameObjectHelper.AddVolumeComponent(go)
    -- end

    --占据的格子是否已经释放
    self._tileReleased = false
end

function AircraftFurniture:Init()
    self._cfgID = tonumber(self._go.name)
    local cfg = Cfg.cfg_item_furniture[self._cfgID]
    if cfg == nil then
        Log.exception("[AircraftFurniture] 找不到家具配置：", self._cfgID)
    end
    self._type = cfg.AirFurnitureType

    local model = self._go.transform:Find("model")
    --有些家具可能会没有模型，model没有子物体代表没有模型
    self._hasModel = model.childCount > 0
    self._effectSlot = self._go.transform:Find("EffectSlot")
    if self._hasModel then
        --家具除了动态加载的特效之外，还有一些特效属于家具的一部分，这些特效统一挂在effect节点下，比如投影仪
        self._furEffect = model:GetChild(0):Find("effect")
        self._modelT = model
    end
    ---@type UnityEngine.Animation
    self._animation = model.gameObject:GetComponentInChildren(typeof(UnityEngine.Animation))

    if cfg.FurIdleAction then
        self._idleAnimName = cfg.FurIdleAction
        self:Anim_Play(cfg.FurIdleAction)
    end

    self._petDefaultActionCfg = cfg.DefaultAction
    if cfg.SpecialAction then
        self._petSpecialActionCfg = {}
        for _, value in ipairs(cfg.SpecialAction) do
            --星灵行为对应的是皮肤ID
            local petSkinID = value[1]
            local cfgID = value[2]
            self._petSpecialActionCfg[petSkinID] = cfgID
        end
    end

    --region points
    local pointsRootGo = self._go.transform:Find("pointsRoot").gameObject
    if pointsRootGo then
        local pointsRoot = pointsRootGo.transform
        local count = pointsRoot.childCount
        if count <= 0 then
            AirLog("家具的交互点数量为", count)
        else
            for i = 0, count - 1 do
                local actionPoint = pointsRoot:GetChild(i)
                local idx = i + 1
                local aircraftFurniturePoint = AircraftFurniturePoint:New(idx, actionPoint)
                self._points[idx] = aircraftFurniturePoint
            end
        end
    else
        AirLog("家具没有交互点：", self._cfgID)
    end

    --endregion
    --当前可用点
    self._available = #self._points
    --正在家具上交互的星灵数量，星灵在向家具走的过程中会占据一个点，但并没有立刻与家具交互
    self._petOnCount = 0

    self._hasExtraAnim = cfg.HasExtraAnim
end

function AircraftFurniture:Dispose()
    if self._req then
        self._req:Dispose()
    end

    if self._footReqs then
        for _, req in ipairs(self._footReqs) do
            req:Dispose()
        end
    end
    if self._gridAreaReq then
        self._gridAreaReq:Dispose()
    end

    --删除家具后保存，会导致
    if not self._tileReleased then
        self:OccupyTiles(false)
    end
    self._occupiedTiles = nil

    if self._shaker then
        self._shaker:Kill()
        self._shaker = nil
    end
end

function AircraftFurniture:GetPets()
    local ids = {}
    for id, _ in pairs(self._pets) do
        ids[#ids + 1] = id
    end
    return ids
end

--占据一个点，并返回Point
---@return AircraftFurniturePoint
function AircraftFurniture:PopPoint()
    if self._available <= 0 then
        Log.fatal("[AircraftFurniture] no point")
        return
    end
    local target = math.random(1, self._available)
    local i = 1
    for idx, point in ipairs(self._points) do
        if not point:IsOccupied() then
            if i == target then
                self._available = self._available - 1
                point:Occupy()
                return point
            end
            i = i + 1
        end
    end
end
---@param point AircraftFurniturePoint
function AircraftFurniture:ReleasePoint(point)
    if not table.icontains(self._points, point) then
        Log.fatal("[AircraftFurniture] 当前家具不包含该点")
    end

    point:Release()
    self._available = self._available + 1

    if self._available > #self._points then
        Log.exception("家具点数量错误，", self._cfgID, "数量：", self._available)
    end
end

function AircraftFurniture:OccupyPointByIndex(idx)
    local point = self._points[idx]
    self._available = self._available - 1
    point:Occupy()
    return point
end

--该点是否被占据
function AircraftFurniture:IsPointOccupied(idx)
    return self._points[idx]:IsOccupied()
end

function AircraftFurniture:AvailableCount()
    return self._available
end

--通过名称占据1个点
function AircraftFurniture:PopPointByName(name)
    for _, point in ipairs(self._points) do
        if point:Name() == name and not point:IsOccupied() then
            self._available = self._available - 1
            point:Occupy()
            return point
        end
    end
end

--通过名称获取1个未占据的点，但不占据
function AircraftFurniture:GetPointByName(name)
    for _, point in ipairs(self._points) do
        if point:Name() == name and not point:IsOccupied() then
            return point
        end
    end
end

--按名字判定是否有可用的点
function AircraftFurniture:HasAvailablePoint(name)
    for _, point in ipairs(self._points) do
        if point:Name() == name and not point:IsOccupied() then
            return true
        end
    end
end

--占据所有点
function AircraftFurniture:OccupyAllPoint(occupy)
    for _, point in ipairs(self._points) do
        if occupy then
            point:Occupy()
        else
            point:Release()
        end
    end
    if occupy then
        self._available = 0
    else
        self._available = #self._points
    end
end

function AircraftFurniture:HasPoint(idx)
    return self._points[idx] ~= nil
end

function AircraftFurniture:Floor()
    return self._floor
end

function AircraftFurniture:Type()
    return self._type
end
function AircraftFurniture:Area()
    return self._area
end
function AircraftFurniture:CfgID()
    return self._cfgID
end
function AircraftFurniture:ID()
    Log.exception("家具的ID接口已删除，请使用CfgID()获取家具的配置ID。", debug.traceback())
end

--实例id只用于在运行时区分家具
function AircraftFurniture:InstanceID()
    return self._instanceID
end

function AircraftFurniture:MatchKey(key)
    return key == self:GetPstKey()
end

--获取家具的唯一持久id
---@return string
function AircraftFurniture:GetPstKey()
    if self._svrData then
        return string.format(
            "%s|%s|%s|%s|%s",
            self._svrData.asset_id,
            self._svrData.area_id,
            self._svrData.surface,
            self._svrData.pos_x,
            self._svrData.pos_z
        )
    else
        --不能动的家具每个区域只会有1个，所以通过配置id和区域id能组成唯一索引
        return string.format("%s|%s", self._cfgID, self._area)
    end
end

function AircraftFurniture:EffectSlot()
    return self._effectSlot
end

--是否没有星灵在家具上
function AircraftFurniture:IsEmpty()
    return self._available >= #self._points
end

--与家具交互时，星灵从家具上获取行为配置
function AircraftFurniture:GetPetActionCfg(skinID)
    local cfg
    if self._petSpecialActionCfg then
        cfg = self._petSpecialActionCfg[skinID]
    end
    if cfg == nil then
        cfg = self._petDefaultActionCfg
    end
    return cfg
end

---@param pet AircraftPet
function AircraftFurniture:OnPetArrive(pet)
    self._pets[pet:TemplateID()] = true
    self._petOnCount = self._petOnCount + 1
end

---@param pet AircraftPet
function AircraftFurniture:OnPetLeave(pet)
    if self._pets[pet:TemplateID()] then
        self._pets[pet:TemplateID()] = nil
        self._petOnCount = self._petOnCount - 1
    else
        Log.exception(
            "[AircraftFurniture] 星灵不在家具上，无法离开。星灵id：",
            pet:TemplateID(),
            ", 家具id：",
            self._cfgID,
            debug.traceback()
        )
    end

    --判断是否需要恢复空闲动作
    if self._petOnCount > 0 then
    else
        --家具上没有星灵，恢复默认家具的动画
        if self._idleAnimName then
            self:Anim_Play(self._idleAnimName)
        end
    end
end

function AircraftFurniture:Anim_Play(name)
    if not self._animation then
        Log.exception("[AircraftFurniture] 找不到Animation不能播放，家具id：", self._cfgID, debug.traceback())
    end
    self._animation:Play(name)
end

--停止动画
function AircraftFurniture:Anim_Stop()
    if self._animation then
        if self._animation.isPlaying then
            local clips = HelperProxy:GetInstance():GetAllAnimationClip(self._animation)
            for i = 0, clips.Length - 1 do
                ---@type UnityEngine.AnimationClip
                local clip = clips[i]
                if self._animation:IsPlaying(clip.name) then
                    ---@type UnityEngine.AnimationState
                    local state = self._animation:get_Item(clip.name)
                    state.time = 0
                    state.enabled = true
                    state.weight = 1
                    self._animation:Sample()
                    state.enabled = false
                    break
                end
            end
        end
        self._animation:Stop()
    end
end

function AircraftFurniture:Animation()
    return self._animation
end

---@return UnityEngine.Tranform
function AircraftFurniture:Transform()
    return self._transform
end

--此家具有没有模型
function AircraftFurniture:HasModel()
    return self._hasModel
end

--显隐家具特效
function AircraftFurniture:SetEffectActive(active)
    if self._effectSlot then
        self._effectSlot.gameObject:SetActive(active)
    end
    if self._furEffect then
        self._furEffect.gameObject:SetActive(active)
    end
end
--region 装扮新增
--所属的平面

---@param data MobileFurnitureInfo 初始化家具的装扮信息
function AircraftFurniture:SetDecorateData(data, newAdder, worldPos, worldRot)
    self._svrData = data
    self._gridPosition = Vector2(GridHelper.ToFloat(data.pos_x), GridHelper.ToFloat(data.pos_z))
    ---@type number
    self._rotY = data.rot
    self._surfaceID = data.surface

    local cfg = Cfg.cfg_item_furniture[self._cfgID]
    if cfg == nil then
        Log.exception("找不到家具配置：", self._cfgID)
    end
    self._layer = cfg.Layer
    self._locationType = cfg.LocateType
    self._oprateType = cfg.OprateType
    self._size = Vector2(cfg.Size[1], cfg.Size[2])
    self._ambient = cfg.Atmosphere

    self:SetPosition(worldPos)
    self:SetRotation(worldRot)
end

function AircraftFurniture:SurfaceID()
    return self._surfaceID
end
--平面内位置
function AircraftFurniture:GridPosition()
    return self._gridPosition
end
--平面内旋转，只绕y轴转
function AircraftFurniture:GridRotY()
    return self._rotY
end

function AircraftFurniture:Size()
    return self._size
end

--氛围配置，不包含工作技加成
function AircraftFurniture:Ambient()
    return self._ambient
end

function AircraftFurniture:Offset()
    return self._offset
end

function AircraftFurniture:WorldPosition()
    return self._worldPosition
end

function AircraftFurniture:WorldRotation()
    return self._worldRotation
end

function AircraftFurniture:SetPosition(p)
    self._worldPosition = p --保存一份，获取时不用调c#
    self._transform.position = p:Clone()
end

function AircraftFurniture:SetRotation(r)
    self._worldRotation = r
    self._transform.rotation = r:Clone()
end

function AircraftFurniture:Layer()
    return self._layer
end

function AircraftFurniture:LocationType()
    return self._locationType
end

function AircraftFurniture:OprateType()
    return self._oprateType
end

function AircraftFurniture:IsThisGO(go)
    return self._go == go
end

--撤下，并未保存，只是临时隐藏家具
function AircraftFurniture:SetActive(active)
    self._go:SetActive(active)
end

--返回服务器下发的数据
function AircraftFurniture:GetSvrData()
    return self._svrData
end

function AircraftFurniture:_showFootprint(show)
    if show then
        if self._footprints then
            for _, go in ipairs(self._footprints) do
                go:SetActive(true)
            end
        else
            if self._points and #self._points > 0 then
                self._footReqs = {}
                self._footprints = {}
                for i, point in ipairs(self._points) do
                    local target = point:Target()
                    local req =
                        ResourceManager:GetInstance():SyncLoadAsset("AircraftFootprint.prefab", LoadType.GameObject)
                    self._footReqs[i] = req
                    local t = req.Obj.transform
                    t:SetParent(target)
                    t.localPosition = Vector3.zero
                    t.localRotation = Quaternion.identity
                    local go = req.Obj
                    go:SetActive(true)
                    self._footprints[i] = go
                end
            end
        end
    else
        if self._footprints then
            for _, go in ipairs(self._footprints) do
                go:SetActive(false)
            end
        end
    end
end

function AircraftFurniture:_showGridArea(show, pickUp)
    if show then
        if self._gridAreaParent == nil then
            Log.exception("家具没有FGrid节点:", self._cfgID)
        end
        if not self._areaGridImage then
            local req = ResourceManager:GetInstance():SyncLoadAsset("AircraftFurnitureArea.prefab", LoadType.GameObject)
            self._gridAreaReq = req
            local go = req.Obj
            local t = go.transform
            go:SetActive(true)
            self._areaGridCanvas = go
            t:SetParent(self._gridAreaParent)
            t.localPosition = Vector3(0, -GridHelper.PICKUPHEIGHT + 0.05, 0)
            t.localRotation = Quaternion.identity
            ---@type UIView
            local uiview = go:GetComponent(typeof(UIView))
            local image = uiview:GetUIComponent("Image", "Image")
            local rect = uiview:GetUIComponent("RectTransform", "Image")
            rect.sizeDelta = Vector2(self._size.x / 0.006 * GridHelper.SIZE, self._size.y / 0.006 * GridHelper.SIZE)
            self._areaGridImage = image
            trans = t
        end
        self._areaGridCanvas:SetActive(true)

        if pickUp then
            self._areaGridCanvas.transform.localPosition = Vector3(0, -GridHelper.PICKUPHEIGHT + 0.05, 0)
        else
            self._areaGridCanvas.transform.localPosition = Vector3(0, 0.05, 0)
        end
    else
        if self._areaGridCanvas then
            self._areaGridCanvas:SetActive(false)
        end
    end
end

function AircraftFurniture:ShowAreaAndFootprint(show, isPickUp)
    self:_showGridArea(show, isPickUp)
    self:_showFootprint(show)
end

function AircraftFurniture:ShowOutline()
    if self._outline == nil then
        self._outline = self._modelT.gameObject:AddComponent(typeof(OutlineComponent))
    end
    self._outline.enabled = true
end

function AircraftFurniture:SetOutlineColor(color)
    if self._outline then
        self._outline.outlinColor = color
    end
end

function AircraftFurniture:HideOutline()
    if self._outline then
        self._outline.enabled = false
    end
end

function AircraftFurniture:SetAreaGridValid(valid)
    if valid then
        self._areaGridImage.color = Color(5 / 255, 239 / 255, 240 / 255)
    else
        self._areaGridImage.color = Color(254 / 255, 56 / 255, 56 / 255)
    end
end

function AircraftFurniture:SetTiles(tiles)
    --该家具占据的格子
    ---@type table<number,AircraftTile>
    self._occupiedTiles = tiles
end

function AircraftFurniture:OccupyTiles(occupy)
    if self._occupiedTiles then
        for _, tile in ipairs(self._occupiedTiles) do
            if occupy then
                tile:Occupy(self._layer, self._instanceID)
            else
                tile:Release(self._layer, self._instanceID)
            end
        end
        self._tileReleased = not occupy
    end
end

function AircraftFurniture:DoShake(onFinish)
    local offset = self._transform.right * 0.5
    if self._hasModel then
        self._shaker =
            self._modelT:DOShakePosition(0.3, offset, 50, 90, false):OnComplete(
            function()
                self._shaker = nil
                if onFinish then
                    onFinish()
                end
            end
        )
    end
end

function AircraftFurniture:HasExtraAnim()
    return self._hasExtraAnim
end

function AircraftFurniture.Default()
    local f = {}
    f.GridPosition = function()
        return Vector2(2, 2)
    end
    f.GridRotation = function()
        return 30
    end
    f.Size = function()
        return Vector2(2, 2)
    end
    f.Offset = function()
        return Vector3(-1, -1)
    end
    return f
end
--endregion

-------------------------------------------------------------------
--[[
    家具点
]]
---@class AircraftFurniturePoint:Object
_class("AircraftFurniturePoint", Object)
AircraftFurniturePoint = AircraftFurniturePoint

---@param target Vector3
---@param action Vector3
---@param rotation Quaternion
function AircraftFurniturePoint:Constructor(idx, point)
    self._idx = idx
    self._occupied = false
    self._name = point.name

    self._actionPoint = point
    self._targetPoint = point:GetChild(0)
end
--移动目标点
---@return Vector3
function AircraftFurniturePoint:MovePoint()
    return self._targetPoint.position
end

function AircraftFurniturePoint:Target()
    return self._targetPoint
end

--交互点
---@return Vector3
function AircraftFurniturePoint:InteractionPoint()
    return self._actionPoint.position, self._actionPoint.rotation
end
--是否被占据
---@return boolean
function AircraftFurniturePoint:IsOccupied()
    return self._occupied
end

function AircraftFurniturePoint:Occupy()
    if self._occupied then
        Log.exception("[AircraftFurniture] 当前点已被占据")
    end
    self._occupied = true
end
function AircraftFurniturePoint:Release()
    if not self._occupied then
        Log.exception("[AircraftFurniture] 当前点未被占据，不用释放", debug.traceback())
    end
    self._occupied = false
end
function AircraftFurniturePoint:Index()
    return self._idx
end
function AircraftFurniturePoint:Name()
    return self._name
end
