--[[
    设置主动技不能使用 --sp巴顿 主动技为能量体系，但释放后即使能量充足也需要禁用
]]
require('buff_logic_base')

_class("BuffLogicSetActiveSkillCanNotReady", BuffLogicBase)
---@class BuffLogicSetActiveSkillCanNotReady : BuffLogicBase
BuffLogicSetActiveSkillCanNotReady = BuffLogicSetActiveSkillCanNotReady
function BuffLogicSetActiveSkillCanNotReady:Constructor(buffInstance, logicParam)
	self._extraSkillID = logicParam.extraSkillID--指定附加技ID
	self._reasonTips = logicParam.reasonTips--无法发动 点ui时的特殊提示 枚举 BattleUIActiveSkillCannotCastReason
end
function BuffLogicSetActiveSkillCanNotReady:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    if self._extraSkillID then
        blsvc:ChangePetActiveSkillReady(e, 0,self._extraSkillID)
        blsvc:BuffSetPetExtraActiveSkillCanNotReady(e,self._extraSkillID,true,self._reasonTips)
    else
        blsvc:ChangePetActiveSkillReady(e, 0)
        blsvc:BuffSetPetActiveSkillCanNotReady(e,true,self._reasonTips)
    end
    return BuffResultSetActiveSkillCanNotReady:New(self._buffInstance:BuffSeq(), true,false,self._extraSkillID)
end

_class("BuffLogicResetActiveSkillCanNotReady", BuffLogicBase)
---@class BuffLogicResetActiveSkillCanNotReady : BuffLogicBase
BuffLogicResetActiveSkillCanNotReady = BuffLogicResetActiveSkillCanNotReady
function BuffLogicResetActiveSkillCanNotReady:Constructor(buffInstance, logicParam)
	self._extraSkillID = logicParam.extraSkillID--指定附加技ID
end
function BuffLogicResetActiveSkillCanNotReady:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    if self._extraSkillID then
        blsvc:BuffSetPetExtraActiveSkillCanNotReady(e,self._extraSkillID,false)
    else
        blsvc:BuffSetPetActiveSkillCanNotReady(e,false)
    end
    local shouldReady = false
    local localSkillID = e:SkillInfo():GetActiveSkillID()
    if not localSkillID then
        local petPstIDComponent = e:PetPstID()
        local petPstID = petPstIDComponent:GetPstID()
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        localSkillID = petData:GetPetActiveSkill()
    end
    if self._extraSkillID then
        localSkillID = self._extraSkillID
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(localSkillID)

    ---@type AttributesComponent
    local attributesComponent = e:Attributes()

    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        local currentPower = attributesComponent:GetAttribute("LegendPower")
        local minCost = blsvc:CalcMinCostByExtraParam(e,localSkillID)
        if currentPower >= minCost then
            shouldReady = true
        end
    else
        local currentPower = utilData:GetPetPowerAttr(e,localSkillID)
        if currentPower <= 0 then
            shouldReady = true
        end
    end
    local ready = 0
    if shouldReady then
        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        ready = blsvc:ChangePetActiveSkillReady(e, 1,localSkillID)
    end
    return BuffResultSetActiveSkillCanNotReady:New(self._buffInstance:BuffSeq(), false,ready==1,self._extraSkillID)
end
