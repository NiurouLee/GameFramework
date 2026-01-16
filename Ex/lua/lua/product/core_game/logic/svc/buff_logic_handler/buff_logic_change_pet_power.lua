--[[
    改变星灵主动技能CD
]]
--------------------------------
---@class EnumChangePetPower
EnumChangePetPower = {
    Random = 1, ---随机选一个，限定职业
    Self = 2, ---自己
    AllPet = 3, ---全部星灵: 也可以通过技能目标配置9（全体宝宝） + Self来实现，
    PrioritySmall = 4 --优先从CD值小的开始算
}
_enum("EnumChangePetPower", EnumChangePetPower)
--------------------------------
_class("BuffLogicChangePetPower", BuffLogicBase)
---@class BuffLogicChangePetPower:BuffLogicBase
BuffLogicChangePetPower = BuffLogicChangePetPower

function BuffLogicChangePetPower:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
    self._logicType = logicParam.logicType or EnumChangePetPower.AllPet
    self._logicParameter = logicParam.logicParameter
    self._complete = logicParam.complete or false
    self._skipFull = logicParam.skipFull ---是否跳过已经满了的 2020-07-30只有EnumChangePetPower.Self在用
    self._jobs =
        logicParam.jobs or
        {PetProfType.PetProf_Attack, PetProfType.PetProf_Blood, PetProfType.PetProf_Color, PetProfType.PetProf_Function}
    self._notifyView = logicParam.notifyView or 1 --是否立刻变化，默认1立刻，如果是怪物攻击的配置0
    self._addCdAnimation = logicParam.addCdAnimation or 1 --增加CD的时候 是否显示红光动画，默认1显示
    self._setValue = logicParam.setValue or 0 --新的值，不使用当前加上新增。而是直接设置这个值
    self._setByMaxPower = logicParam.setByMaxPower or 0 --直接用maxPower设置
    self._force = logicParam.force or 0 --是否强制修改，本回合用过主动技也修改CD。默认0不修改 1:修改 2：修改且处理当回合放过技能的情况
    self._delayToRoundEnter = logicParam.delayToRoundEnter--是否延迟到下回合开始生效
    self._readyNoRemind = logicParam.readyNoRemind--ready 是否播音效、提示动画
end

