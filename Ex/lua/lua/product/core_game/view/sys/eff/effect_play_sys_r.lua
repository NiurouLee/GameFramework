--[[------------------------------------------------
    EffectPlaySystem_Render: 特效播放控制系统
--]] ------------------------------------------------
---@class EffectPlaySystem_Render:Object
_class("EffectPlaySystem_Render", Object)
EffectPlaySystem_Render = EffectPlaySystem_Render

function EffectPlaySystem_Render:Constructor(world)
    ---@type MainWorld
    self.world = world
    self.group = world:GetGroup(world.BW_WEMatchers.EffectController)
end

function EffectPlaySystem_Render:Execute()
    self.group:HandleForeach(self, self.UpdateEffect)
end

---@param e Entity
function EffectPlaySystem_Render:UpdateEffect(e)
    local timeService = self.world:GetService("Time")
    ---@type EffectControllerComponent
    local effCtrl = e:EffectController()
    effCtrl.CurrentTime = effCtrl.CurrentTime + timeService:GetDeltaTimeMs()
    if effCtrl.Duration > 0 and effCtrl.CurrentTime > effCtrl.Duration then
        local cb = effCtrl:GetDestroyCallback()
        if cb then
            cb()
        end

        ---删除特效前，需要先把特效从父节点detach掉
        if e:HasView() then
            local effObj = e:View():GetGameObject()
            ---这个地方，如果要删除的特效是挂在另外一个特效身上，
            ---当另外一个特效已经删除后，会导致在这里释放子特效时报错
            if tostring(effObj) ~= "null" and effObj.transform then
                effObj.transform.parent = nil
            end
        end

        self.world:DestroyEntity(e)
    end
    local effectType = effCtrl:GetEffectType()
    if effectType == EffectType.FollowHead then
        self:_UpdateFollowHeadEffect(e, effCtrl)
    elseif effectType == EffectType.Path then
        self:_UpdatePathEffect(e, effCtrl)
    elseif effectType == EffectType.Bind then
        self:_UpdateBindEffect(e, effCtrl)
    elseif effectType == EffectType.UI then
        self:_UpdateUIEffect(e, effCtrl)
    end
end

function EffectPlaySystem_Render:_UpdateFollowHeadEffect(e, effCtrl)
    local heightOffset = effCtrl:GetHeightOffset()
    local holderEntity = effCtrl:GetBindEntity()
    if holderEntity == nil then
        ---todo holder为空，需要测试删掉特效entity
        Log.fatal("EffectPlaySystem_Render effect holder is null")
        return
    end

    local hodlerEntityCmpt = holderEntity:View()
    if hodlerEntityCmpt == nil then
        ---holder为空，删掉特效entity
        self.world:DestroyEntity(e)
        --Log.fatal("EffectPlaySystem_Render effect holder view is null")
        return
    end

    e:SetViewVisible(holderEntity:IsViewVisible())
    if not holderEntity:IsViewVisible() then
        return
    end

    local holderObj = holderEntity:View():GetGameObject()
    local effectObj = nil
    local effectViewCmpt = e:View()
    if effectViewCmpt ~= nil then
        effectObj = effectViewCmpt:GetGameObject()
    end

    if holderObj ~= nil then
        if effectObj ~= nil then
            local hpOffset = Vector3(0, heightOffset, 0)
            ---@type HPComponent
            local hpCmpt = holderEntity:HP()
            if hpCmpt then
                hpOffset = hpCmpt:GetHPOffset()
            end
            hpOffset = hpOffset - Vector3(0, BattleConst.HeadBuffHeightOffset, 0)

            local ownerObj = holderEntity:View().ViewWrapper.GameObject
            local skinnedMeshRender = GameObjectHelper.FindFirstSkinedMeshRender(ownerObj)
            if not skinnedMeshRender then
                return
            end
            local skinnedMeshPosition = skinnedMeshRender.transform.position + hpOffset
            local meshExtents = GameObjectHelper.FindFirstSkinedMeshRenderBoundsExtent(ownerObj)
            local convertExtents = Vector3(0, meshExtents.x * 2, 0)
            local targetPos = skinnedMeshPosition + convertExtents
            local effectTras = e:View().ViewWrapper.GameObject.transform
            effectTras.position = targetPos
        end
    end
