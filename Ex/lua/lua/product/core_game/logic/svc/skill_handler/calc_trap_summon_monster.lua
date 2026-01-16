--[[
    TrapSummonMonsterType = 163, --召唤机关在自己上面召唤怪物
]]
---@class SkillEffectCalcTrapSummonMonster: Object
_class("SkillEffectCalcTrapSummonMonster", Object)
SkillEffectCalcTrapSummonMonster = SkillEffectCalcTrapSummonMonster

function SkillEffectCalcTrapSummonMonster:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcTrapSummonMonster
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
    ---@type ConfigServiceHelper
    self._configService = self._world:GetService("Config")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalcTrapSummonMonster:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}
    ---@type SkillEffectTrapSummonMonsterParam
    local param = skillEffectCalcParam.skillEffectParam
    local casterID = skillEffectCalcParam.casterEntityID
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(casterID)
    local type =param:GetSummonType()
    local monsterIDList = param:GetMonsterIDList()
    local delay = param:GetDelay()
    ---@type AttributesComponent
    local attCpt = casterEntity:Attributes()
    local curRound = self._world:BattleStat():GetLevelTotalRoundCount()
    local trapBeginCastRound = attCpt:GetAttribute("TrapBeginCastRound")
    ---@type TrapComponent
    local trapCmpt = casterEntity:Trap()
    local bornRound =trapCmpt:GetTrapBornRound()
    local interval = param:GetInterval()
    local trapOpenState = attCpt:GetAttribute("OpenState")
    if not trapBeginCastRound then
        trapBeginCastRound = curRound
        attCpt:SetSimpleAttribute("TrapBeginCastRound",curRound)
    end
    ---@type SkillEffectTrapSummonMonsterResult
    local result = SkillEffectTrapSummonMonsterResult:New()
    local summonMonsterIndex = attCpt:GetAttribute("TrapNextMonsterIndex")
    local summonDone = attCpt:GetAttribute("TrapSummonDone")
    local canSummon = true
    local summonRound =attCpt:GetAttribute("TrapNextSummonMonsterRound")
    if delay ~= 0 then
        ---在开始能召唤回合前一回合如果是关闭状态，要播放打开动画
        if delay + bornRound == curRound +1 and trapOpenState==0  then
            result:SetTrapOpenStateChange(true)
            attCpt:Modify("OpenState",1)
            result:SetTrapOpenState(1)
            local res = DataAttributeResult:New(casterID, "OpenState", 1)
            self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
            goto Over
        end
        if (curRound-bornRound) < delay then
            goto Over
        end
    end
    if not summonMonsterIndex then
        summonMonsterIndex = 1
    end
    ---召唤完毕了就永久gg
    if summonDone and summonDone==1  then
        goto Over
    end
    ---位置被占用不能召唤
    if not  self:IsCasterPosBlock(casterEntity,summonMonsterIndex,monsterIDList,type) then
        canSummon = false
    end
    ---没有的话初始化一下
    if not summonRound then
        summonRound = curRound
    end
    ---间隔召唤后在召唤前一回合会打开机关播放表现
    if summonRound == curRound+1 then
        result:SetTrapOpenStateChange(true)
        attCpt:Modify("OpenState",1)
        result:SetTrapOpenState(1)
        local res = DataAttributeResult:New(casterID, "OpenState", 1)
        self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
        goto Over
    end
    if summonRound >curRound then
        goto Over
    end

    ---设置下一次召唤回合
    if canSummon then
        summonRound = summonRound + interval+1
        attCpt:SetSimpleAttribute("TrapNextSummonMonsterRound",summonRound)
    else
        goto Over
    end
    if type == TrapSummonMonsterType.SequenceType then
        if summonMonsterIndex + 1 > #monsterIDList then
            ---设置下召唤完毕标记
            attCpt:SetSimpleAttribute("TrapSummonDone", 1)
        end
    elseif type == TrapSummonMonsterType.CycleType then
        if summonMonsterIndex > #monsterIDList then
            summonMonsterIndex = 1
        end
    end
    if canSummon then
        local monsterID = monsterIDList[summonMonsterIndex]
        result = self:SummonMonster(casterEntity,monsterID)
        attCpt:SetSimpleAttribute("TrapNextMonsterIndex",summonMonsterIndex+1)
        if interval >0 then
            result:SetTrapOpenStateChange(true)
            attCpt:Modify("OpenState",0)
            result:SetTrapOpenState(0)
            local res = DataAttributeResult:New(casterID, "OpenState", 0)
            self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
        end
    end
    ::Over::
    return { result }
end

function SkillEffectCalcTrapSummonMonster:IsCasterPosBlock(casterEntity,summonMonsterIndex,monsterIDList,type)
    ---@type BodyAreaComponent
    local bodyAreCpt = casterEntity:BodyArea()
    local casterPos = casterEntity:GetGridPosition()
    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    if summonMonsterIndex>#monsterIDList and type == TrapSummonMonsterType.CycleType then
        summonMonsterIndex = 1
    end
    local monsterID = monsterIDList[summonMonsterIndex]
    if not monsterID then
        return false
    end
    local monsterRaceType = monsterConfigData:GetMonsterRaceType(monsterID)

    local blockFlag
    if monsterRaceType== MonsterRaceType.Fly then
        blockFlag = BlockFlag.MonsterFly
    elseif monsterRaceType== MonsterRaceType.Land then
        blockFlag = BlockFlag.MonsterLand
    end
    ---@type Vector2[]
    local bodyArea =bodyAreCpt:GetArea()
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    for i, pos in ipairs(bodyArea) do
        local newPos = pos+ casterPos
        if boardSvc:IsPosBlock(newPos,blockFlag) then
            return false
        end
    end
    return true
end

---@param casterEntity Entity
function SkillEffectCalcTrapSummonMonster:SummonMonster(casterEntity,monsterID)
    ---@type BodyAreaComponent
    local bodyAreCpt = casterEntity:BodyArea()
    ---@type MonsterCreationServiceLogic
    local monsterCreationSvc = self._world:GetService("MonsterCreationLogic")
    ---@type MonsterTransformParam
    local monsterTransformParam = MonsterTransformParam:New(monsterID)
    local casterPos = casterEntity:GetGridPosition()
    local casterDir = casterEntity:GetGridDirection()

    monsterTransformParam:SetPosition(casterPos)
    monsterTransformParam:SetForward(casterDir)
    monsterTransformParam:SetRotation(casterDir)
    local monsterEntity= monsterCreationSvc:CreateMonster(monsterTransformParam)
    monsterEntity:AddSummoner(casterEntity:GetID())
    ---@type SkillEffectTrapSummonMonsterResult
    local result = SkillEffectTrapSummonMonsterResult:New(monsterEntity:GetID())
    result:SetMonsterTransformParam(monsterTransformParam)
    return result
end
