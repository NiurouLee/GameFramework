--[[------------------------------------------------------------------------------------------
    InnerStoryTipsComponent 
]] --------------------------------------------------------------------------------------------


_class("InnerStoryTipsComponent", Object)
---@class InnerStoryTipsComponent: Object
InnerStoryTipsComponent = InnerStoryTipsComponent

function InnerStoryTipsComponent:Constructor(entityID,offset,tipsID)
	self._entityID = entityID
	self._offSet = offset
	self._tipsID = tipsID
end

function InnerStoryTipsComponent:SetParam(entityID,offset,tipsID)
	self._entityID = entityID
	self._offSet = offset
	self._tipsID = tipsID
end

function InnerStoryTipsComponent:GetEntityID()
	return self._entityID
end
function InnerStoryTipsComponent:GetOffset()
	return self._offSet
end
function InnerStoryTipsComponent:GetTipsID()
	return self._tipsID
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] function Entity:InnerStoryTipsComponent()
	return self:GetComponent(self.WEComponentsEnum.InnerStoryTips)
end

function Entity:HasInnerStoryTipsComponent()
	return self:HasComponent(self.WEComponentsEnum.InnerStoryTips)
end

function Entity:AddInnerStoryTipsComponent(entityID,offset,tipsID)
	local index = self.WEComponentsEnum.InnerStoryTips
	local component = InnerStoryTipsComponent:New(entityID,offset,tipsID)
	self:AddComponent(index, component)
end

function Entity:ReplaceInnerStoryTipsComponent(entityID,offset,tipsID)
	local storyTips = self:InnerStoryTipsComponent()
	if (storyTips == nil) then
		storyTips = InnerStoryTipsComponent:New(entityID,offset,tipsID)
	else
		storyTips:SetParam(entityID,offset,tipsID)
	end

	self:ReplaceComponent(self.WEComponentsEnum.InnerStoryTips, storyTips)
end

function Entity:RemoveInnerStoryTipsComponent()
	if self:HasInnerStoryTipsComponent() then
		self:RemoveComponent(self.WEComponentsEnum.InnerStoryTips)
	end
end

---已经展示过的InnerStory Tips和Banner 数据

_class("InnerStoryShowUpData", Object)
---@class InnerStoryShowUpData: Object
InnerStoryShowUpData = InnerStoryShowUpData

function InnerStoryShowUpData:Constructor(type,showType,waveNum,roundNum)
	---是Banner还是Tips
	self._type = type
	---出现时机种类
	self._showType = showType
	---波次数
	self._waveNum = waveNum
	---回合数
	self._roundNum = roundNum
end

function InnerStoryShowUpData:IsMe(type,showType,waveNum,roundNum)
	return self._type == type and self._showType == showType and self._waveNum == waveNum and self._roundNum == roundNum
end