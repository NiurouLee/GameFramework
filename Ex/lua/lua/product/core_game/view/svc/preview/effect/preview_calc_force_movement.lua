--[[
    免【免位移】的位移效果——强制位移：预览版本

    效果仅对单格非boss怪物生效，按阻挡计算，顺序为点选确定方向的最远端向最近端
    路线上不考虑格子上其他单位的触发，但落点上正常处理

    预览版本：本体逻辑是一种特殊的计算器，这里是复制了核心逻辑，返回一个技能结果用来预览
]]
_class("PreviewSkillEffectCalc_ForceMovement", Object)
---@class PreviewSkillEffectCalc_ForceMovement
PreviewSkillEffectCalc_ForceMovement = PreviewSkillEffectCalc_ForceMovement

---@param world MainWorld
function PreviewSkillEffectCalc_ForceMovement:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param skillPreviewContext SkillPreviewContext
---@param skillEffectParam SkillEffectParam_ForceMovement
---@return SkillEffectResult_ForceMovement
function PreviewSkillEffectCalc_ForceMovement:Calculate(casterEntity, skillPreviewContext, skillEffectParam)
    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()

    if not previewPickUpComponent then
        Log.error(self._className, "施法者没有ActiveSkillPickupComponent")
        return
    end

    local pickupPosArray = previewPickUpComponent:GetAllValidPickUpGridPos()
    if #pickupPosArray == 0 then
        Log.error(self._className, "没有点选位置记录")
        return
    end

    local targetIDs = skillPreviewContext:GetTargetEntityIDList(SkillEffectType.ForceMovement)
    local includeMultiSize = skillEffectParam:IsIncludeMultiSize()--支持多格怪
    local includeTrap = skillEffectParam:IsIncludeTrap()--支持多格怪

    ---@type Entity[]
    local tSelectedTarget = {}
    for _, targetID in ipairs(targetIDs) do
        local e = self._world:GetEntityByID(targetID)
        if self:IsEntityTarget(e,includeMultiSize,includeTrap) then
            table.insert(tSelectedTarget, e)
        end
    end

    local moveCenterPos = casterEntity:GetGridPosition()
    local pickupDirPos = pickupPosArray[1]
    local isPickTargetMove = false
    --阿克希亚的点选，第一个是点目标的
    if #pickupPosArray > 1 then
        moveCenterPos = pickupPosArray[1]
        pickupDirPos = pickupPosArray[2]
        isPickTargetMove = true --是点击目标 然后强制移动--可能是多格怪，方向需要根据bodyArea处理
    end
    local v2Dir = moveCenterPos - pickupDirPos--注意方向与移动方向相反

    if v2Dir.x > 0 then
        v2Dir.x = 1
    elseif v2Dir.x < 0 then
        v2Dir.x = -1
    end
    if v2Dir.y > 0 then
        v2Dir.y = 1
    elseif v2Dir.y < 0 then
        v2Dir.y = -1
    end

    local sortFunction = ForceMovementCalculator.GetEntitySortFunctionByDir(v2Dir)
    table.sort(tSelectedTarget, sortFunction)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    ---@type BoardServiceLogic
    local lbsvc = self._world:GetService("BoardLogic")

    local isCalcStepByPick = skillEffectParam:IsCalcStepByPick()
    local result = SkillEffectResult_ForceMovement:New()
    for _, e in ipairs(tSelectedTarget) do
        local maxStep = skillEffectParam:GetStep()

        if isPickTargetMove then--点目标然后点方向 可能有多格怪，需要重新计算移动方向
            v2Dir,maxStep = self:_ReCalcMoveDirByTargetAndPick(e,moveCenterPos,pickupDirPos,maxStep,isCalcStepByPick)
        end
        local bodyArea = e:BodyArea():GetArea()
        local final
        for i = 1, maxStep do
            local v2 = e:GetGridPosition() - v2Dir * i

            local blockFlag = BlockFlag.MonsterLand
            if e:HasMonsterID() then
                local monsterClassID = e:MonsterID():GetMonsterClassID()
                local cfgMonsterClass = Cfg.cfg_monster_class({ID = monsterClassID})[1]
                if cfgMonsterClass.RaceType == MonsterRaceType.Fly then
                    blockFlag = BlockFlag.MonsterFly
                end
            end
            local canMove = true
            if bodyArea and #bodyArea > 1 then--多格怪
                local blockExceptTarget = {e:GetID()}
                -- 将除技能目标以外的阻挡复制一份用来计算
                self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(nil, blockExceptTarget)
                ---@type BoardServiceLogic
                local boardsvc = self._world:GetService("BoardLogic")
                local blockVal = boardsvc:GetEntityMoveBlockFlag(e)
                local fitFullBodyArea = self:IsPosFitFullBodyArea(v2, e, blockVal,nil)
                if not fitFullBodyArea then
                    canMove = false
                    break
                end
            else
                local pieceBlock = utilData:FindBlockByPos(v2)
                if utilData:IsValidPiecePos(v2) and pieceBlock and (not lbsvc:IsPosBlock(v2, blockFlag)) then
                    --final = v2
                else
                    canMove = false
                    break
                end
            end
            
            if canMove then
                final = v2
            else
                break
            end
        end

        result:AppendMoveResult(e:GetID(), e:GetGridPosition(), final or e:GetGridPosition(), {})
    end

    return result
