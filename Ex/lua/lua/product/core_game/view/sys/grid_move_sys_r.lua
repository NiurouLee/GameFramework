--[[-------------------------------------
    GridMoveSystem_Render 基于逻辑坐标的移动流程
--]] -------------------------------------

---@class GridMoveSystem_Render:Object
_class("GridMoveSystem_Render", Object)
GridMoveSystem_Render = GridMoveSystem_Render

function GridMoveSystem_Render:Constructor(world)
    ---@type MainWorld
    self.world = world
    self.group = world:GetGroup(world.BW_WEMatchers.GridMove)

    ---@type TimeService
    self._timeService = self.world:GetService("Time")
end

function GridMoveSystem_Render:Execute()
    self.group:HandleForeach(self, self.UpdateGridMove)
end

---@param e Entity
function GridMoveSystem_Render:UpdateGridMove(e)
    if e:HasPauseFlag() then --有暂停标记就暂停
        return
    end
    ---@type GridMoveComponent
    local gridMoveCmpt = e:GridMove()
    --local gridLocCmpt = e:GridLocation()
    ---@type LocationComponent
    local locationComponent = e:Location()
    local gridMoveTargetPos = gridMoveCmpt:GetTargetPos()
    local gridMoveOriginPos = gridMoveCmpt:GetOriginPos()
    local gridMoveSetHeight = gridMoveCmpt:GetMovingHeight()
    local gridMoveSpeed = gridMoveCmpt:GetSpeed()
    if gridMoveTargetPos == nil then
        e:RemoveGridMove()
        return
    end
    if not gridMoveSpeed then
        e:RemoveGridMove()
        return
    end
    ---@type BoardServiceRender
    local boardServiceRender = self.world:GetService("BoardRender")

    ---这代码没意义吧
    if locationComponent == nil then
        --e:SetGridLocation(gridMoveCmpt.targetPos:Clone(), Vector2(0, -1))
        e:SetLocation(gridMoveCmpt:GetTargetPos(), Vector2(0, -1))
        e:RemoveGridMove()
        return
    end

    ---@type Vector2
    local gridPosition = boardServiceRender:GetRealEntityGridPos(e)

    local distance = Vector2.Distance(gridMoveTargetPos, gridPosition)

    local deltaTimeMS = self._timeService:GetDeltaTimeMs()
    local movement = deltaTimeMS * gridMoveCmpt:GetSpeed() / 1000

    if movement > distance then
        e:SetPosition(gridMoveTargetPos)
        e:RemoveGridMove()
        if e:HasTeam() then
            local pets = e:Team():GetTeamPetEntities()
            for i,pet in ipairs(pets) do
                pet:SetPosition(gridMoveTargetPos)
            end
        end
        return
    else
        if distance == 0 then
            --Log.fatal("GridMoveOver EntityID:",e:GetID())
            e:RemoveGridMove()
            return
        else
            local pos = Vector2.Lerp(gridPosition, gridMoveTargetPos, movement / distance)
            local localPosition = boardServiceRender:GridPos2RenderPos(pos)
            --Log.fatal("SetRenderPos: ", tostring(pos)," EntityID:",e:GetID())
            if gridMoveSetHeight then
                pos = Vector3(localPosition.x,gridMoveSetHeight,localPosition.z)
            end
            e:SetPosition(pos)

            --脚底阴影&被怪物覆盖的机关隐藏
            if e:HasMonsterID() and distance > 0.5 and not gridMoveCmpt.hasRefreshPiece then --HasAI
                gridMoveCmpt.hasRefreshPiece = true
                if gridMoveCmpt:IsRefreshPiece() then
                    self:RefreshTrapsInPath(e, gridMoveOriginPos, gridMoveTargetPos)
                end
            end
        end
    end
end

function GridMoveSystem_Render:RefreshTrapsInPath(e, v2Origin, v2Target)
    --计算多格怪重叠
    ---@type PieceServiceRender
    local pieceService = self.world:GetService("Piece")
    ---@type TrapServiceRender
    local trapServiceRender = self.world:GetService("TrapRender")

    local v2GridOffset = e:GridLocation():GetGridOffset()
    local v2OriginNonOffset = v2Origin - v2GridOffset
    local v2TargetNonOffset = v2Target - v2GridOffset

    local tArea = e:BodyArea():GetArea()
    local tNewAbsArea = {}
    for _, v2Relative in ipairs(tArea) do
        table.insert(tNewAbsArea, v2Relative + v2TargetNonOffset)
    end

    local tOldAbsArea = {}
    for _, v2Relative in ipairs(tArea) do
        table.insert(tOldAbsArea, v2Relative + v2OriginNonOffset)
    end

    for _, v2 in ipairs(tNewAbsArea) do
        if not table.icontains(tOldAbsArea, v2) then
            self:_ShowHideTrapAtPos(v2, false)
        end
    end

    for _, v2 in ipairs(tOldAbsArea) do
        if not table.icontains(tNewAbsArea, v2) then
            self:_ShowHideTrapAtPos(v2, true)
        end
    end
end

function GridMoveSystem_Render:_ShowHideTrapAtPos(v2Pos, isShow)
    ---@type TrapServiceRender
    local trapServiceRender = self.world:GetService("TrapRender")

    if v2Pos.x == math.floor(v2Pos.x) and v2Pos.y == math.floor(v2Pos.y) then
        trapServiceRender:ShowHideTrapAtPos(v2Pos, isShow)
    end
end
