require "behavior_base"

--怪物行为组件基类
---@class MonsterBeHaviorBase : BeHaviorBase
_class("MonsterBeHaviorBase", BeHaviorBase)
MonsterBeHaviorBase = MonsterBeHaviorBase

function MonsterBeHaviorBase:SetMonster(monster)
    ---@type Monster
    self.monster = monster
end

---@return Monster
function MonsterBeHaviorBase:GetMonster()
    return self.monster
end

---@return MonsterData
function MonsterBeHaviorBase:GetMonsterData()
    return self.monster:GetMonsterData()
end

function MonsterBeHaviorBase:GetCfg()
    local monsterCfg = self:GetMonsterData().cfg
    return monsterCfg
end

function MonsterBeHaviorBase:GetBehavior(behaviorName)
    return self.monster:GetBehavior(behaviorName)
end

function MonsterBeHaviorBase:GetCoreController()
    return self.monster:GetCoreController()
end

function MonsterBeHaviorBase:GetBounceData()
    return self.monster:GetCoreController():GetData()
end

function MonsterBeHaviorBase:Exec()
end

function MonsterBeHaviorBase:ExecAsync(TT,finishCall)
    if finishCall then
        finishCall()
    end
end

function MonsterBeHaviorBase:Init(param)
    self:OnInit(param)
end

function MonsterBeHaviorBase:Show()
    self:OnShow()
end

function MonsterBeHaviorBase:Reset()
    self:OnReset()
end

function MonsterBeHaviorBase:Release()
    self:OnRelease()
end

function MonsterBeHaviorBase:OnShow()
end

function MonsterBeHaviorBase:OnInit(param)
end

function MonsterBeHaviorBase:OnReset()
end

function MonsterBeHaviorBase:OnRelease()
end