end

---@param e Entity
function PreviewSkillEffectCalc_ForceMovement:IsEntityTarget(e,includeMultiSize,includeTrap)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        if includeTrap then
            if e:HasTrapID() then
                return true
            end
        end
        return e:HasTeam() or e:HasPet()
    end
    local isTrap = false
    if not e:HasMonsterID() then
        if includeTrap and e:HasTrapID() then
            isTrap = true
        else
            return false
        end
    end
    if e:HasGhost() then
        return false
    end

    if not isTrap then
        ---@type ConfigService
        local cfgsvc = self._world:GetService("Config")
        local monsterConfigData = cfgsvc:GetMonsterConfigData()
        local monsterID = e:MonsterID():GetMonsterID()
        if monsterConfigData:IsBoss(monsterID) then
            return false
        end
    end

    if (not includeMultiSize) and (e:BodyArea():GetAreaCount() ~= 1) then
        return false
    end

    -- 免疫 强制位移（及牵引的强制效果）
    ---@type BuffLogicService
    local bufflsvc = self._world:GetService("BuffLogic")
    if bufflsvc:CheckForceMoveImmunity(e) then
        return false
    end

    return true
end
function PreviewSkillEffectCalc_ForceMovement:_NewPieceBlockBlackboard(centerPos, targetIDs)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local blackboard = utilData:CreatePieceBlockBlackboard(targetIDs)
    --blackboard[centerPos.x][centerPos.y]:AddBlock(-1, BlockFlag.MonsterLand | BlockFlag.MonsterFly | BlockFlag.LinkLine)
    return blackboard
end
---@param gridPos Vector2
---@param entity Entity
---@param usePosOff Vector2 多格怪 用于计算圈数的点可能是逻辑坐标+usePosOff 计算fit时需要做偏移
function PreviewSkillEffectCalc_ForceMovement:IsPosFitFullBodyArea(gridPos, entity, testBlockVal,bodyAreaByOff)
    local checkPos = gridPos
    local areaArray = entity:BodyArea():GetArea()
    if bodyAreaByOff then
        areaArray = bodyAreaByOff
    end
    for _, v2RelativeBody in ipairs(areaArray) do
        local v2 = checkPos + v2RelativeBody
        if (not self._pieceBlockBlackboard[v2.x]) or (not self._pieceBlockBlackboard[v2.x][v2.y]) then
            return false
        end
        if (self._pieceBlockBlackboard[v2.x][v2.y]:GetBlock() & testBlockVal ~= 0) then
            return false
        end
        ---@type UtilDataServiceShare
        local utilData = entity:GetOwnerWorld():GetService("UtilData")
        if (utilData:IsPosBlockWithEntityRace(v2, testBlockVal, entity)) then
            return false
        end
    end
    return true
