--[[------------------------------------------------------------------------------------------
    DeadMarkComponent : 用于标记逻辑死亡
    带这个组件的Entity，将不会被技能逻辑选中。如果有其他逻辑信息，也可以放在这里。
    怪物行动阶段，血量变为0的怪物，会挂上此组件，后续的所有技能都不会选择死亡目标；
]] --------------------------------------------------------------------------------------------

---@class DeadMarkComponent: Object
_class("DeadMarkComponent", Object)
DeadMarkComponent = DeadMarkComponent

function DeadMarkComponent:Constructor(addCount)
    ---被谁打死
    self._casterEntityID = nil

    ---上面那个施法者的第几次连锁技打死，连锁技可以有多次重复施放
    self._chainAttackIndex = -1

    ---是否已经处理逻辑死亡效果
    self._hasDoLogicDead = false

    self._addCount = addCount
end

function DeadMarkComponent:SetDeadCasterID(casterEntityID)
    self._casterEntityID = casterEntityID
end

---死亡触发者
function DeadMarkComponent:GetDeadCasterID()
    return self._casterEntityID
end

function DeadMarkComponent:SetChainAttackIndex(atkIndex)
    self._chainAttackIndex = atkIndex
end

---第几次连锁技
function DeadMarkComponent:GetChainAttackIndex()
    return self._chainAttackIndex
end

function DeadMarkComponent:SetDoLogicDead(hasDoLogic)
    self._hasDoLogicDead = hasDoLogic
end

function DeadMarkComponent:HasDoLogicDead()
    return self._hasDoLogicDead
end

function DeadMarkComponent:GetDeadMarkAddCount()
    return self._addCount
end

 ---@return DeadMarkComponent
function Entity:DeadMark()
    return self:GetComponent(self.WEComponentsEnum.DeadMark)
end

function Entity:HasDeadMark()
    return self:HasComponent(self.WEComponentsEnum.DeadMark)
end

function Entity:AddDeadMark()
    local addCount = self._world:BattleStat():FetchNewDeadMarkAddCount()
    local index = self.WEComponentsEnum.DeadMark
    local component = DeadMarkComponent:New(addCount)
    self:AddComponent(index, component)
    self._world:GetSyncLogger():Trace({key = "AddDeadMark", entityID = self:GetID()})
end

function Entity:ReplaceDeadMark()
    local addCount = self._world:BattleStat():FetchNewDeadMarkAddCount()
    local index = self.WEComponentsEnum.DeadMark
    local component = DeadMarkComponent:New(addCount)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveDeadMark()
    if self:HasDeadMark() then
        self:RemoveComponent(self.WEComponentsEnum.DeadMark)
    end
end
