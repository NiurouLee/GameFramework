require("trigger_base")

--血量<x触发
_class("TTBloodLessThan", TriggerBase)
TTBloodLessThan = TTBloodLessThan

function TTBloodLessThan:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    local curhp = owner:Attributes():GetCurrentHP()
    local maxhp = owner:Attributes():CalcMaxHp()

    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        local cAttr = teamEntity:Attributes()
        curhp = cAttr:GetCurrentHP()
        maxhp = cAttr:CalcMaxHp()
    end

    local isOwnerAndNotifierPlayer =
        (owner:HasTeam() or entity:HasTeam()) and (owner:HasPetPstID() or entity:HasPetPstID())

    local blood = curhp / maxhp
    --20200711 注掉 * 100 咱们一般都配置0.5这种，有其他地方用么？
    return blood < self._x and (owner:GetID() == entity:GetID() or isOwnerAndNotifierPlayer)
end

--血量>x触发
_class("TTBloodMoreThan", TriggerBase)
TTBloodMoreThan = TTBloodMoreThan

function TTBloodMoreThan:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    local curhp = owner:Attributes():GetCurrentHP()
    local maxhp = owner:Attributes():CalcMaxHp()

    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        local cAttr = teamEntity:Attributes()
        curhp = cAttr:GetCurrentHP()
        maxhp = cAttr:CalcMaxHp()
    end

    ---特殊类型的通知类型，不需要考虑通知对象
    if notify:GetNotifyType() == NotifyType.PlayerMoveStart then
        local curBlood = curhp / maxhp
        return curBlood > self._x
    end

    local isOwnerAndNotifierPlayer =
        (owner:HasTeam() or entity:HasTeam()) and (owner:HasPetPstID() or entity:HasPetPstID())

    local blood = curhp / maxhp
    --20200711 注掉 * 100 咱们一般都配置0.5这种，有其他地方用么？
    return blood > self._x and (owner:GetID() == entity:GetID() or isOwnerAndNotifierPlayer)
end

--血量等于

_class("TTBloodEqual", TriggerBase)
TTBloodEqual = TTBloodEqual

function TTBloodEqual:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    local curhp = owner:Attributes():GetCurrentHP()
    local maxhp = owner:Attributes():CalcMaxHp()

    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        local cAttr = teamEntity:Attributes()
        curhp = cAttr:GetCurrentHP()
        maxhp = cAttr:CalcMaxHp()
    end

    local isOwnerAndNotifierPlayer =
        (owner:HasTeam() or entity:HasTeam()) and (owner:HasPetPstID() or entity:HasPetPstID())

    local blood = curhp / maxhp
    return blood == self._x and (owner:GetID() == entity:GetID() or isOwnerAndNotifierPlayer)
end

--对buff owner的血量判定
_class("TTOwnerBlood", TriggerBase)
TTOwnerBlood = TTOwnerBlood

function TTOwnerBlood:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local curhp = owner:Attributes():GetCurrentHP()
    local maxhp = owner:Attributes():CalcMaxHp()
    local blood = curhp / maxhp
    return CompareNumber(self._x, blood, self._y)
end

--受到大于某值得伤害触发
_class("TTDamageLargerThenRate", TriggerBase)
TTDamageLargerThenRate = TTDamageLargerThenRate

function TTDamageLargerThenRate:IsSatisfied(notify)
    return (math.abs(notify:GetChangeHP()) / notify:GetMaxHP()) > self._x
end

---判断攻击者者的元素属性是否匹配
_class("TTAttackElementMatch", TriggerBase)
---@class TTAttackElementMatch:TriggerBase
TTAttackElementMatch = TTAttackElementMatch

---@param notify NotifyAttackBase
function TTAttackElementMatch:IsSatisfied(notify)
    local element
    local ownerEntity = notify:GetAttackerEntity()
    if notify:GetAttackerEntity():PetPstID() then
        element = notify:GetAttackerEntity():Attributes():GetAttribute("Element")
    elseif notify:GetAttackerEntity():MonsterID() then
        element = notify:GetAttackerEntity():Element():GetPrimaryType()
    end
    for i, p in ipairs(self._param) do
        if element == p then
            return true
        end
    end
    return false
end

---判断目标的所在格子元素属性是否匹配
_class("TTTargetGridElementMatch", TriggerBase)
---@class TTTargetGridElementMatch:TriggerBase
TTTargetGridElementMatch = TTTargetGridElementMatch

---@param notify NotifyAttackBase
function TTTargetGridElementMatch:IsSatisfied(notify)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local gridPos = notify:GetDefenderEntity():GridLocation().Position
    ---目标是怪
    if notify:GetDefenderEntity():BodyArea() then
        ---@type BodyAreaComponent
        local bodyAreaComponent = notify:GetDefenderEntity():BodyArea()
        local bodyArea = bodyAreaComponent._area
        for _, v in ipairs(bodyArea) do
            local pieceElement = utilData:FindPieceElement(Vector2(gridPos.x + v.x, gridPos.y + v.y))
            for _, elementType in ipairs(self._param) do
                if elementType == pieceElement then
                    return true
                end
            end
        end
    else
        local pieceElement = utilData:FindPieceElement(gridPos)
        for _, elementType in ipairs(self._param) do
            if elementType == pieceElement then
                return true
            end
        end
    end
    return false
end

---判断目标的元素属性是否匹配
_class("TTDefenderElementMatch", TriggerBase)
---@class TTDefenderElementMatch:TriggerBase
TTDefenderElementMatch = TTDefenderElementMatch

---@param notify NotifyAttackBase
function TTDefenderElementMatch:IsSatisfied(notify)
    self._satisfied = false
    ---@type Entity
    local attacker = notify:GetNotifyEntity()
    ---@type Entity
    local defender = notify:GetDefenderEntity()
    if attacker == nil or defender == nil then
        return
    end

    local owner = self:GetOwnerEntity()
    if owner:GetID() ~= attacker:GetID() then
        return
    end

    local elementCom = defender:Element()
    if not elementCom then
        return
    end
    local defElement = elementCom:GetPrimaryType()
    for _, element in ipairs(self._param) do
        if element == defElement then
            return true
        end
    end
end

--combo数是x的倍数
_class("TTCombo", TriggerBase)

function TTCombo:IsSatisfied(notify)
    local combo = self._world:GetService("Battle"):GetLogicComboNum()
    return combo > 0 and combo % self._x == 0
end

---判断Buff拥有者元素是否匹配
_class("TTOwnerElementMatch", TriggerBase)
---@class TTOwnerElementMatch:TriggerBase
TTOwnerElementMatch = TTOwnerElementMatch

function TTOwnerElementMatch:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local element = nil
    if entity:PetPstID() then
        element = entity:Attributes():GetAttribute("Element")
    elseif entity:MonsterID() then
        element = entity:Attributes():GetAttribute("Element")
    end
    for i, p in ipairs(self._param) do
        if element == p then
            return true
        end
    end
end

---判断触发的的Buff是否匹配
_class("TTNotifyBuff", TriggerBase)
---@class TTNotifyBuff:TriggerBase
TTNotifyBuff = TTNotifyBuff

---@param notify TTNotifyBuff
function TTNotifyBuff:IsSatisfied(notify)
    ---@type BuffComponent
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    --传了entity再判断  存在怪物回合开始的时候通知所有怪物的情况  entity是nil
    if entity and owner ~= entity then
        return false
    end
    local buffCmp = owner:BuffComponent()
    if not buffCmp then
        return false
    end
    self._satisfied = false
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            return true
        end
    end
end

---判断触发的的Buff是否匹配
_class("TTNotifyOnlyBuff", TriggerBase)
---@class TTNotifyOnlyBuff:TriggerBase
TTNotifyOnlyBuff = TTNotifyOnlyBuff

---@param notify TTNotifyOnlyBuff
function TTNotifyOnlyBuff:OnNotify(notify)
    local entity = notify:GetNotifyEntity()
    self._satisfied = false
    local buffCmp = entity:BuffComponent()
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            self._satisfied = true
            break
        end
    end
end

function TTNotifyOnlyBuff:IsSatisfied()
    return self._satisfied
end

--region TTTrapOnPos
---判断触发的的Buff是否匹配
---@class TTTrapOnPos:TriggerBase
_class("TTTrapOnPos", TriggerBase)
TTTrapOnPos = TTTrapOnPos

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd|NTEffect156MoveOneGrid
function TTTrapOnPos:OnNotify(notify)
    self._pos = notify:GetPos()
end

function TTTrapOnPos:IsSatisfied()
    --!!! 特别注意，因为这里是用于行动到某个格子上，判断格子上是否有机关，但是机关可能因为触发技已经死亡了。所以这里不判断机关是否死亡 !!!
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    local listIDRet = {}
    local listTraps = trapGroup:GetEntities()
    for i = 1, #listTraps do
        local trap = listTraps[i]
        if trap then
            local pos = trap:GetGridPosition()
            ---@type BodyAreaComponent
            local bodyArea = trap:BodyArea()
            local bodyAreaList = bodyArea:GetArea()
            for _, area in ipairs(bodyAreaList) do
                if (area.x + pos.x) == self._pos.x and (area.y + pos.y) == self._pos.y then
                    ---@type TrapComponent
                    local trapComponent = trap:Trap()
                    if trapComponent and trapComponent:GetTrapID() then
                        table.insert(listIDRet, trapComponent:GetTrapID())
                    end
                end
            end
        end
    end

    for index, trapID in ipairs(listIDRet) do
        if trapID == self._x then
            return true
        end
    end
end

--endregion

-- function TTSameCampInTeam:
---判断队伍中同阵营的角色数量
---@class TTSameCampInTeam:TriggerBase
_class("TTSameCampInTeam", TriggerBase)
TTSameCampInTeam = TTSameCampInTeam

function TTSameCampInTeam:Constructor()
    -- self._param[1] => triggerCondition[2][1] => triggerType
    self._targetCampType = self._param[1]
    self._targetCount = self._param[2]

    self._satisfied = false
end

function TTSameCampInTeam:IsSatisfied()
    -- 开场统计阵容
    ---@type table<number, number>
    local dicPetCampCount = {}
    local pets = self._world.BW_WorldInfo:GetLocalMatchPetList()
    for _, matchPet in ipairs(pets) do
        local campID = matchPet:GetPetCamp()
        if (not dicPetCampCount[campID]) then
            dicPetCampCount[campID] = 0
        end
        dicPetCampCount[campID] = dicPetCampCount[campID] + 1
    end

    local requiredCount = dicPetCampCount[self._targetCampType]
    if requiredCount and requiredCount >= self._targetCount then
        self._satisfied = true
    end

    Log.notice(
        "TTSameCampInTeam: IsSatisfied=",
        self._satisfied,
        "requiredCamp=",
        self._targetCampType,
        "requiredCount=",
        self._targetCount
    )

    return self._satisfied
end

---判断自己的Buff是否匹配
_class("TTOwnerBuff", TriggerBase)
---@class TTOwnerBuff:TriggerBase
TTOwnerBuff = TTOwnerBuff

---@param notify TTOwnerBuff
function TTOwnerBuff:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()

    if owner:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local buffCmp = owner:BuffComponent()
    if not buffCmp then
        return
    end
    self._satisfied = false
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            self._satisfied = true
            return true
        end
    end
end

---判断自己的是不是不存在配置的buff
_class("TTOwnerNoBuff", TriggerBase)
---@class TTOwnerNoBuff:TriggerBase
TTOwnerNoBuff = TTOwnerNoBuff

function TTOwnerNoBuff:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()

    if owner:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local buffCmp = owner:BuffComponent()
    if not buffCmp then
        return
    end
    self._satisfied = false
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            self._satisfied = false
            return false
        end
    end
    return true
end

---判断目标的Buff是否匹配
_class("TTDefenderBuff", TriggerBase)
---@class TTDefenderBuff:TriggerBase
TTDefenderBuff = TTDefenderBuff

---@param notify NotifyAttackBase
function TTDefenderBuff:IsSatisfied(notify)
    ---@type BuffComponent
    local buffCmp = notify:GetDefenderEntity():BuffComponent()
    if not buffCmp then
        return
    end
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            return true
        end
    end
end

_class("TTDefenderNoBuff", TriggerBase)
---@class TTDefenderNoBuff:TriggerBase
TTDefenderNoBuff = TTDefenderNoBuff

---@param notify NotifyAttackBase
function TTDefenderNoBuff:IsSatisfied(notify)
    if not notify:GetDefenderEntity() then
        return false
    end
    ---@type BuffComponent
    local buffCmp = notify:GetDefenderEntity():BuffComponent()
    if not buffCmp then
        return false
    end
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            return false
        end
    end
    return true
end

_class("TTDefenderBodyAreaHasTrap", TriggerBase)
---@class TTDefenderBodyAreaHasTrap:TriggerBase
TTDefenderBodyAreaHasTrap = TTDefenderBodyAreaHasTrap

---@param notify NotifyAttackBase
function TTDefenderBodyAreaHasTrap:IsSatisfied(notify)
    local defender = notify:GetDefenderEntity()
    if not defender then
        return false
    end

    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")

    local gridPosition = defender:GetGridPosition()
    local bodyArea = defender:BodyArea():GetArea()
    for _, areaPos in ipairs(bodyArea) do
        local workPos = areaPos + gridPosition
        local traps = utilSvc:GetTrapsAtPos(workPos)
        if traps then
            for index, e in ipairs(traps) do
                if table.intable(self._param, e:Trap():GetTrapID()) then
                    return true
                end
            end
        end
    end

    return false
end

--房间类型
_class("TTMazeRoomType", TriggerBase)
---@class TTMazeRoomType:TriggerBase
TTMazeRoomType = TTMazeRoomType

function TTMazeRoomType:IsSatisfied()
    ---@type MazeService
    local mazeService = self:GetWorld():GetService("Maze")
    if mazeService:GetMazeRoomType() == self._x then
        return true
    end
end

--怪物AI匹配
_class("TTMonsterAI", TriggerBase)
---@class TTMonsterAI:TriggerBase
TTMonsterAI = TTMonsterAI

function TTMonsterAI:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local monsterID = entity:MonsterID()
    if not monsterID then
        return
    end
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    local monsterAIIDList = monsterConfigData:GetMonsterAIID(monsterID:GetMonsterID())

    local monsterMainAIID = monsterAIIDList[1][1]

    return table.icontains(self._param, monsterMainAIID)
end

--怪物AI匹配 存活数量
_class("TTMonsterAIAliveCount", TriggerBase)
---@class TTMonsterAIAliveCount:TriggerBase
TTMonsterAIAliveCount = TTMonsterAIAliveCount

function TTMonsterAIAliveCount:IsSatisfied(notify)
    --挂载者没死
    local owner = self:GetOwnerEntity()
    if owner:HasDeadMark() then
        return false
    end

    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    --死的怪物要检测AI，避免其他怪物死亡也触发
    local notifyEntity = notify:GetNotifyEntity()
    local notifyEntityMonsterID = notifyEntity:MonsterID()
    local notifyEntityMonsterAIIDList = monsterConfigData:GetMonsterAIID(notifyEntityMonsterID:GetMonsterID())
    if notifyEntityMonsterAIIDList[1][1] ~= self._x then
        return false
    end

    local aliveCount = 0
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()

    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() and e:GetID() ~= notifyEntity:GetID() then
            local monsterID = e:MonsterID()
            local monsterAIIDList = monsterConfigData:GetMonsterAIID(monsterID:GetMonsterID())

            if monsterAIIDList[1][1] == self._x then
                aliveCount = aliveCount + 1
            end
        end
    end

    local isSatisfied = (aliveCount == self._y) or (self._z and aliveCount == self._z)

    return isSatisfied
end

--根据怪物体型x判断
_class("TTMonsterBodyArea", TriggerBase)
TTMonsterBodyArea = TTMonsterBodyArea

function TTMonsterBodyArea:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local cnt = entity:BodyArea():GetAreaCount()
    if (cnt == 1 and self._x == 1) then
        return true
    end
    if cnt > 1 and self._x > 1 then
        return true
    end
    return false
end

--常规怪
_class("TTRegularBodyMonster", TriggerBase)
TTRegularBodyMonster = TTRegularBodyMonster

function TTRegularBodyMonster:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    if not entity then
        return false
    end
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    if monsterConfigData:IsRegularShape(entity:MonsterID():GetMonsterID()) then
        return true
    end
    return false
end

--根据怪物classID判断
_class("TTMonsterClassIDMatch", TriggerBase)
TTMonsterClassIDMatch = TTMonsterClassIDMatch

function TTMonsterClassIDMatch:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()

    local monsterID = entity:MonsterID():GetMonsterID()

    local monsterClassID = 0
    local cfg = Cfg.cfg_monster[monsterID]
    if cfg and cfg.ClassID then
        monsterClassID = cfg.ClassID
    end

    if table.intable(self._param, monsterClassID) then
        return true
    end
    return false
end

--按次数循环触发
---@class TTCountCycle:TriggerCount
_class("TTCountCycle", TriggerCount)
TTCountCycle = TTCountCycle

function TTCountCycle:OnNotify(notify)
    self:AddCount(1)
end

function TTCountCycle:IsSatisfied(notify)
    local _satisfied = self._count >= self._x
    if _satisfied then
        self:SetCount(0)
    end
    return _satisfied
end

--region TTCompareCount
---@class TTCompareCount:TriggerBase
_class("TTCompareCount", TriggerBase)
TTCompareCount = TTCompareCount

---x：操作flag；y：key字串；z及之后：参数
---当前保存的触发数与参数3相比较，满足参数2所指定的比较关系时返回true
function TTCompareCount:IsSatisfied(notify)
    local operation = self._x
    local owner = self:GetOwnerEntity()
    local cBuff = owner:BuffComponent()
    local key = self:GetKeyStr()
    --操作1：每次触发计数+1，无条件返回true
    if operation == 1 then
        local n = self._z or 1 --默认自增1
        local newCount = cBuff:GetBuffValue(key) or 0
        newCount = newCount + n
        cBuff:SetBuffValue(key, newCount)
        return true
    end
    --操作2：每次触发计数清零，无条件返回true
    if operation == 2 then
        local n = self._z or 0 --默认赋值0，即清零
        cBuff:SetBuffValue(key, n)
        return true
    end
    --操作3：每次触发比较计数和配置并返回比较结果
    local countSave = cBuff:GetBuffValue(key) or 0
    local compareFlag = self._param[3]
    local count = self._param[4]
    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = countSave == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = countSave ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = countSave > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = countSave >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = countSave < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = countSave <= count
    end
    return satisfied
end

function TTCompareCount:GetKeyStr()
    return "CompareTriggerCount" .. self._y
end

--endregion

---比较运算符枚举
---@class ComparisonOperator
local ComparisonOperator = {
    EQ = 1, --equal 等于
    NE = 2, --not equal 不等于
    GT = 3, --great than 大于
    GE = 4, --great equal 大于等于
    LT = 5, --less than 小于
    LE = 6 --less equal 小于等于
}
_enum("ComparisonOperator", ComparisonOperator)

--自己被特定pet普工
_class("TTSpecificPetNormalHitMe", TriggerBase)
TTSpecificPetNormalHitMe = TTSpecificPetNormalHitMe

---@type notify NotifyAttackBase
function TTSpecificPetNormalHitMe:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.PlayerBeHit and notify:GetNotifyType() ~= NotifyType.MonsterBeHit then
        return
    end

    local attacker = notify:GetAttackerEntity()

    if
        notify:GetSkillType() == SkillType.Normal and attacker:HasPetPstID() and
            attacker:PetPstID():GetTemplateID() == self._x and
            notify:GetDefenderEntity() == self:GetOwnerEntity()
     then
        return true
    end
end

--宝宝触发
_class("TTPetNotify", TriggerBase)
TTPetNotify = TTPetNotify

function TTPetNotify:IsSatisfied(notify)
    local notifyEntity = notify:GetNotifyEntity()
    if not notifyEntity then
        return false
    end
    if notifyEntity:PetPstID() then
        return true
    end
    if notifyEntity:HasSuperEntity() and notifyEntity:EntityType():IsSkillHolder() then
        return notifyEntity:GetSuperEntity():HasPetPstID()
    end
    return false
end

--被击者与攻击者距离触发,暂时只考虑攻击者是宝宝的情况
_class("TTDefenderDistance", TriggerBase)
TTDefenderDistance = TTDefenderDistance

function TTDefenderDistance:IsSatisfied(notify)
    local attacker = notify:GetNotifyEntity()
    local attackPos = notify:GetTargetPos()
    if not attacker:PetPstID() then
        return false
    end
    if attacker ~= self:GetOwnerEntity() then
        return false
    end
    local attackerPos = attacker:GridLocation():Center()
    local distance = Vector2.Distance(attackPos, attackerPos)
    local paramDistance = tonumber(self._param[1])

    if distance < paramDistance then
        return true
    end
    return false
