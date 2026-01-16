--[[
    SnakeHeadMove = 11, --贪吃蛇身体移动和增长
]]
---@class SkillEffectCalc_SnakeBodyMoveAndGrowth: Object
_class("SkillEffectCalc_SnakeBodyMoveAndGrowth", Object)
SkillEffectCalc_SnakeBodyMoveAndGrowth = SkillEffectCalc_SnakeBodyMoveAndGrowth

function SkillEffectCalc_SnakeBodyMoveAndGrowth:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    ---@type MonsterShowLogicService
    self._monsterShowLogic = self._world:GetService("MonsterShowLogic")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SnakeBodyMoveAndGrowth:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterID = skillEffectCalcParam.casterEntityID
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SkillEffectParamSnakeBodyMoveAndGrowth
    local effectParam = skillEffectCalcParam.skillEffectParam
    ---@type SnakeMoveType
    local snakeMoveType = effectParam:GetMoveType()

    local headMonsterID = effectParam:GetHeadMonsterID()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local headEntityList = utilDataSvc:FindMonsterByMonsterID(headMonsterID)
    ---@type  Entity
    local headEntity = headEntityList[1]
    local headEntityID = headEntity:GetID()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type ShareSkillResultComponent
    local shareResultCmpt =boardEntity:ShareSkillResult()
    local resultContainer = shareResultCmpt:GetResultContainerByEntityID(headEntity:GetID())

    if headEntity:HasDeadMark() then
        casterEntity:Attributes():Modify("HP", 0)
        self._monsterShowLogic:AddMonsterDeadMark(casterEntity)
        Log.debug("SnakeBodyDead ModifyHP =0 defender=", casterEntity:GetID())
        ---@type SkillEffectSnakeBodyMoveAndGrowthResult
        local result = SkillEffectSnakeBodyMoveAndGrowthResult:New()
        result._casterIsDead = true
        shareResultCmpt:AddEntityResult(casterID,result)
        return result
    end
        ---@type table<number, SkillEffectSnakeHeadMoveResult>
    local resultArray = resultContainer:GetEffectResultsAsArray(SkillEffectType.SnakeHeadMove)

    Log.fatal("SnakeHeadMoveResultCount:",#resultArray)

    ---@type  SkillEffectSnakeHeadMoveResult
    local headMoveResult = resultArray[#resultArray]
    if not headMoveResult:GetCasterIsDead() then
        ---@type AttributesComponent
        local attrCmpt = casterEntity:Attributes()
        local curHP =attrCmpt:GetCurrentHP()
        local maxHP = attrCmpt:CalcMaxHp()

        if curHP<maxHP then
            casterEntity:Attributes():Modify("HP", maxHP)
        end
        local headNewPos = headMoveResult:GetNewPos()
        local bodyNewPos = headMoveResult:GetOldPos()
        local oldBodyArea = casterEntity:BodyArea():GetArea()
        local bodyOldPos = casterEntity:GetGridPosition()
        local newBodyArea,newBodyPos = self:ChangeBodyArea(oldBodyArea,bodyNewPos,bodyOldPos,snakeMoveType)
        ---@type SkillEffectSnakeBodyMoveAndGrowthResult
        local result = SkillEffectSnakeBodyMoveAndGrowthResult:New(bodyOldPos,bodyNewPos,oldBodyArea,newBodyArea,newBodyPos)
        result:SetHeadNewPos(headNewPos)
        shareResultCmpt:AddEntityResult(casterID,result)
        return result
    else
        casterEntity:Attributes():Modify("HP", 0)
        self._monsterShowLogic:AddMonsterDeadMark(casterEntity)
        Log.debug("SnakeBodyDead ModifyHP =0 defender=", casterEntity:GetID())
        ---@type SkillEffectSnakeBodyMoveAndGrowthResult
        local result = SkillEffectSnakeBodyMoveAndGrowthResult:New()
        result._casterIsDead = true
        shareResultCmpt:AddEntityResult(casterID,result)
        return result
    end
end

function SkillEffectCalc_SnakeBodyMoveAndGrowth:ChangeBodyArea(oldBodyArea,bodyNewPos,bodyOldPos,snakeMoveType)
    Log.fatal("OldPos:",bodyOldPos,"NewPos:",bodyNewPos)
    local newBodyArea = {Vector2(0,0)}
    for i, v in ipairs(oldBodyArea) do
        if i~= #oldBodyArea then
            local offset = v+ bodyOldPos
            local area = offset-bodyNewPos
            Log.fatal("Index:",i,"Offset:",offset,"Area:",area)
            table.insert(newBodyArea,area)
        end
    end
    local newBodyPos
    if snakeMoveType == SnakeMoveType.Growth then
        local offset = oldBodyArea[#oldBodyArea]+ bodyOldPos
        local area = offset-bodyNewPos
        newBodyPos = offset
        Log.fatal("Growth Offset:",offset,"Area:",area)
        table.insert(newBodyArea,area)
    end
    return newBodyArea,newBodyPos
end