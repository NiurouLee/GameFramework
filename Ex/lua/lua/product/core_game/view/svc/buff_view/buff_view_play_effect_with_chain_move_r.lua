--[[
    播放特效
]]
_class("BuffViewPlayEffectWithChainMove", BuffViewBase)
---@class BuffViewPlayEffectWithChainMove : BuffViewBase
BuffViewPlayEffectWithChainMove = BuffViewPlayEffectWithChainMove
---
function BuffViewPlayEffectWithChainMove:PlayView(TT, notify)
    ---@type BuffResultPlayEffectWithChainMove
    local buffResult = self._buffResult

    local notifyType = buffResult:GetNotifyType()
    local notifyPos = buffResult:GetNotifyPos()
    local isStart = buffResult:GetIsStart()
    local isEnd = buffResult:GetIsEnd()
    local permanentEffectID = buffResult:GetPermanentEffectID()
    local moveEffectID = buffResult:GetMoveEffectID()
    local useType = buffResult:GetUseType()

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    local e = self._entity
    ---@type EffectHolderComponent
    local effectHolderCmpt = e:EffectHolder()
    if not effectHolderCmpt then
        e:AddEffectHolder()
    end
    effectHolderCmpt = e:EffectHolder()

    if notifyType == NotifyType.PlayerEachMoveStart then
        self:_HandleEachMoveStartByType(e,buffResult,effectHolderCmpt,effectService)
    elseif notifyType == NotifyType.PlayerEachMoveEnd then
        if moveEffectID then
            effectService:CreateWorldPositionEffect(moveEffectID, notifyPos)
        end
        if isEnd then
            self:_HandleChainMoveEndByType(e,buffResult,effectHolderCmpt,effectService)
        end
    elseif notifyType == NotifyType.PetChainMoveBegin then
        if isStart then
            self:_HandleChainMoveBeginByType(e,buffResult,effectHolderCmpt,effectService)
        end
    elseif notifyType == NotifyType.PlayerMoveStart then
        --可以卡住连线流程
        self:_HandlePlayerMoveStartByType(TT,e,buffResult,effectHolderCmpt,effectService)
    end
end
---
function BuffViewPlayEffectWithChainMove:IsNotifyMatch(notify)
    ---@type BuffResultPlayEffectWithChainMove
    local buffResult = self._buffResult

    local notifyType = buffResult:GetNotifyType()
    local notifyPos = buffResult:GetNotifyPos()

    if not notify then
        return false
    end
    if notifyType == NotifyType.PlayerMoveStart then
        local useType = buffResult:GetUseType()
        if useType == PlayEffectWithChainMoveType.Zhongxu then
            return true
        end
    end
    if
        notifyType ~= NotifyType.PlayerEachMoveStart and notifyType ~= NotifyType.PlayerEachMoveEnd and
            notifyType ~= NotifyType.PetChainMoveBegin
     then
        return false
    end
    if notifyType == NotifyType.PetChainMoveBegin then
        --只有队长通知,仲胥作为队员也需要处理
        local useType = buffResult:GetUseType()
        if useType == PlayEffectWithChainMoveType.Zhongxu then
        elseif notify:GetEntityID() ~= self._entity:GetID() then
            return false
        end
    elseif notify:GetEntityID() ~= self._entity:GetID() then
        return false
    end

    if notify:GetNotifyType() ~= notifyType then
        return false
    end

    if notify:GetPos() ~= notifyPos then
        return false
    end

    return true
end
--每次移动开始
---@param buffResult BuffResultPlayEffectWithChainMove
---@param effectHolderCmpt EffectHolderComponent
function BuffViewPlayEffectWithChainMove:_HandleEachMoveStartByType(e,buffResult,effectHolderCmpt,effectService)
    local useType = buffResult:GetUseType()
    local typeParam = buffResult:GetTypeParam()
    if not useType then
        useType = PlayEffectWithChainMoveType.Normal
    end
    if useType == PlayEffectWithChainMoveType.Normal then
        --不处理
    elseif useType == PlayEffectWithChainMoveType.Zhongxu then
        local bvcmpt = self._entity:BuffView()
        local played = bvcmpt:GetBuffValue("ZhongxuTrasnToCatPlayed")
        if played and (played == 1) then--偶现未变身 加容错 log
        else
            Log.error("PlayEffectWithChainMove,EachMoveStart,trans to cat not played")
            local permanentEffectID = buffResult:GetPermanentEffectID()
            if permanentEffectID then
                local effect = effectService:CreateEffect(permanentEffectID, e)
                self:_ZhongxuCatEffectAddMaterialAnimation(effect)
                effectHolderCmpt:AttachPermanentEffect(effect:GetID())
                effectHolderCmpt:AttachChainMovePermanentEffect(effect:GetID())
                self:_ZhongxuShowHideModel(false)
                bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 1)
                bvcmpt:SetBuffValue("ZhongxuCatEffectEntityID", effect:GetID())
            end
        end
    end
