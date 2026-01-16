--[[
    
]]
---@class BuffLogicSetNormalSkillWithBuffLayerAndTrap:BuffLogicBase
_class("BuffLogicSetNormalSkillWithBuffLayerAndTrap", BuffLogicBase)
BuffLogicSetNormalSkillWithBuffLayerAndTrap = BuffLogicSetNormalSkillWithBuffLayerAndTrap

function BuffLogicSetNormalSkillWithBuffLayerAndTrap:Constructor(buffInstance, logicParam)
    self._trapIDs = logicParam.trapIDs
    self._buffEffectType = logicParam.buffEffectType
    self._addLayer = logicParam.addLayer
    self._skillList = logicParam.skillList
end

function BuffLogicSetNormalSkillWithBuffLayerAndTrap:DoLogic(notify)
    local e = self._buffInstance:Entity()
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()

    local setSkillParam = nil

    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layerCount = svc:GetBuffLayer(e, self._buffEffectType)

    if layerCount and layerCount > 0 then
        setSkillParam = {}
        setSkillParam.buffEffectType = self._buffEffectType
        setSkillParam.curLayerCount = layerCount
        setSkillParam.trapIDs = self._trapIDs
        setSkillParam.addLayer = self._addLayer
        setSkillParam.skillList = self._skillList
    end

    --储存连线中替换的普攻技能
    buffCmpt:SetBuffValue("ChangeNormalSkillWithBuffLayerAndTrap", setSkillParam)
end
