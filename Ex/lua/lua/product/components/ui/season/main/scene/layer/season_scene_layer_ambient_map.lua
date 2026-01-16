require "season_scene_layer_base"

--氛围特效层(随着地图的变化而变化): 默认显示，满足条件后隐藏,一帧切
---@class SeasonSceneLayerAmbientMap:SeasonSceneLayerBase
_class("SeasonSceneLayerAmbientMap", SeasonSceneLayerBase)
SeasonSceneLayerAmbientMap = SeasonSceneLayerAmbientMap

function SeasonSceneLayerAmbientMap:Constructor(sceneRoot)
    self._time = 1
    self._ambientLayer = self._sceneRootTransform:Find(SeasonSceneLayer.AmbientMap)
    self:_CacheAmbientMap()
end

function SeasonSceneLayerAmbientMap:Dispose()
    SeasonSceneLayerAmbientMap.super.Dispose(self)
    table.clear(self._map)
end

function SeasonSceneLayerAmbientMap:UnLock(zoneMask, zoneID2Animation)
end

function SeasonSceneLayerAmbientMap:ChangeMap(ids, openingID, closeID)
    local mapCount = table.count(self._map)
    if mapCount > 0 then
        for id, effect in pairs(self._map) do
            if id == closeID then
                effect:SetActive(false)
            else
                effect:SetActive(table.icontains(ids, id))
            end
        end
    end
end

function SeasonSceneLayerAmbientMap:_CacheAmbientMap()
    if self._ambientLayer then
        local mapCount = self._ambientLayer.childCount
        if mapCount > 0 then
            for i = 1, self._maxMapCount do
                local map = self._ambientLayer:Find(tostring(i))
                if map then
                    self._map[i] = map.gameObject
                end
            end
        end
    end
end