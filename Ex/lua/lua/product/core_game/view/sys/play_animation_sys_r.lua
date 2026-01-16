--[[------------------------------------------------------------------------------------------
    PlayAnimationSystem_Render : legacy动画控制系统
]] --------------------------------------------------------------------------------------------

---@class PlayAnimationSystem_Render: ReactiveSystem
_class("PlayAnimationSystem_Render", ReactiveSystem)
PlayAnimationSystem_Render = PlayAnimationSystem_Render

function PlayAnimationSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function PlayAnimationSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.LegacyAnimation)
    local c = Collector:New({group}, {"Added"})
    return c
end

---@param entity Entity
function PlayAnimationSystem_Render:Filter(entity)
    return entity:HasLegacyAnimation() and entity:HasView() and not entity:HasPiece()
end

function PlayAnimationSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local e = entities[i]
        self:HandleEntity(e)
    end
end

---@param e Entity
function PlayAnimationSystem_Render:HandleEntity(e)
    ---@type LegacyAnimationComponent
    local animCtrl = e:LegacyAnimation()

    ---@type UnityEngine.GameObject
    local gridGameObj = e:View().ViewWrapper.GameObject

    ---@type UnityEngine.Animation 动画组件
    local u3dAnimCmpt = gridGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
    if not u3dAnimCmpt then 
        Log.fatal("Can not find animation component")
        return 
    end

    ---检查有没有挂动画
    local clipCount = u3dAnimCmpt:GetClipCount()
    if clipCount <= 0 then
        return  
    end


    local animList = animCtrl:GetLegacyAnimationList()
    if animList == nil then 
        return 
    end

    if #animList <= 0 then 
        return
    end
        
    if #animList > 1 then 
        for _,v in ipairs(animList) do 
            u3dAnimCmpt:PlayQueued(v,UnityEngine.QueueMode.CompleteOthers)
            self:_LogGridAnim(e,v)
        end
    else
        ---有时候会发现PlayQueued会出现播放不完成的问题，还没找出是啥原因
        local curAnim = animList[1]
        u3dAnimCmpt:Play(curAnim)

        self:_LogGridAnim(e,curAnim)
    end

end

function PlayAnimationSystem_Render:_LogGridAnim(e,anim)
    if EDITOR then 
        ---@type UnityEngine.GameObject
        local gridGameObj = e:View().ViewWrapper.GameObject

        local gridPos = e:GridLocation().Position
        if gridGameObj.transform.position.y==  BattleConst.CacheHeight then 
            Log.fatal("PlayAnimationSystem_Render:",anim,";高度:"..gridGameObj.transform.position.y, Log.traceback())
        end
    end
end

function PlayAnimationSystem_Render:_CacheAnimObj()

end