--[[------------------------------------------------------------------------------------------
    PreviewEnvComponent : 预览环境组件
]] --------------------------------------------------------------------------------------------

_class("PreviewEnvComponent", Object)
---@class PreviewEnvComponent: Object
PreviewEnvComponent = PreviewEnvComponent

function PreviewEnvComponent:Constructor(world)
    self._world = world
    self:ResetPreviewEnv()
end

function PreviewEnvComponent:ResetPreviewEnv()
    self._previewTeamID = nil
    self._prismPieces = nil --记录棱镜格子
    self._prismEntityIDs = nil
    self._prismChangedPieces = {} --棱镜修改的格子
    self._pieceBlocks = nil --阻挡信息
    self._allPieceTable = nil --格子颜色pos索引
    self._pieceTypes = nil --格子颜色posIdx索引
    self._immuneHitbacks = nil --免疫击退的怪物ID
    self._pieceEntities = nil --格子上的entity索引
    self._needUpdateConnectPieces = false --标记需要更新联通区
    self._convertPlayerPosGridEffectEntityID = nil --为玩家脚下格子预览转色创建的特殊特效entityID
    self._convertPlayerPosHidePieceEntityID = nil -- 为玩家脚下格子预览转色时隐藏的脚下格子entityID
    self._monsterClickCount = 0
end

function PreviewEnvComponent:SetConvertPlayerPosGridEffectEntityID(id)
    self._convertPlayerPosGridEffectEntityID = id
end

function PreviewEnvComponent:GetConvertPlayerPosGridEffectEntityID()
    return self._convertPlayerPosGridEffectEntityID
end

function PreviewEnvComponent:ClearConvertPlayerPosGridEffectEntityID()
    self._convertPlayerPosGridEffectEntityID = nil
end

function PreviewEnvComponent:ResetPieceEntities(t)
    self._pieceEntities = t
end

function PreviewEnvComponent:ResetImmuneHitbacks(t)
    self._immuneHitbacks = t
end

function PreviewEnvComponent:ResetPieceTable(t)
    self._allPieceTable = t
end

function PreviewEnvComponent:ResetPieceTypes(t)
    self._pieceTypes = t
end

function PreviewEnvComponent:ResetPrismPieces(t)
    self._prismPieces = t
end

function PreviewEnvComponent:ResetPrismEntityIDs(t)
    self._prismEntityIDs = t
end

function PreviewEnvComponent:ResetPieceBlocks(t)
    self._pieceBlocks = t
end

function PreviewEnvComponent:IsImmuneHitback(e)
	if not self._immuneHitbacks then
		return false
	end
	return table.icontains(self._immuneHitbacks, e:GetID())
end

