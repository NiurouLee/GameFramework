--[[------------------------------------------------------------------------------------------
    PreviewChainPathComponent : 玩家划线过程中的组件，属于预览模块
]]--------------------------------------------------------------------------------------------


_class( "PreviewChainPathComponent", Object )
---@class PreviewChainPathComponent: Object
PreviewChainPathComponent =PreviewChainPathComponent

function PreviewChainPathComponent:Constructor(chainPath, elementType, lastElementType)
    self._chainPath = chainPath or {}
    self._elementType = elementType or PieceType.None
    self._lastElementType = lastElementType or PieceType.None
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
function PreviewChainPathComponent:GetPreviewChainPath()
    return self._chainPath
end

function PreviewChainPathComponent:GetPreviewPieceType()
    return self._elementType
end

function PreviewChainPathComponent:SetPreviewChainPath(chainPath, elementType)
    self._chainPath = chainPath
    self._elementType = elementType

    if chainPath then
        self._chainNum = #chainPath - 1
    else
        self._chainNum = 0
    end
end

function PreviewChainPathComponent:GetPreviewChainNum()
    return self._chainNum
end

function PreviewChainPathComponent:GetPreviewChainTotalCount()
    return #self._chainPath
end

function PreviewChainPathComponent:ClearPreviewChainPath()
    self._chainPath = {}

    self._firstElementType = nil
    self._firstElementIndex = -1
end

--------------------------------------------------------------------------------------------
---每次链接新格子后搞一下最后一个格子周边可连接格子的感应区半径
function PreviewChainPathComponent:SetGridRadius(nearbyGridRadius)
    self._nearbyGridRadius = nearbyGridRadius
end

function PreviewChainPathComponent:GetGridRadius(gridPos)
    for k, v in pairs(self._nearbyGridRadius) do
        if k == gridPos then
            return v
        end
    end
    return GridRadiusType.Default
end

function PreviewChainPathComponent:GetMoveBack()
    return self._bMoveBack
end

function PreviewChainPathComponent:SetMoveBack(bMoveBack)
    self._bMoveBack = bMoveBack
end

---设置第一个颜色类型，非万色
function PreviewChainPathComponent:SetFirstElementData(elementType,index)
    self._firstElementType = elementType
    self._firstElementIndex = index
end

function PreviewChainPathComponent:GetFirstElementData()
    return self._firstElementType,self._firstElementIndex
end
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]--------------------------------------------------------------------------------------------
---@return PreviewChainPathComponent
function Entity:PreviewChainPath()
    return self:GetComponent(self.WEComponentsEnum.PreviewChainPath)
end


function Entity:HasPreviewChainPath()
    return self:HasComponent(self.WEComponentsEnum.PreviewChainPath)
end


function Entity:AddPreviewChainPath()
    local index = self.WEComponentsEnum.PreviewChainPath;
    local component = PreviewChainPathComponent:New()
    self:AddComponent(index, component)
end


function Entity:ReplacePreviewChainPath(chainPath, elementType, lastElementType)
    local index = self.WEComponentsEnum.PreviewChainPath;
    local component = PreviewChainPathComponent:New(chainPath, elementType, lastElementType)
    self:ReplaceComponent(index, component)

    --Log.fatal("UpdatePath----elemType:",elementType," laseElemType:",lastElementType,Log.traceback())
end


function Entity:RemovePreviewChainPath()
    if self:HasPreviewChainPath() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewChainPath)
    end
end