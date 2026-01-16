require "monster_behavior_base"

--怪物行为组件-被攻击后改变阵营
---@class MonsterBeHaviorChgCampWhenAttacked : MonsterBeHaviorBase
_class("MonsterBeHaviorChgCampWhenAttacked", MonsterBeHaviorBase)
MonsterBeHaviorChgCampWhenAttacked = MonsterBeHaviorChgCampWhenAttacked

function MonsterBeHaviorChgCampWhenAttacked:Name()
    return "MonsterBeHaviorChgCampWhenAttacked"
end

function MonsterBeHaviorChgCampWhenAttacked:Exec()
    --chg camp
    local monsterData = self:GetMonsterData()
    monsterData:ChgCamp()

    local coreController = self:GetCoreController()
    coreController:GetObjMgr():ChgMonsterCampToPlayer(self.monster)
    
end

function MonsterBeHaviorChgCampWhenAttacked:OnInit(param)
end

function MonsterBeHaviorChgCampWhenAttacked:OnShow()
end

function MonsterBeHaviorChgCampWhenAttacked:OnReset()
end

function MonsterBeHaviorChgCampWhenAttacked:OnRelease()
end
