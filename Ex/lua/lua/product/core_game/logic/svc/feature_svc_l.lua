--[[------------------------------------------------------------------------------------------
    FeatureServiceLogic : 模块逻辑服务
]] --------------------------------------------------------------------------------------------
require("battle_ui_active_skill_cannot_cast_reason")

_class("FeatureServiceLogic", BaseService)
---@class FeatureServiceLogic: BaseService
FeatureServiceLogic = FeatureServiceLogic
---部分模式屏蔽
function FeatureServiceLogic:CanEnableFeature()
    if self._world:MatchType() == MatchType.MT_Chess then
        return false
    end
    return true
end

---进局时初始化本局的模块
function FeatureServiceLogic:DoInitFeatureList()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    local featureCfgDataDic = self:_FindFeatureListCfgDataDic()
    ---@type FeatureEffectParamBase[]
    local featureDataList = self._configService:ParseCustomFeatureList(featureCfgDataDic)
    local featureCount = #featureDataList
    Log.info("DoInitFeatureList,count:",featureCount)
    for index,featureParam in ipairs(featureDataList) do
        Log.info("DoInitFeatureList,featureType:",featureParam:GetFeatureType())
        logicFeatureCmpt:AddFeatureData(featureParam:GetFeatureType(),featureParam)
    end
    self:_HandleInitFeatureList()
end

---中途加入伙伴光灵，检查该光灵是否附带当前没有的模块
function FeatureServiceLogic:OnPartnerPetJoinCheckFeature(partnerPetEntity)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    local petFeatureCfgDataDic = self:_FindFeatureListCfgDataDicOnPet(partnerPetEntity)
    local featureCfgDataDic = {}
    for featureType, cfgData in pairs(petFeatureCfgDataDic) do
        if not self:HasFeatureType(featureType) then--只处理当前没有的模块
            featureCfgDataDic[featureType] = cfgData
        end
    end
    ---@type FeatureEffectParamBase[]
    local featureDataList = self._configService:ParseCustomFeatureList(featureCfgDataDic)
    local featureCount = #featureDataList
    Log.info("OnPartnerPetJoinCheckFeature,count:",featureCount)
    for index,featureParam in ipairs(featureDataList) do
        Log.info("OnPartnerPetJoinCheckFeature,featureType:",featureParam:GetFeatureType())
        logicFeatureCmpt:AddFeatureData(featureParam:GetFeatureType(),featureParam)
        self:_HandleInitFeature(featureParam:GetFeatureType(),featureParam)
    end
end
---buff（小秘境圣物）对局中添加模块
function FeatureServiceLogic:OnBuffAddFeature(cfgFeatureList)
    local findFeatureDic = {}
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if cfgFeatureList then
        local buffFeatures = cfgFeatureList.feature
        if buffFeatures then
            for featureType,featureData in pairs(buffFeatures) do--原始配置数据
                if not findFeatureDic[featureType] then 
                    findFeatureDic[featureType] = featureData
                end
            end
        end
    end
    local finalFeatureDic = {}
    for featureType,featureData in pairs(findFeatureDic) do
        finalFeatureDic[featureType] = featureData
    end
    --clone
    for k,v in pairs(finalFeatureDic) do
        finalFeatureDic[k] = table.cloneconf(v)
    end
    local buffFeatureCfgDataDic = finalFeatureDic
    local featureCfgDataDic = {}
    for featureType, cfgData in pairs(buffFeatureCfgDataDic) do
        if not self:HasFeatureType(featureType) then--只处理当前没有的模块
            featureCfgDataDic[featureType] = cfgData
        end
    end
    ---@type FeatureEffectParamBase[]
    local featureDataList = self._configService:ParseCustomFeatureList(featureCfgDataDic)
    local featureCount = #featureDataList
    Log.info("OnBuffAddFeature,count:",featureCount)
    for index,featureParam in ipairs(featureDataList) do
        Log.info("OnBuffAddFeature,featureType:",featureParam:GetFeatureType())
        logicFeatureCmpt:AddFeatureData(featureParam:GetFeatureType(),featureParam)
        self:_HandleInitFeature(featureParam:GetFeatureType(),featureParam)
    end
end
---根据关卡、光灵配置，取出本次对局的模块信息列表--原始配置数据 {[featureType]={}}
function FeatureServiceLogic:_FindFeatureListCfgDataDic()
    --模块配置优先级：天赋 > 光灵 > 关卡  光灵队伍顺序越靠前，优先级越高，队长最先

    local finalForceParamList = {}--梅 指定san模块用的系统id

    local finalFeatureDic = {}
    --先填上level的模块配置
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local levelFeatureList = levelConfigData:GetFeatureList()--原始配置数据
    if levelFeatureList then
        local levelFeatures = levelFeatureList.feature
        if levelFeatures then
            for featureType,featureData in pairs(levelFeatures) do--原始配置数据
                finalFeatureDic[featureType] = featureData
            end
        end
        if levelFeatureList.forceParam then
            local forceParamDic = {}
            for featureType,forceData in pairs(levelFeatureList.forceParam) do--替换最终配置数据中某些参数 (关卡目前没有需求，与光灵保持一致)
                forceParamDic[featureType] = forceData
            end
            table.insert(finalForceParamList,forceParamDic)
        end
    end
    --光灵配置覆盖
    local petsFeatureDic = {}
    local petsForceParamList = {}
    local petSkinsForceParamList = {}
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    ---@type table<number,number>  队伍的逻辑顺序 key是序号 value是PetPstID
    local teamOrder = teamCmpt:GetTeamOrder()
    for order,petPstID in ipairs(teamOrder) do
        local petEntity = teamCmpt:GetPetEntityByPetPstID(petPstID)
        ---@type MatchPet
        local matchPet = petEntity:MatchPet():GetMatchPet()
        local petFeatureList = matchPet:GetFeatureList()--原始配置数据
        if petFeatureList then
            local petFeatures = petFeatureList.feature
            if petFeatures then
                for featureType,featureData in pairs(petFeatures) do--原始配置数据
                    if not petsFeatureDic[featureType] then --前面的优先
                        petsFeatureDic[featureType] = featureData
                    end
                end
            end
            --修改最终模块数据中的参数 梅 指定san模块用的系统id
            if petFeatureList.forceParam then
                local forceParamDic = {}
                for featureType,forceData in pairs(petFeatureList.forceParam) do--替换最终配置数据中某些参数 梅 指定san模块用的系统id
                    forceParamDic[featureType] = forceData
                end
                table.insert(petsForceParamList,1,forceParamDic)
            end
            local skinId = matchPet:GetSkinId()
            local skinCfg = Cfg.cfg_pet_skin[skinId]
            if skinCfg then
                --时装修改部分配置--与forceParam 逻辑相同
                local customParamCfg = skinCfg.InnerCustomParam
                if customParamCfg and customParamCfg.featureCustomParam then
                    local featureCustomParamCfg = customParamCfg.featureCustomParam
                    local forceParamDic = {}
                    for featureType, forceData in pairs(featureCustomParamCfg) do
                        forceParamDic[featureType] = forceData
                    end
                    table.insert(petSkinsForceParamList,1,forceParamDic)
                end
            end
        end
        --精炼部分
        local equipRefineFeatureList = matchPet:GetEquipRefineFeatureList()
        if equipRefineFeatureList then
            local petFeatures = equipRefineFeatureList.feature
            if petFeatures then
                for featureType,featureData in pairs(petFeatures) do--原始配置数据
                    if not petsFeatureDic[featureType] then --前面的优先
                        petsFeatureDic[featureType] = featureData
                    end
                end
            end
            --修改最终模块数据中的参数 梅 指定san模块用的系统id
            if equipRefineFeatureList.forceParam then
                local forceParamDic = {}
                for featureType,forceData in pairs(equipRefineFeatureList.forceParam) do--替换最终配置数据中某些参数 梅 指定san模块用的系统id
                    forceParamDic[featureType] = forceData
                end
                table.insert(petsForceParamList,1,forceParamDic)
            end
        end
    end
    for featureType,featureData in pairs(petsFeatureDic) do --光灵配置覆盖关卡配置
        finalFeatureDic[featureType] = featureData
    end
    for _,petForceParamDic in ipairs(petsForceParamList) do --替换最终配置数据中某些参数 梅 指定san模块用的系统id 优先级暂同模块配置
        table.insert(finalForceParamList,petForceParamDic)
    end
    for _,petSkinForceParamDic in ipairs(petSkinsForceParamList) do --替换最终配置数据中某些参数 时装 改表现
        table.insert(finalForceParamList,petSkinForceParamDic)
    end
    --clone
    for k,v in pairs(finalFeatureDic) do
        finalFeatureDic[k] = table.cloneconf(v)
    end

    --替换部分参数
    for _,forceParamDic in ipairs(finalForceParamList) do
        for featureType,forceData in pairs(forceParamDic) do
            if finalFeatureDic[featureType] then
                for key,value in pairs(forceData) do
                    finalFeatureDic[featureType][key] = value
                end
            end
        end
    end

    --天赋树替换配置
    ---@type TalentService
    local talentSvc = self._world:GetService("Talent")
    talentSvc:ChangeFeature(finalFeatureDic)
    
    return finalFeatureDic
