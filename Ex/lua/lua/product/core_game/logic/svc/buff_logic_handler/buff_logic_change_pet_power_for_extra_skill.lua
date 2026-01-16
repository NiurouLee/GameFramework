--[[
    改变星灵附加主动技能CD
]]
--------------------------------
_class("BuffLogicChangePetPowerForExtraSkill", BuffLogicBase)
---@class BuffLogicChangePetPowerForExtraSkill:BuffLogicBase
BuffLogicChangePetPowerForExtraSkill = BuffLogicChangePetPowerForExtraSkill

function BuffLogicChangePetPowerForExtraSkill:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
    self._logicType = logicParam.logicType or EnumChangePetPower.Self
    self._logicParameter = logicParam.logicParameter
    self._complete = logicParam.complete or false
    self._skipFull = logicParam.skipFull ---是否跳过已经满了的 2020-07-30只有EnumChangePetPower.Self在用
    self._jobs =
        logicParam.jobs or
        {PetProfType.PetProf_Attack, PetProfType.PetProf_Blood, PetProfType.PetProf_Color, PetProfType.PetProf_Function}
    self._notifyView = logicParam.notifyView or 1 --是否立刻变化，默认1立刻，如果是怪物攻击的配置0
    self._addCdAnimation = logicParam.addCdAnimation or 1 --增加CD的时候 是否显示红光动画，默认1显示
    self._setValue = logicParam.setValue or 0 --新的值，不使用当前加上新增。而是直接设置这个值
    self._force = logicParam.force or 0 --是否强制修改，本回合用过主动技也修改CD。默认0不修改 1:修改 2：修改且处理当回合放过技能的情况
    self._delayToRoundEnter = logicParam.delayToRoundEnter--是否延迟到下回合开始生效
    self._readyNoRemind = logicParam.readyNoRemind--ready 是否播音效、提示动画
    self._extraSkillIndex = logicParam.extraSkillIndex or 1--附加技序号，从1开始
end

function BuffLogicChangePetPowerForExtraSkill:DoLogic()
    local petPowerStateList = {}
    ---@type MainWorld
    local world = self._buffInstance:World()
    local teamEntity = world:Player():GetLocalTeamEntity()
    if self._entity:HasTeam() then
        teamEntity = self._entity
    elseif self._entity:HasPet() then
        teamEntity = self._entity:Pet():GetOwnerTeamEntity()
    end
    local petEntities = teamEntity:Team():GetTeamPetEntities()
    if self._logicType == EnumChangePetPower.Self then
        --减少自己
        local petEntity = self._buffInstance:Entity()
        if not petEntity then
            return
        end

        self:_OnChangePetPower(petEntity, petPowerStateList)
    end

    --成功了才通知
    if next(petPowerStateList) then
        local buffResult = BuffResultChangePetPowerForExtraSkill:New(petPowerStateList, self._notifyView)
        return buffResult
    end
end

