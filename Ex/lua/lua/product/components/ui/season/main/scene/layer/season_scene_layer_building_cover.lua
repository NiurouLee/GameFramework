--维护一个建筑和它的遮挡检测点的关系
---@class SeasonSceneLayerBuildingCover:Object
_class("SeasonSceneLayerBuildingCover", Object)
SeasonSceneLayerBuildingCover = SeasonSceneLayerBuildingCover

function SeasonSceneLayerBuildingCover:Constructor(building)
    self._yDelta = 2
    ---@type UnityEngine.Transform
    self._building = building
    self._buildingRawPosition = building.position
    ---@type UnityEngine.Transform[]
    self._covers = {}
end

---@param cover UnityEngine.Transform
function SeasonSceneLayerBuildingCover:AddBuildingCover(cover)
    table.insert(self._covers, cover)
end

function SeasonSceneLayerBuildingCover:GetRawPosition()
    return self._buildingRawPosition
end

---@return boolean 如果返回true需要建筑遮挡角色否则人遮挡建筑
function SeasonSceneLayerBuildingCover:OnCoverCheck(position)
    local z = position.z
    local x = position.x
    local targetCover = nil
    for _, cover in pairs(self._covers) do
        if not targetCover then
            targetCover = cover
        else
            if Mathf.Abs(cover.position.x - x) < Mathf.Abs(targetCover.position.x - x) then
                targetCover = cover
            end
        end
    end
    if targetCover then
        return z < targetCover.position.z
    end
    return false
end

--调整建筑高度
function SeasonSceneLayerBuildingCover:IncreaseBuildingY()
    self._building.position = Vector3(self._buildingRawPosition.x, self._buildingRawPosition.y + self._yDelta, self._buildingRawPosition.z)
end

--还原建筑高度
function SeasonSceneLayerBuildingCover:ReduceBuildingY()
    self._building.position = self._buildingRawPosition
end

function SeasonSceneLayerBuildingCover:Dispose()
    self._building = nil
    table.clear(self._covers)
end