--[[******************************************************************************************
    Entity Spawn_Rule Extensions
    这里扩展特化 Entity 个体的出生规则描述
    规则可能独立，也可能会受到世界的出生管理制约，这些规则描述如何生效会在具体SpawnSystem的实现中展现
--******************************************************************************************]]--

--[[------------------------------------------------------------------------------------------
    SpawnRuleFixedLocation : 
]]--------------------------------------------------------------------------------------------

---@class SpawnRuleFixedLocation: ISpawnRule
_class( "SpawnRuleFixedLocation", ISpawnRule )

function SpawnRuleFixedLocation:Constructor(pos, dir)
    self.Position = pos
    self.Direction = dir
end

---@param entity Entity
function SpawnRuleFixedLocation:MakeSpawn(entity, world)
    entity:SetLocation(self.Position, self.Direction)
end


--[[------------------------------------------------------------------------------------------
    SpawnRuleFixedScenePoint : 
]]--------------------------------------------------------------------------------------------

---@class SpawnRuleFixedScenePoint: ISpawnRule
_class( "SpawnRuleFixedScenePoint", ISpawnRule )

function SpawnRuleFixedScenePoint:Constructor(pointIndex)
    self.PointIndex = pointIndex
end

---@param entity Entity
function SpawnRuleFixedScenePoint:MakeSpawn(entity, world)
    local spawnMng = world:SpawnMng().Manager
    local points = spawnMng.AllPoints
    local pos = points[self.PointIndex]
    if pos == nil then
        Log.fatal("SpawnRuleFixedScenePoint Cant Find Point on index: "..self.PointIndex)
        pos = Vector3(0,0,0)
    end
    entity:SetPosition(pos)
end


--[[------------------------------------------------------------------------------------------
    SpawnRuleRandomScenePoint : 
]]--------------------------------------------------------------------------------------------

---@class SpawnRuleRandomScenePoint: ISpawnRule
_class( "SpawnRuleRandomScenePoint", ISpawnRule )

function SpawnRuleRandomScenePoint:Constructor()

end

---@param entity Entity
function SpawnRuleRandomScenePoint:MakeSpawn(entity, world)
end


