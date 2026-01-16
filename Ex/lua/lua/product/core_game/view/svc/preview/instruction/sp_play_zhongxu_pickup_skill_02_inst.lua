require("sp_base_inst")

_class("SkillPreviewPlayZhongxuPickupSkill02Instruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayZhongxuPickupSkill02Instruction: SkillPreviewBaseInstruction
SkillPreviewPlayZhongxuPickupSkill02Instruction = SkillPreviewPlayZhongxuPickupSkill02Instruction

function SkillPreviewPlayZhongxuPickupSkill02Instruction:Constructor(params)
    self._trapID = tonumber(params.trapID)
    self._forceMovementIndex = tonumber(params.forceMovementIndex)
end

---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayZhongxuPickupSkill02Instruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld

    local world = previewContext:GetWorld()

    ---@type UtilScopeCalcServiceShare
	local utilScopeSvc = world:GetService("UtilScopeCalc")
    	---@type Entity
	local renderBoardEntity = world:GetRenderBoardEntity()
	---@type PickUpTargetComponent
	local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
	local activeSkillID = pickUpTargetCmpt:GetCurActiveSkillID()
    	---@type ConfigService
	local configService = world:GetService("Config")
    	---@type SkillConfigData
	local skillConfigData = configService:GetSkillConfigData(activeSkillID, casterEntity)
    local pickUpValidScopeList = {}
    local pickUpInvalidScopeList = {}

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")

    local parser = SkillScopeParamParser:New()

    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    local pickupPosArray = previewPickUpComponent and previewPickUpComponent:GetAllValidPickUpGridPos() or {}
    if #pickupPosArray == 0 then
        entitySvc:DestroyGhost()

        previewActiveSkillService:DestroyPickUpArrow()

        pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.firstPickValidScopeList or {})
        pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.firstPickInvalidScopeList or {})

        ---@type Vector2[]
        local validGridList = utilScopeSvc:BuildScopeGridList(pickUpValidScopeList, casterEntity) or {}
        ---@type Vector2[]
        local invalidGridList = utilScopeSvc:BuildScopeGridList(pickUpInvalidScopeList, casterEntity) or {}

        local finalGridList = {}
        for _, v2 in ipairs(validGridList) do
            if not table.Vector2Include(invalidGridList, v2) then
                table.insert(finalGridList, v2)
            end
        end

        previewActiveSkillService:DoConvert(finalGridList,"Normal", "Dark")
    else
        local firstPickup = pickupPosArray[1]
        ---@type UtilDataServiceShare
        local utilData = world:GetService("UtilData")
        local isPickTrap = false
        local isPickEnemyTeam = false
        local isPickMonster = false

        local pickEntity = nil
        local tTrapEntities = utilData:GetTrapsAtPos(firstPickup)
        for _, e in ipairs(tTrapEntities) do
            if e:TrapID():GetTrapID() == self._trapID then
                isPickTrap = true
                pickEntity = e
                break
            end
        end
        if not isPickTrap then
            if world:MatchType() == MatchType.MT_BlackFist then
                if casterEntity:HasPet() then
                    ---@type Entity
                    local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
                    ---@type Entity
                    local enemyEntity = teamEntity:Team():GetEnemyTeamEntity()
                    local enemyTeamPos = enemyEntity:GetGridPosition()
                    if enemyTeamPos == firstPickup then
                        isPickEnemyTeam = true
                        pickEntity = enemyEntity
                    end
                end
            else
                local monsterEntity = utilData:GetMonsterAtPos(firstPickup)
                if monsterEntity then
                    isPickMonster = true
                    pickEntity = monsterEntity
                end
            end
        end
        
        if isPickTrap then
            if #pickupPosArray == 1 then
                entitySvc:DestroyGhost()

                pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickValidScopeList or {})
                pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickInvalidScopeList or {})

                ---@type Vector2[]
                local validGridList = utilScopeSvc:BuildScopeGridList(pickUpValidScopeList, casterEntity) or {}
                ---@type Vector2[]
                local invalidGridList = utilScopeSvc:BuildScopeGridList(pickUpInvalidScopeList, casterEntity) or {}
                local arrowScope = {}
                local finalGridList = {}
                for _, v2 in ipairs(validGridList) do
                    if not table.Vector2Include(invalidGridList, v2) then
                        table.insert(finalGridList, v2)
                        table.insert(arrowScope,v2)
                    end
                end

                table.insert(finalGridList, firstPickup)

                previewActiveSkillService:DoConvert(finalGridList,"Normal", "Dark")
                previewActiveSkillService:DestroyPickUpArrow()
                --previewActiveSkillService:ShowFourPickUpArrow(false, firstPickup)
                self:_ShowAroundScopeArrows(world,pickEntity,arrowScope)
            else
                entitySvc:DestroyGhost()
                YIELD(TT) --同一帧删除ghost再创建，会创建不出来？？？

                ---@type SkillPreviewEffectCalcService
                local previewEffectCalcService = world:GetService("PreviewCalcEffect")
                ---@type Vector2[]
                local scopeGridList = previewContext:GetScopeResult()
                --local effect = previewContext:GetEffect(SkillEffectType.ForceMovement)
                local effect = skillConfigData:GetSkillEffectByIndex(self._forceMovementIndex)

                ---@type SkillEffectResult_ForceMovement
                local result = previewEffectCalcService:CalcForceMovement(casterEntity, previewContext, effect)

                if result then
                    self:_DoForceMovementPresentation(TT, world, result)
                end

                local arrowEntities = world:GetGroup(world.BW_WEMatchers.PickUpArrow):GetEntities()
                for _, e in ipairs(arrowEntities) do
                    local arrowPos = e:GetRenderGridPosition()
                    local statTable = {}
                    if arrowPos == pickupPosArray[2] then
                        statTable = {select = true, idle = false}
                    else
                        statTable = {select = false, idle = true}
                    end
                    e:SetAnimatorControllerBools(statTable)
                end
            end
        elseif isPickEnemyTeam or isPickMonster then
            if #pickupPosArray == 1 then
                entitySvc:DestroyGhost()

                pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickValidScopeList or {})
                pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickInvalidScopeList or {})

                ---@type Vector2[]
                local validGridList = utilScopeSvc:BuildScopeGridList(pickUpValidScopeList, casterEntity) or {}
                ---@type Vector2[]
                local invalidGridList = utilScopeSvc:BuildScopeGridList(pickUpInvalidScopeList, casterEntity) or {}
                local arrowScope = {}
                local finalGridList = {}
                for _, v2 in ipairs(validGridList) do
                    if not table.Vector2Include(invalidGridList, v2) then
                        table.insert(finalGridList, v2)
                        table.insert(arrowScope,v2)
                    end
                end

                table.insert(finalGridList, firstPickup)

                previewActiveSkillService:DoConvert(finalGridList,"Normal", "Dark")
                previewActiveSkillService:DestroyPickUpArrow()
                self:_ShowAroundScopeArrows(world,pickEntity,arrowScope)
                --previewActiveSkillService:ShowFourPickUpArrow(false, firstPickup)
            else
                entitySvc:DestroyGhost()
                YIELD(TT) --同一帧删除ghost再创建，会创建不出来？？？

                ---@type SkillPreviewEffectCalcService
                local previewEffectCalcService = world:GetService("PreviewCalcEffect")
                ---@type Vector2[]
                local scopeGridList = previewContext:GetScopeResult()
                --local effect = previewContext:GetEffect(SkillEffectType.ForceMovement)
                local effect = skillConfigData:GetSkillEffectByIndex(self._forceMovementIndex)

                ---@type SkillEffectResult_ForceMovement
                local result = previewEffectCalcService:CalcForceMovement(casterEntity, previewContext, effect)

                if result then
                    self:_DoForceMovementPresentation(TT, world, result)
                end

                local arrowEntities = world:GetGroup(world.BW_WEMatchers.PickUpArrow):GetEntities()
                for _, e in ipairs(arrowEntities) do
                    local arrowPos = e:GetRenderGridPosition()
                    local statTable = {}
                    if arrowPos == pickupPosArray[2] then
                        statTable = {select = true, idle = false}
                    else
                        statTable = {select = false, idle = true}
                    end
                    e:SetAnimatorControllerBools(statTable)
                end
            end
        end
    end