end
--开始连线移动
---@param buffResult BuffResultPlayEffectWithChainMove
function BuffViewPlayEffectWithChainMove:_HandleChainMoveBeginByType(e,buffResult,effectHolderCmpt,effectService)
    local useType = buffResult:GetUseType()
    local typeParam = buffResult:GetTypeParam()
    if not useType then
        useType = PlayEffectWithChainMoveType.Normal
    end
    local notifyPos = buffResult:GetNotifyPos()
    local permanentEffectID = buffResult:GetPermanentEffectID()
    local moveEffectID = buffResult:GetMoveEffectID()
    if useType == PlayEffectWithChainMoveType.Normal then
        if moveEffectID then
            effectService:CreateWorldPositionEffect(moveEffectID, notifyPos)
        end
        if permanentEffectID then
            local effect = effectService:CreateEffect(permanentEffectID, e)
            effectHolderCmpt:AttachPermanentEffect(effect:GetID())
            effectHolderCmpt:AttachChainMovePermanentEffect(effect:GetID())
        end
    elseif useType == PlayEffectWithChainMoveType.Zhongxu then
        if moveEffectID then
            effectService:CreateWorldPositionEffect(moveEffectID, notifyPos)
        end
        local bvcmpt = self._entity:BuffView()
        bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 0)

        local transTaskID = bvcmpt:GetBuffValue("ZhongxuTrasnToCatTaskID")
        if transTaskID and (transTaskID > 0) then--避免重复
            return 
        end
        --作为队长时有切换效果
        if typeParam and typeParam.isTeamLeader  then--and (typeParam.chainPathCount > 1)
            -- local transToCatTaskID =
            -- GameGlobal.TaskManager():CoreGameStartTask(
            --     self._ZhongxuPetTransToCat,
            --     self,
            --     e,
            --     effectHolderCmpt,
            --     effectService,
            --     permanentEffectID
            -- )
            -- local bvcmpt = self._entity:BuffView()
            -- bvcmpt:SetBuffValue("ZhongxuTrasnToCatTaskID", transToCatTaskID)
            -- bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 1)
        else
            if permanentEffectID then
                local effect = effectService:CreateEffect(permanentEffectID, e)
                self:_ZhongxuCatEffectAddMaterialAnimation(effect)
                effectHolderCmpt:AttachPermanentEffect(effect:GetID())
                effectHolderCmpt:AttachChainMovePermanentEffect(effect:GetID())
                self:_ZhongxuShowHideModel(false)
                bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 1)
                bvcmpt:SetBuffValue("ZhongxuCatEffectEntityID", effect:GetID())
            end
        end
    end
end
--连线移动结束
---@param buffResult BuffResultPlayEffectWithChainMove
---@param effectService EffectService
function BuffViewPlayEffectWithChainMove:_HandleChainMoveEndByType(e,buffResult,effectHolderCmpt,effectService)
    local useType = buffResult:GetUseType()
    local typeParam = buffResult:GetTypeParam()
    if not useType then
        useType = PlayEffectWithChainMoveType.Normal
    end
    if useType == PlayEffectWithChainMoveType.Normal then
        local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
        effectService:_DestroyEffectArray(permanentEffectList)
        effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
    elseif useType == PlayEffectWithChainMoveType.Zhongxu then
        local bvcmpt = self._entity:BuffView()
        local played = bvcmpt:GetBuffValue("ZhongxuCatTrasnToPetPlayed")
        if played and (played == 1) then--避免重复
            if typeParam and typeParam.isTeamLeader then
            else
                local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
                effectService:_DestroyEffectArray(permanentEffectList)
                effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
                self:_ZhongxuShowHideModel(true)
                bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
                bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 0)
            end
            return
        end
        --作为队长时有切换效果
        if typeParam and typeParam.isTeamLeader  then--and (typeParam.chainPathCount > 1)
            bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
            bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 0)
            local transRevertTaskID =
            GameGlobal.TaskManager():CoreGameStartTask(
                self._ZhongxuCatTransToPet,
                self,
                e,
                effectHolderCmpt,
                effectService
            )
            local bvcmpt = self._entity:BuffView()
            bvcmpt:SetBuffValue("ZhongxuTrasnRevertTaskID", transRevertTaskID)
        else
            local permanentEffectList = effectHolderCmpt:GetChainMovePermanentEffect()
            effectService:_DestroyEffectArray(permanentEffectList)
            effectHolderCmpt:ClearChainMovePermanentEffectIDListAfterDestroy()
            self:_ZhongxuShowHideModel(true)
            bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 1)
            bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 0)
        end
    end
