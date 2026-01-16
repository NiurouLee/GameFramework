---@class SkillEffectEnum_SummonType
local SkillEffectEnum_SummonType = {
    Monster = 1, ---怪物
    Trap = 2, ---机关
    Drop = 3 ---掉落
}
_enum("SkillEffectEnum_SummonType", SkillEffectEnum_SummonType)

--[[
    SkillEffectResult_SummonEverything : 召唤技能结果
]]
_class("SkillEffectResult_SummonEverything", SkillEffectResultBase)
---@class SkillEffectResult_SummonEverything: SkillEffectResultBase
SkillEffectResult_SummonEverything = SkillEffectResult_SummonEverything

---@param posSummon Vector2
---@param posCenter Vector2
function SkillEffectResult_SummonEverything:Constructor(nSummonType, nSummonID, posCenter, posSummon)
    self.m_nSummonType = nSummonType
    self.m_nSummonID = nSummonID
    self.m_posCenter = posCenter or Vector2(0, 0)
    self.m_posSummon = posSummon
    self._dir =Vector2(0,1)

    ---运行时数据
    self.m_monster = {}
    self.m_trap = {}

    ---召唤时的姿态数据
    ---@type MonsterTransformParam
    self._transformData = nil
end

function SkillEffectResult_SummonEverything:GetEffectType()
    return SkillEffectType.SummonEverything
end

function SkillEffectResult_SummonEverything:GetSummonType()
    return self.m_nSummonType
end
function SkillEffectResult_SummonEverything:GetSummonID()
    return self.m_nSummonID
end
function SkillEffectResult_SummonEverything:GetSummonPos()
    return self.m_posSummon
end
function SkillEffectResult_SummonEverything:SetSummonPos(posSummon)
    self.m_posSummon = posSummon
    if self._transformData then
        self._transformData:SetPosition(posSummon)
    end
end
function SkillEffectResult_SummonEverything:GetPosCenter()
    return self.m_posCenter
end

function SkillEffectResult_SummonEverything:GetGridPos()
    return self.m_posSummon
end

function SkillEffectResult_SummonEverything:SetMonsterData(nMonsterID, entityWorkID, entityHp, transformData)
    local monsterData = {}
    monsterData.m_nMonsterID = nMonsterID
    monsterData.m_entityWorkID = entityWorkID
    monsterData.m_entityHp = entityHp
    self.m_monster = monsterData

    self._transformData = transformData
end

function SkillEffectResult_SummonEverything:GetMonsterData()
    return self.m_monster
end

function SkillEffectResult_SummonEverything:SetTrapData(nTrapID, entityWorkID)
    local trapData = {}
    trapData.m_nTrapID = nTrapID
    ---@type Entity
    trapData.m_entityWorkID = entityWorkID
    self.m_trap = trapData
end

function SkillEffectResult_SummonEverything:GetTrapData()
    return self.m_trap
end

function SkillEffectResult_SummonEverything:GetSummonTransformData()
    return self._transformData
end

function SkillEffectResult_SummonEverything:SetDirection(direction)
    self._dir = direction
end