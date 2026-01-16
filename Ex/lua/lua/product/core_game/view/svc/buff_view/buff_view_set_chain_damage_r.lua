--[[
    传递伤害表现
]]
_class("BuffViewSetChainDamage", BuffViewBase)
---@class BuffViewSetChainDamage : BuffViewBase
BuffViewSetChainDamage = BuffViewSetChainDamage

function BuffViewSetChainDamage:PlayView(TT, notify)
    ---@type BuffResultSetChainDamage
    local result = self._buffResult

    local attackerID = result:GetAttackerID()
    local defenderID = result:GetDefenderID()
    local lineEffectID = result:GetLineEffectID()
    local isRemove = result:GetIsRemove()
    -- self._removeAnim = result:GetRemoveAnim()
    local removeEffectID = result:GetRemoveEffectID()
    local removeLineEntityList = result:GetRemoveLineEntityList()

    local attacker = self._world:GetEntityByID(attackerID)
    local defender = self._world:GetEntityByID(defenderID)
    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    local viewParams = self._viewInstance:BuffConfigData():GetViewParams() or {}

    if isRemove == 1 then
        --会有多个链子同时破碎
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                --作为施法者负责删除特效，被挂者不管
                self:_RemoveEntityLineEffect(TT, attackerID, lineEffectID, removeEffectID, true)

                --作为被挂载的，在自己死亡的时候卸载buff，需要清除那些对自己施法链子的特效
                if removeLineEntityList and table.count(removeLineEntityList) > 0 then
                    for _, entityID in ipairs(removeLineEntityList) do
                        self:_RemoveEntityLineEffect(TT, entityID, lineEffectID, removeEffectID, false)
                        self:_RemoveEntityLineEffect(TT, entityID, lineEffectID, removeEffectID, true)
                    end
                end
            end
        )
    else
        if attacker:HasSuperEntity() then
            attacker = attacker:GetSuperEntity()
        end
        --如果是队伍，目标改成队长
        if attacker:HasTeam() then
            attacker = defender:GetTeamLeaderPetEntity()
        end
        if defender:HasSuperEntity() then
            defender = defender:GetSuperEntity()
        end
        if defender:HasTeam() then
            defender = defender:GetTeamLeaderPetEntity()
        end

        ---@type EffectLineRendererComponent
        local effectLineRenderer = attacker:EffectLineRenderer()
        if not effectLineRenderer then
            attacker:AddEffectLineRenderer()
            effectLineRenderer = attacker:EffectLineRenderer()
        end
        ---@type EffectHolderComponent
        local effectHolderCmpt = attacker:EffectHolder()
        if not effectHolderCmpt then
            attacker:AddEffectHolder()
            effectHolderCmpt = attacker:EffectHolder()
        end

        if lineEffectID then
            local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[lineEffectID]
            local effect
            if effectEntityIdList then
                effect = self._world:GetEntityByID(effectEntityIdList[1])
            end

            if not effect then
                --需要创建连线特效
                effect = effectService:CreateEffect(lineEffectID, attacker)
                effectHolderCmpt:AttachPermanentEffect(effect:GetID())
            end

            --等待一帧才有View()
            -- YIELD(TT)

            --获取特效GetGameObject上面的LineRenderer组件
            local go = effect:View():GetGameObject()
            local renderers
            renderers = go:GetComponentsInChildren(typeof(UnityEngine.LineRenderer), true)

            local attackerViewRoot = attacker:View().ViewWrapper.GameObject.transform
            local attackRoot = GameObjectHelper.FindChild(attackerViewRoot, "Hit")
            if not attackRoot then
                attackRoot = GameObjectHelper.FindChild(attackerViewRoot, "Root")
            end

            local defenderViewRoot = defender:View().ViewWrapper.GameObject.transform
            local defenderRoot = GameObjectHelper.FindChild(defenderViewRoot, "Hit")
            if not defenderRoot then
                defenderRoot = GameObjectHelper.FindChild(defenderViewRoot, "Root")
            end

            effectLineRenderer:InitEffectLineRenderer(
                attackerID,
                attackRoot,
                defenderRoot,
                attackerViewRoot,
                renderers,
                effect:GetID()
            )
            effectLineRenderer:SetEffectLineRendererShow(attackerID, true)
            effectLineRenderer:SetTargetEntityID(defenderID)
        end
    end

    --给目标添加特效
    local targetPermanentEffectID = viewParams.targetPermanentEffectID
    if targetPermanentEffectID then
        --施法者自己身上的检测位移断开的，def和atk是一个
        if attackerID == defenderID and removeLineEntityList and table.count(removeLineEntityList) > 0 then
            defender = self._world:GetEntityByID(removeLineEntityList[1])
        end
        if defender:HasSuperEntity() then
            defender = defender:GetSuperEntity()
        end
        if defender:HasTeam() then
            defender = defender:GetTeamLeaderPetEntity()
        end
        ---@type EffectHolderComponent
        local defenderEffectHolderCmpt = defender:EffectHolder()
        if not defenderEffectHolderCmpt then
            defender:AddEffectHolder()
            defenderEffectHolderCmpt = defender:EffectHolder()
        end

        if isRemove == 1 then
            GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    local lineEffect = nil
                    local effectEntityIdList = defenderEffectHolderCmpt:GetEffectIDEntityDic()[targetPermanentEffectID]
                    if effectEntityIdList then
                        lineEffect = self._world:GetEntityByID(effectEntityIdList[1])
                    end
                    if not lineEffect then
                        return
                    end

                    local go = lineEffect:View():GetGameObject()

                    local targetPermanentEffectRemoveAnim = viewParams.targetPermanentEffectRemoveAnim
                    local removeAnimTime = viewParams.removeAnimTime

                    --破碎动画
                    ---@type UnityEngine.Animation
                    local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
                    if anim and anim.clip then
                        anim:Play(targetPermanentEffectRemoveAnim)
                        YIELD(TT, removeAnimTime)
                    end

                    --删除特效
                    self._world:DestroyEntity(lineEffect)
                    defenderEffectHolderCmpt:GetEffectIDEntityDic()[targetPermanentEffectID][1] = nil
                end
            )
        else
            if notify and notify:GetNotifyType() == NotifyType.ChangeTeamLeader then
                --卸载掉旧队长身上的特效
                local oldTeamLeader = notify:GetOldTeamLeader()
                ---@type EffectHolderComponent
                local oldTeamLeaderEffectHolderCmpt = oldTeamLeader:EffectHolder()
                local lineEffect = nil
                local oldTeamLeaderEffectEntityIdList =
                    oldTeamLeaderEffectHolderCmpt:GetEffectIDEntityDic()[targetPermanentEffectID]
                if oldTeamLeaderEffectEntityIdList then
                    lineEffect = self._world:GetEntityByID(oldTeamLeaderEffectEntityIdList[1])
                end
                if lineEffect then
                    self._world:DestroyEntity(lineEffect)
                    oldTeamLeaderEffectHolderCmpt:GetEffectIDEntityDic()[targetPermanentEffectID][1] = nil
                end
            end

            local lineEffect = nil
            local defenderEffectEntityIdList = defenderEffectHolderCmpt:GetEffectIDEntityDic()[targetPermanentEffectID]
            if defenderEffectEntityIdList then
                lineEffect = self._world:GetEntityByID(defenderEffectEntityIdList[1])
            end

            --如果上回合加过  就不加了
            if not lineEffect then
                --给队长添加特效
                local permanentEffectEntity = effectService:CreateEffect(targetPermanentEffectID, defender)
                defenderEffectHolderCmpt:AttachPermanentEffect(permanentEffectEntity:GetID())
            end
        end
    end

    local notOpenLineEffectObjName = viewParams.NotOpenLineEffectObjName
    if notOpenLineEffectObjName then
        ---@type BuffViewComponent
        local buffView = attacker:BuffView()
        buffView:SetBuffValue("NotOpenLineEffectObjName", notOpenLineEffectObjName)
    end
