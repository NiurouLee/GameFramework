require("sp_base_inst")

_class("SkillPreviewPlayAkexiyaPickupSkill02Instruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayAkexiyaPickupSkill02Instruction: SkillPreviewBaseInstruction
SkillPreviewPlayAkexiyaPickupSkill02Instruction = SkillPreviewPlayAkexiyaPickupSkill02Instruction

function SkillPreviewPlayAkexiyaPickupSkill02Instruction:Constructor(params)
    self._trapID = tonumber(params.trapID)
    self._forceMovementIndex = tonumber(params.forceMovementIndex)
end

---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayAkexiyaPickupSkill02Instruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = previewContext:GetWorld()

    -- 好孩子不要学，阿克希亚的需求比较特殊
    local activeSkillID = casterEntity:SkillInfo():GetActiveSkillID()
    ---@type ConfigService
    local configService = world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, casterEntity)
    local pickUpValidScopeList = {}
    local pickUpInvalidScopeList = {}

    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")

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
        if utilData:IsPosListHaveMonster({firstPickup}) then
            if #pickupPosArray == 1 then
                entitySvc:DestroyGhost()

                pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickValidScopeList or {})
                pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.monsterPickInvalidScopeList or {})

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

                table.insert(finalGridList, firstPickup)

                previewActiveSkillService:DoConvert(finalGridList,"Normal", "Dark")
                previewActiveSkillService:DestroyPickUpArrow()
                previewActiveSkillService:ShowFourPickUpArrow(false, firstPickup)
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
        else
            previewActiveSkillService:DestroyPickUpArrow()

            if #pickupPosArray == 1 then
                entitySvc:DestroyGhost()

                pickUpValidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickValidScopeList or {})
                pickUpInvalidScopeList = self:_ParseScopeList(skillConfigData._pickUpParam.trapPickInvalidScopeList or {})

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

                table.insert(finalGridList, pickupPosArray[1])

                previewActiveSkillService:DoConvert(finalGridList,"Normal", "Dark")
            else
                entitySvc:DestroyGhost()
                YIELD(TT)

                local ghostTemplateEntity
                local tTrapEntities = utilData:GetTrapsAtPos(firstPickup)
                for _, e in ipairs(tTrapEntities) do
                    if e:TrapID():GetTrapID() == self._trapID then
                        ghostTemplateEntity = e
                        break
                    end
                end

                if ghostTemplateEntity then
                    entitySvc:CreateGhost(pickupPosArray[2], ghostTemplateEntity, "AtkUltPreview")
                end
            end
        end
    end
end

---@param result SkillEffectResult_ForceMovement
function SkillPreviewPlayAkexiyaPickupSkill02Instruction:_DoForceMovementPresentation(TT, world, result)
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
function SkillPreviewPlayAkexiyaPickupSkill02Instruction:_DoSingleTarget(TT, world, info, entity)
    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    local entitySvc = world:GetService("RenderEntity")

    local ghostEntity = entitySvc:CreateGhost(info.v2OldPos, entity,"AtkUltPreview")

    ghostEntity:AddGridMove(BattleConst.ForceMovementPreviewSpeed, info.v2NewPos, info.v2OldPos)
    -- 使用GridMove实现表现，但需要等待所有牵引结束，需要启动监工协程
    -- GridMove有独立的系统负责计算实际的位移，所以没有计算时间
    return GameGlobal.TaskManager():CoreGameStartTask(self._IsMoveFinished, self, ghostEntity)
end

function SkillPreviewPlayAkexiyaPickupSkill02Instruction:_IsMoveFinished(TT, entity)
    return not entity:HasGridMove()
end

function SkillPreviewPlayAkexiyaPickupSkill02Instruction:_ParseScopeList(list)
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
