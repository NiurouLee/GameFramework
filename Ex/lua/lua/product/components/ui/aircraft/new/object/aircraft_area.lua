--[[
    风船区域
]]
---@class AircraftArea:Object
_class("AircraftArea", Object)
AircraftArea = AircraftArea

---@param room AircraftRoom
function AircraftArea:Constructor(main, id, areaGo, room, getTile)
    ---@type AircraftMain
    self._main = main
    self._id = id
    self._floor = Cfg.cfg_aircraft_area[id].Floor
    self._go = areaGo
    ---@type AircraftRoom 区域内的房间，可以为空，表示该区域内没有房间或者房间未解锁
    self._room = room

    self._isLock = self:checkLock()
    --这里为了解决某个现网玩家的bug把休息室所有格子开放了, 不能再关闭
    --影响的范围是休息室窗边放长椅的一块格子在房间解锁前也开放了，影响范围不大，因为房间解锁时会回收所有摆过的家具
    if self._id == 3 then
        self._isLock = false
    end
    self._tileGetter = getTile

    ---@type UnityEngine.BoxCollider
    local box = areaGo:GetComponent(typeof(UnityEngine.BoxCollider))
    local pos = areaGo.transform.position + box.center - areaGo.transform.forward * (box.size.z / 2)
    -- pos.z = -8
    self._center = pos

    ---@type table<number,AircraftFurniture>
    self._furnitures = {}

    self:FlushEditData()

    --是否进入过
    self._entered = false
end

function AircraftArea:Refresh(room)
    self._room = room
    self._isLock = self:checkLock()

    self:FlushEditData()
    self._entered = false
end

--检查区域内房间是否锁定
function AircraftArea:checkLock()
    --改区域是否解锁，取绝于区域内是否有房间，若有房间则取绝于房间是否解锁，休闲区房间2级视为解锁
    local space = Cfg.cfg_aircraft_area[self._id].SpaceId
    self._spaceID = space
    if space then
        if not self._room then
            return true
        end
        local type = self._room:LogicRoomType()
        if type >= AirRoomType.AmusementBegin and type <= AirRoomType.AmusementEnd then
            --休闲区房间
            if self._room:Level() <= 1 then
                return true
            end
        end
    end
    return false
end

function AircraftArea:Dispose()
    for id, surface in pairs(self._surfaces) do
        surface:Dispose()
    end

    for _, furniture in pairs(self._furnitures) do
        furniture:Dispose()
    end
end

function AircraftArea:Floor()
    return self._floor
end

function AircraftArea:CenterPos()
    return self._center
end

function AircraftArea:IsThis(go)
    return self._go == go
end
function AircraftArea:ID()
    return self._id
end
function AircraftArea:CameraID()
    return self._defaultCameraId
end

---@param type LocationType
function AircraftArea:GetCameraCfg(type)
    return self._cameraCfg[type]
end

function AircraftArea:GetFurniture(id)
    --随便找一个
    for _, fur in pairs(self._furnitures) do
        if fur:CfgID() == id then
            return fur
        end
    end
end

---@return type<number,AircraftFurniture>
function AircraftArea:Furnitures()
    return self._furnitures
end

function AircraftArea:SpaceID()
    return self._spaceID
end

--生成编辑时数据
function AircraftArea:FlushEditData()
    local cfg = Cfg.cfg_aircraft_area[self._id]
    local cfgSurs = AircraftGrids[cfg.Floor]
    --相机配置必须为4个，顺序为：默认、地面、墙、天花板，大于0有效
    self._defaultCameraId = cfg.Cam[1]
    self._cameraCfg = {}
    --地面
    --这里写死，地面跟默认公用一套配置
    self._cameraCfg[LocationType.Floor] = self._defaultCameraId
    --墙
    if cfg.Cam[2] and cfg.Cam[2] > 0 then
        self._cameraCfg[LocationType.Wall] = cfg.Cam[2]
    end
    --天花板
    if cfg.Cam[3] and cfg.Cam[3] > 0 then
        self._cameraCfg[LocationType.Ceiling] = cfg.Cam[3]
    end

    --所有的面
    local surfaces = {}
    for id, cfgSur in pairs(cfgSurs) do
        local w = cfgSur.Width
        local h = cfgSur.Height
        local cfgTiles = cfgSur.Tiles
        local tiles = {}
        local count = 0
        for i = 1, w do
            for j = 1, h do
                local cfgTile = cfgTiles[i][j]
                if cfgTile then
                    if self:checkTile(cfgTile) then
                        if tiles[i] == nil then
                            tiles[i] = {}
                        end
                        tiles[i][j] = self._tileGetter(cfg.Floor, id, i, j)
                        count = count + 1
                    end
                end
            end
        end
        if count > 0 then
            surfaces[id] = AircraftSurface:New(cfgSur, tiles)
        end
    end

    ---@type table<number,AircraftSurface>
    self._surfaces = surfaces

    self:RefreshFurniture()
end

function AircraftArea:RefreshSurfaces(room)
    self._room = room
    self._isLock = self:checkLock()

    if self._surfaces then
        for _, sur in pairs(self._surfaces) do
            sur:Dispose()
        end
    end
    self._surfaces = nil

    local cfg = Cfg.cfg_aircraft_area[self._id]
    local cfgSurs = AircraftGrids[cfg.Floor]
    --所有的面
    local surfaces = {}
    for id, cfgSur in pairs(cfgSurs) do
        local w = cfgSur.Width
        local h = cfgSur.Height
        local cfgTiles = cfgSur.Tiles
        local tiles = {}
        local count = 0
        for i = 1, w do
            for j = 1, h do
                local cfgTile = cfgTiles[i][j]
                if cfgTile then
                    if self:checkTile(cfgTile) then
                        if tiles[i] == nil then
                            tiles[i] = {}
                        end
                        tiles[i][j] = self._tileGetter(cfg.Floor, id, i, j)
                        count = count + 1
                    end
                end
            end
        end
        if count > 0 then
            surfaces[id] = AircraftSurface:New(cfgSur, tiles)
        end
    end

    ---@type table<number,AircraftSurface>
    self._surfaces = surfaces
