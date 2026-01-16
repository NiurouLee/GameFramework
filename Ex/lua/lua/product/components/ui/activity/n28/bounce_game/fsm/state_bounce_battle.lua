---@class StateBounceBattle : StateBounceBase
_class("StateBounceBattle", StateBounceBase)
StateBounceBattle = StateBounceBattle

function StateBounceBattle:OnEnter(TT, ...)
    self:Init()
    
end

function StateBounceBattle:OnExit(TT)
end

--战斗时间轴更新
function StateBounceBattle:OnUpdate(deltaTimeMS)
    self.bounceData.durationMs = self.bounceData.durationMs + deltaTimeMS

    --生成器更新
    for k, v in pairs(self.monsterGenerator) do
        v:OnUpdate(deltaTimeMS)
    end

    --对象管理器战斗更新
    self.objMgr:OnUpdate(deltaTimeMS)
end

function StateBounceBattle:OnJump()
    self:GetPlayer():OnJump()
end

function StateBounceBattle:OnAttack()
    self:GetPlayer():OnAttack()
end