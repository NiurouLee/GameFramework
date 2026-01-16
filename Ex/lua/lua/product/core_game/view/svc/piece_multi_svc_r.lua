--[[------------------------------------------------------------------------------------------
    PieceMultiServiceRender 格子相关Service 
]] --------------------------------------------------------------------------------------------
_class("PieceMultiServiceRender", Object)
---@class PieceMultiServiceRender:Object
PieceMultiServiceRender = PieceMultiServiceRender

function PieceMultiServiceRender:Constructor(world)
    ---@type MainWorld
    self._world = world

    self._multiBoard = {}

    ---@type table<number, PieceAnimationData>
    self._pieceAnimData = {}
    self._pieceAnimData[PieceEffectType.Normal] = PieceAnimationData:New()
    self._pieceAnimData[PieceEffectType.Prism] = PrismPieceAnimationData:New()

    ---通过代码使用的动画名称
    self._animNameNormal = "Normal"
    self._animNameDark = "Dark"
end

function PieceMultiServiceRender:GetCurBoard(boardIndex)
    if not self._multiBoard then
        self._multiBoard = {}
    end
    if not self._multiBoard[boardIndex] then
        self._multiBoard[boardIndex] = {}
    end

    local curBoard = self._multiBoard[boardIndex]
    return curBoard
end

function PieceMultiServiceRender:GetCurBoardPieceEffect(boardIndex)
    local curBoard = self:GetCurBoard(boardIndex)
    if not curBoard._pieceEffect then
        curBoard._pieceEffect = {}
    end
    return curBoard._pieceEffect
end

function PieceMultiServiceRender:GetCurBoardPieceAnim(boardIndex)
    local curBoard = self:GetCurBoard(boardIndex)
    if not curBoard._pieceAnim then
        curBoard._pieceAnim = {}
    end
    return curBoard._pieceAnim
end

function PieceMultiServiceRender:InitPieceAnim(boardIndex)
    local pieceEffect = self:GetCurBoardPieceEffect(boardIndex)
    local pieceAnim = self:GetCurBoardPieceAnim(boardIndex)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieces = utilData:GetReplicaBoardPieces(boardIndex)
    for x, row in pairs(pieces) do
        for y, grid in pairs(row) do
            if not pieceAnim[x] then
                pieceEffect[x] = {}
                pieceAnim[x] = {}
            end
            pieceAnim[x][y] = self._animNameNormal
        end
    end
end

---@return Entity
function PieceMultiServiceRender:FindPieceEntity(boardIndex, pos)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderMultiBoardComponent
    local renderMultiBoardCmpt = renderBoardEntity:RenderMultiBoard()
    return renderMultiBoardCmpt:GetGridRenderEntity(boardIndex, pos)
end

---@param effectType  PieceEffectType
function PieceMultiServiceRender:SetPieceRenderEffect(boardIndex, pos, effectType)
    local pieceEffect = self:GetCurBoardPieceEffect(boardIndex)
    if pieceEffect[pos.x][pos.y] == effectType then
        return
    end

    pieceEffect[pos.x][pos.y] = effectType
    self:ResetPieceAnimation(boardIndex, pos)
end

function PieceMultiServiceRender:SetPieceAnimUp(boardIndex, pos)
    self:SetPieceAnimation(boardIndex, pos, "Up")
end

function PieceMultiServiceRender:SetPieceAnimDown(boardIndex, pos)
    self:SetPieceAnimation(boardIndex, pos, "Down")
end

function PieceMultiServiceRender:SetPieceAnimation(boardIndex, pos, anim)
    local pieceAnim = self:GetCurBoardPieceAnim(boardIndex)
    local col = pieceAnim[pos.x]
    if not col then
        Log.fatal("###  no pos.x in _pieceAnim. pos=", pos, " ", Log.traceback())
        return
    end
    local curAnim = col[pos.y]
    if curAnim == anim then
        return
    end

    pieceAnim[pos.x][pos.y] = anim

    local e = self:FindPieceEntity(boardIndex, pos)
    if e ~= nil then
        --e:SetAnimatorControllerBools(self:GetPieceStatusTable(anim))
        self:_PlayGridAnimation(boardIndex, e, anim)
    else
        --Log.fatal("grid error,can not find grid", pos, Log.traceback())
    end
end

---@param pos Vector2
function PieceMultiServiceRender:ResetPieceAnimation(boardIndex, pos)
    local pieceAnim = self:GetCurBoardPieceAnim(boardIndex)
    local curAnim = pieceAnim[pos.x][pos.y]

    local e = self:FindPieceEntity(boardIndex, pos)
    if e and curAnim then
        self:_PlayGridAnimation(boardIndex, e, curAnim)
    end
end

function PieceMultiServiceRender:GetPieceAnimation(boardIndex, pos)
    local pieceAnim = self:GetCurBoardPieceAnim(boardIndex)
    if not pieceAnim[pos.x] then
        return
    end
    local curAnim = pieceAnim[pos.x][pos.y]
    return curAnim
end

---@param e Entity 格子
---@param anim string 动画名称
---@param ... table 变长的动画列表
function PieceMultiServiceRender:_PlayGridAnimation(boardIndex, e, anim, ...)
    local animList = {}
    animList[#animList + 1] = self:GetAnimResName(boardIndex, e, anim)

    local animArgs = {...}
    if #animArgs > 0 then
        for _, v in ipairs(animArgs) do
            animList[#animList + 1] = self:GetAnimResName(boardIndex, e, v)
        end
    end

    ---@type PieceServiceRender
    local pieceService = self._world:GetService("Piece")
    pieceService:_PlayPieceU3DAnimation(animList, e)
end

function PieceMultiServiceRender:GetEffAnimTableData(boardIndex, e)
    local pos = e:GetGridPosition()
    local pieceEffect = self:GetCurBoardPieceEffect(boardIndex)
    local curEff = pieceEffect[pos.x][pos.y] or PieceEffectType.Normal
    local effAnimTable = self._pieceAnimData[curEff]
    return effAnimTable
end

---@param e Entity
---@param anim string
function PieceMultiServiceRender:GetAnimResName(boardIndex, e, anim)
    local effAnimTable = self:GetEffAnimTableData(boardIndex, e)

    local animResName = effAnimTable:GetAnimationName(anim)
    if not animResName then
        Log.fatal("不存在" .. anim .. "对应的格子动画资源！格子位置：" .. tostring(anim) .. " 格子特效类型：" .. " boardIndex：" .. boardIndex)
    end
    return animResName
end
