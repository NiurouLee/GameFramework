require("notify_type")
require("echo")

AutoTestCheckResult = {
    NotTriggered = 1, --未触发
    CheckFailed = 2, --失败
    CheckPassed = 3 --通过
}

local transTable = {
    [0] = "立即检查",
    [3] = "怪物回合开始",
    [4] = "怪物回合结束",
    [6] = "怪物死亡",
    [9] = "玩家回合开始",
    [10] = "玩家回合结束",
    [13] = "普攻每次攻击前",
    [14] = "普通每次攻击后",
    [15] = "怪物每次攻击前",
    [16] = "怪物每次攻击后",
    [17] = "连锁技每次攻击前",
    [18] = "连锁技每次攻击后",
    [19] = "主动技每次攻击前",
    [20] = "主动技每次攻击后",
    [25] = "全体普攻开始前",
    [26] = "全体普攻结束后",
    [70] = "全体连锁技开始前",
    [71] = "全体连锁技接受后",
    [27] = "单人连锁技开始前",
    [28] = "单人连锁技结束后",
    [29] = "主动技开始前",
    [30] = "主动技结束后",
    [46] = "场上出现水格子",
    [71] = "所有连锁技结束",
    [73] = "场上出现转色",
    [88] = "下次输入",
    [89] = "二次连锁技结束"
}

AutoTestCheckNotifier = {}
for k, v in pairs(NotifyType) do
    local key = " "
    if v < 10 then
        key = key .. "00"
    elseif v < 100 then
        key = key .. "0"
    end
    if transTable[v] then
        key = key .. v .. " " .. transTable[v]
    else
        key = key .. v .. " " .. k
    end
    AutoTestCheckNotifier[key] = v
end

CompareFuncMap = {
    ["<"] = function(a, b)
        return a < b
    end,
    [">"] = function(a, b)
        return a > b
    end,
    ["<="] = function(a, b)
        return a <= b
    end,
    [">="] = function(a, b)
        return a >= b
    end,
    ["=="] = function(a, b)
        return a == b
    end,
    ["!="] = function(a, b)
        return a ~= b
    end,
    ["~="] = function(a, b)
        return a ~= b
    end
}

require("trigger_owner")

_class("AutoTestCheckPointBase", ITriggerOwner)
AutoTestCheckPointBase = AutoTestCheckPointBase

function AutoTestCheckPointBase:Constructor(e, args, world)
    self._entity = e
    self._args = args
    self._world = world
    self._result = AutoTestCheckResult.NotTriggered
    self._msghead = " entity=" .. (args.name or "team") .. " "
    self._message = " "
    self:BeforeCheck()
end

function AutoTestCheckPointBase:OnTrigger(notify)
    local ret = self:Check(notify)
    if ret then
        self._result = AutoTestCheckResult.CheckPassed
        --已经通过就取消注册
        self._world:GetService("AutoTest"):DetachCheckPassedPoints_Test()
    else
        self._result = AutoTestCheckResult.CheckFailed
    end
end

function AutoTestCheckPointBase:CollectResult()
    return {
        actionName = self._className,
        result = self._result,
        message = self._msghead .. self._message
    }
end

function AutoTestCheckPointBase:BeforeCheck()
    Log.error("BeforeCheck() not implemented!!")
end

function AutoTestCheckPointBase:Check(notify)
    Log.error("Check() not implemented!!")
end

--检查血量变化
_class("CheckEntityChangeHP_Test", AutoTestCheckPointBase)
CheckEntityChangeHP_Test = CheckEntityChangeHP_Test

function CheckEntityChangeHP_Test:BeforeCheck()
    self.oldHP = self._entity:Attributes():GetCurrentHP()
end

function CheckEntityChangeHP_Test:Check(notify)
    local newHP = self._entity:Attributes():GetCurrentHP()
    local cmp = self._args.compare
    local f = CompareFuncMap[cmp]

    self._message = " oldHP=" .. self.oldHP .. " newHP=" .. newHP .. " compare:" .. cmp
    if f and f(self.oldHP, newHP) then
        return true
    end
    return false
end

