--[[---------------------------------------------------------------
    2020-07-06 韩玉信
    ActionIs_ValidHitBackPos 检测目标是否是一个有效的击退位置
    原理： 计算出击退后的落点位置
        击退炸弹，落点周围有玩家时返回 AINewNodeStatus.Success
        击退玩家，落点后面是炸弹时返回 AINewNodeStatus.Success
--]] ---------------------------------------------------------------
require "action_is_base"
---------------------------------------------------------------
_class("ActionIs_ValidHitBackPos", ActionIsBase)
---@class ActionIs_ValidHitBackPos:ActionIsBase
ActionIs_ValidHitBackPos = ActionIs_ValidHitBackPos

function ActionIs_ValidHitBackPos:Constructor()
end

function ActionIs_ValidHitBackPos:OnUpdate(dtTime)
    local nSkillID = self:GetLogicData(1)
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local posSelf = self.m_entityOwn:GetGridPosition()
    ---@type Entity
    local entityPlayer = aiCmpt:GetTargetDefault()
    local posPlayer = entityPlayer:GetGridPosition()

    local nIsValid = 0
    ---@type Entity
    local entityTarget = aiCmpt:GetTargetEntity()
    local posHitTarget = self:_CalHitTargetPos(posSelf, entityTarget, nSkillID)
    if entityTarget == entityPlayer then
        local posDir = GameHelper.ComputeLogicDir(posPlayer - posSelf)
        ---@type TrapServiceLogic
        local trapServiceLogic = self._world:GetService("TrapLogic")
        ---@type UtilDataServiceShare
        local utilSvc = self._world:GetService("UtilData")
        local posTrapPlan = posHitTarget + posDir
        if trapServiceLogic:HasLiveBomb(posTrapPlan) then
            local trapBomb = utilSvc:FindTrapByTypeAndPos(TrapType.BombByHitBack, posTrapPlan)
            if trapBomb and table.count(trapBomb) > 0 then
                self:PrintLog("skillID = " ,nSkillID ,", 有效击退点<玩家>" ,self:_MakePosString(posHitTarget))
                nIsValid = AINewNodeStatus.Success
            else
                self:PrintLog("skillID = " ,nSkillID ,", 无效击退点<玩家>" ,self:_MakePosString(posHitTarget))
                nIsValid = AINewNodeStatus.Failure
            end
        else
            self:PrintLog("skillID = " ,nSkillID ,", 有效击退点<玩家>" ,self:_MakePosString(posHitTarget))
            nIsValid = AINewNodeStatus.Success
        end
    else
        -- ---2020-07-16 封闭炸弹爆炸范围的判定代码
        -- local listBombAttack = ComputeScopeRange.ComputeRange_SquareRing(posHitTarget, 1, 1, false)
        -- local bValidPos = table.icontains(listBombAttack, posPlayer)
        local posBomb = entityTarget:GetGridPosition()
        local bValidPos = self:_IsCanHitBombToPlayer(posSelf, posBomb, posPlayer, self:GetLogicData(-1))
        if bValidPos then
            self:PrintLog("skillID = " ,nSkillID ,", 有效击退点<炸弹>" ,self:_MakePosString(posHitTarget))
            nIsValid = AINewNodeStatus.Success
        else
            self:PrintLog("skillID = " ,nSkillID ,", 无效击退点<炸弹>" ,self:_MakePosString(posHitTarget))
            nIsValid = AINewNodeStatus.Failure
        end
    end

    return nIsValid
end
---------------------------------------------------------------
---计算击退位置
---@param entityMonster Entity
---@param entityBomb Entity
function ActionIs_ValidHitBackPos:_CalHitTargetPos(posAttacker, entityBomb, nSkillID)
    local posDefender = entityBomb:GetGridPosition()
    local bodyDefender = entityBomb:BodyArea()
    local dir = GameHelper.ComputeLogicDir(posDefender - posAttacker)
    local nHitDistance = nil
    local ignorePlayerBlock = false

    ---@type ConfigDecorationService
    local svcCfgDeco = self._world:GetService("ConfigDecoration")
    local skillEffectArray = svcCfgDeco:GetLatestEffectParamArray(entityBomb:GetID(), nSkillID)
    for i = 1, #skillEffectArray do
        local effectType = skillEffectArray[i]:GetEffectType()
        if effectType == SkillEffectType.HitBack then
            nHitDistance = skillEffectArray[i]:GetDistance()
            break
        end
    end
    nHitDistance = nHitDistance or 9

    ---@type SkillEffectCalcService
    local skillEffectService = self._world:GetService("SkillEffectCalc")
    local targetPos =
        skillEffectService:CalHitbackPosByEntityDir(
        posDefender,
        bodyDefender,
        dir,
        nHitDistance,
        {},
        ignorePlayerBlock,
        entityBomb
    )
    return targetPos
end

---------------------------------------------------------------