end

_class("TTMonsterSkillDamageEnd", TriggerBase)
TTMonsterSkillDamageEnd = TTMonsterSkillDamageEnd

---@param notify NTMonsterSkillDamageEnd
function TTMonsterSkillDamageEnd:IsSatisfied(notify)
    self._satisfied = false
    ---@type Entity
    local attacker = notify:GetNotifyEntity()
    local owner = self:GetOwnerEntity()
    if owner ~= attacker then
        return false
    end
    local skillId = notify:GetSkillID()
    if self._x == skillId then
        return true
    end

    if self._param and table.intable(self._param, skillId) then
        return true
    end

    return false
end

--------------------------------
---主动技打到的第一排触发
_class("TTActiveSkillFirstHitRow", TriggerBase)
TTActiveSkillFirstHitRow = TTActiveSkillFirstHitRow
function TTActiveSkillFirstHitRow:Constructor()
    self._firstRowPosList = nil
end

function TTActiveSkillFirstHitRow:Reset()
    self._firstRowPosList = nil
end

---@param notify INotifyBase
function TTActiveSkillFirstHitRow:IsSatisfied(notify)
    local attacker = notify:GetNotifyEntity()
    local owner = self:GetOwnerEntity()
    if owner ~= attacker then
        return false
    end
    if notify:GetNotifyType() == NotifyType.NotifyTrainFirstRowPos then
        self._firstRowPosList = notify:GetData()
    end
    if not self._firstRowPosList then
        return false
    end
    if notify:GetNotifyType() == NotifyType.ActiveSkillEachAttackStart then
        local targetPos = notify:GetTargetPos()
        if table.icontains(self._firstRowPosList, targetPos) then
            return true
        end
    end
    if
        ((notify:GetNotifyType() == NotifyType.ActiveSkillAttackEnd) or
            (notify:GetNotifyType() == NotifyType.ActiveSkillAttackEndBeforeMonsterDead))
     then
        self:Reset()
    end
    return false
end

--------------------------------
---攻击的目标是技能范围的中心
_class("TTTargetPosIsSkillCenterPos", TriggerBase)
TTTargetPosIsSkillCenterPos = TTTargetPosIsSkillCenterPos
function TTTargetPosIsSkillCenterPos:Constructor()
end

---@param notify INotifyBase
function TTTargetPosIsSkillCenterPos:IsSatisfied(notify)
    local entityCaster = notify:GetNotifyEntity()
    if entityCaster == self:GetOwnerEntity() then
        return false
    end
    local targetPos = notify:GetTargetPos()
    local skillResult = entityCaster:SkillContext():GetResultContainer()
    local centerPos = skillResult:GetScopeResult():GetCenterPos()
    local ret = targetPos == centerPos
    return ret
end

--region BodyArea中的子集格子列表过滤
---@class TTTargetBodyAreaSubset:TriggerBase
_class("TTTargetBodyAreaSubset", TriggerBase)
TTTargetBodyAreaSubset = TTTargetBodyAreaSubset

---@param notify NotifyAttackBase
function TTTargetBodyAreaSubset:IsSatisfied(notify)
    --从参数中拿BodyArea中例外格子
    local defender = notify:GetDefenderEntity()
    local posDefender = defender:GridLocation().Position
    ---@type Vector2[]
    local exceptionPos = {}
    for i = 1, table.count(self._param), 2 do
        local v = Vector2(self._param[i], self._param[i + 1])
        local pos = v + posDefender
        table.insert(exceptionPos, pos)
    end
    if table.icontains(exceptionPos, notify:GetTargetPos()) then
        return true
    end
    return false
end

--endregion

--region BodyArea中的子集格子列表过滤（buff）
---@class TTTargetBodyAreaSubsetBuff:TriggerBase
_class("TTTargetBodyAreaSubsetBuff", TriggerBase)
TTTargetBodyAreaSubsetBuff = TTTargetBodyAreaSubsetBuff

---@param notify NTEachAddBuff
function TTTargetBodyAreaSubsetBuff:IsSatisfied(notify)
    --从参数中拿BodyArea中例外格子
    local defender = notify:GetDefenderEntity()
    local posDefender = defender:GridLocation().Position
    local attackRange = notify:GetAttackRange()
    ---@type Vector2[]
    local posList = {}
    for i = 1, table.count(self._param), 2 do
        local v = Vector2(self._param[i], self._param[i + 1])
        local pos = v + posDefender
        table.insert(posList, pos)
    end
    if attackRange then
        for _, grid in ipairs(attackRange) do
            if table.icontains(posList, grid) then
                return false --攻击范围和参数位置有交集，不满足
            end
        end
    end
    return true --攻击范围和参数位置无交集，满足
end

--endregion

_class("TTMonsterKilled", TriggerBase)
---@class TTMonsterKilled : TriggerBase
TTMonsterKilled = TTMonsterKilled

---@param notify INotifyBase
function TTMonsterKilled:IsSatisfied(notify)
    local isOnlySelf = self._param[1] == 1

    ---@type Entity
    local entity = notify:GetNotifyEntity()
    local ownerEntity = self:GetOwnerEntity()

    if isOnlySelf and (entity:GetID() ~= ownerEntity:GetID()) then
        return false
    end

    local skillEffectResultContainer = entity:SkillContext():GetResultContainer()
    if not skillEffectResultContainer then
        return false
    end

    local skillScopeResult = skillEffectResultContainer:GetScopeResult()
    if not skillScopeResult then
        return false
    end

    local world = entity:GetOwnerWorld()

    local ids = skillScopeResult:GetTargetIDs()
    for _, monsterEntityID in ipairs(ids) do
        local entity = world:GetEntityByID(monsterEntityID)
        local monsterID = entity:MonsterID()
        if monsterID then
            local attributeComponent = entity:Attributes()
            if attributeComponent then
                local logicHP = attributeComponent:GetCurrentHP()
                if
                    ((not entity) or -- 实体已销毁
                        (entity:HasDeadMark()) or -- 已标记死亡
                        (logicHP <= 0))
                 then -- 空血，即将标记死亡
                    return true
                end
            end
        end
    end

    return false
end

---@class TTLimitAiRound:TriggerBase
_class("TTLimitAiRound", TriggerBase)
TTLimitAiRound = TTLimitAiRound

function TTLimitAiRound:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()

    ---@type AIComponentNew
    local aiComponent = owner:AI()
    local nSaveRound = aiComponent:GetRuntimeData("NextRoundCount") or 0

    if self._param and table.intable(self._param, nSaveRound) then
        return true
    end

    return false
end

----------------------------------------------------------------
---@class TTTrapBombSummon:TriggerBase
_class("TTTrapBombSummon", TriggerBase)
TTTrapBombSummon = TTTrapBombSummon

function TTTrapBombSummon:IsSatisfied(notify)
    local nNotifyType = notify:GetNotifyType()
    if nNotifyType == NotifyType.TrapAction then
        local posAction = notify:GetPosAction()
        local entityOwn = self:GetOwnerEntity()
        local posEntityOwn = entityOwn:GetGridPosition()
        if posEntityOwn ~= posAction then
            return false
        end
        local bHave = self:_IsHaveTrapBomb(posAction)
        Log.debug("[TrapBomb]：判定ID=[", entityOwn:GetID(), "]在位置", GameHelper.MakePosString(posAction), "是否有炸弹", bHave)
        return not bHave
    end

    local entityOwn = self:GetOwnerEntity()
    local posSelf = entityOwn:GridLocation().Position
    local bHave = self:_IsHaveTrapBomb(posSelf)
    return not bHave
    -- return false
end

function TTTrapBombSummon:_IsHaveTrapBomb(pos)
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    local listTrapBomb = utilSvc:FindTrapByTypeAndPos(TrapType.BombByHitBack, pos)
    if not listTrapBomb or table.count(listTrapBomb) <= 0 then
        return false
    end
    return true
end

----------------------------------------------------------------

_class("TTSuperChain", TriggerBase)
TTSuperChain = TTSuperChain

function TTSuperChain:IsSatisfied(notify)
    return self._world:BattleStat():IsRoundSuperChain()
end

_class("TTPossessedGridConverted", TriggerBase)
---@class TTPossessedGridConverted : TriggerBase
TTPossessedGridConverted = TTPossessedGridConverted

---@param notify NTGridConvert
function TTPossessedGridConverted:IsSatisfied(notify)
    local entity = self:GetOwnerEntity()
    local gridPosition = entity:GetGridPosition()
    local bodyAreaComponent = entity:BodyArea()
    local bodyArea = {}
    if bodyAreaComponent then
        bodyArea = bodyAreaComponent:GetArea()
    else
        table.insert(bodyArea, Vector2.New(0, 0))
    end

    local keepPieceType = self._param[1]

    for _, areaPos in ipairs(bodyArea) do
        local absolutePos = areaPos + gridPosition
        local convertInfo = notify:GetConvertInfoAt(absolutePos)
        if convertInfo then
            local after = convertInfo:GetAfterPieceType()
            if (after ~= keepPieceType) then
                return true
            end
        end
    end

    return false
end

_class("TTTeamMovePieceTypeMatch", TriggerBase)
---@class TTTeamMovePieceTypeMatch
TTTeamMovePieceTypeMatch = TTTeamMovePieceTypeMatch

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function TTTeamMovePieceTypeMatch:IsSatisfied(notify)
    local entityID = notify:GetEntityID()
    local entity = self._world:GetEntityByID(entityID)
    ---@type Entity
    local teamEntity = entity:Pet():GetOwnerTeamEntity()
    local teamEntityLeader = teamEntity:GetTeamLeaderPetEntity()
    if teamEntityLeader:GetID() ~= entityID then
        return false
    end

    local pieceType = notify:GetPosPieceType()
    return table.icontains(self._param, pieceType)
end

_class("TTPieceTypeMatch", TriggerBase)
---@class TTPieceTypeMatch
TTPieceTypeMatch = TTPieceTypeMatch

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function TTPieceTypeMatch:IsSatisfied(notify)
    local entityID = notify:GetEntityID()
    local entity = self:GetOwnerEntity()
    if entity:GetID() ~= entityID then
        return false
    end

    local pieceType = notify:GetPosPieceType()
    return table.icontains(self._param, pieceType)
end

_class("TTPosPieceTypeMatch", TriggerBase)
---@class TTPosPieceTypeMatch
TTPosPieceTypeMatch = TTPosPieceTypeMatch

--- notify 需要支持GetPosPieceType()
function TTPosPieceTypeMatch:IsSatisfied(notify)
    local pieceType = notify:GetPosPieceType()
    return table.icontains(self._param, pieceType)
end

_class("TTPieceEffectTypeMatch", TriggerBase)
---@class TTPieceEffectTypeMatch
TTPieceEffectTypeMatch = TTPieceEffectTypeMatch

---@param notify NTPlayerEachMoveStart|NTPlayerEachMoveEnd
function TTPieceEffectTypeMatch:IsSatisfied(notify)
    -- local entityID = notify:GetEntityID()
    -- local entity = self:GetOwnerEntity()
    -- if entity:GetID() ~= entityID then
    --     return false
    -- end

    local pieceEffectType = notify:GetPieceEffectType()
    return self._x == pieceEffectType
end

_class("TTTrapTrigger", TriggerBase)
---@class TTTrapTrigger : TriggerBase

---@param notify NTTrapSkillStart|NTTrapSkillEnd
function TTTrapTrigger:IsSatisfied(notify)
    if (not notify._skillID) or (not notify._trapEntity) then
        return false
    end

    local trapID = self._param[1]
    local trapSkillID = self._param[2]

    local cTrap = notify._trapEntity:Trap()
    if not cTrap then
        return false
    end

    return (trapID == cTrap:GetTrapID()) and (trapSkillID == notify._skillID)
end

--传送技能的旧坐标在自己的范围内 且新坐标不在自己范围内
_class("TTTeleportOldPosInOwnerArea", TriggerBase)
TTTeleportOldPosInOwnerArea = TTTeleportOldPosInOwnerArea

function TTTeleportOldPosInOwnerArea:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local owner = self:GetOwnerEntity()
    if not entity or owner:HasDeadMark() then
        return false
    end
    local posOld = notify:GetPosOld()
    local posNew = notify:GetPosNew()

    local owner = self:GetOwnerEntity()
    local center = owner:GridLocation().Position
    local area = owner:BodyArea():GetArea()

    local isChangePos = false
    for _, v in ipairs(area) do
        local workPos = center + v
        if posOld.x == workPos.x and posOld.y == workPos.y then
            isChangePos = true
        end
    end

    for _, v in ipairs(area) do
        local workPos = center + v
        if posNew.x == workPos.x and posNew.y == workPos.y then
            isChangePos = false
        end
    end

    return isChangePos
end

--传送技能的新坐标在自己的范围内 且旧坐标不在自己范围内
_class("TTTeleportNewPosInOwnerArea", TriggerBase)
TTTeleportNewPosInOwnerArea = TTTeleportNewPosInOwnerArea

function TTTeleportNewPosInOwnerArea:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local owner = self:GetOwnerEntity()
    if not entity or owner:HasDeadMark() then
        return false
    end
    local posOld = notify:GetPosOld()
    local posNew = notify:GetPosNew()

    local owner = self:GetOwnerEntity()
    local center = owner:GridLocation().Position
    local area = owner:BodyArea():GetArea()

    local isChangePos = false
    -- for _, v in ipairs(area) do
    --     local workPos = center + v
    --     if posNew.x == workPos.x and posNew.y == workPos.y then
    --         isChangePos = true
    --     end
    -- end

    -- for _, v in ipairs(area) do
    --     local workPos = center + v
    --     if posOld.x == workPos.x and posOld.y == workPos.y then
    --         isChangePos = false
    --     end
    -- end

    if posNew.x == center.x and posNew.y == center.y then
        isChangePos = true
    end

    return isChangePos
end

---判断与Team的Buff是否匹配
_class("TTTeamOwnerBuff", TriggerBase)
---@class TTTeamOwnerBuff:TriggerBase
TTTeamOwnerBuff = TTTeamOwnerBuff

---@param notify TTOwnerBuff
function TTTeamOwnerBuff:IsSatisfied(notify)
    -- local entity = notify._ownerEntity
    local owner = self:GetOwnerEntity()
    ---@type BuffComponent
    local buffCmp
    if owner:HasPetPstID() then
        ---@type Entity
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        buffCmp = teamEntity:BuffComponent()
    else
        return
    end
    if not buffCmp then
        return
    end
    self._satisfied = false
    for i, buffEffect in ipairs(self._param) do
        if buffCmp:HasBuffEffect(buffEffect) then
            self._satisfied = true
            return true
        end
    end
end

--通知目标是队长
_class("TTNotifyTeamLeader", TriggerBase)
---@class TTNotifyTeamLeader:TriggerBase
TTNotifyTeamLeader = TTNotifyTeamLeader

function TTNotifyTeamLeader:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    if entity:HasPet() then
        ---@type Entity
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        local teamEntityLeader = teamEntity:GetTeamLeaderPetEntity()
        return teamEntityLeader:GetID() == entity:GetID()
    end
    return false
end

--机关释放技能
_class("TTTrapSkillMatch", TriggerBase)
---@class TTTrapSkillMatch:TriggerBase
TTTrapSkillMatch = TTTrapSkillMatch

function TTTrapSkillMatch:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if not trapCmpt then
        return false
    end

    local skillId = notify:GetSkillID()
    local trapID = trapCmpt:GetTrapID()
    --必须 trapID  SkillID 都匹配
    if self._x == trapID and self._y == skillId then
        return true
    end

    return false
end

_class("TTFirstDeadPet", TriggerBase)
TTFirstDeadPet = TTFirstDeadPet
function TTFirstDeadPet:IsSatisfied(notify)
    if self._world:BattleStat():GetFirstDeadPetEntity() then
        return true
    end
    return false
end

---技能匹配
_class("TTSkillIDMatch", TriggerBase)
---@class TTSkillIDMatch:TriggerBase
TTSkillIDMatch = TTSkillIDMatch

function TTSkillIDMatch:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local skillID = notify:GetSkillID()
    for i, p in ipairs(self._param) do
        if skillID == p then
            return true
        end
    end
    return false
end

---技能标签匹配
_class("TTActiveSkillTag", TriggerBase)
---@class TTActiveSkillTag:TriggerBase
TTActiveSkillTag = TTActiveSkillTag

function TTActiveSkillTag:IsSatisfied(notify)
    local entity = notify:GetNotifyEntity()
    local skillID = notify:GetSkillID()
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    local skillCfg = configSvc:GetSkillConfigData(skillID)
    local skillTags = skillCfg:GetSkillTag()
    for i, v in ipairs(self._param) do
        if not table.icontains(skillTags, v) then
            return false
        end
    end
    return true
end

--星灵施放瞬移效果后
_class("TTAfterPetTeleport", TriggerBase)
---@class TTAfterPetTeleport:TriggerBase
TTAfterPetTeleport = TTAfterPetTeleport
function TTAfterPetTeleport:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---挂buff的目标如果已经死亡，不触发
    local owner = self:GetOwnerEntity()
    if not entity or owner:HasDeadMark() then
        return false
    end

    if entity:HasPetPstID() then
        return true
    end

    return false
end

--血条护盾值大于0
_class("TTHasHPShield", TriggerBase)
---@class TTHasHPShield:TriggerBase
TTHasHPShield = TTHasHPShield
function TTHasHPShield:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---挂buff的目标如果已经死亡，不触发GetTargetMap
    local owner = self:GetOwnerEntity()

    local testOwner = self._param[1] == 1
    if testOwner then
        entity = owner
    end

    if not entity or owner:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if buffCmpt == nil then
        return false
    end

    local curHpShieldValue = buffCmpt:GetBuffValue("HPShield") or 0
    if curHpShieldValue <= 0 then
        return false
    end

    return true
end

--队伍 血条护盾值大于0
_class("TTTeamHasHPShield", TriggerBase)
---@class TTTeamHasHPShield:TriggerBase
TTTeamHasHPShield = TTTeamHasHPShield
function TTTeamHasHPShield:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---挂buff的目标如果已经死亡，不触发GetTargetMap
    local owner = self:GetOwnerEntity()
    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        entity = teamEntity
    end

    if not entity or owner:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local buffCmpt = entity:BuffComponent()
    if buffCmpt == nil then
        return false
    end

    local curHpShieldValue = buffCmpt:GetBuffValue("HPShield") or 0
    if curHpShieldValue <= 0 then
        return false
    end

    return true
end

-- TTDamageOnAllMonsters

_class("TTDamageOnAllMonsters", TriggerBase)
---@class TTDamageOnAllMonsters:TriggerBase
TTDamageOnAllMonsters = TTDamageOnAllMonsters

---@param notify NTChainSkillDamageEnd
function TTDamageOnAllMonsters:IsSatisfied(notify)
    local targetMap = notify:GetTargetMap()

    local eOwner = self:GetOwnerEntity()
    local eidOwner = eOwner:GetID()
    local notifyEntity = notify:GetNotifyEntity()
    if type(notifyEntity) == "table" then
        notifyEntity = notifyEntity:GetID()
    end
    if (notifyEntity ~= eidOwner) then
        return false
    end

    if self._world:MatchType() == MatchType.MT_BlackFist then
        return true
    end

    local aliveMonsters = self._world:GetGroupEntities(self._world.BW_WEMatchers.AliveMonster)
    for _, entity in ipairs(aliveMonsters) do
        local idEntity = entity:GetID()
        if not targetMap[idEntity] then
            return false
        end
    end

    return true
end

--玩家掉血
_class("TTPlayerDecreaseHp", TriggerBase)
---@class TTPlayerDecreaseHp:TriggerBase
TTPlayerDecreaseHp = TTPlayerDecreaseHp
---@param notify NTPlayerHPChange
function TTPlayerDecreaseHp:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---挂buff的目标如果已经死亡，不触发
    local owner = self:GetOwnerEntity()
    if not entity or owner:HasDeadMark() then
        return false
    end

    local changeHp = notify:GetChangeHP()
    if changeHp < 0 then
        return true
    end

    return false
end

--战斗胜利、失败
_class("TTGameOver", TriggerBase)
---@class TTGameOver:TriggerBase
TTGameOver = TTGameOver

---@param notify NTGameOver
function TTGameOver:IsSatisfied(notify)
    --0失败 1胜利
    if self._x == 1 then
        return notify:GetVictory() == self._x
    end

    ---@type PlayerDefeatType
    local defeatType = notify:GetDefeatType()
    return defeatType == self._y
end

