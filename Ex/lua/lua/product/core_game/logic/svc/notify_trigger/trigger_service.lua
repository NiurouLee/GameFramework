_class("TriggerService", BaseService)
---@class TriggerService : BaseService
TriggerService = TriggerService

function TriggerService:Constructor(world)
	---@type CombinedTrigger[]
    self._listeners = {}
    self._factory = TriggerFactory:New()
end

function TriggerService:ClearTriggers()
    self._listeners={}
end

function TriggerService:Initialize()
    self._showLog = self._world:RunAtClient()
end


function TriggerService:CreateTrigger(triggerOwner, triggerCond, world)
    return self._factory:CreateTrigger(triggerOwner, triggerCond, world)
end
---@param notify INotifyBase
function TriggerService:Notify(notify)
    local notifyEntity = notify:GetNotifyEntity()
    local notifyEntityID = 0
    if notifyEntity then
        notifyEntityID = notifyEntity:GetID()
    end

    ---检查NotifyEntity是否可以发放通知
    local canNotify = self:_CheckEntityCanNotify(notifyEntity, notify)
    if not canNotify then
        Log.debug("[TriggerService] Notify is Forbidden, entityID=", notifyEntityID, " notifyType=", notify:GetNotifyType())
        return
    end

    self:SaveConvertInfo(notify)

    --日志太多，线上关闭
    if self._showLog then
        Log.debug(
            "TriggerService Notify ",
            notify:GetNotifyType(),
            GetEnumKey("NotifyType", notify:GetNotifyType()),
            " NotifyEntity=",
            notifyEntityID
        )
    end

    local notifyType = notify:GetNotifyType()
    local listeners = self._listeners[notifyType]
    if not listeners then
        return
    end

    local triggers = {}
    ---@param combinedTrigger CombinedTrigger
    for i, combinedTrigger in ipairs(listeners) do
        ----被冻结的人 不接受notify 暂时只收怪物死亡+[被控制、被击退和被牵引通知____20230324]
        if combinedTrigger:IsActive() and self:IsNotifyCanTrigger(notify, combinedTrigger) then
            combinedTrigger:OnNotifyWrapper(notify)
            if combinedTrigger:IsSatisfied(notify) then
                table.insert(triggers, combinedTrigger)
            end
        end
    end

    --trigger触发的逻辑里可能增加或删除listener，所以要在外面遍历
    for i, trigger in ipairs(triggers) do
        trigger:OnTrigger(notify)
    end

    --触发次级通知
    local nt = notify:GetSubordinateNotify()
    if nt then
        self:Notify(nt)
    end
end

function TriggerService:Attach(trigger)
    local notifyTypeList = trigger:GetNotifyType()
    for k, notifyType in ipairs(notifyTypeList) do
        local listeners = self._listeners[notifyType]
        if not listeners then
            listeners = {}
            self._listeners[notifyType] = listeners
        end

        listeners[#listeners + 1] = trigger
    end
end

function TriggerService:Detach(trigger)
    local notifyTypeList = trigger:GetNotifyType()
    for k, notifyType in ipairs(notifyTypeList) do
        local listeners = self._listeners[notifyType]
        if not listeners then
            Log.error("detach trigger error, not attached!")
            return
        end

        table.removev(listeners, trigger)
    end
end

----@param notify INotifyBase
---@param combinedTrigger CombinedTrigger
function TriggerService:IsNotifyCanTrigger(notify, combinedTrigger)
    ---被冻结的实体只接受附身对象的死亡、被控制、被击退和被牵引通知
    ---此类通知会解除附身状态
    if notify:GetNotifyType() == NotifyType.MonsterDead or
        notify:GetNotifyType() == NotifyType.AddControlBuffEnd or
        notify:GetNotifyType() == NotifyType.HitBackEnd or
        notify:GetNotifyType() == NotifyType.TractionEnd
    then
        return true
    end

    ---@type TriggerBase[]
    local triggerList = combinedTrigger:GetTriggers()
    for _, trigger in ipairs(triggerList) do
        local entity = trigger:GetOwnerEntity()
        if entity then
            return not entity:BuffComponent():IsBuffFreeze()
        end
    end
    return true
end

---@param notifyEntity Entity
---@param notify INotifyBase
function TriggerService:_CheckEntityCanNotify(notifyEntity, notify)
    if not notifyEntity then
        return true
    end

    local notifyType = notify:GetNotifyType()

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    if buffSvc:IsPetNotifyTypeDisable(notifyEntity, notifyType) then
        return false
    end
    
    return true
end

function TriggerService:GetPlayerMoveEndPosByNotify(notify)
    --不同notify传pos的方法都不一样
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posTeam = teamEntity:GridLocation().Position
    local curMovePos = posTeam
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
    then
        curMovePos = notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport or notify:GetNotifyType() == NotifyType.EntityMoveEnd then
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:HasPet() then
            notifyEntity = notifyEntity:Pet():GetOwnerTeamEntity()
        end
        if teamEntity:GetID() == notifyEntity:GetID() then
            curMovePos = notify:GetPosNew()
        end
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd and notify:GetDefenderId() == teamEntity:GetID() then
        curMovePos = notify:GetPosEnd()
    elseif notify:GetNotifyType() == NotifyType.TractionEnd and notify:GetDefenderId() == teamEntity:GetID() then
        curMovePos = notify:GetPosEnd()
    end

    return curMovePos
end

function TriggerService:GetPlayerMoveBeginPosByNotify(notify)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posTeam = teamEntity:GridLocation().Position
    local moveBeginPos = posTeam
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
    then
        moveBeginPos = notify:GetOldPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport or notify:GetNotifyType() == NotifyType.EntityMoveEnd then
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:HasPet() then
            notifyEntity = notifyEntity:Pet():GetOwnerTeamEntity()
        end
        if teamEntity:GetID() == notifyEntity:GetID() then
            moveBeginPos = notify:GetPosOld()
        end
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd and notify:GetDefenderId() == teamEntity:GetID() then
        moveBeginPos = notify:GetPosStart()
    elseif notify:GetNotifyType() == NotifyType.TractionEnd and notify:GetDefenderId() == teamEntity:GetID() then
        moveBeginPos = notify:GetPosStart()
    end

    return moveBeginPos
end

---@param notify NTGridConvert
function TriggerService:SaveConvertInfo(notify)
end