--[[
    
]]
_class("BuffViewAddTeamLeaderEffect", BuffViewBase)
---@class BuffViewAddTeamLeaderEffect : BuffViewBase
BuffViewAddTeamLeaderEffect = BuffViewAddTeamLeaderEffect

function BuffViewAddTeamLeaderEffect:PlayView(TT, notify)
    ---@type BuffResultAddTeamLeaderEffect
    local result = self._buffResult

    local oldTeamLeaderID = result:GetOldTeamLeaderID()
    local newTeamLeaderID = result:GetNewTeamLeaderID()
    local effectID = result:GetEffectID()
    local isRemove = result:GetRemove()
    local removeAnim = result:GetRemoveAnim()
    local removeAnimTime = result:GetRemoveAnimTime()

    local oldTeamLeader = self._world:GetEntityByID(oldTeamLeaderID)
    local newTeamLeader = self._world:GetEntityByID(newTeamLeaderID)

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    ---@type EffectHolderComponent
    local effectHolderCmpt = newTeamLeader:EffectHolder()
    if not effectHolderCmpt then
        newTeamLeader:AddEffectHolder()
        effectHolderCmpt = newTeamLeader:EffectHolder()
    end

    if isRemove == 1 then
        --会有多个链子同时破碎
        GameGlobal.TaskManager():CoreGameStartTask(
            function(TT)
                local effect = nil
                local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[effectID]
                if effectEntityIdList then
                    effect = self._world:GetEntityByID(effectEntityIdList[1])
                end
                if not effect then
                    return
                end

                local go = effect:View():GetGameObject()

                --破碎动画
                ---@type UnityEngine.Animation
                local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
                if go and anim and anim.clip and removeAnim then
                    anim:Play(removeAnim)
                    if removeAnimTime then
                        YIELD(TT, removeAnimTime)
                    end
                end

                --删除特效
                if go and go ~= null and anim and anim ~= null then
                    self._world:DestroyEntity(effect)
                    effectHolderCmpt:GetEffectIDEntityDic()[effectID][1] = nil
                end
            end
        )
    else
        if notify and (notify:GetNotifyType() == NotifyType.ChainSkillTurnStart) then
            local team = newTeamLeader:Pet():GetOwnerTeamEntity()
            local petList = team:Team():GetTeamPetEntities()
            for i, entity in ipairs(petList) do
                if entity:GetID() ~= newTeamLeaderID then
                    self:RemoveOldTeamLeaderEffect(entity, effectID)
                end
            end
        end

        if oldTeamLeader then
            --卸载掉旧队长身上的特效
            local oldTeamLeader = notify:GetOldTeamLeader()
            self:RemoveOldTeamLeaderEffect(oldTeamLeader, effectID)
        end

        local effectEntityIdList = effectHolderCmpt:GetEffectIDEntityDic()[effectID]
        local effect
        if effectEntityIdList then
            effect = self._world:GetEntityByID(effectEntityIdList[1])
        end

        --如果身上有这个特效，并且特效在播放死亡动画，则隐藏正在死亡的动画，创建新的
        if effect then
            local go = effect:View():GetGameObject()
            ---@type UnityEngine.Animation
            local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
            if anim:IsPlaying(removeAnim) then
                go.gameObject:SetActive(false)
                self._world:DestroyEntity(effect)
                effectHolderCmpt:GetEffectIDEntityDic()[effectID][1] = nil
                effect = nil
            end
        end

        if not effect then
            --需要创建连线特效
            effect = effectService:CreateEffect(effectID, newTeamLeader)
            effectHolderCmpt:AttachPermanentEffect(effect:GetID())
        end
    end
end

--是否匹配参数
---@param notify NTMonsterHPCChange
function BuffViewAddTeamLeaderEffect:IsNotifyMatch(notify)
    ---@type BuffResultAddTeamLeaderEffect
    local result = self._buffResult

    return true
end

function BuffViewAddTeamLeaderEffect:RemoveOldTeamLeaderEffect(oldTeamLeader, effectID)
    ---@type EffectHolderComponent
    local oldTeamLeaderEffectHolderCmpt = oldTeamLeader:EffectHolder()
    if not oldTeamLeaderEffectHolderCmpt then
        Log.warn("BuffViewAddTeamLeaderEffect: old team leader has no EffectHolderComponent. ")
        return
    end
    local effect = nil
    local oldTeamLeaderEffectEntityIdList = oldTeamLeaderEffectHolderCmpt:GetEffectIDEntityDic()[effectID]
    if oldTeamLeaderEffectEntityIdList then
        effect = self._world:GetEntityByID(oldTeamLeaderEffectEntityIdList[1])
    end
    if effect then
        self._world:DestroyEntity(effect)
        oldTeamLeaderEffectHolderCmpt:GetEffectIDEntityDic()[effectID][1] = nil
    end
end