--火车专用,被攻击者是否在攻击范围内中心的一条线上
--方法就是根据点选方向 判断被攻击坐标的x或者y是否与点选方向相同
_class("TTDefenderInCenterLine", TriggerBase)
---@class TTDefenderInCenterLine:TriggerBase
TTDefenderInCenterLine = TTDefenderInCenterLine
---@param notify NotifyAttackBase
function TTDefenderInCenterLine:IsSatisfied(notify)
    ---@type Entity
    local casterEntity = notify:GetNotifyEntity()
    local defenderPos = notify:GetTargetPos()
    if not casterEntity:HasPetPstID() or casterEntity:GetID() ~= self:GetOwnerEntity():GetID() then
        return false
    end
    ---@type ActiveSkillPickUpComponent
    local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
    ---@type HitBackDirectionType
    local pickDirection, pickGrid = activeSkillPickUpComponent:GetLastPickDirectionAndPickPos()
    if pickDirection == HitBackDirectionType.Right or pickDirection == HitBackDirectionType.Left then
        if defenderPos.y == pickGrid.y then
            return true
        end
    end
    if pickDirection == HitBackDirectionType.Up or pickDirection == HitBackDirectionType.Down then
        if defenderPos.x == pickGrid.x then
            return true
        end
    end

    return false
end

--检测通知是否是指定的层
_class("TTCheckLayer", TriggerBase)
---@class TTCheckLayer:TriggerBase
TTCheckLayer = TTCheckLayer
---@param notify NTNotifyLayerChange
function TTCheckLayer:IsSatisfied(notify)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local layerName = notify:GetLayerName()

    for i, buffEffect in ipairs(self._param) do
        local condName = buffLogicService:GetBuffLayerName(buffEffect)
        if layerName == condName then
            return true
        end
    end

    return false
end

_class("TTDefenderHPLessThan", TriggerBase)
---@class TTDefenderHPLessThan : TriggerBase
TTDefenderHPLessThan = TTDefenderHPLessThan

---@param notify NotifyAttackBase
function TTDefenderHPLessThan:IsSatisfied(notify)
    local cAttrDefender = notify:GetDefenderEntity():Attributes()
    if (not cAttrDefender) or (not cAttrDefender:GetCurrentHP()) then
        return false
    end

    local curhp = cAttrDefender:GetCurrentHP()
    local maxhp = cAttrDefender:CalcMaxHp()
    local pct = curhp / maxhp

    return pct < self._param[1]
end

_class("TTCmpDefenderHPPercent", TriggerBase)
---@class TTCmpDefenderHPPercent : TriggerBase
TTCmpDefenderHPPercent = TTCmpDefenderHPPercent

---@param notify NotifyAttackBase
function TTCmpDefenderHPPercent:IsSatisfied(notify)
    --不判断机关
    if notify:GetDefenderEntity():Trap() then
        return false
    end

    local cAttrDefender = notify:GetDefenderEntity():Attributes()
    if (not cAttrDefender) or (not cAttrDefender:GetCurrentHP()) then
        return false
    end

    local curhp = cAttrDefender:GetCurrentHP()
    local maxhp = cAttrDefender:CalcMaxHp()
    local pct = curhp / maxhp
    local cmpType = self._param[1]
    local count = self._param[2]
    return Algorithm.CmpByOperator(pct, count, cmpType)
end

_class("TTCampOrElementMatch", TriggerBase)
---@class TTCampOrElementMatch : TriggerBase
TTCampOrElementMatch = TTCampOrElementMatch

---@param notify NTPetCreate
function TTCampOrElementMatch:IsSatisfied(notify)
    if self._x == notify:GetElement() or self._y == notify:GetCampID() then
        return true
    else
        return false
    end
end

--region TTElementMatch
---@class TTElementMatch : TriggerBase
_class("TTElementMatch", TriggerBase)
TTElementMatch = TTElementMatch

---@param notify NTPetCreate
function TTElementMatch:IsSatisfied(notify)
    if self._x == notify:GetElement() then
        return true
    end
    return false
end

--endregion

_class("TTSlantNormalAttack", TriggerBase)
---@class TTSlantNormalAttack : TriggerBase
TTSlantNormalAttack = TTSlantNormalAttack

---@param notify NTPetCreate
function TTSlantNormalAttack:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()

    local attackPos = notify:GetAttackPos()
    local targetPos = notify:GetTargetPos()
    if
        notify:GetAttackerEntity() == owner and math.abs(attackPos.x - targetPos.x) == 1 and
            math.abs(attackPos.y - targetPos.y) == 1
     then
        return true
    end

    return false
end

---Team拥有Debuff
_class("TTTeamOwnerDebuff", TriggerBase)
---@class TTTeamOwnerDebuff:TriggerBase
TTTeamOwnerDebuff = TTTeamOwnerDebuff

---@param notify TTOwnerBuff
function TTTeamOwnerDebuff:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    ---@type BuffComponent
    local buffCmp
    if owner:HasPetPstID() then
        ---@type Entity
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        buffCmp = teamEntity:BuffComponent()
    else
        return
    end
    if not buffCmp then
        return
    end
    self._satisfied = buffCmp:HasDebuff()
    return self._satisfied
end

---拥有者有Debuff
_class("TTOwnerDebuff", TriggerBase)
---@class TTOwnerDebuff:TriggerBase
TTOwnerDebuff = TTOwnerDebuff

function TTOwnerDebuff:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    ---@type BuffComponent
    local buffCmp
    buffCmp = owner:BuffComponent()

    if not buffCmp then
        return
    end
    self._satisfied = buffCmp:HasDebuff()
    return self._satisfied
end

---被击者有Debuff
_class("TTDefenderDenuff", TriggerBase)
---@class TTDefenderDenuff:TriggerBase
TTDefenderDenuff = TTDefenderDenuff

function TTDefenderDenuff:IsSatisfied(notify)
    ---@type BuffComponent
    local buffCmp = notify:GetDefenderEntity():BuffComponent()
    if not buffCmp then
        return
    end
    if not buffCmp then
        return
    end
    self._satisfied = buffCmp:HasDebuff()
    return self._satisfied
end

--region CompareChainPath
---@class TTCompareChainPath:TriggerBase
_class("TTCompareChainPath", TriggerBase)
TTCompareChainPath = TTCompareChainPath

function TTCompareChainPath:OnNotify(notify)
end

function TTCompareChainPath:IsSatisfied(notify)
    self._chainCount = notify:GetChainCount() --通知时存储的所释放的连锁技的连锁数
    local compareFlag = self._x --比较操作枚举
    local count = self._y --配置的连锁数
    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = self._chainCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = self._chainCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = self._chainCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = self._chainCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = self._chainCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = self._chainCount <= count
    end
    return satisfied
end

--endregion

--region CompareSkillStageIndex = 277, --技能阶段比较
---@class TTCompareSkillStageIndex:TriggerBase
_class("TTCompareSkillStageIndex", TriggerBase)
TTCompareSkillStageIndex = TTCompareSkillStageIndex

function TTCompareSkillStageIndex:OnNotify(notify)
end

function TTCompareSkillStageIndex:IsSatisfied(notify)
    self._skillStageIndex = notify:GetSkillStageIndex() --通知时存储的技能阶段
    if not self._skillStageIndex then
        return false
    end
    local compareFlag = self._x --比较操作枚举
    local count = self._y --配置的连锁数
    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = self._skillStageIndex == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = self._skillStageIndex ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = self._skillStageIndex > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = self._skillStageIndex >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = self._skillStageIndex < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = self._skillStageIndex <= count
    end
    return satisfied
end

--endregion

---@class CompMonsterType
local CompMonsterType = {
    All = 1, ---全选
    ExceptBoss = 2, ---除了Boss
    OnlyBoss = 3 ---只有Boss
}
_enum("CompMonsterType", CompMonsterType)

_class("TTCompMonsterType", TriggerBase)
---@class TTCompMonsterType:TriggerBase
TTCompMonsterType = TTCompMonsterType
---@param notify NTMonsterShow
function TTCompMonsterType:IsSatisfied(notify)
    local compareFlag = self._x --比较操作枚举
    local notifyEntity = notify:GetNotifyEntity()
    if not notifyEntity:MonsterID() then
        return false
    end
    local isBoss = notifyEntity:HasBoss()

    if compareFlag == CompMonsterType.All then --eq
        return true
    elseif compareFlag == CompMonsterType.ExceptBoss then --ne
        return not isBoss
    elseif compareFlag == CompMonsterType.OnlyBoss then --gt
        return isBoss
    end
    return false
end

_class("TTNotifyMeOrTeam", TriggerBase)
---@class TTNotifyMeOrTeam:TriggerBase
TTNotifyMeOrTeam = TTNotifyMeOrTeam
function TTNotifyMeOrTeam:IsSatisfied(notify)
    local notifyEntity = notify:GetNotifyEntity()
    if not notifyEntity then
        return false
    end
    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:GetID() == notifyEntity:GetID() then
        return true
    end
    if ownerEntity:HasPet() and notifyEntity:GetID() == ownerEntity:Pet():GetOwnerTeamEntity():GetID() then
        return true
    end
    return false
end

_class("TTNotifyMeOrTeamPet", TriggerBase)
---@class TTNotifyMeOrTeamPet:TriggerBase
TTNotifyMeOrTeamPet = TTNotifyMeOrTeamPet
function TTNotifyMeOrTeamPet:IsSatisfied(notify)
    local notifyEntity = notify:GetNotifyEntity()
    if not notifyEntity then
        return false
    end
    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:GetID() == notifyEntity:GetID() then
        return true
    end
    if ownerEntity:HasPet() and notifyEntity:GetID() == ownerEntity:Pet():GetOwnerTeamEntity():GetID() then
        return true
    end
    if
        ownerEntity:HasPet() and notifyEntity:HasPet() and
            notifyEntity:Pet():GetOwnerTeamEntity():GetID() == ownerEntity:Pet():GetOwnerTeamEntity():GetID()
     then
        return true
    end
    return false
end

_class("TTAtkHPPercentGreater", TriggerBase)
---@class TTAtkHPPercentGreater:TriggerBase
TTAtkHPPercentGreater = TTAtkHPPercentGreater
---@param notify NotifyAttackBase
function TTAtkHPPercentGreater:IsSatisfied(notify)
    if not notify.GetAttackerEntity or not notify.GetDefenderEntity then
        return false
    end
    ---@type Entity
    local attacker = notify:GetAttackerEntity()
    ---@type Entity
    local defender = notify:GetDefenderEntity()

    if defender:HasTeam() then
        if not (attacker:MonsterID() or attacker:HasPet()) then
            return false
        end
    else
        return false
    end
    local defHP = defender:Attributes():GetCurrentHP()
    local defMaxHP = defender:Attributes():CalcMaxHp()
    local atkHP = attacker:Attributes():GetCurrentHP()
    local atkMaxHP = attacker:Attributes():CalcMaxHp()
    local defPercent = math.modf(defHP / defMaxHP * 1000)
    local atkPercent = math.modf(atkHP / atkMaxHP * 1000)
    if atkPercent > defPercent then
        return true
    else
        return false
    end
end

_class("TTDefHPPercentGreater", TriggerBase)
---@class TTDefHPPercentGreater:TriggerBase
TTDefHPPercentGreater = TTDefHPPercentGreater
---@param notify NotifyAttackBase
function TTDefHPPercentGreater:IsSatisfied(notify)
    if not notify.GetAttackerEntity or not notify.GetDefenderEntity then
        return false
    end
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    ---@type Entity
    local attacker = notify:GetAttackerEntity()
    ---@type Entity
    local defender = notify:GetDefenderEntity()

    local atkHP = attacker:Attributes():GetCurrentHP()
    local atkMaxHP = attacker:Attributes():CalcMaxHp()

    if attacker:HasPetPstID() then
        if not (defender:MonsterID() or defender:HasTeam()) then
            return false
        end
        atkHP, atkMaxHP = battleService:GetCasterHP(attacker)
    else
        return false
    end
    local defHP = defender:Attributes():GetCurrentHP()
    local defMaxHP = defender:Attributes():CalcMaxHp()

    local defPercent = math.modf(defHP / defMaxHP * 1000)
    local atkPercent = math.modf(atkHP / atkMaxHP * 1000)
    if atkPercent < defPercent then
        return true
    else
        return false
    end
end

_class("TTChainSkillCount", TriggerBase)
TTChainSkillCount = TTChainSkillCount

---@param notify NTChainSkillTurnEnd
function TTChainSkillCount:IsSatisfied(notify)
    local cnt = notify:GetChainSkillCount()
    return cnt >= self._x
end

_class("TTNotifyMeEffectType", TriggerBase)
TTNotifyMeEffectType = TTNotifyMeEffectType

---@param notify NotifyAttackBase
function TTNotifyMeEffectType:IsSatisfied(notify)
    if notify.GetEffectType and notify:GetEffectType() and self.x then
        return notify:GetEffectType() == self.x and notify:GetNotifyEntity():GetID() == self:GetOwnerEntity():GetID()
    end
    return false
end

_class("TTNotifySkill", TriggerBase)
TTNotifySkill = TTNotifySkill

---@param notify NotifyAttackBase
function TTNotifySkill:IsSatisfied(notify)
    return table.icontains(self._param, notify:GetSkillID())
end

_class("TTNotifyEffectType", TriggerBase)
TTNotifyEffectType = TTNotifyEffectType

---@param notify NotifyAttackBase
function TTNotifyEffectType:IsSatisfied(notify)
    if notify.GetEffectType and notify:GetEffectType() and self._x then
        return notify:GetEffectType() == self._x
    end
    return false
end

_class("TTLayerBiggerThan", TriggerBase)
TTLayerBiggerThan = TTLayerBiggerThan
function TTLayerBiggerThan:IsSatisfied(notify)
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layerName = svc:GetBuffLayerName(self._x)
    local layerCount = svc:GetBuffLayer(self:GetOwnerEntity(), self._x)
    if layerCount and layerCount >= self._y then
        return true
    end
    return false
end

--通知的被打者是自己
_class("TTNotifyDefenderIsMe", TriggerBase)
---@class TTNotifyDefenderIsMe:TriggerBase
TTNotifyDefenderIsMe = TTNotifyDefenderIsMe

function TTNotifyDefenderIsMe:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    if owner:HasPet() then
        owner = owner:Pet():GetOwnerTeamEntity()
    end
    local entity = notify:GetDefenderEntity()
    return owner:GetID() == entity:GetID()
end

function Algorithm.CmpByOperator(value, target, operator)
    if type(value) ~= "number" or type(target) ~= "number" then
        return false
    end
    if operator == ComparisonOperator.EQ then
        return value == target
    elseif operator == ComparisonOperator.NE then
        return value ~= target
    elseif operator == ComparisonOperator.GT then
        return value > target
    elseif operator == ComparisonOperator.GE then
        return value >= target
    elseif operator == ComparisonOperator.LT then
        return value < target
    elseif operator == ComparisonOperator.LE then
        return value <= target
    end
    return false
end

--判断目标数量
_class("TTDefenderCount", TriggerBase)
---@class TTDefenderCount:TriggerBase
TTDefenderCount = TTDefenderCount

function TTDefenderCount:IsSatisfied(notify)
    local targetCount = notify:GetTargetCount()

    local cmpType = self._param[1]
    local count = self._param[2]
    return Algorithm.CmpByOperator(targetCount, count, cmpType)
end

--判断目标数量
_class("TTCmpDeferHPAndAtkerAtk", TriggerBase)
---@class TTCmpDeferHPAndAtkerAtk:TriggerBase
TTCmpDeferHPAndAtkerAtk = TTCmpDeferHPAndAtkerAtk
---@param notify NotifyAttackBase
function TTCmpDeferHPAndAtkerAtk:IsSatisfied(notify)
    if not notify.GetDefenderEntity or not notify.GetAttackerEntity then
        return false
    end
    ----@type Entity
    local defender = notify:GetDefenderEntity()
    ----@type Entity
    local attacker = notify:GetAttackerEntity()
    local defenderHP = defender:Attributes():GetCurrentHP()
    if not defenderHP then
        return false
    end
    ----@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local attackerAtkNum = buffLogicService:GetAttributeValue(attacker, "Attack")
    local cmpType = self._param[1]
    local count = self._param[2] * attackerAtkNum
    return Algorithm.CmpByOperator(defenderHP, count, cmpType)
end

---@class TTIsDefenderPlayer : TriggerBase
_class("TTIsDefenderPlayer", TriggerBase)
TTIsDefenderPlayer = TTIsDefenderPlayer

---@param notify NotifyAttackBase
function TTIsDefenderPlayer:IsSatisfied(notify)
    if not NotifyAttackBase:IsInstanceOfType(notify) then
        return false
    end

    local def = notify:GetDefenderEntity()
    local eDef
    if type(def) == "number" then
        eDef = self._world:GetEntityByID(def)
    elseif Entity:IsInstanceOfType(def) then
        eDef = def
    end

    if not eDef then
        return false
    end

    return eDef:HasTeam() or eDef:HasPetPstID()
end

