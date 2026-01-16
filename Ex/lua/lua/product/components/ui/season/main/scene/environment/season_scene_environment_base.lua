--场景生态环境相关
---@class SeasonSceneEnvironmentBase:Object
_class("SeasonSceneEnvironmentBase", Object)
SeasonSceneEnvironmentBase = SeasonSceneEnvironmentBase

function SeasonSceneEnvironmentBase:Constructor(sceneRoot)
    ---@type UnityEngine.Transform
    self._sceneRootTransform = sceneRoot.transform
    self._isUnlock = false
end

function SeasonSceneEnvironmentBase:Update(deltaTime)
end

function SeasonSceneEnvironmentBase:Dispose()
end

function SeasonSceneEnvironmentBase:UnLock()
end