--[[
    层数叠加
]]
_class("BuffViewAddLayer", BuffViewBase)
BuffViewAddLayer = BuffViewAddLayer

function BuffViewAddLayer:PlayView(TT, notify, trace)
    ---@type BuffResultLayer
    local res = self._buffResult
    local curLayer = res:GetLayer()
    local buffseq = res:GetBuffSeq()
    local addLayer = res:GetAddLayer()
    ---@type BuffViewComponent
    local buffView = self._entity:BuffView()
    ---@type BuffViewInstance
    local viewInstance = buffView:GetBuffViewInstance(buffseq)
    if not viewInstance then
        Log.error("BuffViewAddLayer not find viewInstance! entity=", self._entity:GetID(), " layer=", curLayer)
        return
    end

    if self._isTrapDead then
         ---由于机关在洗板时死亡，播放顺序会与逻辑顺序存在较大差异，把在机关死亡通知时只采用最大层数的。小层数被滤掉
         --如果逻辑层数比表现滞后就跳过这个layer的表现
         local curViewLayer = viewInstance:GetLayerCount() or 0
         if addLayer > 0 and curLayer < curViewLayer then
             return
         end
         if addLayer < 0 and curLayer > curViewLayer then
             return
         end
    end

    Log.debug("BuffViewAddLayer entity=", self._entity:GetID(), " layer=", curLayer)

    --血条buff层数
    local casterEntity = self:BuffViewInstance():GetBuffViewContext() and self:BuffViewInstance():GetBuffViewContext().casterEntity or nil
    viewInstance:SetLayerCount(TT, curLayer, res.totalLayerCount, casterEntity)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    if res:IsDontDisplay() then
        return
    end
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

    -- if processing layer is owner's active skill energy...
    self:TryShowLayerAsActiveSkillEnergy(TT, viewInstance, res)
end

function BuffViewAddLayer:TryShowLayerAsActiveSkillEnergy(TT, viewInstance, res)
    if not self._entity:HasSkillInfo() then
        -- no SkillInfoComponent, no active skill ID
        return
    end
    local activeSkillID = self._entity:SkillInfo():GetActiveSkillID()
    ---@type SkillConfigData
    local activeSkillConfig = self._world:GetService("Config"):GetSkillConfigData(activeSkillID, self._entity)
    if (not activeSkillConfig) or (activeSkillConfig:GetSkillTriggerType() ~= SkillTriggerType.BuffLayer) then
        -- his/her active skill does not costing buff layer
        return
    end
    local buffEffectType = viewInstance:GetBuffEffectType()
    local extraParam = activeSkillConfig:GetSkillTriggerExtraParam()
    if self._buffResult:GetLayerType() ~= extraParam.buffEffectType then
        -- not this buff
        return
    end

    -- push game event to UI
    if not self._entity:HasPetPstID() then
        return
    end

    local petPstID = self._entity:PetPstID():GetPstID()
    local curLayer = res:GetLayer()
    local ready = curLayer >= activeSkillConfig:GetSkillTriggerParam()
    if ready then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, ready)
    end

    local notify = NTPowerReady:New(self._world:GetEntityByID(self._entity:GetID()))
    self._world:GetService("PlayBuff"):PlayBuffView(TT, notify)

    -- designer prefers the other way: light => chain skill lock. code below moved to BuffViewLockChainSkill
    ---- get its view index and light up
    -----@type BuffConfigData
    --local buffConfig = viewInstance:BuffConfigData()
    --local viewParam = buffConfig:GetViewParams() or {}
    --local index = viewParam.ActiveSkillChainEnergyViewIndex
    --if not index then
    --    -- no index, no light
    --    return
    --end
    --
    ---- "Let there be light. "
    --GameGlobal:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyChange, {
    --    petPstID = petPstID,
    --    index = index,
    --    on = true
    --})
end

