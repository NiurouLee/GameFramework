--[[
    ActionLastSkillDamageTargetAntiCaster 当前AI上一个技能伤害到的目标施放一个技能，技能目标是当前AI（需要排除技能范围的其他目标）
--]]
require "action_is_base"
_class("ActionLastSkillDamageTargetAntiCaster", ActionIsBase)
---@class ActionLastSkillDamageTargetAntiCaster:ActionIsBase
ActionLastSkillDamageTargetAntiCaster = ActionLastSkillDamageTargetAntiCaster

function ActionLastSkillDamageTargetAntiCaster:OnUpdate()
    local skillID = self:GetLogicData(-1)
    local targetChessClassID = self:GetLogicData(-2)

    --存的目标
    ---@type AISkillResult
    local targetAISkillResult = nil
    local targetEntity

    ---@type AIRecorderComponent
    local recorderCmpt = self._world:GetBoardEntity():AIRecorder()
    -- local entityIDList = recorderCmpt:GetAICasterIDList()

    --第一阶段 找自己的技能结果中 是否攻击到了指定棋子
    ---@type AIResultCollection
    local collection = recorderCmpt:GetAIResultCollection(self.m_entityOwn:GetID())
    if collection and collection:HasSpellResult() then
        local resList = collection:GetSpellResultList()
        for _, v in ipairs(resList) do
            ---@type AISkillResult
            local aiSkillResult = v
            ---@type SkillEffectResultContainer
            local skillEffectResultContainer = aiSkillResult:GetResultContainer()

            ---@type SkillDamageEffectResult[]
            local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
            if resultArray then
                for _, v in ipairs(resultArray) do
                    ---@type SkillDamageEffectResult
                    local skillResult = v
                    local targetID = skillResult:GetTargetID()
                    local curTargetEntity = self._world:GetEntityByID(targetID)
                    if curTargetEntity and not curTargetEntity:HasDeadMark() then
                        ---@type ChessPetComponent
                        local chessPetCmpt = curTargetEntity:ChessPet()
                        if chessPetCmpt then
                            local chessPetClassID = chessPetCmpt:GetChessPetClassID()
                            if targetChessClassID == chessPetClassID then
                                targetEntity = curTargetEntity
                                targetAISkillResult = aiSkillResult
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not targetEntity then
        return AINewNodeStatus.Failure
    end

    --目标眩晕跳过反击
    ---@type BuffComponent
    local buffCmpt = targetEntity:BuffComponent()
    local isStun = buffCmpt:HasFlag(BuffFlags.SkipTurn)
    if isStun then
        return AINewNodeStatus.Failure
    end

    --第二阶段 判断自己是否在棋子的反击范围内
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(skillID)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    local selfPos = self.m_entityOwn:GetGridPosition()
    local curBodyArea = self.m_entityOwn:BodyArea():GetArea()
    local curBodyPosList = {}
    for _, pos in ipairs(curBodyArea) do
        local workPos = selfPos + pos
        table.insert(curBodyPosList, workPos)
    end

    local targetPos = targetEntity:GetGridPosition()
    local targetDir = targetEntity:GridLocation().Direction
    local targetBodyArea = targetEntity:BodyArea():GetArea()

    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, targetPos, targetEntity, targetDir)

    local inRange = false
    for _, pos in ipairs(curBodyPosList) do
        if table.intable(scopeResult:GetAttackRange(), pos) then
            inRange = true
            break
        end
    end

    if inRange == false then
        return AINewNodeStatus.Failure
    end

    --第三阶段 设置范围目标
    scopeResult:ClearTargetIDs()
    scopeResult:AddTargetID(self.m_entityOwn:GetID())
    scopeResult:AddTargetIDAndPos(self.m_entityOwn:GetID(), selfPos)

    ---@type SkillEffectResultContainer
    local skillResult = targetEntity:SkillContext():GetResultContainer()
    skillResult:Clear()
    skillResult:SetSkillID(skillID)
    skillResult:SetScopeResult(scopeResult)

    ---主动技计算器
    local activeSkillCalculator = ActiveSkillCalculator:New(self._world)
    ---主动技计算流程
    activeSkillCalculator:DoCalculateSkill(targetEntity)

    ---@type SkillEffectResultContainer
    local result = targetEntity:SkillContext():GetResultContainer()
    targetEntity:ReplaceSkillContext()

    local antiChessResultList = {}
    table.insert(antiChessResultList, {entityID = targetEntity:GetID(), skillID = skillID, skillResult = skillResult})
    targetAISkillResult:SetAISkillResult_AntiChessResultList(antiChessResultList)

    return AINewNodeStatus.Success
end