--检查有buffid
_class("CheckEntityHasBuff_Test", AutoTestCheckPointBase)
CheckEntityHasBuff_Test = CheckEntityHasBuff_Test

function CheckEntityHasBuff_Test:BeforeCheck()
end

function CheckEntityHasBuff_Test:Check(notify)
    local inst = self._entity:BuffComponent():GetBuffById(self._args.buffID)
    self._message = " has no buff:" .. self._args.buffID
    if inst then
        return true
    end
    return false
end

--检查buff层数
_class("CheckEntityBuffLayer_Test", AutoTestCheckPointBase)
CheckEntityBuffLayer_Test = CheckEntityBuffLayer_Test

function CheckEntityBuffLayer_Test:BeforeCheck()
end

function CheckEntityBuffLayer_Test:Check(notify)
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layer = svc:GetBuffLayer(self._entity, self._args.layerType)
    self._message = " layerType=" .. self._args.layerType .. " layer=" .. layer .. " expect=" .. self._args.layer
    if layer == self._args.layer then
        return true
    end

    return false
end

--检查战斗数值
_class("CheckMatchLog_Test", AutoTestCheckPointBase)
CheckMatchLog_Test = CheckMatchLog_Test

function CheckMatchLog_Test:BeforeCheck()
end

function CheckMatchLog_Test:Check(notify)
    --local logs = self._world:GetMatchLogger():GetLogs()
end

--检查combo数变化
_class("CheckCombo_Test", AutoTestCheckPointBase)
CheckCombo_Test = CheckCombo_Test

function CheckCombo_Test:BeforeCheck()
    self.old_combo = self._world:GetService("Battle"):GetLogicComboNum()
end

function CheckCombo_Test:Check(notify)
    local combo = self._world:GetService("Battle"):GetLogicComboNum()
    local val = combo - self.old_combo
    self._message = " oldCombo=" .. self.old_combo .. " newCombo=" .. combo
    if val == self._args.change then
        return true
    end
    return false
end

--检查触发二次连锁
_class("CheckDoubleChain_Test", AutoTestCheckPointBase)
CheckDoubleChain_Test = CheckDoubleChain_Test

function CheckDoubleChain_Test:BeforeCheck()
end

function CheckDoubleChain_Test:Check(notify)
    self._message = " double chain notify entity=" .. notify:GetNotifyEntity():GetID()
    if notify:GetNotifyEntity() == self._entity then
        return true
    end

    return false
end

--检查位置
_class("CheckEntityPos_Test", AutoTestCheckPointBase)
CheckEntityPos_Test = CheckEntityPos_Test

function CheckEntityPos_Test:BeforeCheck()
end

function CheckEntityPos_Test:Check(notify)
    local pos1 = self._args.pos
    local pos2 = Vector2.Pos2Index(self._entity:GetGridPosition())
    self._message = "entity pos=" .. pos2
    if pos1 == pos2 then
        return true
    end

    return false
end

--检查格子颜色
_class("CheckPieceType_Test", AutoTestCheckPointBase)
CheckPieceType_Test = CheckPieceType_Test

function CheckPieceType_Test:BeforeCheck()
end

function CheckPieceType_Test:Check(notify)
    local pos = Vector2.Index2Pos(self._args.pos)
    local boardCmpt = self._world:GetBoardEntity():Board()
    local pieceType = boardCmpt:GetPieceType(pos)
    self._message = "pos=" .. self._args.pos .. " pieceType=" .. pieceType
    if pieceType == self._args.pieceType then
        return true
    end
    return false
end

--检查格子上有机关
_class("CheckGridTrap_Test", AutoTestCheckPointBase)
CheckGridTrap_Test = CheckGridTrap_Test

function CheckGridTrap_Test:BeforeCheck()
end

function CheckGridTrap_Test:Check(notify)
    local pos = Vector2.Index2Pos(self._args.pos)
    local exist = self._args.exist
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es = boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return not e:HasDeadMark() and e:HasTrapID() and table.icontains(self._args.trapIds, e:TrapID():GetTrapID())
        end
    )
    self._message = "pos=" .. self._args.pos ..
        " expect trapid=" .. table.concat(self._args.trapIds, " ") ..
        " exist=" .. tostring(exist) .. ' trapCount=' .. #es

    if exist then
        return #es > 0
    else
        return #es == 0
    end