function BuffViewAddLayer:IsNotifyMatch(notify)
    if
        notify:GetNotifyType() == NotifyType.PlayerEachMoveStart or
            notify:GetNotifyType() == NotifyType.PlayerEachMoveEnd or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
     then
        local movePos = self._buffResult:GetMovePos()
        return movePos == notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.BeforeHighFrequencyDamageHit then
        return notify:GetHitIndex() == self._buffResult:GetHighFrequencyDamageIndex()
    elseif notify:GetNotifyType() == NotifyType.AfterHighFrequencyDamageHit then
        return notify:GetHitIndex() == self._buffResult:GetHighFrequencyDamageIndex()
    elseif notify:GetNotifyType() == NotifyType.PlayerBeHit then
        local damageIndexMatch = true
        if self._buffResult.damageIndex and notify:GetDamageIndex() then
            damageIndexMatch = self._buffResult.damageIndex == notify:GetDamageIndex()
        end
        return self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos() and
            self._buffResult.attackerEntity == notify:GetAttackerEntity() and
            self._buffResult.defenderEntity == notify:GetDefenderEntity() and
            damageIndexMatch
    elseif notify:GetNotifyType() == NotifyType.MonsterBeHit then
        --特殊模式：不再使用攻击者/被击者/攻击坐标/被击坐标去匹配是否可以播放。改用次数播放，一个notify只能触发一个Viewlayer，然后修改notify，让其不会触发多个View
        local viewParams = self._viewInstance:BuffConfigData():GetViewParams()
        if viewParams and viewParams.ViewMatchNotifyIndex == 1 then
            ---@type BuffViewInstance
            local viewInstance = self._viewInstance

            local notifyMatchLayer = notify:GetMatchBuffViewLayer(viewInstance:BuffID())
            if notifyMatchLayer then
                return false
            end

            --获取当前回合数
            local curRoundCount = BattleStatHelper.GetLevelTotalRoundCount()
            local buffResultRound = self._buffResult:GetLevelTotalRoundCount()
            if curRoundCount ~= buffResultRound then
                return false
            end

            local curLayer = self._buffResult:GetLayer()

            notify:SetMatchBuffViewLayer(curLayer, viewInstance:BuffID())
            return true
        end
	
        local damageIndexMatch = true
        if self._buffResult:GetDamageStageIndex() and notify:GetDamageStageIndex() then
            damageIndexMatch = self._buffResult:GetDamageStageIndex() == notify:GetDamageStageIndex()
        end
        local curSkillDamageIndex = true
        if self._buffResult:GetCurSkillDamageIndex() and notify:GetCurSkillDamageIndex() then
            curSkillDamageIndex = self._buffResult:GetCurSkillDamageIndex() == notify:GetCurSkillDamageIndex()
        end
        return self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos() and
            self._buffResult.attackerEntity == notify:GetAttackerEntity() and
            self._buffResult.defenderEntity == notify:GetDefenderEntity() and
            damageIndexMatch and curSkillDamageIndex
    elseif notify.GetAttackPos and notify.GetTargetPos and self._buffResult.attackPos and self._buffResult.targetPos then
        return (self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos())
    elseif notify:GetNotifyType() == NotifyType.TrapSkillStart then
        local movePos = self._buffResult:GetMovePos()
        return movePos == notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.MinosAbsorbTrap then
        local notifyEntity =  notify:GetNotifyEntity()
        return notifyEntity:GetID() == self._buffResult.abTrapID
    elseif notify:GetNotifyType() == NotifyType.PetMinosAbsorbTrap then
        local notifyEntity =  notify:GetNotifyEntity()
        return notifyEntity:GetID() == self._buffResult.abTrapID
    elseif (notify:GetNotifyType() == NotifyType.SuperGridTriggerEnd) or (notify:GetNotifyType() == NotifyType.PoorGridTriggerEnd) then
        return notify:GetTriggerPos() == self._buffResult:GetTriggerPos()
    elseif notify:GetNotifyType() == NotifyType.ReduceShieldLayer then
        return notify:GetNotifyLayer() == self._buffResult:GetLayer() and
        notify:GetNotifyEntity() == self._viewInstance:Entity()
    elseif (notify:GetNotifyType() == NotifyType.NotifyLayerChange) then
        ---@type NTNotifyLayerChange
        local n = notify
        ---@type BuffConfigData
        local configData = self:BuffViewInstance():BuffConfigData()
        local viewParams = configData:GetViewParams() or {}
        local isIgnoreOldLayer = viewParams.ignoreOldLayer == 1

        if (not isIgnoreOldLayer) and self._buffResult.__oldFinalLayer ~= n.__oldFinalLayer then
            return false
        end

        if (n:GetNotifyEntity()) and (self._buffResult:GetNotifyLayerChange_Entity() ~= n:GetNotifyEntity()) then
            return false
        end

        return true
    elseif (notify:GetNotifyType() == NotifyType.TrapDead) then
        ---@type Entity
        local entity = notify:GetNotifyEntity()
        self._isTrapDead = true
        return entity:GetID() == self._buffResult:GetEntityID()
    elseif (notify:GetNotifyType() == NotifyType.BuffLoad) then
        local buffLoadEntityID = notify:GetCasterEntityID()
        if buffLoadEntityID and self._buffResult.__buffLogicAddLayer_source then
            return buffLoadEntityID == self._buffResult.__buffLogicAddLayer_source
        else
            return true
        end
    else
        return true
    end
end

--[[
    清空层数
]]
_class("BuffViewClearLayer", BuffViewBase)
BuffViewClearLayer = BuffViewClearLayer

