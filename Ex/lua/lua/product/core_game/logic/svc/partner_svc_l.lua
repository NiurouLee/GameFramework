--[[------------------------------------------------------------------------------------------
    PartnerServiceLogic : 伙伴逻辑服务
]] --------------------------------------------------------------------------------------------
require("battle_ui_active_skill_cannot_cast_reason")

_class("PartnerServiceLogic", BaseService)
---@class PartnerServiceLogic: BaseService
PartnerServiceLogic = PartnerServiceLogic

function PartnerServiceLogic:Constructor()
end

function PartnerServiceLogic:Initialize()
end
function PartnerServiceLogic:CanEnablePartner()
    if self._world:MatchType() == MatchType.MT_MiniMaze then
        return true
    end
    return false
end

function PartnerServiceLogic:CreatePartner(partnerID)
    if not self:CanEnablePartner() then
        return
    end
    if not partnerID then
        return
    end
    local partnerCfg = Cfg.cfg_mini_maze_partner_info[partnerID]
    if not partnerCfg then
        Log.debug("[MiniMaze] PartnerServiceLogic:CreatePartner no partnerCfg, partnerID: ",partnerID)
        return
    end
    local partnerAttrCfg = nil
    local cfgGroup = Cfg.cfg_component_bloodsucker_pet_attribute{ComponentID = BattleConst.PartnerAttrCfgComponentID, PetId = partnerCfg.PetID}
    if cfgGroup and #cfgGroup > 0 then
        partnerAttrCfg = cfgGroup[1]
    end
    if not partnerAttrCfg then
        Log.debug("[MiniMaze] PartnerServiceLogic:CreatePartner no partnerAttrCfg, partnerID: ",partnerID)
        return
    end
    local teamPetsMax = 8
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPetEntitys = teamEntity:Team():GetTeamPetEntities()
    if #teamPetEntitys >= teamPetsMax then
        Log.debug("[MiniMaze] PartnerServiceLogic:CreatePartner too mutch pet ")
        return
    end
    --记录被弃选的伙伴ID
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local curWaveIndex = battleStatCmpt:GetCurWaveIndex()
    local curWaveOptionalPartnerIDList = battleStatCmpt:GetWaveOptionalPartnerIDList(curWaveIndex)
    local abandonedList = {}
    if curWaveOptionalPartnerIDList then
        for _, partnerID in ipairs(curWaveOptionalPartnerIDList) do
            table.insert(abandonedList,partnerID)
        end
    end
    battleStatCmpt:AddAbandonedPartnerIDList(abandonedList)
    --存储选择过的伙伴
    --if self._world:RunAtServer() then
        battleStatCmpt:SetWaveChoosePartner(curWaveIndex, partnerID)
    --end

    local createInfo = {}
    createInfo.petID = partnerCfg.PetID
    createInfo.level = 1
    createInfo.grade = partnerAttrCfg.Grade
    createInfo.awake = partnerAttrCfg.Awakening
    createInfo.equip = partnerAttrCfg.Equip
    createInfo.atk = partnerAttrCfg.Attack
    createInfo.def = partnerAttrCfg.Def
    createInfo.hp = partnerAttrCfg.Hp
    createInfo.affinityLevel = 1
    -- createInfo.level = partnerCfg.Level
    -- createInfo.grade = partnerCfg.GradeLevel
    -- createInfo.awake = partnerCfg.AwakenLevel
    -- createInfo.equip = partnerCfg.EquipLevel
    -- createInfo.atk = partnerCfg.Attack
    -- createInfo.def = partnerCfg.Defence
    -- createInfo.hp = partnerCfg.Health
    -- createInfo.affinityLevel = partnerCfg.AffinityLevel
    local petEntity,petInfo,matchPet,petRes,hp,maxHP = self:CreateMiddleEnterPet(createInfo)
    Log.debug("[MiniMaze] PartnerServiceLogic:CreatePartner after CreateMiddleEnterPet ")
    --local svc = self._world:GetService("L2R")
    --svc:L2RAddPartnerData(partnerID,petInfo,matchPet,petRes,hp,maxHP)
    return partnerID,petInfo,matchPet,petRes,hp,maxHP
