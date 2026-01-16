--[[------------------------------------------------------------------------------------------
    RenderBoardComponent : 挂在表现棋盘Entity身上，用于存放全局信息的组件
]] --------------------------------------------------------------------------------------------

_class("RenderBoardComponent", Object)
---@class RenderBoardComponent: Object
RenderBoardComponent = RenderBoardComponent

function RenderBoardComponent:Constructor()
    self._firstPetEntityID = -1

    self._gridEntityTable = {} --表现层的entity BW_WEMatchers.Piece
    ---@type UnityEngine.GameObject[]
    self._sceneGOs = {} --局内场景下暂存的结点

    ---局内使用的格子材质
    self._gridMaterialPath = ""

    ---局内网格线prefab的request
    self._brillantLineReq = nil
    ---横线列表
    self._hLineObjList = {}
    ---竖线列表
    self._vLineObjList = {}

    self._brillantGridLineExtendParam = 0.5

    self._dimensionClearPreviewTaskID = -1

    ---连线取消区域是否激活
    self._chainPathCancelAreaActive = false

    --【玩家连线阶段】格子颜色映射，key是被替换的颜色，value是替换后的颜色
    self._mapByPieceType = {}
    --【玩家连线阶段】格子颜色映射，key是坐标，valie是替换后的颜色
    self._mapByPosition = {}

    ---地板格子特殊材质特效【黑天使Boss场景内需在地板下播放玻璃体格子特效】
    self._gridEffectEntityIDTable = {}
    ---场景特效ID【黑天使Boss场景内切换场景后播放的场景特效】
    self._sceneEffectEntityID = nil

    --连线第一格视为某颜色时的特效相关
    self._mapPieceFirstChainPathEffectEntityID = nil
    self._mapPieceFirstChainPathEffectID = nil
    self._mapPieceFirstChainPathEffectOutAnim = nil

    --格子基准点可配置修改，默认是 BattleConst.BaseGridRenderPos
    self._baseGridRenderPos = BattleConst.BaseGridRenderPos
end
function RenderBoardComponent:Dispose()
    self._sceneGOs = {}
    self._brillantLineReq = nil
end

function RenderBoardComponent:GetFirstPetRenderEntityID()
    return self._firstPetEntityID
end

function RenderBoardComponent:SetFirstPetRenderEntityID(id)
    self._firstPetEntityID = id
end

function RenderBoardComponent:GetGridRenderEntityTable()
    return self._gridEntityTable
end

function RenderBoardComponent:GetGridRenderEntity(pos)
    if not pos or not self._gridEntityTable[pos.x] or not self._gridEntityTable[pos.x][pos.y] then
        return nil
    end
    return self._gridEntityTable[pos.x][pos.y]
end

function RenderBoardComponent:SetGridRenderEntityData(pos, gridEntity)
    if not self._gridEntityTable[pos.x] then
        self._gridEntityTable[pos.x] = {}
    end
    if not self._gridEntityTable[pos.x][pos.y] then
        self._gridEntityTable[pos.x][pos.y] = {}
    end
    self._gridEntityTable[pos.x][pos.y] = gridEntity
end

function RenderBoardComponent:RemoveGridRenderEntityData(pos)
    if not self._gridEntityTable[pos.x][pos.y] then
        self._gridEntityTable[pos.x][pos.y] = {}
    end
    self._gridEntityTable[pos.x][pos.y] = nil
end

function RenderBoardComponent:GetGridEffectEntityID(pos)
    if not pos or not self._gridEffectEntityIDTable[pos.x] or not self._gridEffectEntityIDTable[pos.x][pos.y] then
        return nil
    end
    return self._gridEffectEntityIDTable[pos.x][pos.y]
end

function RenderBoardComponent:SetGridEffectEntityID(pos, entityID)
    if not self._gridEffectEntityIDTable[pos.x] then
        self._gridEffectEntityIDTable[pos.x] = {}
    end
    if not self._gridEffectEntityIDTable[pos.x][pos.y] then
        self._gridEffectEntityIDTable[pos.x][pos.y] = {}
    end
    self._gridEffectEntityIDTable[pos.x][pos.y] = entityID
end

