--[[
    SnakeHeadMove = 11, --贪吃蛇身体移动和增长
]]
---@class SkillEffectCalc_SnakeTailMove: Object
_class("SkillEffectCalc_SnakeTailMove", Object)
SkillEffectCalc_SnakeTailMove = SkillEffectCalc_SnakeTailMove

function SkillEffectCalc_SnakeTailMove:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type MonsterShowLogicService
    self._monsterShowLogic = self._world:GetService("MonsterShowLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SnakeTailMove:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterID = skillEffectCalcParam.casterEntityID
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SkillEffectParamSnakeTailMove
    local effectParam = skillEffectCalcParam.skillEffectParam
    ---@type SnakeMoveType
    local snakeMoveType = effectParam:GetMoveType()

    local bodyMonsterID = effectParam:GetBodyMonsterID()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type ShareSkillResultComponent
    local shareResultCmpt =boardEntity:ShareSkillResult()
    local bodyEntityList = utilDataSvc:FindMonsterByMonsterID(bodyMonsterID)
    ---@type  Entity
    local bodyEntity = bodyEntityList[1]
    if bodyEntity:HasDeadMark() then
        casterEntity:Attributes():Modify("HP", 0)
        self._monsterShowLogic:AddMonsterDeadMark(casterEntity)
        Log.debug("SnakeTailDead ModifyHP =0 defender=", casterEntity:GetID())
        local result = SkillEffectSnakeTailMoveResult:New(nil,true)
        return result
    end
    local resultContainer = shareResultCmpt:GetResultContainerByEntityID(bodyEntity:GetID())

    ---@type table<number, SkillEffectSnakeBodyMoveAndGrowthResult>
    local resultArray = resultContainer:GetEffectResultsAsArray(SkillEffectType.SnakeBodyMoveAndGrowth)
    Log.fatal("SnakeBodyMoveResultCount:",#resultArray)
    ---@type  SkillEffectSnakeBodyMoveAndGrowthResult
    local bodyMoveAndGrowthResult = resultArray[#resultArray]
    if bodyMoveAndGrowthResult:IsCasterDead() then
        casterEntity:Attributes():Modify("HP", 0)
        self._monsterShowLogic:AddMonsterDeadMark(casterEntity)
        Log.debug("SnakeTailDead ModifyHP =0 defender=", casterEntity:GetID())
        local result = SkillEffectSnakeTailMoveResult:New(nil,bodyMoveAndGrowthResult:IsCasterDead())
        return result
    end
    local newBodyPos = bodyMoveAndGrowthResult:GetNewBodyPos()
    ---@type SkillEffectSnakeTailMoveResult
    local result
    if not newBodyPos then
        local oldBodyArea = bodyMoveAndGrowthResult:GetOldBodyArea()
        local newBodyArea = bodyMoveAndGrowthResult:GetNewBodyArea()
        local oldBodyPos = bodyMoveAndGrowthResult:GetBodyOldPos()
        local bodyNewPos = bodyMoveAndGrowthResult:GetBodyNewPos()
        local tailPos = oldBodyArea[#oldBodyArea] + oldBodyPos
        Log.fatal("SnakeNewTailPos:",tailPos)
        local lastBodyPos = newBodyArea[#newBodyArea] + bodyNewPos
        Log.fatal("SnakeBodyLastPos:",lastBodyPos)
        result = SkillEffectSnakeTailMoveResult:New(tailPos,bodyMoveAndGrowthResult:IsCasterDead())
        result:SetLastBodyPos(lastBodyPos)
    else
        Log.fatal("SnakeNewTailPos:Nil","newBodyPos:",newBodyPos)
        result = SkillEffectSnakeTailMoveResult:New(nil,bodyMoveAndGrowthResult:IsCasterDead())
    end
    return result
end