end

---@param effectService EffectService
function BuffViewPlayEffectWithChainMove:_ZhongxuPetTransToCat(TT,e,effectHolderCmpt,effectService,permanentEffectID)
    Log.debug("PlayEffectWithChainMove,play ZhongxuCatTransToPet task")
    --播动作
    ---@type BuffResultPlayEffectWithChainMove
    local buffResult = self._buffResult
    local typeParam = buffResult:GetTypeParam()
    ---@type BuffPlayEffectWithChainMoveZhongxuViewParam
    local specialParam = typeParam.specialParam
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    local chain_path = renderBoardEntity:RenderChainPath():GetRenderChainPath()
    if chain_path and #chain_path > 1 then
        --e:SetDirection(chain_path[2] - chain_path[1])
    end
    local audioID = specialParam._transAudioID or 2585
    AudioHelperController.PlayInnerGameSfx(audioID)
    local actEffID = specialParam._transEffectID or 160181102
    local matAnim = specialParam._transMatAnim or "effanim_1601811_atk_revolve1"
    local animName = specialParam._transAnim or "AttackMove1"
    e:SetAnimatorControllerTriggers({animName})
    effectService:CreateEffect(actEffID, e)
    e:PlayMaterialAnim(matAnim)
    
    YIELD(TT,400)
    local catEffEntity = nil
    if permanentEffectID then
        local effect = effectService:CreateEffect(permanentEffectID, e)
        self:_ZhongxuCatEffectAddMaterialAnimation(effect)
        effectHolderCmpt:AttachPermanentEffect(effect:GetID())
        effectHolderCmpt:AttachChainMovePermanentEffect(effect:GetID())
        catEffEntity = effect
        local bvcmpt = self._entity:BuffView()
        bvcmpt:SetBuffValue("ZhongxuCatEffectEntityID", effect:GetID())
    end
    local catEffID = specialParam._catShowEffectID or 160181106
    effectService:CreateEffect(catEffID, e)
    local catMatAnim = specialParam._catShowMatAnim or "effanim_1601811_atk_weapon02_in"
    if catEffEntity then
        catEffEntity:PlayMaterialAnim(catMatAnim)
    end
    self:_ZhongxuShowHideModel(false)
    --YIELD(TT,500)
    local bvcmpt = self._entity:BuffView()
    bvcmpt:SetBuffValue("ZhongxuTrasnToCatTaskID", 0)
end
function BuffViewPlayEffectWithChainMove:_ZhongxuCatEffectAddMaterialAnimation(effect)
    if not effect then
        return
    end
    local effView = effect:View()
    if not effView then
        return
    end
    local viewWrapper = effView.ViewWrapper
    if not viewWrapper then
        return
    end
    local matAnimMonoCmpt = viewWrapper.GameObject:GetComponent(typeof(MaterialAnimation))
    if matAnimMonoCmpt then
        UnityEngine.Object.Destroy(matAnimMonoCmpt)
    end
    matAnimMonoCmpt = viewWrapper.GameObject:AddComponent(typeof(MaterialAnimation))
    local resServ = self._world.BW_Services.ResourcesPool
    local container = resServ:LoadAsset("globalShaderEffects.asset")
    
    effect:AddMaterialAnimationComponent(container, matAnimMonoCmpt)
    local shaderEffect = "1601811_shader_effects.asset"
    if shaderEffect then
        local containerShaderEffect = resServ:LoadAsset(shaderEffect)
        if containerShaderEffect then
            effect:MaterialAnimationComponent():LoadContainer(containerShaderEffect)
        end
    end
