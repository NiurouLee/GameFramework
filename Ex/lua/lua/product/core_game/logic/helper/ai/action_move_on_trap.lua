--[[-------------------------------------
移动到Data里配置的技能目标最多的位置
--]] -------------------------------------
require "action_move_base"
---@class ActionMoveOnTrap:ActionMoveBase
_class("ActionMoveOnTrap", ActionMoveBase)
ActionMoveOnTrap = ActionMoveOnTrap

--------------------------------
function ActionMoveOnTrap:Constructor()
    self:_Reset()
end
function ActionMoveOnTrap:Reset()
    ActionMoveOnTrap.super.Reset(self)
    self:_Reset()
end
function ActionMoveOnTrap:_Reset()
    self._targetPos = nil
end

function ActionMoveOnTrap:InitTargetPosList(listPosTarget)
    --获取技能ID
    local nSkillID = self:GetLogicData(1)
    local skillID = self:GetLogicData(-1)
    if not skillID then
        skillID = nSkillID
    end
    if skillID == 0 then
        return
    end

    local trapID = self:GetLogicData(-2)
    if trapID == 0 then
        return
    end
    local trapIDTwo = self:GetLogicData(-3) or 0

    local posSelf = self.m_entityOwn:GetGridPosition()
    local dir = self.m_entityOwn:GridLocation().Direction
    local selfBodyArea = self.m_entityOwn:BodyArea():GetArea()

    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local remainMobility = aiCmpt:GetMobilityValid()
    if remainMobility <= 0 then
        self._targetPos = posSelf
        return
    end

    local targetEntity = aiCmpt:GetTargetEntity()
    local posTarget = targetEntity:GetGridPosition()

    --先检测不位移能不能攻击到
    --使用技能ID 寻找攻击发起点
    local skillRangeData = self:CalculateSkillRange(skillID, posSelf, dir, selfBodyArea)
    if table.intable(skillRangeData, posTarget) then
        self._targetPos = posSelf
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    local tarpPosList = trapServerLogic:FindTrapPosByTrapID(trapID)
    local tarpTwoPosList = trapServerLogic:FindTrapPosByTrapID(trapIDTwo)
    table.appendArray(tarpPosList, tarpTwoPosList)

    local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}
    local validPosList = {posSelf}

    --每个行动点计算一次
    for i = 1, remainMobility do
        local calcPosList = table.cloneconf(validPosList)
        for _, pos in ipairs(calcPosList) do
            for k, dir in ipairs(dirs) do
                local workPos = pos + dir
                --没添加过 and 有机关 and 没阻挡
                if
                    not table.intable(validPosList, workPos) and table.intable(tarpPosList, workPos) and
                        not utilDataSvc:IsPosBlock(workPos, BlockFlag.MonsterLand)
                 then
                    table.insert(validPosList, workPos)
                end
            end
        end
    end

    local oneMoveStepPosList = {}

    --添加的顺序就是可以移动的顺序
    for _, pos in ipairs(validPosList) do
        local skillRange = self:CalculateSkillRange(skillID, pos, dir, selfBodyArea)
        if table.intable(skillRange, posTarget) then
            --如果有可以攻击到的点就返回那个点
            self._targetPos = pos
            return
        end
        local dis = Vector2.Distance(posSelf, pos)
        if dis == 1 then
            table.insert(oneMoveStepPosList, pos)
        end
    end

    --走一步的范围 这样可以保证不会走到机关外面的范围
    if table.count(oneMoveStepPosList) > 0 then
        table.sort(
            oneMoveStepPosList,
            function(a, b)
                local disA = Vector2.Distance(posTarget, a)
                local disB = Vector2.Distance(posTarget, b)
                return disA < disB
            end
        )
        self._targetPos = oneMoveStepPosList[1]
        return
    end

    --都没有坐标就返回自己当前的
    self._targetPos = validPosList[1]
end

function ActionMoveOnTrap:FindNewTargetPos()
    return self._targetPos
end