function RenderBoardComponent:RemoveGridEffectEntityID(pos)
    if self._gridEffectEntityIDTable[pos.x] and self._gridEffectEntityIDTable[pos.x][pos.y] then
        self._gridEffectEntityIDTable[pos.x][pos.y] = nil
    end
end

function RenderBoardComponent:GetSceneEffectEntityID()
    return self._sceneEffectEntityID
end

function RenderBoardComponent:SetSceneEffectEntityID(entityID)
    self._sceneEffectEntityID = entityID
end

--region SceneGO
---@param name string GameObject 名
function RenderBoardComponent:GetSceneGO(name)
    return self._sceneGOs[name]
end
---@param go UnityEngine.GameObject
function RenderBoardComponent:SetSceneGO(go)
    if go then
        self._sceneGOs[go.name] = go
    end
end
--endregion

function RenderBoardComponent:GetGridMaterialPath()
    return self._gridMaterialPath
end

function RenderBoardComponent:SetGridMaterialPath(matPath)
    self._gridMaterialPath = matPath
end

function RenderBoardComponent:SetBrillantGridLineExtendParam(len)
    self._brillantGridLineExtendParam = len
end

function RenderBoardComponent:GetBrillantGridLineExtendParam()
    return self._brillantGridLineExtendParam
end

function RenderBoardComponent:GetBrillantGridObj()
    if self._brillantLineReq == nil then
        return nil
    end

    return self._brillantLineReq.Obj
end

function RenderBoardComponent:SetBrillantGridRequest(req)
    self._brillantLineReq = req
end

function RenderBoardComponent:SetBrillantGridLineList(h, v)
    self._hLineObjList = h
    self._vLineObjList = v
end

function RenderBoardComponent:GetBrillantGridLineList()
    return self._hLineObjList, self._vLineObjList
end

function RenderBoardComponent:GetDimensionClearPreviewTaskID()
    return self._dimensionClearPreviewTaskID
end

function RenderBoardComponent:SetDimensionClearPreviewTaskID(id)
    self._dimensionClearPreviewTaskID = id
end

-------连线区域激活
function RenderBoardComponent:GetChainPathCancelAreaActive()
    return self._chainPathCancelAreaActive
end

function RenderBoardComponent:SetChainPathCancelAreaActive(isActive)
    self._chainPathCancelAreaActive = isActive
end

function RenderBoardComponent:GetMapPieceFirstChainPathEffectEntityID()
    return self._mapPieceFirstChainPathEffectEntityID
end

function RenderBoardComponent:SetMapPieceFirstChainPathEffectEntityID(entityID)
    self._mapPieceFirstChainPathEffectEntityID = entityID
end
function RenderBoardComponent:GetMapPieceFirstChainPathEffectID()
    return self._mapPieceFirstChainPathEffectID
end

function RenderBoardComponent:SetMapPieceFirstChainPathEffectID(effectID)
    self._mapPieceFirstChainPathEffectID = effectID
end
function RenderBoardComponent:GetMapPieceFirstChainPathEffectOutAnim()
    return self._mapPieceFirstChainPathEffectOutAnim
end

function RenderBoardComponent:SetMapPieceFirstChainPathEffectOutAnim(outAnim)
    self._mapPieceFirstChainPathEffectOutAnim = outAnim
end
function RenderBoardComponent:SetBaseGridRenderPos(renderPos)
    self._baseGridRenderPos = renderPos
end
function RenderBoardComponent:GetBaseGridRenderPos()
    return self._baseGridRenderPos
end

------------------------------------------------------------------------------------------
---@return RenderBoardComponent
function Entity:RenderBoard()
    return self:GetComponent(self.WEComponentsEnum.RenderBoard)
end

function Entity:HasRenderBoard()
    return self:HasComponent(self.WEComponentsEnum.RenderBoard)
end

function Entity:AddRenderBoard()
    local index = self.WEComponentsEnum.RenderBoard
    local component = RenderBoardComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceRenderBoard()
    local index = self.WEComponentsEnum.RenderBoard
    local component = RenderBoardComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveRenderBoard()
    if self:HasRenderBoard() then
        self:RemoveComponent(self.WEComponentsEnum.RenderBoard)
    end
end
