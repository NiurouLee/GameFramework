--[[
    根据Layer
]]
_class("BuffViewAddHPByLayer", BuffViewBase)
---@class BuffViewAddHPByLayer:BuffViewBase
BuffViewAddHPByLayer = BuffViewAddHPByLayer

function BuffViewAddHPByLayer:Constructor()
end

--是否匹配参数
function BuffViewAddHPByLayer:IsNotifyMatch(notify)
    ---@type BuffResultCastSkill
    local result = self._buffResult
    ---@type NTNotifyLayerChange
    local n = notify

    if notify:GetLayerName() ~= result:GetLayerName() then
        return false
    end
    if result:GetLayerTotalCount() ~= n:GetTotalCount() then
       return false
    end
    return true
end


function BuffViewAddHPByLayer:PlayView(TT)
    ---@type BuffResultAddHPByLayer
    local res = self._buffResult
    local damageInfo = res:GetDamageInfo()
    local entity = self._world:GetEntityByID(res:GetEntityID())

    local curLayer = res:GetLayer()
    local buffseq = res:GetBuffSeq()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        Log.error("BuffViewAddHPByLayer not find viewInstance! entity=", self._entity:GetID(), " layer=", curLayer)
        return
    end

    Log.debug("BuffViewAddHPByLayer entity=", self._entity:GetID(), " layer=", curLayer)

    --血条buff层数
    local casterEntity = self:BuffViewInstance():GetBuffViewContext() and self:BuffViewInstance():GetBuffViewContext().casterEntity or nil
    viewInstance:SetLayerCount(TT, curLayer, res.totalLayerCount, casterEntity)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
    --星灵被动层数
    if self._entity:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(
                GameEventType.SetAccumulateNum,
                self._entity:PetPstID():GetPstID(),
                curLayer
        )
    end

    local buffEffectEntityID = viewInstance:GetBuffEffectEntityID()
    local effectAnimList = viewInstance:GetBuffEffectLayerAnimList()
    ---@type Entity
    local buffEffectEntity = self._world:GetEntityByID(buffEffectEntityID)
    if effectAnimList and buffEffectEntity then
        local effectGameObj = buffEffectEntity:View().ViewWrapper.GameObject

        ---@type UnityEngine.Animation
        local anim = effectGameObj:GetComponentInChildren(typeof(UnityEngine.Animation))
        if anim then
            Log.info("CurLayer ",curLayer," totalLayer ", res.totalLayerCount)

            local animName = effectAnimList[curLayer]
            Log.info(" CurAnim ",animName)
            anim:Play(animName)
        else
            Log.fatal("Can not find view layer animation cmpt")
        end
    end

    local buffConfigData = viewInstance:BuffConfigData()
    local viewParams = buffConfigData:GetViewParams() or {}
    if viewParams.IsHPEnergy then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateHPEnergy, self._entity:GetID(), curLayer)
    end



    YIELD(TT)

    --材质动画
    local materialAnimationComponent = entity:MaterialAnimationComponent()
    if materialAnimationComponent then
        materialAnimationComponent:PlayCure()
    end

    --加血飘字
    ---@type PlayDamageService
    local playDamageService = self._world:GetService("PlayDamage")
    playDamageService:AsyncUpdateHPAndDisplayDamage(entity, damageInfo)

end
