--[[
    只用作星灵提升防御，如果后续需要小怪提升防御需另加在后面
]]
--设置
_class("BuffLogicSetIncreaseAddDefense", BuffLogicBase)
---@class BuffLogicSetIncreaseAddDefense:BuffLogicBase
BuffLogicSetIncreaseAddDefense = BuffLogicSetIncreaseAddDefense

function BuffLogicSetIncreaseAddDefense:Constructor(buffInstance, logicParam)
    self._increaseRate = logicParam.increaseRate or 1
    self._referTo = logicParam.referTo
	---@type Entity
    self._AddedEntity = self._entity

    self._headOut = logicParam.headOut ~= nil
end

function BuffLogicSetIncreaseAddDefense:DoLogic()
    ---@type PetPstIDComponent
    local pstIDCmpt = self._AddedEntity:PetPstID()
    local pstID = pstIDCmpt:GetPstID()

    local petData = self._world.BW_WorldInfo:GetPetData(pstID)
    local baseValue = 0
    if self._referTo == "attack" then
        baseValue = petData:GetPetAttack()
    elseif self._referTo == "defence" then
        baseValue = petData:GetPetDefence()
    end
    if baseValue == 0 then
        Log.fatal("Add 0 Defence check config")
    end
    local increaseValue = baseValue * self._increaseRate
    self._buffLogicService:ChangeBaseDefence(self._AddedEntity, self:GetBuffSeq(),ModifyBaseDefenceType.DefenceConstantFix,increaseValue)


	if self._AddedEntity:HasPetPstID() then
        local teamEntity = self._AddedEntity:Pet():GetOwnerTeamEntity()
		self:UpdateTeamDefenceLogic(teamEntity)
	end

    if self._headOut then
       return true
    end
end

--取消
_class("BuffLogicResetIncreaseAddDefense", BuffLogicBase)
BuffLogicResetIncreaseAddDefense = BuffLogicResetIncreaseAddDefense

function BuffLogicResetIncreaseAddDefense:Constructor(buffInstance, logicParam)
    self._AddedEntity = self._entity
    self._black = logicParam.black ~= nil
end

function BuffLogicResetIncreaseAddDefense:DoLogic()
    local e = self._AddedEntity
    self._buffLogicService:RemoveBaseDefence(e, self:GetBuffSeq(),ModifyBaseDefenceType.DefenceConstantFix)
    if self._black then
        return true
    end
	if self._AddedEntity:HasPetPstID() then
        local teamEntity = self._AddedEntity:Pet():GetOwnerTeamEntity()
		self:UpdateTeamDefenceLogic(teamEntity)
	end
end
