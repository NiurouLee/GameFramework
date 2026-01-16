--[[-------------------------------------------
    ActionSaveRoundCount 返回自己维护的回合数
--]] -------------------------------------------
require "ai_node_new"
----------------------------------------------------------------
_class("ActionRoundBase", AINewNode)
---@class ActionRoundBase : AINewNode
ActionRoundBase = ActionRoundBase

function ActionRoundBase:Constructor()
    self.m_nRoundData = 0 ---当前回合
end
function ActionRoundBase:InitializeNode(cfg, context, logicOwn, configData)
    ActionRoundBase.super.InitializeNode(self, cfg, context, logicOwn, configData)
end
function ActionRoundBase:Reset()
    ActionRoundBase.super.Reset(self)
    self.m_nRoundData = self:GetRuntimeData("RoundCount") or 0
end
--------------------------------
function ActionRoundBase:_MakeRoundCount(nRoundData, nLoopLimit)
    ---(0,N-1) ==> (1,N)
    local nNewRound = math.fmod(nRoundData - 1, nLoopLimit) + 1
    return nNewRound
end
---当前回合数+1并保存
function ActionRoundBase:_SaveRoundCount(nSaveRound, nLoopLimit)
    ---维护当前回合数
    local nRountNow = self:_MakeRoundCount(nSaveRound + 1, nLoopLimit)
    ---计算下一回合数
    local nRountNext = self:_MakeRoundCount(nRountNow + 1, nLoopLimit)

    self:SetRuntimeData("RoundCount", nRountNow)
    self:SetRuntimeData("NextRoundCount", nRountNext)
    self:PrintLog( "m_nRoundNow = ", nRountNow, ", m_nRountNext = ", nRountNext)
    return nRountNow
end
function ActionRoundBase:TryToSaveRoundCount(nLoopLimit)
    local nGameRound = self:GetGameRountNow()
    local nSaveRound = self:GetRuntimeData("GameRound")
    if nil == nSaveRound or nSaveRound ~= nGameRound then
        self.m_nRoundData = self:_SaveRoundCount(self.m_nRoundData, nLoopLimit)
        self:SetRuntimeData("GameRound", nGameRound)
        return true
    else
        self.m_nRoundData = self:GetRuntimeData("RoundCount")
    end
    return false
end
----------------------------------------------------------------
---保存循环的回合数
_class("ActionRound_SaveOnly", ActionRoundBase)
---@class ActionRound_SaveOnly : ActionRoundBase
ActionRound_SaveOnly = ActionRound_SaveOnly

function ActionRound_SaveOnly:OnBegin()
    ---循环阈值
    local nLoopLimit = self:GetLogicData(-1)
    if nil == nLoopLimit or nLoopLimit <= 0 then
        nLoopLimit = self:GetRuntimeData("SkillCount") or 1
    end
    local nSaveAction = self:TryToSaveRoundCount(nLoopLimit)
end

function ActionRound_SaveOnly:OnUpdate()
    return AINewNodeStatus.Success
end
----------------------------------------------------------------
---保存并返回循环的回合数
_class("ActionSaveRoundCount", ActionRound_SaveOnly)
---@class ActionSaveRoundCount : ActionRound_SaveOnly
ActionSaveRoundCount = ActionSaveRoundCount

function ActionSaveRoundCount:OnUpdate()
    local nRoundCount = self.m_nRoundData
    self:PrintDebugLog("RoundCount = ",nRoundCount)
    return AINewNodeStatus.Other + nRoundCount
end
----------------------------------------------------------------
---返回循环的回合数
_class("ActionRound_GetSave", AINewNode)
---@class ActionRound_GetSave : AINewNode
ActionRound_GetSave = ActionRound_GetSave
function ActionRound_GetSave:OnUpdate()
    local nRoundLogic = self:GetRuntimeData("RoundCount")
    self:PrintDebugLog("RoundCount = ",nRoundLogic)
    return AINewNodeStatus.Other + nRoundLogic
end
----------------------------------------------------------------
---判断循环的回合数是否是设定值
_class("ActionRound_IsSame", AINewNode)
---@class ActionRound_IsSame : AINewNode
ActionRound_IsSame = ActionRound_IsSame
function ActionRound_IsSame:OnUpdate()
    local nConfigData = self:GetLogicData(-1)
    local nGameRound = self:GetGameRountNow()
    local nSaveRound = self:GetRuntimeData("GameRound")
    local nRoundLogic = self:GetRuntimeData("RoundCount") or 0
    if nGameRound == nSaveRound then ---每回合的第N次进入： RoundCount更新后
        nRoundLogic = self:GetRuntimeData("RoundCount") or 0
    else ---每回合的第一次进入： RoundCount更新前
        nRoundLogic = self:GetRuntimeData("NextRoundCount") or 0
    end
    self:PrintLog(" nSaveRound = ", nRoundLogic, ", nConfigData = ", nConfigData)
    self:PrintDebugLog(" nSaveRound = ", nRoundLogic, ", nConfigData = ", nConfigData)
    if nConfigData == nRoundLogic then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
----------------------------------------------------------------
---回合数是否比阈值大
_class("ActionRound_IsLimit", ActionRoundBase)
---@class ActionRound_IsLimit : ActionRoundBase
ActionRound_IsLimit = ActionRound_IsLimit

function ActionRound_IsLimit:OnBegin()
    ---循环阈值
    local nLoopLimit = 10000
    self:TryToSaveRoundCount(nLoopLimit)
end

function ActionRound_IsLimit:OnUpdate()
    local nRountCount = self.m_nRoundData
    local nLimitCount = self:GetLogicData(-1)
    self:PrintDebugLog("RoundCount = ",nRountCount," LimitCount = ",nLimitCount)
    if nRountCount >= nLimitCount then
        return AINewNodeStatus.Success
    end
    return AINewNodeStatus.Failure
end
----------------------------------------------------------------

---@class ActionSetRoundCount : ActionRoundBase
_class("ActionSetRoundCount", ActionRoundBase)
ActionSetRoundCount = ActionSetRoundCount

function ActionSetRoundCount:OnBegin()
    local roundCount = self:GetLogicData(-1)
    local nextRoundCount = self:GetLogicData(-2)
    local gameRound = self:GetLogicData(-3)
    self:SetRuntimeData("RoundCount", roundCount)
    self:SetRuntimeData("NextRoundCount", nextRoundCount)
    if not gameRound then
        gameRound = self:GetGameRountNow()
    end
    self:SetRuntimeData("GameRound", gameRound)
end

function ActionSetRoundCount:OnUpdate()
    return AINewNodeStatus.Success
end