function BuffViewClearLayer:PlayView(TT)
    ---@type BuffResultClearLayer
    local res = self._buffResult
    local curLayer = res:GetLayer()
    local dontDisplay = res:GetDonotDisplay()
    local ownerEntityID = res:GetOwnerEntityID()
    local targetBuffSeq = res:GetTargetBuffSeq()
    local ownerEntity = self._world:GetEntityByID(ownerEntityID)
    if not ownerEntity then
        return
    end
    ---@type BuffViewComponent
    local buffView = ownerEntity:BuffView()
    for _, value in ipairs(targetBuffSeq) do
        local viewInstance = buffView:GetBuffViewInstance(value)
        if not viewInstance then
            viewInstance = self._viewInstance
        end
        viewInstance:SetLayerCount(TT, curLayer, res:GetTotalLayer())
        if res:GetIsUnload() == 1 and curLayer == 0 then
            viewInstance:SetUnload()
        end
    end

    Log.debug("BuffViewClearLayer entity=", ownerEntity:GetID(), " layer=", curLayer)
    self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)

    if dontDisplay then
        return
    end

    if ownerEntity:HasPetPstID() then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.SetAccumulateNum,
            ownerEntity:PetPstID():GetPstID(),
            curLayer
        )
    end

    for _, value in ipairs(targetBuffSeq) do
        local viewInstance = buffView:GetBuffViewInstance(value)
        if not viewInstance then
            viewInstance = self._viewInstance
        end
        local buffConfigData = viewInstance:BuffConfigData()
        local viewParams = buffConfigData:GetViewParams() or {}
        if viewParams.IsHPEnergy then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateHPEnergy, self._entity:GetID(), curLayer)
        end
    end
end

function BuffViewClearLayer:IsNotifyMatch(notify)
    if
        (notify:GetNotifyType() == NotifyType.NormalEachAttackStart or
            notify:GetNotifyType() == NotifyType.NormalEachAttackEnd or
            notify:GetNotifyType() == NotifyType.BuffCastSkillEachAttackBegin
        )
     then
        local result = self._buffResult
        return (result.attacker == notify:GetAttackerEntity() and result.defender == notify:GetDefenderEntity() and
            result.attackPos == notify:GetAttackPos() and
            result.targetPos == notify:GetTargetPos())
    elseif notify:GetNotifyType() == NotifyType.NotifyLayerChange then
        ---@type NTNotifyLayerChange
        local n = notify
        if self._buffResult:GetTotalLayer() ~= n:GetTotalCount() then
            return false
        end
    elseif notify:GetNotifyType() == NotifyType.TrapSkillStart then
        local movePos = self._buffResult:GetMovePos()
        return movePos == notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.MinosAbsorbTrap then
        local notifyEntity =  notify:GetNotifyEntity()
        return notifyEntity:GetID() == self._buffResult.abTrapID
    elseif notify:GetNotifyType() == NotifyType.PetMinosAbsorbTrap then
        local notifyEntity =  notify:GetNotifyEntity()
        return notifyEntity:GetID() == self._buffResult.abTrapID
    elseif (notify:GetNotifyType() == NotifyType.SuperGridTriggerEnd) or (notify:GetNotifyType() == NotifyType.PoorGridTriggerEnd) then
        return notify:GetTriggerPos() == self._buffResult:GetTriggerPos()
    elseif notify:GetNotifyType() == NotifyType.ReduceShieldLayer then
        return notify:GetNotifyLayer() == self._buffResult:GetLayer() and
        notify:GetNotifyEntity() == self._viewInstance:Entity()
    elseif notify:GetNotifyType() == NotifyType.MonsterBeHit then
        --特殊模式：不再使用攻击者/被击者/攻击坐标/被击坐标去匹配是否可以播放。改用次数播放，一个notify只能触发一个Viewlayer，然后修改notify，让其不会触发多个View
        local viewParams = self._viewInstance:BuffConfigData():GetViewParams()
        if viewParams and viewParams.ViewMatchNotifyIndex == 1 then
            ---@type BuffViewInstance
            local viewInstance = self._viewInstance

            local notifyMatchLayer = notify:GetMatchBuffViewLayer(viewInstance:BuffID())
            if notifyMatchLayer then
                return false
            end
            local curLayer = self._buffResult:GetLayer()

            notify:SetMatchBuffViewLayer(curLayer, viewInstance:BuffID())
            return true
        end

        return self._buffResult.attackPos == notify:GetAttackPos() and
            self._buffResult.targetPos == notify:GetTargetPos() and
            self._buffResult.attacker == notify:GetAttackerEntity() and
            self._buffResult.defender == notify:GetDefenderEntity() 
    end

    return true
end

_class("BuffViewForceRefreshLayer", BuffViewBase)
BuffViewForceRefreshLayer = BuffViewForceRefreshLayer

function BuffViewForceRefreshLayer:PlayView(TT)
    ---@type BuffResultForceRefreshLayer
    local result = self._buffResult
    local layer = result:GetBuffLayer()
    if type(layer) == "number" and layer > 0 then
        if self._entity:HasPetPstID() then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.SetAccumulateNum,
                self._entity:PetPstID():GetPstID(),
                layer
            )
        end

        if self._world:Player():IsLocalTeamEntity(self._entity) then
            self._entity:BuffView():SetBuffValue(result:GetBuffLayerName(), layer)
            self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
        end
    end
end
