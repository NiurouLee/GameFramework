--[[------------------------------------------------------------------------------------------
    MonsterIDComponent : 每个怪物身上的ID
]] --------------------------------------------------------------------------------------------

_class("MonsterIDComponent", Object)
---@class MonsterIDComponent: Object
MonsterIDComponent = MonsterIDComponent

function MonsterIDComponent:Constructor(monsterID, raceType, nMonsterType, nGroupID, classID,campType)
    self._monsterID = monsterID
    self._raceType = raceType
    self._monsterType = nMonsterType
    self._campType = campType
    self._groupID = nGroupID
    self._classID = classID
    self._gridDownEnable = true
    self._outLineEnable = true

    ---世界Boss 阶段数据
    self._isWorldBoss = false
    self._initStageHPData = {}
    self._initStageBuffData = {}
    self._initStageAttrData = {}
    self._curStage = 1
    self._curBeHitDamage = 0
    self._curRoundChangeStageCount = 0

    --精英怪
    self._eliteIDArray = {}
    self._eliteIDArrayAttach = {} --被精英怪附身后增加的精英词缀ID列表
    self._eliteIDArrayOri = {} --怪物本身的精英词缀ID列表

    self._damageSyncMonsterID = nil
    self._snakeBodyEffectID = nil
end

function MonsterIDComponent:GetCampType()
    return self._campType
end

function MonsterIDComponent:SetSnakeBodyEffect(effectID)
    self._snakeBodyEffectID = effectID
end

function  MonsterIDComponent:GetSnakeBodyEffectID()
    return self._snakeBodyEffectID
end

function MonsterIDComponent:SetDamageSyncMonsterID(monsterID)
    self._monsterDamageSyncMonsterID =monsterID
end

function MonsterIDComponent:GetDamageSyncMonsterID()
    return self._monsterDamageSyncMonsterID
end

function MonsterIDComponent:GetMonsterID()
    return self._monsterID
end
function MonsterIDComponent:GetMonsterClassID()
    return self._classID
end
function MonsterIDComponent:GetMonsterType()
    return self._monsterType
end
function MonsterIDComponent:GetMonsterGroupID()
    return self._groupID
end

---@return MonsterRaceType
function MonsterIDComponent:GetMonsterRaceType()
    return self._raceType
end
function MonsterIDComponent:GetMonsterBlockData()
    if MonsterRaceType.Fly == self._raceType then
        return BlockFlag.MonsterFly
    end
    return BlockFlag.MonsterLand
end

function MonsterIDComponent:IsNeedGridDown()
    return self._gridDownEnable
end

function MonsterIDComponent:SetNeedGridDownEnable(enable)
    self._gridDownEnable = enable
end

function MonsterIDComponent:IsNeedOutLine()
    return self._outLineEnable
end

function MonsterIDComponent:SetNeedOutLineEnable(enable)
    self._outLineEnable = enable
end

function MonsterIDComponent:InitWorldBossStageData(stageData)
    for _, v in ipairs(stageData) do
        local stageIndex = v.stage
        self._initStageHPData[stageIndex] = v.hp
        self._initStageBuffData[stageIndex] = {}
        for _, buffID in ipairs(v.buffIDList) do
            table.insert(self._initStageBuffData[stageIndex], buffID)
        end
        self._initStageAttrData[stageIndex] = table.cloneconf(v.attr)
    end
    self._curStage = 1
end

function MonsterIDComponent:AddMonsterBeHitDamage(damage)
    self._curBeHitDamage = self._curBeHitDamage + damage
end

function MonsterIDComponent:WorldBossSwitchStage()
    local needAddBuffList = {}
    local newAttrData = nil
    if
        self._curBeHitDamage >= self._initStageHPData[self._curStage] and
            self._curStage < table.count(self._initStageHPData)
     then
        while self._curBeHitDamage >= self._initStageHPData[self._curStage] and
            self._curStage < table.count(self._initStageHPData) do
            self._curBeHitDamage = self._curBeHitDamage - self._initStageHPData[self._curStage]
            self._curStage = self._curStage + 1
            ---最后的阶段
            if self._curStage > table.count(self._initStageHPData) then
                self._curStage = table.count(self._initStageHPData)
            else
                self._curRoundChangeStageCount = self._curRoundChangeStageCount + 1
                local addBuffList = self._initStageBuffData[self._curStage]
                for _, buffID in ipairs(addBuffList) do
                    table.insert(needAddBuffList, buffID)
                end
                local attrData = self._initStageAttrData[self._curStage]
                newAttrData = attrData
            end
            --Log.fatal("LogicMonsterStage ",self._curStage)
        end
    end
    return needAddBuffList,newAttrData
end

function MonsterIDComponent:GetCurRoundChangeStageCount()
    return self._curRoundChangeStageCount
end

function MonsterIDComponent:ResetCurRoundChangeStageCount()
    self._curRoundChangeStageCount = 0
end

function MonsterIDComponent:SetWorldBossState(state)
    self._isWorldBoss = state
end

function MonsterIDComponent:IsWorldBoss()
    return self._isWorldBoss
end

function MonsterIDComponent:GetCurStage()
    return self._curStage
end

function MonsterIDComponent:SetEliteIDArray(t)
    self._eliteIDArray = t
    self._eliteIDArrayOri = table.cloneconf(t)
end

function MonsterIDComponent:GetEliteIDArray()
    return self._eliteIDArray
end

function MonsterIDComponent:IsEliteMonster()
    return #(self._eliteIDArray) > 0
end

---有可能随多个附身相同的一个，所以此处用append，不直接设置
function MonsterIDComponent:SetEliteIDArrayAttach(t)
    table.appendArray(self._eliteIDArrayAttach, t)
    table.appendArray(self._eliteIDArray, t)
end

function MonsterIDComponent:GetEliteIDArrayAttach()
    return self._eliteIDArrayAttach
end

function MonsterIDComponent:ClearEliteIDArrayAttach()
    if #self._eliteIDArrayAttach == 0 then
        return
    end
    -- for _, value in ipairs(self._eliteIDArrayAttach) do
    --     table.removev(self._eliteIDArray, value)
    -- end
    self._eliteIDArrayAttach = {}
    ---重设怪物初始精英词缀
    self._eliteIDArray = table.cloneconf(self._eliteIDArrayOri)
end
function MonsterIDComponent:GetWorldBossStageAttrData(stage)
    local attrData = self._initStageAttrData[stage]
    return attrData
end
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
---@return MonsterIDComponent
function Entity:MonsterID()
    return self:GetComponent(self.WEComponentsEnum.MonsterID)
end

function Entity:HasMonsterID()
    return self:HasComponent(self.WEComponentsEnum.MonsterID)
end

function Entity:AddMonsterID()
    local index = self.WEComponentsEnum.MonsterID
    local component = MonsterIDComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceMonsterID(monsterID, raceType, nMonsterType, nGroupID, monsterClassID,campType)
    local index = self.WEComponentsEnum.MonsterID
    local component = MonsterIDComponent:New(monsterID, raceType, nMonsterType, nGroupID, monsterClassID,campType)
    self:ReplaceComponent(index, component)
end

function Entity:RemoveMonsterID()
    if self:HasMonsterID() then
        self:RemoveComponent(self.WEComponentsEnum.MonsterID)
    end
end

function Entity:GetMonsterIDComponentEnum()
    local index = self.WEComponentsEnum.MonsterID
    return index
end
