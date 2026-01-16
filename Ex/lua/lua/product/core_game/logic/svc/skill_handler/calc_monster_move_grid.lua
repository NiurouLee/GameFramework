--[[
    MonsterMoveGrid = 123,
]]

_class("SkillEffectCalc_MonsterMoveGrid", Object)
---@class SkillEffectCalc_MonsterMoveGrid: Object
SkillEffectCalc_MonsterMoveGrid = SkillEffectCalc_MonsterMoveGrid

function SkillEffectCalc_MonsterMoveGrid:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveGrid:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type SkillEffectMonsterMoveGridParam
    local param = skillEffectCalcParam.skillEffectParam
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local movePath,pieceType  = utilCalcSvc:GetMonsterMove2PlayerNearestPath(casterEntity,param:IsEnableAnyPiece())
    local isCasterDead = false
    ---@type MonsterMoveGridResult[]
    local posWalkResultList = {}
    if pieceType then
        local oldPosList = {}
        for i, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterMoveGridResult
            local walkRes = MonsterMoveGridResult:New()

            sBoard:UpdateEntityBlockFlag(casterEntity, posSelf, pos)
            casterEntity:SetGridPosition(pos)
            casterEntity:SetGridDirection(pos - posSelf)

            local entityID = casterEntity:GetID()
            table.insert(posWalkResultList,walkRes)
            walkRes:SetWalkPos(pos)
            ---处理到达一个格子的处理
            self:_OnArrivePos(casterEntity,walkRes)
            table.insert(oldPosList,pos)
            if casterEntity:HasDeadMark() then
                isCasterDead = true
                break
            end
        end
        local newPosList = sBoard:SupplyPieceList(oldPosList)
        ---@type Entity
        local boardEntity = self._world:GetBoardEntity()
        ---@type BoardComponent
        local boardCmpt = boardEntity:Board()
        boardCmpt:FillPieces(newPosList)
        for i, walkRes in ipairs(posWalkResultList) do
            local newPos = newPosList[i]
            walkRes:SetNewGridType(newPos.color)
        end
    end
    local result = SkillEffectMonsterMoveGridResult:New(posWalkResultList,isCasterDead)
    return { result }
end
function SkillEffectCalc_MonsterMoveGrid:_OnArrivePos(casterEntity,walkRes)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local pos = casterEntity:GetGridPosition()


    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(casterEntity, TrapTriggerOrigin.MonsterGridMove)
    for i, e in ipairs(listTrapWork) do
        ---@type Entity
        local trapEntity = e
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = listTrapResult[i]
        local aiResult = AISkillResult:New()
        aiResult:SetResultContainer(skillEffectResultContainer)
        walkRes:AddWalkTrap(trapEntity:GetID(), aiResult)
    end

    local nTrapCount = table.count(listTrapWork)

    ----本次移动经过的格子
    --local passGrids = {}
    --local isDuplicate = function(pos)
    --    for _, value in ipairs(passGrids) do
    --        if value.x == pos.x and value.y == pos.y then
    --            return true
    --        end
    --    end
    --    return false
    --end
    --local bodyArea = casterEntity:BodyArea():GetArea()
    --local dir = casterEntity:GridLocation():GetGridDir()
    --local curPos = casterEntity:GetGridPosition()
    --for _, value in ipairs(bodyArea) do
    --    local pos = curPos + value - dir
    --    if not isDuplicate(pos) then
    --        passGrids[#passGrids + 1] = pos
    --    end
    --end
    --
    --
    --walkRes:SetWalkPassedGrid(passGrids)
end

