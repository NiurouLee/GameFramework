--[[------------------------------------------------------------------------------------------
    AI调度服务，从AISystem改过来的
]] --------------------------------------------------------------------------------------------
require("base_service")
_class("AISchedulerService", BaseService)
---@class AISchedulerService:BaseService
AISchedulerService = AISchedulerService

function AISchedulerService:Initialize()
    ---@type AIService
    self.m_aiService = self._world:GetService("AI")
    ---@type BattleService
    self.m_battleService = self._world:GetService("Battle")
    self._boardService = self._world:GetService("BoardLogic")
    self.group = self._world:GetGroup(self._world.BW_WEMatchers.AI)
    self:_InitListScan()
    self.m_bRebuildScan = true
end

function AISchedulerService:_InitListScan()
    -- 这段单独拿出来，之后可以考虑MT_Chess有专属的AISchedulerService_Chess(类似BattleService_Maze)
    if self._world:MatchType() == MatchType.MT_Chess then
        self.m_listScan = SortedArray:New(Algorithm.COMPARE_CUSTOM, AISchedulerService._ChessModeComparer)
    else
        self.m_listScan = SortedArray:New(Algorithm.COMPARE_CUSTOM, AISchedulerService._LessComparer)
    end
    self.m_listScan:AllowDuplicate() --允许重复元素
end

function AISchedulerService:GetAIList()
    return self.m_listScan
end

function AISchedulerService:SetAIList(elist)
    self.m_listScan:Clear()
    for i, e in ipairs(elist) do
        if not e:AI():IsLogicEnd() then
            self.m_listScan:Insert(e)
        end
    end
end

---调度AI的主过程
function AISchedulerService:DoScheduleAILogic()
    return self:_UpdateWorkList()
end

---更新指定队列的AI
function AISchedulerService:DoUpdateAIList()
    for i = 1, self.m_listScan:Size() do
        local e = self.m_listScan:GetAt(i)
        self:UpdateAI(e)
    end
end

---@param e Entity
function AISchedulerService:UpdateAI(e)
    ---@type AIComponentNew
    if nil == e then
        return
    end
    local pos = e:GridLocation().Position
    local aiComponent = e:AI()
    if aiComponent:IsLogicEnd() or e:HasDeadMark() then
        return
    end
    local timeService = self._world:GetService("Time")
    local deltaTimeMS = timeService:GetDeltaTimeMs()
    aiComponent:Update(deltaTimeMS)
    aiComponent:ResetLogic()
end

--- 更新工作队列，返回是否结束
function AISchedulerService:_UpdateWorkList()
    local listWork = self.m_listScan
    local nMaxCount = listWork:Size()
    if nMaxCount <= 0 then
        return true
    end
    local nCountHaveDown = 0
    for i = 1, nMaxCount do
        ---@type Entity
        local entityWork = listWork:GetAt(i)
        local bUpdate = false
        ---@type AIComponentNew
        local aiComponent = nil
        if entityWork and not entityWork:HasDeadMark() then
            aiComponent = entityWork:AI()
            if false == aiComponent:IsLogicEnd() then
                self:UpdateAI(entityWork)
                aiComponent:OutLog("扫描队列<退出>")
            end
        else
            Log.fatal("EntityIsDead:",entityWork:GetID())
        end
        if entityWork:HasDeadMark() or aiComponent:IsAIRoundEnd() then
            nCountHaveDown = nCountHaveDown + 1
        end
    end

    return nCountHaveDown == nMaxCount
end

----------------------------------------------------------------
AISchedulerService._LessComparer = function(entityA, entityB)
    local nDistanceA = entityA:AI():GetDistance()
    local nDistanceB = entityB:AI():GetDistance()
    if nDistanceA < nDistanceB then
        return 1
    elseif nDistanceA > nDistanceB then
        return -1
    else ---距离相同，按顺时针排序
        ---@type AIComponentNew
        local center = entityA:AI():GetTargetPos()
        local a = entityA:GridLocation().Position
        local b = entityA:GridLocation().Position
        if a.x - center.x >= 0 and b.x - center.x < 0 then
            return 1
        end
        if a.x - center.x < 0 and b.x - center.x >= 0 then
            return -1
        end

        local nReturn = 0
        if a.x - center.x == 0 and b.x - center.x == 0 then
            if a.y - center.y >= 0 or b.y - center.y >= 0 then
                nReturn = a.y - b.y
            else
                nReturn = b.y - a.y
            end
        end
        if 0 == nReturn then
            local det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y)
            if det < 0 then
                nReturn = 1
            elseif det > 0 then
                nReturn = -1
            end
        end
        if 0 == nReturn then
            local nIDA = entityA:GetID()
            local nIDB = entityB:GetID()
            nReturn = nIDA - nIDB
        end
        if nReturn > 0 then
            return 1
        elseif nReturn < 0 then
            return -1
        else
            return 0
        end
    end
    return 0
end
----------------------------------------------------------------.

---@param entityA Entity
---@param entityB Entity
---@return number {1, 0, -1}
AISchedulerService._ChessModeComparer = function(entityA, entityB)
    if entityA == nil or not entityA:MonsterID() then 
        return 0
    end

    if entityB == nil or not entityB:MonsterID() then 
        return 0
    end

    local mstIDA = entityA:MonsterID():GetMonsterID()
    local mstIDB = entityB:MonsterID():GetMonsterID()

    if (not entityA:HasMonsterID()) or (not entityB:HasMonsterID()) then
        goto COMPARE_ENTITY_ID_INSTEAD
    end

    if mstIDA ~= mstIDB then
        return (mstIDA < mstIDB) and (1) or (-1)
    end

    ::COMPARE_ENTITY_ID_INSTEAD::
    local eidA = entityA:GetID()
    local eidB = entityB:GetID()
    if eidA == eidB then
        return 0
    else
        return (eidA < eidB) and (1) or (-1)
    end
end