end

---@param result SkillEffectResult_ForceMovement
function SkillPreviewPlayZhongxuPickupSkill02Instruction:_DoForceMovementPresentation(TT, world, result)
    local taskIDs = {}
    local array = result:GetMoveResult()
    for _, info in ipairs(array) do
        local entity = world:GetEntityByID(info.targetID)
        if (info.isMoved) then
            local tid = self:_DoSingleTarget(TT, world, info, entity)
            if tid then
                table.insert(taskIDs, tid)
            end
        end
    end

    while not TaskHelper:GetInstance():IsAllTaskFinished(taskIDs) do
        YIELD(TT)
    end
end

---@param info SkillEffectResult_ForceMovement_MoveResult
function SkillPreviewPlayZhongxuPickupSkill02Instruction:_DoSingleTarget(TT, world, info, entity)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local entitySvc = world:GetService("RenderEntity")

    local ghostEntity = entitySvc:CreateGhost(info.v2OldPos, entity,"AtkUltPreview")

    ghostEntity:AddGridMove(BattleConst.ForceMovementPreviewSpeed, info.v2NewPos, info.v2OldPos)
    -- 使用GridMove实现表现，但需要等待所有牵引结束，需要启动监工协程
    -- GridMove有独立的系统负责计算实际的位移，所以没有计算时间
    return GameGlobal.TaskManager():CoreGameStartTask(self._IsMoveFinished, self, ghostEntity)
