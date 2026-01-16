--[[
    SealedCurse: 诅咒：无法上场，首发于诅魍（2000551?）
]]
require("br_sealed_curse")

_class("BuffLogicSetSealedCurse", BuffLogicBase)
---@class BuffLogicSetSealedCurse : BuffLogicBase
BuffLogicSetSealedCurse = BuffLogicSetSealedCurse

function BuffLogicSetSealedCurse:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.SealedCurse)
    return BuffResultSealedCurse:New(self._buffInstance:BuffSeq(), true)
end

_class("BuffLogicResetSealedCurse", BuffLogicBase)
BuffLogicResetSealedCurse = BuffLogicResetSealedCurse

function BuffLogicResetSealedCurse:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.SealedCurse)

    --MSG27123 因诅咒效果导致ready=0的光灵在当前回合诅咒卸载后，ready需设回1，否则验证时会报错
    local shouldReady = false

    local localSkillID = e:SkillInfo():GetActiveSkillID()
    if not localSkillID then
        local petPstIDComponent = e:PetPstID()
        local petPstID = petPstIDComponent:GetPstID()
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        localSkillID = petData:GetPetActiveSkill()
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID)

    ---@type AttributesComponent
    local attributesComponent = e:Attributes()

    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        local currentPower = attributesComponent:GetAttribute("LegendPower")
        if currentPower >= skillConfigData:GetSkillTriggerParam() then
            shouldReady = true
        end
    else
        local currentPower = attributesComponent:GetAttribute("Power")
        if currentPower <= 0 then
            shouldReady = true
        end
    end

    if shouldReady then
        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        blsvc:ChangePetActiveSkillReady(e, 1)
    end
    return BuffResultSealedCurse:New(self._buffInstance:BuffSeq(), false)
end
