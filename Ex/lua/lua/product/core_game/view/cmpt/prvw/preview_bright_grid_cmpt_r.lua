--[[------------------------------------------------------------------------------------------
    PreviewBrightGridComponent : 格子亮暗色组件
]] --------------------------------------------------------------------------------------------


_class("PreviewBrightGridComponent", Object)
---@class PreviewBrightGridComponent: Object
PreviewBrightGridComponent = PreviewBrightGridComponent

function PreviewBrightGridComponent:Constructor()
    self._originalGridElementTable = {}
    self._brightGridElementTable = {}
    self._maskGridElementTable = {}
end

function PreviewBrightGridComponent:ClearTempBrightGridList()
    self._originalGridElementTable = {}
    self._brightGridElementTable = {}
    self._maskGridElementTable = {}
end

---在亮暗色处理前备份格子颜色
function PreviewBrightGridComponent:BackupGridElement(originalTable)
    self._originalGridElementTable = table.cloneconf(originalTable)
end

---获取亮暗色之前的格子颜色
function PreviewBrightGridComponent:GetBackupGridElement()
    return self._originalGridElementTable
end

function PreviewBrightGridComponent:SetBrightGridTable(brightGridTable)
    self._brightGridElementTable = brightGridTable
end

function PreviewBrightGridComponent:SetMaskGridTable(maskGridTable)
    self._maskGridElementTable = maskGridTable
end

function PreviewBrightGridComponent:GetBrightGridTable()
    return self._brightGridElementTable
end



function PreviewBrightGridComponent:DoConvertBright(world, brightElementType)
    self._world = world

    local brightGridArray = self:GetBrightGridTable()

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieces = env:GetAllPieceType()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    for x, columnDic in pairs(pieces) do
        for y, curGridType in pairs(columnDic) do
            local curGridPos = Vector2(x, y)
            local isBright = table.icontains(brightGridArray, curGridPos)
            if isBright then
                pieceService:SetPieceAnimGray(curGridPos)
            else
                pieceService:SetPieceAnimBlack(curGridPos)
            end
        end
    end
end

function PreviewBrightGridComponent:DoConvertSliver(world)
    self._world = world

    local brightGridArray = self:GetBrightGridTable()

    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieces = env:GetAllPieceType()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    for x, columnDic in pairs(pieces) do
        for y, curGridType in pairs(columnDic) do
            local curGridPos = Vector2(x, y)
            local isBright = table.icontains(brightGridArray, curGridPos)
            local targetElementType = nil
            if isBright == true then
                pieceService:SetPieceAnimSliver(curGridPos)
            else
                pieceService:SetPieceAnimBlack(curGridPos)
            end
        end
    end
end

--将_brightGridElementTable中的格子转为brightElementType颜色(亮色)，而不将其余的格子转为暗色
function PreviewBrightGridComponent:DoConvertHight(world, brightElementType)
    self._world = world

    local brightGridArray = self:GetBrightGridTable()

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    for _, curGridPos in pairs(brightGridArray) do
        pieceService:SetPieceAnimGray(curGridPos)
    end
end

---压暗处理
function PreviewBrightGridComponent:DoConvertMask(world)
    self._world = world


    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    local pieces = env:GetAllPieceType()
    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")

    for x, columnDic in pairs(pieces) do
        for y, curGridType in pairs(columnDic) do
            local curGridPos = Vector2(x, y)
            pieceService:SetPieceAnimDark(curGridPos)
        end
    end
end

--------------------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] function Entity:PreviewBrightGrid()
    return self:GetComponent(self.WEComponentsEnum.PreviewBrightGrid)
end

function Entity:HasPreviewBrightGrid()
    return self:HasComponent(self.WEComponentsEnum.PreviewBrightGrid)
end

function Entity:AddPreviewBrightGrid()
    local index = self.WEComponentsEnum.PreviewBrightGrid
    local component = PreviewBrightGridComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePreviewBrightGrid()
    local index = self.WEComponentsEnum.PreviewBrightGrid
    local component = PreviewBrightGridComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemovePreviewBrightGrid()
    if self:HasPreviewBrightGrid() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewBrightGrid)
    end
end
