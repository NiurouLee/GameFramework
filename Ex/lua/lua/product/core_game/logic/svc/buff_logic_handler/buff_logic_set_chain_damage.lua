--[[
    链接伤害，传递伤害/恢复
]]
_class("BuffLogicSetChainDamage", BuffLogicBase)
---@class BuffLogicSetChainDamage: BuffLogicBase
BuffLogicSetChainDamage = BuffLogicSetChainDamage

function BuffLogicSetChainDamage:Constructor(buffInstance, logicParam)
    self._damage = logicParam.damage
    self._recover = logicParam.recover
    self._enable = logicParam.enable or 1
    self._remove = logicParam.remove or 0
    self._lineEffectID = logicParam.lineEffectID

    self._removeAnim = logicParam.removeAnim
    self._removeEffectID = logicParam.removeEffectID
    self._removeTargetBuffEffectTypeList = logicParam.removeTargetBuffEffectTypeList or {}

    self._onlyView = logicParam.onlyView or 0
end

function BuffLogicSetChainDamage:DoLogic(notify)
    ---@type Entity
    local entity = self._buffInstance:Entity()

    local context = self._buffInstance:Context()
    if not context then
        return
    end
    local casterEntity = context.casterEntity
    if not casterEntity then
        return
    end
    local effectCasterEntity = casterEntity--兼容 由skillHolder释放的技能挂buff
    if casterEntity:HasSuperEntity() then
        effectCasterEntity = casterEntity:GetSuperEntity()
    end
    --自己不能给自己加
    if effectCasterEntity:GetID() == entity:GetID() and self._remove == 0 then
        return
    end

    -- if casterEntity:HasDeadMark() then
    --     return
    -- end

    if notify and notify:GetNotifyType() == NotifyType.ChangeTeamLeader then
        --换队长的时候逻辑不变，只是表现上把线连给新队长
    else
        --被挂buff的和施法者都添加链接属性
        local isAdd = (self._remove ~= 1)
        --设置buff的挂载者和buff的施法者
        if isAdd then
            self:_SetLogicChainValue(entity:GetID(), effectCasterEntity:GetID())
            self:_SetLogicChainValue(effectCasterEntity:GetID(), entity:GetID())
        else
            if self._onlyView == 0 then
                self:_ClearChainEntity(entity:GetID())
            else
                self._removeLineEntityList = {}
                local teamEntity = self._world:Player():GetCurrentTeamEntity()
                local teamLeader = teamEntity:Team():GetTeamLeaderEntity()
                table.insert(self._removeLineEntityList, teamEntity:GetID())
            end
        end
    end

    local buffResult =
        BuffResultSetChainDamage:New(casterEntity:GetID(), entity:GetID(), self._lineEffectID, self._remove)
    buffResult:SetRemoveAnim(self._removeAnim)
    buffResult:SetRemoveEffectID(self._removeEffectID)
    buffResult:SetRemoveLineEntityList(self._removeLineEntityList)

    if notify and notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        buffResult:SetMonsterMoveOneFinish(notify:GetNotifyEntity():GetID(), notify:GetWalkPos())
    end
    if notify and notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        buffResult:SetTeamLeaderEachMoveEnd(notify:GetPos())
    end

    return buffResult
end

function BuffLogicSetChainDamage:DoOverlap(logicParam, context)
    self._buffInstance:SetContext(context)
    return self:DoLogic()
end

---在被击者身上的组件里设置下一个传递者的系数
function BuffLogicSetChainDamage:_SetLogicChainValue(defenderID, chainEntityID, isAdd)
    local entity = self._world:GetEntityByID(defenderID)

    --链接伤害组件
    if not entity:HasLogicChainDamage() then
        entity:AddLogicChainDamage()
    end
    ---@type LogicChainDamageComponent
    local logicChainDamage = entity:LogicChainDamage()

    -- if isAdd then
    if self._damage then
        logicChainDamage:SetChainDamageList(chainEntityID, self._damage)
    end
    if self._recover then
        logicChainDamage:SetChainRecoverList(chainEntityID, self._recover)
    end

    if self._enable then
        logicChainDamage:SetChainDamageEnable(self._enable == 1)
    end

    --因为要不同的怪物添加相同的buff，buff改成了叠加，再每次叠加挂载的时候更换了 context.casterEntity。所以这里不能再直接删除buff的施法者身上组件的值
    --
    -- else
    --     logicChainDamage:SetChainDamageList(chainEntityID, nil)
    --     logicChainDamage:SetChainRecoverList(chainEntityID, nil)
    -- end
end

function BuffLogicSetChainDamage:_ClearChainEntity(castererID)
    local entity = self._world:GetEntityByID(castererID)
    if not entity:HasLogicChainDamage() then
        entity:AddLogicChainDamage()
    end
    ---@type LogicChainDamageComponent
    local logicChainDamage = entity:LogicChainDamage()

    --将和自己相连的交给表现删除连线。如果执行删除的是被添加buff的，自己是没有特效的，需要告诉那些对自己施法链接的人做删除连线表现
    self._removeLineEntityList = {}

    --清除和自己链接的其他人身上关于自己的信息
    local damageList = logicChainDamage:GetChainDamageList()
    for chainEntityID, percent in pairs(damageList) do
        local chainEntity = self._world:GetEntityByID(chainEntityID)
        ---@type LogicChainDamageComponent
        local chainEntityComponent = chainEntity:LogicChainDamage()
        chainEntityComponent:SetChainDamageList(castererID, nil)
        -- self:_RemoveTargetBuff(chainEntityID)

        if not table.intable(self._removeLineEntityList, chainEntityID) then
            table.insert(self._removeLineEntityList, chainEntityID)
        end
    end

    local recoverList = logicChainDamage:GetChainRecoverList()
    for chainEntityID, percent in pairs(recoverList) do
        local chainEntity = self._world:GetEntityByID(chainEntityID)
        ---@type LogicChainDamageComponent
        local chainEntityComponent = chainEntity:LogicChainDamage()
        chainEntityComponent:SetChainRecoverList(castererID, nil)
        -- self:_RemoveTargetBuff(chainEntityID)

        if not table.intable(self._removeLineEntityList, chainEntityID) then
            table.insert(self._removeLineEntityList, chainEntityID)
        end
    end

    logicChainDamage:Clear()
end

function BuffLogicSetChainDamage:_RemoveTargetBuff(defenderID)
    if not self._removeTargetBuffEffectTypeList or table.count(self._removeTargetBuffEffectTypeList) == 0 then
        return
    end

    ---@type Entity
    local entity = self._buffInstance:Entity()
    local defender = self._world:GetEntityByID(defenderID)
    ---@type BuffComponent
    local buffCmpt = defender:BuffComponent()
    local buffArray = buffCmpt:GetBuffArray()
    local buffCopy = table.shallowcopy(buffArray)

    for _, buffInstance in ipairs(buffCopy) do
        local target
        if table.intable(self._removeTargetBuffEffectTypeList, buffInstance:GetBuffEffectType()) then
            local context = buffInstance:Context()
            if context and context.casterEntity then
                local casterEntity = context.casterEntity
                local effectCasterEntity = casterEntity
                if casterEntity:HasSuperEntity() then
                    effectCasterEntity = casterEntity:GetSuperEntity()
                end
                if effectCasterEntity:GetID() == entity:GetID() then
                    buffInstance:Unload(NTBuffUnload:New())
                end
            end
            
        end
    end
end
