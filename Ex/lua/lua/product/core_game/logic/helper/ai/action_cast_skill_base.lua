--[[-------------------------------------
    ActionCastSkillBase 释放特定的技能
--]] -------------------------------------
require "ai_node_new"
---@class ActionCastSkillBase : AINewNode
_class("ActionCastSkillBase", AINewNode)
ActionCastSkillBase = ActionCastSkillBase
----------------------------------------------------------------
function ActionCastSkillBase:Constructor()
    ---@type MainWorld
    self._world = nil
    self.m_nWaitTaskID = 0
    self.m_nWaitSkillType = 0
end

---@param cfg table
---@param context CustomNodeContext
function ActionCastSkillBase:InitializeNode(cfg, context, parentNode, configData)
    ActionCastSkillBase.super.InitializeNode(self, cfg, context, parentNode, configData)
end
--------------------------------    ---派生类要实现的函数
function ActionCastSkillBase:GetWorkSkillID()
    return nil
end
--------------------------------
function ActionCastSkillBase:OnBegin()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    --进这个节点表示自己移动完了
    aiCmpt:SetMoveState(AIMoveState.MoveEnd)
end

function ActionCastSkillBase:OnUpdate()
    local nSkillID = self:GetWorkSkillID()
    if not nSkillID or nSkillID <= 0 then
        self:PrintLog("释放技能，skillID = nil")
        return AINewNodeStatus.Failure
    end
    ---角色死亡，直接返回
    if AINewNode.IsEntityDead(self.m_entityOwn) then
        return AINewNodeStatus.Failure
    end

    ---麻痹Buff不放技能
    if self.m_entityOwn:BuffComponent():HasFlag(BuffFlags.Benumb) then
        self:PrintLog("施放技能<麻痹Buff不放技能>，技能ID = " ,nSkillID)
        return AINewNodeStatus.Failure
    end

    ---进入施放技能的节点，会算出来技能结果
    local ret = self:_CalcAISkill(nSkillID)
    return ret
end

function ActionCastSkillBase:_CalcAISkill(skillID)
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    self.m_nWaitSkillType = skillConfigData:GetSkillType()

    if SkillType.Normal == self.m_nWaitSkillType then
        self:PrintLog("施放普攻技能，技能ID = " ,skillID)
        self:PrintDebugLog("施放普攻技能，技能ID = " ,skillID)
        self:_CastNormalSkill(skillID)
        return AINewNodeStatus.Success
    else
        --移动结束才能放技能
        if self:_IsAllAIMoveDone() then
            self:PrintLog("所有AI移动结束，施放非普攻技能，技能ID = " ,skillID)
            self:PrintDebugLog("所有AI移动结束，施放非普攻技能，技能ID = " ,skillID)
            self:_CastSkill(skillID)
            return AINewNodeStatus.Success
        else
            self:PrintLog("本次施放非普攻技能失败，需要等待移动结束，技能ID = " ,skillID)
            --否则保持可施法状态结束本次循环
            return AINewNodeStatus.Failure
        end
    end
end

function ActionCastSkillBase:_CastNormalSkill(skillID)
    self:PrintLog2(" CastNormalSkill skillID=",skillID)
    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    ---@type AIRecorderComponent
    local recorderCmpt = self._world:GetBoardEntity():AIRecorder()

    local casterEntityID = self.m_entityOwn:GetID()
    local atkCount = 1
    --如果有两次普攻的属性则攻击两次，Buff中会修改这个属性
    if self.m_entityOwn:Attributes():GetAttribute("DoubleAtk") then
        atkCount = 2
    end

    for i = 1, atkCount do
        ---@type AISkillResult
        local aiResult = AISkillResult:New()
        aiResult:SetCastSkillDir(self.m_entityOwn:GetGridDirection())
        recorderCmpt:AddNormalAttackResult(casterEntityID, aiResult)

        skillLogicSvc:CalcAISkillResult(self.m_entityOwn, skillID, aiResult)
    end
end

function ActionCastSkillBase:_CastSkill(skillID)
    ---@type SkillLogicService
    local skillLogicSvc = self._world:GetService("SkillLogic")
    ---@type AIRecorderComponent
    local recorderCmpt = self._world:GetBoardEntity():AIRecorder()

    local casterEntityID = self.m_entityOwn:GetID()
    ---@type AISkillResult
    local aiResult = AISkillResult:New()
    aiResult:SetCastSkillDir(self.m_entityOwn:GetGridDirection())
    aiResult:SetCasterEntityID(casterEntityID)
    aiResult:SetParallelID(self:GetParallelID()) 
    recorderCmpt:AddSpellResult(casterEntityID, aiResult)

    self:PrintLog( " CastSkill skillID=", skillID)
    skillLogicSvc:CalcAISkillResult(self.m_entityOwn, skillID, aiResult)

    local deadChessPetEntityIDList = self:_HandleChessPetDead()
    aiResult:SetAISkillResult_DeadChessList(deadChessPetEntityIDList)
end

---战棋模式下需要处理棋子的死亡
function ActionCastSkillBase:_HandleChessPetDead()
    if self._world:MatchType() ~= MatchType.MT_Chess then
        return
    end

    ---@type ChessServiceLogic
    local chessSvc = self._world:GetService("ChessLogic")
    local deadIDList = chessSvc:GetDeadChessPetList()
    
    ---执行死亡逻辑
    chessSvc:DoChessPetListDeadLogic(deadIDList)

    return deadIDList
end