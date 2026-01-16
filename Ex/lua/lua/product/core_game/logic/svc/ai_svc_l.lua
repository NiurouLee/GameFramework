--[[------------------------------------------------------------------------------------------
    AIService AI使用的Service
]] --------------------------------------------------------------------------------------------

_class("AIService", Object)
---@class AIService:Object
AIService = AIService

function AIService:Constructor(world)
    self._world = world
    self.m_nRunningAiType = 0
    self.m_nRunningAiOrder = 0
end

function AIService:EnterService(monsterList, nLogicType, nOrder)
    self:PrintAIServiceLog(
        "[AI], =====EnterService： MonsterCount = [",
        #monsterList,
        "], LogicType.Order = [",
        nLogicType,
        ".",
        nOrder,
        "]"
    )
    self:SetRunningSign(nLogicType, nOrder)
    for i = 1, #monsterList do
        self:_OnEvent_AI(monsterList[i], true, nLogicType, nOrder)
    end
end
function AIService:ExistService(monsterList, nLogicType, nOrder)
    self:SetRunningSign(0, 0)
    for i = 1, #monsterList do
        self:_OnEvent_AI(monsterList[i], false)
    end
    self:PrintAIServiceLog(
        "[AI], =====ExistService： MonsterCount = [",
        #monsterList,
        "], LogicType.Order = [",
        nLogicType,
        ".",
        nOrder,
        "]"
    )
end

function AIService:SetRunningSign(nLogicType, nOrder)
    self.m_nRunningAiType = nLogicType
    self.m_nRunningAiOrder = nOrder
end

function AIService:_OnEvent_AI(entityWork, bEnable, nLogicType, order)
    ---@type AIComponentNew
    local aiComponent = entityWork:AI()
    if not aiComponent then
        return
    end
    if bEnable then
        aiComponent:OnEvent_EnableAiLogic(entityWork, nLogicType, order)
    else
        aiComponent:OnEvent_DisableAiLogic(entityWork)
        aiComponent:ClearAIRoundRunCount()
    end
end

local function Sort_StatLogicOrders(a, b)
    return a[1] < b[1]
