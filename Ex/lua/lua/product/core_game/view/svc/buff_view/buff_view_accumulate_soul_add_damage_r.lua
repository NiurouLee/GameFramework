--[[
    米亚被动收集灵魂增加伤害
]]
_class("BuffViewAccumulateSoulAddDamage", BuffViewBase)
BuffViewAccumulateSoulAddDamage = BuffViewAccumulateSoulAddDamage

---@param notify NTCollectSouls
function BuffViewAccumulateSoulAddDamage:PlayView(TT, notify)
    ---@type BuffResultAccumulateSoulAddDamage
    local result = self:GetBuffResult()
    local curAccumulateNum = result:GetLayer()
    self._entity:BuffView():SetBuffValue("SoulCount", curAccumulateNum)
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.SetAccumulateNum,
        self._entity:PetPstID():GetPstID(),
        curAccumulateNum
    )
    if notify:GetNotifyEntity() == self._entity then
        return
    end

    self:_PlayCollectSoul(TT, notify:GetTargetEntityList(), notify:GetNotifyEntity())

    local cfgData = self._viewInstance:BuffConfigData()
    local cfg = cfgData:GetViewParams()
    if not cfg then
        return
    end
    local waitTime = cfg.waitBuffViewTime
    if waitTime then
        YIELD(TT, waitTime)
    end
end

function BuffViewAccumulateSoulAddDamage:_PlayCollectSoul(TT, targetEntityList, casterEntity)
    local cfgData = self._viewInstance:BuffConfigData()
    local cfg = cfgData:GetViewParams()
    if not cfg then
        return
    end
    if targetEntityList == nil or table.count(targetEntityList) <= 0 then
        return
    end

    local targetGridPosList = {}
    for k, v in pairs(targetEntityList) do
        if v and v:Location() then
            targetGridPosList[#targetGridPosList + 1] = v:Location():GetPosition()
        end
    end

    if not self._skillService then
        ---@type PlaySkillService
        self._skillService = self._world:GetService("PlaySkill")
    end

    ---@type EffectService
    local effectService = self._world:GetService("Effect")

    local castAudioId = cfg.castAudioId
    local castAnimName = cfg.castAnimName
    local castEffect = cfg.castEffect
    local gridEffectId = cfg.gridEffectID
    local bornEffectId = cfg.bornEffectID
    local bornEffectTime = cfg.bornEffectTime
    local startHigh = cfg.startHigh
    local flyTime = cfg.flyTime
    local endHigh = cfg.endHigh
    local castEndEffectId = cfg.castEndEffectId
    local castEndEffectTime = cfg.castEndEffectTime

    --播放音效
    if castAudioId then
        self._skillService:PlayCastAudio(TT, castAudioId, 0)
    end
    --播放施法者动作和特效
    local effectList = self:_PlayAnimationEffect(TT, casterEntity, castAnimName, castEffect, 0)
    ---出生特效
    if bornEffectId and bornEffectId > 0 then
        for k, v in pairs(targetGridPosList) do
            local renderPos = v
            local effectEntity = effectService:CreatePositionEffect(bornEffectId, renderPos)
        end
    end
    YIELD(TT, bornEffectTime)
    ---弹道特效
    local effectEntityList = {}
    for k, v in pairs(targetGridPosList) do
        local renderPos = v
        renderPos.y = renderPos.y + startHigh
        local effect = effectService:CreatePositionEffect(gridEffectId, renderPos)
        table.insert(effectEntityList, {entity = effect, position = renderPos})
    end
    --飞行
    local taskIDs = {}
    for k, v in pairs(effectEntityList) do
        local view = v.entity:View()
        local go = view:GetGameObject()
        local curTaskID =
            GameGlobal.TaskManager():CoreGameStartTask(
            self._DoFlyLine,
            self,
            v.entity,
            casterEntity,
            v.position,
            flyTime,
            endHigh
        )
        if curTaskID > 0 then
            taskIDs[#taskIDs + 1] = curTaskID
        end
        YIELD(TT)
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
    for i = 1, #effectList do
        self._world:DestroyEntity(effectList[i])
    end

    self:_PlayAnimationEffect(TT, casterEntity, nil, castEndEffectId, castEndEffectTime)
end

function BuffViewAccumulateSoulAddDamage:_PlayAnimationEffect(TT, casterEntity, stAnimationName, nEffectID, nEffectTime)
    --施法者动作
    if stAnimationName and "" ~= stAnimationName then
        casterEntity:SetAnimatorControllerTriggers({stAnimationName})
    end
    local effectList = {}
    --施法者特效
    if nEffectID then
        ---@type EffectService
        local effectService = self._world:GetService("Effect")
        local listEffectID = {}
        if type(nEffectID) == "number" then
            if nEffectID > 0 then ---2019-12-17增加支持配置为空或者0，来跳过本阶段
                listEffectID[#listEffectID + 1] = nEffectID
            end
        elseif type(nEffectID) == "table" then
            listEffectID = nEffectID
        end
        for i = 1, #listEffectID do
            effectList[#effectList + 1] = effectService:CreateEffect(listEffectID[i], casterEntity)
        end
    end
    YIELD(TT, nEffectTime)
    return effectList
end

---直线飞行
function BuffViewAccumulateSoulAddDamage:_DoFlyLine(TT, entityEffect, entityCaster, effectRenderPos, flyTime, endHigh)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local posCaster = entityCaster:GetGridPosition()
    local gridWorldpos = boardServiceRender:GridPos2RenderPos(posCaster)

    ---@type ViewComponent
    local effectViewCmpt = entityEffect:View()
    ---@type UnityEngine.GameObject
    local effectObject = effectViewCmpt:GetGameObject()

    gridWorldpos.y = gridWorldpos.y + endHigh

    local endtime = GameGlobal:GetInstance():GetCurrentTime() + flyTime

    local transWork = effectObject.transform
    local nFlyTime = flyTime / 1000.0
    local easeWork = transWork:DOMove(gridWorldpos, nFlyTime, false):SetEase(DG.Tweening.Ease.InOutSine)

    ---等待飞行结束
    while GameGlobal:GetInstance():GetCurrentTime() < endtime do
        YIELD(TT)
    end
    effectObject:SetActive(false)
    self._world:DestroyEntity(entityEffect)
end
