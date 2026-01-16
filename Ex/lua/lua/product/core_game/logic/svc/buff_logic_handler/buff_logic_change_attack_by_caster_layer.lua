---buff持有者的攻击力 = buff持有者的攻击力 + 施法者攻击力 * 攻击力百分比 * 施法者某种buff层数

---@class BuffLogicChangeAttackByCasterLayer: BuffLogicBase
_class("BuffLogicChangeAttackByCasterLayer", BuffLogicBase)
BuffLogicChangeAttackByCasterLayer = BuffLogicChangeAttackByCasterLayer

function BuffLogicChangeAttackByCasterLayer:Constructor(buffInstance, logicParam)
    self._layerType = logicParam.layerType
    self._mulPerLayer = logicParam.mulPerLayer or 0
end

function BuffLogicChangeAttackByCasterLayer:DoLogic()
    if not self._layerType then
        Log.fatal("### layerType is nil")
        return
    end
    local context = self._buffInstance:Context()
    if not context then
        return
    end
    --- 从别处复制来的，没看到context的完整结构定义，也没有类型注释，不确定是否有函数获取施法者
    ---@type Entity
    local eCaster = context.casterEntity
    local cAttrCaster = eCaster:Attributes()
    local base = cAttrCaster:GetAttribute("Attack")
    if not base then
        return
    end
    local eBeneficiary = self._buffInstance:Entity()
    local layerCount = self._buffLogicService:GetBuffLayer(eCaster, self._layerType) or 0
    local val = base * self._mulPerLayer * layerCount
    self._buffLogicService:ChangeBaseAttack(
        eBeneficiary,
        self:GetBuffSeq(),
        ModifyBaseAttackType.AttackConstantFix,
        val
    )
    self._buffInstance.BuffLogicChangeAttackByCasterLayer_ChangeAttackType = ModifyBaseAttackType.AttackConstantFix
    -- local result = BuffResultChangeAttackByCasterLayer:New(eCaster:GetID(), val)
    -- return result
end

---@class BuffLogicUndoChangeAttackByCasterLayer: BuffLogicBase
_class("BuffLogicUndoChangeAttackByCasterLayer", BuffLogicBase)
BuffLogicUndoChangeAttackByCasterLayer = BuffLogicUndoChangeAttackByCasterLayer

function BuffLogicUndoChangeAttackByCasterLayer:Constructor(buffInstance, logicParam)
end

function BuffLogicUndoChangeAttackByCasterLayer:DoLogic()
    local eBeneficiary = self._buffInstance:Entity()
    self._buffLogicService:RemoveBaseAttack(
        eBeneficiary,
        self:GetBuffSeq(),
        self._buffInstance.BuffLogicChangeAttackByCasterLayer_ChangeAttackType
    )
    -- local context = self._buffInstance:Context()
    -- local casterEntityID = 0
    -- if context then
    --     casterEntityID = context.casterEntity:GetID()
    -- end
    -- local result = BuffResultUndoChangeAttackByCasterLayer:New(casterEntityID)
    -- return result
end
