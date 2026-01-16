--[[
    改变传说星灵主动技能量
]]
--------------------------------

--------------------------------
_class("BuffLogicChangePetLegendPower", BuffLogicBase)
---@class BuffLogicChangePetLegendPower:BuffLogicBase
BuffLogicChangePetLegendPower = BuffLogicChangePetLegendPower

function BuffLogicChangePetLegendPower:Constructor(buffInstance, logicParam)
    self._enable = logicParam.enable or 1--列奥精炼修改buff参数，会在还没有附加主动技时就带有这个buff，但不应该生效
    self._addValue = logicParam.addValue or 0
    self._maxValue = logicParam.maxValue or 0
    ---region 减n%的能量（最少减少x）
    self._addPercent = logicParam.addPercent
    self._addPercentMinAbsValue = logicParam.addPercentMinAbsValue
    self._checkExtraSkillID = logicParam.checkExtraSkillID--附加主动技id，用这个id判断ready
end

function BuffLogicChangePetLegendPower:DoLogic(notify)
    if self._enable ~= 1 then
        return
    end
    --减少自己
    local petEntity = self._buffInstance:Entity()
    if not petEntity then
        return
    end

    local petPowerStateList = {}
    self:_OnChangePetPower(petEntity, petPowerStateList)

    local buffResult = BuffResultChangePetLegendPower:New(petPowerStateList)
    if notify then
        if notify.GetAttackPos and notify.GetTargetPos then
            buffResult.attackPos = notify:GetAttackPos()
            buffResult.targetPos = notify:GetTargetPos()
        end
    end
    return buffResult
end

function BuffLogicChangePetLegendPower:_OnChangePetPower(petEntity, petPowerStateList)
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    ---@type AttributesComponent
    local curAttributeCmpt = petEntity:Attributes()
    local curLegendPower = curAttributeCmpt:GetAttribute("LegendPower")
    local addValue = self:_CalcModifyValue(curLegendPower)
    local newPower = curLegendPower + addValue
    if newPower < 0 then
        newPower = 0
    end

    --限制了添加的最多数量
    if self._maxValue ~= 0 and newPower > self._maxValue then
        newPower = self._maxValue
    end

    local ready = false

    local activeSkillID = petEntity:SkillInfo():GetActiveSkillID()
    if self._checkExtraSkillID and self._checkExtraSkillID ~= 0 then
        activeSkillID = self._checkExtraSkillID
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID, petEntity)

    ---@type BuffLogicService
    local blsvc = self._buffLogicService
    
    local requireNTPowerReady = false
    --local minCost = skillConfigData:GetSkillTriggerParam()
    local minCost = blsvc:CalcMinCostByExtraParam(petEntity,activeSkillID)
    if newPower >= minCost then
        blsvc:ChangePetActiveSkillReady(petEntity, 1,activeSkillID)
        ready = true

        local notify = NTPowerReady:New(petEntity)
        self._world:GetService("Trigger"):Notify(notify)
        requireNTPowerReady = true
    else
        blsvc:ChangePetActiveSkillReady(petEntity, 0,activeSkillID)
        ready = false
    end
    
    if newPower > BattleConst.LegendPowerMax then
        newPower = BattleConst.LegendPowerMax
    end

    local previouslyReady = curLegendPower >= minCost
    curAttributeCmpt:Modify("LegendPower", newPower)

    if not petPowerStateList[petPstID] then
        petPowerStateList[petPstID] = {}
    end
    petPowerStateList[petPstID].petEntityID = petEntity:GetID()
    petPowerStateList[petPstID].petPstID = petPstID
    petPowerStateList[petPstID].power = newPower
    petPowerStateList[petPstID].ready = ready
    petPowerStateList[petPstID].previouslyReady = previouslyReady
    petPowerStateList[petPstID].requireNTPowerReady = requireNTPowerReady
    -- MSG46289->MSG46451
    petPowerStateList[petPstID].maxValue = (self._maxValue ~= 0) and self._maxValue

    petPowerStateList[petPstID].extraSkillID = self._checkExtraSkillID

    Log.debug("BuffLogicChangePetLegendPower pet entity=", petEntity:GetID(), " power=", newPower, " ready=", ready)
    return true
end
function BuffLogicChangePetLegendPower:_CalcModifyValue(curLegendPower)
    local addValue = self._addValue
    if self._addPercent then
        local oriModifyVal = curLegendPower * self._addPercent
        local absModifyVal = math.abs(oriModifyVal)
        absModifyVal = math.floor(absModifyVal)
        if self._addPercentMinAbsValue then
            if absModifyVal < self._addPercentMinAbsValue then
                absModifyVal = self._addPercentMinAbsValue
            end
        end
        if oriModifyVal < 0 then
            addValue = -1 * absModifyVal
        else
            addValue = absModifyVal
        end
    end
    return addValue
end

-- function BuffLogicChangePetLegendPower:_CalcMinCostByExtraParam(defaultCost,skillConfigData)
--     local petEntity = self._buffInstance:Entity()
--     ---@type UtilDataServiceShare
--     local utilData = self._world:GetService("UtilData")
--     local cost = utilData:CalcMinCostLegendPowerByExtraParam(petEntity,defaultCost,skillConfigData,0,false)
--     return cost
-- end