end

--是否匹配参数
---@param notify NTMonsterHPCChange
function BuffViewSetChainDamage:IsNotifyMatch(notify)
    ---@type BuffResultSetChainDamage
    local result = self._buffResult
    local notifyType = notify:GetNotifyType()
    if notifyType == NotifyType.BuffLoad then
        local attackerID = result:GetAttackerID()
        local casterID = notify:GetCasterEntityID()
        if attackerID ~= casterID then
            return false
        end
    end

    if notify and notifyType == NotifyType.MonsterMoveOneFinish then
        local monsterMoveEntityID = result:GetMonsterMoveOneFinishEntityID()
        local monsterMoveWalkPos = result:GetMonsterMoveOneFinishWalkPos()
        return (monsterMoveEntityID == notify:GetNotifyEntity():GetID()) and (monsterMoveWalkPos == notify:GetWalkPos())
    end
    if notify and notifyType == NotifyType.TeamLeaderEachMoveEnd then
        local walkPos = result:GetTeamLeaderEachMoveEnd()
        return walkPos == notify:GetPos()
    end

    return true
end

function BuffViewSetChainDamage:_RemoveEntityLineEffect(TT, entityID, lineEffectID, removeEffectID, isCaster)
    local entity = self._world:GetEntityByID(entityID)

    if not entity then
        return
    end
    if entity:HasSuperEntity() then
        entity = entity:GetSuperEntity()
    end
    --如果是队伍换成队长
    if entity:HasTeam() then
        entity = entity:GetTeamLeaderPetEntity()
    end

    --
    ---@type EffectHolderComponent
    local effectHolderCmpt = entity:EffectHolder()
    if not effectHolderCmpt then
        return
    end

    ---@type EffectService
    local effectService = self._world:GetService("Effect")
    if removeEffectID then
        local curPos = entity:GetPosition()
        local attackerViewRoot = entity:View().ViewWrapper.GameObject.transform
        local attackRoot = GameObjectHelper.FindChild(attackerViewRoot, "Hit")
        if attackRoot then
            local attackHit = attackRoot.position
            effectService:CreateWorldPositionEffect(removeEffectID, attackHit)
        end
    end

    ---@type EffectLineRendererComponent
    local effectLineRenderer = entity:EffectLineRenderer()
    if not effectLineRenderer then
        return
    end
    local defenderID = effectLineRenderer:GetTargetEntityID()
    local casterEntityID = effectLineRenderer:GetCasterEntityID()
    --当处理某个目标的时候 需要判断本次要删除的目标是否是一个施法者  他的对象是否是本次要删除的目标
    if isCaster == false and casterEntityID == entityID and defenderID ~= entity:GetID() then
        return
    end

    if lineEffectID then
        local lineEffect = nil
        local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[lineEffectID]
        if effectEntityIdList then
            lineEffect = self._world:GetEntityByID(effectEntityIdList[1])
        end
        if not lineEffect then
            return
        end

        local go = lineEffect:View():GetGameObject()

        --破碎动画
        ---@type UnityEngine.Animation
        local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
        if anim and anim.clip then
            anim:Play()
            YIELD(TT, anim.clip.length * 1000)
        end

        --删除特效
        self._world:DestroyEntity(lineEffect)
        effectHolderCmpt:GetEffectIDEntityDic()[lineEffectID][1] = nil

        --注意 设置isShow并不等于关闭显示  只是sys那里不刷新会return
        effectLineRenderer:SetEffectLineRendererShow(entityID, false)
    end
end