end

function SkillPreviewPlayZhongxuPickupSkill02Instruction:_IsMoveFinished(TT, entity)
    return not entity:HasGridMove()
end

function SkillPreviewPlayZhongxuPickupSkill02Instruction:_ParseScopeList(list)
    local parser = SkillScopeParamParser:New()

    local t = {}
    for _, v in ipairs(list) do
        ---@type SkillPreviewScopeParam
        local param = SkillPreviewScopeParam:New(v)
        local data = parser:ParseScopeParam(v.ScopeType, v.ScopeParam)
        param:SetScopeParamData(data)
        table.insert(t, param)
    end
    return t
end
function SkillPreviewPlayZhongxuPickupSkill02Instruction:_ShowAroundScopeArrows(world,entity,arrowScope)
    --再根据当前的范围重新画
    ---@type RenderEntityService
    local renderEntityService = world:GetService("RenderEntity")
    local v2CasterPos = entity:GetGridPosition()
    for _, v2Scope in ipairs(arrowScope) do
        local dir = self:_CalcArrowDirByTargetAndPos(entity,v2Scope)
        local eArrow = renderEntityService:CreateRenderEntity(EntityConfigIDRender.PickUpArrow)
        eArrow:SetLocation(v2Scope, dir)
    end
end
function SkillPreviewPlayZhongxuPickupSkill02Instruction:_CalcArrowDirByTargetAndPos(targetEntity, arrowPos)
    local dir
    local targetPos = targetEntity:GetGridPosition()
    local bodyArea = targetEntity:BodyArea():GetArea()
    if bodyArea then
        if #bodyArea == 1 then
            dir = arrowPos - targetPos
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
            if arrowPos.y > upMaxY then--上
                dir = Vector2.up
            elseif arrowPos.y < downMinY then
                dir = Vector2.down
            elseif arrowPos.x > rightMaxX then
                dir = Vector2.right
            elseif arrowPos.x < leftMinX then
                dir = Vector2.left
            end
        end
    end
    return dir
end