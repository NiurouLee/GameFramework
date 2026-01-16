--[[
    自动白盒测试服务
]]
_class("AutoTestService", BaseService)
---@class AutoTestService : BaseService
AutoTestService = AutoTestService

function AutoTestService:Constructor()
    ---@type AutoTestModule
    self.md = GameGlobal.GetModule(AutoTestModule)
    self._cheat = AutoTestCheat:New(self._world, self)
    self._isRunning = false
    self._blackBoard = {} --黑板
    self._checkPoints = {} --检查点
    self._logCollector = {} --日志收集器
    self._logs = {} --日志
    self._entities = {} --命名对象
end

function AutoTestService:IsRunning()
    return self._isRunning
end

--自动测试[waitinput状态开始执行]
function AutoTestService:AutoTest(TT)
    local config = self.md:GetTestConfig()
    local setup = self.md:GetTestSetup()
    local cases = config.cases
    self:BeginAutoTest_Test(config, setup)
    self:BeginSuiteLog_Test(config.name)
    for i, case in ipairs(cases) do
        self:RunCase(TT, case)
    end
    self:EndSuiteLog_Test()
    self:EndAutoTest_Test()
end

---@param setup AutoTestSetup
function AutoTestService:BeginAutoTest_Test(config, setup)
    self._isRunning = true
    self._checkPoints = {} --检查点
    self._logCollector = {} --日志收集器
    self._logs = {} --日志
    self._entities = {} --命名对象
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    self._entities["team"] = teamEntity
    local es = teamEntity:Team():GetTeamPetEntities()
    for i, e in ipairs(es) do
        local petid = e:PetPstID():GetTemplateID()
        for _, pet in ipairs(config.petList) do
            if pet.id == petid then
                if self._entities[pet.name] then
                    Log.error("白盒测试对象命名冲突：", pet.name)
                end
                self._entities[pet.name] = e
                break
            end
        end
    end

    --黑拳赛
    local teamEntity = self._world:Player():GetRemoteTeamEntity()
    if teamEntity then
        self._entities["enemy"] = teamEntity
        local es = teamEntity:Team():GetTeamPetEntities()
        for i, e in ipairs(es) do
            local petid = e:PetPstID():GetTemplateID()
            for _, pet in ipairs(config.remotePet) do
                if pet.id == petid then
                    if self._entities[pet.name] then
                        Log.error("白盒测试对象命名冲突：", pet.name)
                    end
                    self._entities[pet.name] = e
                    break
                end
            end
        end
    end

    --关卡配置
    setup:OnWaitInput(self._world)
end

function AutoTestService:EndAutoTest_Test()
    self._blackBoard = {} --黑板清空
    self.md:AddResultLogs(self._logs)
    --退出测试
    self.md:AutoTestClose()
    --self._isRunning = false
end

function AutoTestService:RunCase(TT, case)
    self:BeginCaseLog_Test(case.name)
    for i, node in ipairs(case) do
        local action = self._cheat[node.action .. "_Test"]
        if not action then
            local class = Classes[node.action .. "_Test"]
            if class then
                self:AddCheckPoint_Test(node)
            else
                Log.exception("RunCase() not find action=", node.action)
                return
            end
        else
            Log.debug("[AutoTest] RunCase action:", i, " ", node.action)
            action(self._cheat, TT, node.args)
        end
        YIELD(TT, 100)
    end
    self:EndCaseLog_Test()
    self:RemoveCheckPoints_Test()
end

function AutoTestService:BeginSuiteLog_Test(suiteName)
    table.insert(
        self._logCollector,
        {
            suiteName = suiteName,
            time = os.date("%Y-%m-%d %H:%M:%S")
        }
    )
end