end

---@param e Entity
---@param effCtrl EffectControllerComponent
function EffectPlaySystem_Render:_UpdatePathEffect(e, effCtrl)
    ---@type ViewComponent
    local viewCmpt = e:View()
    if viewCmpt == nil then
        return
    end

    local viewObj = viewCmpt:GetGameObject()
    if viewObj == nil then
        ---todo
        return
    end

    local curRenderPos = viewObj.transform.position

    ---@type Vector3
    local targetRenderPos = effCtrl:GetTargetRenderPos()
    local moveSpeed = effCtrl:GetMoveSpeed()

    ---@type number 距离目标
    local distance = Vector2.Distance(targetRenderPos, curRenderPos)

    local timeService = self._world:GetService("Time")
    local deltaTimeMS = timeService:GetDeltaTimeMs()
    local movement = deltaTimeMS * moveSpeed / 1000

    if movement > distance then
        viewObj.transform.position = targetRenderPos
        return
    else
        local lerpPos = Vector3.Lerp(curRenderPos, targetRenderPos, movement / distance)
        viewObj.transform.position = lerpPos
    end
end

---@param e Entity
---@param effCtrl EffectControllerComponent
function EffectPlaySystem_Render:_UpdateBindEffect(e, effCtrl)
    local followMove = effCtrl:GetFollowMove()
    local followRotate = effCtrl:GetFollowRotate()
    local followRotateCaster = effCtrl:GetFollowRotateCaster()

    local effView = e:View()
    if not effView then
        return
    end

    local effectObj = effView:GetGameObject()
    if (not effectObj) or (tostring(effectObj) == "null") then 
        return 
    end

    if not followMove or not followRotate then
        local holderEntity = effCtrl:GetBindEntity()
        if holderEntity == nil then
            Log.notice("特效绑定的Entity为空！")
            return
        end

        local hodlerEntityCmpt = holderEntity:View()
        if hodlerEntityCmpt == nil then
            Log.notice("特效绑定的Entity的View为空！")
            return
        end

        local holderObj = holderEntity:View():GetGameObject()
        if (holderObj == nil) or (tostring(holderObj) == "null") then
            Log.notice("特效绑定的Entity的View的GameObject为空！")
            return
        end

        if followMove then
            effectObj.transform.position = holderObj.transform.position
            local offSet = effCtrl:GetPosOffSet()
            if offSet then
                effectObj.transform.position = effectObj.transform.position + offSet
            end
        end

        if followRotate then
            effectObj.transform.rotation = holderObj.transform.rotation
        elseif followRotateCaster then
            local casterEntityID = effCtrl:GetEffectCasterID()
            local casterEntity = self.world:GetEntityByID(casterEntityID)
            if casterEntity then
                local casterView = casterEntity:View()
                local casterObj = casterView:GetGameObject()

                if casterObj then
                    local direction = effectObj.transform.position - casterObj.transform.position
                    effectObj.transform.rotation = Quaternion.LookRotation(direction)
                end
            else
                Log.notice("特效配置为旋转至面向施法者，但没有施法者或绑定者信息")
            end
        end
    end
end

function EffectPlaySystem_Render:_UpdateUIEffect(e, effCtrl)
    local effCtrl = e:EffectController()
    local effectType = effCtrl:GetEffectType()
    local mainCameraCmpt = self.world:MainCamera()
    local hudCanvas = mainCameraCmpt:HUDCanvas()
    local trans = e:View().ViewWrapper.GameObject.transform

    local pos = e:EffectController():GetTargetGridPos()
    if pos then
        ---@type RenderBattleService
        local renderBattleService = self.world:GetService("RenderBattle")
        local hudWorldPos = renderBattleService:GridPos2HudWorldPos(pos)
        trans.position = hudWorldPos
    end
end
