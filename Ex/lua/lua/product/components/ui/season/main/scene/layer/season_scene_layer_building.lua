--低层建筑层，处理这角色的遮挡关系以及该层的战争迷雾效果
---@class SeasonSceneLayerBuilding:SeasonSceneLayerBase
_class("SeasonSceneLayerBuilding", SeasonSceneLayerBase)
SeasonSceneLayerBuilding = SeasonSceneLayerBuilding

function SeasonSceneLayerBuilding:Constructor(sceneRoot)
    self._time = 1
    self._zoneMask = nil
    ---@type UnityEngine.Transform
    self._buildingLayer = self._sceneRootTransform:Find(SeasonSceneLayer.Building)
    self._coverFlag = "_cover"
    ---@type SeasonSceneLayerBuildingCover[]
    self._buildingCovers = {}
    self._animationRenders = {}
    self:_CreateBuildingCover()
end

function SeasonSceneLayerBuilding:Dispose()
    SeasonSceneLayerBuilding.super.Dispose(self)
    if self._tweenTask then
        GameGlobal.TaskManager():KillTask(self._tweenTask)
        self._tweenTask = nil
    end
    for _, cover in pairs(self._buildingCovers) do
        cover:Dispose()
    end
    table.clear(self._buildingCovers)
    table.clear(self._animationRenders)
end

function SeasonSceneLayerBuilding:UnLock(zoneMask, zoneID2Animation)
    local v4 = SeasonTool:GetInstance():GetV4ByZoneMask(zoneMask, zoneID2Animation)
    for zoneID, zoneRenderers in pairs(self._renderers) do
        for _, renderer in pairs(zoneRenderers) do
            if renderer.material then
                renderer.material:SetVector("_AreaUnlockMask", v4)
            end
        end
    end
    self._zoneMask = zoneMask
    self:TweenV4()
end

function SeasonSceneLayerBuilding:OnCoverCheck(position)
    for buildingName, seasonSceneBuildingCover in pairs(self._buildingCovers) do
        if seasonSceneBuildingCover:OnCoverCheck(position) then
            seasonSceneBuildingCover:IncreaseBuildingY()
        else
            seasonSceneBuildingCover:ReduceBuildingY()
        end
    end
end

---构建building和cover的对应关系
function SeasonSceneLayerBuilding:_CreateBuildingCover()
    if self._buildingLayer then
        local zoneCount = self._buildingLayer.childCount
        if zoneCount > 0 then
            for i = 0, zoneCount - 1 do
                local zone = self._buildingLayer:GetChild(i)
                if zone then
                    local zoneid = i + 1
                    local childCount = zone.childCount
                    for j = 0, childCount - 1 do
                        local building = zone:GetChild(j)
                        if not string.find(building.name, self._coverFlag) then --建筑
                            if not self._buildingCovers[building.name] then
                                self._buildingCovers[building.name] = SeasonSceneLayerBuildingCover:New(building)
                            end
                            local renderers = building.gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
                            if renderers.Length > 0 then
                                for k = 0, renderers.Length - 1 do
                                    self:InsertMeshRender(zoneid, renderers[k])
                                end
                            end
                        else
                            local buildingName = string.gsub(building.name, self._coverFlag, "")
                            if self._buildingCovers[buildingName] then
                                self._buildingCovers[buildingName]:AddBuildingCover(building)
                            end
                        end
                    end
                end
            end
        end
    end
end

function SeasonSceneLayerBuilding:TweenV4()
    self._tweenTask = GameGlobal.TaskManager():StartTask(function (TT)
        YIELD(TT)
        local v4 = SeasonTool:GetInstance():GetV4ByZoneMask(self._zoneMask)
        for zoneID, zoneRenderers in pairs(self._renderers) do
            for _, renderer in pairs(zoneRenderers) do
                if renderer.material then
                    renderer.material:DOVector(v4, "_AreaUnlockMask", self._time)
                end
            end
        end
    end)
end