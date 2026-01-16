require "monster_behavior_base"

--怪物行为组件-显示进度条
---@class MonsterBeHaviorShowHpProgress : MonsterBeHaviorBase
_class("MonsterBeHaviorShowHpProgress", MonsterBeHaviorBase)
MonsterBeHaviorShowHpProgress = MonsterBeHaviorShowHpProgress

function MonsterBeHaviorShowHpProgress:Name()
    return "MonsterBeHaviorShowHpProgress"
end

function MonsterBeHaviorShowHpProgress:SetProgress( hp)
    local bounceController = self:GetCoreController()
    bounceController:HPProgressChange(self.monster:GetPstId(), hp, self.monster.monsterData.initHp)
end

function MonsterBeHaviorShowHpProgress:OnInit(param)
end

function MonsterBeHaviorShowHpProgress:OnShow()
    ---@type BounceController
    local bounceController = self:GetCoreController()
    bounceController:ShowHPProgress(self.monster:GetPstId(), self.monster.monsterData.initHp)
end

function MonsterBeHaviorShowHpProgress:OnReset()
    ---@type BounceController
    local bounceController = self:GetCoreController()
    bounceController:HideHPProgress(self.monster:GetPstId())
end

function MonsterBeHaviorShowHpProgress:OnRelease()
end