end
---伙伴系统 取指定光灵身上的模块信息列表--原始配置数据 {[featureType]={}}
---强制修改参数的不处理 例：梅
function FeatureServiceLogic:_FindFeatureListCfgDataDicOnPet(petEntity)
    local finalFeatureDic = {}
    --光灵配置覆盖
    local petsFeatureDic = {}
    ---@type MatchPet
    local matchPet = petEntity:MatchPet():GetMatchPet()
    local petFeatureList = matchPet:GetFeatureList()--原始配置数据
    if petFeatureList then
        local petFeatures = petFeatureList.feature
        if petFeatures then
            for featureType,featureData in pairs(petFeatures) do--原始配置数据
                if not petsFeatureDic[featureType] then --前面的优先
                    petsFeatureDic[featureType] = featureData
                end
            end
        end
    end
    for featureType,featureData in pairs(petsFeatureDic) do --光灵配置覆盖关卡配置
        finalFeatureDic[featureType] = featureData
    end
    --clone
    for k,v in pairs(finalFeatureDic) do
        finalFeatureDic[k] = table.cloneconf(v)
    end
    return finalFeatureDic
end
---
function FeatureServiceLogic:GetLogicCmpt()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = boardEntity:LogicFeature()
    return logicFeatureCmpt
end
---各模块初始化处理
function FeatureServiceLogic:_HandleInitFeatureList()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    local featureTypeList = logicFeatureCmpt:GetFeatureTypeList()
    for i,featureType in ipairs(featureTypeList) do
        local featureData = logicFeatureCmpt:GetFeatureData(featureType)
        if featureData then
            self:_HandleInitFeature(featureType,featureData)
        end
    end
end
---各模块初始化处理
function FeatureServiceLogic:_HandleInitFeature(featureType,featureData)
    if featureType == FeatureType.Sanity then--San值模块
        self:_HandleInitFeature_Sanity(featureType,featureData)
    elseif featureType == FeatureType.DayNight then--昼夜模块
        self:_HandleInitFeature_DayNight(featureType,featureData)
    elseif featureType == FeatureType.PersonaSkill then--P5模块
        self:_HandleInitFeature_PersonaSkill(featureType,featureData)
    elseif featureType == FeatureType.Card then--选牌模块
        self:_HandleInitFeature_Card(featureType,featureData)
    elseif featureType == FeatureType.MasterSkill
        or featureType == FeatureType.MasterSkillRecover
        or featureType == FeatureType.MasterSkillTeleport
     then--空裔技能模块
        self:_HandleInitFeature_MasterSkill(featureType,featureData)
    elseif featureType == FeatureType.Scan then
        self:_HandleInitFeature_Scan(featureData)
    elseif featureType == FeatureType.TrapCount then
        self:_HandleInitFeature_TrapCount(featureType,featureData)
    elseif featureType == FeatureType.PopStar then
        self:_HandleInitFeature_PopStar(featureType, featureData)
    end