end
--测试 中途加光灵
function PartnerServiceLogic:CreateMiddleEnterPet(createInfo)
    local petID = createInfo.petID
    local cfg = Cfg.cfg_pet[petID]
    if not cfg then
        return
    end
    local petEntity,petInfo,matchPet = self:CreateMiddleEnterTeamMember(createInfo)
    local petRes = self:CreateMiddleEnterTeamMemberRes(petEntity)

    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type AttributesComponent
    local attributesComponent = teamEntity:Attributes()
    local hp = attributesComponent:GetCurrentHP()
    local maxHP = attributesComponent:CalcMaxHp()
    return petEntity,petInfo,matchPet,petRes,hp,maxHP
end

------------------
--测试 中途加光灵

function PartnerServiceLogic:CreateMiddleEnterTeamMember(createInfo)
    local petID = createInfo.petID
    ---@type RandomServiceLogic
    local randomSvc = self._world:GetService("RandomLogic")
    local randomFlag = randomSvc:LogicRand(1, 100)
    local petInfo = MatchPetInfo:New()
    local tmpPstid = 999000000 + petID + (randomFlag*10000000)
    petInfo.pet_pstid = tmpPstid
    petInfo.pet_power = -1 --初始能量
    petInfo.template_id = petID --配置id
    petInfo.level = createInfo.level or 1 --等级
    petInfo.grade = createInfo.grade or 0 --觉醒
    petInfo.awakening = createInfo.awake or 0--突破
    petInfo.affinity_level = createInfo.affinityLevel or 1 --亲密度等级
    petInfo.team_slot = 6 --宝宝在星灵队伍中的位置
    petInfo.attack = createInfo.atk or 0 --攻击力
    petInfo.defense = createInfo.def or 0 --防御力
    petInfo.max_hp = createInfo.hp or 0 --血量上限
    petInfo.cur_hp = createInfo.hp or 0 -- 当前血量
    petInfo.after_damage = 0 --伤害后处理系数
    petInfo.equip_lv = createInfo.equip or 0 --装备等级
    petInfo.m_nHelpPetKey = 0 --助战标识

    ------------------
    local petPstID = petInfo.pet_pstid

    local matchPet = MatchPet:New(petInfo)
    local listMatchPet = self._world.BW_WorldInfo:GetLocalMatchPetList()
    table.insert(listMatchPet,matchPet)
    self._world.BW_WorldInfo.localMatchPetDict[petPstID] = matchPet
    -----------------------------------
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type AffixService
    local affixService = self._world:GetService("Affix")
    ---@type Pet
    local petData = matchPet--self._world.BW_WorldInfo:GetPetData(petPstID)
    local petId = petData:GetTemplateID()
    --觉醒
    local awaking = petData:GetPetAwakening()
    --突破
    local grade = petData:GetPetGrade()
    --皮肤
    local skinId = petData:GetSkinId()
    --普通攻击
    local normalSkillID = petData:GetNormalSkill()
    if normalSkillID then
        configService:GetSkillConfigData(normalSkillID)
    end
    --连锁技能
    local chainSkillIDs = petData:GetChainSkillInfo()
    if chainSkillIDs then
        for i = 1, #chainSkillIDs do
            ---@type SkillConfigData
            local configData = configService:GetSkillConfigData(chainSkillIDs[i].Skill)
            affixService:ChangePetChainCount(configData)
        end
    end
    --主动技能
    local activeSkillID = petData:GetPetActiveSkill()
    if activeSkillID then
        configService:GetSkillConfigData(activeSkillID)
    end
    ----------------------------------------

    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    
    local petPstID = matchPet:GetPstID()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    local petEntity = entityService:_CreateTeamMemberLogic(matchPet, petPstID, teamEntity)

    self:_ReAddTeamBuffOnPartnerJoin(petEntity)
    self:_CheckFeatureOnPartnerJoin(petEntity)
    
    return petEntity,petInfo,matchPet
