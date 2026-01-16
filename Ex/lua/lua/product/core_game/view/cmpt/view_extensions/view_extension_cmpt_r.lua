--[[------------------------------------------------------------------------------------------
    ViewExtensionComponent : View组件的扩展Cmpt 显隐/材质数据等
]] --------------------------------------------------------------------------------------------

---@class ViewExtensionComponent: Object
_class("ViewExtensionComponent", Object)
ViewExtensionComponent = ViewExtensionComponent

function ViewExtensionComponent:Constructor(visible)
    self.Visible = visible
end ---@return ViewExtensionComponent
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensionensions
]] function Entity:ViewExtension()
    if self:HasTeam() then
        ---@type Entity
        local teamLeaderEntity = self:GetTeamLeaderPetEntity()
        return teamLeaderEntity:ViewExtension()
    else
        return self:GetComponent(self.WEComponentsEnum.ViewExtension)
    end
end

function Entity:HasViewExtension()
    return self:HasComponent(self.WEComponentsEnum.ViewExtension)
end

function Entity:SetViewVisible(visible)
    local index = self.WEComponentsEnum.ViewExtension
    ---@type ViewExtensionComponent
    local component = nil
    if self:HasViewExtension() then
        component = self:ViewExtension()
        component.Visible = visible
    else
        component = ViewExtensionComponent:New(visible)
        self:ReplaceComponent(index, component)
    end
    local world = self:GetOwnerWorld()
    ---@type RenderEntityService
    local renderEntitySvc = world:GetService("RenderEntity")
    if renderEntitySvc ~= nil then 
        renderEntitySvc:SetEntityVisible(self, visible)
    end
end
---通过设置高度达到隐藏的效果
function Entity:SetUpToVisible(visible)
	if not visible then
		self:SetLocationHeight(BattleConst.CacheHeight)
	else
		self:SetLocationHeight(0)
	end
end

function Entity:IsViewVisible()
    ---@type ViewExtensionComponent
    local viewExtensionCmpt = self:ViewExtension()
    if viewExtensionCmpt == nil then
        return false
    end

    return viewExtensionCmpt.Visible
end
