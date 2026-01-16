---@class SeasonSceneManager:Object
_class("SeasonSceneManager", Object)
SeasonSceneManager = SeasonSceneManager

function SeasonSceneManager:Constructor()
    self._mapEventPointRootName = "MapEventPoint"
    self._sceneRootName = "SceneRoot"
end

function SeasonSceneManager:OnInit()
    ---@type UnityEngine.GameObject
    self._sceenRoot = GameObjectHelper.Find(self._sceneRootName)
    if not self._sceenRoot then
        Log.fatal("SeasonSceneManager scene no sceneroot! root name is ", self._sceneRootName)
        return
    end
    self._mapEventPointRoot = GameObjectHelper.CreateEmpty(self._mapEventPointRootName, nil)
    self._mapEventPointRoot.layer = SeasonLayerMask.Stage
    self._scene = self._mapEventPointRoot.scene
    self._sceneLayers = SeasonSceneLayers:New(self._sceenRoot)
    self._environment = SeasonSceneEnvironment:New(self._sceenRoot)
end

function SeasonSceneManager:GetEventPointRoot()
    return self._mapEventPointRoot
end

function SeasonSceneManager:GetEventPointRootTransform()
    return self._mapEventPointRoot.transform
end

function SeasonSceneManager:Update(deltaTime)
    self._environment:Update(deltaTime)
end

function SeasonSceneManager:Dispose()
    self._sceneLayers:Dispose()
    self._environment:Dispose()
    UnityEngine.Object.Destroy(self._mapEventPointRoot)
end

---@type UnityEngine.SceneManagement.Scene
function SeasonSceneManager:Scene()
    return self._scene
end

---@param layerType SeasonSceneLayer
---@return SeasonSceneLayerBase
function SeasonSceneManager:GetLayer(layerType)
    return self._sceneLayers:GetLayer(layerType)
end

--解锁某个区的时候场景上的表现
---@param zoneMask number
---@param zoneID2Animation number
function SeasonSceneManager:UnLockZone(zoneMask, zoneID2Animation)
    self._sceneLayers:UnLockZone(zoneMask, zoneID2Animation)
    self._environment:UnLockZone(zoneMask, zoneID2Animation)
end

---@param ids table 当前要显示的地图id
---@param openingID number 当前要alpha渐变显示的地图id
---@param closeID number 当前要关闭的地图id
function SeasonSceneManager:ChangeMap(ids, openingID, closeID)
    self._sceneLayers:ChangeMap(ids, openingID, closeID)
end