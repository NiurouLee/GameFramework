---@class SeasonSceneLayers:Object
_class("SeasonSceneLayers", Object)
SeasonSceneLayers = SeasonSceneLayers

function SeasonSceneLayers:Constructor(sceenRoot)
    ---@type UnityEngine.GameObject
    self._sceenRoot = sceenRoot
    ---@type SeasonSceneLayerBase[]
    self._layers = {}
    self._layers[SeasonSceneLayer.SoundMaterial] = SeasonSceneLayerMaterial:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.ZoneFlag] = SeasonSceneLayerZoneFlag:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.Ground] = SeasonSceneLayerGround:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.Building] = SeasonSceneLayerBuilding:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.HighBuilding] = SeasonSceneLayerHighBuilding:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.FogMask] = SeasonSceneLayerFogMask:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.Ambient] = SeasonSceneLayerAmbient:New(self._sceenRoot)
    self._layers[SeasonSceneLayer.AmbientMap] = SeasonSceneLayerAmbientMap:New(self._sceenRoot)
end

function SeasonSceneLayers:Update(deltaTime)
end

function SeasonSceneLayers:Dispose()
    for key, layer in pairs(self._layers) do
        layer:Dispose()
    end
    table.clear(self._layers)
end

---@param layerType SeasonSceneLayer
---@return SeasonSceneLayerBase
function SeasonSceneLayers:GetLayer(layerType)
    return self._layers[layerType]
end

--解锁某个区的时候场景上的表现
---@param zoneMask number
---@param zoneID2Animation number
function SeasonSceneLayers:UnLockZone(zoneMask, zoneID2Animation)
    for _, layer in pairs(self._layers) do
        layer:UnLock(zoneMask, zoneID2Animation)
    end
end

---@param ids table 当前要显示的地图id
---@param openingID number 当前要alpha渐变显示的地图id
---@param closeID number 当前要关闭的地图id
function SeasonSceneLayers:ChangeMap(ids, openingID, closeID)
    for _, layer in pairs(self._layers) do
        layer:ChangeMap(ids, openingID, closeID)
    end
end