function AutoTestService:BeginCaseLog_Test(caseName)
    local suiteLog = self._logCollector[#self._logCollector]
    suiteLog[#suiteLog + 1] = { caseName = caseName }
end

function AutoTestService:AddActionLog_Test(t)
    local suiteLog = self._logCollector[#self._logCollector]
    local caseLog = suiteLog[#suiteLog]
    caseLog[#caseLog + 1] = t
end

function AutoTestService:EndCaseLog_Test()
    for i, v in ipairs(self._checkPoints) do
        local t = v.checker:CollectResult()
        self:AddActionLog_Test(t)
    end
end

function AutoTestService:EndSuiteLog_Test()
    local fail = false
    local suiteLog = self._logCollector[#self._logCollector]
    local mdb = MarkdownBuilder:New()
    local consoleLog = "[" .. suiteLog.time .. "] TestSuite:" .. suiteLog.suiteName .. "\n"
    local s = "[" .. suiteLog.time .. "] TestSuite:" .. suiteLog.suiteName
    mdb:AppendH1(s)
    for i, case in ipairs(suiteLog) do
        consoleLog = consoleLog .. "\t[" .. i .. "] TestCase:" .. case.caseName .. "\n"
        s = "[" .. i .. "] TestCase:" .. case.caseName
        mdb:AppendH2(s)

        for i, action in ipairs(case) do
            consoleLog = consoleLog .. "\t\t" .. "[" .. action.actionName .. "] result:"
            s = "\t\t" .. "[" .. action.actionName .. "] result:"
            mdb:AppendText(s)
            if action.result == AutoTestCheckResult.CheckPassed then
                consoleLog = consoleLog .. "<color=#00e300>" .. GetEnumKey("AutoTestCheckResult", action.result) .. "</color>"
                s = GetEnumKey("AutoTestCheckResult", action.result)
                mdb:AppendColorGreen(s)
            else
                fail = true
                consoleLog = consoleLog .. "<color=#f30000>" .. GetEnumKey("AutoTestCheckResult", action.result) .. "</color>"
                s = GetEnumKey("AutoTestCheckResult", action.result)
                mdb:AppendColorRed(s)
            end
            consoleLog = consoleLog .. action.message .. "\n"
            s = action.message .. "\n"
            mdb:AppendColorGray(s)
        end
    end

    Log.debug(consoleLog)
    s = mdb:ToString()

    if fail and self.md:GetStartType() ~= AutoTestStartType.Debug then
        self.md:AddFailedSuite(suiteLog.suiteName)
        WorkWXPoster.SendWorkWXMarkDown(s)
    end
    table.insert(self._logs, consoleLog)
end

--添加检查点
function AutoTestService:AddCheckPoint_Test(node)
    local action = node.action
    local args = node.args
    local class = _G[action .. "_Test"]
    if not class then
        Log.error("AddCheckPoint_Test not find check point ", action)
        return
    end
    local e = self._entities[args.name or "team"]
    local checker = class:New(e, args, self._world)
    if args.trigger == 0 then --立即检查
        checker:OnTrigger()
        table.insert(self._checkPoints, { trigger = nil, checker = checker })
        return
    end
    ---@type TriggerService
    local svc = self._world:GetService("Trigger")
    local cond = { { args.trigger }, { 1 } }
    local trigger = svc:CreateTrigger(checker, cond, self._world)
    trigger:SetActive(true)
    svc:Attach(trigger)
    table.insert(self._checkPoints, { trigger = trigger, checker = checker })
end

--清除检查点
function AutoTestService:RemoveCheckPoints_Test()
    ---@type TriggerService
    local svc = self._world:GetService("Trigger")
    for i, v in ipairs(self._checkPoints) do
        if v.trigger then
            svc:Detach(v.trigger)
        end
    end
    self._checkPoints = {}
end

--清除已经检查通过的检查点
function AutoTestService:DetachCheckPassedPoints_Test()
    ---@type TriggerService
    local svc = self._world:GetService("Trigger")
    for i, v in ipairs(self._checkPoints) do
        if v.checker._result == AutoTestCheckResult.CheckPassed and v.trigger then
            svc:Detach(v.trigger)
        end
    end
end

--黑板写入值
function AutoTestService:WriteBlackBoard_Test(key, value)
    self._blackBoard[key] = value
end

--黑板读取值
function AutoTestService:ReadBlackBoard_Test(key, default)
    return self._blackBoard[key] or default
end

function AutoTestService:GetEntityByName_Test(entityName)
    local e = self._entities[entityName]
    return e
end

function AutoTestService:SetEntityName_Test(name, entity)
    self._entities[name] = entity
end

function AutoTestService:SetGameOver_Test()
    self._gameOver = true
end

function AutoTestService:IsGameOver_Test()
    return self._gameOver
end
