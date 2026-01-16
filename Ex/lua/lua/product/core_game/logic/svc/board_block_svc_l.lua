require("board_svc_l")
---判断pos位置阻挡了blockFlag指示的阻挡类型： 带体型
function BoardServiceLogic:IsPosBlockByArea(pos, blockFlag, listArea, entityExcept)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local ret = false
    for i = 1, #listArea do
        local posWork = pos + listArea[i]
        if utilDataSvc:IsPosBlock(posWork, blockFlag) then
            if not entityExcept then
                return true
            end
            local entityMonster = utilDataSvc:GetMonsterAtPos(posWork)
            if not entityMonster or entityMonster ~= entityExcept then
                return true
            end
            local entityTrap = utilDataSvc:GetTrapsAtPos(posWork)
            if #entityTrap == 0 or table.icontains(entityTrap, entityExcept) then
                return true
            end
        end
    end
    return false
end

--region Block
---@param pos Vector2
---@param blockFlag BlockFlag
---pos位置是否阻挡了blockFlag指示的阻挡类型
function BoardServiceLogic:IsPosBlock(pos, blockFlag)
    if not pos then
        return false
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(pos) then
        return true --棋盘外的位置一律阻挡
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end

---@return PieceBlockData
function BoardServiceLogic:FindBlockByPos(pos)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cmptBoard = boardEntity:Board()
    return cmptBoard:FindBlockByPos(pos)
end

---根据Cfg.cfg_block的ID获取阻挡信息
function BoardServiceLogic:GetBlockFlagByBlockId(blockId)
    if self._blockDict then --缓存
        if self._blockDict[blockId] then
            return self._blockDict[blockId]
        end
    else
        self._blockDict = {}
    end
    local cfgv = Cfg.cfg_block[blockId]
    if cfgv then
        local b = 0
        for _, value in ipairs(cfgv.BlockFlag) do
            b = b | GetBlockFlagByValue(value)
        end
        self._blockDict[blockId] = b
        return b
    else
        Log.fatal("### no block id in cfg_block. blockId=", blockId)
    end
    return 0
end

function BoardServiceLogic:IsPosExistNegtiveBlock(pos)
    local block = self:FindBlockByPos(pos)
    return block:IsExistNegative()
end

---@param e Entity
---@param posOld Vector2
function BoardServiceLogic:RemoveEntityBlockFlag(e, posOld)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea = e:BodyArea():GetArea()
    local blockFlag = self:GetBlockFlag(e)
    for _, area in ipairs(bodyArea) do
        self:RemovePosBlock(e, posOld + area, blockFlag)
    end
    return bodyArea, blockFlag
end

---移除pos位置的blockFlag类型的Block
---@param blockFlag BlockFlag
function BoardServiceLogic:RemovePosBlock(e, pos, blockFlag)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(pos) then
        return
    end
    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if nil == pieceBlock then
        return
    end

    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end

    pieceBlock:DelBlock(e:GetID(), blockFlag)
    local boardCmpt = self._world:GetBoardEntity():Board()
    boardCmpt:RemovePieceEntity(pos, e)
end

---@param e Entity
---@param posOld Vector2
---@param posNew Vector2
function BoardServiceLogic:UpdateEntityBlockFlag(e, posOld, posNew)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea, blockFlag = self:RemoveEntityBlockFlag(e, posOld)
    for _, area in ipairs(bodyArea) do
        self:SetPosBlock(e, posNew + area, blockFlag)
    end
end

---更新目标entity的block为指定的flag
---@param e Entity
---@param pos Vector2
function BoardServiceLogic:SetEntityBlockFlag(e, pos, blockFlag)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea = e:BodyArea():GetArea()
    for _, area in ipairs(bodyArea) do
        self:SetPosBlock(e, pos + area, blockFlag)
    end
end

---给pos位置设置blockFlag类型的Block
function BoardServiceLogic:SetPosBlock(entity, pos, blockFlag)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(pos) then
        return
    end

    --记录格子上的entity
    local boardCmpt = self._world:GetBoardEntity():Board()
    boardCmpt:AddPieceEntity(pos, entity)

    ---@type PieceBlockData
    local pieceBlock = self:FindBlockByPos(pos)
    if pieceBlock == nil then
        return
    end
    blockFlag = blockFlag or self:GetBlockFlag(entity)
    pieceBlock:AddBlock(entity:GetID(), blockFlag)
end

---@param e Entity
function BoardServiceLogic:GetBlockFlag(e)
    if e:HasGhost() then
        local ownerId = e:Ghost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetBlockFlag(eOwner)
        end
        Log.fatal("### Ghost has not owner.", e:GridLocation() and e:GridLocation().Position, ownerId)
        return 0
    end
    if e:HasGuideGhost() then
        local ownerId = e:GuideGhost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetBlockFlag(eOwner)
        end
        Log.fatal("### Guide Ghost has not owner.", e:GridLocation() and e:GridLocation().Position, ownerId)
        return 0
    end
    if e:HasBlockFlag() then
        return e:BlockFlag():GetBlockFlag()
    end
    Log.fatal("### RemoveEntityBlockFlag new entity type.", e:EntityType().Value)
    return 0
end

---@param blockFlag BlockFlag
---根据Block标记查找有这个标记的位置列表
function BoardServiceLogic:GetPosListByFlag(blockFlag)
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local cBoard = boardEntity:Board()
    return cBoard:GetPosListByFlag(blockFlag)
end
---@param monsterEntity Entity
---@param blockFlag BlockFlag
function BoardServiceLogic:IsMonsterPosBlock(monsterEntity, newPos, blockFlag)
    if not monsterEntity or not monsterEntity:GetID() then
        return false
    end
    ---@type BodyAreaComponent
    local areaCmpt = monsterEntity:BodyArea()
    local areaList = areaCmpt:GetArea()
    return self:IsPosBlockByArea(newPos, blockFlag, areaList)
end
