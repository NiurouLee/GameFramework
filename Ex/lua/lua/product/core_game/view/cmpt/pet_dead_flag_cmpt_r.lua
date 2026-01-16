--[[------------------------------------------------------------------------------------------
	PetDeadFlagComponent : 宠物表现死亡组件
]]--------------------------------------------------------------------------------------------

---@class PetDeadFlagComponent: Object
_class( "PetDeadFlagComponent", Object )

function PetDeadFlagComponent:Constructor()

end

-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function PetDeadFlagComponent:WEC_PostInitialize(owner)
	--ToDo WEC_PostInitialize
end

function PetDeadFlagComponent:WEC_PostRemoved()
	--Do WEC_PostRemoved
end

-- This:
--//////////////////////////////////////////////////////////


--[[------------------------------------------------------------------------------------------
	Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return PetDeadFlagComponent
function Entity:PetDeadFlag()
	return self:GetComponent(self.WEComponentsEnum.PetDeadFlag)
end


function Entity:HasPetDeadFlag()
	return self:HasComponent(self.WEComponentsEnum.PetDeadFlag)
end


function Entity:AddPetDeadFlag()
	local index = self.WEComponentsEnum.PetDeadFlag;
	local component = PetDeadFlagComponent:New()
	self:AddComponent(index, component)
end


function Entity:ReplacePetDeadFlag()
	local index = self.WEComponentsEnum.PetDeadFlag;
	local component = PetDeadFlagComponent:New()
	self:ReplaceComponent(index, component)
end


function Entity:RemovePetDeadFlag()
	if self:HasPetDeadFlag() then
		self:RemoveComponent(self.WEComponentsEnum.PetDeadFlag)
	end
end