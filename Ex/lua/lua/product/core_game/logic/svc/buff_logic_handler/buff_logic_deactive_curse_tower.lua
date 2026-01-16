--[[
    将诅咒塔失活
]]

_class("BuffLogicDeactiveCurseTower", BuffLogicBase)
BuffLogicDeactiveCurseTower = BuffLogicDeactiveCurseTower

function BuffLogicDeactiveCurseTower:Constructor(buffInstance, logicParam)
end

function BuffLogicDeactiveCurseTower:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type CurseTowerComponent
    local curseTowerCmpt = e:CurseTower()
    if not curseTowerCmpt then 
        return 
    end

    curseTowerCmpt:SetTowerState(CurseTowerState.Deactive)
    return true
end