function PreviewEnvComponent:GetEntitiesAtPos(pos, filter)
    if not self._pieceEntities then
        return {}
    end
    local posIdx = Vector2.Pos2Index(pos)

    local es = self._pieceEntities[posIdx]
    if not es then
        return {}
    end
    local ret = {}
    if filter then
        for i, e in ipairs(es) do
            if filter(e) then
                ret[#ret + 1] = e
            end
        end
    else
        ret = es
    end
    return ret
end

function PreviewEnvComponent:GetPosBlockData(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._pieceBlocks[posIdx]
end

function PreviewEnvComponent:GetEntityBlockFlag(e)
    if e:HasGhost() then
        local ownerId = e:Ghost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetEntityBlockFlag(eOwner)
        end
    end
    if e:HasGuideGhost() then
        local ownerId = e:GuideGhost():GetOwnerID()
        local eOwner = self._world:GetEntityByID(ownerId)
        if eOwner then
            return self:GetEntityBlockFlag(eOwner)
        end
    end
    if e:HasPetPstID() then
        local team = e:Pet():GetOwnerTeamEntity()
        return self:GetEntityBlockFlag(team)
    end
    if e:HasBlockFlag() then
        return e:BlockFlag():GetBlockFlag()
    end
end

function PreviewEnvComponent:IsPosBlock(pos, blockFlag)
    if not pos then
        return false
    end
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    if not utilData:IsValidPiecePos(pos) then
        return true
    end
    if not blockFlag then
        return false
    end
    ---@type PieceBlockData
    local pieceBlock = self:GetPosBlockData(pos)
    if nil == pieceBlock then
        return true
    end
    return pieceBlock:CheckBlock(blockFlag)
end

function PreviewEnvComponent:AddEntityBlockFlag(e, pos)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea = e:BodyArea():GetArea()
    local blockFlag = self:GetEntityBlockFlag(e)
    for _, area in ipairs(bodyArea) do
        local blockData = self:GetPosBlockData(pos + area)
        blockData:AddBlock(e:GetID(), blockFlag)
    end
end

function PreviewEnvComponent:DelEntityBlockFlag(e, pos)
    if e:HasPetPstID() then
        e = e:Pet():GetOwnerTeamEntity()
    end
    local bodyArea = e:BodyArea():GetArea()
    for _, area in ipairs(bodyArea) do
        local blockData = self:GetPosBlockData(pos + area)
        if not blockData then
            Log.error("DelEntityBlockFlag() NOT find blockData!! pos=", pos, " area=", area)
        end
        if blockData then 
            blockData:DelBlock(e:GetID())
        end
    end
end

--判断当前位置是否是棱镜格子
---@param pos Vector2
function PreviewEnvComponent:IsPrismPiece(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismPieces[posIdx]
end

function PreviewEnvComponent:GetPrismEntityIDAtPos(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._prismEntityIDs[posIdx]
end

--一个格子可以被多个棱镜转色，第二个棱镜回退的时候还原的是转色后的格子颜色
--所以取格子颜色的时候应该从previewEnv里取，不能用逻辑颜色
--PreviewEnvComponent:ApplyPrism=>BoardRenderService:_ApplyPrismToPreviewEnv

function PreviewEnvComponent:UnapplyPrism(prismPos)
    local posIdx = Vector2.Pos2Index(prismPos)
    local changed = self._prismChangedPieces[posIdx]
    if changed then
        for posIdx, pieceType in pairs(changed) do
            self._pieceTypes[posIdx] = pieceType
        end
        self._prismChangedPieces[posIdx] = nil
        self:SetNeedUpdateConnectPieces(true)
    end
end

function PreviewEnvComponent:GetPrismChangedPieces(prismPos)
    local posIdx = Vector2.Pos2Index(prismPos)
    return self._prismChangedPieces[posIdx]
end

function PreviewEnvComponent:SetNeedUpdateConnectPieces(b)
    self._needUpdateConnectPieces = b
end

function PreviewEnvComponent:GetNeedUpdateConnectPieces()
    return self._needUpdateConnectPieces
end

function PreviewEnvComponent:SetPieceType(pos, pieceType)
    local posIdx = Vector2.Pos2Index(pos)
    self._pieceTypes[posIdx] = pieceType
end

function PreviewEnvComponent:GetPieceType(pos)
    local posIdx = Vector2.Pos2Index(pos)
    return self._pieceTypes[posIdx]
end

function PreviewEnvComponent:GetAllPieceType()
    return self._allPieceTable
end

function PreviewEnvComponent:SetMonsterClickCount(count)
    self._monsterClickCount = count
end

function PreviewEnvComponent:GetMonsterClickCount()
    return self._monsterClickCount
end

--[[
    Entity Extensions
]]
---@return PreviewEnvComponent
function Entity:PreviewEnv()
    return self:GetComponent(self.WEComponentsEnum.PreviewEnv)
end

function Entity:HasPreviewEnv()
    return self:HasComponent(self.WEComponentsEnum.PreviewEnv)
end

function Entity:AddPreviewEnv()
    local index = self.WEComponentsEnum.PreviewEnv
    local component = PreviewEnvComponent:New(self._world)
    self:AddComponent(index, component)
end

function Entity:RemovePreviewEnv()
    if self:HasPreviewEnv() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewEnv)
    end
end

function Entity:ReplacePreviewEnv()
    local index = self.WEComponentsEnum.PreviewEnv
    local component = PreviewEnvComponent:New(self._world)
    self:ReplaceComponent(index, component)
end
