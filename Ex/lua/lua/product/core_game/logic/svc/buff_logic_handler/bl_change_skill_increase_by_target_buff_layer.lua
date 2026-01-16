--[[
    根据目标身上的buff的Layer 增加挂载者技能伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillIncreaseByTargetBuffLayer", BuffLogicBase)
---@class BuffLogicChangeSkillIncreaseByTargetBuffLayer:BuffLogicBase
BuffLogicChangeSkillIncreaseByTargetBuffLayer = BuffLogicChangeSkillIncreaseByTargetBuffLayer

function BuffLogicChangeSkillIncreaseByTargetBuffLayer:Constructor(buffInstance, logicParam)
    self._buffInstance._effectList = logicParam.effectList
    self._minValue = logicParam.minValue or 0
    self._oneLayerValue = logicParam.oneLayerValue or 0
    self._layerType = logicParam.layerType
end

function BuffLogicChangeSkillIncreaseByTargetBuffLayer:DoLogic(notify)
    --挂载者 增伤的目标
    local casterEntity = self._buffInstance:Entity()
    --攻击目标 检测的目标
    local defenderEntity = notify:GetDefenderEntity()
    if not defenderEntity then
        return
    end

    --获取层数
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layer = svc:GetBuffLayer(defenderEntity, self._layerType)
    local changeValue = self._minValue + self._oneLayerValue * layer
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillIncrease(casterEntity, self:GetBuffSeq(), paramType, changeValue)
    end
end

function BuffLogicChangeSkillIncreaseByTargetBuffLayer:DoOverlap(logicParam)
    return self:DoLogic()
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillIncreaseByTargetBuffLayer", BuffLogicBase)
---@class BuffLogicRemoveSkillIncreaseByTargetBuffLayer:BuffLogicBase
BuffLogicRemoveSkillIncreaseByTargetBuffLayer = BuffLogicRemoveSkillIncreaseByTargetBuffLayer

function BuffLogicRemoveSkillIncreaseByTargetBuffLayer:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillIncreaseByTargetBuffLayer:DoLogic()
    --挂载者 增伤的目标
    local casterEntity = self._buffInstance:Entity()
    if not casterEntity then
        return
    end
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillIncrease(casterEntity, self:GetBuffSeq(), paramType)
    end
    return true
end

function BuffLogicRemoveSkillIncreaseByTargetBuffLayer:DoOverlap(logicParam)
end
