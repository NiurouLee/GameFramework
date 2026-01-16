--[[------------------------------------------------------------------------------------------
    RenderAttributesComponent 表现层没有动态修改数据的需求，只要接收逻辑层的结果就行了
]] --------------------------------------------------------------------------------------------

_class("RenderAttributesComponent", Object)
---@class RenderAttributesComponent:Object
RenderAttributesComponent = RenderAttributesComponent
function RenderAttributesComponent:Constructor()
    self._attrValues = {}
end

function RenderAttributesComponent:SetAttribute(attrName, value)
    self._attrValues[attrName] = value
end

function RenderAttributesComponent:GetAttribute(attrName)
	if attrName then
		return self._attrValues[attrName]
	end
	return nil
end

---@return RenderAttributesComponent
function Entity:RenderAttributes()
    return self:GetComponent(self.WEComponentsEnum.RenderAttributes)
end

function Entity:HasRenderAttributes()
    return self:HasComponent(self.WEComponentsEnum.RenderAttributes)
end

function Entity:AddRenderAttributes()
    local index = self.WEComponentsEnum.RenderAttributes
    local component = RenderAttributesComponent:New()
    self:AddComponent(index, component)
end

function Entity:RemoveRenderAttributes()
    if self:HasRenderAttributes() then
        self:RemoveComponent(self.WEComponentsEnum.RenderAttributes)
    end
end

function Entity:ReplaceRenderAttributes(component)
    self:ReplaceComponent(self.WEComponentsEnum.RenderAttributes, component)
end
