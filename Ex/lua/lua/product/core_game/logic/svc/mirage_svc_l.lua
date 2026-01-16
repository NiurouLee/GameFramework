--[[------------------------------------------------------------------------------------------

    MirageServiceLogic : 幻境逻辑服务
]]
   --------------------------------------------------------------------------------------------

_class("MirageServiceLogic", BaseService)
---@class MirageServiceLogic: BaseService
MirageServiceLogic = MirageServiceLogic

function MirageServiceLogic:GetMirageComponent()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type MirageComponent
    local mirageCmpt = boardEntity:Mirage()

    return mirageCmpt
end

function MirageServiceLogic:SetMirageOver()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    boardEntity:ReplaceMirage()
end

function MirageServiceLogic:SetMirageOpen()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    mirageCmpt:SetMirageOpenState(true)
end

function MirageServiceLogic:IsMirageOpen()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    return mirageCmpt:IsMirageOpen()
end

function MirageServiceLogic:SetMirageForceClose()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    mirageCmpt:SetMirageForceClose(true)
end

function MirageServiceLogic:IsMirageForceClose()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    return mirageCmpt:IsMirageForceClose()
end

function MirageServiceLogic:SetTrapRefreshID(refreshID)
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    mirageCmpt:SetTrapRefreshID(refreshID)
end

function MirageServiceLogic:SetMirageTrapInheritAttributes(attributes)
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    mirageCmpt:SetMirageTrapInheritAttributes(attributes)
end

function MirageServiceLogic:SetMirageBossEntityID(bossEntityID)
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    mirageCmpt:SetMirageBossEntityID(bossEntityID)
end

function MirageServiceLogic:DoMirageCreateTraps()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    local trapRefreshID = mirageCmpt:GetTrapRefreshID()

    ---@type LevelMonsterRefreshParam
    local refreshParam = LevelMonsterRefreshParam:New(self._world)

    ----@type TrapTransformParam[]
    local trapInternalIDList = {}
    if trapRefreshID > 0 then
        local trapRefCfg = Cfg.cfg_refresh_trap[trapRefreshID]
        if not trapRefCfg then
            Log.fatal("MirageServiceLogic:CreateTraps Not Find Trap Refresh ID:", trapRefreshID)
        end
        trapInternalIDList = table.cloneconf(refreshParam:ParseTrapRefreshParam(trapRefCfg))
    end

    ---@type LogicEntityService
    local entitySvc = self._world:GetService("LogicEntity")
    local inheritAttributes = mirageCmpt:GetMirageTrapInheritAttributes()
    local trapPosTable, eTraps = entitySvc:CreateWaveRefreshTraps(trapInternalIDList, inheritAttributes)
    return eTraps
end

---玩家移动
function MirageServiceLogic:DoMirageCalculateTeamMove()
    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    local movePos = mirageCmpt:GetMovePos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if not teamEntity then
        return
    end

    ---@type MirageWalkResult
    local mirageWalkRes = MirageWalkResult:New()

    local lastPos = teamEntity:GetGridPosition()

    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")

    local newDirection = movePos - lastPos
    --设置坐标和朝向
    local pets = teamEntity:Team():GetTeamPetEntities()
    for _, entityPet in ipairs(pets) do
        entityPet:SetGridLocation(movePos, newDirection)
        entityPet:GridLocation():SetMoveLastPosition(movePos)
    end
    teamEntity:SetGridLocation(movePos, newDirection)
    teamEntity:GridLocation():SetMoveLastPosition(movePos)
    mirageWalkRes:SetWalkPos(movePos)

    --更新阻挡
    sBoard:UpdateEntityBlockFlag(teamEntity, lastPos, movePos)

    --更新原格子颜色
    local pieceColor = sBoard:SupplyPieceList({ lastPos })[1].color
    sBoard:SetPieceTypeLogic(pieceColor, lastPos)
    mirageWalkRes:SetOldPosColor(pieceColor)

    --玩家脚下设置灰色
    local colorNew = sBoard:GetPieceType(movePos)
    if sBoard:GetCanConvertGridElement(movePos) then
        colorNew = PieceType.None
    end
    sBoard:SetPieceTypeLogic(colorNew, movePos)
    mirageWalkRes:SetNewPosColor(colorNew)

    --触发机关
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(teamEntity, TrapTriggerOrigin.Move)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)

        mirageWalkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    mirageCmpt:SetWalkResult(mirageWalkRes)

    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RMirageWalkData(mirageWalkRes)
end

function MirageServiceLogic:DoMirageCastTrapSkill()
    local traps = {}
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")

    ---@type Group
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for i, e in ipairs(group:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        local trapType = trapCmpt:GetTrapType()
        if trapType == TrapType.MirageTrap and not e:HasDeadMark() then
            local skillID = trapCmpt:GetMoveSkillID()
            if skillID and skillID > 0 then
                skillLogicService:CalcSkillEffect(e, skillID)
                skillLogicService:UpdateRenderSkillRoutine(e)
                traps[#traps + 1] = e
            end
        end
    end

    return traps
end

function MirageServiceLogic:DoMirageCastTrapWarningSkill()
    local traps = {}
    local warningPosList = {}
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")

    ---@type Group
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for i, e in ipairs(group:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        local trapType = trapCmpt:GetTrapType()
        if trapType == TrapType.MirageTrap and not e:HasDeadMark() then
            local skillID = trapCmpt:GetWarningSkillID()
            if skillID and skillID > 0 then
                skillLogicService:CalcSkillEffect(e, skillID)

                --存储预警范围
                ---@type SkillEffectResultContainer
                local skillEffectResultContainer = e:SkillContext():GetResultContainer()
                ---@type SkillEffectResult_ShowWarningArea
                local effectResult = skillEffectResultContainer:GetEffectResultByArray(SkillEffectType.ShowWarningArea)
                if effectResult then
                    local posList = effectResult:GetWarningPosList()
                    table.appendArray(warningPosList, posList)
                end

                --更新
                skillLogicService:UpdateRenderSkillRoutine(e)
                traps[#traps + 1] = e
            end
        end
    end

    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RMirageWarningData(warningPosList)

    return traps
end

function MirageServiceLogic:DoMirageCastTrapDieSkill()
    local traps = {}
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")

    ---@type Group
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for i, e in ipairs(group:GetEntities()) do
        ---@type TrapComponent
        local trapCmpt = e:Trap()
        local trapType = trapCmpt:GetTrapType()
        if trapType == TrapType.MirageTrap and not e:HasDeadMark() then
            local skillID = trapCmpt:GetDieSkillID()
            if skillID and skillID > 0 then
                skillLogicService:CalcSkillEffect(e, skillID)
                skillLogicService:UpdateRenderSkillRoutine(e)
                traps[#traps + 1] = e
            end
        end
    end

    return traps
end

function MirageServiceLogic:DoMirageBossReturn()
    ---@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")

    ---@type MirageComponent
    local mirageCmpt = self:GetMirageComponent()
    local bossEntityID = mirageCmpt:GetMirageBossEntityID()

    ---@type Entity
    local bossEntity = self._world:GetEntityByID(bossEntityID)
    if bossEntity then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local skillID = utilDataSvc:GetMonsterBackSkill(bossEntity)
        if skillID and skillID > 0 then
            skillLogicService:CalcSkillEffect(bossEntity, skillID)
            skillLogicService:UpdateRenderSkillRoutine(bossEntity)
        end
    end

    return bossEntity
end