end
---某种模块有没有生效
function FeatureServiceLogic:HasFeatureType(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local featureData = logicFeatureCmpt:GetFeatureData(featureType)
        if featureData then
            return true
        end
    end
    return false
end
---取模块信息（进局后的配置信息）
function FeatureServiceLogic:GetFeatureData(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local featureData = logicFeatureCmpt:GetFeatureData(featureType)
        return featureData
    end
end
---取当前生效的模块类型列表
function FeatureServiceLogic:GetFeatureTypeList()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local featureTypeList = logicFeatureCmpt:GetFeatureTypeList()
        return featureTypeList
    end
end

---roundEnter
function FeatureServiceLogic:DoFeatureOnRoundEnter(incRound)
    self:_CheckFeatureSanOnRoundEnter()
    self:_CheckFeatureDayNightOnRoundEnter()
    self:_CheckFeatureSkillOnRoundEnter(FeatureType.PersonaSkill,incRound)
    self:_CheckFeatureSkillOnRoundEnter(FeatureType.MasterSkill,incRound)
    self:_CheckFeatureSkillOnRoundEnter(FeatureType.MasterSkillRecover,incRound)
    self:_CheckFeatureSkillOnRoundEnter(FeatureType.MasterSkillTeleport,incRound)
end
--------------------------------San---------------------------------------
--region san(sanity system)
---San值系统初始化
function FeatureServiceLogic:_HandleInitFeature_Sanity(featureType,featureData)
    ---@type FeatureEffectParamSan
    local param = featureData
    --设置初始值
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type AttributesComponent
    local boardAttr = boardEntity:Attributes()
    if boardAttr then
        local enterValue = param:GetEnterSanValue()
        boardAttr:Modify("San",enterValue)
        Log.info("_HandleInitFeature_Sanity,enterValue:",enterValue)
        local sanityParam = param:GetSanityParam()
        local words = sanityParam.wordList
        local gameStartBuffs = {}
        self:_SanityInitWords(words,gameStartBuffs)
        
    end
end
---回合开始
function FeatureServiceLogic:_CheckFeatureSanOnRoundEnter()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not battleStatCmpt:IsFirstRound() then
        ---@type FeatureEffectParamSan
        local sanData = self:GetFeatureData(FeatureType.Sanity)
        if sanData then
            local delVal = sanData:GetRoundDelValue()
            if delVal then
                local curVal,oldVal,realModifyValue,debtVal,modifyTimes = self:DecreaseSanValue(delVal)
                self._world:GetService("Trigger"):Notify(NTSanValueChange:New(curVal, oldVal,debtVal,modifyTimes))
                ---@type L2RService
                local l2rSvc = self._world:GetService("L2R")
                l2rSvc:L2RSanRoundDecrease(curVal,oldVal,realModifyValue,debtVal,modifyTimes)
            end
        end
    else--第一回合 发San值变化通知
        ---@type FeatureEffectParamSan
        local sanData = self:GetFeatureData(FeatureType.Sanity)
        if sanData then
            local curSan = self:GetSanValue()
            local debtVal = 0
            local modifyTimes = 0
            self._world:GetService("Trigger"):Notify(NTSanValueChange:New(curSan, curSan,debtVal,modifyTimes))
            ---@type L2RService
            local l2rSvc = self._world:GetService("L2R")
            l2rSvc:L2RSanRoundDecrease(curSan,curSan,0,debtVal,modifyTimes)
        end
    end
end
---San值系统 挂buff
function FeatureServiceLogic:_SanityInitWords(words,gameStartBuffs)
    if words == nil or #words == 0 then
        return
    end
    ---@type BuffLogicService
    local buffLogic = self._world:GetService("BuffLogic")
    for _, wordID in ipairs(words) do
        local cfg = Cfg.cfg_word_buff[wordID]
        if cfg == nil then
            Log.fatal("word not found: ", wordID)
            return
        end
        for _, id in ipairs(cfg.BuffID) do
            Log.notice("[Sanity] 初始化词缀，", wordID, "挂buff: ", id)
            local ret = buffLogic:AddBuffByTargetType(id, cfg.BuffTargetType, cfg.BuffTargetParam)
            ---@param inst BuffInstance
            for _, inst in ipairs(ret) do
                gameStartBuffs[#gameStartBuffs + 1] = {inst:Entity(), inst:BuffSeq()}
            end
        end
    end
end
---San值相关
function FeatureServiceLogic:SetSanValue(sanValue)
    local finalSan = sanValue
    local maxSan = self:GetSanMaxValue()
    local minSan = self:GetSanMinValue()

    if finalSan > maxSan then
        finalSan = maxSan
    end
    if finalSan < minSan then
        finalSan = minSan
    end
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type AttributesComponent
    local boardAttr = boardEntity:Attributes()
    if boardAttr then
        boardAttr:Modify("San",finalSan)
        Log.info("SetSanValue,sanValue:",finalSan)
    end
end
---San值相关
---每次触发修改 累计次数 用于buff表现选择
function FeatureServiceLogic:_RecordModifySanTimes()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:RecordModifySanTimes()
    end
end
function FeatureServiceLogic:ModifySanValue(modifyValue)
    if modifyValue >= 0 then
        return self:IncreaseSanValue(modifyValue)
    else
        return self:DecreaseSanValue(-modifyValue)
    end
end
function FeatureServiceLogic:IncreaseSanValue(increaseValue)
    local oldSan = self:GetSanValue()
    local maxSan = self:GetSanMaxValue()
    local minSan = self:GetSanMinValue()
    local realModifyValue = increaseValue
    local finalSan = oldSan + increaseValue
    if finalSan > maxSan then
        finalSan = maxSan
    end
    if finalSan < minSan then
        finalSan = minSan
    end
    realModifyValue = finalSan - oldSan
    self:SetSanValue(finalSan)
    local debtVal = 0
    local modifyTimes = self:_RecordModifySanTimes()
    return finalSan,oldSan,realModifyValue,debtVal,modifyTimes
end
---San值相关
function FeatureServiceLogic:DecreaseSanValue(decreaseValue)
    local oldSan = self:GetSanValue()
    local minSan = self:GetSanMinValue()
    local realModifyValue = decreaseValue
    local finalSan = oldSan - decreaseValue
    local debtVal = 0
    if finalSan < minSan then
        debtVal = minSan - finalSan--扣除时 不足的san值
        finalSan = minSan
    end
    realModifyValue = finalSan - oldSan
    self:SetSanValue(finalSan)
    local modifyTimes = self:_RecordModifySanTimes()
    return finalSan,oldSan,realModifyValue,debtVal,modifyTimes
end
---San值相关
function FeatureServiceLogic:GetSanValue()
    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type AttributesComponent
    local boardAttr = boardEntity:Attributes()
    if boardAttr then
        local sanValue = boardAttr:GetAttribute("San")
        return sanValue
    end
end
---San值相关
function FeatureServiceLogic:GetSanMaxValue()
    ---@type FeatureEffectParamSan
    local featureData = self:GetFeatureData(FeatureType.Sanity)
    if featureData then
        local maxVal = featureData:GetMaxSanValue()
        return maxVal
    end
    return 100--默认
end
---San值相关
function FeatureServiceLogic:GetSanMinValue()
    ---@type FeatureEffectParamSan
    local featureData = self:GetFeatureData(FeatureType.Sanity)
    if featureData then
        local minVal = featureData:GetMinSanValue()
        return minVal
    end
    return 0--默认
end

---@class FeatureSanActiveSkillCanCastContext
---@field scopeGridCount number

---Calculate san cost if unit casts its active skill. The calculation does **not** consume san directly
---@param casterEntity Entity caster entity
---@param skillID number ID of an active skill which is **SkillTriggerType.San**
---@param context FeatureSanActiveSkillCanCastContext context with required arguments
---@return number, number, number, table<number, boolean> san cost if action commences, HP cost if action commences, HP converted san value, involvedTriggerParamTypes
function FeatureServiceLogic:CalcActiveSkillSanCost(casterEntity, skillID, context)
    local triggerParamTypeBool = {}
    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    local skillcfg = cfgsvc:GetSkillConfigData(skillID)
    local logicSanVal = self:GetSanValue()

    local requireVal = 0
    local requireHPVal = 0
    local hpConvertVal = 0

    ---@type table<SkillTriggerTypeExtraParam, any>
    local triggerExtraParam = skillcfg:GetSkillTriggerExtraParam()
    if not triggerExtraParam then
        return requireVal, requireHPVal
    end

    if triggerExtraParam[SkillTriggerTypeExtraParam.SanValue] then
        triggerParamTypeBool[SkillTriggerTypeExtraParam.SanValue] = true
        requireVal = triggerExtraParam[SkillTriggerTypeExtraParam.SanValue]
        -- SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan enables a unit use its HP as san if necessary
        if (requireVal > logicSanVal) and triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] then
            triggerParamTypeBool[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] = true
            local rate = triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] --每1点san对应百分比
            hpConvertVal = requireVal - logicSanVal
            requireHPVal = hpConvertVal / rate * 0.01
            requireVal = logicSanVal
        end
    end

    if triggerExtraParam[SkillTriggerTypeExtraParam.SanByScopeGridCounts] then
        triggerParamTypeBool[SkillTriggerTypeExtraParam.SanByScopeGridCounts] = true
        local valPerGrid = triggerExtraParam[SkillTriggerTypeExtraParam.SanByScopeGridCounts]
        local scopeGridCount = context.scopeGridCount or 0
        requireVal = scopeGridCount * valPerGrid
        -- SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan enables a unit use its HP as san if necessary
        if (requireVal > logicSanVal) and triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] then
            triggerParamTypeBool[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] = true
            local rate = triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] --每1点san对应百分比
            hpConvertVal = requireVal - logicSanVal
            requireHPVal = hpConvertVal / rate * 0.01
            requireVal = logicSanVal
        end
    end

    if triggerExtraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes] then
        triggerParamTypeBool[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes] = true
        local baseVal = triggerExtraParam[SkillTriggerTypeExtraParam.SanValue]
        local modVal = triggerExtraParam[SkillTriggerTypeExtraParam.SanChangeByRoundCastTimes]
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local pstid = 0
        if casterEntity and casterEntity:PetPstID() then
            pstid = casterEntity:PetPstID():GetPstID()
        end
        local curRoundCastTimes = 0
        if pstid > 0 then
            curRoundCastTimes = battleStatCmpt:GetCurRoundDoActiveSkillTimes(pstid)
        end
        requireVal = baseVal + (modVal * curRoundCastTimes)
        -- SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan enables a unit use its HP as san if necessary
        if (requireVal > logicSanVal) and triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] then
            triggerParamTypeBool[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] = true
            local rate = triggerExtraParam[SkillTriggerTypeExtraParam.DecreaseHPPercentAsSan] --每1点san对应百分比
            hpConvertVal = requireVal - logicSanVal
            requireHPVal = hpConvertVal / rate * 0.01
            requireVal = logicSanVal
        end
    end

    return requireVal, requireHPVal, hpConvertVal, triggerParamTypeBool
