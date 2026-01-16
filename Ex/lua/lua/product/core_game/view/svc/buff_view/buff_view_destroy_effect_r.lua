--[[
    
]]
_class("BuffViewDestroyEffect", BuffViewBase)
---@class BuffViewDestroyEffect : BuffViewBase
BuffViewDestroyEffect = BuffViewDestroyEffect

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function BuffViewDestroyEffect:PlayView(TT, notify)
    ---@type BuffResultDestroyEffect
    local result = self._buffResult
    local gameObjectName = result:GetObjName()
    local waitTime = result:GetWaitTime()

    ---@type UnityEngine.GameObject
    local targetGameObject = UnityEngine.GameObject.Find(gameObjectName)

    if not targetGameObject then
        return
    end

    if waitTime and waitTime > 0 then
        ---@type FadeComponent
        local fadeComponent = targetGameObject:AddComponent(typeof(FadeComponent))
        fadeComponent.Alpha = 1
        ---@type MathService
        local mathService = self._world:GetService("Math")
        local tmpDuration = waitTime

        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                while fadeComponent.Alpha > 0 do
                    tmpDuration = tmpDuration - UnityEngine.Time.deltaTime
                    local tran = tmpDuration / waitTime
                    tran = mathService:ClampValue(tran, 0, 1)

                    fadeComponent.Alpha = tran
                    YIELD(TT)
                end

                -- YIELD(TT, waitTime * 1000)

                if targetGameObject then
                    UnityEngine.Object.Destroy(targetGameObject)
                end
            end
        )
    else
        UnityEngine.Object.Destroy(targetGameObject)
    end
end

--是否匹配参数
function BuffViewDestroyEffect:IsNotifyMatch(notify)
    return true
end