--region     TrapExist = 278, --存在指定机关
---@class TTTrapExist:TriggerBase
_class("TTTrapExist", TriggerBase)
TTTrapExist = TTTrapExist
---@param notify NotifyAttackBase
function TTTrapExist:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    ---@type MainWorld
    local world = owner:GetOwnerWorld()
    local trapGroup = world:GetGroup(world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            local trapID = e:Trap():GetTrapID()

            if table.intable(self._param, trapID) then
                return true
            end
        end
    end

    return false
end

--endregion

_class("TTMonsterAliveCount", TriggerBase)
---@class TTMonsterAliveCount:TriggerBase
TTMonsterAliveCount = TTMonsterAliveCount

function TTMonsterAliveCount:IsSatisfied(notify)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    local monsterAliveCount = battleService:GetAliveMonsterCount()
    if self._world:MatchType() == MatchType.MT_BlackFist then
        monsterAliveCount = 1
    end
    return Algorithm.CmpByOperator(monsterAliveCount, self._y, self._x)
end

_class("TTPlayerHPRecovered", TriggerBase)
---@class TTPlayerHPRecovered : TriggerBase
TTPlayerHPRecovered = TTPlayerHPRecovered

function TTPlayerHPRecovered:IsSatisfied(notify)
    return notify:GetChangeHP() > 0
end

_class("TTIsAttachMonsterDead", TriggerBase)
---@class TTIsAttachMonsterDead : TriggerBase
TTIsAttachMonsterDead = TTIsAttachMonsterDead
---@param notify  NTMonsterDead
function TTIsAttachMonsterDead:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.MonsterDead then
        return false
    end
    local deadMonsterEntity = notify:GetNotifyEntity()
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if not owner:AI() then
        return false
    end
    local attachMonsterID = owner:AI():GetRuntimeData("AttachMonsterID")
    return deadMonsterEntity:GetID() == attachMonsterID
end

_class("TTChainPathTypeElement", TriggerBase)
---@class TTChainPathTypeElement : TriggerBase
TTChainPathTypeElement = TTChainPathTypeElement
---@param notify  NTNormalAttackStart
function TTChainPathTypeElement:IsSatisfied(notify)
    if not notify.GetChainPathType then
        return false
    end
    ---@type PieceType
    local chainPathType = notify:GetChainPathType()
    return table.icontains(self._param, chainPathType)
end

_class("TTBuffEffectMatch", TriggerBase)
TTBuffEffectMatch = TTBuffEffectMatch

function TTBuffEffectMatch:IsSatisfied(notify)
    local effctType = notify:GetBuffEffectType()
    return table.icontains(self._param, effctType)
end

_class("TTRemoveDuplicateDefender", TriggerBase)
TTRemoveDuplicateDefender = TTRemoveDuplicateDefender

function TTRemoveDuplicateDefender:Constructor()
    self._defenderIds = {}
end

function TTRemoveDuplicateDefender:IsSatisfied(notify)
    local es = notify:GetTargetEntityList()
    local e = es[1]
    if e and not table.icontains(self._defenderIds, e:GetID()) then
        self._defenderIds[#self._defenderIds + 1] = e:GetID()
        return true
    end
    return false
end

--施法者是机关
_class("TTNotifyEntityIsPetOrTrap", TriggerBase)
---@class TTNotifyEntityIsPetOrTrap:TriggerBase
TTNotifyEntityIsPetOrTrap = TTNotifyEntityIsPetOrTrap

function TTNotifyEntityIsPetOrTrap:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    if entity:HasPetPstID() then
        return true
    end

    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if trapCmpt then
        return true
    end

    return false
end

_class("TTNotifyNotMe", TriggerBase)
---@class TTNotifyNotMe:TriggerBase
TTNotifyNotMe = TTNotifyNotMe
function TTNotifyNotMe:IsSatisfied(notify)
    local notifyEntity = notify:GetNotifyEntity()
    if not notifyEntity or notifyEntity:MonsterID() then
        return false
    end
    local ownerEntity = self:GetOwnerEntity()

    return ownerEntity:GetID() ~= notifyEntity:GetID()
end

_class("TTStickerNeedToDie", TriggerBase)
---@class TTStickerNeedToDie:TriggerBase
TTStickerNeedToDie = TTStickerNeedToDie
function TTStickerNeedToDie:IsSatisfied(notify)
    local ownerEntity = self:GetOwnerEntity()
    local pos = ownerEntity:GetGridPosition()
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es =
        boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return e:HasTeam()
        end
    )
    --人站在上面不能触发贴纸死亡
    if #es > 0 then
        return false
    end
    local triggerCnt = ownerEntity:Trap():GetCurrentTriggerCount()
    return triggerCnt > 0
end

_class("TTPosInSpTrap", TriggerBase)
---@class TTPosInSpTrap:TriggerBase
TTPosInSpTrap = TTPosInSpTrap
---@param notify INotifyBase
function TTPosInSpTrap:IsSatisfied(notify)
    local ownerEntity = self:GetOwnerEntity()
    local pos
    if notify:GetNotifyType() == NotifyType.Teleport then
        pos = notify:GetPosNew()
        local casterEntity = notify:GetNotifyEntity()
        if casterEntity:GetID() ~= ownerEntity:GetID() then
            return false
        end
    end
    if notify:GetNotifyType() == NotifyType.HitBackEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID ~= ownerEntity:GetID() then
            return false
        end
    end
    if notify:GetNotifyType() == NotifyType.TractionEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID ~= ownerEntity:GetID() then
            return false
        end
    end
    if not pos then
        return false
    end
    ---@type TrapServiceLogic
    local trapLogic = self._world:GetService("TrapLogic")
    local trapIDList = trapLogic:FindTrapIDByPos(pos)
    return table.intable(trapIDList, self._x)
end

_class("TTPosNoInSpTrap", TriggerBase)
---@class TTPosNoInSpTrap:TriggerBase
TTPosNoInSpTrap = TTPosNoInSpTrap
---@param notify INotifyBase
function TTPosNoInSpTrap:IsSatisfied(notify)
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()

    local pos
    if notify:GetNotifyType() == NotifyType.Teleport then
        pos = notify:GetPosNew()
        local casterEntity = notify:GetNotifyEntity()
        if casterEntity:GetID() ~= ownerEntity:GetID() then
            return false
        end
    end
    if notify:GetNotifyType() == NotifyType.HitBackEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID ~= ownerEntity:GetID() then
            return false
        end
    end
    if notify:GetNotifyType() == NotifyType.TractionEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID ~= ownerEntity:GetID() then
            return false
        end
    end
    if not pos then
        return false
    end
    ---@type TrapServiceLogic
    local trapLogic = self._world:GetService("TrapLogic")
    local trapIDList = trapLogic:FindTrapIDByPos(pos)
    return not table.intable(trapIDList, self._x)
end

--波数匹配
_class("TTWaveNumMatch", TriggerBase)

TTWaveNumMatch = TTWaveNumMatch

function TTWaveNumMatch:IsSatisfied(notify)
    local waveNum = notify:GetWaveNum()
    if waveNum and table.intable(self._param, waveNum) then
        return true
    end
    return false
end

--region TTAtkTargetPosMarkedByAttacker
---@class TTAtkTargetPosMarkedByAttacker : TriggerBase
_class("TTAtkTargetPosMarkedByAttacker", TriggerBase)
TTAtkTargetPosMarkedByAttacker = TTAtkTargetPosMarkedByAttacker

-- TriggerBase:Constructor(owner, triggerCond)
function TTAtkTargetPosMarkedByAttacker:Constructor(_owner, _triggerCond, series)
    self._series = series or 1
end

---@param notify NotifyAttackBase
function TTAtkTargetPosMarkedByAttacker:IsSatisfied(notify)
    ---@type Entity
    local eAttacker = notify:GetAttackerEntity()
    if not eAttacker:HasMarkGridComponent() then
        return false
    end

    ---@type MarkGridComponent
    local cMarkGrid = eAttacker:MarkGridComponent()

    return cMarkGrid:IsPosMarked(self._series, Vector2.Pos2Index(notify:GetTargetPos()))
end

--endregion

--血量>x触发
_class("TTSimpleHPMoreThan", TriggerBase)
TTSimpleHPMoreThan = TTSimpleHPMoreThan

function TTSimpleHPMoreThan:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    local entity = notify:GetNotifyEntity()
    local curhp = owner:Attributes():GetCurrentHP()
    local maxhp = owner:Attributes():CalcMaxHp()

    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        local cAttr = teamEntity:Attributes()
        curhp = cAttr:GetCurrentHP()
        maxhp = cAttr:CalcMaxHp()
    end

    local blood = curhp / maxhp
    --20200711 注掉 * 100 咱们一般都配置0.5这种，有其他地方用么？
    return blood > self._x
end

_class("TTResetGridFlushTrapPosNoInMy", TriggerBase)
---@class TTResetGridFlushTrapPosNoInMy:TriggerBase
TTResetGridFlushTrapPosNoInMy = TTResetGridFlushTrapPosNoInMy
---@param notify NTResetGridFlushTrap
function TTResetGridFlushTrapPosNoInMy:IsSatisfied(notify)
    ----@type Entity[]
    local trapList
    if notify:GetNotifyType() == NotifyType.ResetGridFlushTrap then
        trapList = notify:GetFlushTrapList()
    end
    if not trapList then
        return false
    end
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    local ownerPos = ownerEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local areaCmpt = ownerEntity:BodyArea()
    local areaList = areaCmpt:GetArea()
    local onwerPosList = {}

    for i, area in ipairs(areaList) do
        table.insert(onwerPosList, Vector2(ownerPos.x + area.x, ownerPos.y + area.y))
    end

    for _, entity in ipairs(trapList) do
        local pos = entity:GetGridPosition()
        ---@type TrapComponent
        local trapComponent = entity:Trap()
        if trapComponent and trapComponent:GetTrapID() then
            if table.Vector2Include(onwerPosList, pos) and trapComponent:GetTrapID() == self._x then
                return true
            end
        end
    end
    return false
end

--region SkillScopeCompareTargetCount = 299, --范围内对比怪物数量
---@class TTSkillScopeCompareTargetCount:TriggerBase
_class("TTSkillScopeCompareTargetCount", TriggerBase)
TTSkillScopeCompareTargetCount = TTSkillScopeCompareTargetCount

function TTSkillScopeCompareTargetCount:OnNotify(notify)
end

function TTSkillScopeCompareTargetCount:IsSatisfied(notify)
    local skillID = self._param[1]
    local compareFlag = self._param[2] --比较操作枚举
    local count = self._param[3] --配置的比较数量数

    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    local ownerPos = ownerEntity:GetGridPosition()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local skillTargetType = skillConfigData:GetSkillTargetType()

    ---计算连锁技范围
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, ownerPos, ownerEntity)

    ---计算范围内目标
    local targetEntityIDArray = targetSelector:DoSelectSkillTarget(ownerEntity, skillTargetType, scopeResult, skillID)

    ---去重
    local entityIDArray = {}
    for i = 1, #targetEntityIDArray do
        if not table.icontains(entityIDArray, targetEntityIDArray[i]) then
            table.insert(entityIDArray, targetEntityIDArray[i])
        end
    end

    local targetEntityCount = 0
    for _, targetID in ipairs(entityIDArray) do
        local targetEntity = self._world:GetEntityByID(targetID)
        if targetEntity and not targetEntity:HasDeadMark() then
            targetEntityCount = targetEntityCount + 1
        end
    end

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = targetEntityCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = targetEntityCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = targetEntityCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = targetEntityCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = targetEntityCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = targetEntityCount <= count
    end
    return satisfied
end

_class("TTTargetAroundBodyAreaCompareMonsterCount", TriggerBase)
---@class TTTargetAroundBodyAreaCompareMonsterCount:TriggerBase
TTTargetAroundBodyAreaCompareMonsterCount = TTTargetAroundBodyAreaCompareMonsterCount

---@param notify NTGridConvert
function TTTargetAroundBodyAreaCompareMonsterCount:IsSatisfied(notify)
    local ringCount = self._param[1] --圈数
    local compareFlag = self._param[2] --比较操作枚举
    local count = self._param[3] --配置的比较数量数

    ---@type Entity
    local targetEntity = nil
    if notify.GetDefenderEntity then
        targetEntity = notify:GetDefenderEntity()
    end
    if not targetEntity then
        targetEntity = self:GetOwnerEntity()
    end

    local v2SelfGridPos = targetEntity:GetGridPosition()
    local bodyArea = targetEntity:BodyArea():GetArea()
    local v2SelfDir = targetEntity:GetGridDirection()

    ---@type UtilScopeCalcServiceShare
    local scopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(scopeSvc)
    local scopeResult =
    scopeCalc:ComputeScopeRange(
            SkillScopeType.AroundBodyArea,
            {0, ringCount},
            v2SelfGridPos,
            bodyArea,
            v2SelfDir,
            SkillTargetType.Monster,
            v2SelfGridPos
    )

    local posList = scopeResult:GetAttackRange()

    --不能直接用范围算好的目标。需求是计算所有活着怪物的数量，包括哪些不可被选择为目标的怪物。需要重新计算目标
    local monsterEntityList = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        --不计算自己
        if not e:HasDeadMark() and e:GetID() ~= targetEntity:GetID() then
            ---@type BodyAreaComponent
            local bodyAreaCmpt = e:BodyArea()
            local bodyArea = bodyAreaCmpt:GetArea()
            ---@type Vector2
            local myPos = e:GetGridPosition()
            for i, v in ipairs(bodyArea) do
                local pos = myPos + v
                if table.intable(posList, pos) then
                    table.insert(monsterEntityList, e)
                    break
                end
            end
        end
    end

    local targetEntityCount = table.count(monsterEntityList)

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = targetEntityCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = targetEntityCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = targetEntityCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = targetEntityCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = targetEntityCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = targetEntityCount <= count
    end
    return satisfied
end

_class("TTTeamInActiveSkillScope", TriggerBase)
---@class TTTeamInActiveSkillScope:TriggerBase
TTTeamInActiveSkillScope = TTTeamInActiveSkillScope
function TTTeamInActiveSkillScope:IsSatisfied(notify)
    local calcScopeWithPickUpPosIndex = self._param[1] --使用点选坐标计算范围,不写默认施法者坐标，1是点选的第一个点，2是第二个点

    ---@type Entity
    local casterEntity = self:GetOwnerEntity()
    local centerPos = casterEntity:GetGridPosition()

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = casterEntity:ActiveSkillPickUpComponent()
    if calcScopeWithPickUpPosIndex and pickupComponent then
        local pickUpGridArray = pickupComponent:GetAllValidPickUpGridPos()
        centerPos = pickUpGridArray[calcScopeWithPickUpPosIndex]
        if not centerPos then
            centerPos = pickupComponent:GetLastPickUpGridPos()
        end
    end

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()
    ---@type ActiveSkillComponent
    local activeSkillCmpt = teamEntity:ActiveSkill()
    local activeSkillID = activeSkillCmpt:GetActiveSkillID()

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, centerPos, casterEntity)

    local skillRangeGridList = scopeResult:GetAttackRange()

    if table.icontains(skillRangeGridList, teamPos) then
        return true
    end

    return false
end

_class("TTNTTrapPosInMy", TriggerBase)
---@class TTNTTrapPosInMy:TriggerBase
TTNTTrapPosInMy = TTNTTrapPosInMy
---@param notify NTTrapShow
function TTNTTrapPosInMy:IsSatisfied(notify)
    ---@type Entity
    local entity
    if notify:GetNotifyType() == NotifyType.TrapDead or notify:GetNotifyType() == NotifyType.TrapShow then
        entity = notify:GetNotifyEntity()
    end
    if not entity then
        return false
    end
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    local ownerPos = ownerEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local areaCmpt = ownerEntity:BodyArea()
    local areaList = areaCmpt:GetArea()
    local onwerPosList = {}

    for i, area in ipairs(areaList) do
        table.insert(onwerPosList, Vector2(ownerPos.x + area.x, ownerPos.y + area.y))
    end

    local pos = entity:GetGridPosition()
    ---@type TrapComponent
    local trapComponent = entity:Trap()
    if trapComponent and trapComponent:GetTrapID() then
        if table.Vector2Include(onwerPosList, pos) and trapComponent:GetTrapID() == self._x then
            return true
        end
    end
    return false
end

--endregion

--region     DefenderHasMostBuffLayer = 301, ---被击者是拥有指定buff层数最多的怪物，层数大于0，层数相同选血量最多的
_class("TTDefenderHasMostBuffLayer", TriggerBase)
---@class TTDefenderHasMostBuffLayer:TriggerBase
TTDefenderHasMostBuffLayer = TTDefenderHasMostBuffLayer

---@param notify NotifyAttackBase
function TTDefenderHasMostBuffLayer:IsSatisfied(notify)
    local defenderEntity = notify:GetDefenderEntity()
    if not defenderEntity then
        return false
    end
    ---@type BuffComponent
    local buffCmp = defenderEntity:BuffComponent()
    if not buffCmp then
        return false
    end
    self._satisfied = false

    local buffEffectType = self._x
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")

    local monsterEntityList = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            table.insert(monsterEntityList, e)
        end
    end

    --黑拳赛
    if defenderEntity:HasTeam() then
        table.insert(monsterEntityList, defenderEntity)
    end

    if table.count(monsterEntityList) == 0 then
        return false
    end

    --对比buff的层数
    local hasMostBuffLayerMonsterEntityList = {}
    local mostBuffLayer = 0
    for _, e in ipairs(monsterEntityList) do
        local curMarkLayer = svc:GetBuffLayer(e, buffEffectType)
        if curMarkLayer > mostBuffLayer then
            table.clear(hasMostBuffLayerMonsterEntityList)
            table.insert(hasMostBuffLayerMonsterEntityList, e)
            mostBuffLayer = curMarkLayer
        elseif curMarkLayer == mostBuffLayer and curMarkLayer ~= 0 then
            table.insert(hasMostBuffLayerMonsterEntityList, e)
        end
    end

    if table.count(hasMostBuffLayerMonsterEntityList) == 0 then
        return false
    end

    local hasMostBuffLayerMonsterEntity
    --buff层数都一样，对比血量最多的
    if table.count(hasMostBuffLayerMonsterEntityList) > 0 then
        local mostHp = 0
        for _, e in ipairs(hasMostBuffLayerMonsterEntityList) do
            local curhp = e:Attributes():GetCurrentHP()
            if curhp > mostHp then
                curhp = mostHp
                hasMostBuffLayerMonsterEntity = e
            end
        end
    end

    if not hasMostBuffLayerMonsterEntity then
        return false
    end

    self._satisfied = hasMostBuffLayerMonsterEntity:GetID() == defenderEntity:GetID()

    return self._satisfied
end

--endregion

_class("TTCurseTowerIsActive", TriggerBase)
---@class TTCurseTowerIsActive:TriggerBase
TTCurseTowerIsActive = TTCurseTowerIsActive

function TTCurseTowerIsActive:IsSatisfied(notify)
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    ---@type CurseTowerComponent
    local curseTowerCmpt = ownerEntity:CurseTower()
    if not curseTowerCmpt then
        return false
    end

    local towerState = curseTowerCmpt:GetTowerState()
    if towerState == CurseTowerState.Deactive then
        return false
    end

    return true
end

_class("TTOwnerGridPosChange", TriggerBase)
---@class TTOwnerGridPosChange:TriggerBase
TTOwnerGridPosChange = TTOwnerGridPosChange
---@param notify INotifyBase
function TTOwnerGridPosChange:IsSatisfied(notify)
    local ownerEntity = self:GetOwnerEntity()
    local pos
    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        pos = notify:GetWalkPos()
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:GetID() == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.Teleport then
        pos = notify:GetPosNew()
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:GetID() == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.HitBackEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.TractionEnd then
        pos = notify:GetPosEnd()
        local defenderID = notify:GetDefenderId()
        if defenderID == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        local pet = notify:GetNotifyEntity()
        local team = pet:Pet():GetOwnerTeamEntity()
        if team:GetID() == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.ForceMovement then
        pos = notify:GetPosNew()
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:GetID() == ownerEntity:GetID() then
            return true
        end
    end
    if notify:GetNotifyType() == NotifyType.TransportEachMoveEnd then
        pos = notify:GetPosNew()
        local notifyEntity = notify:GetNotifyEntity()
        if notifyEntity:GetID() == ownerEntity:GetID() then
            return true
        end
    end
    return false
end

_class("TTConvertSourceEffectType", TriggerBase)
---@class TTConvertSourceEffectType:TriggerBase
TTConvertSourceEffectType = TTConvertSourceEffectType

---@param notify NTGridConvert
function TTConvertSourceEffectType:IsSatisfied(notify)
    if type(notify.GetConvertEffectType) ~= "function" then
        Log.error(self._className, "通知与判定不兼容。")
        return false
    end

    local source = notify:GetConvertEffectType()
    if (not source) then
        return false
    end

    return table.icontains(self._param, source)
end

--    NotifyEntityIsOwnerSummonerEntity = 306, --buff通知的entity是buff持有者的召唤者
---@class TTNotifyEntityIsOwnerSummonerEntity:TriggerBase
_class("TTNotifyEntityIsOwnerSummonerEntity", TriggerBase)
TTNotifyEntityIsOwnerSummonerEntity = TTNotifyEntityIsOwnerSummonerEntity
function TTNotifyEntityIsOwnerSummonerEntity:IsSatisfied(notify)
    if not notify.GetNotifyEntity then
        return false
    end
    ---@type Entity
    local entity = notify:GetNotifyEntity()
    ---@type Entity
    local owner = self:GetOwnerEntity()
    ---@type Entity
    local ownerSummonerEntity = owner:GetSummonerEntity()
    if not ownerSummonerEntity then
        return false
    end

    local satisfied = entity:GetID() == ownerSummonerEntity:GetID()
    return satisfied
end

---@class TTTrapTriggerIsMyTeam:TriggerBase
_class("TTTrapTriggerIsMyTeam", TriggerBase)
TTTrapTriggerIsMyTeam = TTTrapTriggerIsMyTeam
function TTTrapTriggerIsMyTeam:IsSatisfied(notify)
    if not notify.GetTriggerEntity then
        return false
    end

    local triggerEnitity = notify:GetTriggerEntity()
    if not triggerEnitity then
        return true
    end
    if triggerEnitity:HasPet() then
        triggerEnitity = triggerEnitity:Pet():GetOwnerTeamEntity()
    end

    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:HasPet() then
        ownerEntity = ownerEntity:Pet():GetOwnerTeamEntity()
    end

    return triggerEnitity == ownerEntity
end

---@class TTNotifyFriendPetOrTeam:TriggerBase
_class("TTNotifyFriendPetOrTeam", TriggerBase)
TTNotifyFriendPetOrTeam = TTNotifyFriendPetOrTeam
function TTNotifyFriendPetOrTeam:IsSatisfied(notify)
    local notifyEntity = notify:GetNotifyEntity()
    if notifyEntity:HasPet() then
        notifyEntity = notifyEntity:Pet():GetOwnerTeamEntity()
    end

    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:HasPet() then
        ownerEntity = ownerEntity:Pet():GetOwnerTeamEntity()
    end

    return notifyEntity:GetID() == ownerEntity:GetID()
end

_class("TTDonotCheckGameTurn", TriggerBase)
TTDonotCheckGameTurn = TTDonotCheckGameTurn

function TTDonotCheckGameTurn:IsSatisfied(notify)
    return true
end

_class("TTCasterIsLegendPet", TriggerBase)
---@class TTCasterIsLegendPet:TriggerBase
TTCasterIsLegendPet = TTCasterIsLegendPet

---@param notify NTGridConvert
function TTCasterIsLegendPet:IsSatisfied(notify)
    if
        notify:GetNotifyType() ~= NotifyType.ActiveSkillAttackStart and
            notify:GetNotifyType() ~= NotifyType.ActiveSkillAttackEnd
     then
        return false
    end
    ---@type Entity
    local casterEntity = notify:GetAttackerEntity()
    if casterEntity:HasPetPstID() and casterEntity:PetPstID():IsLegendPet() then
        return true
    end
    return false
end

--IsAuroraTime = 308, --极光时刻
_class("TTIsAuroraTime", TriggerBase)
---@class TTIsAuroraTime:TriggerBase
TTIsAuroraTime = TTIsAuroraTime