end
function PartnerServiceLogic:CreateMiddleEnterTeamMemberRes(petEntity)
    ---@type PetCreationResult
    local petRes = DataPetCreationResult:New()
    local matchPet = petEntity:MatchPet():GetMatchPet()

    local eid = petEntity:GetID()
    petRes:SetPetCreationLogicEntityID(eid)

    local tplID = matchPet:GetTemplateID()
    petRes:SetPetCreationTemplateID(tplID)

    local pstID = matchPet:GetPstID()
    petRes:SetPetCreationPstID(pstID)

    local firstElement = matchPet:GetPetFirstElement()
    local secondElement = matchPet:GetPetSecondElement()
    petRes:SetPetCreationElementType(firstElement, secondElement)

    local petPrefab = matchPet:GetPetPrefab(PetSkinEffectPath.MODEL_INGAME)
    petRes:SetPetCreationRes(petPrefab)

    ---@type GridLocationComponent
    local gridLocCmpt = petEntity:GridLocation()
    local gridPos = gridLocCmpt:GetGridPos()
    petRes:SetPetCreationGridPos(gridPos)

    ---@type AttributesComponent
    local attrCmpt = petEntity:Attributes()
    local hp = attrCmpt:GetCurrentHP()
    local maxHP = attrCmpt:CalcMaxHp()

    petRes:SetPetCreation_CurHp(hp)
    petRes:SetPetCreation_MaxHp(maxHP)

    
    return petRes
end
function PartnerServiceLogic:_ReAddTeamBuffOnPartnerJoin(petEntity)
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    --读取关卡数据 获得队长出生点
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    --local teamPos = levelConfigData:GetPlayerBornPos()
    --local teamRotation = levelConfigData:GetPlayerBornRotation()

    local teamPos = teamEntity:GetGridPosition()
    local teamRotation = teamEntity:GetGridDirection()
    ---@type LogicEntityService
    local entityService = self._world:GetService("LogicEntity")
    ---@type Entity
    local tmpTeamEntity = entityService:CreateLogicEntity(EntityConfigIDConst.Team)
    tmpTeamEntity:SetGridPosition(teamPos)
    tmpTeamEntity:SetGridDirection(teamRotation)
    local tmpEntitys = {}
    table.insert(tmpEntitys,petEntity)

    tmpTeamEntity:Team():SetTeamPetEntities(tmpEntitys)
    --tmpTeamEntity:SetTeamLeaderPetEntity(teamEntity:GetTeamLeaderPetEntity())
    self._world:Player():SetAddPartnerTempTeam(tmpTeamEntity)
    ---构造一个强化BuffMap 当挂buff的时候判断是否需要修改参数
    self:_DoCreateIntensifyBuffMap(tmpTeamEntity)

    ---设置星灵的被动技能
    --流程
    --1.遍历当前队伍光灵的被动，加buff时只加给新队伍和新光灵（使用标记判断，替换buff目标）
    --2.新光灵加入当前队伍，正常执行新光灵的被动
    self:_DoLogicSetCurPetsPassiveSkill(teamEntity,tmpTeamEntity)
    self._world:Player():SetAddPartnerTempTeam(nil)--恢复buff目标替换
    --伙伴加入队伍
    local team = teamEntity:Team()
    local order = team:GetTeamOrder()
    table.insert(order,petEntity:PetPstID():GetPstID())
    team:SetTeamOrder(order)
    local petEntitys = team:GetTeamPetEntities()
    table.insert(petEntitys,petEntity)
    team:SetTeamPetEntities(petEntitys)
    --执行伙伴的被动
    self:_DoLogicSetNewPetPassiveSkill(teamEntity,tmpTeamEntity)

    ---设置伙伴的强化buff
    self:_DoLogicSetPetIntensifyBuff(tmpTeamEntity)--队伍里只有伙伴

    --词缀等处理
    self._world:Player():SetAddPartnerTempTeam(tmpTeamEntity)--开启buff目标替换
    local GameStartBuffs={}
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    battleService:InitWordBuff(GameStartBuffs)
    battleService:InitTalePetBuff(GameStartBuffs)
    self._world:GetService("Affix"):InitAffixBuff(GameStartBuffs)
    --小秘境圣物
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local allMiniMazeRelicList = battleStatCmpt:GetAllMiniMazeRelicList()
    if allMiniMazeRelicList then
        for _, relicID in ipairs(allMiniMazeRelicList) do
            battleService:ApplyRelic(relicID,false,reApply)
        end
    end

    self._world:Player():SetAddPartnerTempTeam(nil)--恢复buff目标替换

    tmpTeamEntity:Team():SetTeamPetEntities({})
    
    self:UnLoadTmpTeamBuff(tmpTeamEntity)
    self._world:DestroyEntity(tmpTeamEntity)
