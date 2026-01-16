---@class HomelandSceneManager:Object
_class("HomelandSceneManager", Object)
HomelandSceneManager = HomelandSceneManager

function HomelandSceneManager:Constructor()
    self._runtimeRootName = "RuntimeRoot"
    self._sceneRootName = "Envrionment"
    self._buildingRootName = "Building"
    self._waterRootName = "WaterManage"
end

function HomelandSceneManager:Init()
    self._runtimeRootTrans = UnityEngine.GameObject.Find(self._runtimeRootName).transform
    self._sceneRoot = UnityEngine.GameObject.Find(self._sceneRootName)
    self._sceneRootTrans = self._sceneRoot.transform
    self._buildingRootTrans = self._sceneRootTrans:Find(self._buildingRootName)

    ---@type UnityEngine.AI.NavMeshSurface
    self._navmeshSurface = self._sceneRoot:GetComponent(typeof(UnityEngine.AI.NavMeshSurface))

    ---@type WaterDepthCmd
    self._waterDepthCmd = self._sceneRootTrans:Find(self._waterRootName):GetComponent(typeof(WaterDepthCmd))
    
    --找到H3DRenderSetting
    local findName = "[H3DRenderSetting]"
    local findGo = UnityEngine.GameObject.Find(findName)
    if findGo then
        ---@type H3dRenderSetting
        self._h3dRenderSetting = findGo:GetComponent(typeof(H3DRenderSetting))
    end

    if not APPVER1190 then
        ---@type UnityEngine.MeshRenderer
        local mr = self._sceneRoot.transform:Find("MatRef").gameObject:GetComponent(typeof(UnityEngine.MeshRenderer))
        for i = 0, mr.sharedMaterials.Length - 1 do
            mr.sharedMaterials[i].shader.maximumLOD = 200
        end
    end
end

---@return UnityEngine.Transform
function HomelandSceneManager:RuntimeRootTrans()
    return self._runtimeRootTrans
end

---@return UnityEngine.Transform
function HomelandSceneManager:BuildingRootTrans()
    return self._buildingRootTrans
end

---@return UnityEngine.Transform
function HomelandSceneManager:SceneRootTrans()
    return self._sceneRootTrans
end

---@return UnityEngine.AsyncOperation
function HomelandSceneManager:BuildNavMesh()
    return self._navmeshSurface:UpdateNavMesh(self._navmeshSurface.navMeshData)
end

function HomelandSceneManager:BuildNavMeshAsync()
    GameGlobal.TaskManager():StartTask(function(TT)
        GameGlobal.UIStateManager():Lock("WaitBuildNavMesh")
        YIELD(TT)
        local res = self._navmeshSurface:UpdateNavMesh(self._navmeshSurface.navMeshData)
        while not res.isDone do
            YIELD(TT)
        end
        YIELD(TT)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnHomelandNavmeshUpdated)
        GameGlobal.UIStateManager():UnLock("WaitBuildNavMesh")
    end)
end

function HomelandSceneManager:Dispose()
end

function HomelandSceneManager:WaterDepthCmdUpdateAllRender()
    if not self._waterDepthCmd then
        return
    end
    self._waterDepthCmd:UpdateAllRender()
end

function HomelandSceneManager:AddWaterDepthTarget(gameObject)
    if not self._waterDepthCmd then
        return
    end
    self._waterDepthCmd:AddTarget(gameObject)
    self._waterDepthCmd:UpdateAllRender()
end

function HomelandSceneManager:RemoveWaterDepthTarget(gameObject)
    if not self._waterDepthCmd then
        return
    end
    self._waterDepthCmd:RemoveTarget(gameObject)
    self._waterDepthCmd:UpdateAllRender()
end

function HomelandSceneManager:SetCustomLightTransform(transform)
    self._h3dRenderSetting.CustomLight = transform
end

function HomelandSceneManager:GetCustomLightTransform()
    return self._h3dRenderSetting.CustomLight
end

function HomelandSceneManager:UpdateH3DRenderSetting()
    self._h3dRenderSetting:UpdateGlobalParam()
end