function BuffLogicChangePetPower:DoLogic()
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
    if self._logicType == EnumChangePetPower.Random then
        --减少随机一个星灵

        local cdNotEnougthPetList = {}

        for _, petEntity in ipairs(petEntities) do
            if not petEntity:HasPetDeadMark() then
                ---@type MatchPet
                local matchPet = petEntity:MatchPet():GetMatchPet()
                if table.icontains(self._jobs, matchPet:GetJob()) then
                    ---@type AttributesComponent
                    local attributeCmpt = petEntity:Attributes()
                    local power = attributeCmpt:GetAttribute("Power")
                    if power > 0 then
                        table.insert(cdNotEnougthPetList, petEntity)
                    end
                end
            end
        end

        if #cdNotEnougthPetList == 0 then
            return
        end
        ---@type RandomServiceLogic
        local randomSvc = self._world:GetService("RandomLogic")
        local randomIndex = randomSvc:LogicRand(1, #cdNotEnougthPetList)

        local curPet = cdNotEnougthPetList[randomIndex]

        self:_OnChangePetPower(curPet, petPowerStateList)
    elseif self._logicType == EnumChangePetPower.Self then
        --减少自己
        local petEntity = self._buffInstance:Entity()
        if not petEntity then
            return
        end

        self:_OnChangePetPower(petEntity, petPowerStateList)
    elseif self._logicType == EnumChangePetPower.AllPet then
        --减少全部星灵
        local petEntity = self._buffInstance:Entity()
        if not petEntity then
            return
        end

        local cdNotEnougthPetList = {}

        for _, petEntity in ipairs(petEntities) do
            ---@type AttributesComponent
            local attributeCmpt = petEntity:Attributes()
            local power = attributeCmpt:GetAttribute("Power")
            if power > 0 then
                self:_OnChangePetPower(petEntity, petPowerStateList)
            end
        end
    elseif self._logicType == EnumChangePetPower.PrioritySmall then
        --优先从CD值小的开始算
        local petEntityList = {}

        local cdNotEnougthPetList = {}
        for _, petEntity in ipairs(petEntities) do
            table.insert(petEntityList, petEntity)
        end
        table.sort(
            petEntityList,
            function(e1, e2)
                local power1 = e1:Attributes():GetAttribute("Power")
                local power2 = e2:Attributes():GetAttribute("Power")
                return power1 < power2
            end
        )
        local chengeTimes = math.min(table.count(petEntityList), self._logicParameter)
        for i = 1, chengeTimes do
            local petEntity = petEntityList[i]
            self:_OnChangePetPower(petEntity, petPowerStateList)
            petEntity:BuffComponent():SetBuffValue("AddPetPower", 1)
        end
    end

    --成功了才通知
    if next(petPowerStateList) then
        local buffResult = BuffResultChangePetPower:New(petPowerStateList, self._notifyView)
        return buffResult
    end
end

function BuffLogicChangePetPower:_OnChangePetPower(petEntity, petPowerStateList)
    local activeSkillID = petEntity:SkillInfo():GetActiveSkillID()
    local petPstIDComponent = petEntity:PetPstID()
    local petPstID = petPstIDComponent:GetPstID()
    if not activeSkillID then
        ---@type Pet
        local petData = self._world.BW_WorldInfo:GetPetData(petPstID)
        activeSkillID = petData:GetPetActiveSkill()
    end

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    --传说光灵不处理cd
    if (skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy) or (skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer) then
        return
    end

    ---@type AttributesComponent
    local curAttributeCmpt = petEntity:Attributes()
    local curPower = curAttributeCmpt:GetAttribute("Power")
    local curReady = curAttributeCmpt:GetAttribute("Ready")
    if self._skipFull and curPower <= 0 and curReady == 1 then
        return false
    end

    local newPower = curPower - self._addValue
    if self._setValue ~= 0 then
        --不使用当前加上新增。而是直接设置这个值
        newPower = self._setValue
    end
    if self._setByMaxPower ~= 0 then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local maxPower = utilData:GetPetMaxPowerAttr(petEntity,activeSkillID)
        newPower = maxPower
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
        blsvc:ChangePetActiveSkillReady(petEntity, 1)
        ready = true

        local notify = NTPowerReady:New(petEntity)
        self._world:GetService("Trigger"):Notify(notify)
        requireNTPowerReady = true
    else
        ---@type BattleStatComponent
        local battleStatComponent = self._world:BattleStat()
        local lastDoActiveSkillRound = battleStatComponent:GetLastDoActiveSkillRound(petPstID)
        local curRound = battleStatComponent:GetLevelTotalRoundCount()

        -- 本回合放过主动技的星灵，除非特殊设计(self._complete == true)，否则不恢复CD
        -- 减少CD的走这个判断   增加CD的不走这个判断
        if (lastDoActiveSkillRound == curRound) and newPower < curPower and self._force == 0 then
            return false
        end
        if not self:_CanCurRoundChangePower(curPower,newPower,petEntity) then
            return false
        end
        if self._force == 2 then
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
                local buffComponent = petEntity:BuffComponent()
                local keyStr = "HadSaveSkillGrayWatch" .. "_Round_" .. tostring(curRound) .. "_Skill_" .. tostring(activeSkillID)
                local hadSaveSkillGrayWatch = buffComponent:GetBuffValue(keyStr)
                --没有保存过灰表状态
                if hadSaveSkillGrayWatch == nil then
                    newPower = curPower - (self._addValue - 1)
                    buffComponent:SetBuffValue(keyStr, true)
                    battleStatComponent:SetLastDoActiveSkillRound(petPstID, nil)
                end
            end
        end
        if newPower <= 0 then
            blsvc:ChangePetActiveSkillReady(petEntity, 1)
            ready = true

            local notify = NTPowerReady:New(petEntity)
            self._world:GetService("Trigger"):Notify(notify)
            requireNTPowerReady = true
        end
        if curAttributeCmpt:GetAttribute("Ready") == 1 and newPower > 0 then
            blsvc:ChangePetActiveSkillReady(petEntity, 0)
            cancelReady = true
        end
    end

    if newPower < 0 then
        newPower = 0
    end
    self._world:GetSyncLogger():Trace(
            {key = "BuffLogicChangePetPower", petEntityID = petEntity:GetID(), newPower = newPower}
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
    self:PrintBuffLogicLog("ChangePetPower() pet entity=", petEntity:GetID(), " power=", newPower,"notifyView=",self._notifyView)
    curAttributeCmpt:Modify("Power", newPower)

    return true
end
---能否本回合修改能量
function BuffLogicChangePetPower:_CanCurRoundChangePower(curPower,newPower,petEntity)
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