end

---Check if player can cast one active skill
---@param casterEntity Entity caster entity
---@param skillID number ID of an active skill which is **SkillTriggerType.San**
---@param context FeatureSanActiveSkillCanCastContext context with required arguments
---@return boolean, BattleUIActiveSkillCannotCastReason|nil
function FeatureServiceLogic:IsActiveSkillCanCast(casterEntity, skillID, context)
    local logicSanVal = self:GetSanValue()
    if not logicSanVal then
        return false
    end

    local requireVal, requireHPPercent, _hpConvertVal, isTriggerParamUsed = self:CalcActiveSkillSanCost(casterEntity, skillID, context)
    local result = logicSanVal >= requireVal
    if (not result) then
        local firstFailedReason = SkillTriggerTypeExtraParam.SanValue
        if (not isTriggerParamUsed[SkillTriggerTypeExtraParam.SanValue]) and (isTriggerParamUsed[SkillTriggerTypeExtraParam.SanByScopeGridCounts]) then
            firstFailedReason = BattleUIActiveSkillCannotCastReason.SanByScopeGridCounts
        end
        return result, firstFailedReason
    end

    if requireHPPercent > 0 then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        --[[
            注意：这里使用casterEntity而不是teamEntity
            GetCurrentLogicHP在秘境和秘境之外有不同的行为，可以保证秘境内外的功能，但是：
            因为秘境内的血量计算机制，光灵当前血量与队伍整体血量是不同的
            这里如果用teamEntity，会导致类似**莲**这样的光灵，在释放主动技时造成自杀，这种情况（至少目前）是【不允许】的
            参考MSG41035的备注：“讨论纪要”
        ]]
        local hp = utilData:GetCurrentLogicHP(casterEntity)
        local maxhp = utilData:GetCurrentLogicMaxHP(casterEntity)
        local requireHPVal = maxhp * requireHPPercent
        result = result and (hp > requireHPVal)
        if (not result) then
            return result, BattleUIActiveSkillCannotCastReason.DecreaseHPPercentAsSan
        end
    end

    ---@type ConfigService
    local cfgsvc = self._world:GetService("Config")
    local skillcfg = cfgsvc:GetSkillConfigData(skillID)
    ---@type table<SkillTriggerTypeExtraParam, any>
    local triggerExtraParam = skillcfg:GetSkillTriggerExtraParam()
    if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.SanNotFull] then
        local logicMaxSan = self:GetSanMaxValue()
        result = result and ((logicSanVal - requireVal) < logicMaxSan) -- 这些条件是可以叠加的，后面判断要考虑前面的潜在变化
        if (not result) then
            return result, BattleUIActiveSkillCannotCastReason.SanNotFull
        end
    end
    if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.CardNotFull] then
        result = result and (self:CanAddCard()) -- 这些条件是可以叠加的，后面判断要考虑前面的潜在变化
        if (not result) then
            return result, BattleUIActiveSkillCannotCastReason.CardNotFull
        end
    end

    return result
end

--endregion
--------------------------------San End---------------------------------------

