--循环生成模式
---@class RecursionGenType
local RecursionGenType = {
    None = 0,--不循环
    Always = 1,--一直循环
    Times = 2 --限定次数
}
_enum("RecursionGenType", RecursionGenType)

--怪物生成器
--计算新生成的怪物id
--生成的怪物
--增加到对象管理
---@class MonsterGenerator : Object
_class("MonsterGenerator", Object)
MonsterGenerator = MonsterGenerator

---@param cfgId number --生成器id
---@param genCall function --生成时回调函数
function MonsterGenerator:Init(cfgId, genCall)
    self.generatorId = cfgId
    self.generatorCall = genCall --生成对象时，回调
    self.durationMs = 0
    self.cfg = Cfg.cfg_bounce_monster_gen[cfgId]
    self.genBatchs = {}
    if not self.cfg then
        Log.fatal("err:MonsterGenerator can't find cfg_bounce_monster_gen with id = " .. cfgId)
        return
    end


    self.recursionMaxTimes = 0
    local recursion = self.cfg.Recursion
    if not recursion or recursion == 0 then
        self.recursionType = RecursionGenType.None
    elseif recursion < 0 then
        self.recursionType = RecursionGenType.Always
    else
        self.recursionType = RecursionGenType.Times
        self.recursionMaxTimes = recursion
    end

    self.recursionTimes = 0 --已循环生成次数
    self.durationPerRecurion = 0 --一次循环消耗总时间

    for i, v in ipairs(self.cfg.Product) do
        local batch = MonsterGeneratorBatch.New()
        local batchDelay = v[1]
        local batchRuleId = v[2]
        local ruleCfg = Cfg.cfg_bounce_monster_gen_rule[batchRuleId]
        if not ruleCfg then
            Log.fatal("MonsterGenerator err: can't find cfg_bounce_monster_rule with id = " .. batchRuleId)
            return
        end
        batch.ruleCfg = ruleCfg
        batch.offsetMs = self.durationPerRecurion + batchDelay
        batch.duration = ruleCfg.Num * ruleCfg.Interval
        self.durationPerRecurion = batch.offsetMs + batch.duration
        batch.hasGenNum = 0 --已生成数量
        table.insert(self.genBatchs, batch)
    end
end

--设置CoreController
---@param coreController BounceController 
function MonsterGenerator:SetCoreController(coreController)
    self.coreController = coreController
    
    ---@type  BounceMonsterPool 
    self.monsterPool = self.coreController:GetMonsterPool()
    
    ---@type  BounceObjMgr 
    self.objMgr = self.coreController:GetObjMgr()

    ---@type UnityEngine.RectTransform
    self.monsterParentRt = self.coreController:GetObjectsRoot()
end


function MonsterGenerator:Reset()
    self.durationMs = 0
    self.recursionTimes = 0
    self.genTaskOver = nil -- 生成任务结束
    for k, batch in pairs(self.genBatchs) do
        batch.hasGenNum = 0
    end

    self.nextGenrator = nil
end

function MonsterGenerator:OnUpdate(durationMs)
    if self.genTaskOver then
        if self.nextGenrator then
            self.nextGenrator:OnUpdate(durationMs)
        end
        return
    end

    self.durationMs = self.durationMs + durationMs
    --根据self.durationMs产生怪物
    local ruleCfg = nil
    local isGenAll = true
    for k, batch in pairs(self.genBatchs) do
        if not batch:IsGenFull() then
            isGenAll = false
            --判断是否可以生成
            local nextGenTime = batch:GetNextGenTime() + self.recursionTimes * self.durationPerRecurion
            if nextGenTime <= self.durationMs then
                ruleCfg = batch:GetRuleCfg()
                batch.hasGenNum = batch.hasGenNum + 1
            end
            break 
        end
    end

    --该循环所有batch都已生成，判断循环
    if isGenAll then
        self.recursionTimes = self.recursionTimes + 1
        if self.recursionType == RecursionGenType.None then
            self.genTaskOver = true
            self:InitNextGenerator()
        elseif self.recursionType == RecursionGenType.Always then
            for k, v in pairs(self.genBatchs) do
                v:Reset()
            end
        elseif self.recursionType == RecursionGenType.Times then
            if self.recursionMaxTimes >= self.recursionMaxTimes then
                self.genTaskOver = true
                self:InitNextGenerator()
            else
                for k, v in pairs(self.genBatchs) do
                    v:Reset()
                end
            end
        end
        
    end

    --generate monster and add to objMgr
    if ruleCfg then
        local monsterId = ruleCfg.Monster
        local monster = self.monsterPool:Get(monsterId)
        --SetMonster values
        monster:SetCoreController(self.coreController)
        ---@type MonsterBeHaviorView
        local view = monster:GetBehavior(MonsterBeHaviorView.Name())
        if view then
            view:SetParent(self.monsterParentRt)
        end
        ---@type MonsterBeHaviorPosition
        local posBehaviour = monster:GetBehavior(MonsterBeHaviorPosition.Name())
        if posBehaviour then
            local initPos = Vector2(ruleCfg.Pos[1], ruleCfg.Pos[2])
            posBehaviour:SetPosition(initPos)
        end
        self.objMgr:AddMonster(monster)

        --call after generate
        if self.generatorCall then
            self.generatorCall()
        end
    end
end

function MonsterGenerator:InitNextGenerator()
    --init next generator
    if self.cfg.NextGenId then
        self.nextGenrator = MonsterGenerator:New()
        self.nextGenrator:Init(self.cfg.NextGenId, self.generatorCall)
        self.nextGenrator:SetCoreController(self.coreController)
    end
end

--怪物生成批次
---@class MonsterGeneratorBatch : Object
_class("MonsterGeneratorBatch", Object)
MonsterGeneratorBatch = MonsterGeneratorBatch

function MonsterGeneratorBatch:Constructor()
    --Cfg.cfg_bounce_monster_gen
    self.ruleCfg = nil
    self.offsetMs = 0
    self.duration = 0

    self.hasGenNum = 0 --已生成数量
end

function MonsterGeneratorBatch:Reset()
    self.hasGenNum =0
end

--是否生成完成
function MonsterGeneratorBatch:IsGenFull()
    return self.hasGenNum == self.ruleCfg.Num
end

--下一次生成时间
function MonsterGeneratorBatch:GetNextGenTime()
    return self.offsetMs + (self.hasGenNum + 1) * self.ruleCfg.Interval
end

function MonsterGeneratorBatch:GetRuleCfg()
    return self.ruleCfg
end
