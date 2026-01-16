--[[
    根据怪物Buff效果类型触发Buff效果
]]
_class("BuffLogicBuffEffectTrigger", BuffLogicBase)
---@class BuffLogicBuffEffectTrigger:BuffLogicBase
BuffLogicBuffEffectTrigger = BuffLogicBuffEffectTrigger

function BuffLogicBuffEffectTrigger:Constructor(buffInstance, logicParam)
    self._buffEffectType = logicParam.buffEffectType
    self._buffID = logicParam.buffID
end

function BuffLogicBuffEffectTrigger:DoLogic(notify)
    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    local owner = self._buffInstance:Entity()
    local success = false
    local buffCount = 0
    --获取所有怪物
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
        local buffCom = monsterEntity:BuffComponent()
        if buffCom then
            local buffInstance = buffCom:GetSingleBuffByBuffEffect(self._buffEffectType)
            if buffInstance then
                --添加buff
                buffSvc:AddBuff(self._buffID, owner)
                buffCount = buffCount + 1
                success = true
            end
        end
    end
    if success then
        --通知执行buff逻辑
        self._world:GetService("Trigger"):Notify(NTNotifyTriggerBuff:New(owner))
    end
    local res = BuffResultBuffEffectTrigger:New(buffCount,success)
    return res
end
