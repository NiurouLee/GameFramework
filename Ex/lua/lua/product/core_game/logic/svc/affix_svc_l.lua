--[[------------------------------------------------------------------------------------------
    AffixService 词条逻辑类
]] --------------------------------------------------------------------------------------------
require("base_service")

_class("AffixService", BaseService)
---@class AffixService:BaseService
AffixService = AffixService

function AffixService:Constructor(world)
    self._replaceMonsterIDList = {}
    self._world = world
    self._parseAffixParam = {}
    self._parseAffixParam[AffixType.TeamLeadOnlyInElementAttack] = IAffixParam
    self._parseAffixParam[AffixType.ChangePetAttr] = AffixChangePetAttrParam
    self._parseAffixParam[AffixType.CloseAuroraTime] = IAffixParam
    self._parseAffixParam[AffixType.ChangePetChainCount] = AffixChangePetChainCountParam
    self._parseAffixParam[AffixType.ChangeMonsterAttr] = AffixChangeMonsterAttrParam
    self._parseAffixParam[AffixType.ReplaceMonsterAI] = AffixReplaceMonsterAIParam
    self._parseAffixParam[AffixType.ReplaceMonsterSkill] = AffixReplaceMonsterSkillIDParam
    self._parseAffixParam[AffixType.ChangeTrapAttr] = AffixChangeTrapAttrParam
    self._parseAffixParam[AffixType.PlayerBeHitLimit] = AffixPlayerBeHitCountParam
    self._parseAffixParam[AffixType.ReplaceLevelComplete] = AffixReplaceLevelCompleteTypeParam
    self._parseAffixParam[AffixType.AddAffixBuff] = AffixAddBuffParam
    self._parseAffixParam[AffixType.ChangeWaveBeginMonsterID] = AffixChangeWaveIDParamBase
    self._parseAffixParam[AffixType.ChangeWaveBeginTrapID] = AffixChangeWaveIDParamBase
    self._parseAffixParam[AffixType.AddWaveBeginMonsterIDAndPos] = AffixAddWaveIDParamBase
    self._parseAffixParam[AffixType.AddWaveBeginTrapIDAndPos] = AffixAddWaveTrapIDAndPosParamBase
    self._parseAffixParam[AffixType.ChangeWaveInternalMonsterID] = AffixChangeWaveInternalIDParamBase
    self._parseAffixParam[AffixType.ChangeWaveInternalTrapID] = AffixChangeWaveInternalIDParamBase
    self._parseAffixParam[AffixType.AddWaveInternalMonsterIDAndPos] = AffixAddWaveInternalIDParamBase
    self._parseAffixParam[AffixType.AddWaveInternalTrapIDAndPos] = AffixAddWaveInternalTrapIDAndPosParam
    self._parseAffixParam[AffixType.ChangeAllMonsterAttr] = AffixChangeAllMonsterAttrParam
    self._parseAffixParam[AffixType.ChangeLevelRound] = AffixChangeLevelRoundParam
    self._parseAffixParam[AffixType.ChangeWaveInternalParam] = AffixChangeWaveInternalParam
    self._parseAffixParam[AffixType.AddWaveInternalParam] = AffixAddWaveInternalParam
    self._parseAffixParam[AffixType.ReplaceMonsterBuff] = AffixReplaceMonsterBuffParam
    self._parseAffixParam[AffixType.ReplaceMonsterEliteBuff] = AffixReplaceMonsterEliteBuffParam
    self._parseAffixParam[AffixType.AddMonsterBuff] = AffixAddMonsterBuffParam
    self._parseAffixParam[AffixType.AddMonsterEliteBuff] = AffixAddMonsterEliteBuffParam
    self._parseAffixParam[AffixType.ReplaceTrapSkill] = AffixReplaceTrapSkillParam
    self._parseAffixParam[AffixType.AddTrapBuff] = AffixAddTrapBuffParam
    self._parseAffixParam[AffixType.ReplaceTrapBuff] = AffixReplaceTrapBuffParam
    self._parseAffixParam[AffixType.ReplaceMonsterSpSkill] = AffixReplaceMonsterSpSkillParam
    self._parseAffixParam[AffixType.ChangePieceRefreshType] = AffixChangePieceRefreshTypeParam
    self._parseAffixParam[AffixType.ReplaceFeatureModule] = AffixReplaceFeatureModule
    self._parseAffixParam[AffixType.NoAuroraTimeLimit] = IAffixParam
    self._parseAffixParam[AffixType.ReplacePieceGenWeight] = AffixReplacePieceGenWeightParam
    self._parseAffixParam[AffixType.IncreasePetNoDefenceDamage] = AffixIncreasePetNoDefenceDamageParam
    self._parseAffixParam[AffixType.ChangePetAddBuffMaxRound] = AffixChangePetAddBuffMaxRoundParam
    self._parseAffixParam[AffixType.AddChainPathNum] = AffixAddChainPathNumParam
end

----@return AffixDataComponent
function AffixService:GetAffixDataCmpt()
    ----@type AffixDataComponent
    local affixDataCmpt = self._world:GetBoardEntity():AffixData()
    return affixDataCmpt
end

---@return boolean
function AffixService:HasAffixData(affixType)
    ---@type AffixDataComponent
    local affixDataCmpt = self:GetAffixDataCmpt()
    return affixDataCmpt:HasAffixData(affixType)
end

---@return IAffixParam
function AffixService:GetAffixData(affixType)
    ---@type AffixDataComponent
    local affixDataCmpt = self:GetAffixDataCmpt()
    return affixDataCmpt:GetAffixDataList(affixType)