end
function PartnerServiceLogic:UnLoadTmpTeamBuff(tmpTeamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:RemoveAllBuffInstance(tmpTeamEntity)
end
--处理模块
function PartnerServiceLogic:_CheckFeatureOnPartnerJoin(petEntity)
    ---@type FeatureServiceLogic
    local featureService = self._world:GetService("FeatureLogic")
    if featureService then
        featureService:OnPartnerPetJoinCheckFeature(petEntity)
    end
end

function PartnerServiceLogic:_DoCreateIntensifyBuffMap(tmpTeamEntity)
    local pets = tmpTeamEntity:Team():GetTeamPetEntities()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    for _, petEntity in ipairs(pets) do
        ---@type BuffIntensifyParam[]
        local equipIntensifyParams = petEntity:SkillInfo():GetEquipIntensifyParam()
        if equipIntensifyParams then
            battleStatCmpt:AddBuffIntensifyParam(equipIntensifyParams)
        end
    end
end

--被动技能
function PartnerServiceLogic:_DoLogicSetCurPetsPassiveSkill(teamEntity,tmpTeamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:ReBuildCurrentPetsPassiveSkillToPartner(teamEntity,tmpTeamEntity)
    -- local teamEntities = self._world:Player():GetAllTeamEntities()
    -- for _, teamEntity in ipairs(teamEntities) do
    --     buffLogicService:BuildPetPassiveSkill(teamEntity)
    -- end
end
function PartnerServiceLogic:_DoLogicSetNewPetPassiveSkill(teamEntity,tmpTeamEntity)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:BuildNewPartnerPassiveSkill(teamEntity,tmpTeamEntity)
    -- local teamEntities = self._world:Player():GetAllTeamEntities()
    -- for _, teamEntity in ipairs(teamEntities) do
    --     buffLogicService:BuildPetPassiveSkill(teamEntity)
    -- end
end

function PartnerServiceLogic:_DoLogicSetPetIntensifyBuff(tmpTeamEntity)
    --local teamEntities = self._world:Player():GetAllTeamEntities()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    buffLogicService:BuildPetIntensifyBuff(tmpTeamEntity)
    -- for _, teamEntity in ipairs(teamEntities) do
    --     buffLogicService:BuildPetIntensifyBuff(teamEntity)
    -- end
end
--正在加入伙伴时，替换buff目标
--当前队伍光灵的被动加给伙伴
function PartnerServiceLogic:ReplaceBuffTarget(buffTargetType)
    local isAddingPartner = self._world:Player():IsAddingPartner()
    if isAddingPartner then
        if buffTargetType == BuffTargetType.Team then
            --改为临时队伍
            buffTargetType = BuffTargetType.AddPartnerTmpTeam
        elseif buffTargetType == BuffTargetType.AllPet then
            --改为临时队伍中的pet
            buffTargetType = BuffTargetType.AddPartnerAllPartnerPet
        elseif buffTargetType == BuffTargetType.PetElement then
            --改为临时队伍中的符合元素的pet
            buffTargetType = BuffTargetType.AddPartnerAllPartnerPetElement
        elseif buffTargetType == BuffTargetType.PetJob then
            --改为临时队伍中的符合职业的光灵
            buffTargetType = BuffTargetType.AddPartnerTmpPetJob
        elseif buffTargetType == BuffTargetType.AllTalePet then
            --改为临时队伍中的传说光灵
            buffTargetType = BuffTargetType.AddPartnerTmpAllTalePet
        elseif buffTargetType == BuffTargetType.AllNonTalePet then
            --改为临时队伍中的非传说光灵
            buffTargetType = BuffTargetType.AddPartnerTmpAllNonTalePet
        else
            --其他的都不加
            buffTargetType = BuffTargetType.None
        end
        return buffTargetType
    else
        return buffTargetType
    end
end

function PartnerServiceLogic:_CalcChoosePartner()
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local curWaveIndex = battleStatCmpt:GetCurWaveIndex()
    ---@type LevelConfigData
    local levelConfigData = self._configService:GetLevelConfigData()
    local cfgMiniMazeWave = levelConfigData:GetMiniMazeWaveCfg(curWaveIndex)
    if not cfgMiniMazeWave then
        return
    end
    if not cfgMiniMazeWave.PartnerGroupID then
        return
    end
    local eachGroupCount = 1
    local choosePartners = {}
    for _, partnerGroupID in ipairs(cfgMiniMazeWave.PartnerGroupID) do
        local partnerGroupCfg = Cfg.cfg_mini_maze_partner_group[partnerGroupID]
        if partnerGroupCfg then
            local arr = partnerGroupCfg.PartnerIDArray
            if arr and #arr > 0 then
                local partnerArray = table.cloneconf(arr)
                --筛选 去掉队伍中已有的光灵（及互斥的sp光灵）、去掉前面弃选过的伙伴 
                partnerArray = self:_CalcValidPartnerDepot(partnerArray)

                ---@type RandomServiceLogic
                local randomSvc = self._world:GetService("RandomLogic")
                for i = 1, eachGroupCount do
                    local randomRes = randomSvc:LogicRand(1, #partnerArray)
                    local partnerID = partnerArray[randomRes]
                    table.insert(choosePartners, partnerID)
                end
            end
        end
    end
    if #choosePartners > 0 then
        --记录供选择的伙伴id列表
        ---@type BattleStatComponent
        local battleStateCmpt = self._world:BattleStat()
        battleStateCmpt:SetWaveOptionalPartnerIDList(curWaveIndex,choosePartners)
        return choosePartners
    end
    
end
--过滤可选伙伴
function PartnerServiceLogic:_CalcValidPartnerDepot(groupPartnerArray)
    local partnerArray = groupPartnerArray
    local tmpArr = {}
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local abandonedList = battleStatCmpt:GetAbandonedPartnerIDList()
    if abandonedList then
        for _, partnerID in ipairs(partnerArray) do
            if not table.icontains(abandonedList,partnerID) then
                table.insert(tmpArr,partnerID)
            end
        end
        partnerArray = tmpArr
    end
    --去掉队伍中已有的光灵（及互斥的sp光灵）
    local tmpArr1 = {}
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    local teamPets = teamEntity:Team():GetTeamPetEntities()
    local teamPetTemplateIDList = {}--队伍里的光灵模板ID列表
    local bindPetTemplateIDList = {}--队伍里光灵绑定的光灵ID（如果伙伴的光灵有绑定ID且绑定ID与列表中的一致，则冲突）
    for i, e in ipairs(teamPets) do
        local cPetPstID = e:PetPstID()
        local petTemplateID = cPetPstID:GetTemplateID()
        table.insert(teamPetTemplateIDList,petTemplateID)
        --sp卡互斥
        local petCfg = Cfg.cfg_pet[petTemplateID]
        if petCfg then
            if petCfg.BinderPetID then
                table.insert( bindPetTemplateIDList, petCfg.BinderPetID)
            end
        end
    end
    for _, partnerID in ipairs(partnerArray) do
        local partnerCfg = Cfg.cfg_mini_maze_partner_info[partnerID]
        if partnerCfg then
            local partnerPetID = partnerCfg.PetID
            if not table.icontains(teamPetTemplateIDList,partnerPetID) then
                local partnerPetCfg = Cfg.cfg_pet[partnerPetID]
                if partnerPetCfg then
                    if (not partnerPetCfg.BinderPetID) or (not table.icontains(bindPetTemplateIDList, partnerPetCfg.BinderPetID)) then
                        table.insert(tmpArr1,partnerID)
                    end
                end
            end
        end
    end
    partnerArray = tmpArr1
    return partnerArray
end