end
---@param effectService EffectService
function BuffViewPlayEffectWithChainMove:_ZhongxuCatTransToPet(TT,e,effectHolderCmpt,effectService)
    Log.debug("PlayEffectWithChainMove,play ZhongxuCatTransToPet task , enter")
    local bvcmpt = self._entity:BuffView()
    local transToCatTaskID = bvcmpt:GetBuffValue("ZhongxuTrasnToCatTaskID")
    if transToCatTaskID and transToCatTaskID > 0 then
        local taskIDs = {transToCatTaskID}
        while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
            YIELD(TT)
        end
    end
    Log.debug("PlayEffectWithChainMove,play ZhongxuCatTransToPet task")
    
    ---@type BuffResultPlayEffectWithChainMove
    local buffResult = self._buffResult
    local typeParam = buffResult:GetTypeParam()
    ---@type BuffPlayEffectWithChainMoveZhongxuViewParam
    local specialParam = typeParam.specialParam

    local audioID = specialParam._transAudioID or 2585
    AudioHelperController.PlayInnerGameSfx(audioID)
    local catEffID = specialParam._catHideEffectID or 160181108
    local catMatAnim = specialParam._catHideMatAnim or "effanim_1601811_atk_weapon02_out"

    local catEffEntity = nil
    local catEffectID = bvcmpt:GetBuffValue("ZhongxuCatEffectEntityID")
    if catEffectID and (catEffectID > 0) then
        catEffEntity = self._world:GetEntityByID(catEffectID)
    end
    effectService:CreateEffect(catEffID, e)
    if catEffEntity then
        catEffEntity:PlayMaterialAnim(catMatAnim)
    end
    local actEffID = specialParam._revertEffectID or 160181104
    effectService:CreateEffect(actEffID, e)
    --e:SetAnimatorControllerTriggers({"idle"})
    YIELD(TT,500)
    local matAnim = specialParam._revertMatAnim or "effanim_1601811_atk_revolve2"
    local animName = specialParam._revertAnim or "AttackMove2"
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
function BuffViewPlayEffectWithChainMove:_ZhongxuShowHideModel(bShow)
    Log.debug("PlayEffectWithChainMove,ZhongxuShowHideModel,",bShow)
    local cView = self._entity:View()
    local CSGameObject = cView:GetGameObject()
    local CSGameObjectRoot = CSGameObject.transform:Find("Root")
    local tSkinnedMeshRender = CSGameObjectRoot.transform:GetComponentsInChildren(typeof(UnityEngine.SkinnedMeshRenderer))
    for i = 0, tSkinnedMeshRender.Length - 1 do
        tSkinnedMeshRender[i].enabled = bShow
    end
end

--(整队)开始连线移动
---@param buffResult BuffResultPlayEffectWithChainMove
function BuffViewPlayEffectWithChainMove:_HandlePlayerMoveStartByType(TT,e,buffResult,effectHolderCmpt,effectService)
    local useType = buffResult:GetUseType()
    local typeParam = buffResult:GetTypeParam()
    if not useType then
        useType = PlayEffectWithChainMoveType.Normal
    end
    local notifyPos = buffResult:GetNotifyPos()
    local permanentEffectID = buffResult:GetPermanentEffectID()
    local moveEffectID = buffResult:GetMoveEffectID()
    if useType == PlayEffectWithChainMoveType.Normal then
    elseif useType == PlayEffectWithChainMoveType.Zhongxu then
        if moveEffectID then
            effectService:CreateWorldPositionEffect(moveEffectID, notifyPos)
        end
        local bvcmpt = self._entity:BuffView()
        bvcmpt:SetBuffValue("ZhongxuCatTrasnToPetPlayed", 0)

        local transTaskID = bvcmpt:GetBuffValue("ZhongxuTrasnToCatTaskID")
        if transTaskID and (transTaskID > 0) then--避免重复
            return 
        end
        local eTeam = self._entity:Pet():GetOwnerTeamEntity()
        --这个通知发出后，可能会临时替换队长（菲雅），重新取一下
        local curIsTeamLeader = (self._entity:GetID() == eTeam:Team():GetTeamLeaderEntityID())
        --作为队长时有切换效果--这个通知只处理队长
        if typeParam and typeParam.isTeamLeader and curIsTeamLeader then--and (typeParam.chainPathCount > 1)
            -- local transToCatTaskID =
            -- GameGlobal.TaskManager():CoreGameStartTask(
            --     self._ZhongxuPetTransToCat,
            --     self,
            --     e,
            --     effectHolderCmpt,
            --     effectService,
            --     permanentEffectID
            -- )
            local transToCatTaskID = 0
            self:_ZhongxuPetTransToCat(TT, e, effectHolderCmpt, effectService, permanentEffectID)
            local bvcmpt = self._entity:BuffView()
            bvcmpt:SetBuffValue("ZhongxuTrasnToCatTaskID", transToCatTaskID)
            bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 1)
        else
            -- if permanentEffectID then
            --     local effect = effectService:CreateEffect(permanentEffectID, e)
            --     self:_ZhongxuCatEffectAddMaterialAnimation(effect)
            --     effectHolderCmpt:AttachPermanentEffect(effect:GetID())
            --     effectHolderCmpt:AttachChainMovePermanentEffect(effect:GetID())
            --     self:_ZhongxuShowHideModel(false)
            --     bvcmpt:SetBuffValue("ZhongxuTrasnToCatPlayed", 1)
            --     bvcmpt:SetBuffValue("ZhongxuCatEffectEntityID", effect:GetID())
            -- end
        end
    end
end