end

--检查血量值
_class("CheckEntityHP_Test", AutoTestCheckPointBase)
CheckEntityHP_Test = CheckEntityHP_Test

function CheckEntityHP_Test:BeforeCheck()
end

function CheckEntityHP_Test:Check(notify)
    local curHP = self._entity:Attributes():GetCurrentHP()
    local tarHP = self._args.hp

    local cmp = self._args.compare
    local f = CompareFuncMap[cmp]

    self._message = " tarHP=" .. tarHP .. " curHP=" .. curHP .. " compare:" .. cmp
    if f and f(tarHP, curHP) then
        return true
    end
    return false
end

--检查目标身上有某种buff
_class("CheckEntityBuff_Test", AutoTestCheckPointBase)
CheckEntityBuff_Test = CheckEntityBuff_Test

function CheckEntityBuff_Test:BeforeCheck()
end

function CheckEntityBuff_Test:Check(notify)
    local exist = self._args.exist
    local buffCmpt = self._entity:BuffComponent()
    if buffCmpt:CheckHaveBuffById(self._args.buffId) then
        return exist
    end
    return not exist
end

--检查目标身上buffvalue
_class("CheckEntityBuffValue_Test", AutoTestCheckPointBase)
CheckEntityBuffValue_Test = CheckEntityBuffValue_Test

function CheckEntityBuffValue_Test:BeforeCheck()
end

function CheckEntityBuffValue_Test:Check(notify)
    local buffCmpt = self._entity:BuffComponent()
    local val = buffCmpt:GetBuffValue(self._args.key) or 0
    local ret = math.abs(val - self._args.value) < 0.001
    self._message = "buff key:" .. self._args.key .. " value:" .. val .. " expect:" .. self._args.value
    if ret then
        return true
    end
    return false
end

--检查场上有某个机关
_class("CheckTrapExist_Test", AutoTestCheckPointBase)
CheckTrapExist_Test = CheckTrapExist_Test

function CheckTrapExist_Test:BeforeCheck()
end

function CheckTrapExist_Test:Check(notify)
    local exist = self._args.exist
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for i, e in ipairs(group:GetEntities()) do
        local trapid = e:TrapID():GetTrapID()
        if table.icontains(self._args.trapIds, trapid) then
            return exist
        end
    end
    return not exist
end

--检查不卡死就行
_class("CheckDump_Test", AutoTestCheckPointBase)
CheckDump_Test = CheckDump_Test

function CheckDump_Test:BeforeCheck()
end

function CheckDump_Test:Check(notify)
    return true
end

--检查关卡胜利/失败
_class("CheckBattleResult_Test", AutoTestCheckPointBase)
CheckBattleResult_Test = CheckBattleResult_Test

function CheckBattleResult_Test:BeforeCheck()
end

---@param notify NTGameOver
function CheckBattleResult_Test:Check(notify)
    local victory = self._args.victory
    local v = notify:GetVictory()
    self._message = " battleResult:" .. v .. " expect:" .. victory
    return v == victory
end

--检查三星条件是否完成
_class("Check3StarComplete_Test", AutoTestCheckPointBase)
Check3StarComplete_Test = Check3StarComplete_Test

function Check3StarComplete_Test:BeforeCheck()
end

function Check3StarComplete_Test:Check(notify)
    ---@type BonusCalcService
    local bonusCalcService = self._world:GetService("BonusCalc")
    ---@type Star3CalcService
    local star3CalcService = self._world:GetService("Star3Calc")
    local conditionParser = ObjectiveConditionParamParser:New()
    local conditionType = self._args.conditionType
    local conditionNumber = self._args.conditionParam
    conditionNumber = string.split(conditionNumber, "|")
    local conditionParam = nil
    if star3CalcService:IsSpecialCondition(conditionType) then
        conditionParam = star3CalcService:GetSpecialConditionData(conditionNumber)
    elseif star3CalcService:IsSpecialTotalCountCondition(conditionType) then
        conditionParam = star3CalcService:GetSpecialConditionTotalData(conditionNumber)
    else
        conditionParam = conditionParser:ParseObjectiveConditionParam(conditionType, conditionNumber)
    end
    local expect = self._args.expect
    local finish = bonusCalcService:CalcCondition(conditionType, conditionParam)
    self._message = " condition " .. conditionType .. " finish=" .. tostring(finish) .. " expect=" .. tostring(expect)
    return finish == expect
