--[[
    增加技能最终伤害
]]
--设置技能伤害加成
_class("BuffLogicChangeSkillFinalByLayer", BuffLogicBase)
---@class BuffLogicChangeSkillFinalByLayer:BuffLogicBase
BuffLogicChangeSkillFinalByLayer = BuffLogicChangeSkillFinalByLayer

function BuffLogicChangeSkillFinalByLayer:Constructor(buffInstance, logicParam)
    ---影响的技能类型 列表
    self._buffInstance._effectList = logicParam.effectList
    self._oneLayerValue = logicParam.oneLayerValue or 0
    self._layerType = logicParam.layerType or self._buffInstance:GetBuffEffectType()
    self._calcLayerMax = logicParam.calcLayerMax or 0
    self._useTeamLayer = logicParam.useTeamLayer or 0 --从队伍身上取layer
end

function BuffLogicChangeSkillFinalByLayer:DoLogic()
    --获取层数
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layerEntity = self._entity
    if self._useTeamLayer == 1 then
        layerEntity = self._world:Player():GetCurrentTeamEntity()
    end
    local layer = svc:GetBuffLayer(layerEntity, self._layerType)
    if self._calcLayerMax > 0 and layer > self._calcLayerMax then
        layer = self._calcLayerMax
    end

    local changeValue = 0
    changeValue = self._oneLayerValue * layer

    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:ChangeSkillFinalParam(self._entity, self:GetBuffSeq(), paramType, changeValue)
    end
end

--取消技能伤害加成
_class("BuffLogicRemoveSkillFinalByLayer", BuffLogicBase)
BuffLogicRemoveSkillFinalByLayer = BuffLogicRemoveSkillFinalByLayer

function BuffLogicRemoveSkillFinalByLayer:Constructor(buffInstance, logicParam)
end

function BuffLogicRemoveSkillFinalByLayer:DoLogic()
    for _, paramType in ipairs(self._buffInstance._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(self._entity, self:GetBuffSeq(), paramType)
    end
end
