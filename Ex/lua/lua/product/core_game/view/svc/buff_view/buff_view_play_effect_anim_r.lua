--[[
    播放特效
]]
_class("BuffViewPlayEffectAnim", BuffViewBase)
---@class BuffViewPlayEffectAnim : BuffViewBase
BuffViewPlayEffectAnim = BuffViewPlayEffectAnim

function BuffViewPlayEffectAnim:PlayView(TT)
    ---@type BuffResultPlayEffectAnim
    local result = self._buffResult
    local gameObjectName = result:GetObjName()
    local animName = result:GetAnimName()
    local waitTime = result:GetWaitTime()

    ---@type UnityEngine.GameObject
    local targetGameObject = UnityEngine.GameObject.Find(gameObjectName)

    if not targetGameObject then
        return
    end

    GameGlobal.TaskManager():CoreGameStartTask(
        function(TT)
            YIELD(TT, waitTime * 1000)

            --再找一次
            targetGameObject = UnityEngine.GameObject.Find(gameObjectName)
            if targetGameObject then
                if animName then
                    ---@type UnityEngine.Animation
                    local anim = targetGameObject.gameObject:GetComponent("Animation")
                    anim:Play(animName)
                end
            end
        end
    )
end
