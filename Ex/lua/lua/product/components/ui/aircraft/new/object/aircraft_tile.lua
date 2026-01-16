--[[
    风船地形格子
]]
---@class AircraftTile:Object
_class("AircraftTile", Object)
AircraftTile = AircraftTile
function AircraftTile:Constructor(cfg)
    ---@type table<number,number>
    self._occupied = {}
end

function AircraftTile:Dispose()
    self._occupied = nil
end

function AircraftTile:Occupied(layer)
    return self._occupied[layer] and (next(self._occupied[layer]) ~= nil)
end

function AircraftTile:GetFurnitureIDs(layer)
    return self._occupied[layer]
end

--占据格子
--2022.8.15对算法进行修改，对现网数据容错，允许错误数据运行
function AircraftTile:Occupy(layer, furInsID)
    if self:Occupied(layer) then
        Log.fatal("该格子已被占据")
    end
    if not self._occupied[layer] then
        self._occupied[layer] = {}
    end
    self._occupied[layer][furInsID] = true
end

--释放格子
function AircraftTile:Release(layer, furInsID)
    if self._occupied[layer] then
        if self._occupied[layer][furInsID] then
            self._occupied[layer][furInsID] = nil
        else
            Log.fatal("格子未被占据，不能释放")
        end
    else
        Log.fatal("格子层未被占据")
    end
end
