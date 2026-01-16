--[[
    MonsterMoveGridByMonsterElement = 141, --怪物按照属性选择一条跟属性相同颜色的最短可行走路线。
]]

_class("SkillEffectCalc_MonsterMoveGridByElement", Object)
---@class SkillEffectCalc_MonsterMoveGridByElement: Object
SkillEffectCalc_MonsterMoveGridByElement = SkillEffectCalc_MonsterMoveGridByElement

function SkillEffectCalc_MonsterMoveGridByElement:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MonsterMoveGridByElement:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    local targetID = false
    if table.count(targetIDList) >= 1 then
        targetID = targetIDList[1]
    end
    if not targetID or targetID == -1  then
        Log.fatal("Need Target SkillID",skillEffectCalcParam:GetSkillID())
    end
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type BoardServiceLogic
    local sBoard = self._world:GetService("BoardLogic")
    local element = casterEntity:Element():GetPrimaryType()
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)
    local movePath = {}
    if not targetEntity:HasDeadMark() then
        movePath  = utilCalcSvc:GetMonster2TargetNearestPathByElement(casterEntity,targetID,element)
    end
    local isCasterDead = false
    ---@type MonsterWalkResult[]
    local posWalkResultList = {}
    if #movePath ~=0 then
        local oldPosList = {}
        for i, pos in ipairs(movePath) do
            local posSelf = casterEntity:GetGridPosition()
            ---@type MonsterWalkResult
            local walkRes = MonsterWalkResult:New()

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
    end
    local result = SkillEffectMonsterMoveGridByElementResult:New(posWalkResultList,isCasterDead)
    return { result }
end
---@param walkRes MonsterWalkResult
function SkillEffectCalc_MonsterMoveGridByElement:_OnArrivePos(casterEntity,walkRes)

    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local pos = casterEntity:GetGridPosition()


    local listTrapWork, listTrapResult = trapServiceLogic:TriggerTrapByEntity(casterEntity, TrapTriggerOrigin.ChessMonsterGridMoveByElement)
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

