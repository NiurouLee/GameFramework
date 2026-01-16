---@class StateBounceBase : State
_class("StateBounceBase", State)
StateBounceBase = StateBounceBase

function StateBounceBase:Init()
    if not self.coreController then
        ---@type coreController
        self.coreController = self.fsm:GetData()
        
        ---@type BounceData
        self.bounceData = self.coreController:GetData()
    
        ---@type UIBounceMainController
        self.uiController = self.coreController:GetUIController()
    
        ---@type BounceMonsterPool
        self.monsterPool = self.coreController:GetMonsterPool()
    
        ---@type BounceObjMgr
        self.objMgr = self.coreController:GetObjMgr()
    
        ---@type MonsterGenerator
        self.monsterGenerator = self.coreController:GetMonsterGenerator()
    end
end

function StateBounceBase:GetPlayer()
    return self.objMgr.player
end


function StateBounceBase:Destroy()
end

--子类继承执行
function StateBounceBase:OnJump()
end

--子类继承执行
function StateBounceBase:OnAttack()
end