end

--检查场上怪物数量
_class("CheckMonsterCount_Test", AutoTestCheckPointBase)
CheckMonsterCount_Test = CheckMonsterCount_Test

function CheckMonsterCount_Test:Check(notify)
    local monsterID = self._args.monsterid
    local expect = self._args.count
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local n = 0
    for i, e in ipairs(group:GetEntities()) do
        if e:MonsterID():GetMonsterID() == monsterID then
            n = n + 1
        end
    end
    self._message = " monsterID=" .. monsterID .. " count=" .. n .. " expect=" .. expect
    return n == expect
end

--检查光灵的队伍位置
_class("CheckTeamOrder_Test", AutoTestCheckPointBase)
CheckTeamOrder_Test = CheckTeamOrder_Test

function CheckTeamOrder_Test:Check(notify)
    ---@type AutoTestService
    local svc = self._world:GetService("AutoTest")
    ---@type Entity
    local e = svc:GetEntityByName_Test(self._args.name)
    local petPstID = e:PetPstID():GetPstID()

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()

    local teamOrder = teamEntity:Team():GetTeamOrder()
    local orderIndex = 0
    for index, value in ipairs(teamOrder) do
        if petPstID == value then
            orderIndex = index
        end
    end

    self._message = " teamOrder=" .. orderIndex .. " expect=" .. self._args.index
    return orderIndex == self._args.index
end

--检查San值
_class("CheckSanValue_Test", AutoTestCheckPointBase)
CheckSanValue_Test = CheckSanValue_Test

function CheckSanValue_Test:BeforeCheck()
end

function CheckSanValue_Test:Check(notify)
    ---@type FeatureServiceLogic
    local featureSvc = self._world:GetService("FeatureLogic")
    if not featureSvc then
        self._message = " Feature Service Logic is nil!"
        return false
    end

    local curSanValue = featureSvc:GetSanValue()
    local expectSanValue = self._args.expect
    local cmp = self._args.compare
    local f = CompareFuncMap[cmp]

    self._message = " San=" .. curSanValue .. " expect=" .. expectSanValue .. " compare:" .. cmp
    if f and f(curSanValue, expectSanValue) then
        return true
    end
    return false
end

--检查昼夜状态
_class("CheckDayNightState_Test", AutoTestCheckPointBase)
CheckDayNightState_Test = CheckDayNightState_Test

function CheckDayNightState_Test:BeforeCheck()
end

function CheckDayNightState_Test:Check(notify)
    ---@type FeatureServiceLogic
    local featureSvc = self._world:GetService("FeatureLogic")
    if not featureSvc then
        self._message = " Feature Service Logic is nil!"
        return false
    end
    local curState = featureSvc:GetCurDayNightState()
    if not curState then
        self._message = " Day Night Feature is nil!"
        return false
    end

    local expectState = self._args.expect
    self._message = " cur state=" .. curState .. " expect=" .. expectState

    return curState == expectState
end

--检查机关数量
_class("CheckTrapCount_Test", AutoTestCheckPointBase)
CheckTrapCount_Test = CheckTrapCount_Test

function CheckTrapCount_Test:BeforeCheck()
end

function CheckTrapCount_Test:Check(notify)
    local expectCount = self._args.expect
    local trapCount = 0
    local group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    for _, e in ipairs(group:GetEntities()) do
        local trapID = e:TrapID():GetTrapID()
        if table.icontains(self._args.trapIDs, trapID) and not e:HasDeadMark() then
            trapCount = trapCount + 1
        end
    end
    return trapCount == expectCount
end