end

function AffixService:ParseAffixData(affixList)
    ----@type AffixDataComponent
    local affixDataCmpt = self:GetAffixDataCmpt()
    if table.count(affixList) < 1 then
        return
    end
    for i, affixID in ipairs(affixList) do
        local affixParamList = Cfg.cfg_affix[affixID]
        if not affixParamList or not affixParamList.EntryParam or table.count(affixParamList.EntryParam) < 1 then
            Log.exception("ParseAffixData cant find affixID :", affixID)
            return
        end
        for i = 2, #(affixParamList.EntryParam) do
            local affixData = affixParamList.EntryParam[i]
            local paramClassType = self._parseAffixParam[affixData.affixType]
            if paramClassType == nil then
                Log.exception("ParseAffixData cant find affixType :", affixData.affixType)
                return
            end
            local affixParam = paramClassType:New(affixData, affixParamList.Type, i)
            affixParam:Init(self._world)
            affixDataCmpt:AddAffixData(affixData.affixType, affixParam)
        end
    end
    affixDataCmpt:Sort()
end

---@param attrNum number
---@param type ChangePetAttrType
---@return number
function AffixService:_ChangePetAttr(attrNum, type)
    if self:HasAffixData(AffixType.ChangePetAttr) then
        ---@type AffixChangePetAttrParam[]
        local affixChangePetAttrParamList = self:GetAffixData(AffixType.ChangePetAttr)
        for _, param in ipairs(affixChangePetAttrParamList) do
            if param:GetType() == type then
                return param:CalcAttr(attrNum)
            end
        end
    end
    return attrNum
end

---@param hp number
---@param defence number
---@return number,number,number
function AffixService:ChangePetAttr(hp, sourceDefence)
    local maxHP = self:_ChangePetAttr(hp, ChangePetAttrType.AllPetMaxHPPercent)
    local curHP = self:_ChangePetAttr(maxHP, ChangePetAttrType.AllPetCurHPPercent)
    local defence = self:_ChangePetAttr(sourceDefence, ChangePetAttrType.AllPetDefence)
    return curHP, maxHP, defence
end

function AffixService:IsCloseAuroraTime()
    return self:HasAffixData(AffixType.CloseAuroraTime)
end
function AffixService:IsNoAuroraTimeLimit()
    return self:HasAffixData(AffixType.NoAuroraTimeLimit)
end

---@param configData SkillConfigData
function AffixService:ChangePetChainCount(configData)
    if self:HasAffixData(AffixType.ChangePetChainCount) then
        ---@type AffixChangePetChainCountParam[]
        local affixChangePetChainCountParam = self:GetAffixData(AffixType.ChangePetChainCount)
        for _, param in ipairs(affixChangePetChainCountParam) do
            configData._triggerParam = param:CalcChainCount(configData._triggerParam)
        end
        return configData
    end
    return configData
end

function AffixService:ChangePetSkillChainCount(skillInfoList)
    if self:HasAffixData(AffixType.ChangePetChainCount) then
        ---@type AffixChangePetChainCountParam[]
        local affixChangePetChainCountParam = self:GetAffixData(AffixType.ChangePetChainCount)
        for _, skillInfo in ipairs(skillInfoList) do
            for _, param in ipairs(affixChangePetChainCountParam) do
                skillInfo.Chain = param:CalcChainCount(skillInfo.Chain)
            end
        end
    end
    return skillInfoList
end

---@return boolean
---@param teamEntity Entity
---@param chainPathElementType PieceType
function AffixService:IsTeamLeaderCanAttack(teamEntity, chainPathElementType)
    if self:HasAffixData(AffixType.TeamLeadOnlyInElementAttack) then
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        ---@type Entity
        local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
        ---@type ElementComponent
        local elementCmpt = teamLeaderEntity:Element()
        ----主属性或者副属性匹配就可以
        return CanMatchPieceType(chainPathElementType, elementCmpt:GetPrimaryType()) or
            (elementCmpt:HasSecondaryType() and CanMatchPieceType(chainPathElementType, elementCmpt:GetSecondaryType()))
    end
    return true
end

---@return boolean
---@param teamEntity Entity
---@param chainPathElementType PieceType
function AffixService:IsTeamLeaderUseSecondaryType(teamEntity, chainPathElementType)
    if self:HasAffixData(AffixType.TeamLeadOnlyInElementAttack) then
        ---@type BattleService
        local battleService = self._world:GetService("Battle")
        ---@type Entity
        local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
        ---@type ElementComponent
        local elementCmpt = teamLeaderEntity:Element()
        if CanMatchPieceType(chainPathElementType, elementCmpt:GetPrimaryType()) then
            return false
        end
        if elementCmpt:HasSecondaryType() and CanMatchPieceType(chainPathElementType, elementCmpt:GetSecondaryType()) then
            return true
        end
    end
    return false
end

---@param param AffixChangeMonsterAttrParam
---@param attrType AffixAttrType
function AffixService:GetMonsterAttrNum(param, attrNum, attrType)
    if attrType == AffixAttrType.HP and param:GetMonsterHP() then
        return param:GetMonsterHP()
    end
    if attrType == AffixAttrType.Attack and param:GetMonsterAttack() then
        return param:GetMonsterAttack()
    end
    if attrType == AffixAttrType.Defence and param:GetMonsterDefence() then
        return param:GetMonsterDefence()
    end
    return attrNum
