--[[------------------------------------------------------------------------------------------
    BodyAreaComponent : 对象体积占的格子数组件
]] --------------------------------------------------------------------------------------------

_class("BodyAreaComponent", Object)
---@class BodyAreaComponent: Object
BodyAreaComponent = BodyAreaComponent

---@param area Vector2[]
function BodyAreaComponent:Constructor(area)
    self._area = area
end
---不替换组件 只是重新设置
function BodyAreaComponent:SetArea(area)
    self._area = area
end
function BodyAreaComponent:GetArea()
    return self._area
end
---返回body占地面积：格子数量   2019-11-06韩玉信添加
function BodyAreaComponent:GetAreaCount()
    return #self._area
end

---预览时候的身形(为了解决 实际1格子的怪物，点周围10个格子都可以选中这个怪物的预览)
function BodyAreaComponent:SetPreviewArea(previewArea)
    self._previewArea = previewArea
end
---预览时候的身形
function BodyAreaComponent:GetPreviewArea()
    return self._previewArea
end

--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return BodyAreaComponent
function Entity:BodyArea()
    return self:GetComponent(self.WEComponentsEnum.BodyArea)
end

function Entity:HasBodyArea()
    return self:HasComponent(self.WEComponentsEnum.BodyArea)
end

function Entity:AddBodyArea(area)
    local index = self.WEComponentsEnum.BodyArea
    local component = BodyAreaComponent:New(area)
    self:AddComponent(index, component)
end

function Entity:ReplaceBodyArea(area)
    local index = self.WEComponentsEnum.BodyArea
    local component = BodyAreaComponent:New(area)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveBodyArea()
    if self:HasBodyArea() then
        self:RemoveComponent(self.WEComponentsEnum.BodyArea)
    end
end