--检查卡牌数量
_class("CheckCardCount_Test", AutoTestCheckPointBase)
CheckCardCount_Test = CheckCardCount_Test

function CheckCardCount_Test:BeforeCheck()
end

function CheckCardCount_Test:Check(notify)
    ---@type FeatureServiceLogic
    local featureSvc = self._world:GetService("FeatureLogic")
    if not featureSvc then
        self._message = " Feature Service Logic is nil!"
        return false
    end

    local curCardCount = featureSvc:GetCurCardCount()
    local expectCardCount = self._args.expect
    local cmp = self._args.compare
    local f = CompareFuncMap[cmp]

    self._message = " 当前卡牌数量=" .. curCardCount .. " expect=" .. expectCardCount .. " compare:" .. cmp
    if f and f(curCardCount, expectCardCount) then
        return true
    end
    return false
end

--检查剩余回合数
_class("CheckCurWaveLeftRound_Test", AutoTestCheckPointBase)
CheckCurWaveLeftRound_Test = CheckCurWaveLeftRound_Test

function CheckCurWaveLeftRound_Test:BeforeCheck()
end

function CheckCurWaveLeftRound_Test:Check(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local restRound = battleStatCmpt:GetCurWaveRound()
    local exceptRound = self._args.expect
    local cmp = self._args.compare
    local f = CompareFuncMap[cmp]

    self._message = " 当前剩余回合数=" .. restRound .. " expect=" .. exceptRound .. " compare:" .. cmp
    if f and f(restRound, exceptRound) then
        return true
    end
    return false
end

--检查极光时刻
_class("CheckIsAuroraTime_Test", AutoTestCheckPointBase)
CheckIsAuroraTime_Test = CheckIsAuroraTime_Test

function CheckIsAuroraTime_Test:BeforeCheck()
end

function CheckIsAuroraTime_Test:Check(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local bAuroraTime = battleStatCmpt:IsRoundAuroraTime()
    local bExcept = self._args.expect

    self._message = "当前是否是极光时刻=" .. toString(bAuroraTime) .. " expect=" .. toString(bExcept)
    if bAuroraTime then
        return true
    end
    return (bAuroraTime == bExcept)
end

--检查占格数
_class("CheckEntityBodyAreaCount_Test", AutoTestCheckPointBase)
CheckEntityBodyAreaCount_Test = CheckEntityBodyAreaCount_Test

function CheckEntityBodyAreaCount_Test:BeforeCheck()
end

function CheckEntityBodyAreaCount_Test:Check(notify)
    local exceptCount = self._args.expect

    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    ---@type BodyAreaComponent
    local bodyAreaCmpt = self._entity:BodyArea()
    local bodyAreaCount = 0
    if bodyAreaCmpt then
        bodyAreaCount = bodyAreaCmpt:GetAreaCount()
    end
    self._message = " 占格子数=" .. bodyAreaCount .. " expect=" .. self._args.expect
    if bodyAreaCount == exceptCount then
        return true
    end
    return false
end

--检查光灵主动技是否能释放
_class("CheckPetActiveSkillCanCast_Test", AutoTestCheckPointBase)
CheckPetActiveSkillCanCast_Test = CheckPetActiveSkillCanCast_Test

function CheckPetActiveSkillCanCast_Test:Check(notify)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if not utilDataSvc then
        self._message = " Util Data Share Service is nil!"
        return false
    end

    ---@type PetPstIDComponent
    local petPstIDComponent = self._entity:PetPstID()
    if not petPstIDComponent then
        self._message = " 检查的对象不是光灵!"
        return false
    end
    local pstID = petPstIDComponent:GetPstID()
    local skillID = self._args.skillID
    local res, _, reason = utilDataSvc:CheckActiveSkillCastCondition(pstID, skillID)

    local expectRes = self._args.expect

    self._message = " 是否可释放=" .. tostring(res) .. " 期望值=" .. tostring(expectRes)
    
    if reason then
        self._message = " 是否可释放=" .. tostring(res) .. " 不可释放原因=" .. reason .. " 期望值=" ..
            tostring(expectRes)
    end
    return res == expectRes
end
