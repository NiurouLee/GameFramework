--[[
    改变星灵主动技能CD
]]
--------------------------------
_class("BuffLogicChangePetPowerAndWatch", BuffLogicBase)
---@class BuffLogicChangePetPowerAndWatch:BuffLogicBase
BuffLogicChangePetPowerAndWatch = BuffLogicChangePetPowerAndWatch

function BuffLogicChangePetPowerAndWatch:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
end

function BuffLogicChangePetPowerAndWatch:DoLogic()
    local petPowerStateList = {}
    ---@type MainWorld
    local world = self._buffInstance:World()

    --减少自己
    local petEntity = self._buffInstance:Entity()
    if not petEntity then
        return
    end

    self:_OnChangePetPower(petEntity, petPowerStateList)

    --成功了才通知
    if next(petPowerStateList) then
        local buffResult = BuffResultChangePetPowerAndWatch:New(petPowerStateList)
        return buffResult
    end
end

function BuffLogicChangePetPowerAndWatch:_OnChangePetPower(petEntity, petPowerStateList)
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()

    ---@type AttributesComponent
    local curAttributeCmpt = petEntity:Attributes()
    local curPower = curAttributeCmpt:GetAttribute("Power")
    if curPower <= 0 then
        return false
    end

    local newPower = curPower - self._addValue

    local ready = false
    local requireNTPowerReady = false

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")

    ---@type BattleStatComponent
    local battleStatComponent = self._world:BattleStat()
    local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
    local curRound = battleStatComponent:GetLevelTotalRoundCount()

    ---
    local activeSkillID = petEntity:SkillInfo():GetActiveSkillID()
    ---光灵释放主动技的记录  [petPstID]={[回合1]={技能ID1，技能ID2},[回合2]={技能ID1}}
    local curRoundHadCastSkillList = battleStatComponent:GetPetDoActiveSkillRecord(petPstID, curRound)
    --当前回合放过该主动技
    local curRoundHadCastTargetSkill = false
    if curRoundHadCastSkillList and table.count(curRoundHadCastSkillList) > 0 then
        if table.icontains(curRoundHadCastSkillList, activeSkillID) then
            curRoundHadCastTargetSkill = true
        end
    end

    --当前回合放过该主动技
    if curRoundHadCastTargetSkill then
        ---@type BuffComponent
        local buffComponent = self._entity:BuffComponent()
        local keyStr = "HadSaveSkillGrayWatch" .. "_Round_" .. tostring(curRound) .. "_Skill_" .. tostring(activeSkillID)
        local hadSaveSkillGrayWatch = buffComponent:GetBuffValue(keyStr)
        --没有保存过灰表状态
        if hadSaveSkillGrayWatch == nil then
            newPower = curPower - (self._addValue - 1)
            buffComponent:SetBuffValue(keyStr, true)
            battleStatComponent:SetLastDoActiveSkillRound(petPstID, nil)
        end
    end
    ---

    if newPower <= 0 then
        newPower = 0
        blsvc:ChangePetActiveSkillReady(petEntity, 1)
        ready = true

        local notify = NTPowerReady:New(petEntity)
        self._world:GetService("Trigger"):Notify(notify)
        requireNTPowerReady = true
    end

    self._world:GetSyncLogger():Trace(
        {key = "BuffLogicChangePetPowerAndWatch", petEntityID = petEntity:GetID(), newPower = newPower}
    )

    if not petPowerStateList[petPstID] then
        petPowerStateList[petPstID] = {}
    end
    petPowerStateList[petPstID].petEntityID = petEntity:GetID()
    petPowerStateList[petPstID].petPstID = petPstID
    petPowerStateList[petPstID].power = newPower
    petPowerStateList[petPstID].ready = ready
    petPowerStateList[petPstID].requireNTPowerReady = requireNTPowerReady
    self:PrintBuffLogicLog("ChangePetPower() pet entity=", petEntity:GetID(), " power=", newPower)
    curAttributeCmpt:Modify("Power", newPower)

    return true
end
