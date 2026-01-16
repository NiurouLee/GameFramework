--[[------------------------------------------------------------------------------------------
    MonsterAreaOutLineComponent : 技能范围
]] --------------------------------------------------------------------------------------------


_class("MonsterAreaOutLineComponent", Object)
---@class  MonsterAreaOutLineComponent: Object
MonsterAreaOutLineComponent = MonsterAreaOutLineComponent

function MonsterAreaOutLineComponent:Constructor()
	self._renderEntityIDList={}
end

function MonsterAreaOutLineComponent:AddEntityID(entityID)
	table.insert(self._renderEntityIDList,entityID)
end

function MonsterAreaOutLineComponent:ClearEntityIDList()
	self._renderEntityIDList = {}
end

function MonsterAreaOutLineComponent:GetEntityIDList()
	return self._renderEntityIDList
end


--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return MonsterAreaOutLineComponent
function Entity:MonsterAreaOutLineComponent()
	return self:GetComponent(self.WEComponentsEnum.MonsterAreaOutLineComponent)
end

function Entity:HasMonsterAreaOutLineComponent()
	return self:HasComponent(self.WEComponentsEnum.MonsterAreaOutLineComponent)
end

function Entity:AddMonsterAreaOutLineComponent()
	local index = self.WEComponentsEnum.MonsterAreaOutLineComponent
	local component = MonsterAreaOutLineComponent:New()
	self:AddComponent(index, component)
end

function Entity:ReplaceMonsterAreaOutLineComponent()
	local index = self.WEComponentsEnum.MonsterAreaOutLineComponent
	local component = MonsterAreaOutLineComponent:New()
	self:ReplaceComponent(index, component)
end

function Entity:RemoveMonsterAreaOutLineComponent()
	if self:HasMonsterAreaOutLineComponent() then
		self:RemoveComponent(self.WEComponentsEnum.MonsterAreaOutLineComponent)
	end
end
