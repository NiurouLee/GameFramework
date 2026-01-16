---buff持有者的攻击力 = buff持有者的攻击力 + 施法者攻击力 * 攻击力百分比 * 某种属性格子数量

---@class BuffLogicChangeAttackByCasterPieceCount: BuffLogicBase
_class("BuffLogicChangeAttackByCasterPieceCount", BuffLogicBase)
BuffLogicChangeAttackByCasterPieceCount = BuffLogicChangeAttackByCasterPieceCount

function BuffLogicChangeAttackByCasterPieceCount:Constructor(buffInstance, logicParam)
    self._mul = logicParam.mul or 0
    ---@type PieceType[]
    self._element = logicParam.element or {} --格子颜色数组
end

function BuffLogicChangeAttackByCasterPieceCount:DoLogic()
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
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posList = boardServiceLogic:GetGridPosByPieceType(self._element)
    local pieceCount = table.count(posList)
    local val = base * self._mul * pieceCount
    local eBeneficiary = self._buffInstance:Entity()
    self._buffLogicService:ChangeBaseAttack(
        eBeneficiary,
        self:GetBuffSeq(),
        ModifyBaseAttackType.AttackConstantFix,
        val
    )
    self._buffInstance._ChangeAttackType = ModifyBaseAttackType.AttackConstantFix
end

---@class BuffLogicUndoChangeAttackByCasterPieceCount: BuffLogicBase
_class("BuffLogicUndoChangeAttackByCasterPieceCount", BuffLogicBase)
BuffLogicUndoChangeAttackByCasterPieceCount = BuffLogicUndoChangeAttackByCasterPieceCount

function BuffLogicUndoChangeAttackByCasterPieceCount:Constructor(buffInstance, logicParam)
end

function BuffLogicUndoChangeAttackByCasterPieceCount:DoLogic()
    local eBeneficiary = self._buffInstance:Entity()
    self._buffLogicService:RemoveBaseAttack(eBeneficiary, self:GetBuffSeq(), self._buffInstance._ChangeAttackType)
end
