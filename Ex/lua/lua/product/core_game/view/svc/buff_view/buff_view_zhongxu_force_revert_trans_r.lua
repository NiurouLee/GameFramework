--[[
    
]]
_class("BuffViewZhongxuForceRevertTrans", BuffViewBase)
---@class BuffViewZhongxuForceRevertTrans : BuffViewBase
BuffViewZhongxuForceRevertTrans = BuffViewZhongxuForceRevertTrans

function BuffViewZhongxuForceRevertTrans:PlayView(TT, notify)
    ---@type BuffResultZhongxuForceRevertTrans
    local result = self._buffResult
    ---@type  Entity
    local entity = self._entity
    local bvcmpt = self._entity:BuffView()
    local transToCatTaskID = bvcmpt:GetBuffValue("ZhongxuTrasnToCatTaskID")
    if transToCatTaskID and transToCatTaskID > 0 then
        local taskIDs = {transToCatTaskID}
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
            YIELD(TT)
        end
    end
    local bvcmpt = self._entity:BuffView()
    local isTeamLeader = false
    if entity:HasPet() then
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        local teamLeader = teamEntity:GetTeamLeaderPetEntity()
        if entity:GetID() == teamLeader:GetID() then
            isTeamLeader = true
        end
    end
    local played = bvcmpt:GetBuffValue("ZhongxuCatTrasnToPetPlayed")
    if played and played == 1 then
        if isTeamLeader then
        else
            ---@type EffectHolderComponent
            local effectHolderCmpt = entity:EffectHolder()
            if effectHolderCmpt then
                ---@type EffectService
                local effectService = self._world:GetService("Effect")
                local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
                effectService:_DestroyEffectArray(permanentEffectList)
                effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
                self:_ZhongxuShowHideModel(true)
                bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
                bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 0)
            end
        end
        return
    end
    
    YIELD(TT)
    local bvcmpt = self._entity:BuffView()
    if isTeamLeader then
        ---@type EffectHolderComponent
        local effectHolderCmpt = entity:EffectHolder()
        if effectHolderCmpt then
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
            self:_ZhongxuCatTransToPet(TT,entity,effectHolderCmpt,effectService)
        end
    else
        ---@type EffectHolderComponent
        local effectHolderCmpt = entity:EffectHolder()
        if effectHolderCmpt then
            ---@type EffectService
            local effectService = self._world:GetService("Effect")
            local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
            effectService:_DestroyEffectArray(permanentEffectList)
            effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
            self:_ZhongxuShowHideModel(true)
            bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
        end
    end
end

--是否匹配参数
function BuffViewZhongxuForceRevertTrans:IsNotifyMatch(notify)
    return true
end
function BuffViewZhongxuForceRevertTrans:_ZhongxuShowHideModel(bShow)
    Log.debug("ZhongxuForceRevertTrans, ZhongxuShowHideModel ,",bShow)
    local cView = self._entity:View()
    local CSGameObject = cView:GetGameObject()
    local CSGameObjectRoot = CSGameObject.transform:Find("Root")
    local tSkinnedMeshRender = CSGameObjectRoot.transform:GetComponentsInChildren(typeof(UnityEngine.SkinnedMeshRenderer))
    for i = 0, tSkinnedMeshRender.Length - 1 do
        tSkinnedMeshRender[i].enabled = bShow
    end
end
---@param effectService EffectService
function BuffViewZhongxuForceRevertTrans:_ZhongxuCatTransToPet(TT,e,effectHolderCmpt,effectService)
    Log.debug("ZhongxuForceRevertTrans,play ZhongxuCatTransToPet task , enter")
    local bvcmpt = self._entity:BuffView()
    local transToCatTaskID = bvcmpt:GetBuffValue("ZhongxuTrasnToCatTaskID")
    if transToCatTaskID and transToCatTaskID > 0 then
        local taskIDs = {transToCatTaskID}
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
            YIELD(TT)
        end
    end
    Log.debug("ZhongxuForceRevertTrans,play ZhongxuCatTransToPet task")

    local audioID = 2585
    AudioHelperController.PlayInnerGameSfx(audioID)
    local catEffID = 160181108
    local catMatAnim = "effanim_1601811_atk_weapon02_out"

    local catEffEntity = nil
    local catEffectID = bvcmpt:GetBuffValue("ZhongxuCatEffectEntityID")
    if catEffectID and (catEffectID > 0) then
        catEffEntity = self._world:GetEntityByID(catEffectID)
    end
    effectService:CreateEffect(catEffID, e)
    if catEffEntity then
        catEffEntity:PlayMaterialAnim(catMatAnim)
    end
    local actEffID = 160181104 --sjs_todo
    effectService:CreateEffect(actEffID, e)
    --e:SetAnimatorControllerTriggers({"idle"})
    YIELD(TT,500)
    local matAnim = "effanim_1601811_atk_revolve2"
    local animName = "AttackMove2"
    self:_ZhongxuShowHideModel(true)
    e:SetAnimatorControllerTriggers({animName})
    e:PlayMaterialAnim(matAnim)
    YIELD(TT,500)
    local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
    effectService:_DestroyEffectArray(permanentEffectList)
    effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
    YIELD(TT,400)
    bvcmpt:SetBuffValue("ZhongxuTrasnRevertTaskID", 0)
end