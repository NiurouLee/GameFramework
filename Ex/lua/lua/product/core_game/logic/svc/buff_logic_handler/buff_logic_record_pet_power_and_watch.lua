--[[
    记录星灵主动技能CD
]]
--------------------------------
_class("BuffLogicRecordPetPowerAndWatch", BuffLogicBase)
---@class BuffLogicRecordPetPowerAndWatch:BuffLogicBase
BuffLogicRecordPetPowerAndWatch = BuffLogicRecordPetPowerAndWatch

function BuffLogicRecordPetPowerAndWatch:Constructor(buffInstance, logicParam)
    self._record = logicParam.record --记录
    self._apply = logicParam.apply --应用
end

function BuffLogicRecordPetPowerAndWatch:DoLogic()
    local petPowerStateList = {}
    ---@type MainWorld
    local world = self._buffInstance:World()

    --减少自己
    local petEntity = self._buffInstance:Entity()
    if not petEntity then
        return
    end

    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()

    ---@type AttributesComponent
    local curAttributeCmpt = petEntity:Attributes()

    ---@type BuffComponent
    local buffComponent = self._entity:BuffComponent()
    local recordKey = "BuffLogicRecordPetPowerAndWatch"

    local activeSkillID = petEntity:SkillInfo():GetActiveSkillID()

    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")
    local curReady = utilDataSvc:GetPetSkillReadyAttr(petEntity, activeSkillID)
    local curPower = curAttributeCmpt:GetAttribute("Power")

    if self._record == 1 then
        --记录值 不需要表现

        local grayWatch = false

        ---@type BattleStatComponent
        local battleStatComponent = world:BattleStat()
        local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
        local curRound = battleStatComponent:GetLevelTotalRoundCount()

        ---
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
            --放过技能是灰表状态
            grayWatch = true

            local keyStr =
                "HadSaveSkillGrayWatch" .. "_Round_" .. tostring(curRound) .. "_Skill_" .. tostring(activeSkillID)
            local hadSaveSkillGrayWatch = buffComponent:GetBuffValue(keyStr)
            --保存过灰表状态 当前就不是灰表
            if hadSaveSkillGrayWatch then
                grayWatch = false
            end
        end

        local recordPetPowerAndWatchData = {power = curPower, grayWatch = grayWatch, ready = curReady}
        buffComponent:SetBuffValue(recordKey, recordPetPowerAndWatchData)

        return
    elseif self._apply == 1 then
        --应用记录值 需要表现

        local recordPetPowerAndWatchData = buffComponent:GetBuffValue(recordKey)
        if not recordPetPowerAndWatchData then
            return
        end

        local recordPower = recordPetPowerAndWatchData.power
        local recordGrayWatch = recordPetPowerAndWatchData.grayWatch
        local recordReady = (recordPetPowerAndWatchData.ready == 1)

        curAttributeCmpt:Modify("Power", recordPower)
        ---@type BuffLogicService
        local blsvc = world:GetService("BuffLogic")
        blsvc:ChangePetActiveSkillReady(petEntity, recordReady)

        local notifyView = false
        if curReady == 0 and recordReady == true then
            local notify = NTPowerReady:New(petEntity)
            world:GetService("Trigger"):Notify(notify)
            notifyView = true
        end

        --使用记录后 清除该值
        buffComponent:SetBuffValue(recordKey, nil)

        --记录的时候不是灰表则清掉
        if recordGrayWatch == false then
            --上回合使用技能的记录
            ---@type BattleStatComponent
            local battleStatComponent = world:BattleStat()
            battleStatComponent:SetLastDoActiveSkillRound(petPstID, nil)
        end

        local buffResult =
            BuffResultRecordPetPowerAndWatch:New(
            petEntity:GetID(),
            petPstID,
            recordPower,
            recordReady,
            recordGrayWatch,
            notifyView
        )
        return buffResult
    end
end
