require "action_move_base"

--region 候选位置信息结构
_class("ActionIlluminaHealerMoveToTeammate_CandidatePos", Object)
---@class ActionIlluminaHealerMoveToTeammate_CandidatePos : Object
---@field New fun(movePos:Vector2, targetEntity:Entity, targetDistance:number, hpPercent:number, sortIndex:number):ActionIlluminaHealerMoveToTeammate_CandidatePos
ActionIlluminaHealerMoveToTeammate_CandidatePos = ActionIlluminaHealerMoveToTeammate_CandidatePos

---@private
function ActionIlluminaHealerMoveToTeammate_CandidatePos:Constructor(movePos, targetEntity, targetDistance, hpPercent, sortIndex)
    self.movePos = movePos
    self.targetEntity = targetEntity
    self.targetDistance = targetDistance
    self.hpPercent = hpPercent
    self.sortIndex = sortIndex
end

---@param a ActionIlluminaHealerMoveToTeammate_CandidatePos
---@param b ActionIlluminaHealerMoveToTeammate_CandidatePos
---@return boolean
function ActionIlluminaHealerMoveToTeammate_CandidatePos.Compare(a, b)
    if a.hpPercent ~= b.hpPercent then
        return a.hpPercent < b.hpPercent
    end

    if a.targetDistance ~= b.targetDistance then
        return a.targetDistance < b.targetDistance
    end

    return a.sortIndex < b.sortIndex
end
--endregion

_class("ActionIlluminaHealerMoveToTeammate", ActionMoveBase)
---@class ActionIlluminaHealerMoveToTeammate : ActionMoveBase
ActionIlluminaHealerMoveToTeammate = ActionIlluminaHealerMoveToTeammate

function ActionIlluminaHealerMoveToTeammate:FindNewTargetPos()
    local nSkillID = self:GetLogicData(-1)
    if nSkillID == nil or nSkillID <= 0 then
        self:PrintLog("[ActionIlluminaHealerMoveToTeammate] Can not find skill,move failed",self.m_entityOwn:GetID())
        return
    end

    local posSelf = self.m_entityOwn:GetGridPosition()
    ---@type AIComponentNew
    local aiComponent = self.m_entityOwn:AI()
    local nWalkTotal = aiComponent:GetMobilityValid()
    local selfBodyArea = self.m_entityOwn:BodyArea():GetArea()
    ---@type table<number, ComputeWalkPos>
    local cbFilter = Callback:New(1, self.IsPosAccessible, self)
    local walkRange = ComputeScopeRange.ComputeRange_WalkMathPos(posSelf, #selfBodyArea, nWalkTotal, cbFilter)

    ---@type SkillScopeTargetSelector
    local targetSelector = SkillScopeTargetSelector:New(self._world)

    ---@type ActionIlluminaHealerMoveToTeammate_CandidatePos[]
    local candidates = {}

    local movePosBlock = BlockFlag.MonsterLand
    if self.m_entityOwn:HasMonsterID() then
        local cMonsterID = self.m_entityOwn:MonsterID()
        movePosBlock = cMonsterID:GetMonsterBlockData()
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    -- AI移动的决策结果是原地会发生什么？
    -- 后面的计算会用到这个顺序，所以请一定保证自己位置在walkRange的最后
    table.insert(walkRange, ComputeWalkPos:New(posSelf, 0))

    for _, walkPos in ipairs(walkRange) do
        local centerPos = walkPos:GetPos()
        if (centerPos == posSelf) or (not utilData:IsPosBlock(centerPos, movePosBlock)) then
            local fullRange = {}
            local fullRangeIndexDict = {}
            self:_AppendVector2Array(fullRange, fullRangeIndexDict, self:CalculateSkillRange(nSkillID, centerPos, Vector2.up, selfBodyArea))
            self:_AppendVector2Array(fullRange, fullRangeIndexDict, self:CalculateSkillRange(nSkillID, centerPos, Vector2.down, selfBodyArea))
            self:_AppendVector2Array(fullRange, fullRangeIndexDict, self:CalculateSkillRange(nSkillID, centerPos, Vector2.left, selfBodyArea))
            self:_AppendVector2Array(fullRange, fullRangeIndexDict, self:CalculateSkillRange(nSkillID, centerPos, Vector2.right, selfBodyArea))

            -- 用目标选择器去找符合条件的怪物
            local scopeResult = SkillScopeResult:New(SkillScopeType.None, centerPos, fullRange, fullRange)
            local targetArray = targetSelector:DoSelectSkillTarget(self.m_entityOwn, SkillTargetType.SingleGridMonsterLowestHPPercent, scopeResult)

            if #targetArray > 0 then
                -- 记录以这个点为中心的能拿到的怪物信息和排序用信息
                -- SkillTargetType.SingleGridMonsterLowestHPPercent 只会返回一个单位
                local eid = targetArray[1]
                local e = self._world:GetEntityByID(eid)
                local cAttributes = e:Attributes()
                local maxHP = cAttributes:CalcMaxHp()
                local currentHP = cAttributes:GetCurrentHP()
                local percent = currentHP / maxHP

                local distance = Vector2.Distance(posSelf, e:GetGridPosition())

                local candidateInfo = ActionIlluminaHealerMoveToTeammate_CandidatePos:New(centerPos, e, distance, percent, #candidates)
                table.insert(candidates, candidateInfo)
            end
        end
    end

    -- 最优情况：在移动范围内可以找到一个目标
    if #candidates > 0 then
        table.sort(candidates, ActionIlluminaHealerMoveToTeammate_CandidatePos.Compare)
        local winner = candidates[1]
        return winner.movePos
    end

    -- 不太优情况：移动+技能范围内没有单格怪时，全场取最近单个怪
    local distance = 2147483647 --应该够大了
    local nearestTargetEntity

    local selfEntityID = self.m_entityOwn:GetID()
    local globalMonsterEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(globalMonsterEntities) do
        if (e:GetID() ~= selfEntityID) and (not e:HasDeadMark()) and (#(e:BodyArea():GetArea()) == 1) then
            local dis = Vector2.Distance(e:GetGridPosition(), posSelf)
            if dis < distance then
                distance = dis
                nearestTargetEntity = e
            end
        end
    end

    if nearestTargetEntity then
        return nearestTargetEntity:GetGridPosition()
    end

    -- 保底情况：全场都取不到单格怪时，按远离玩家位置移动
    local posList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByFar)
    for i = 1, #walkRange - 1 do --最后一个是自身位置
        local v2 = walkRange[i]
        AINewNode.InsertSortedArray( posList, v2, posSelf, i)
    end

    return self:FindPosValid(posList, posSelf)
end

--function ActionIlluminaHealerMoveToTeammate:FindNewWalkPos(posWalkList, posTarget, posSelf)
--    return posTarget
--end

---@param array Vector2[]
---@param dict table<number, boolean>
---@param source Vector2[]
---@private
function ActionIlluminaHealerMoveToTeammate:_AppendVector2Array(array, dict, source)
    for _, v2 in ipairs(source) do
        local idx = Vector2.Pos2Index(v2)
        if not dict[idx] then
            dict[idx] = true
            table.insert(array, v2)
        end
    end
end