end
function AIService:StatLogicOrders(nLogicType, orderList)
    local orders = orderList or {}
    ---@type Group
    local aiGroup = self._world:GetGroup(self._world.BW_WEMatchers.AI)
    local listAllEntity = aiGroup:GetEntities()
    local boardService = self._world:GetService("BoardLogic")
    local curGameTurn = self._world:GetGameTurn()
    local es = {}
    for i, e in ipairs(listAllEntity) do
        --在其他面的AI不激活
        if not e:HasOutsideRegion() then
            if e:HasOffBoardMonster() then--手动离场的怪 ai继续执行（符文刺客）
                es[#es + 1] = e
            else
                local pos = e:GridLocation().Position
                if boardService:IsInAIArea(pos) then
                    es[#es + 1] = e
                end
            end
        end
    end
    listAllEntity = es

    for i = 1, #listAllEntity do
        ---@type Entity
        local e = listAllEntity[i]
        --回合判定
        if e:GameTurn():GetGameTurn() == curGameTurn then
            ---@type AIComponentNew
            local aiComponent = e:AI()
            local orderList = aiComponent:GetAILogicOrders(nLogicType)
            for _, order in ipairs(orderList) do
                local hasorder = false
                for _, v in ipairs(orders) do
                    if v[1] == order then
                        if not table.icontains(v[2], e) then
                            table.insert(v[2], e)
                        end
                        hasorder = true
                        break
                    end
                end
                if not hasorder then
                    orders[#orders + 1] = {order, {e}}
                end
            end
        end
    end

    table.sort(
        orders,Sort_StatLogicOrders
    )

    return orders
end

function AIService:RunAiLogicByOrder(listEntity, nLogicType, nOrder)
    nOrder = nOrder or 1000
    local nCountEntity = #listEntity
    if nCountEntity <= 0 then
        return
    end
    self._world:GetSyncLogger():Trace(
        {key = "RunAiLogicByOrder", entityCount = nCountEntity, logicType = nLogicType, nOrder = nOrder}
    )

    ---@type AIRecorderComponent
    local aiRecorderCmpt = self._world:GetBoardEntity():AIRecorder()
    ---@type AISchedulerService
    local aiSchedulerService = self._world:GetService("AIScheduler")

    aiRecorderCmpt:AddOrderResult(nOrder)

    self:EnterService(listEntity, nLogicType, nOrder)

    local nCountDown = 0
    local nCountHaveDown = 0
    local maxCalcCount = 100

    aiSchedulerService:SetAIList(listEntity)

    for i = 1, 100 do
        nCountDown = nCountDown + 1
        local ok = aiSchedulerService:DoScheduleAILogic()
        if ok then
            break
        end
    end

    if nCountDown >= maxCalcCount then
        for i = 1, nCountEntity do
            ---@type AIComponentNew
            local aiComponent = listEntity[i]:AI()
            if aiComponent and not aiComponent:IsLogicEnd() then
                aiComponent:OutErrorLog("<AI计算次数超过100>")
            end
        end
        if EDITOR then
            Log.exception("AI计算次数超过100")
        end
    end

    self:ExistService(listEntity, nLogicType, nOrder)
end

function AIService:_CheckAIOrder(alreadyExeOrder, orderArray, nowOrder)
    if table.icontains(alreadyExeOrder, nowOrder) then
        local alreadyStr = ""
        local orderArrayStr = ""

        for i, m in ipairs(orderArray) do
            orderArrayStr = orderArrayStr .. tostring(m[1]) .. ","
        end

        for i, order in ipairs(alreadyExeOrder) do
            alreadyStr = alreadyStr .. tostring(order) .. ","
        end
        self:PrintAIServiceLog(
            "Order:",
            nowOrder,
            " is repeatRun ,AlreadyRunOrderList:",
            alreadyStr,
            "OrderArray:",
            orderArrayStr
        )
        if EDITOR then
            Log.exception("Order:", nowOrder, " 重复执行")
        end
    end
    table.insert(alreadyExeOrder, nowOrder)
end

function AIService:RunAiLogic_WaitEnd(nLogicType)
    local orderArray = self:StatLogicOrders(nLogicType)
    local i = 1
    local alreadyExeOrder = {}
    while i <= #orderArray do
        local v = orderArray[i]
        local aiOrder = v[1]
        local aiEntities = v[2]
        self:_CheckAIOrder(alreadyExeOrder, orderArray, aiOrder)
        self:PrintAIServiceLog("RunAiLogic_WaitEnd AI order=", aiOrder)
        self:RunAiLogicByOrder(aiEntities, nLogicType, aiOrder)
        orderArray = self:StatLogicOrders(nLogicType, orderArray)
        i = i + 1
    end

    --结果通知表现层
    self:_UpdateAILogicResult()
end

-- function AIService:RunAiLogic_OneOrder(listEntity, nLogicType, nOrder)
--     self:RunAiLogicByOrder(listEntity, nLogicType, nOrder)
--     --结果通知表现层
--     self:_UpdateAILogicResult()
-- end

function AIService:_UpdateAILogicResult()
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RAILogicData()
end

---@param e Entity
function AIService:AddPauseFlag(e, pauseDuration)
    if e == nil or pauseDuration <= 0 then
        return
    end

    e:AddPauseFlag(pauseDuration)

    ---@type H3DTimer
    local h3dTimer = self._world:GetWorldTimer()
    ---@type H3DTimerEvent
    self._removePauseFlagEvent = h3dTimer:AddEvent(pauseDuration, self._RemovePauseFlag, self, e)
end

---@param e Entity
function AIService:_RemovePauseFlag(e)
    e:RemovePauseFlag()

    ---@type H3DTimer
    local h3dTimer = self._world:GetWorldTimer()
    h3dTimer:CancelEvent(self._removePauseFlagEvent)
    self._removePauseFlagEvent = nil
end

function AIService:PrintAIServiceLog(...)
    if self._world and self._world:IsDevelopEnv() then
        Log.debug(...)
    end
end
