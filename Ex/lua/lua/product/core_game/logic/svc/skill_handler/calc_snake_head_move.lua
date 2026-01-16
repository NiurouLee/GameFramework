--[[
    SnakeHeadMove = 11, --召唤机关
]]
---@class SkillEffectCalc_SnakeHeadMove: Object
_class("SkillEffectCalc_SnakeHeadMove", Object)
SkillEffectCalc_SnakeHeadMove = SkillEffectCalc_SnakeHeadMove

function SkillEffectCalc_SnakeHeadMove:Constructor(world)
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
function SkillEffectCalc_SnakeHeadMove:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterID = skillEffectCalcParam.casterEntityID
    local targetIDList =skillEffectCalcParam.targetEntityIDs
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SkillEffectParamSnakeHeadMove
    local effectParam = skillEffectCalcParam.skillEffectParam
    ---@type SnakeMoveType
    local snakeMoveType = effectParam:GetHeadMoveType()

    local tailMonsterID = effectParam:GetTailMonsterID()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type ShareSkillResultComponent
    local shareResultCmpt =boardEntity:ShareSkillResult()
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local tailEntityList = utilDataSvc:FindMonsterByMonsterID(tailMonsterID)
    ---@type  Entity
    local tailEntity = tailEntityList[1]
    ---@type Vector2
    local ignorePos = nil
    if snakeMoveType == SnakeMoveType.Move then
        ignorePos = tailEntity:GetGridPosition()
    end
    local result
    if snakeMoveType~= SnakeMoveType.Attack then
        ---@type UtilCalcServiceShare
        local utilCalcSvc = self._world:GetService("UtilCalc")
        local retPath = utilCalcSvc:SnakeFindPathMove2PlayerNearestPath(casterEntity,ignorePos)
        if #retPath ~= 0 then
            local  pos = retPath[1]
            result = SkillEffectSnakeHeadMoveResult:New(pos,casterPos,false)
        else
            local casterDir = casterEntity:GetGridDirection()
            local offset = {}
            if casterDir == Vector2(0,1) then
                offset = {Vector2(0,1),Vector2(1,0),Vector2(-1,0)}
            elseif casterDir == Vector2(0,-1) then
                offset = {Vector2(0,-1),Vector2(1,0),Vector2(-1,0)}
            elseif casterDir == Vector2(1,0) then
                offset = {Vector2(0,1),Vector2(1,0),Vector2(0,-1)}
            elseif casterDir == Vector2(-1,0) then
                offset = {Vector2(0,1),Vector2(-1,0),Vector2(0,-1)}
            end
            local posList ={}
            for i, v in ipairs(offset) do
                local offSetPos = Vector2(casterPos.x+v.x,v.y+casterPos.y)
                if utilCalcSvc:SnakeHeadCheckBlock(offSetPos,ignorePos) then
                    table.insert(posList,offSetPos)
                end
            end
            if #posList > 0 then
                local tailPos =  tailEntity:GetGridPosition()
                table.sort(posList,function( a,b)
                    local disA = Vector2.Distance(a,tailPos)
                    local disB = Vector2.Distance(b,tailPos)
                    return disA> disB
                end)
                local pos = posList[1]
                result = SkillEffectSnakeHeadMoveResult:New(pos,casterPos,false)
            else
                if casterEntity:HasMonsterID() then
                    casterEntity:Attributes():Modify("HP", 0)
                    self._monsterShowLogic:AddMonsterDeadMark(casterEntity)
                    Log.debug("SnakeHeadDead ModifyHP =0 defender=", casterEntity:GetID())
                    result = SkillEffectSnakeHeadMoveResult:New(nil,casterPos,true)
                end
            end
        end
    else
        local targetID = targetIDList[1]
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)
        local pos = targetEntity:GetGridPosition()
        result = SkillEffectSnakeHeadMoveResult:New(pos,casterPos,false)
    end
    shareResultCmpt:AddEntityResult(casterID,result)
    return result
end