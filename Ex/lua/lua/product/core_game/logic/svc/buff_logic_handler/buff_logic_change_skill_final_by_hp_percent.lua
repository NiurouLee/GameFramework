---@class ChangeSkillFinalByHPPercentType
local ChangeSkillFinalByHPPercentType ={
	RestHP = 1,  ---剩余血量百分比
	LostHP = 2,  ---损失血量百分比
}
_enum("ChangeSkillFinalByHPPercentType",ChangeSkillFinalByHPPercentType)

--[[
    当目标损失N%血量，buff持有者的最终伤害提升M%
]]
---@class BuffLogicChangeSkillFinalByHPPercent:BuffLogicBase
_class("BuffLogicChangeSkillFinalByHPPercent", BuffLogicBase)
BuffLogicChangeSkillFinalByHPPercent = BuffLogicChangeSkillFinalByHPPercent

function BuffLogicChangeSkillFinalByHPPercent:Constructor(buffInstance, logicParam)
    self._HPPercent = logicParam.HPPercent or {}
    self._promote = logicParam.promote or {}
    -- _HPPercent _promote 是阶段性的配置表

    --region 线性参数
    self._useLinear = logicParam.useLinear--用线性方法
    self._promoteType = logicParam.promoteType or ChangeSkillFinalByHPPercentType.RestHP--决定是按照血量计算方式（每有xx百分比的血  或   每失去xx百分比的血）
    self._eachHpPercent = logicParam.eachHpPercent--每有/失去多少百分比的hp
    self._promotePercent = logicParam.promotePercent--提升多少的skillFInal
    self._maxSkillFinal = logicParam.maxSkillFinal--最多提升的skillFInal
    --region end
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList ---影响的技能类型 列表

    ---默认1代表取defender，2代表取Team，3代表buff宿主
    self._calcSourceType = tonumber(logicParam.hpPercentSourceType) or 1
    self._entity = buffInstance._entity --buff持有者
end

---@param notify NotifyAttackBase
function BuffLogicChangeSkillFinalByHPPercent:DoLogic(notify)
    local sourceEntity = nil
    if self._calcSourceType == 1 then 
        sourceEntity = notify:GetDefenderEntity()
    elseif self._calcSourceType == 2 then 
        sourceEntity = self._world:Player():GetCurrentTeamEntity()
    elseif self._calcSourceType == 3 then 
        sourceEntity = self:GetEntity()
    end
    
    local cAttributes = sourceEntity:Attributes()
    local curHP = cAttributes:GetCurrentHP()
    local maxHP = cAttributes:CalcMaxHp()
    local percentHP = curHP / maxHP
    if self._promoteType == ChangeSkillFinalByHPPercentType.LostHP then
        percentHP = (maxHP - curHP) / maxHP
    end
    local promoteRate = 0
    if self._useLinear and (self._useLinear == 1) then--用线性
        if self._eachHpPercent and self._promotePercent and (self._eachHpPercent ~= 0) then
            promoteRate = percentHP / self._eachHpPercent * self._promotePercent
            if self._maxSkillFinal and (promoteRate > self._maxSkillFinal) then
                promoteRate = self._maxSkillFinal
            end
        end
    else
        local sepIdx = 0
        for index, per in ipairs(self._HPPercent) do --拿到目标当前HP比例小于等于per且大于下一个的索引
            if per >= percentHP then
                sepIdx = index
            end
        end
        promoteRate = self._promote[sepIdx] or 0
    end
    if promoteRate == 0 then
        return
    end
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:ChangeSkillFinalParam(self._entity, self:GetBuffSeq(), paramType, promoteRate)
    end
end
----------------------------------------------------------------------------------
---@class BuffLogicRemoveSkillFinalByHPPercent:BuffLogicBase
_class("BuffLogicRemoveSkillFinalByHPPercent", BuffLogicBase)
BuffLogicRemoveSkillFinalByHPPercent = BuffLogicRemoveSkillFinalByHPPercent

function BuffLogicRemoveSkillFinalByHPPercent:Constructor(buffInstance, logicParam)
    self._entity = buffInstance._entity
    ---@type ModifySkillParamType[]
    self._effectList = logicParam.effectList
end

function BuffLogicRemoveSkillFinalByHPPercent:DoLogic()
    for _, paramType in ipairs(self._effectList) do
        self._buffLogicService:RemoveSkillFinalParam(self._entity, self:GetBuffSeq(), paramType)
    end
end
