--[[
    禁用启用主动技
]]
--禁用
_class("BuffLogicSetBanActiveSkill", BuffLogicBase)
BuffLogicSetBanActiveSkill = BuffLogicSetBanActiveSkill

function BuffLogicSetBanActiveSkill:Constructor(buffInstance, logicParam)
end

function BuffLogicSetBanActiveSkill:DoLogic()
    local world = self._buffInstance:World()
    world:AddBattleFlag(BattleFlagType.BanActiveSkill)
end

--启用
_class("BuffLogicResetBanActiveSkill", BuffLogicBase)
BuffLogicResetBanActiveSkill = BuffLogicResetBanActiveSkill

function BuffLogicResetBanActiveSkill:Constructor(buffInstance, logicParam)
end

function BuffLogicResetBanActiveSkill:DoLogic()
    local world = self._buffInstance:World()
    world:RemoveBattleFlag(BattleFlagType.BanActiveSkill)
end
