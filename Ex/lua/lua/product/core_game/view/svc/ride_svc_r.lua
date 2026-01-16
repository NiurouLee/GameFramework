--[[------------------------------------------------------------------------------------------
    RideServiceRender : 机关表现
]] --------------------------------------------------------------------------------------------

_class("RideServiceRender", BaseService)
---@class RideServiceRender: BaseService
RideServiceRender = RideServiceRender

function RideServiceRender:Constructor(world)

end

function RideServiceRender:Initialize()
    ---@type RenderEntityService
    self._entityRenderSvc = self._world:GetService("RenderEntity")
    ---@type PieceServiceRender
    self._pieceRenderSvc = self._world:GetService("Piece")
    ---@type UtilDataServiceShare
    self._utilDataSvc = self._world:GetService("UtilData")
end

function RideServiceRender:RideTrap(rideID, mountID, gridLocRes)
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)
    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)
    local pos = rideEntity:GetGridPosition() + rideEntity:GetGridOffset()
    local dir = rideEntity:GetGridDirection()
    local targetPos = rideEntity:GetGridPosition()
    local hieght = rideEntity:GetGridHeight()

    if gridLocRes then
        pos = gridLocRes:GetGridLocResultBornPos() + gridLocRes:GetGridLocResultBornOffset()
        dir = gridLocRes:GetGridLocResultBornDir()
        targetPos = gridLocRes:GetGridLocResultBornPos()
        hieght = gridLocRes:GetGridLocResultBornHeight()
    end
    local bodyArea = rideEntity:BodyArea():GetArea()
    for i = 1, #bodyArea do
        local posWork = targetPos + bodyArea[i]
        if self._utilDataSvc:IsValidPiecePos(posWork) then
            self._pieceRenderSvc:SetPieceAnimDown(posWork)
        end
    end

    rideEntity:SetLocation(pos, dir)
    rideEntity:SetLocationHeight(hieght)
    self._entityRenderSvc:CreateMonsterAreaOutlineEntity(rideEntity)
    rideEntity:ReplaceRideRender(rideID, mountID)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTRideStateChange:New(rideEntity, true))
    -- ---@type LocationComponent
    -- local ridLocationCmpt = rideEntity:Location()
    -- ridLocationCmpt:SetModifyLocationCallback(
    --     function(pos, dir)
    --         self:SetTargetLocation(pos, dir, mountEntity, rideEntity:GetGridOffset(), mountEntity:GetGridOffset())
    --     end
    -- )


    mountEntity:ReplaceRideRender(rideID, mountID)
    -- ---@type LocationComponent
    -- local mountLocationCmpt = mountEntity:Location()
    -- mountLocationCmpt:SetModifyLocationCallback(
    --     function(pos, dir)
    --         self:SetTargetLocation(pos, dir, rideEntity, mountEntity:GetGridOffset(), rideEntity:GetGridOffset())
    --     end
    -- )
    Log.debug("[RideServiceRender:RideTrap] ride_id = ", rideID, ", trap_id = ", mountID)
end

function RideServiceRender:RideMonster(rideID, mountID, gridLocRes)
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)
    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)
    local pos = rideEntity:GetGridPosition() + rideEntity:GetGridOffset()
    local dir = rideEntity:GetGridDirection()
    local hieght = rideEntity:GetGridHeight()

    local rideOffset = Vector2.New(rideEntity:GetGridOffset().x, rideEntity:GetGridOffset().y)
    local mountOffset = Vector2.New(mountEntity:GetGridOffset().x, mountEntity:GetGridOffset().y)

    if gridLocRes then
        pos = gridLocRes:GetGridLocResultBornPos() + gridLocRes:GetGridLocResultBornOffset()
        dir = gridLocRes:GetGridLocResultBornDir()
        hieght = gridLocRes:GetGridLocResultBornHeight()
        rideOffset = Vector2.New(gridLocRes:GetGridLocResultBornOffset().x, gridLocRes:GetGridLocResultBornOffset().y)
    end

    ---@type MonsterIDComponent
    local monsterIDCmpt = rideEntity:MonsterID()
    if monsterIDCmpt then
        monsterIDCmpt:SetNeedOutLineEnable(false)
    end
    rideEntity:SetLocation(pos, dir)
    rideEntity:SetLocationHeight(hieght)
    rideEntity:ReplaceRideRender(rideID, mountID)
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTRideStateChange:New(rideEntity, true))
    ---@type LocationComponent
    local ridLocationCmpt = rideEntity:Location()
    ridLocationCmpt:SetModifyLocationCallback(
        function(pos, dir)
            self:SetTargetLocation(pos, dir, mountEntity, rideOffset, mountOffset)
        end
    )

    mountEntity:ReplaceRideRender(rideID, mountID)
    ---@type LocationComponent
    local mountLocationCmpt = mountEntity:Location()
    mountLocationCmpt:SetModifyLocationCallback(
        function(pos, dir)
            self:SetTargetLocation(pos, dir, rideEntity, mountOffset, rideOffset)
        end
    )

    Log.debug("[RideServiceRender:RideMonster] ride_id = ", rideID, ", monster_id = ", mountID)