function BuffLogicChangePetPowerForExtraSkill:_OnChangePetPower(petEntity, petPowerStateList)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local skillIndex = self._extraSkillIndex + 1
    ---@type SkillInfoComponent
    local skillInfoCmpt = petEntity:SkillInfo()
    local activeSkillID = skillInfoCmpt:GetSkillIDByIndex(skillIndex)
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    if not activeSkillID or (activeSkillID == 0) then
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        local extraSkillList = petData:GetPetExtraActiveSkill()
        if extraSkillList then
            activeSkillID = extraSkillList[self._extraSkillIndex]
        end
    end
    if not activeSkillID or (activeSkillID == 0) then
        return
    end
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    --传说光灵不处理cd
    if (skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy) or (skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer) then
        return
    end

    local curPower = utilData:GetPetPowerAttr(petEntity,activeSkillID)
    local curReady = utilData:GetPetSkillReadyAttr(petEntity,activeSkillID)
    if self._skipFull and curPower <= 0 and curReady == 1 then
        return false
    end

    local newPower = curPower - self._addValue
    if self._setValue ~= 0 then
        --不使用当前加上新增。而是直接设置这个值
        newPower = self._setValue
    end

    local ready = false
    local cancelReady = false

    ---@type BuffLogicService
    local blsvc = self._world:GetService("BuffLogic")

    local requireNTPowerReady = false
    if self._complete then
        if not self:_CanCurRoundChangePower(curPower,newPower,petEntity) then
            return false
        end
        newPower = 0
        blsvc:ChangePetActiveSkillReady(petEntity, 1,activeSkillID)
        ready = true

        local notify = NTPowerReady:New(petEntity)
        self._world:GetService("Trigger"):Notify(notify)
        requireNTPowerReady = true
    else
        ---@type BattleStatComponent
        local battleStatComponent = self._world:BattleStat()
        local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID,self._extraSkillIndex)
        local curRound = battleStatComponent:GetLevelTotalRoundCount()

        -- 本回合放过主动技的星灵，除非特殊设计(self._complete == true)，否则不恢复CD
        -- 减少CD的走这个判断   增加CD的不走这个判断
        if (lastDoActiveSkillRound == curRound) and newPower < curPower and self._force == 0 then
            return false
        end
        if not self:_CanCurRoundChangePower(curPower,newPower,petEntity) then
            return false
        end
        if (lastDoActiveSkillRound == curRound) and (self._force == 2) then
            ---@type BuffComponent
            local buffComponent = petEntity:BuffComponent()
            --技能表的状态 默认是灰色
            local keyStr = "SkillWatchIsGray"..tostring(self._extraSkillIndex)
            local skillWatchIsGray = buffComponent:GetBuffValue(keyStr) or true
            if self._setValue == 0 then--用addvalue 的时候 打破表算一次cd削减
                local curAddValue = self._addValue
                if skillWatchIsGray then
                    curAddValue = curAddValue - 1
                end
                newPower = curPower - curAddValue
            end

            if skillWatchIsGray then
                buffComponent:SetBuffValue(keyStr, false)
                battleStatComponent:SetLastDoActiveSkillRound(petPstID, nil,self._extraSkillIndex)
            end
        end
        if newPower <= 0 then
            blsvc:ChangePetActiveSkillReady(petEntity, 1,activeSkillID)
            ready = true

            local notify = NTPowerReady:New(petEntity)
            self._world:GetService("Trigger"):Notify(notify)
            requireNTPowerReady = true
        end
        local readyAttr = utilData:GetPetSkillReadyAttr(petEntity,activeSkillID)
        if readyAttr == 1 and newPower > 0 then
            blsvc:ChangePetActiveSkillReady(petEntity, 0,activeSkillID)
            cancelReady = true
        end
    end

    if newPower < 0 then
        newPower = 0
    end
    self._world:GetSyncLogger():Trace(
            {key = "BuffLogicChangePetPowerForExtraSkill", petEntityID = petEntity:GetID(), newPower = newPower}
    )
    if not petPowerStateList[petPstID] then
        petPowerStateList[petPstID] = {}
    end
    petPowerStateList[petPstID].petEntityID = petEntity:GetID()
    petPowerStateList[petPstID].petPstID = petPstID
    petPowerStateList[petPstID].power = newPower
    petPowerStateList[petPstID].ready = ready
    petPowerStateList[petPstID].cancelReady = cancelReady --取消准备(在准备状态中被添加CD)
    petPowerStateList[petPstID].addCdAnimation = self._addCdAnimation
    petPowerStateList[petPstID].requireNTPowerReady = requireNTPowerReady
    petPowerStateList[petPstID].readyNoRemind = self._readyNoRemind
    petPowerStateList[petPstID].skillID = activeSkillID
    self:PrintBuffLogicLog("ChangePetPowerForExtraSkill() pet entity=", petEntity:GetID(), " skillID=", activeSkillID," power=", newPower,"notifyView=",self._notifyView)
    utilData:SetPetPowerAttr(petEntity,newPower,activeSkillID)

    return true
end
---能否本回合修改能量
function BuffLogicChangePetPowerForExtraSkill:_CanCurRoundChangePower(curPower,newPower,petEntity)
    --if self._notifyView==0 then
    if self._delayToRoundEnter then
        local changePower = newPower-curPower
        local curChangePower = petEntity:BuffComponent():GetBuffValue("DelayChangePowerValue")
        if not curChangePower then
            petEntity:BuffComponent():SetBuffValue("DelayChangePowerValue",0)
            curChangePower = 0
        end
        petEntity:BuffComponent():SetBuffValue("DelayChangePowerValue",curChangePower+changePower)
        return false
    end
    return true
end