--------------------------------昼夜-------------------------------------------
---昼夜系统初始化
---@param featureData FeatureEffectParamDayNight
function FeatureServiceLogic:_HandleInitFeature_DayNight(featureType,featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local enterState = featureData:GetEnterState()--第一回合配置夜晚 也要从白天切换过去
        logicFeatureCmpt:SetDayNightData(FeatureDayNightState.Day,featureData:GetLastRound(FeatureDayNightState.Day))
    end
end
---回合开始 回合数变化 检查昼夜切换
function FeatureServiceLogic:_CheckFeatureDayNightOnRoundEnter()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type FeatureEffectParamDayNight
    local featureData = self:GetFeatureData(FeatureType.DayNight)
    if featureData then
        ---@type LogicFeatureComponent
        local logicFeatureCmpt = self:GetLogicCmpt()
        if logicFeatureCmpt then
            local ignoreFirstRoundCheck = logicFeatureCmpt:GetDayNightIgnoreFirstRoundCheck()
            if ignoreFirstRoundCheck or (not battleStatCmpt:IsFirstRound()) then
                local curState,oldState,restRound = self:_DecreaseDayNightRound(1)
                if curState ~= oldState then
                    self._world:GetService("Trigger"):Notify(NTDayNightStateChange:New(curState, oldState))
                end
                ---@type L2RService
                local l2rSvc = self._world:GetService("L2R")
                l2rSvc:L2RDayNightRoundChange(curState,oldState,restRound)
            else
                --第一回合 入场配置为黑夜，需要从白天切换
                local enterState = featureData:GetEnterState()
                local oldState,oldRestRound = logicFeatureCmpt:GetDayNightData()
                if enterState ~= oldState then
                    local curState = enterState
                    local restRound = featureData:GetLastRound(curState)
                    logicFeatureCmpt:SetDayNightData(curState,restRound)
                    self._world:GetService("Trigger"):Notify(NTDayNightStateChange:New(curState, oldState))
                    ---@type L2RService
                    local l2rSvc = self._world:GetService("L2R")
                    l2rSvc:L2RDayNightRoundChange(curState,oldState,restRound)
                end
            end
        end
    end
end
--buff用 修改昼夜
function FeatureServiceLogic:ModifyDayNightData(newState,restRound)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    local oldState,oldRestRound = logicFeatureCmpt:GetDayNightData()
    logicFeatureCmpt:SetDayNightData(newState,restRound)
    logicFeatureCmpt:SetDayNightIgnoreFirstRoundCheck(true)
    if newState ~= oldState then
        self._world:GetService("Trigger"):Notify(NTDayNightStateChange:New(newState, oldState))
    end
    Log.debug("Feature logic,buff modify dayNight, oldState:",oldState," newState:",newState," restRound:",restRound)
    return oldState,newState,restRound
end
---昼夜 回合变化
function FeatureServiceLogic:_DecreaseDayNightRound(decRound)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    local oldState,oldRestRound = logicFeatureCmpt:GetDayNightData()
    local restRound = oldRestRound - decRound
    local curState = oldState
    if restRound <= 0 then --切换
        if oldState == FeatureDayNightState.Day then
            curState = FeatureDayNightState.Night
        else
            curState = FeatureDayNightState.Day
        end
        ---@type FeatureEffectParamDayNight
        local featureData = self:GetFeatureData(FeatureType.DayNight)
        if featureData then
            restRound = featureData:GetLastRound(curState)
        end
    end
    logicFeatureCmpt:SetDayNightData(curState,restRound)
    return curState,oldState,restRound
end
---昼夜相关
---@return FeatureDayNightState
function FeatureServiceLogic:GetCurDayNightState()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local curState,restRound = logicFeatureCmpt:GetDayNightData()
        return curState
    end
end
--------------------------------昼夜 End---------------------------------------
---region P5模块
---P5模块初始化
---@param featureData FeatureEffectParamPersonaSkill
function FeatureServiceLogic:_HandleInitFeature_PersonaSkill(featureType,featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local personaSkill = featureData:GetPersonaSkillID()
        logicFeatureCmpt:SetFeatureSkillID(FeatureType.PersonaSkill,personaSkill)
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        local skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.PersonaSkillHolder)
        if skillHolder then
            local holderID = skillHolder:GetID()
            logicFeatureCmpt:SetFeatureSkillHolderID(FeatureType.PersonaSkill,holderID)
            local attack,p5PetCount = self:_HandlePersonaPetsInfo()
            --临时
            local firstElement = ElementType.ElementType_Green
            local secondElement = ElementType.ElementType_Green
            --设置数值
            local attributeCmpt = skillHolder:Attributes()
            attributeCmpt:SetSimpleAttribute("Element", firstElement)
            attributeCmpt:Modify("Attack", attack)
            skillHolder:ReplaceElement(firstElement, secondElement)
            logicFeatureCmpt:SetPersonaPetCount(p5PetCount)
        end
        self:SetFeatureSkillCurPower(FeatureType.PersonaSkill,0,1)
    end
end
function FeatureServiceLogic:_HandlePersonaPetsInfo()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    ---@type table<number,number>  队伍的逻辑顺序 key是序号 value是PetPstID
    local teamOrder = teamCmpt:GetTeamOrder()
    local topAttack = 1
    local personPetCount = 0
    for order,petPstID in ipairs(teamOrder) do
        local petEntity = teamCmpt:GetPetEntityByPetPstID(petPstID)
        ---@type MatchPet
        local matchPet = petEntity:MatchPet():GetMatchPet()
        local petFeatureList = matchPet:GetFeatureList()--原始配置数据
        if petFeatureList then
            local petFeatures = petFeatureList.feature
            if petFeatures then
                if petFeatures[FeatureType.PersonaSkill] then
                    local attack = matchPet:GetPetAttack()
                    if attack > topAttack then
                        topAttack = attack
                    end
                    personPetCount = personPetCount + 1
                end
            end
        end
    end
    return topAttack,personPetCount
end
function FeatureServiceLogic:GetPersonaPetCount()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetPersonaPetCount()
    end
    return 1
end
---end region P5模块

---region 选牌模块
---选牌模块初始化
---@param featureData FeatureEffectParamCard
function FeatureServiceLogic:_HandleInitFeature_Card(featureType,featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local cardSkillDic = featureData:GetCardSkillDic()
        logicFeatureCmpt:SetCardSkillDic(cardSkillDic)
        local cardMax = featureData:GetCardMax()
        logicFeatureCmpt:SetCardMax(cardMax)
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        local skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.PersonaSkillHolder)
        if skillHolder then
            local holderID = skillHolder:GetID()
            logicFeatureCmpt:SetFeatureSkillHolderID(FeatureType.Card,holderID)
            --临时
            local firstElement = ElementType.ElementType_Green
            local secondElement = ElementType.ElementType_Green
            local attack = self:_HandleCardPetsInfo()
            --设置数值
            local attributeCmpt = skillHolder:Attributes()
            attributeCmpt:SetSimpleAttribute("Element", firstElement)
            attributeCmpt:Modify("Attack", attack)
            skillHolder:ReplaceElement(firstElement, secondElement)
        end
        self:SetFeatureSkillCurPower(FeatureType.Card,0,1)
        local initCardNum = featureData:GetInitCardNum()
        if initCardNum and initCardNum > 0 then
            local needNum = initCardNum
            local initCardList = featureData:GetInitCardList()
            if initCardList then
                for _,cardType in ipairs(initCardList) do
                    if cardType >= FeatureCardType.MIN and cardType <= FeatureCardType.MAX then
                        needNum = needNum - 1
                        if needNum < 0 then
                            break
                        end
                        self:AddCard(cardType)
                    end
                end
            end
            if needNum > 0 then
                ---@type RandomServiceLogic
                local randomSvc = self._world:GetService("RandomLogic")
                ---产生随机数
                for i = 1 , needNum do
                    local cardType = randomSvc:LogicRand(FeatureCardType.MIN, FeatureCardType.MAX)--固定三种
                    self:AddCard(cardType)
                end
            end
            
        end
        -- self:AddCard(FeatureCardType.A)
        -- self:AddCard(FeatureCardType.A)
        -- self:AddCard(FeatureCardType.A)
        -- self:AddCard(FeatureCardType.B)
        -- self:AddCard(FeatureCardType.B)
        -- self:AddCard(FeatureCardType.B)
        -- self:AddCard(FeatureCardType.C)
        -- self:AddCard(FeatureCardType.C)
        -- self:AddCard(FeatureCardType.C)
    end
end
function FeatureServiceLogic:_HandleCardPetsInfo()
    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type TeamComponent
    local teamCmpt = teamEntity:Team()
    ---@type table<number,number>  队伍的逻辑顺序 key是序号 value是PetPstID
    local teamOrder = teamCmpt:GetTeamOrder()
    local topAttack = 1
    for order,petPstID in ipairs(teamOrder) do
        local petEntity = teamCmpt:GetPetEntityByPetPstID(petPstID)
        ---@type MatchPet
        local matchPet = petEntity:MatchPet():GetMatchPet()
        local petFeatureList = matchPet:GetFeatureList()--原始配置数据
        if petFeatureList then
            local petFeatures = petFeatureList.feature
            if petFeatures then
                if petFeatures[FeatureType.Card] then
                    local attack = matchPet:GetPetAttack()
                    if attack > topAttack then
                        topAttack = attack
                    end
                end
            end
        end
    end
    return topAttack
end
---记录抽牌
function FeatureServiceLogic:AddCard(cardType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        if logicFeatureCmpt:CanAddCard() then
            logicFeatureCmpt:AddCard(cardType)
        end
    end
end
function FeatureServiceLogic:CanAddCard()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:CanAddCard()
    end
    return false
end
function FeatureServiceLogic:GetCards()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetCards()
    end
    return {}
end
function FeatureServiceLogic:GetCurCardCount()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetCurCardCount()
    end
    return 0
end
function FeatureServiceLogic:CostCard(cardList)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:CostCard(cardList)
    end
    return {}
end
function FeatureServiceLogic:CostCardByType(compositionType)
    local cardList = self:GetCostCardListByType(compositionType)
    self:CostCard(cardList)
end
function FeatureServiceLogic:GetCostCardListByType(compositionType)
    local quickDic = {
        [FeatureCardCompositionType.ABC] = {1,2,3},
        [FeatureCardCompositionType.AAA] = {1,1,1},
        [FeatureCardCompositionType.BBB] = {2,2,2},
        [FeatureCardCompositionType.CCC] = {3,3,3},
        [FeatureCardCompositionType.AAB] = {1,1,2},
        [FeatureCardCompositionType.AAC] = {1,1,3},
        [FeatureCardCompositionType.BBA] = {1,2,2},
        [FeatureCardCompositionType.BBC] = {2,2,3},
        [FeatureCardCompositionType.CCA] = {1,3,3},
        [FeatureCardCompositionType.CCB] = {2,3,3},
    }
    return quickDic[compositionType] or {}
end
function FeatureServiceLogic:IsCardEnoughToCost(compositionType)
    local cards = self:GetCards()
    local cost = self:GetCostCardListByType(compositionType)
    local costDic = {}
    for _,cardType in ipairs(cost) do
        if costDic[cardType] then
            costDic[cardType] = costDic[cardType] + 1
        else
            costDic[cardType] = 1
        end
    end
    local enough = true
    for cardType,count in pairs(costDic) do
        if cards[cardType] and (cards[cardType] >= count) then
        else
            enough = false
            break
        end
    end
    return enough
end
-- function FeatureServiceLogic:CaclCardCompositionType(cardList)
--     local comType = FeatureCardCompositionType.NONE
--     if cardList and #cardList >= 3 then
--         local checked = {}
--         local diffTypeCount = 0
--         for i,cardType in ipairs(cardList) do
--             if not table.icontains(checked,cardType) then
--                 table.insert(checked,cardType)
--             end
--         end
--         diffTypeCount = #checked
--         if diffTypeCount == 3 then
--             comType = FeatureCardCompositionType.ABC
--         elseif diffTypeCount == 2 then
--             comType = FeatureCardCompositionType.AAB
--         elseif diffTypeCount == 1 then
--             comType = FeatureCardCompositionType.AAA
--         end
--     end
--     return comType
-- end

--卡牌列表转换为枚举 
function FeatureServiceLogic:CaclCardCompositionType(cardList)
    local quickDic = {
        [123] = FeatureCardCompositionType.ABC,
        [111] = FeatureCardCompositionType.AAA,
        [222] = FeatureCardCompositionType.BBB,
        [333] = FeatureCardCompositionType.CCC,
        [112] = FeatureCardCompositionType.AAB,
        [113] = FeatureCardCompositionType.AAC,
        [122] = FeatureCardCompositionType.BBA,
        [223] = FeatureCardCompositionType.BBC,
        [133] = FeatureCardCompositionType.CCA,
        [233] = FeatureCardCompositionType.CCB,
    }
    local comType = FeatureCardCompositionType.NONE
    if cardList and #cardList >= 3 then
        local sortedCard = {}
        for i,cardType in ipairs(cardList) do
            table.insert(sortedCard,cardType)
        end
        table.sort(sortedCard)
        local dicKey = sortedCard[1] * 100 + sortedCard[2] * 10 + sortedCard[3]
        local resType = quickDic[dicKey]
        if resType then
            comType = resType
        end
    end
    return comType
end
--记录抽牌
function FeatureServiceLogic:RecordDrawCard(teamEntityID,curRound,cardType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:RecordDrawCard(teamEntityID,curRound,cardType)
    end
    return
end
--取抽牌数 指定队伍id，回合 round不填则取该队总数
function FeatureServiceLogic:GetDrawCardTimes(teamEntityID,round)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetDrawCardTimes(teamEntityID,round)
    end
    return
end
--根据抽牌次数取固定的卡牌 用于引导关
function FeatureServiceLogic:GetNextDrawFixedCard()
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if not teamEntity then
        return
    end
    local teamEntityID = teamEntity:GetID()
    local curTimes = self:GetDrawCardTimes(teamEntityID)
    if not curTimes then
        return
    end
    local nextTimes = curTimes + 1
    ---@type FeatureEffectParamCard
    local featureData = self:GetFeatureData(FeatureType.Card)
    if featureData then
        local cardType = featureData:GetFixedDrawCard(nextTimes)
        if cardType then
            if cardType >= FeatureCardType.MIN and cardType <= FeatureCardType.MAX then
                return cardType
            end
        end
    end
    return
end
--自动战斗 判断牌库是否有3张相同卡牌
function FeatureServiceLogic:HasEnoughSameCard(count)
    local depot = self:GetCards()
    if depot then
        for cardType,cardCount in pairs(depot) do --pairs 遍历
            if cardCount >= count then
                return true
            end
        end
    end
    return false
end
--自动战斗 杰诺 第一回合抽到牌库有3张相同，本回合就不做抽牌 记录一下
function FeatureServiceLogic:SetAutoFightFirstRoundDrawCardEnough(teamEntityID,bEnough)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetAutoFightFirstRoundDrawCardEnough(teamEntityID,bEnough)
    end
    return
end
--自动战斗 杰诺 第一回合抽到牌库有3张相同，本回合就不做抽牌 记录一下
function FeatureServiceLogic:GetAutoFightFirstRoundDrawCardEnough(teamEntityID)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetAutoFightFirstRoundDrawCardEnough(teamEntityID)
    end
    return true
end
--自动战斗 可用的技能列表 
function FeatureServiceLogic:GetAvailableCardSkillList()
    --顺序 3牌相同、3牌不同、其他
    local skillCheckSeq = {
        FeatureCardCompositionType.AAA,
        FeatureCardCompositionType.BBB,
        FeatureCardCompositionType.CCC,
        FeatureCardCompositionType.ABC,
        FeatureCardCompositionType.AAB,
        FeatureCardCompositionType.AAC,
        FeatureCardCompositionType.BBA,
        FeatureCardCompositionType.BBC,
        FeatureCardCompositionType.CCA,
        FeatureCardCompositionType.CCB,
    }
    local featureData = self:GetFeatureData(FeatureType.Card)
    if not featureData then
        return {}
    end
    local skillList = {}
    local cardSkillDic = featureData:GetCardSkillDic()
    for _,comType in ipairs(skillCheckSeq) do
        local skillID = cardSkillDic[comType]
        if skillID then
            local canCast = self:_CheckFeatureSkillCastCondition_Card(skillID)
            if canCast then
                table.insert(skillList,skillID)
            end
        end
    end
    return skillList
end
--抽牌权重
function FeatureServiceLogic:GetRandomDrawCardWeight(teamEntityID)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetRandomDrawCardWeight(teamEntityID)
    end
end
---end region 选牌模块


------region 空裔技能模块
---初始化
---@param featureData FeatureEffectParamMasterSkill
function FeatureServiceLogic:_HandleInitFeature_MasterSkill(featureType,featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local masterSkill = featureData:GetMasterSkillID()
        logicFeatureCmpt:SetFeatureSkillID(featureType,masterSkill)
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        local skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.PersonaSkillHolder)
        if skillHolder then
            local holderID = skillHolder:GetID()
            logicFeatureCmpt:SetFeatureSkillHolderID(featureType,holderID)
            local attack = 100
            --临时
            local firstElement = ElementType.ElementType_Green
            local secondElement = ElementType.ElementType_Green
            --设置数值
            local attributeCmpt = skillHolder:Attributes()
            attributeCmpt:SetSimpleAttribute("Element", firstElement)
            attributeCmpt:Modify("Attack", attack)
            skillHolder:ReplaceElement(firstElement, secondElement)
        end
        self:SetFeatureSkillCurPower(featureType,0,1)
    end
end


---end region 空裔技能模块

--region 消灭星星技能模块
---初始化
---@param featureData FeatureEffectParamPopStar
function FeatureServiceLogic:_HandleInitFeature_PopStar(featureType, featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local masterSkill = featureData:GetMasterSkillID()
        logicFeatureCmpt:SetFeatureSkillID(featureType, masterSkill)
        ---@type LogicEntityService
        local entityService = self._world:GetService("LogicEntity")
        local skillHolder = entityService:CreateLogicEntity(EntityConfigIDConst.PersonaSkillHolder)
        if skillHolder then
            local holderID = skillHolder:GetID()
            logicFeatureCmpt:SetFeatureSkillHolderID(featureType, holderID)
            local attack = 100
            --临时
            local firstElement = ElementType.ElementType_Green
            local secondElement = ElementType.ElementType_Green
            --设置数值
            local attributeCmpt = skillHolder:Attributes()
            attributeCmpt:SetSimpleAttribute("Element", firstElement)
            attributeCmpt:Modify("Attack", attack)
            skillHolder:ReplaceElement(firstElement, secondElement)
        end
        self:SetFeatureSkillCurPower(featureType, 0, 0)
    end
end
--endregion 消灭星星技能模块

--region 阿克希亚扫描模块
---@param featureData FeatureEffectParamScan
function FeatureServiceLogic:_HandleInitFeature_Scan(featureData)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()

    if not logicFeatureCmpt then
        Log.error("FeatureServiceLogic: no LogicFeatureComponent found")
        return
    end

    logicFeatureCmpt:InitScanFeature(
        featureData:GetSummonTrapSkillID(),
        featureData:GetForceMovementSkillID(),
        featureData:GetSummonScanTrapSkillID(),
        featureData:GetEmptySkillID()
    )
end
--endregion

--region 机关数量显示模块
---@param featureData FeatureEffectParamTrapCount
function FeatureServiceLogic:_HandleInitFeature_TrapCount(featureType,featureData)
end
--endregion

---region 模块技能通用
function FeatureServiceLogic:_CheckFeatureSkillOnRoundEnter(featureType,incRound)
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    if not battleStatCmpt:IsFirstRound() then
        ---@type FeatureEffectParamMasterSkill
        local featureData = self:GetFeatureData(featureType)
        if featureData then
            local curPower,curReady = self:GetFeatureSkillCurPower(featureType)
            if curPower and curReady and (curReady == 0) then
                if incRound then
                    ---@type LogicFeatureComponent
                    local logicFeatureCmpt = self:GetLogicCmpt()
                    if logicFeatureCmpt then

                        ---延迟修改的到回合开始才生效
                        local delayChangePowerValue = self:GetFeatureSkillDelayModifyPower(featureType)
                        if delayChangePowerValue and delayChangePowerValue ~= 0  then
                            curPower = curPower + delayChangePowerValue
                            self:SetFeatureSkillDelayModifyPower(featureType,0)
                        end

                        local lastDoFeatureSkillRound = logicFeatureCmpt:GetLastDoFeatureSkillRound(featureType)
                        local curRound = battleStatCmpt:GetLevelTotalRoundCount()
                        if lastDoFeatureSkillRound then
                            ---由于现在是WaitInPut处理的CD 所以要大于1
                            if (curRound - lastDoFeatureSkillRound) > 1 then
                                curPower = curPower - 1
                            end
                        else
                            if incRound then
                                curPower = curPower - 1
                            end
                        end
                    end
                    if curPower < 0 then
                        curPower = 0
                    end
                    if curPower == 0 then
                        curReady = 1
                    end
                    self:SetFeatureSkillCurPower(featureType,curPower,curReady)
                    self._world:EventDispatcher():Dispatch(GameEventType.PersonaPowerChange,featureType, curPower, curReady)
                end
            end
        end
    end
end
function FeatureServiceLogic:SetFeatureSkillCurPower(featureType,power,ready)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetFeatureSkillCurPower(featureType,power,ready)
    end
end
function FeatureServiceLogic:GetFeatureSkillCurPower(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetFeatureSkillCurPower(featureType)
    end
    return nil
end
--延迟改cd
function FeatureServiceLogic:SetFeatureSkillDelayModifyPower(featureType,delayModifyPower)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetFeatureSkillDelayModifyPower(featureType,delayModifyPower)
    end
end
function FeatureServiceLogic:GetFeatureSkillDelayModifyPower(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetFeatureSkillDelayModifyPower(featureType)
    end
    return 0
end
function FeatureServiceLogic:BuffChangeFeatureSkillPower(featureType,modifyValue)
    if FeatureType.PopStar == featureType then
        return self:_BuffChangeFeatureSkillPowerForPopStar(modifyValue)
    end

    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    ---@type FeatureEffectParamMasterSkill
    local featureData = self:GetFeatureData(featureType)
    if featureData then
        local curPower,curReady = self:GetFeatureSkillCurPower(featureType)
        if curPower and (curPower > 0) then
            if modifyValue and (modifyValue ~= 0) then
                ---@type LogicFeatureComponent
                local logicFeatureCmpt = self:GetLogicCmpt()
                if logicFeatureCmpt then
                    local lastDoFeatureSkillRound = logicFeatureCmpt:GetLastDoFeatureSkillRound(featureType)
                    local curRound = battleStatCmpt:GetLevelTotalRoundCount()
                    if lastDoFeatureSkillRound then
                        if (curRound - lastDoFeatureSkillRound) > 0 then
                            curPower = curPower + modifyValue
                        else
                            --当回合放过技能，延迟到下回合修改cd
                            local oldDelayModifyPower = self:GetFeatureSkillDelayModifyPower(featureType)
                            local curDelayModifyPower = oldDelayModifyPower + modifyValue
                            self:SetFeatureSkillDelayModifyPower(featureType,curDelayModifyPower)
                            return
                        end
                    else
                        curPower = curPower + modifyValue
                    end
                end
                if curPower < 0 then
                    curPower = 0
                end
                if curPower == 0 then
                    curReady = 1
                end
                self:SetFeatureSkillCurPower(featureType,curPower,curReady)
                return featureType,curPower,curReady
                --

                --self._world:EventDispatcher():Dispatch(GameEventType.PersonaPowerChange,featureType, curPower, curReady)
            end
        end
    end
end

function FeatureServiceLogic:_BuffChangeFeatureSkillPowerForPopStar(modifyValue)
    ---@type FeatureEffectParamPopStar
    local featureData = self:GetFeatureData(FeatureType.PopStar)
    if featureData then
        local curPower, curReady = self:GetFeatureSkillCurPower(FeatureType.PopStar)
        if curPower then
            if modifyValue and (modifyValue ~= 0) then
                ---@type LogicFeatureComponent
                local logicFeatureCmpt = self:GetLogicCmpt()
                if logicFeatureCmpt then
                    curPower = curPower + modifyValue
                end
                if curPower < 0 then
                    curPower = 0
                end

                local skillID = featureData:GetMasterSkillID()
                ---@type ConfigService
                local configService = self._world:GetService("Config")
                ---@type SkillConfigData
                local skillConfigData = configService:GetSkillConfigData(skillID)
                local costLegendPower = skillConfigData:GetSkillTriggerParam()
                if curPower >= costLegendPower then
                    curReady = 1
                else
                    curReady = 0
                end
                self:SetFeatureSkillCurPower(FeatureType.PopStar, curPower, curReady)
                return FeatureType.PopStar, curPower, curReady
            end
        end
    end
end

function FeatureServiceLogic:CheckFeatureSkillCastCondition(featureType,skillID)
    --主动技释放条件校验日志信息
    local log = {
        tostring(BattleConst.Kick),
        tostring(skillID),
    }

    ---如果不踢人的话，就不需要检查合法性了
    if not BattleConst.Kick then
        return true, log
    end
    if FeatureType.PersonaSkill == featureType
        or FeatureType.MasterSkill == featureType
        or FeatureType.MasterSkillRecover == featureType
        or FeatureType.MasterSkillTeleport == featureType
     then
        --UI技能ID和逻辑技能ID一致
        local localSkillID = self:GetFeatureSkillID(featureType)
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(localSkillID)

        if localSkillID ~= skillID then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end

        local curPower,ready = self:GetFeatureSkillCurPower(featureType)
        ---ready需要是1
        if ready == 0 then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end

        if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
            -- --传说光灵
            -- local legendPower = castPetEntity:Attributes():GetAttribute("LegendPower")
            -- local costLegendPower = skillConfigData:GetSkillTriggerParam()
            -- --罗伊 根据点选不同 消耗能量不同
            -- costLegendPower = self:_GetLegendPowerConstByExtraParam(costLegendPower, skillConfigData, petPstID)

            -- if legendPower < costLegendPower then
            --     return false, log, BattleUIActiveSkillCannotCastReason.NotReady
            -- end
        else
            --其他主动技
            ---CD值需要是0
            if curPower ~= 0 then
                return false, log, BattleUIActiveSkillCannotCastReason.NotReady
            end
        end
    elseif FeatureType.PopStar == featureType then
        --UI技能ID和逻辑技能ID一致
        local localSkillID = self:GetFeatureSkillID(featureType)
        if localSkillID ~= skillID then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end

        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(localSkillID)    

        ---获取当前传说能量点和是否就绪
        local legendPower, ready = self:GetFeatureSkillCurPower(featureType)
        if ready == 0 then
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end

        if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
            local costLegendPower = skillConfigData:GetSkillTriggerParam()
            
            if legendPower < costLegendPower then
                return false, log, BattleUIActiveSkillCannotCastReason.NotReady
            end
        else
            ---配置错误，需配置能量点触发
            return false, log, BattleUIActiveSkillCannotCastReason.NotReady
        end
    elseif FeatureType.Card == featureType then
        return self:_CheckFeatureSkillCastCondition_Card(skillID,log)
    end
    return true, log
end
function FeatureServiceLogic:_CheckFeatureSkillCastCondition_Card(skillID,log)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    if skillConfigData then
        local triggerExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if triggerExtraParam then
            local cardCostType = triggerExtraParam[SkillTriggerTypeExtraParam.CardCost]
            if cardCostType then
                if self:IsCardEnoughToCost(cardCostType) then
                    --检查目标是否有指定buff
                    local tarPetNotHasBuffParam = triggerExtraParam[SkillTriggerTypeExtraParam.CardTarPetNotHasBuff]
                    if tarPetNotHasBuffParam then
                        if #tarPetNotHasBuffParam > 0 then
                            local tarPetType = tarPetNotHasBuffParam[1]
                            local checkBuffList = {}
                            local totalParam = #tarPetNotHasBuffParam
                            for i=2,totalParam do
                                local buffEffect = tarPetNotHasBuffParam[i]
                                table.insert(checkBuffList,buffEffect)
                            end
                            local tarPet = nil
                            if tarPetType == FeatureTarPetSelectType.TeamLeader then
                                local teamEntity = self._world:Player():GetCurrentTeamEntity()
                                if teamEntity then
                                    local teamLeader = teamEntity:Team():GetTeamLeaderEntity()
                                    tarPet = teamLeader
                                end
                            elseif tarPetType == FeatureTarPetSelectType.TeamTail then
                                local teamEntity = self._world:Player():GetCurrentTeamEntity()
                                if teamEntity then
                                    ---@type TeamComponent
                                    local cTeam = teamEntity:Team()
                                    local teamOrder = cTeam:GetTeamOrder()
                                    local finalIndex = #teamOrder
                                    local lastPetPstID = teamOrder[finalIndex]
                                    local lastPetEntity = cTeam:GetPetEntityByPetPstID(lastPetPstID)
                                    tarPet = lastPetEntity
                                end
                            end
                            if tarPet then
                                local hasBuff = false
                                ---@type UtilDataServiceShare
                                local utilData = self._world:GetService("UtilData")
                                for i,buffEffect in ipairs(checkBuffList) do
                                    hasBuff = utilData:HasBuffEffect(tarPet,buffEffect)
                                    if hasBuff then
                                        break
                                    end
                                end
                                if hasBuff then
                                    return false, log, BattleUIActiveSkillCannotCastReason.CardTarPetHasBuff
                                end
                            end
                        end
                    else
                        return true,log
                    end
                    return true,log
                else
                    return false, log, BattleUIActiveSkillCannotCastReason.CardNotEnough
                end
            end
        end
    end
    return false,log, BattleUIActiveSkillCannotCastReason.NotReady
end
function FeatureServiceLogic:OnFeatureSkillCast(featureType,skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    if FeatureType.PersonaSkill == featureType
        or FeatureType.MasterSkill == featureType
        or FeatureType.MasterSkillRecover == featureType
        or FeatureType.MasterSkillTeleport == featureType
    then
        local MaxPower = skillConfigData:GetSkillTriggerParam()
        local cdOff = self:GetAllFeatureSkillCdOff()
        local specificCdOff = self:GetSpecificFeatureSkillCdOff(featureType)
        MaxPower = MaxPower + cdOff + specificCdOff
        if MaxPower < 0 then
            MaxPower = 0
        end
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local round = battleStatCmpt:GetLevelTotalRoundCount()
        self:SetLastDoFeatureSkillRound(featureType,round)
        self:SetFeatureSkillCurPower(featureType,MaxPower,0)
     elseif FeatureType.Card == featureType then
        if skillConfigData then
            local triggerExtraParam = skillConfigData:GetSkillTriggerExtraParam()
            if triggerExtraParam then
                local cardCostType = triggerExtraParam[SkillTriggerTypeExtraParam.CardCost]
                if cardCostType then
                    self:CostCardByType(cardCostType)
                    self._world:EventDispatcher():Dispatch(GameEventType.FeatureUIRefreshCardNum)
                end
            end
        end
    elseif FeatureType.PopStar == featureType then
        local costLegendPower = skillConfigData:GetSkillTriggerParam()
        local legendPower, isReady = self:GetFeatureSkillCurPower(featureType)
        legendPower = legendPower - costLegendPower
        if legendPower <= 0 then
            legendPower = 0
            isReady = 0
        end
        self:SetFeatureSkillCurPower(featureType, legendPower, isReady)
        self._world:EventDispatcher():Dispatch(GameEventType.PersonaPowerChange, featureType, legendPower, isReady)
    end
end
function FeatureServiceLogic:SetLastDoFeatureSkillRound(featureType,round)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetLastDoFeatureSkillRound(featureType,round)
    end
end
function FeatureServiceLogic:GetLastDoFeatureSkillRound(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetLastDoFeatureSkillRound(featureType)
    end
end
function FeatureServiceLogic:GetFeatureSkillID(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local skillID = logicFeatureCmpt:GetFeatureSkillID(featureType)
        return skillID
    end
    return nil
end
function FeatureServiceLogic:GetFeatureSkillHolderEntityID(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        local holderID = logicFeatureCmpt:GetFeatureSkillHolderID(featureType)
        if holderID then
            return holderID
        end
    end
    return nil
end
function FeatureServiceLogic:GetFeatureSkillHolderEntity(featureType)
    local holderID = self:GetFeatureSkillHolderEntityID(featureType)
    if holderID then
        local skillHolder = self._world:GetEntityByID(holderID)
        return skillHolder
    end
    return nil
end
function FeatureServiceLogic:SetAllFeatureSkillCdOff(cdOff)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetAllFeatureSkillCdOff(cdOff)
    end
end
function FeatureServiceLogic:GetAllFeatureSkillCdOff()
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetAllFeatureSkillCdOff()
    end
    return 0
end
function FeatureServiceLogic:SetSpecificFeatureSkillCdOff(featureType,cdOff)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        logicFeatureCmpt:SetSpecificFeatureSkillCdOff(featureType,cdOff)
    end
end
function FeatureServiceLogic:GetSpecificFeatureSkillCdOff(featureType)
    ---@type LogicFeatureComponent
    local logicFeatureCmpt = self:GetLogicCmpt()
    if logicFeatureCmpt then
        return logicFeatureCmpt:GetSpecificFeatureSkillCdOff(featureType)
    end
    return 0
end
------end region 模块技能通用