end

---@param attrType AffixAttrType
function AffixService:ChangeMonsterAttr(monsterID, attrNum, attrType)
    if self:HasAffixData(AffixType.ChangeMonsterAttr) then
        ---@type AffixChangeMonsterAttrParam[]
        local affixChangeMonsterAttrParamList = self:GetAffixData(AffixType.ChangeMonsterAttr)
        for _, param in ipairs(affixChangeMonsterAttrParamList) do
            if param:GetMonsterID() == monsterID then
                return self:GetMonsterAttrNum(param, attrNum, attrType)
            end
        end
    end
    return attrNum
end

function AffixService:ChangeMonsterAI(monsterID, aiType, aiIDAndOrderList)
    if self:HasAffixData(AffixType.ReplaceMonsterAI) then
        ---@type AffixReplaceMonsterAIParam[]
        local affixReplaceMonsterAIParamList = self:GetAffixData(AffixType.ReplaceMonsterAI)
        for _, param in ipairs(affixReplaceMonsterAIParamList) do
            if param:GetMonsterID() == monsterID and param:GetAIType() == aiType then
                local temp = table.cloneconf(aiIDAndOrderList)
                for i, aiAndOrder in ipairs(temp) do
                    aiAndOrder[1] = param:ReplaceAI(aiAndOrder[1])
                end
                return temp
            end
        end
    end
    return aiIDAndOrderList
end

function AffixService:ChangeMonsterSkillID(monsterID, skillIDs)
    if self:HasAffixData(AffixType.ReplaceMonsterSkill) then
        ---@type AffixReplaceMonsterAIParam[]
        local affixReplaceMonsterAIParamList = self:GetAffixData(AffixType.ReplaceMonsterSkill)
        local temp = table.cloneconf(skillIDs)
        local bReplace = false
        for _, param in ipairs(affixReplaceMonsterAIParamList) do
            if param:GetMonsterID() == monsterID then
                bReplace = true
                for i, v in ipairs(temp) do
                    for k, skillID in ipairs(v) do
                        temp[i][k] = param:ReplaceSkillID(skillID)
                    end
                end
            end
        end
        return temp
    end
    return skillIDs
end

---@param param AffixChangeTrapAttrParam
---@param attrType string
function AffixService:GetTrapAttrNum(param, attrNum, attrType)
    if attrType == "HP" and param:GetTrapHP() then
        return param:GetTrapHP()
    end
    if attrType == "MaxHP" and param:GetTrapMaxHP() then
        return param:GetTrapMaxHP()
    end
    if attrType == "Attack" and param:GetTrapAttack() then
        return param:GetTrapAttack()
    end
    if attrType == "Defense" and param:GetTrapDefence() then
        return param:GetTrapDefence()
    end
    if attrType == "TrapPower" and param:GetTrapPower() then
        return param:GetTrapPower()
    end
    return attrNum
end

---@param attrType string
function AffixService:ChangeTrapAttr(trapID, attrNum, attrType)
    if self:HasAffixData(AffixType.ChangeTrapAttr) then
        ---@type AffixChangeTrapAttrParam[]
        local affixChangeTrapAttrParamList = self:GetAffixData(AffixType.ChangeTrapAttr)
        for _, param in ipairs(affixChangeTrapAttrParamList) do
            if param:GetTrapID() == trapID then
                return self:GetTrapAttrNum(param, attrNum, attrType)
            end
        end
    end
    return attrNum
end

---@param param AffixReplaceTrapSkillParam
---@param skillType string
function AffixService:GetTrapSkillValue(param, value, skillType)
    if skillType == "Trigger" and param:GetTriggerSkillID() then
        return param:GetTriggerSkillID()
    end
    if skillType == "Appear" and param:GetAppearSkillID() then
        return param:GetAppearSkillID()
    end
    if skillType == "Die" and param:GetDieSkillID() then
        return param:GetDieSkillID()
    end
    if skillType == "Active" and param:GetActiveSkillID() then
        return param:GetActiveSkillID()
    end
    return value
end

---@param skillType string
function AffixService:ChangeTrapSkill(trapID, value, skillType)
    if self:HasAffixData(AffixType.ReplaceTrapSkill) then
        ---@type AffixReplaceTrapSkillParam[]
        local affixChangeTrapAttrParamList = self:GetAffixData(AffixType.ReplaceTrapSkill)
        for _, param in ipairs(affixChangeTrapAttrParamList) do
            if param:GetTrapID() == trapID then
                return self:GetTrapSkillValue(param, value, skillType)
            end
        end
    end
    return value
end

function AffixService:ChangeLevelComplete()
end

---是否满足单局被击次数  满足等同死亡
function AffixService:IsEnoughPlayerBeHitCount()
    if self:HasAffixData(AffixType.PlayerBeHitLimit) then
        ---@type AffixPlayerBeHitCountParam[]
        local affixPlayerBeHitCountParamList = self:GetAffixData(AffixType.PlayerBeHitLimit)
        local param = affixPlayerBeHitCountParamList[1]
        local playerBeHitCount = self._world:BattleStat():GetPlayerBeHitCount()
        if param:GetPlayerBeHitCount() <= playerBeHitCount then
            return true
        end
    end
    return false
end

function AffixService:GetAffixLevelCompleteType(completeType)
    if self:HasAffixData(AffixType.ReplaceLevelComplete) then
        ---@type AffixReplaceLevelCompleteTypeParam[]
        local affixReplaceLevelCompleteTypeParamList = self:GetAffixData(AffixType.ReplaceLevelComplete)
        local param = affixReplaceLevelCompleteTypeParamList[1]
        return param:GetType()
    end
    return completeType