---@param notify NTGridConvert
function TTIsAuroraTime:IsSatisfied(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    return battleStatCmpt:IsRoundAuroraTime()
end

---@class TTAttackerIsMeOrAttackerSuperIsMe:TriggerBase
_class("TTAttackerIsMeOrAttackerSuperIsMe", TriggerBase)
TTAttackerIsMeOrAttackerSuperIsMe = TTAttackerIsMeOrAttackerSuperIsMe
---@param notify NotifyAttackBase
function TTAttackerIsMeOrAttackerSuperIsMe:IsSatisfied(notify)
    ---@type Entity
    local attackEntity = notify:GetAttackerEntity()
    local ownerEntity = self:GetOwnerEntity()
    if attackEntity:GetID() == ownerEntity:GetID() then
        return true
    end

    if attackEntity:HasSuperEntity() and attackEntity:GetSuperEntity():GetID() == ownerEntity:GetID() then
        return true
    end

    return false
end

---@class TTTeamLeaderMoveEndPosInRingRange : TriggerBase
_class("TTTeamLeaderMoveEndPosInRingRange", TriggerBase)
TTTeamLeaderMoveEndPosInRingRange = TTTeamLeaderMoveEndPosInRingRange

---@param notify NTTeamLeaderEachMoveEnd
function TTTeamLeaderMoveEndPosInRingRange:IsSatisfied(notify)
    local world = notify:GetNotifyEntity():GetOwnerWorld()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()

    local scopeParamParser = SkillScopeParamParser:New()
    local param = scopeParamParser:ParseScopeParam(SkillScopeType.SquareRing, self._param)

    local bodyArea = self:GetOwnerEntity():BodyArea():GetArea()

    local scopeResult =
        scopeCalc:ComputeScopeRange(
        SkillScopeType.SquareRing,
        param,
        self:GetOwnerEntity():GetGridPosition(),
        bodyArea,
        self:GetOwnerEntity():GetGridDirection(),
        SkillTargetType.Pet,
        self:GetOwnerEntity():GetGridPosition(),
        self:GetOwnerEntity()
    )

    if not scopeResult:GetAttackRange() then
        return false
    end

    return table.icontains(scopeResult:GetAttackRange(), notify:GetPos())
end

---@class TTNotifyEntityIsSpecificPet:TriggerBase
_class("TTNotifyEntityIsSpecificPet", TriggerBase)
TTNotifyEntityIsSpecificPet = TTNotifyEntityIsSpecificPet
---@param notify NTActiveSkillAttackEnd
function TTNotifyEntityIsSpecificPet:IsSatisfied(notify)
    if not notify.GetNotifyEntity then
        return false
    end
    local notifyEntity = notify:GetNotifyEntity()
    if notifyEntity:HasPetPstID() and table.icontains(self._param, notifyEntity:PetPstID():GetTemplateID()) then
        return true
    end

    return false
end

---@class TTNotifyTrapLevelMatch:TriggerBase
_class("TTNotifyTrapLevelMatch", TriggerBase)
TTNotifyTrapLevelMatch = TTNotifyTrapLevelMatch
---@param notify NTActiveSkillAttackEnd
function TTNotifyTrapLevelMatch:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if not trapCmpt then
        return false
    end

    local trapLevel = trapCmpt:GetTrapLevel()
    if table.icontains(self._param, trapLevel) then
        return true
    end

    return false
end

---@class TTNotifyTrapIDMatch:TriggerBase
_class("TTNotifyTrapIDMatch", TriggerBase)
TTNotifyTrapIDMatch = TTNotifyTrapIDMatch
function TTNotifyTrapIDMatch:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    ---@type TrapComponent
    local trapCmpt = entity:Trap()
    if not trapCmpt then
        return false
    end

    local trapID = trapCmpt:GetTrapID()
    if table.icontains(self._param, trapID) then
        return true
    end

    return false
end

_class("TTNotifyEntityInOwnerBodyArea", TriggerBase)
---@class TTNotifyEntityInOwnerBodyArea:TriggerBase
TTNotifyEntityInOwnerBodyArea = TTNotifyEntityInOwnerBodyArea
---@param notify NTTrapShow
function TTNotifyEntityInOwnerBodyArea:IsSatisfied(notify)
    ---@type Entity
    local entity = notify:GetNotifyEntity()

    if not entity then
        return false
    end

    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    local ownerPos = ownerEntity:GetGridPosition()
    ---@type BodyAreaComponent
    local areaCmpt = ownerEntity:BodyArea()
    local areaList = areaCmpt:GetArea()
    local onwerPosList = {}

    for i, area in ipairs(areaList) do
        table.insert(onwerPosList, Vector2(ownerPos.x + area.x, ownerPos.y + area.y))
    end

    local pos = entity:GetGridPosition()
    ---@type TrapComponent
    local trapComponent = entity:Trap()
    if trapComponent and trapComponent:GetTrapID() then
        if table.Vector2Include(onwerPosList, pos) then
            return true
        end
    end
    return false
end

--判断buff层数 可被{N1,N2,...}中一个整除
---@class TTLayerCountDivisible:TriggerBase
_class("TTLayerCountDivisible", TriggerBase)
TTLayerCountDivisible = TTLayerCountDivisible

function TTLayerCountDivisible:IsSatisfied(notify) --buffId为_x的层数达到_y时，返回true
    local buffId = self._param[1] --buffId

    local e = self:GetOwnerEntity()
    local cBuff = e:BuffComponent()
    local layerCount = 0
    local instance = cBuff:GetBuffById(buffId)
    if instance then
        local layerName = instance:GetBuffLayerName()
        layerCount = cBuff:GetBuffValue(layerName) or 0
    end
    if layerCount == 0 then
        return false
    end
    local totalParam = #self._param
    local bDivesible = false
    for i = 2, totalParam do
        local divNum = self._param[i]
        if divNum == 0 then
        else
            local a, b = math.modf(layerCount / divNum)
            if b == 0 then
                bDivesible = true
                break
            end
        end
    end
    return bDivesible
end

---@class TTChainSkillStage:TriggerBase
_class("TTChainSkillStage", TriggerBase)
TTChainSkillStage = TTChainSkillStage
---@param notify NTChainSkillAttackStart
---@param notify NTChainSkillAttackEnd
function TTChainSkillStage:IsSatisfied(notify)
    local chainStage = self._param[1] --chainStage 连锁技能阶段
    if notify.GetChainSkillStage then
        local curStage = notify:GetChainSkillStage()
        if curStage and chainStage and curStage == chainStage then
            return true
        end
    end
    return false
end

_class("TTTeamInSideSkillScope", TriggerBase)
---@class TTTeamInSideSkillScope:TriggerBase
TTTeamInSideSkillScope = TTTeamInSideSkillScope
function TTTeamInSideSkillScope:IsSatisfied(notify)
    local skillID = self._param[1]
    local inSide = self._param[2] or 1 --默认1在范围内，0是不在范围内

    --不同notify传pos的方法都不一样
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posTeam = teamEntity:GridLocation().Position
    local curMovePos = posTeam
    if
        notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
     then
        curMovePos = notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        curMovePos = notify:GetPosNew()
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd and notify:GetDefenderId() == teamEntity:GetID() then
        curMovePos = notify:GetPosEnd()
    elseif notify:GetNotifyType() == NotifyType.EntityMoveEnd then
        curMovePos = notify:GetPosNew()
    end

    --使用施法者机关的坐标计算技能范围
    local ownerEntity = self:GetOwnerEntity()
    local bodyArea = ownerEntity:BodyArea():GetArea()
    local posSelf = ownerEntity:GridLocation().Position
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, posSelf, Vector2(0, 1), bodyArea)

    --判断范围是否包含notify的坐标
    local match = table.icontains(skillResult:GetAttackRange(), curMovePos)
    if inSide == 1 then
        return match
    elseif inSide == 0 then
        return not match
    end

    return false
end

_class("TTMonsterInAuraRange", TriggerBase)
---@class TTMonsterInAuraRange:TriggerBase
TTMonsterInAuraRange = TTMonsterInAuraRange
function TTMonsterInAuraRange:IsSatisfied(notify)
    local auraGroupID = self._param[1]
    local inSide = self._param[2] or 1 --默认1在范围内，0是不在范围内
    local inBoss = self._param[3] or 0 --默认0不是BOSS，1是BOSS

    --不同notify传pos的方法都不一样
    ---@type Entity
    local entity = notify:GetNotifyEntity()
    local curMovePos = entity:GridLocation().Position
    local bodyArea = entity:BodyArea():GetArea()
    if notify:GetNotifyType() == NotifyType.MonsterMoveOneFinish then
        curMovePos = notify:GetWalkPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        curMovePos = notify:GetPosNew()
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd then
        entity = self._world:GetEntityByID(notify:GetDefenderId())
        curMovePos = notify:GetPosEnd()
		bodyArea = entity:BodyArea():GetArea()
    elseif notify:GetNotifyType() == NotifyType.EntityMoveEnd then
        curMovePos = notify:GetPosNew()
    elseif notify:GetNotifyType() == NotifyType.PlayerTurnStart then
        entity = self:GetOwnerEntity()
        curMovePos = entity:GridLocation().Position
		bodyArea = entity:BodyArea():GetArea()
    end

    --只判断怪物
    if not entity:HasMonsterID() then
        return false
    end

    if inBoss == 0 and entity:HasBoss() then
        return false
    end
    if inBoss == 1 and not entity:HasBoss() then
        return false
    end

    --获取光环范围
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local totalAuraRange = trapSvc:GetTotalAuraRangeByGroupID(auraGroupID)
    --判断范围是否包含notify的坐标
    -- local match = table.icontains(totalAuraRange, curMovePos)
    local match = false
    for _, value in pairs(bodyArea) do
        local workPos = curMovePos + value
        if table.icontains(totalAuraRange, workPos) then
            match = true
            break
        end
    end

    if inSide == 1 then
        return match
    elseif inSide == 0 then
        return not match
    end

    return false
end

---@class TTMoveEntityIsTeamOrPet:TriggerBase
_class("TTMoveEntityIsTeamOrPet", TriggerBase)
TTMoveEntityIsTeamOrPet = TTMoveEntityIsTeamOrPet
---@param notify NTHitBackEnd
---@param notify NTTeamLeaderEachMoveEnd
---@param notify NTTeleport
function TTMoveEntityIsTeamOrPet:IsSatisfied(notify)
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if notify:GetNotifyType() == NotifyType.HitBackEnd then
        return notify:GetDefenderId() == teamEntity:GetID()
    elseif notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd then
        return true
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        local entity = notify:GetNotifyEntity()
        return entity:HasTeam() or entity:HasPetPstID()
    elseif notify:GetNotifyType() == NotifyType.TransportEachMoveEnd then
        local entity = notify:GetNotifyEntity()
        return entity:HasTeam() or entity:HasPetPstID()
    elseif notify:GetNotifyType() == NotifyType.ForceMovement then
        local entity = notify:GetNotifyEntity()
        return entity:HasTeam() or entity:HasPetPstID()
    end

    return false
end

---判断目标列表的Buff是否匹配
_class("TTDefenderListHasBuff", TriggerBase)
---@class TTDefenderListHasBuff:TriggerBase
TTDefenderListHasBuff = TTDefenderListHasBuff

---@param notify NTChainSkillAttackEnd
function TTDefenderListHasBuff:IsSatisfied(notify)
    if notify.GetDefenderEntityIDList then
        local eids = notify:GetDefenderEntityIDList()
        for _, id in ipairs(eids) do
            local defender = self._world:GetEntityByID(id)
            ---@type BuffComponent
            local buffCmp = defender:BuffComponent()
            if buffCmp then
                for i, buffEffect in ipairs(self._param) do
                    if buffCmp:HasBuffEffect(buffEffect) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

_class("TTNotifyBuffEffectMatch", TriggerBase)
---@class TTNotifyBuffEffectMatch : TriggerBase

function TTNotifyBuffEffectMatch:IsSatisfied(notify)
    if not notify.GetBuffEffectType then
        return false
    end

    return table.icontains(self._param, notify:GetBuffEffectType())
end

_class("TTIsMeNewTeamLeader", TriggerBase)
---@class TTIsMeNewTeamLeader : TriggerBase
TTIsMeNewTeamLeader = TTIsMeNewTeamLeader

--是否满足光灵是当前队长且不是原队长
---@param notify INotifyBase
function TTIsMeNewTeamLeader:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if not owner:HasPetPstID() then
        return false
    end

    local tOldTeamOrder = notify:GetOldTeamOrder()
    local ownerPstID = owner:PetPstID():GetPstID()
    if tOldTeamOrder and ownerPstID == tOldTeamOrder[1] then
        return false
    end

    if not notify.GetNewTeamOrder then
        ---@type Entity
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        local cTeam = teamEntity:Team()
        local eTeamLeader = cTeam:GetTeamLeaderEntity()
        return owner:GetID() == eTeamLeader:GetID()
    end

    local tNewTeamOrder = notify:GetNewTeamOrder()
    if self._param[1] == 1 then
        return ownerPstID ~= tNewTeamOrder[1]
    else
        return ownerPstID == tNewTeamOrder[1]
    end
end

---owner光灵当前是队长
_class("TTOwnerPetIsTeamLeader", TriggerBase)
---@class TTOwnerPetIsTeamLeader:TriggerBase
TTOwnerPetIsTeamLeader = TTOwnerPetIsTeamLeader
function TTOwnerPetIsTeamLeader:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        if teamEntity and teamEntity:Team() then
            local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
            if teamLeaderEntityID == owner:GetID() then
                return true
            end
        end
    end
    return false
end

---本次队伍顺序变化中，owner光灵位置变化的正负值（1：向下 -1：向上 0：没变）
_class("TTOwnerPetTeamOrderChangeType", TriggerBase)
---@class TTOwnerPetTeamOrderChangeType:TriggerBase
TTOwnerPetTeamOrderChangeType = TTOwnerPetTeamOrderChangeType

---@param notify NTTeamOrderChange
function TTOwnerPetTeamOrderChangeType:IsSatisfied(notify)
    local getTeamOrderIndex = function(teamOrder, petPstID)
        for i, v in ipairs(teamOrder) do
            if v == petPstID then
                return i
            end
        end
    end
    local bSatisfied = false
    local checkOffType = tonumber(self._param[1]) or 0

    local offIndex  --偏移值
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasDeadMark() then
        return false
    end
    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        if teamEntity and teamEntity:Team() then
            local cTeam = teamEntity:Team()
            local ownerPstId = owner:PetPstID():GetPstID()
            if notify.GetOldTeamOrder and notify.GetNewTeamOrder then
                local oldOrder = notify:GetOldTeamOrder()
                local newOrder = notify:GetNewTeamOrder()
                local oldIndex = getTeamOrderIndex(oldOrder, ownerPstId)
                local newIndex = getTeamOrderIndex(newOrder, ownerPstId)
                offIndex = newIndex - oldIndex
                local curOffType = 0
                if offIndex > 0 then
                    curOffType = 1
                elseif offIndex < 0 then
                    curOffType = -1
                end
                if curOffType == checkOffType then
                    bSatisfied = true
                end
            end
        end
    end

    local operation = tonumber(self._param[2]) or 0
    if operation ~= 0 then
        local key = self:GetKeyStr()
        --操作1：记录偏移
        if operation == 1 then
            if offIndex then
                local cBuff = owner:BuffComponent()
                if cBuff then
                    cBuff:SetBuffValue(key, offIndex)
                end
            end
        end
    end

    return bSatisfied
end

function TTOwnerPetTeamOrderChangeType:GetKeyStr()
    if self._param[3] then
        return "OwnerPetTeamOrderChangeType" .. self._param[3]
    end
    return "OwnerPetTeamOrderChangeType"
end

--NotifyIsOwnerSummonerTeamOrFriendPet = 328, --buff通知的entity是buff持有者的召唤者/所在的队伍/队友
---@class TTNotifyIsOwnerSummonerTeamOrFriendPet:TriggerBase
_class("TTNotifyIsOwnerSummonerTeamOrFriendPet", TriggerBase)
TTNotifyIsOwnerSummonerTeamOrFriendPet = TTNotifyIsOwnerSummonerTeamOrFriendPet
function TTNotifyIsOwnerSummonerTeamOrFriendPet:IsSatisfied(notify)
    if not notify.GetNotifyEntity then
        return false
    end
    ---@type Entity
    local owner = self:GetOwnerEntity()
    ---@type Entity
    local ownerSummonerEntity = owner:GetSummonerEntity()
    if not ownerSummonerEntity then
        return false
    end

    --自己召唤者的队伍
    local ownerSummonerTeamEntity = nil
    if ownerSummonerEntity:Pet() then
        ownerSummonerTeamEntity = ownerSummonerEntity:Pet():GetOwnerTeamEntity()
    elseif ownerSummonerEntity:GetSuperEntity() then
        ownerSummonerTeamEntity = ownerSummonerEntity:GetSuperEntity():Pet():GetOwnerTeamEntity()
    else
        return false
    end

    ---@type Entity
    local entity = notify:GetNotifyEntity()
    if notify:GetNotifyType() == NotifyType.TractionEnd then
        local defenderID = notify:GetDefenderId()
        entity = self._world:GetEntityByID(defenderID)
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd then
        local defenderID = notify:GetDefenderId()
        entity = self._world:GetEntityByID(defenderID)
    end

    if entity:HasTeam() then
        --通知者是队伍
    elseif entity:HasPet() then
        --通知者是星灵,取星灵的队伍
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        entity = teamEntity
    elseif entity:HasTrapID() then
        --通知者是机关,取自己召唤者的队伍（用于机关的出生死亡）  如果通知的是自己就直接返回
        return entity:GetID() == owner:GetID()
    end

    local match = entity:GetID() == ownerSummonerTeamEntity:GetID()
    return match
end

--被击目标是自己
_class("TTDefenderIsMe", TriggerBase)
---@class TTDefenderIsMe:TriggerBase
TTDefenderIsMe = TTDefenderIsMe

function TTDefenderIsMe:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    if notify.GetDefenderEntity then
        local entity = notify:GetDefenderEntity()
        return owner == entity
    end
    return false
end

_class("TTOwnerPetIsNotTeamTail", TriggerBase)
TTOwnerPetIsNotTeamTail = TTOwnerPetIsNotTeamTail

function TTOwnerPetIsNotTeamTail:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()
    if not owner:HasPet() then
        return false
    end

    local cTeam = owner:Pet():GetOwnerTeamEntity():Team()
    local teamOrder = cTeam:GetTeamOrder()
    if notify.GetFormerTeamOrder and notify:GetFormerTeamOrder() then
        teamOrder = notify:GetFormerTeamOrder()
    elseif notify.GetNewTeamOrder and notify:GetNewTeamOrder() then
        teamOrder = notify:GetNewTeamOrder()
    end

    for i = #teamOrder, 1, -1 do
        local pstId = teamOrder[i]
        local e = cTeam:GetPetEntityByPetPstID(pstId)
        if e:PetPstID():IsHelpPet() then
            goto CONTINUE
        elseif e:HasPetDeadMark() then --MSG46715
            goto CONTINUE
        else
            return pstId ~= (owner:PetPstID():GetPstID())
        end
        ::CONTINUE::
    end
end

---@class TTPetInSkillScope:TriggerBase
_class("TTPetInSkillScope", TriggerBase)
TTPetInSkillScope = TTPetInSkillScope

function TTPetInSkillScope:IsSatisfied(notify)
    local skillID = self._param[1]
    local inSide = self._param[2] or 1 --默认1在范围内，0是不在范围内

    --使用施法者机关的坐标计算技能范围
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:HasDeadMark() then
        return false
    end
    local posSelf = ownerEntity:GridLocation():GetGridPos()
    local bodyArea = ownerEntity:BodyArea():GetArea()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local skillResult = skillCalculater:CalcSkillScope(skillConfigData, posSelf, Vector2(0, 1), bodyArea)

    --获取施法者光灵的位置
    local petPos = Vector2(0, 0)
    if ownerEntity:HasSummoner() then
        local petEntity = ownerEntity:GetSummonerEntity()
        if petEntity then
            petPos = petEntity:GetGridPosition()
            if petEntity:HasSuperEntity() then
                petPos = petEntity:GetSuperEntity():GetGridPosition()
            end
        end
    end

    --判断范围是否包含光灵的坐标
    local match = table.icontains(skillResult:GetAttackRange(), petPos)
    if inSide == 1 then
        return match
    elseif inSide == 0 then
        return not match
    end

    return false
end

---San值 在范围内
_class("TTSanValueInRange", TriggerBase)
---@class TTSanValueInRange:TriggerBase
TTSanValueInRange = TTSanValueInRange
function TTSanValueInRange:IsSatisfied(notify)
    local minValue = self._param[1]
    local maxValue = self._param[2]
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:HasFeatureType(FeatureType.Sanity) then
            local curSanValue = featureLogicSvc:GetSanValue()
            if curSanValue then
                if curSanValue >= minValue and curSanValue <= maxValue then
                    return true
                end
            end
        end
    end
    return false
