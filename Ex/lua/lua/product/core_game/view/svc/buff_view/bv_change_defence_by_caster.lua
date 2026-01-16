--[[
    加防御表现
]]
---@class BuffViewChangeDefenceByCaster:BuffViewBase
_class("BuffViewChangeDefenceByCaster", BuffViewBase)
BuffViewChangeDefenceByCaster = BuffViewChangeDefenceByCaster

function BuffViewChangeDefenceByCaster:PlayView(TT)
	---@type Entity
	local entity = self._entity
	if entity:HasTeam() then
		entity = entity:GetTeamLeaderPetEntity()
	end
	
	if entity:MaterialAnimationComponent() then 
		entity:MaterialAnimationComponent():PlayDefup()
	end

	local cfg = self._viewInstance:BuffConfigData()
	local effectID = cfg:GetExecEffectID()
	if effectID then
		self._world:GetService("Effect"):CreateEffect(effectID, self._entity)
	end

	---@type BuffResultChangeDefenceByCaster
	local result = self._buffResult
	local casterID = result:GetEntityID()
	if result:ShowLight() and casterID then
		local casterEntity = self._world:GetEntityByID(casterID)
		GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, casterEntity:PetPstID():GetPstID(), true)
	end
	self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end

--[[
    卸[加防御]表现
]]
---@class BuffViewUndoChangeDefenceByCaster:BuffViewBase
_class("BuffViewUndoChangeDefenceByCaster", BuffViewBase)
BuffViewUndoChangeDefenceByCaster = BuffViewUndoChangeDefenceByCaster

function BuffViewUndoChangeDefenceByCaster:PlayView(TT)
	---@type BuffResultUndoChangeDefenceByCaster
	local result = self._buffResult
	local black = result:ShowBlack()
	local casterID = result:GetEntityID()
	if black and casterID then
		local casterEntity=self._world:GetEntityByID(casterID)
		GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivatePassive, result.casterEntity:PetPstID():GetPstID(), false)
	end
	self._world:EventDispatcher():Dispatch(GameEventType.ChangeBuff)
end