end

function RideServiceRender:RemoveRideRender(rideID, mountID)
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)
    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)

    Log.debug("[RideServiceRender:RemoveRideRender] ride_id = ", rideID, ", mount_id = ", mountID)

    --移除组件
    rideEntity:RemoveRideRender()
    ---@type LocationComponent
    local ridLocationCmpt = rideEntity:Location()
    ridLocationCmpt:SetModifyLocationCallback(nil)

    --mountEntity可能已经消失了
    if mountEntity then
        mountEntity:RemoveRideRender()
        ---@type LocationComponent
        local mountLocationCmpt = mountEntity:Location()
        mountLocationCmpt:SetModifyLocationCallback(nil)

        if mountEntity:HasTrapID() then
            self._entityRenderSvc:DestroyMonsterAreaOutLineEntity(rideEntity)
            local targetPos = mountEntity:GetGridPosition()
            local bodyArea = mountEntity:BodyArea():GetArea()
            for i = 1, #bodyArea do
                local posWork = targetPos + bodyArea[i]
                if self._utilDataSvc:IsValidPiecePos(posWork) then
                    self._pieceRenderSvc:SetPieceAnimUp(posWork)
                end
            end
        end

        if mountEntity:HasMonsterID() then
            ---@type MonsterIDComponent
            local monsterIDCmpt = rideEntity:MonsterID()
            if monsterIDCmpt then
                monsterIDCmpt:SetNeedOutLineEnable(true)
            end
        end
    end
    self._world:GetService("PlayBuff"):PlayBuffView(TT, NTRideStateChange:New(rideEntity, false))
end

function RideServiceRender:SetNoRidePos(rideID, targetPos, fromTrap)
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)
    rideEntity:SetLocationHeight(0)
    rideEntity:SetPosition(targetPos)

    self._entityRenderSvc:CreateMonsterAreaOutlineEntity(rideEntity)
    local bodyArea = rideEntity:BodyArea():GetArea()
    for i = 1, #bodyArea do
        local posWork = targetPos + bodyArea[i]
        if self._utilDataSvc:IsValidPiecePos(posWork) then
            self._pieceRenderSvc:SetPieceAnimDown(posWork)
        end
    end
end

function RideServiceRender:ReplaceRideRender(rideID, mountID, gridLocRes)
    ---@type Entity
    local rideEntity = self._world:GetEntityByID(rideID)
    local oldMountID = nil
    if rideEntity:HasRideRender() then
        ---@type RideRenderComponent
        local rideCmpt = rideEntity:RideRender()
        oldMountID = rideCmpt:GetMountID()
        if oldMountID == mountID then
            --不需要更换坐骑
            return
        end
        self:RemoveRideRender(rideID, oldMountID)
    else
        self._entityRenderSvc:DestroyMonsterAreaOutLineEntity(rideEntity)

        local targetPos = rideEntity:GetRenderGridPosition()
        local bodyArea = rideEntity:BodyArea():GetArea()
        for i = 1, #bodyArea do
            local posWork = targetPos + bodyArea[i]
            if self._utilDataSvc:IsValidPiecePos(posWork) then
                self._pieceRenderSvc:SetPieceAnimUp(posWork)
            end
        end
    end

    ---@type Entity
    local mountEntity = self._world:GetEntityByID(mountID)
    if mountEntity:HasTrapRender() then
        self:RideTrap(rideID, mountID, gridLocRes)
    elseif mountEntity:HasMonsterID() then
        self:RideMonster(rideID, mountID, gridLocRes)
    end
end

---@param pos Vector2
---@param dir Vector2
---@param targetEntity Entity
function RideServiceRender:SetTargetLocation(pos, dir, targetEntity, oriOffset, targetOffset)
    if not targetEntity:HasLocation() then
        return
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local targetGridPos = boardServiceRender:BoardRenderPos2FloatGridPos_New(pos)
    targetGridPos = targetGridPos - oriOffset + targetOffset

    local targetPos = boardServiceRender:GridPosition2LocationPos(targetGridPos, targetEntity)

    ---@type LocationComponent
    local locationCmpt = targetEntity:Location()
    locationCmpt:CallBackModifyLocation(targetPos, dir, targetEntity)
end