end

function AffixService:GetAffixLastWaveCompleteType(completeType)
    if self:HasAffixData(AffixType.ReplaceLevelComplete) then
        ---@type AffixReplaceLevelCompleteTypeParam[]
        local affixReplaceLevelCompleteTypeParamList = self:GetAffixData(AffixType.ReplaceLevelComplete)
        ---@type AffixReplaceLevelCompleteTypeParam
        local param = affixReplaceLevelCompleteTypeParamList[1]
        if param:IsUseInLastWave() then
            return param:GetType()
        else
            return completeType
        end
    end
    return completeType
end

function AffixService:GetAffixLastWaveCompleteParam(completeParam)
    if self:HasAffixData(AffixType.ReplaceLevelComplete) then
        ---@type AffixReplaceLevelCompleteTypeParam[]
        local affixReplaceLevelCompleteTypeParamList = self:GetAffixData(AffixType.ReplaceLevelComplete)
        ---@type AffixReplaceLevelCompleteTypeParam
        local param = affixReplaceLevelCompleteTypeParamList[1]
        if param:IsUseInLastWave() then
            return param:GetParam()
        else
            return completeParam
        end
    end
    return completeParam
end

function AffixService:GetAffixLevelCompleteParam(completeParam)
    if self:HasAffixData(AffixType.ReplaceLevelComplete) then
        ---@type AffixReplaceLevelCompleteTypeParam[]
        local affixReplaceLevelCompleteTypeParamList = self:GetAffixData(AffixType.ReplaceLevelComplete)
        local param = affixReplaceLevelCompleteTypeParamList[1]
        return param:GetParam()
    end
    return completeParam
end

