--场景Layer
---@class SeasonSceneLayerBase:Object
_class("SeasonSceneLayerBase", Object)
SeasonSceneLayerBase = SeasonSceneLayerBase

function SeasonSceneLayerBase:Constructor(sceneRoot)
    ---@type UnityEngine.Transform
    self._sceneRootTransform = sceneRoot.transform
    self._maxMapCount = 12
    ---@type UnityEngine.GameObject[]
    self._map = {} --地图种类
    ---@type table<UnityEngine.Renderer>
    self._renderers = {} --战争迷雾
end

function SeasonSceneLayerBase:Dispose()
    table.clear(self._renderers)
end

function SeasonSceneLayerBase:UnLock(zoneMask, zoneID2Animation)
end

function SeasonSceneLayerBase:ChangeMap(ids, openID, closeID)
end

---@param zoneid number 区ID
---@param renderer UnityEngine.Renderer
function SeasonSceneLayerBase:InsertMeshRender(zoneid, renderer)
    if zoneid and renderer then
        if not self._renderers[zoneid] then
            self._renderers[zoneid] = {}
        end
        table.insert(self._renderers[zoneid], renderer)
    end
end