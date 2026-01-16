--[[
    风船房间寻路点管理器
]]
---@class AircraftPointHolder:Object
_class("AircraftPointHolder", Object)
AircraftPointHolder = AircraftPointHolder
function AircraftPointHolder:Constructor(parent, floor, name)
    self._parent = parent
    if parent == nil then
        Log.fatal("父节点为空:", name)
        return
    end
    self._name = name
    self._count = parent.childCount
    ---@type table<number, AircraftPosPoint>
    self._point = {}
    self._available = self._count
    --所在楼层
    self._floor = floor
    if self._count == 0 then
        return
    end
    for i = 1, self._count do
        local child = parent:GetChild(i - 1)
        -- child.gameObject:SetActive(false)
        self._point[i] = AircraftPosPoint:New(i, child.position)
    end
end

function AircraftPointHolder:Floor()
    return self._floor
end

--占据一个点，并返回位置
---@return AircraftPosPoint
function AircraftPointHolder:PopPoint()
    if self._available <= 0 then
        Log.fatal("[AircraftPoint] no point, floor:", self._floor)
        return
    end
    local target = math.random(1, self._available)
    local i = 1
    for idx, point in ipairs(self._point) do
        if not self._point[idx]:IsOccupied() then
            if i == target then
                self._available = self._available - 1
                self._point[idx]:Occupy(true)
                return self._point[idx]
            end
            i = i + 1
        end
    end
end

-- 指定占据一个点（慎用，目前社交序列化用,除非能保证顺序）
function AircraftPointHolder:OccupyPoint(index)
    if self._available <= 0 then
        Log.fatal("[AircraftPoint] no point, floor:", self._floor)
        return
    end
    if not self._point[index]:IsOccupied() then
        self._available = self._available - 1
        self._point[index]:Occupy(true)
        return self._point[index]
    end
    return
end

--是否有可用点
---@return boolean
function AircraftPointHolder:HasAvailablePoint()
    return self._available > 0
end

--释放一个点
---@param point AircraftPosPoint
function AircraftPointHolder:ReleasePoint(point)
    if not point:IsOccupied() then
        AirLog("该点未被占据：", self._name, "，", point:Index())
        return
    end
    point:Occupy(false)
    self._available = self._available + 1
end

--释放所有点
function AircraftPointHolder:ReleaseAll()
    if self._point then
        self._available = self._count
        for idx, point in ipairs(self._point) do
            if point:IsOccupied() then
                point:Occupy(false)
            end
        end
    end
end
-----------------------------------------------------------------------------------
---@class AircraftPosPoint:Object
_class("AircraftPosPoint", Object)
AircraftPosPoint = AircraftPosPoint

function AircraftPosPoint:Constructor(idx, pos)
    self._index = idx
    self._pos = pos:Clone()
    self._occupied = false
end

function AircraftPosPoint:Index()
    return self._index
end

function AircraftPosPoint:Pos()
    return self._pos
end

function AircraftPosPoint:IsOccupied()
    return self._occupied
end

function AircraftPosPoint:Occupy(occupy)
    self._occupied = occupy
    -- if occupy then
    --     if self._occupied then
    --         Log.exception("该点已被占据：", debug.traceback())
    --     end
    -- else
    --     if not self._occupied then
    --         AirLog("该点未被占据：", debug.traceback())
    --     end
    --     self._occupied = false
    -- end
end
