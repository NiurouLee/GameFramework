--[[------------------------------------------------------------------------------------------
    PreviewLinkLineComponent : 主动技预览阶段，玩家划线过程的组件
]]
--------------------------------------------------------------------------------------------


_class("PreviewLinkLineComponent", Object)
---@class PreviewLinkLineComponent: Object
PreviewLinkLineComponent = PreviewLinkLineComponent

function PreviewLinkLineComponent:Constructor(chainPath, elementType)
    self._chainPath = chainPath or {}
    self._elementType = elementType or PieceType.None
    self._chainNum = 0

    if #self._chainPath > 0 then
        self._chainNum = #self._chainPath - 1
    end

    ---@type table<Vector2,number>
    self._nearbyGridRadius = {}

    ---是否是回退
    self._bMoveBack = false

    ---第一个非万色格子的属性，这个可以支持双属性出战
    self._firstElementType = nil
    self._firstElementIndex = -1
end

---@return Vector2[]
function PreviewLinkLineComponent:GetPreviewChainPath()
    return self._chainPath
end

function PreviewLinkLineComponent:GetPreviewPieceType()
    return self._elementType
end

function PreviewLinkLineComponent:SetPreviewChainPath(chainPath, elementType)
    self._chainPath = chainPath
    self._elementType = elementType

    if chainPath then
        self._chainNum = #chainPath - 1
    else
        self._chainNum = 0
    end
end

function PreviewLinkLineComponent:GetPreviewChainNum()
    return self._chainNum
end

function PreviewLinkLineComponent:GetPreviewChainTotalCount()
    return #self._chainPath
end

function PreviewLinkLineComponent:ClearPreviewChainPath()
    self._chainPath = {}

    self._firstElementType = nil
    self._firstElementIndex = -1
end

--------------------------------------------------------------------------------------------
---每次链接新格子后搞一下最后一个格子周边可连接格子的感应区半径
function PreviewLinkLineComponent:SetGridRadius(nearbyGridRadius)
    self._nearbyGridRadius = nearbyGridRadius
end

function PreviewLinkLineComponent:GetGridRadius(gridPos)
    for k, v in pairs(self._nearbyGridRadius) do
        if k == gridPos then
            return v
        end
    end
    return GridRadiusType.Default
end

function PreviewLinkLineComponent:GetMoveBack()
    return self._bMoveBack
end

function PreviewLinkLineComponent:SetMoveBack(bMoveBack)
    self._bMoveBack = bMoveBack
end

---设置第一个颜色类型，非万色
function PreviewLinkLineComponent:SetFirstElementData(elementType, index)
    self._firstElementType = elementType
    self._firstElementIndex = index
end

function PreviewLinkLineComponent:GetFirstElementData()
    return self._firstElementType, self._firstElementIndex
end

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
--------------------------------------------------------------------------------------------
---@return PreviewLinkLineComponent
function Entity:PreviewLinkLine()
    return self:GetComponent(self.WEComponentsEnum.PreviewLinkLine)
end

function Entity:HasPreviewLinkLine()
    return self:HasComponent(self.WEComponentsEnum.PreviewLinkLine)
end

function Entity:AddPreviewLinkLine()
    local index = self.WEComponentsEnum.PreviewLinkLine;
    local component = PreviewLinkLineComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePreviewLinkLine(chainPath, elementType)
    local index = self.WEComponentsEnum.PreviewLinkLine;
    local component = PreviewLinkLineComponent:New(chainPath, elementType)
    self:ReplaceComponent(index, component)
end

function Entity:RemovePreviewLinkLine()
    if self:HasPreviewLinkLine() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewLinkLine)
    end
end