end

---主动技拾取点是队伍的坐标
_class("TTPickUpPosIsTeamPos", TriggerBase)
---@class TTPickUpPosIsTeamPos:TriggerBase
TTPickUpPosIsTeamPos = TTPickUpPosIsTeamPos
function TTPickUpPosIsTeamPos:IsSatisfied(notify)
    ----@type Entity
    -- local attacker = notify:GetAttackerEntity()
    local ownerEntity = self:GetOwnerEntity()

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = ownerEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        return false
    end

    local lastPickUpPos = pickupComponent:GetLastPickUpGridPos()
    if not lastPickUpPos then
        return false
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local posTeam = teamEntity:GetGridPosition()

    return lastPickUpPos == posTeam
end

---@class TTIsOnMatchPieceTypeGrid : TriggerBase
_class("TTIsOnMatchPieceTypeGrid", TriggerBase)
TTIsOnMatchPieceTypeGrid = TTIsOnMatchPieceTypeGrid

--是否在指定颜色的格子上
function TTIsOnMatchPieceTypeGrid:IsSatisfied()
    local entity = self:GetOwnerEntity()
    local gridPosition = entity:GetGridPosition()

    local matchPieceType = self._param[1]
    local isMatch = self._param[2] or 1

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pieceType = utilData:FindPieceElement(gridPosition)
    if isMatch == 1 then
        return pieceType == matchPieceType
    else
        return pieceType ~= matchPieceType
    end

    return false
end
---昼夜模块 当前是白天（1）或黑夜（2）
_class("TTCurDayNightState", TriggerBase)
---@class TTCurDayNightState:TriggerBase
TTCurDayNightState = TTCurDayNightState
function TTCurDayNightState:IsSatisfied(notify)
    local checkState = self._param[1]
    ---@type FeatureServiceLogic
    local featureLogicSvc = self._world:GetService("FeatureLogic")
    if featureLogicSvc then
        if featureLogicSvc:HasFeatureType(FeatureType.DayNight) then
            local curState = featureLogicSvc:GetCurDayNightState()
            if curState then
                if curState == checkState then
                    return true
                end
            end
        end
    end
    return false
end

---@class TTSanChangedMode
---@field Increased number
---@field Decreased number
TTSanChangedMode = {
    Increased = 1, ---
    Decreased = 2 ---
}
_enum("TTSanChangedMode", TTSanChangedMode)

_class("TTSanChanged", TriggerBase)
---@class TTSanChanged : TriggerBase
TTSanChanged = TTSanChanged

function TTSanChanged:Constructor()
    self._mode = tonumber(self._param[1])

    self._satisfied = false
end

---@param notify NTSanValueChange
function TTSanChanged:IsSatisfied(notify)
    if not NTSanValueChange:IsInstanceOfType(notify) then
        Log.error("这啥通知??", notify:GetNotifyType())
        return false
    end

    if self._mode == TTSanChangedMode.Increased then
        return notify:GetCurValue() > notify:GetOldValue()
    elseif self._mode == TTSanChangedMode.Decreased then
        return notify:GetCurValue() < notify:GetOldValue()
    end

    Log.error("模式错误：", tostring(self._mode))
    return false
end

_class("TTKilledByPet", TriggerBase)
---@class TTKilledByPet : TriggerBase
TTKilledByPet = TTKilledByPet

---@param notify INotifyBase
---Buff挂载者被光灵/光灵的SkillHolder，光灵召唤出来的东西所杀。都算光灵击杀
function TTKilledByPet:IsSatisfied(notify)
    --攻击者
    ---@type Entity
    local attackEntity = notify:GetNotifyEntity()

    --攻击者是光灵，光灵的SkillHolder，光灵召唤出来的
    local isPetCaster = false
    if
        attackEntity:HasSuperEntity() and attackEntity:EntityType():IsSkillHolder() and
            attackEntity:GetSuperEntity():HasPetPstID()
     then
        isPetCaster = true
    elseif attackEntity:HasSummoner() and attackEntity:GetSummonerEntity():HasPet() then
        isPetCaster = true
    elseif attackEntity:HasPet() then
        isPetCaster = true
    end

    if not isPetCaster then
        return false
    end

    --被击者
    local ownerEntity = self:GetOwnerEntity()

    local skillEffectResultContainer = attackEntity:SkillContext():GetResultContainer()
    if not skillEffectResultContainer then
        return false
    end

    local skillScopeResult = skillEffectResultContainer:GetScopeResult()
    if not skillScopeResult then
        return false
    end

    local ids = skillScopeResult:GetTargetIDs()
    for _, entityID in ipairs(ids) do
        local entity = self._world:GetEntityByID(entityID)
        if entity and entity:GetID() == ownerEntity:GetID() then
            local attributeComponent = entity:Attributes()
            if attributeComponent then
                local logicHP = attributeComponent:GetCurrentHP()
                if
                    ((not entity) or -- 实体已销毁
                        (entity:HasDeadMark()) or -- 已标记死亡
                        (logicHP <= 0))
                 then -- 空血，即将标记死亡
                    return true
                end
            end
        end
    end

    return false
end

--San变化通知的debtValue 大于0 （扣到0后仍不足的部分）
_class("TTSanChangeHasDebtVal", TriggerBase)
---@class TTSanChangeHasDebtVal:TriggerBase
TTSanChangeHasDebtVal = TTSanChangeHasDebtVal
---@param notify NTSanValueChange
function TTSanChangeHasDebtVal:IsSatisfied(notify)
    if notify:GetNotifyType() == NotifyType.SanValueChange then
        local debtVal = notify:GetDebtValue()
        if debtVal and debtVal > 0 then
            return true
        end
    end
    return false
end

---点选的坐标上的怪物做buff匹配
_class("TTPickUpPosMonsterBuffEffectMatch", TriggerBase)
---@class TTPickUpPosMonsterBuffEffectMatch:TriggerBase
TTPickUpPosMonsterBuffEffectMatch = TTPickUpPosMonsterBuffEffectMatch
function TTPickUpPosMonsterBuffEffectMatch:IsSatisfied(notify)
    --只有Buff的挂载者才触发，其他光灵触发的点选不会触发
    ----@type Entity
    local ownerEntity = self:GetOwnerEntity()

    ---@type ActiveSkillPickUpComponent
    local pickupComponent = ownerEntity:ActiveSkillPickUpComponent()
    if not pickupComponent then
        return false
    end

    local lastPickUpPos = pickupComponent:GetLastPickUpGridPos()
    if not lastPickUpPos then
        return false
    end

    --要匹配的Buff
    local buffEffect = self._param[1]
    --是否有，默认1有
    local have = self._param[2] or 1

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local haveBuff = utilData:OnCalcTargetPosMonsterBuffEffectMatch(lastPickUpPos, buffEffect, ownerEntity)

    local isSatisfied = (haveBuff == true and have == 1) or (haveBuff == false and have == 0)
    return isSatisfied
end

---目标坐标上的怪物做buff匹配
_class("TTTargetPosMonsterBuffEffectMatch", TriggerBase)
---@class TTTargetPosMonsterBuffEffectMatch:TriggerBase
TTTargetPosMonsterBuffEffectMatch = TTTargetPosMonsterBuffEffectMatch
function TTTargetPosMonsterBuffEffectMatch:IsSatisfied(notify)
    --只有Buff的挂载者才触发，其他光灵触发的点选不会触发
    ----@type Entity
    local ownerEntity = self:GetOwnerEntity()

    local targetPos = nil
    if notify:GetNotifyType() == NotifyType.NormalAttackChangeBefore then
        targetPos = notify:GetTargetPos()
    end
    if not targetPos then
        return false
    end

    --要匹配的Buff
    local buffEffect = self._param[1]
    --是否有，默认1有
    local have = self._param[2] or 1

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local haveBuff = utilData:OnCalcTargetPosMonsterBuffEffectMatch(targetPos, buffEffect, ownerEntity)

    local isSatisfied = (haveBuff == true and have == 1) or (haveBuff == false and have == 0)
    return isSatisfied
end
---SyncMovePosHasMonster = 341, --（机关）跟随移动，到达位置上有怪物
_class("TTSyncMovePosHasMonster", TriggerBase)
---@class TTSyncMovePosHasMonster:TriggerBase
TTSyncMovePosHasMonster = TTSyncMovePosHasMonster
---@param notify NTSyncMoveEachMoveEnd
function TTSyncMovePosHasMonster:IsSatisfied(notify)
    local targetPos = nil
    if notify:GetNotifyType() == NotifyType.SyncMoveEachMoveEnd then
        targetPos = notify:GetPos()
    end
    if not targetPos then
        return false
    end
    ---@type BoardServiceLogic
    local boardsvc = self._world:GetService("BoardLogic")
    local monsterList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        monsterList = { self._world:Player():GetCurrentEnemyTeamEntity() }
    else
        monsterList = boardsvc:GetMonstersAtPos(targetPos)
    end
    local isSatisfied = false
    for _, monster in ipairs(monsterList) do
        if not monster:HasDeadMark() then
            isSatisfied = true
            break
        end
    end
    return isSatisfied
end
---SyncMovePosHasChanged = 342, --（机关）跟随移动，本次移动有位置变化（参数1：填1表示pathIndex为1时不判断位置变化）
_class("TTSyncMovePosHasChanged", TriggerBase)
---@class TTSyncMovePosHasChanged:TriggerBase
TTSyncMovePosHasChanged = TTSyncMovePosHasChanged
function TTSyncMovePosHasChanged:Constructor()
    local ignoreFirstMove = tonumber(self._param[1])
    self._ignoreFirstMove = (ignoreFirstMove == 1)
end
---@param notify NTSyncMoveEachMoveEnd
function TTSyncMovePosHasChanged:IsSatisfied(notify)
    local targetPos = nil
    if notify:GetNotifyType() == NotifyType.SyncMoveEachMoveEnd then
        targetPos = notify:GetPos()
    end
    if not targetPos then
        return false
    end
    local pathIndex = notify:GetPathIndex()
    if pathIndex == 1 then
        if self._ignoreFirstMove then
            return true
        end
    end
    local oldPos = notify:GetOldPos()
    if oldPos ~= targetPos then
        return true
    end
    return false
end

--骑乘状态 骑乘（1），未骑乘（2）
_class("TTRideState", TriggerBase)
---@class TTRideState:TriggerBase
TTRideState = TTRideState

function TTRideState:IsSatisfied(notify)
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    ---@type Entity
    local notifyEntity = notify:GetNotifyEntity()
    if notifyEntity:GetID() ~= ownerEntity:GetID() then
        return false
    end

    local isRide = nil
    if notify:GetNotifyType() == NotifyType.RideStateChange then
        isRide = notify:GetRideState()
    end

    local checkState = self._param[1] == 1
    if isRide == checkState then
        return true
    end

    return false
end

--是否被骑乘
_class("TTIsMount", TriggerBase)
---@class TTIsMount:TriggerBase
TTIsMount = TTIsMount

function TTIsMount:IsSatisfied(notify)
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    if not ownerEntity:HasRide() then
        return false
    end

    ---@type RideComponent
    local rideCmpt = ownerEntity:Ride()
    local mountID = rideCmpt:GetMountID()

    -- local entityIDList = {}
    -- if notify:GetNotifyType() == NotifyType.ChainSkillAttackEnd or
    --     notify:GetNotifyType() == NotifyType.ActiveSkillAttackEnd or
    --     notify:GetNotifyType() == NotifyType.NormalEachAttackEnd or
    --     notify:GetNotifyType() == NotifyType.TrapActiveSkillEnd
    -- then
    --     entityIDList = notify:GetDefenderEntityIDList()
    -- end

    -- if not table.icontains(entityIDList, mountID) then
    --     return false
    -- end

    ----@type Entity
    local mountEntity = self:GetWorld():GetEntityByID(mountID)
    if not mountEntity then
        return false
    end

    if mountEntity:HasTrap() and mountEntity:HasDeadMark() then
        return true
    elseif mountEntity:HasMonsterID() then
        ---@type BuffComponent
        local buffCmpt = mountEntity:BuffComponent()
        if buffCmpt and buffCmpt:HasBuffEffect(BuffEffectType.Palsy) then
            return true
        end
    end

    return false
end

_class("TTIsTrapStateOpen", TriggerBase)
---@class TTIsTrapStateOpen:TriggerBase
TTIsTrapStateOpen = TTIsTrapStateOpen

function TTIsTrapStateOpen:IsSatisfied()
    ---@type  Entity
    local entity = self:GetOwnerEntity()
    if not entity:HasTrapID() then
        return false
    end
    ---@type AttributesComponent
    local attrCpmt = entity:Attributes()
    local state = self._x or 1
    if attrCpmt and attrCpmt:GetAttribute("OpenState") and attrCpmt:GetAttribute("OpenState") == state  then
        return true
    end
    return false
end

TTLayerCountNonDivisible_ZeroLayerPolicy = {
    TrueOnZero = 1, --0层判定为真
    FalseOnZero = 2 --0层判定为假
}
_enum("TTLayerCountNonDivisible_ZeroLayerPolicy", TTLayerCountNonDivisible_ZeroLayerPolicy)

--判断buff层数不可被给定除数整除
---@class TTLayerCountNonDivisible:TriggerBase
_class("TTLayerCountNonDivisible", TriggerBase)
TTLayerCountNonDivisible = TTLayerCountNonDivisible

function TTLayerCountNonDivisible:IsSatisfied(notify) --buffId为_x的层数达到_y时，返回true
    local buffId = self._param[1] --buffId
    local divider = self._param[2]
    local zeroLayerPolicy = self._param[3]

    if #(self._param) < 3 then
        Log.exception(self._className, "缺少必要参数")
        return false
    end

    if divider == 0 then
        Log.exception(self._className, "除数不能是0")
        return false
    end

    local e = self:GetOwnerEntity()
    local cBuff = e:BuffComponent()
    local layerCount = 0
    local instance = cBuff:GetBuffById(buffId)
    if instance then
        local layerName = instance:GetBuffLayerName()
        layerCount = cBuff:GetBuffValue(layerName) or 0
    end
    if layerCount == 0 then
        return zeroLayerPolicy == TTLayerCountNonDivisible_ZeroLayerPolicy.TrueOnZero
    end

    local a, b = math.modf(layerCount / divider)
    return b ~= 0
end

---@class TTLayerChangeCasterIsMe:TriggerBase
_class("TTLayerChangeCasterIsMe", TriggerBase)
TTLayerChangeCasterIsMe = TTLayerChangeCasterIsMe

function TTLayerChangeCasterIsMe:IsSatisfied(notify) --buffId为_x的层数达到_y时，返回true
    if (not notify:GetCasterEntity()) or (not self:GetOwnerEntity()) then
        return false
    end

    return self:GetOwnerEntity():GetID() == notify:GetCasterEntity():GetID()
end

_class("TTIsMeInvolvedInTeamLeaderChange", TriggerBase)
---@class TTIsMeInvolvedInTeamLeaderChange : TriggerBase
TTIsMeInvolvedInTeamLeaderChange = TTIsMeInvolvedInTeamLeaderChange

function TTIsMeInvolvedInTeamLeaderChange:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if not owner:HasPetPstID() then
        return false
    end
    local ownerEntityID = owner:GetID()

    if notify:GetNotifyType() == NotifyType.TeamOrderChange then
        local oldTeamOrder = notify:GetOldTeamOrder()
        local newTeamOrder = notify:GetNewTeamOrder()
        local ownerPstID = owner:PetPstID():GetPstID()
        return (oldTeamOrder[1] ~= newTeamOrder[1]) and (ownerPstID == oldTeamOrder[1] or ownerPstID == newTeamOrder[1])
    end

    local eNewTeamLeader = notify:GetNewTeamLeader()
    local eOldTeamLeader = notify:GetOldTeamLeader()

    return (ownerEntityID == eNewTeamLeader:GetID()) or (ownerEntityID == eOldTeamLeader:GetID())
end

_class("TTActiveSkillCausedDamage", TriggerBase)
---@class TTActiveSkillCausedDamage : TriggerBase
TTActiveSkillCausedDamage = TTActiveSkillCausedDamage