function AffixService:InitAffixBuff(GameStartBuffs)
    if self:HasAffixData(AffixType.AddAffixBuff) then
        ---@type AffixAddBuffParam[]
        local affixAddBuffParamList = self:GetAffixData(AffixType.AddAffixBuff)
        for _, param in ipairs(affixAddBuffParamList) do
            local affixBuffList = param:GetAffixBuffIDList()
            for _, id in ipairs(affixBuffList) do
                ---@type BuffLogicService
                local buffLogic = self._world:GetService("BuffLogic")
                local cfg = Cfg.cfg_affix_buff[id]
                if cfg == nil then
                    Log.fatal("affix_buff not found: ", id)
                    return
                end
                for _, buffID in ipairs(cfg.BuffID) do
                    -- Log.notice("[Word!!!] 初始化词缀，", wordID, "挂buff: ", id)
                    local ret = buffLogic:AddBuffByTargetType(buffID, cfg.BuffTargetType, cfg.BuffTargetParam)
                    ---@param inst BuffInstance
                    for _, inst in ipairs(ret) do
                        GameStartBuffs[#GameStartBuffs + 1] = { inst:Entity(), inst:BuffSeq() }
                    end
                end
            end
        end
    end
end

---@param monsterWaveParam LevelMonsterWaveParam
function AffixService:ChangeWaveMonsterRefreshParam(monsterWaveParam, waveCount)
    if self:HasAffixData(AffixType.AddWaveBeginMonsterIDAndPos) then
        local monsterRefreshParam = monsterWaveParam:GetWaveBeginRefreshParam()
        -----@type number[]
        local waveMonsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        self:AddWaveMonsterIDAndPos(
            monsterRefreshParam,
            waveCount,
            AffixType.AddWaveBeginMonsterIDAndPos,
            waveMonsterIDList
        )
    end

    if self:HasAffixData(AffixType.AddWaveBeginTrapIDAndPos) then
        local monsterRefreshParam = monsterWaveParam:GetWaveBeginRefreshParam()
        self:AddWaveTrapIDAndPos(monsterRefreshParam, waveCount, AffixType.AddWaveBeginTrapIDAndPos)
    end

    if self:HasAffixData(AffixType.AddWaveInternalMonsterIDAndPos) then
        ---@type MonsterRefreshData[]
        local monsterRefreshDataList = monsterWaveParam:GetWaveInternalRefreshData()
        for _, refreshData in ipairs(monsterRefreshDataList) do
            self:AddWaveInternalMonsterIDAndPos(
                refreshData,
                monsterWaveParam,
                waveCount,
                AffixType.AddWaveInternalMonsterIDAndPos
            )
        end
    end

    if self:HasAffixData(AffixType.AddWaveInternalTrapIDAndPos) then
        ---@type MonsterRefreshData[]
        local monsterRefreshDataList = monsterWaveParam:GetWaveInternalRefreshData()
        for _, refreshData in ipairs(monsterRefreshDataList) do
            self:AddWaveInternalTrapIDAndPos(
                refreshData,
                monsterWaveParam,
                waveCount,
                AffixType.AddWaveInternalTrapIDAndPos
            )
        end
    end

    if self:HasAffixData(AffixType.ChangeWaveBeginMonsterID) then
        local monsterRefreshParam = monsterWaveParam:GetWaveBeginRefreshParam()
        ---@type number[]
        local waveMonsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        self:_ChangeWaveMonsterID(monsterRefreshParam, waveCount, AffixType.ChangeWaveBeginMonsterID, waveMonsterIDList)
    end

    if self:HasAffixData(AffixType.ChangeWaveBeginTrapID) then
        local monsterRefreshParam = monsterWaveParam:GetWaveBeginRefreshParam()
        self:_ChangeWaveTrapID(monsterRefreshParam, waveCount, AffixType.ChangeWaveBeginTrapID)
    end

    if self:HasAffixData(AffixType.ChangeWaveInternalMonsterID) then
        ---@type MonsterRefreshData[]
        local monsterRefreshDataList = monsterWaveParam:GetWaveInternalRefreshData()
        -----@type number[]
        local waveMonsterIDList = monsterWaveParam:GetWaveMonsterIDArray()
        for _, refreshData in ipairs(monsterRefreshDataList) do
            self:ChangeWaveInternalMonsterID(
                refreshData,
                waveCount,
                AffixType.ChangeWaveInternalMonsterID,
                waveMonsterIDList
            )
        end
    end

    if self:HasAffixData(AffixType.ChangeWaveInternalTrapID) then
        ---@type MonsterRefreshData[]
        local monsterRefreshDataList = monsterWaveParam:GetWaveInternalRefreshData()
        for _, refreshData in ipairs(monsterRefreshDataList) do
            self:_ChangeWaveIntervalTrapID(refreshData, monsterWaveParam, waveCount, AffixType.ChangeWaveInternalTrapID)
        end
    end

    return monsterWaveParam
end

---@param monsterWaveParam LevelMonsterWaveParam
---@param monsterRefreshData MonsterRefreshData
---@param type AffixType
function AffixService:AddWaveInternalTrapIDAndPos(monsterRefreshData, monsterWaveParam, waveNum, type)
    ----@type AffixAddWaveInternalIDParamBase[]
    local paramList = self:GetAffixData(type)
    ----@type  TrapTransformParam[]
    local trapList = monsterRefreshData:GetInternalTrapIDDic()
    for _, param in ipairs(paramList) do
        if param:GetRefreshID() == monsterRefreshData:GetInternalRefreshID() and param:GetWaveNum() == waveNum then
            ---@type TrapTransformParam
            local trapTransformParam = TrapTransformParam:New(param:GetID())
            trapTransformParam:SetPositionList({ param:GetPos() })
            trapTransformParam:SetRotationList({ param:GetRotation() })
            table.insert(trapList, trapTransformParam)
        end
    end
end

---@param monsterWaveParam LevelMonsterWaveParam
---@param monsterRefreshData MonsterRefreshData
---@param type AffixType
function AffixService:AddWaveInternalMonsterIDAndPos(monsterRefreshData, monsterWaveParam, waveNum, type)
    ----@type AffixAddWaveInternalIDParamBase[]
    local paramList = self:GetAffixData(type)
    local waveMonsterIDArray = monsterWaveParam:GetWaveMonsterIDArray()
    ----@type LevelMonsterRefreshParam
    local monsterRefreshParam = monsterRefreshData:GetMonsterRefreshParam()
    local monsterInternalIDArray = monsterRefreshData:GetInternalMonsterIDDic()
    ---@type number[]
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    ---@type Vector2[]
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    ---@type Vector2[]
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local posType = monsterRefreshParam:GetMonsterRefreshPosType()
    local monsterPosAndOffSetArray = monsterRefreshParam:GetMonsterPosAndOffSetArray()
    for _, param in ipairs(paramList) do
        if param:GetRefreshID() == monsterRefreshData:GetInternalRefreshID() and param:GetWaveNum() == waveNum then
            table.insert(monsterIDArray, param:GetID())
            table.insert(monsterPosArray, param:GetPos())
            table.insert(waveMonsterIDArray, param:GetID())
            table.insert(monsterInternalIDArray, param:GetID())
            if posType == MonsterRefreshPosType.PositionAndOffSet or
                posType == MonsterRefreshPosType.PositionAndOffSetMultiBoard
            then
                monsterPosAndOffSetArray[#monsterPosAndOffSetArray + 1] = { MonsterPosType.Position, param:GetPos() }
            end
        end
    end
end

---@param monsterRefreshData MonsterRefreshData
---@param type AffixType
---@param waveMonsterIDArray number
function AffixService:ChangeWaveInternalMonsterID(monsterRefreshData, waveNum, type, waveMonsterIDArray)
    ----@type AffixChangeWaveInternalIDParamBase[]
    local paramList = self:GetAffixData(type)
    for _, param in ipairs(paramList) do
        if param:GetRefreshID() == monsterRefreshData:GetInternalRefreshID() and param:GetWaveNum() == waveNum then
            local refreshMonsterIDArray = monsterRefreshData:GetInternalMonsterIDDic()
            local monsterRefreshParam = monsterRefreshData:GetMonsterRefreshParam()
            local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()

            for i, monsterID in ipairs(monsterIDArray) do
                if monsterID == param:GetSourceID() then
                    monsterIDArray[i] = param:GetTargetID()
                    self._replaceMonsterIDList[monsterID] = { waveNum = waveNum, targetID = param:GetTargetID() }
                end
            end
            for i, monsterID in ipairs(waveMonsterIDArray) do
                if monsterID == param:GetSourceID() then
                    waveMonsterIDArray[i] = param:GetTargetID()
                end
            end
            for i, monsterID in ipairs(refreshMonsterIDArray) do
                if monsterID == param:GetSourceID() then
                    refreshMonsterIDArray[i] = param:GetTargetID()
                end
            end
        end
    end
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@param type AffixType
---@param waveMonsterIDArray number
function AffixService:_ChangeWaveMonsterID(monsterRefreshParam, waveNum, type, waveMonsterIDArray)
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    ---@type AffixChangeWaveIDParamBase[]
    local paramList = self:GetAffixData(type)
    for _, param in ipairs(paramList) do
        if param:GetWaveNum() == waveNum then
            for i, monsterID in ipairs(monsterIDArray) do
                if monsterID == param:GetSourceID() then
                    monsterIDArray[i] = param:GetTargetID()
                    self._replaceMonsterIDList[monsterID] = { waveNum = waveNum, targetID = param:GetTargetID() }
                end
            end
            --if type == AffixType.ChangeWaveBeginMonsterID then
            for i, monsterID in ipairs(waveMonsterIDArray) do
                if monsterID == param:GetSourceID() then
                    waveMonsterIDArray[i] = param:GetTargetID()
                end
            end
            --end
        end
    end

    return monsterRefreshParam
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@param type AffixType
function AffixService:AddWaveTrapIDAndPos(monsterRefreshParam, waveCount, type)
    ---@type TrapTransformParam[]
    local trapArray = monsterRefreshParam:GetTrapArray()
    ---@type AffixAddWaveTrapIDAndPosParamBase[]
    local paramList = self:GetAffixData(type)
    for _, param in ipairs(paramList) do
        ---@type TrapTransformParam
        local trapTransformParam = TrapTransformParam:New(param:GetID())
        trapTransformParam:SetPositionList({ param:GetPos() })
        trapTransformParam:SetRotationList({ param:GetRotation() })
        trapArray[#trapArray + 1] = trapTransformParam
    end
end

---@param monsterRefreshParam LevelMonsterRefreshParam
---@param type AffixType
function AffixService:AddWaveMonsterIDAndPos(monsterRefreshParam, waveCount, type, waveMonsterIDList)
    ---@type number[]
    local monsterIDArray = monsterRefreshParam:GetMonsterIDArray()
    ---@type Vector2[]
    local monsterPosArray = monsterRefreshParam:GetMonsterPosArray()
    ---@type Vector2[]
    local monsterRotationArray = monsterRefreshParam:GetMonsterRotationArray()
    local posType = monsterRefreshParam:GetMonsterRefreshPosType()
    local monsterPosAndOffSetArray = monsterRefreshParam:GetMonsterPosAndOffSetArray()
    ---@type AffixAddWaveIDParamBase[]
    local paramList = self:GetAffixData(AffixType.AddWaveBeginMonsterIDAndPos)
    for _, param in ipairs(paramList) do
        if param:GetWaveNum() == waveCount then
            table.insert(monsterIDArray, param:GetID())
            table.insert(monsterPosArray, param:GetPos())
            table.insert(waveMonsterIDList, param:GetID())
            if posType == MonsterRefreshPosType.PositionAndOffSet or
                posType == MonsterRefreshPosType.PositionAndOffSetMultiBoard
            then
                monsterPosAndOffSetArray[#monsterPosAndOffSetArray + 1] = { MonsterPosType.Position, param:GetPos() }
            end
        end
    end
end

function AffixService:_ChangeWaveIntervalTrapID(monsterRefreshData, monsterWaveParam, waveNum, type)
    ----@type AffixChangeWaveInternalIDParamBase[]
    local paramList = self:GetAffixData(type)
    ----@type  TrapTransformParam[]
    local trapList = monsterRefreshData:GetInternalTrapIDDic()
    for _, param in ipairs(paramList) do
        if param:GetRefreshID() == monsterRefreshData:GetInternalRefreshID() and param:GetWaveNum() == waveNum then
            for i, trap in ipairs(trapList) do
                if trap._trapID == param:GetSourceID() then
                    trap._trapID = param:GetTargetID()
                end
            end
        end
    end
end

function AffixService:_ChangeWaveTrapID(monsterRefreshParam, waveCount, type)
    ---@type TrapTransformParam[]
    local trapArray = monsterRefreshParam:GetTrapArray()
    local paramList = self:GetAffixData(AffixType.ChangeWaveBeginTrapID)
    for _, param in ipairs(paramList) do
        for i, trap in ipairs(trapArray) do
            if trap:GetTrapID() == param:GetSourceID() then
                trap._trapID = param:GetTargetID()
                break
            end
        end
    end
end

function AffixService:_GetChangeAllMonsterAttrParam()
    if self:HasAffixData(AffixType.ChangeAllMonsterAttr) then
        ---@type AffixChangeAllMonsterAttrParam[]
        local affixChangeAllMonsterAttrParamList = self:GetAffixData(AffixType.ChangeAllMonsterAttr)
        local affixChangeAllMonsterAttrParam = affixChangeAllMonsterAttrParamList[1]
        local z = affixChangeAllMonsterAttrParam:GetParamZ()
        local y = affixChangeAllMonsterAttrParam:GetParamY()
        return y, z
    end
    return 0, 1
end

function AffixService:ChangeLevelRound(round)
    if self:HasAffixData(AffixType.ChangeLevelRound) then
        ---@type AffixChangeLevelRoundParam[]
        local affixChangeLevelRoundParamList = self:GetAffixData(AffixType.ChangeLevelRound)
        local affixChangeLevelRoundParam = affixChangeLevelRoundParamList[1]
        round = round + affixChangeLevelRoundParam:GetChange()
        if round <= 0 then
            round = 1
        end
    end
    return round
end

function AffixService:ChangeWaveInternalParam(param, refreshIndex, waveNum)
    if self:HasAffixData(AffixType.ChangeWaveInternalParam) then
        ---@type AffixChangeWaveInternalParam[]
        local affixChangeWaveInternalParamList = self:GetAffixData(AffixType.ChangeWaveInternalParam)
        for _, affixChangeWaveInternalParam in ipairs(affixChangeWaveInternalParamList) do
            if refreshIndex == affixChangeWaveInternalParam:GetRefreshIndex() and
                waveNum == affixChangeWaveInternalParam:GetWaveNum()
            then
                return affixChangeWaveInternalParam:GetParam()
            end
        end
    end
    return param
end

function AffixService:AddWaveInternalParam(waveNum)
    local retParamList = {}
    if self:HasAffixData(AffixType.AddWaveInternalParam) then
        ---@type AffixAddWaveInternalParam[]
        local affixAddWaveInternalParamList = self:GetAffixData(AffixType.AddWaveInternalParam)

        for _, affixChangeWaveInternalParam in ipairs(affixAddWaveInternalParamList) do
            if waveNum == affixChangeWaveInternalParam:GetWaveNum() then
                table.insert(retParamList, affixChangeWaveInternalParam)
            end
        end
    end
    return retParamList
end

function AffixService:ChangeMonsterID(idList, waveNum)
    local tmpIDList = {}
    if idList then
        for i, id in ipairs(idList) do
            tmpIDList[i] = id
            if self._replaceMonsterIDList[id] and self._replaceMonsterIDList[id].waveNum == waveNum then
                tmpIDList[i] = self._replaceMonsterIDList[id].targetID
            end
        end
    end
    return tmpIDList
end

function AffixService:ReplaceMonsterBuff(monsterID, buffList)
    if self:HasAffixData(AffixType.ReplaceMonsterBuff) then
        ---@type AffixReplaceMonsterBuffParam[]
        local affixReplaceMonsterBuffParamList = self:GetAffixData(AffixType.ReplaceMonsterBuff)
        for _, param in ipairs(affixReplaceMonsterBuffParamList) do
            if param:GetMonsterID() == monsterID then
                return param:GetBuffList()
            end
        end
    end
    return buffList
end

function AffixService:ReplaceMonsterEliteBuff(monsterID, buffList)
    if self:HasAffixData(AffixType.ReplaceMonsterEliteBuff) then
        ---@type AffixReplaceMonsterEliteBuffParam[]
        local affixReplaceMonsterEliteBuffParamList = self:GetAffixData(AffixType.ReplaceMonsterEliteBuff)
        for _, param in ipairs(affixReplaceMonsterEliteBuffParamList) do
            if param:GetMonsterID() == monsterID then
                return param:GetEliteBuffList()
            end
        end
    end
    return buffList
end

function AffixService:AddMonsterBuff(monsterID, buffList)
    if self:HasAffixData(AffixType.AddMonsterBuff) then
        ---@type AffixAddMonsterBuffParam[]
        local affixAddMonsterBuffParamList = self:GetAffixData(AffixType.AddMonsterBuff)
        local retBuffList = {}
        if buffList then
            for i, v in ipairs(buffList) do
                retBuffList[i] = v
            end
        end
        for _, param in ipairs(affixAddMonsterBuffParamList) do
            if param:GetMonsterID() == monsterID then
                table.appendArray(retBuffList, param:GetBuffList())
            end
        end
        if #retBuffList > 0 then
            return retBuffList
        end
    end
    return buffList
end

function AffixService:AddMonsterEliteBuff(monsterID, buffList)
    if self:HasAffixData(AffixType.AddMonsterEliteBuff) then
        local retBuffList = {}
        if buffList then
            for i, v in ipairs(buffList) do
                retBuffList[i] = v
            end
        end
        ---@type AffixAddMonsterEliteBuffParam[]
        local affixAddMonsterEliteBuffParamList = self:GetAffixData(AffixType.AddMonsterEliteBuff)
        for _, param in ipairs(affixAddMonsterEliteBuffParamList) do
            if param:GetMonsterID() == monsterID then
                table.appendArray(retBuffList, param:GetEliteBuffList())
            end
        end
        if #retBuffList > 0 then
            return retBuffList
        end
    end
    return buffList
end

function AffixService:AddTrapBuff(trapID, buffList)
    if self:HasAffixData(AffixType.AddTrapBuff) then
        local retBuffList = {}
        if buffList then
            for i, v in ipairs(buffList) do
                retBuffList[i] = v
            end
        end
        ---@type AffixAddTrapBuffParam[]
        local affixAddTrapBuffParamList = self:GetAffixData(AffixType.AddTrapBuff)
        for _, param in ipairs(affixAddTrapBuffParamList) do
            if param:GetTrapID() == trapID then
                table.appendArray(retBuffList, param:GetBuffList())
            end
        end
        if #retBuffList > 0 then
            return retBuffList
        end
    end
    return buffList
end

function AffixService:ReplaceTrapBuff(trapID, buffList)
    if self:HasAffixData(AffixType.ReplaceTrapBuff) then
        ---@type AffixReplaceTrapBuffParam[]
        local affixReplaceTrapBuffParamList = self:GetAffixData(AffixType.ReplaceTrapBuff)
        for _, param in ipairs(affixReplaceTrapBuffParamList) do
            if param:GetTrapID() == trapID then
                return param:GetBuffList()
            end
        end
    end
    return buffList
end

function AffixService:ReplaceMonsterSpSkill(monsterID, skillID, skillType)
    if self:HasAffixData(AffixType.ReplaceMonsterSpSkill) then
        ---@type AffixReplaceMonsterSpSkillParam[]
        local affixReplaceMonsterSpSkillParamList = self:GetAffixData(AffixType.ReplaceMonsterSpSkill)
        for _, param in ipairs(affixReplaceMonsterSpSkillParamList) do
            if param:GetMonsterID() == monsterID and param:GetSkillType() == skillType then
                return param:GetSkillID()
            end
        end
    end
    return skillID
end

---@return PieceRefreshType, Vector2, AffixChangePieceRefreshTypeParam
function AffixService:ReplacePieceRefreshType()
    if self:HasAffixData(AffixType.ChangePieceRefreshType) then
        ---@type AffixChangePieceRefreshTypeParam[]
        local affixChangePieceRefreshTypeParamList = self:GetAffixData(AffixType.ChangePieceRefreshType)
        local param = affixChangePieceRefreshTypeParamList[1]
        return param:GetPieceRefreshType(), param:GetFallingDirection(), param
    end
    return PieceRefreshType.Inplace
end

function AffixService:ReplaceReplaceFeatureModule(FeatureList)
    if self:HasAffixData(AffixType.ReplaceFeatureModule) then
        ---@type AffixReplaceFeatureModule[]
        local affixReplaceFeatureModuleList = self:GetAffixData(AffixType.ReplaceFeatureModule)
        for _, param in ipairs(affixReplaceFeatureModuleList) do
            return param:GetConfigTable()
        end
    end
    return FeatureList
end
function AffixService:ProcessGeneratePieceWeight(curWeight)
    if self:HasAffixData(AffixType.ReplacePieceGenWeight) then
        ---@type AffixReplacePieceGenWeightParam[]
        local affixReplacePieceGenWeightParamList = self:GetAffixData(AffixType.ReplacePieceGenWeight)
        local param = affixReplacePieceGenWeightParamList[1]
        if param then
            local replaceWeight = param:GetGeneratePieceWeight()
            if replaceWeight then
                return table.cloneconf(replaceWeight)
            end
        end
    end
    return curWeight
end
function AffixService:ProcessSupplyPieceWeight(curWeight)
    if self:HasAffixData(AffixType.ReplacePieceGenWeight) then
        ---@type AffixReplacePieceGenWeightParam[]
        local affixReplacePieceGenWeightParamList = self:GetAffixData(AffixType.ReplacePieceGenWeight)
        local param = affixReplacePieceGenWeightParamList[1]
        if param then
            local replaceWeight = param:GetSupplyPieceWeight()
            if replaceWeight then
                return table.cloneconf(replaceWeight)
            end
        end
    end
    return curWeight
end

function AffixService:HasIncreasePetNoDefenceDamage()
    return self:HasAffixData(AffixType.IncreasePetNoDefenceDamage)
end

function AffixService:GetIncreasePetNoDefenceDamageParam()
    if self:HasAffixData(AffixType.IncreasePetNoDefenceDamage) then
        ---@type AffixIncreasePetNoDefenceDamageParam[]
        local affixIncreasePetNoDefenceDamageParamList = self:GetAffixData(AffixType.IncreasePetNoDefenceDamage)
        local param = affixIncreasePetNoDefenceDamageParamList[1]
        if param then
            local increasePercent = param:GetIncreasePercent()
            if increasePercent then
                return increasePercent
            end
        end
    end
    return 0
end

function AffixService:HasChangePetAddBuffMaxRound()
    return self:HasAffixData(AffixType.ChangePetAddBuffMaxRound)
end

function AffixService:GetChangePetAddBuffMaxRoundParam(buffEffectFlags)
    if not buffEffectFlags then
        return
    end
    if #buffEffectFlags == 0 then
        return
    end
    if self:HasAffixData(AffixType.ChangePetAddBuffMaxRound) then
        ---@type AffixChangePetAddBuffMaxRoundParam[]
        local affixChangePetAddBuffMaxRoundParamList = self:GetAffixData(AffixType.ChangePetAddBuffMaxRound)
        if affixChangePetAddBuffMaxRoundParamList then
            for _, param in ipairs(affixChangePetAddBuffMaxRoundParamList) do
                local effectFlagNum = param:GetEffectFlagNum()
                if table.icontains(buffEffectFlags,effectFlagNum) then
                    return param:GetChangeRound()
                end
            end
        end
    end
    return
end

function AffixService:HasAddChainPathNum()
    return self:HasAffixData(AffixType.AddChainPathNum)
end
function AffixService:ProcessAddChainPathNum(oriChain)
    if oriChain < 1 then
        return oriChain
    end
    if self:HasAffixData(AffixType.AddChainPathNum) then
        ---@type AffixAddChainPathNumParam[]
        local affixAddChainPathNumParamList = self:GetAffixData(AffixType.AddChainPathNum)
        local param = affixAddChainPathNumParamList[1]
        if param then
            local addNum = param:GetAddChainPathNum()
            if addNum then
                local newChain = oriChain + addNum
                return newChain
            end
        end
    end
    return oriChain
end
function AffixService:GetAddChainPathNum()
    if self:HasAffixData(AffixType.AddChainPathNum) then
        ---@type AffixAddChainPathNumParam[]
        local affixAddChainPathNumParamList = self:GetAffixData(AffixType.AddChainPathNum)
        local param = affixAddChainPathNumParamList[1]
        if param then
            local addNum = param:GetAddChainPathNum()
            if addNum then
                return addNum
            end
        end
    end
end