end

--检查一个格子是否属于本区域
function AircraftArea:checkTile(cfg)
    if cfg.Area1 == self._id or cfg.Area2 == self._id then
        if self._isLock then
            --若房间锁定，需要判断格子是否在锁定时可用
            return cfg.Unlock
        end
        return true
    end
    return false
end

function AircraftArea:RefreshFurniture()
    local destroyFurs = {}
    for id, fur in pairs(self._furnitures) do
        fur:Dispose()
        table.insert(destroyFurs, fur:InstanceID())
        --不能一个个处理，因为星灵可能会随到将要销毁的家具
        -- self._main:AfterFurnitureDestroy(fur)
    end

    self._furnitures = {}

    --本区域所有家具
    ---@type table<number,MobileFurnitureInfo>
    local allFurnitures = self:GetAllFurniture()
    if not allFurnitures then
        allFurnitures = {}
    end
    for _, fur in pairs(allFurnitures) do
        if fur.area_id == self._id then
            local surface = self._surfaces[fur.surface]
            if surface == nil then
                Log.exception("严重错误！找不到家具所在的面。区域:", self._id, "，", "家具ID：", fur.asset_id, "面ID:", fur.surface)
            end
            local req = ResourceManager:GetInstance():SyncLoadAsset(fur.asset_id .. ".prefab", LoadType.GameObject)
            local gridPos = Vector2(GridHelper.ToFloat(fur.pos_x), GridHelper.ToFloat(fur.pos_z))
            local fp, fr = GridHelper.GetFurniturePosRot(surface, gridPos, fur.rot)
            ---@type AircraftFurniture
            local furniture = AircraftFurniture:New(req, nil, self._floor, self._id)
            furniture:SetDecorateData(fur, false, fp, fr)
            --用实例id做key，放置相同配置id的家具重复
            self._furnitures[furniture:InstanceID()] = furniture
            --
            local grids = GridHelper.FurnitureOccupyGrids(furniture, furniture:GridPosition(), furniture:GridRotY())
            local tiles = surface:Tiles()
            local otiles = {}
            for _, pos in ipairs(grids) do
                if tiles[pos.x] == nil then
                    Log.error("找不到列")
                end
                ---@type AircraftTile
                local tile = tiles[pos.x][pos.y]
                if tile == nil then
                    Log.exception(
                        "面上找不到家具占据的格子。",
                        "面:",
                        surface:ID(),
                        "，家具:",
                        fur.asset_id,
                        "，区域:",
                        self._id,
                        "，格子坐标:",
                        pos.x,
                        ",",
                        pos.y
                    )
                end
                -- surface:Show()
                if tile:Occupied(furniture:Layer()) then
                    --这里只做检查，并打印日志
                    Log.fatal("格子已被占据，", "家具id：", fur.asset_id, "，区域：", self._id, "，面：", surface:ID())
                end
                otiles[#otiles + 1] = tile
            end

            furniture:SetTiles(otiles)
            furniture:OccupyTiles(true)
        end
    end

    --默认家具，不占据格子，因为格子不应该铺到默认家具上
    if self._room then
        local defaultFurs = self._room:GetDefaultFurniture()
        if defaultFurs and #defaultFurs > 0 then
            for _, fur in pairs(defaultFurs) do
                self._furnitures[fur:InstanceID()] = fur
            end
        end
    end

    self._main:OnFurnituresDestroy(destroyFurs)
end

function AircraftArea:GetSurface(id)
    return self._surfaces[id]
end

function AircraftArea:Surfaces()
    return self._surfaces
end

function AircraftArea:OnEnter()
    if not self._entered then
        for id, surface in pairs(self._surfaces) do
            surface:Show()
        end
        self._entered = true
    end
    -- self._go:SetActive(true)
end

function AircraftArea:OnExit()
    self._entered = false
    for id, surface in pairs(self._surfaces) do
        surface:Hide()
    end
    -- self._go:SetActive(false)
end

function AircraftArea:GetFurnitureByInsID(id)
    return self._furnitures[id]
end

function AircraftArea:GetAllFurniture()
    --临时代码
    -- local allFurnitures = {}
    -- local f1 = {}
    -- f1.asset_id = 3621001
    -- f1.area_id = 3
    -- f1.surface = -539212130
    -- f1.pos_x = 12
    -- f1.pos_z = 6
    -- f1.rot = 0
    -- allFurnitures[1] = f1
    -- local f2 = {}
    -- f2.asset_id = 3622002
    -- f2.area_id = 3
    -- f2.surface = -744594598
    -- f2.pos_x = 10
    -- f2.pos_z = 10
    -- f2.rot = 0
    -- allFurnitures[2] = f2
    -- local f3 = {}
    -- f3.asset_id = 3623002
    -- f3.area_id = 3
    -- f3.surface = 647525604
    -- f3.pos_x = 5
    -- f3.pos_z = 6
    -- f3.rot = 0
    -- allFurnitures[3] = f3
    -- return allFurnitures

    ---@type AircraftModule
    local airModule = GameGlobal.GetModule(AircraftModule)
    return airModule:GetFurnitureByArea(self._id)
end