end
function PreviewSkillEffectCalc_ForceMovement:CalcTargetForceMovementStep(targetEntity,dir,maxStep)
    if not targetEntity then
        return
    end
    local moveStep = 0
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type BoardServiceLogic
    local lbsvc = self._world:GetService("BoardLogic")
    local e = targetEntity
    local v2Dir = dir
    local bodyArea = e:BodyArea():GetArea()
    local final
    for i = 1, maxStep do
        local v2 = e:GetGridPosition() - v2Dir * i

        local blockFlag = BlockFlag.MonsterLand
        if e:HasMonsterID() then
            local monsterClassID = e:MonsterID():GetMonsterClassID()
            local cfgMonsterClass = Cfg.cfg_monster_class({ID = monsterClassID})[1]
            if cfgMonsterClass.RaceType == MonsterRaceType.Fly then
                blockFlag = BlockFlag.MonsterFly
            end
        end
        local canMove = true
        if bodyArea and #bodyArea > 1 then--多格怪
            local blockExceptTarget = {e:GetID()}
            -- 将除技能目标以外的阻挡复制一份用来计算
            self._pieceBlockBlackboard = self:_NewPieceBlockBlackboard(nil, blockExceptTarget)
            ---@type BoardServiceLogic
            local boardsvc = self._world:GetService("BoardLogic")
            local blockVal = boardsvc:GetEntityMoveBlockFlag(e)
            local fitFullBodyArea = self:IsPosFitFullBodyArea(v2, e, blockVal,nil)
            if not fitFullBodyArea then
                canMove = false
                break
            end
        else
            local pieceBlock = utilData:FindBlockByPos(v2)
            if utilData:IsValidPiecePos(v2) and pieceBlock and (not lbsvc:IsPosBlock(v2, blockFlag)) then
                --final = v2
            else
                canMove = false
                break
            end
        end
        
        if canMove then
            final = v2
            moveStep = i
        else
            break
        end
    end
    return moveStep
end
function PreviewSkillEffectCalc_ForceMovement:_ReCalcMoveDirByTargetAndPick(targetEntity, pickPos,dirPos,defaultStep,isCalcStepByPick)
    local dir
    local step = defaultStep
    local targetPos = targetEntity:GetGridPosition()
    local bodyArea = targetEntity:BodyArea():GetArea()
    if bodyArea then
        if #bodyArea == 1 then
            dir = dirPos - pickPos
            step = math.abs(dir.x) + math.abs(dir.y)
            if dir.x > 0 then
                dir.x = 1
            elseif dir.x < 0 then
                dir.x = -1
            end
            if dir.y > 0 then
                dir.y = 1
            elseif dir.y < 0 then
                dir.y = -1
            end
        else
            local upMaxY = nil
            local downMinY = nil
            local rightMaxX = nil
            local leftMinX = nil
            for index, off in ipairs(bodyArea) do
                local bodyPos = targetPos + off
                if not upMaxY then
                    upMaxY = bodyPos.y
                elseif bodyPos.y > upMaxY then
                    upMaxY = bodyPos.y
                end
                if not downMinY then
                    downMinY = bodyPos.y
                elseif bodyPos.y < downMinY then
                    downMinY = bodyPos.y
                end
                if not rightMaxX then
                    rightMaxX = bodyPos.x
                elseif bodyPos.x > rightMaxX then
                    rightMaxX = bodyPos.x
                end
                if not leftMinX then
                    leftMinX = bodyPos.x
                elseif bodyPos.x < leftMinX then
                    leftMinX = bodyPos.x
                end
            end
            if dirPos.y > upMaxY then--上
                dir = Vector2.up
                if isCalcStepByPick then
                    step = dirPos.y - upMaxY
                end
            elseif dirPos.y < downMinY then
                dir = Vector2.down
                if isCalcStepByPick then
                    step = downMinY - dirPos.y
                end
            elseif dirPos.x > rightMaxX then
                dir = Vector2.right
                if isCalcStepByPick then
                    step = dirPos.x - rightMaxX
                end
            elseif dirPos.x < leftMinX then
                dir = Vector2.left
                if isCalcStepByPick then
                    step = leftMinX - dirPos.x
                end
            end
        end
    end
    --注意方向与移动方向相反
    dir = dir * -1
    return dir,step
end