function TTActiveSkillCausedDamage:IsSatisfied(notify)
    local attacker = notify:GetAttackerEntity()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    ---@type SkillDamageEffectResult[]
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    if (not damageResultArray) or (#damageResultArray == 0) then
        return false
    end

    local damageCount = 0
    -- 伤害类型不是Miss都算
    for _, result in ipairs(damageResultArray) do
        local tDamageInfo = result:GetDamageInfoArray()
        if (tDamageInfo) and (#tDamageInfo > 0) then
            for __, damageInfo in ipairs(tDamageInfo) do
                local targetID = damageInfo:GetTargetEntityID()
                local e = self._world:GetEntityByID(targetID)
                if e and not e:HasTrap() then
                    local damageType = damageInfo:GetDamageType()
                    if damageType ~= DamageType.Miss then
                        damageCount = damageCount + 1
                    end
                end
            end
        end
    end

    return damageCount > 0
end

_class("TTFeatureSkillTypeMatch", TriggerBase)
---@class TTFeatureSkillTypeMatch : TriggerBase
TTFeatureSkillTypeMatch = TTFeatureSkillTypeMatch
---@param notify NTFeatureSkillAttackEnd
function TTFeatureSkillTypeMatch:IsSatisfied(notify)
    if notify:GetNotifyType() == NotifyType.FeatureSkillAttackEnd then
        local ntFeatureType = notify:GetFeatureType()
        for i, p in ipairs(self._param) do
            if ntFeatureType == p then
                return true
            end
        end
    end
    return false
end

---判断自己的Buff是否匹配参数里所有的数据
_class("TTOwnerHasAllBuff", TriggerBase)
---@class TTOwnerHasAllBuff:TriggerBase
TTOwnerHasAllBuff = TTOwnerHasAllBuff

---@param notify TTOwnerHasAllBuff
function TTOwnerHasAllBuff:IsSatisfied(notify)
    local owner = self:GetOwnerEntity()

    if owner:HasDeadMark() then
        return false
    end

    ---@type BuffComponent
    local buffCmp = owner:BuffComponent()
    if not buffCmp then
        return
    end

    for i, buffEffect in ipairs(self._param) do
        if not buffCmp:HasBuffEffect(buffEffect) then
            self._satisfied = false
            return false
        end
    end
    self._satisfied = true

    return true
end

_class("TTFirstNormalAttackDir", TriggerBase)
---@class TTFirstNormalAttackDir:TriggerBase
TTFirstNormalAttackDir = TTFirstNormalAttackDir

function TTFirstNormalAttackDir:IsSatisfied(notify)
    ---@type  Entity
    local entity = self:GetOwnerEntity()

    -- 如果不是光灵，判定为假
    if not entity:HasPetPstID() then
        return
    end

    local cPetPstID = entity:PetPstID()

    local attackPos = notify:GetAttackPos()
    local damagePos = notify:GetTargetPos()
    local dir = damagePos - attackPos
    local dirNum = 0
    if dir.x == 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Up
    elseif dir.x > 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.RightTop
    elseif dir.x > 0 and dir.y == 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Right
    elseif dir.x > 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.RightBottom
    elseif dir.x == 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Down
    elseif dir.x < 0 and dir.y < 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.LeftBottom
    elseif dir.x < 0 and dir.y == 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.Left
    elseif dir.x < 0 and dir.y > 0 then
        dirNum = BuffLogicSaveNormalAttackDirEnum.LeftTop
    end

    -- 如果没在参数规定的范围之内，判定为假
    if not table.icontains(self._param, dirNum) then
        return false
    end

    local curRound = self._world:BattleStat():GetGameRoundCount()
    -- 如果已经进行过这个方向的普攻，判定为假
    if table.icontains(cPetPstID:GetRoundNormalAttackDirTable(curRound), dirNum) then
        return false
    end

    return true
end

---PlayerMovePosNotFirstStep = 354, ---光灵连线移动，chainPathIndex不是1（第一步是在原地）
_class("TTPlayerMovePosNotFirstStep", TriggerBase)
---@class TTPlayerMovePosNotFirstStep:TriggerBase
TTPlayerMovePosNotFirstStep = TTPlayerMovePosNotFirstStep
function TTPlayerMovePosNotFirstStep:Constructor()
end
---@param notify NTPlayerEachMoveEnd
function TTPlayerMovePosNotFirstStep:IsSatisfied(notify)
    local targetPos = nil
    if notify:GetNotifyType() ~= NotifyType.PlayerEachMoveEnd then
        return false
    end
    local chainIndex = notify:GetChainIndex()
    if chainIndex > 1 then
        return true
    end
    return false
end


_class("TTGridConvertMyPos", TriggerBase)
---@class TTGridConvertMyPos:TriggerBase
TTGridConvertMyPos = TTGridConvertMyPos

---@param notify NTGridConvert
function TTGridConvertMyPos:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.GridConvert
            and notify:GetNotifyType() ~= NotifyType.ExChangeGridColor
            and notify:GetNotifyType() ~= NotifyType.CovCrystalPrism then
        return false
    end
    ---@type Entity
    local owner = self:GetOwnerEntity()
    ---@type BodyAreaComponent
    local bodyAreaCmpt = owner:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()
    ---@type Vector2
    local myPos = owner:GetGridPosition()
    for i, v in ipairs(bodyArea) do
        local pos = myPos+v
        if notify:GetConvertInfoAt(pos) ~= nil then
            return true
        end
    end
    return false
end

_class("TTActiveSkillPowerfullRound", TriggerBase)
---@class TTActiveSkillPowerfullRound:TriggerBase
TTActiveSkillPowerfullRound = TTActiveSkillPowerfullRound

function TTActiveSkillPowerfullRound:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasPet() then
        local checkRound = self._param[1] or -1
        ---@type Entity
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        if teamEntity then
            local readyCount = teamEntity:ActiveSkill():GetPreviousReadyRoundCount(owner:GetID())--powerfullRoundCount有问题
            if readyCount == checkRound then
                return true
            end
        end
    end
    return false
end

---@class TTTeamInAuraRange:TriggerBase
_class("TTTeamInAuraRange", TriggerBase)
TTTeamInAuraRange = TTTeamInAuraRange
function TTTeamInAuraRange:IsSatisfied(notify)
    local auraGroupID = self._param[1]
    local inSide = self._param[2] or 1 --默认1在范围内，0是不在范围内

    ---@type TriggerService
    local lsvcTrigger = self._world:GetService("Trigger")
    --不同notify传pos的方法都不一样
    local curMovePos = lsvcTrigger:GetPlayerMoveEndPosByNotify(notify)

    --获取光环范围
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local totalAuraRange = trapSvc:GetTotalAuraRangeByGroupID(auraGroupID)

    --判断范围是否包含notify的坐标
    local match = table.icontains(totalAuraRange, curMovePos)
    if inSide == 1 then
        return match
    elseif inSide == 0 then
        return not match
    end

    return false
end

_class("TTCoffinMusumeCandleLight", TriggerBase)
---@class TTCoffinMusumeCandleLight:TriggerBase
TTCoffinMusumeCandleLight = TTCoffinMusumeCandleLight

---@param notify TTCoffinMusumeCandleLight
function TTCoffinMusumeCandleLight:IsSatisfied(notify)
    local isLightTrue = self._param[1] == 1

    local owner = self:GetOwnerEntity()
    local hasBuffComponent = owner:HasBuff()
    local isLightOn = false

    if hasBuffComponent then
        isLightOn = owner:BuffComponent():GetBuffValue(BattleConst.CandleLightKey) == 1
    end

    return isLightTrue and isLightOn or (not isLightOn)
end


_class("TTPetMoveInRange", TriggerBase)
---@class TTPetMoveInRange:TriggerBase
TTPetMoveInRange = TTPetMoveInRange
---@param notify NTTeamLeaderEachMoveEnd
function TTPetMoveInRange:IsSatisfied(notify)
    local pos = notify:GetPos()
    ---@type number
    local skillID =  self._x
    ---@type Entity
    local owner = self:GetOwnerEntity()
    local bodyArea = owner:BodyArea():GetArea()
    local centerPos = owner:GetGridPosition()
    local casterDir = owner:GetGridDirection()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type ConfigService
    local configSvc =  self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfig = configSvc:GetSkillConfigData(skillID)
    ---@type SkillScopeCalculator
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local result = skillCalculater:CalcSkillScope(skillConfig,centerPos,casterDir,bodyArea, owner)
    local attackRange = result:GetAttackRange()
    return table.Vector2Include(attackRange,pos)
end

---@class TTPosInAuraRange:TriggerBase
_class("TTPosInAuraRange", TriggerBase)
TTPosInAuraRange = TTPosInAuraRange
function TTPosInAuraRange:IsSatisfied(notify)
    local auraGroupID = self._param[1]
    local layerCount = self._param[2] --光环层数
    local inSide = self._param[3] or 1 --默认1在范围内，0是不在范围内
    local compareType = self._param[4] or 1 --光环层数和配置层数的比较方式，默认>=，0则==

    --获取Buff持有者
    ---@type Entity
    local ownerEntity = self:GetOwnerEntity()
    if ownerEntity:HasDeadMark() then
        return false
    end
    local posSelf = ownerEntity:GridLocation():GetGridPos()
    local bodyArea = ownerEntity:BodyArea():GetArea()

    --不同notify传pos的方法都不一样
    local curMovePos = posSelf
    if notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveStart or
            notify:GetNotifyType() == NotifyType.TeamLeaderEachMoveEnd
    then
        curMovePos = notify:GetPos()
    elseif notify:GetNotifyType() == NotifyType.Teleport then
        curMovePos = notify:GetPosNew()
    elseif notify:GetNotifyType() == NotifyType.EntityMoveEnd then
        curMovePos = notify:GetPosNew()
    end

    --检测
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local match = false
    for _, value in ipairs(bodyArea) do
        curMovePos = curMovePos + value
        local count = trapSvc:GetAuraSuperposedCount(auraGroupID, curMovePos)
        if not count then
            count = -1
        end
        if compareType == 1 then
            if count >= layerCount then
                match = true
                break
            end
        elseif compareType == 0 then
            if count == layerCount then
                match = true
                break
            end
        end
    end

    if inSide == 1 then
        return match
    elseif inSide == 0 then
        return not match
    end

    return false
end

_class("TTMonsterCompareDistance", TriggerBase)
---@class TTMonsterCompareDistance:TriggerBase
TTMonsterCompareDistance = TTMonsterCompareDistance
function TTMonsterCompareDistance:IsSatisfied(notify)
    local monsterClassID = self._param[1]
    local targetEntity = nil
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster()
    for i, e in ipairs(monsterList) do
        if monsterClassID == e:MonsterID():GetMonsterClassID() then
            targetEntity = e
            break
        end
    end
    if not targetEntity then
        return false
    end

    local targetPos = targetEntity:GetGridPosition()
    local owner = self:GetOwnerEntity()
    local ownerPos = owner:GetGridPosition()

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPos = teamEntity:GetGridPosition()

    local targetDis = Vector2.Distance(targetPos, teamPos)
    local ownerDis = Vector2.Distance(ownerPos, teamPos)

    local compareFlag = self._param[2]
    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = ownerDis == targetDis
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = ownerDis ~= targetDis
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = ownerDis > targetDis
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = ownerDis >= targetDis
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = ownerDis < targetDis
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = ownerDis <= targetDis
    end
    return satisfied
end

_class("TTHowManyKindsOfElementInTeam", TriggerBase)
---@class TTHowManyKindsOfElementInTeam:TriggerBase
TTHowManyKindsOfElementInTeam = TTHowManyKindsOfElementInTeam
function TTHowManyKindsOfElementInTeam:IsSatisfied(notify)
    ---第一个参数是元素属性来源，1代表主属性，2代表副属性
    local elementSourceType = self._param[1]
    ---第二个参数是比较类型
    local compareFlag = self._param[2]
    ---第三个参数是比较的目标值
    local targetNumber = self._param[3]

    local satisfied = false

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if not teamEntity then
        return satisfied
    end

    local curElementList = {}

    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    local petEntities = teamCmpt:GetTeamPetEntities()
    for _, e in ipairs(petEntities) do
        local curEntityElement = nil
        ---@type ElementComponent
        local elementCmpt = e:Element()
        if elementSourceType == 1 then
            curEntityElement = elementCmpt:GetPrimaryType()
        elseif elementSourceType == 2 then
            curEntityElement = elementCmpt:GetSecondaryType()
        end

        local isContain = table.icontains(curElementList,curEntityElement)
        if isContain == false then
            curElementList[#curElementList + 1] = curEntityElement
        end
    end

    local elementCount = #curElementList
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = elementCount == targetNumber
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = elementCount ~= targetNumber
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = elementCount > targetNumber
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = elementCount >= targetNumber
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = elementCount < targetNumber
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = elementCount <= targetNumber
    end

    return satisfied
end

_class("TTTrapSummonerHasSummonedBefore", TriggerBase)
---@class TTTrapSummonerHasSummonedBefore:TriggerBase
TTTrapSummonerHasSummonedBefore = TTTrapSummonerHasSummonedBefore

---@param notify NTTrapShow
function TTTrapSummonerHasSummonedBefore:IsSatisfied(notify)
    local ownerEntity = notify:GetOwnerEntity()
    if not ownerEntity then
        return false
    end

    -- 这个地方由notify构造者提供，因为逻辑和表现判断时取用的数据不同
    -- 逻辑数据在BattleStat内，表现数据在RenderBattleStat内
    -- 否则逻辑可以正确判断，但表现做判断一定为假
    return notify:IsFirstSummon()
end

_class("TTTrapSummonedByMe", TriggerBase)
---@class TTTrapSummonedByMe:TriggerBase
TTTrapSummonedByMe = TTTrapSummonedByMe

---@param notify NTTrapShow
function TTTrapSummonedByMe:IsSatisfied(notify)
    local ownerEntity = notify:GetOwnerEntity()
    if not ownerEntity then
        return false
    end
    if ownerEntity:HasSuperEntity() and ownerEntity:EntityType():IsSkillHolder() then
        ownerEntity = ownerEntity:GetSuperEntity()
    end

    return ownerEntity:GetID() == self:GetOwnerEntity():GetID()
end

--通知的被打者体型匹配
_class("TTNotifyDefenderBodyAreaMatch", TriggerBase)
---@class TTNotifyDefenderBodyAreaMatch:TriggerBase
TTNotifyDefenderBodyAreaMatch = TTNotifyDefenderBodyAreaMatch

function TTNotifyDefenderBodyAreaMatch:IsSatisfied(notify)
    if notify.GetDefenderEntity then
        local entity = notify:GetDefenderEntity()
        if self._world:MatchType() == MatchType.MT_BlackFist then
            local enemyTeamEntity = self._world:Player():GetCurrentEnemyTeamEntity()
            if entity:GetID() == enemyTeamEntity:GetID() then
                local param = self._param[1]
                if not param then
                    return false
                end
                if param == 1 then
                    return true
                else
                    return false
                end
            else
                return false
            end
        else
            if entity:MonsterID() then
                ---@type BodyAreaComponent
                local bodyAreaComponent = entity:BodyArea()
                if bodyAreaComponent then
                    bodyAreaComponent:GetAreaCount()
                    local cnt = bodyAreaComponent:GetAreaCount()
                    local param = self._param[1]
                    if not param then
                        return false
                    end
                    if (cnt == 1 and param == 1) then--单格怪
                        return true
                    end
                    if cnt > 1 and param > 1 then--多格怪
                        return true
                    end
                end
            end
        end
    end
    return false
end

--通知的被打者体型匹配
_class("TTWeikeNotifySkillType", TriggerBase)
---@class TTWeikeNotifySkillType:TriggerBase
TTWeikeNotifySkillType = TTWeikeNotifySkillType

---@param notify NTPet1601781SkillHolderBase
function TTWeikeNotifySkillType:IsSatisfied(notify)
    local targetSkillType = self._param[1]
    local skillType = notify:GetSkillType()

    return skillType == targetSkillType
end

_class("TTAttackTargetVisibleBuffCount", TriggerBase)
---@class TTAttackTargetVisibleBuffCount : TriggerBase
TTAttackTargetVisibleBuffCount = TTAttackTargetVisibleBuffCount

---@param notify NotifyAttackBase
function TTAttackTargetVisibleBuffCount:IsSatisfied(notify)
    local targetEntity = notify:GetDefenderEntity()
    if (not targetEntity) or (not targetEntity:HasBuff()) then
        return false
    end

    local cBuff = targetEntity:BuffComponent()
    local buffArray = cBuff:GetBuffArray()

    local count = 0
    for _, instance in ipairs(buffArray) do
        local buffID = instance:BuffID()
        local cfgBuff = Cfg.cfg_buff[buffID]
        if cfgBuff.ShowBuffIcon then
            count = count + 1
        end
    end

    return count >= self._param[1]
end

_class("TTDefenderRingDistance", TriggerBase)
---@class TTDefenderRingDistance : TriggerBase
TTDefenderRingDistance = TTDefenderRingDistance

function TTDefenderRingDistance:IsSatisfied(notify)
    ---@type Entity
    local attacker = notify:GetNotifyEntity()
    local attackPos = notify:GetTargetPos()
    if attacker ~= self:GetOwnerEntity() then
        return false
    end
    local attackerPos = attacker:GridLocation():Center()
    local distance = math.min(math.abs(attackerPos.x - attackPos.x), math.abs(attackerPos.y - attackPos.y))
    local paramDistance = tonumber(self._param[1])

    return distance < paramDistance
end

_class("TTIsMeHPLocked", TriggerBase)
---@class TTIsMeHPLocked : TriggerBase
TTIsMeHPLocked = TTIsMeHPLocked

function TTIsMeHPLocked:IsSatisfied(notify)
    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")
    local lockBuff--[[用不上但不让用_表示]], isLock = blsvc:CheckEntityLockHP(self:GetOwnerEntity())

    return isLock
end

--伤害技能的选敌类型匹配 0：格子类型 1：单体类型
_class("TTIsSkillSelectTargetModeMatch", TriggerBase)
---@class TTIsSkillSelectTargetModeMatch : TriggerBase
TTIsSkillSelectTargetModeMatch = TTIsSkillSelectTargetModeMatch

function TTIsSkillSelectTargetModeMatch:IsSatisfied(notify)
    if not notify.GetSkillID then
        return false
    end
    local skillID = notify:GetSkillID()
    if not skillID then
        return false
    end
    ----@type SkillLogicService
    local skillLogicService = self._world:GetService("SkillLogic")
    local checkType = self._param[1] or 0
    if checkType == SkillTargetSelectionMode.Grid then
        local isGridSkill = skillLogicService:IsSelectGridSkill(skillID)
        return isGridSkill
    elseif checkType == SkillTargetSelectionMode.Entity then
        local isSingleSkill = skillLogicService:IsSelectEntitySkill(skillID)
        return isSingleSkill
    end
    return false
end

--转色通知的格子有水格子，和NTGridConvert绑定
_class("TTGridConvertHasWater", TriggerBase)
---@class TTGridConvertHasWater : TriggerBase
TTGridConvertHasWater = TTGridConvertHasWater
---@param notify NTGridConvert
function TTGridConvertHasWater:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.GridConvert then
        return false
    end

    local bluePieceNum = 0
    local convertInfoArray = notify:GetConvertInfoArray()
    for _, convertInfo in ipairs(convertInfoArray) do
        local afterPieceType = convertInfo:GetAfterPieceType()
        if afterPieceType == PieceType.Blue then
            bluePieceNum = bluePieceNum + 1
        end
    end

    if bluePieceNum > 0 then
        notify:SetConvertWaterCount(bluePieceNum)
    end

    return bluePieceNum > 0
end

_class("TTPetIDInTeam", TriggerBase)
---@class TTPetIDInTeam : TriggerBase
TTPetIDInTeam = TTPetIDInTeam

function TTPetIDInTeam:IsSatisfied(notify)
    local ownerEntity = self:GetOwnerEntity()

    if ownerEntity:HasTeam() then
        ---@type TeamComponent
        local cTeam = ownerEntity:Team()
        ---@type Entity[]
        local pets = cTeam:GetTeamPetEntities()
        for _, pet in ipairs(pets) do
            local cPetPstID = pet:PetPstID()
            if table.icontains(self._param, cPetPstID:GetTemplateID()) then
                return true
            end
        end
    end

    if ownerEntity:HasPet() then
        local eTeam = ownerEntity:Pet():GetOwnerTeamEntity()
        ---@type TeamComponent
        local cTeam = eTeam:Team()
        ---@type Entity[]
        local pets = cTeam:GetTeamPetEntities()
        for _, pet in ipairs(pets) do
            local cPetPstID = pet:PetPstID()
            if table.icontains(self._param, cPetPstID:GetTemplateID()) then
                return true
            end
        end
    end

    return false

end

_class("TTChainSkillIndex", TriggerBase)
---@class TTChainSkillIndex : TriggerBase
TTChainSkillIndex = TTChainSkillIndex

function TTChainSkillIndex:IsSatisfied(notify)
    local targetIndex = self._param[1]

    if not self:GetOwnerEntity():HasSkillInfo() then
        return false
    end

    if (not notify.GetChainSkillId) then
        return false
    end

    local chainSkillId = notify:GetChainSkillId()
    if not chainSkillId then
        return false
    end

    local cSkillInfo = self:GetOwnerEntity():SkillInfo()
    local index = cSkillInfo:GetChainSkillLevel(chainSkillId)

    return targetIndex == index
end


---@class TTTeamEnterExitAuraRange : TriggerBase
_class("TTTeamEnterExitAuraRange", TriggerBase)
TTTeamEnterExitAuraRange = TTTeamEnterExitAuraRange

function TTTeamEnterExitAuraRange:IsSatisfied(notify)
    local auraGroupID = self._param[1]
    local paramEnter = self._param[2] or 1 --默认1表示进入，0表示退出
    local isEnter = paramEnter == 1

    ---@type TriggerService
    local lsvcTrigger = self._world:GetService("Trigger")
    --不同notify传pos的方法都不一样
    local moveBeginPos = lsvcTrigger:GetPlayerMoveBeginPosByNotify(notify)
    local moveEndPos = lsvcTrigger:GetPlayerMoveEndPosByNotify(notify)

    if moveBeginPos == moveEndPos then
        -- 程序上存在部分这样的情况，跳过后面的计算
        return false
    end

    --获取光环范围
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    local totalAuraRange = trapSvc:GetTotalAuraRangeByGroupID(auraGroupID)

    local isMoveBeginInAura = table.Vector2Include(totalAuraRange, moveBeginPos)
    local isMoveEndInAura = table.Vector2Include(totalAuraRange, moveEndPos)

    if isEnter then
        return (not isMoveBeginInAura) and (isMoveEndInAura)
    else
        return (isMoveBeginInAura) and (not isMoveEndInAura)
    end

    return false
end

--装备精炼局内UI开关状态是否匹配 参数1：开关状态
---@class TTIsEquipRefineUIStateMatch : TriggerBase
_class("TTIsEquipRefineUIStateMatch", TriggerBase)
TTIsEquipRefineUIStateMatch = TTIsEquipRefineUIStateMatch

function TTIsEquipRefineUIStateMatch:IsSatisfied(notify)
    if not notify.GetRefineUIState then
        return false
    end
    local notifyState = notify:GetRefineUIState()

    local checkState = self._param[1] or EquipRefineUIStateType.On
    if checkState == notifyState then
        return true
    end

    return false
end

--是否是宿主被控制或位移（击退、牵引）
---@class TTIsControlOrMoveHost : TriggerBase
_class("TTIsControlOrMoveHost", TriggerBase)
TTIsControlOrMoveHost = TTIsControlOrMoveHost

function TTIsControlOrMoveHost:IsSatisfied(notify)
    --不同的Notify检查对象不同
    local entityID = nil
    if notify:GetNotifyType() == NotifyType.AddControlBuffEnd then
        ---@type Entity
        local notifyEntity = notify:GetNotifyEntity()
        entityID = notifyEntity:GetID()
    elseif notify:GetNotifyType() == NotifyType.HitBackEnd or
        notify:GetNotifyType() == NotifyType.TractionEnd then
        entityID = notify:GetDefenderId()
    end
    if not entityID then
        return false
    end

    ---@type Entity
    local owner = self:GetOwnerEntity()
    if not owner:AI() then
        return false
    end

    local attachMonsterID = owner:AI():GetRuntimeData("AttachMonsterID")

    return entityID == attachMonsterID
end

--被击者是否体型匹配或不可被位移（一般性检查，只检测无敌、击退、免控）
---@class TTIsDefenderBodyMatchOrCannotBeHitBack : TriggerBase
_class("TTIsDefenderBodyMatchOrCannotBeHitBack", TriggerBase)
TTIsDefenderBodyMatchOrCannotBeHitBack = TTIsDefenderBodyMatchOrCannotBeHitBack

function TTIsDefenderBodyMatchOrCannotBeHitBack:IsSatisfied(notify)
    if not notify.GetDefenderEntity then
        return false
    end
    ---@type Entity
    local defender = notify:GetDefenderEntity()
    local param = self._param[1] or 1

    local isBodyAreaMatch = false
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemyTeamEntity = self._world:Player():GetCurrentEnemyTeamEntity()
        if defender:GetID() == enemyTeamEntity:GetID() then
            if param == 1 then
                isBodyAreaMatch = true
            end
        end
    else
        if defender:MonsterID() then
            ---@type BodyAreaComponent
            local bodyAreaComponent = defender:BodyArea()
            if bodyAreaComponent then
                bodyAreaComponent:GetAreaCount()
                local cnt = bodyAreaComponent:GetAreaCount()
                if (cnt == 1 and param == 1) then --单格怪
                    isBodyAreaMatch = true
                end
                if cnt > 1 and param > 1 then --多格怪
                    isBodyAreaMatch = true
                end
            end
        end
    end

    ---@type BuffLogicService
    local buffSvc = self._world:GetService("BuffLogic")
    local isCannotBeHitBack = not buffSvc:CheckCanBeHitBack(defender)

    return isBodyAreaMatch or isCannotBeHitBack
end

--
---@class TTCheckCountDown : TriggerBase
_class("TTCheckCountDown", TriggerBase)
TTCheckCountDown = TTCheckCountDown

function TTCheckCountDown:IsSatisfied(notify)
    local buffID = self._param[1]
    local checkNumber = self._param[2] or 0

    local owner = self:GetOwnerEntity()

    ---@type BuffComponent
    local buffCmp = owner:BuffComponent()
    ---@type BuffInstance
    local buffInstance = buffCmp:GetBuffById(buffID)
    if not buffInstance then
        return
    end

    local countDown = buffInstance:GetCountDown()
    if not countDown then
        return
    end
    -- --默认减1
    -- local newCountDown = countDown - 1
    -- buffInstance:SetCountDown(newCountDown)

    return countDown == checkNumber
end

---@class TTHasMonsterAroundDefender:TriggerBase
_class("TTHasMonsterAroundDefender", TriggerBase)
TTHasMonsterAroundDefender = TTHasMonsterAroundDefender

function TTHasMonsterAroundDefender:IsSatisfied(notify)
    local skillID = self._param[1]
    if not notify.GetDefenderEntity then
        return false
    end
    local defenderEntity = notify:GetDefenderEntity()
    if not defenderEntity then
        return false
    end
    --使用施法者机关的坐标计算技能范围
    local posDefender = defenderEntity:GetGridPosition()
    local bodyArea = defenderEntity:BodyArea():GetArea()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local scopeResult = skillCalculater:CalcSkillScope(skillConfigData, posDefender, Vector2(0, 1), bodyArea)
    local posList = scopeResult:GetAttackRange()
    ---@type BoardServiceLogic
    local boardsvc = self._world:GetService("BoardLogic")
    for index, rangePos in ipairs(posList) do
        local monsterList = boardsvc:GetMonstersAtPos(rangePos)
        local isSatisfied = false
        for _, monster in ipairs(monsterList) do
            if not monster:HasDeadMark() then
                isSatisfied = true
                break
            end
        end
        if isSatisfied then
            return true
        end
    end
    return false
end

---@class TTFmodLevelTotalRoundCount : TriggerBase
_class("TTFmodLevelTotalRoundCount", TriggerBase)
TTFmodLevelTotalRoundCount = TTFmodLevelTotalRoundCount

function TTFmodLevelTotalRoundCount:IsSatisfied(notify)
    local fmodCount = self._param[1]
    local compareFlag = self._param[2] --比较操作枚举
    local count = self._param[3] --配置的比较数量数

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local levelRound = battleStatCmpt:GetLevelTotalRoundCount()

    local curRound = levelRound % fmodCount
    if curRound == 0 then
        curRound = fmodCount
    end

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = curRound == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = curRound ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = curRound > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = curRound >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = curRound < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = curRound <= count
    end
    return satisfied
end

---@class TTOwnerAroundCompareTrapCount : TriggerBase
_class("TTOwnerAroundCompareTrapCount", TriggerBase)
TTOwnerAroundCompareTrapCount = TTOwnerAroundCompareTrapCount

function TTOwnerAroundCompareTrapCount:IsSatisfied(notify)
    local skillID = self._param[1]
    local compareFlag = self._param[2] --比较操作枚举
    local count = self._param[3] --配置的比较数量数

    local trapIDList = {}
    for i = 4, table.count(self._param), 1 do
        table.insert(trapIDList, self._param[i])
    end

    local hasTrapPosList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            local trapID = e:Trap():GetTrapID()
            if table.intable(trapIDList, trapID) then
                local pos = e:GetGridPosition()
                table.insert(hasTrapPosList, pos)
            end
        end
    end

    ---@type Entity
    local owner = self:GetOwnerEntity()
    --使用施法者机关的坐标计算技能范围
    local posDefender = owner:GetGridPosition()
    local bodyArea = owner:BodyArea():GetArea()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local skillCalculater = SkillScopeCalculator:New(utilScopeSvc)
    ---@type SkillScopeResult
    local scopeResult = skillCalculater:CalcSkillScope(skillConfigData, posDefender, Vector2(0, 1), bodyArea)
    local posList = scopeResult:GetAttackRange()

    local curCount = 0
    for index, rangePos in ipairs(posList) do
        if table.intable(hasTrapPosList, rangePos) then
            curCount = curCount + 1
        end
    end

    local satisfied = false
    if compareFlag == ComparisonOperator.EQ then --eq
        satisfied = curCount == count
    elseif compareFlag == ComparisonOperator.NE then --ne
        satisfied = curCount ~= count
    elseif compareFlag == ComparisonOperator.GT then --gt
        satisfied = curCount > count
    elseif compareFlag == ComparisonOperator.GE then --ge
        satisfied = curCount >= count
    elseif compareFlag == ComparisonOperator.LT then --lt
        satisfied = curCount < count
    elseif compareFlag == ComparisonOperator.LE then --le
        satisfied = curCount <= count
    end
    return satisfied
end
---@class TTActiveSkillCostCasterHPNoZero : TriggerBase
_class("TTActiveSkillCostCasterHPNoZero", TriggerBase)
TTActiveSkillCostCasterHPNoZero = TTActiveSkillCostCasterHPNoZero

function TTActiveSkillCostCasterHPNoZero:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.ActiveSkillCostCasterHPEnd then
        return false
    end
    local damage = notify:GetDamage()
    if damage > 0 then
        return true
    else
        return false
    end
end

---@class HPChangeState
local HPChangeState={
    Increase =0,--增加
    Decrease =1,--减少
}
_enum("HPChangeState",HPChangeState)

---@class TTBloodChange : TriggerBase
_class("TTBloodChange", TriggerBase)
TTBloodChange = TTBloodChange
---@param notify NTHPCChange
function TTBloodChange:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.MonsterHPCChange and
            notify:GetNotifyType() ~= NotifyType.TrapHpChange    and
            notify:GetNotifyType() ~= NotifyType.PlayerHPChange    then
        return false
    end
    local isHPIncrease = notify:IsHPIncrease()
    if self._x == HPChangeState.Increase  then
        return isHPIncrease
    elseif self._x == HPChangeState.Decrease  then
        return not isHPIncrease
    end
end

---@class TTBreakHPLockIsUnlockHP : TriggerBase
_class("TTBreakHPLockIsUnlockHP", TriggerBase)
TTBreakHPLockIsUnlockHP = TTBreakHPLockIsUnlockHP
---@param notify NTBreakHPLock
function TTBreakHPLockIsUnlockHP:IsSatisfied(notify)
    if notify:GetNotifyType() ~= NotifyType.BreakHPLock then
        return false
    end
    local isUnlockHP = notify:GetIsUnlockHP()
    return isUnlockHP == true
end

---战斗还未结束
---@class TTNotHaveBattleLevelResult : TriggerBase
_class("TTNotHaveBattleLevelResult", TriggerBase)
TTNotHaveBattleLevelResult = TTNotHaveBattleLevelResult
function TTNotHaveBattleLevelResult:IsSatisfied(notify)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local battleLevelResult = battleStatCmpt:GetBattleLevelResult()
    return battleLevelResult == false
end

--region 消灭星星相关Trigger
---消灭星星当前总得分>=x触发
---@class TTPopStarScoreNoLess : TriggerBase
_class("TTPopStarScoreNoLess", TriggerBase)
TTPopStarScoreNoLess = TTPopStarScoreNoLess

function TTPopStarScoreNoLess:IsSatisfied(notify)
    ---只相应分数变化通知
    if notify:GetNotifyType() ~= NotifyType.PopStarScoreChange then
        return false
    end

    ---@type PopStarServiceLogic
    local popStarSvc = self._world:GetService("PopStarLogic")
    local curScore = popStarSvc:GetPopGridNum()
    return curScore >= self._x
end

---消灭星星本次消除得分>=x触发
---@class TTPopStarPopNumNoLess : TriggerBase
_class("TTPopStarPopNumNoLess", TriggerBase)
TTPopStarPopNumNoLess = TTPopStarPopNumNoLess

function TTPopStarPopNumNoLess:IsSatisfied(notify)
    ---只相应消除结束通知
    if notify:GetNotifyType() ~= NotifyType.PopStarEnd then
        return false
    end

    local popNum = notify:GetPopNum()
    return popNum >= self._x
end

--endregion 消灭星星相关Trigger

_class("TTPetActiveSkillReady", TriggerBase)
---@class TTPetActiveSkillReady:TriggerBase
TTPetActiveSkillReady = TTPetActiveSkillReady
function TTPetActiveSkillReady:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasPet() then
        local skillID = 0--目前只判断主技能
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local ready = utilData:GetPetSkillReadyAttr(owner,skillID)
        if ready and ready == 1 then
            return true
        end
    end
    return false
end

_class("TTOwnerPetIsTeamLeaderOrChainPathTypeElement", TriggerBase)
---@class TTOwnerPetIsTeamLeaderOrChainPathTypeElement:TriggerBase
TTOwnerPetIsTeamLeaderOrChainPathTypeElement = TTOwnerPetIsTeamLeaderOrChainPathTypeElement
function TTOwnerPetIsTeamLeaderOrChainPathTypeElement:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasPetPstID() then
        local teamEntity = owner:Pet():GetOwnerTeamEntity()
        if teamEntity and teamEntity:Team() then
            local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()
            if teamLeaderEntityID == owner:GetID() then
                return true
            end
        end

        if not notify.GetChainPathType then
            return false
        end
        ---@type PieceType
        local chainPathType = notify:GetChainPathType()
        return table.icontains(self._param, chainPathType)
    end

    return false
end
_class("TTCurseHpOverRedHp", TriggerBase)
---@class TTCurseHpOverRedHp:TriggerBase
TTCurseHpOverRedHp = TTCurseHpOverRedHp
function TTCurseHpOverRedHp:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasDeadMark() then
        return false
    end
    local attrCmpt = owner:Attributes()
    ---@type BuffComponent
    local buffCmpt = owner:BuffComponent()
    if attrCmpt and buffCmpt then
        local curhp = attrCmpt:GetCurrentHP()
        local curCurseHp = buffCmpt:GetCurseHPValue(true)
        if curCurseHp >= curhp then
            return true
        end
    end
    return false
end

_class("TTPlayerEachMoveEndRangeHasMonster", TriggerBase)
---@class TTPlayerEachMoveEndRangeHasMonster : TriggerBase
TTPlayerEachMoveEndRangeHasMonster = TTPlayerEachMoveEndRangeHasMonster

function TTPlayerEachMoveEndRangeHasMonster:Constructor()
    self._skillID = self._param[1]
end

---@param notify NTPlayerEachMoveEnd
function TTPlayerEachMoveEndRangeHasMonster:IsSatisfied(notify)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(self._skillID)

    local centerPos = notify:GetPos()

    local ownerEntity = self:GetOwnerEntity()
    ---@type SkillScopeResult
    local scopeResult = scopeCalc:ComputeScopeRange(
            skillConfigData:GetSkillScopeType(),
            skillConfigData:GetSkillScopeParam(),
            centerPos,
            ownerEntity:BodyArea():GetArea(),
            ownerEntity:GetGridDirection(),
            SkillTargetType.Monster,
            ownerEntity:GetGridPosition(),
            ownerEntity
    )

    local targetSelector = self._world:GetSkillScopeTargetSelector()
    --注意：需求明确要求【普攻过程中被队友击杀者参与计算】因此此处不论死活，此为故意要求
    local tEntityID = targetSelector:_SelectMonsterDeadOrAlive(
            ownerEntity,
            scopeResult,
            self._skillID,
            skillConfigData:GetSkillTargetTypeParam()
    ) or {}

    return #tEntityID > 0
end

_class("TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster", TriggerBase)
---@class TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster : TriggerBase
TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster = TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster

function TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster:Constructor()
    self._skillID = self._param[1]
    self._trapType = {}
    for i = 2, #self._param do
        table.insert(self._trapType, self._param[i])
    end
end

---@param notify NTPlayerEachMoveEnd
function TTPlayerEachMoveEndRangeHasTrapByTypeOrMonster:IsSatisfied(notify)
    local triggerCond = {self._triggerType, self._skillID}
    ---@type TTPlayerEachMoveEndRangeHasMonster
    local triggerMonster = TTPlayerEachMoveEndRangeHasMonster:New(self._owner, triggerCond)

    if triggerMonster:IsSatisfied(notify) then
        return true
    end

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(utilScopeSvc)

    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(self._skillID)

    local centerPos = notify:GetPos()

    local ownerEntity = self:GetOwnerEntity()
    ---@type SkillScopeResult
    local scopeResult = scopeCalc:ComputeScopeRange(
            skillConfigData:GetSkillScopeType(),
            skillConfigData:GetSkillScopeParam(),
            centerPos,
            ownerEntity:BodyArea():GetArea(),
            ownerEntity:GetGridDirection(),
            SkillTargetType.Trap,
            ownerEntity:GetGridPosition(),
            ownerEntity
    )

    local targetSelector = self._world:GetSkillScopeTargetSelector()
    -- 为啥这地方写的是个map........
    local selected = targetSelector:_SelectTrap(
            ownerEntity,
            scopeResult,
            self._skillID,
            skillConfigData:GetSkillTargetTypeParam(),
            false
    ) or {}

    local tEntityID = {}
    for id, _ in pairs(selected) do
        table.insert(tEntityID, id)
    end

    if #tEntityID == 0 then
        return false
    end

    for _, id in ipairs(tEntityID) do
        local e = self._world:GetEntityByID(id)
        ---@type TrapComponent
        local cTrap = e:Trap()
        local trapType = cTrap:GetTrapType()
        if table.icontains(self._trapType, trapType) then
            return true
        end
    end

    return false
end

---DefenderHasAttackerAddIconBuff = 394, --被击者有攻击者添加的显示图标的Buff
_class("TTDefenderHasAttackerAddIconBuff", TriggerBase)
---@class TTDefenderHasAttackerAddIconBuff:TriggerBase
TTDefenderHasAttackerAddIconBuff = TTDefenderHasAttackerAddIconBuff
---@param notify NotifyAttackBase
function TTDefenderHasAttackerAddIconBuff:IsSatisfied(notify)
    if not notify.GetAttackerEntity or not notify.GetDefenderEntity then
        return false
    end
    ---@type Entity
    local attacker = notify:GetAttackerEntity()
    ---@type Entity
    local defender = notify:GetDefenderEntity()

    ---@type BuffComponent
    local buffCmp = defender:BuffComponent()
    if not buffCmp then
        return
    end

    local buffArray = buffCmp:GetBuffArray()
    for _, instance in ipairs(buffArray) do
        local buffLayerName = instance:GetBuffLayerName()
        --配置是否显示图标
        local isShowBuffIcon = instance:BuffConfigData():GetBuffShowBuffIcon()
        --层数
        local buffLayerCount = buffCmp:GetBuffValue(buffLayerName)
        --没层是nil要显示，有层是0不显示
        if isShowBuffIcon and buffLayerCount ~= 0 then
            local context = instance:Context()
            local buffCasterEntity = context and context.casterEntity or nil
            if buffCasterEntity then
                if buffCasterEntity:HasSuperEntity() then
                    buffCasterEntity = buffCasterEntity:GetSuperEntity()
                end
                if buffCasterEntity:GetID() == attacker:GetID() then
                    return true
                end
            end
        end
    end

    return false
end

--被击者被击退或者牵引
---@class TTDefenderBeHitBackOrTraction : TriggerBase
_class("TTDefenderBeHitBackOrTraction", TriggerBase)
TTDefenderBeHitBackOrTraction = TTDefenderBeHitBackOrTraction
function TTDefenderBeHitBackOrTraction:IsSatisfied(notify)
    --不同的Notify检查对象不同
    local entityID = nil
    if notify:GetNotifyType() == NotifyType.HitBackEnd or
        notify:GetNotifyType() == NotifyType.TractionEnd then
        entityID = notify:GetDefenderId()
    end
    
    if not entityID then
        return false
    end

    ---@type Entity
    local owner = self:GetOwnerEntity()

    return entityID == owner:GetID()
end

_class("TTNoCurseHp", TriggerBase)
---@class TTNoCurseHp:TriggerBase
TTNoCurseHp = TTNoCurseHp
function TTNoCurseHp:IsSatisfied(notify)
    ---@type Entity
    local owner = self:GetOwnerEntity()
    if owner:HasDeadMark() then
        return false
    end
    ---@type BuffComponent
    local buffCmpt = owner:BuffComponent()
    if buffCmpt then
        local isCurseHpEnabled = buffCmpt:IsCurseHPEnabled()
        if not isCurseHpEnabled then
            return true
        end
    end
    return false
end

_class("TTMonsterClassIDMatchDefender", TriggerBase)
---@class TTMonsterClassIDMatchDefender : TriggerBase
TTMonsterClassIDMatchDefender = TTMonsterClassIDMatchDefender

---@param notify INotifyBase
function TTMonsterClassIDMatchDefender:IsSatisfied(notify)
    if not notify.GetDefenderEntity then
        Log.error("TTMonsterClassIDMatchDefender(400)无法处理通知: ", tostring(notify:GetNotifyType()))
        return false
    end

    local entity = notify:GetDefenderEntity()
    if not entity:HasMonsterID() then
        return false
    end

    local monsterID = entity:MonsterID():GetMonsterID()

    local monsterClassID = 0
    local cfg = Cfg.cfg_monster[monsterID]
    if cfg and cfg.ClassID then
        monsterClassID = cfg.ClassID
    end

    if table.intable(self._param, monsterClassID) then
        return true
    end
    return false
end

_class("TTIsBuffHasRoundCountAndIcon", TriggerBase)
---@class TTIsBuffHasRoundCountAndIcon : TriggerBase
TTIsBuffHasRoundCountAndIcon = TTIsBuffHasRoundCountAndIcon

---@param notify NTEachAddBuffEnd
function TTIsBuffHasRoundCountAndIcon:IsSatisfied(notify)
    if (not notify.GetBuffID) or (not notify.GetBuffSeqID) then
        Log.exception("buff判定条件408无法处理通知：", tostring(notify:GetNotifyType()))
        return false
    end

    if not notify:GetBuffSeqID() then
        Log.debug("TTIsBuffHasRoundCountAndIcon: buff没有被添加")
        return false
    end

    local buffID = notify:GetBuffID()
    if (not buffID) or (not Cfg.cfg_buff[buffID]) then
        Log.debug("TTIsBuffHasRoundCountAndIcon: 通知数据内没有有效的buffID")
        return false
    end

    local cfg = Cfg.cfg_buff[buffID]
    if cfg.RoundCount == 0 then
        Log.debug("TTIsBuffHasRoundCountAndIcon: buff没有持续时间 ", buffID)
        return false
    end

    if not cfg.ShowBuffIcon then
        Log.debug("TTIsBuffHasRoundCountAndIcon: buff不显示图标 ", buffID)
        return false
    end

    return true
end

_class("TTNotifyIsMyTeam", TriggerBase)
---@class TTNotifyIsMyTeam:TriggerBase
TTNotifyIsMyTeam = TTNotifyIsMyTeam

function TTNotifyIsMyTeam:IsSatisfied(notify)
    local ownerEntity = self:GetOwnerEntity()
    local ownerTeam
    if ownerEntity:HasTeam() then
        ownerTeam = ownerEntity
    elseif ownerEntity:HasPet() then
        ownerTeam = ownerEntity:Pet():GetOwnerTeamEntity()
    end

    if not ownerTeam then
        return false
    end

    local notifyTeam = notify:GetNotifyEntity()
    if not notifyTeam:HasTeam() then
        return false
    end

    return ownerTeam:GetID() == notifyTeam:GetID()
end
