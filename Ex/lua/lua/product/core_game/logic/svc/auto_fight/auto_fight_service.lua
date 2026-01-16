--[[
    自动战斗
]]
require("base_service")

_class("AutoSkillCastData", Object)
---@class AutoSkillCastData : Object
AutoSkillCastData = AutoSkillCastData
function AutoSkillCastData:Constructor(pCaster, nSkillID, nPetID, listPickUpPos, selectTeamPos, pickExtraParam)
    self.m_pCaster = pCaster
    self.m_nSkillID = nSkillID
    self.m_nPetID = nPetID
    self.m_listPickUpPos = listPickUpPos
    self.m_listSelectTeamPos = selectTeamPos
    self.m_pickExtraParam = pickExtraParam
end

_class("AutoFightService", BaseService)
---@class AutoFightService:BaseService
AutoFightService = AutoFightService

function AutoFightService:Constructor()
    self._scopeFilterDevice = SkillScopeFilterDevice:New()
    self._lastConvertColor = 0
    self._randPieceColor = false
    self._lastCastSkillPetIds = {}
    self._env = nil
    self._autoMoving = false
    self._castPetTrapSkillPetEntity = nil
    self._castActiveSkillCount = 0 --释放主动技次数（可连续释放主动技的光灵[菲雅]）
    self._usePickCheck = true--打开则在本地主动技点选时进行容错处理

    ---初始化点选策略计算器
    self:RegistPickUpPolicyCalculator()
end

function AutoFightService:Initialize()
    ---@type BoardServiceLogic
    self._boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type BoardServiceRender
    self._boardServiceRender = self._world:GetService("BoardRender")
    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    ---@type BattleService
    self._battleService = self._world:GetService("Battle")
    ---@type UtilDataServiceShare
    self._utilSvc = self._world:GetService("UtilData")
    ---@type UtilScopeCalcServiceShare
    self._utilScopeSvc = self._world:GetService("UtilScopeCalc")
end

function AutoFightService:EnableAutoMove(enabled)
    self._autoMoving = not enabled
end

function AutoFightService:IsRunning()
    return self._autoMoving
end

function AutoFightService:SetCastPetTrapSkillPetEntity(entity)
    self._castPetTrapSkillPetEntity = entity
end
---菲雅点选策略用
function AutoFightService:GetCastActiveSkillCount()
    return self._castActiveSkillCount
end
function AutoFightService:SetCastActiveSkillCount(count)
    self._castActiveSkillCount = count
end
---自动战斗逻辑
---执行一次的效果是释放一个(风船)机关/光灵主动技或进行一次连线
function AutoFightService:AutoFight(TT, teamEntity)
    if self._autoMoving then
        return
    end

    --开始前处理，屏蔽自动按钮响应、构建自动战斗环境（棋盘信息等）
    self:OnAutoFight_Begin(teamEntity)
    if DEBUG_AUTO_FIGHT then
        self:_AutoMovePath(TT, teamEntity)
    else
        self:_DoAutoFight(TT, teamEntity)
    end
    --结束后处理，恢复自动按钮响应、清理自动战斗环境
    self:OnAutoFight_End(teamEntity)
end

---自动战斗功能逻辑
---执行一次的效果是释放一个(风船)机关/光灵主动技或进行一次连线
function AutoFightService:_DoAutoFight(TT)
    local battleService = self._battleService
    
    --主动技瞬移到传送旋涡中开自动的处理
    if self:Handle_PickUpChainSkillTarget(TT) then
        return
    end
    local allMonsterDead = battleService:CheckAllMonstersDead(self._env.TeamEntity)
    if allMonsterDead then --如果战斗结束了就走最长的路径
        self:Handle_MovePath(TT)
        return
    end

    --释放机关技能
    if self:Handle_CastTrapSkill(TT) then
        return
    end

    --释放主动技
    if self._castPetTrapSkillPetEntity then
        if self:Handle_CastPetTrapSkill(TT, self._castPetTrapSkillPetEntity) then
            self._castPetTrapSkillPetEntity = nil
            return
        else
            self._castPetTrapSkillPetEntity = nil
        end
    elseif self:Handle_CastActiveSkill(TT) then
        return
    end

    self:ClearPetActiveSkillTempData()

    --释放光灵召唤的机关技能（主要是处理本回合光灵未释放主动技时，机关需要释放技能）
    if self:Handle_CastPetTrapSkill(TT) then
        return
    end

    --自动连线
    self:Handle_MovePath(TT)
end

---自动战斗开始
function AutoFightService:OnAutoFight_Begin(teamEntity)
    self._autoMoving = true
    --禁用自动战斗按钮
    self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, true)
    self:_BuildMoveEnv(teamEntity)
end

---自动战斗结束
function AutoFightService:OnAutoFight_End()
    self._env = nil --必须置空，否则引导出错
    self._autoMoving = false
    --启用自动战斗按钮
    self._world:EventDispatcher():Dispatch(GameEventType.BanAutoFightBtn, false)
end

---执行自动连线
function AutoFightService:Handle_MovePath(TT)
    return self:_AutoMovePath(TT)
end
function AutoFightService:Handle_PickUpChainSkillTarget(TT)
    if GameStateID.PickUpChainSkillTarget == self:_GetFsmStateID() then
        GameGlobal.EventDispatcher():Dispatch(
        GameEventType.FakeInput,
        {
                ui = "UIChainSkillPreview",
                input = "btnCancelOnClick",
                args = { nil }
            }
        )
        YIELD(TT,1000)
        return true
    end
end

---执行机关技能
function AutoFightService:Handle_CastTrapSkill(TT)
    ---@type AutoSkillCastData
    local pSkillData = self:_FindTrapSkill()
    if nil == pSkillData then
        return
    end
    return self:_CastTrapSkill(TT, pSkillData.m_pCaster, pSkillData.m_nSkillID, pSkillData.m_listPickUpPos)
end

---执行光灵召唤的机关技能
function AutoFightService:Handle_CastPetTrapSkill(TT, petEntity)
    ---@type AutoSkillCastData
    local pSkillData = self:_FindPetTrapSkill(petEntity)
    if nil == pSkillData then
        return
    end
    return self:_CastTrapSkill(TT, pSkillData.m_pCaster, pSkillData.m_nSkillID, pSkillData.m_listPickUpPos)
end

---执行主动技
function AutoFightService:Handle_CastActiveSkill(TT)
    if self:MissionCanCast() == false then
        return
    end
    local t1 = os.clock()
    ---@type AutoSkillCastData
    local pSkillData = self:_FindActiveSkill(TT)
    if nil == pSkillData then
        return
    end
    local t2 = os.clock()
    Log.debug("[AutoFight]FindActiveSkill() use time=", (t2 - t1) * 1000)
    
    
    --模块技能处理
    if self:_IsFeatureSkill(pSkillData.m_nSkillID) then
        self:_CastFeatureSkill(TT,pSkillData)
        self._lastCastSkillPetIds[pSkillData.m_nPetID] = true
    else
        self:_CastActiveSkill(
            TT,
            pSkillData.m_pCaster,
            pSkillData.m_nSkillID,
            pSkillData.m_nPetID,
            pSkillData.m_listPickUpPos,
            pSkillData.m_listSelectTeamPos, --为啥不直接把pSkillData传进去？
            pSkillData.m_pickExtraParam
        )
        self._lastCastSkillPetIds[pSkillData.m_nPetID] = true
    end
    return pSkillData
end
function AutoFightService:_IsFeatureSkill(skillID)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillID)
    if skillConfigData then
        local skillType = skillConfigData:GetSkillType()
        if skillType == SkillType.FeatureSkill then
            return true
        end
    end
    return false
end
function AutoFightService:_IsPersonaSkill(skillID)
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    if lsvcFeature:HasFeatureType(FeatureType.PersonaSkill) then
        local personSkillID = lsvcFeature:GetFeatureSkillID(FeatureType.PersonaSkill)
        if personSkillID == skillID then
            return true
        end
    end
    return false
end
---关卡是否可释放主动技
function AutoFightService:MissionCanCast()
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()
    if enterData:GetMatchType() == MatchType.MT_Mission then
        local currentMissionId = enterData:GetMissionCreateInfo().mission_id
        local current_mission_cfg = Cfg.cfg_mission[currentMissionId]
        if current_mission_cfg == nil then
            return true
        end

        local missionCanCast = current_mission_cfg.CastSkillLimit
        return missionCanCast
    end
    return true
end
function AutoFightService:_TryInsertSkillToSortList(sorted_skills,e,petId,skillId,configService,battleStatCmpt)
    if self._usePickCheck then
        if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
            local curRound = battleStatCmpt:GetLevelTotalRoundCount()
            if self:_CheckLocalCastActiveSkillErrorCurRound(curRound,skillId) then
                return
            end
        end
    end
    local isBuffSetCanNotReady = self._utilSvc:IsBuffSetExtraActiveSkillCanNotReady(petId,skillId)
    if isBuffSetCanNotReady then
        return
    end
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(skillId)

    --需要区别判断主动技的释放条件
    local powerEligibility = false
    if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
        --传说星灵
        local legendPower = e:Attributes():GetAttribute("LegendPower")
        ---@type UtilDataServiceShare
        --最低消耗可能需要计算（仲胥）
        local defaultCost = skillConfigData:GetSkillTriggerParam()
        local minCost = self._utilSvc:CalcMinCostLegendPowerByExtraParam(e,defaultCost,skillConfigData,0,true)
        powerEligibility = legendPower >= minCost
    elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
        local extraParam = skillConfigData:GetSkillTriggerExtraParam()
        local buffEffectType = extraParam.buffEffectType
        ---@type BuffLogicService
        local blsvc = self._world:GetService("BuffLogic")
        local currentVal = blsvc:GetBuffLayer(e, buffEffectType)
        local requiredVal = skillConfigData:GetSkillTriggerParam()
        powerEligibility = currentVal >= requiredVal
    else
        --星灵
        local power = self._utilSvc:GetPetPowerAttr(e,skillId)
        --local power = e:Attributes():GetAttribute("Power")
        powerEligibility = power == 0
    end
    local disWhenIsTeamLeader = false
    --region 特殊条件：对于特殊主动技，宝宝是队长时不能释放
    if self._utilSvc:IsSkillDisabledWhenCasterIsTeamLeader(petId, skillId) then
        if self._utilSvc:IsPetCurrentTeamLeader(petId) then
            disWhenIsTeamLeader = true
        end
    end

    local ready = self._utilSvc:GetPetSkillReadyAttr(e,skillId)

    if not e:HasPetDeadMark() and powerEligibility and ready == 1 and not disWhenIsTeamLeader then
        table.insert(sorted_skills, { e, skillId, petId })
    end
end
---查找是否有主动技
---1、根据能量、cd等筛选可以释放的光灵技能
---2、根据配置优先级排序
---3、顺序遍历技能，根据具体技能判定是否可释放，找到一个可以释放的技能后返回
---   3.1、判定方法中包含对点选的计算
---找到技能，返回结果AutoSkillCastData 包含释放者、技能id、光灵id、计算出的点选列表及点选的附加信息（罗伊）
---未找到技能返回nil
---@return AutoSkillCastData
function AutoFightService:_FindActiveSkill(TT)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local env = self._env
    ---@type Entity
    local teamEntity = env.TeamEntity
    local pickUpType = SkillPickUpType.None
    ---@type BattleStatComponent
    local battleStatCmpt = self._world:BattleStat()
    local curRound = battleStatCmpt:GetLevelTotalRoundCount()
    local sorted_skills = {}
    for i, e in ipairs(teamEntity:Team():GetTeamPetEntities()) do
        local matchPet = e:MatchPet():GetMatchPet()
        local featureList = matchPet:GetFeatureList() or {feature = {}}
        if featureList.feature[FeatureType.Scan] then
            local featureLogicComponent = self._world:GetBoardEntity():LogicFeature()
            local scanActiveSkillType = featureLogicComponent:GetScanActiveSkillType()
            if scanActiveSkillType ~= ScanFeatureActiveSkillType.SummonTrap then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.ScanFeatureSaveInfo, {
                    skillType = ScanFeatureActiveSkillType.SummonTrap
                })
            end
            YIELD(TT, 200)
        end

        local petId = e:PetPstID():GetPstID()
        local isSilence = self._utilSvc:IsSilenceState(petId)
        if isSilence then
            goto CONTINUE
        end
        local isBuffSetCanNotReady = self._utilSvc:IsBuffSetActiveSkillCanNotReady(petId)
        if isBuffSetCanNotReady then
            goto CONTINUE
        end
        local skillId = e:SkillInfo():GetActiveSkillID()
        if not skillId then
            ---@type Pet
            local petData = self._world.BW_WorldInfo:GetPetData(petId)
            skillId = petData:GetPetActiveSkill()
        end
        self:_TryInsertSkillToSortList(sorted_skills,e,petId,skillId,configService,battleStatCmpt)

        local extraSkillList = e:SkillInfo():GetExtraActiveSkillIDList()--附加主动技
        if extraSkillList and (#extraSkillList > 0) then
            for index, extraSkillId in ipairs(extraSkillList) do
                self:_TryInsertSkillToSortList(sorted_skills,e,petId,extraSkillId,configService,battleStatCmpt)
            end
        end
        ::CONTINUE::
    end

    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        --P5合击技 技能cd好了就放，参与光灵主动技优先级排序
        ---@type FeatureServiceLogic
        local lsvcFeature = self._world:GetService("FeatureLogic")
        if lsvcFeature:HasFeatureType(FeatureType.PersonaSkill) then
            local curPower,ready = lsvcFeature:GetFeatureSkillCurPower(FeatureType.PersonaSkill)
            if ready and ready == 1 and curPower == 0 then
                local skillId = lsvcFeature:GetFeatureSkillID(FeatureType.PersonaSkill)
                table.insert(sorted_skills,{nil,skillId,0,FeatureType.PersonaSkill})
            end
        end
        if lsvcFeature:HasFeatureType(FeatureType.MasterSkillRecover) then
            local curPower,ready = lsvcFeature:GetFeatureSkillCurPower(FeatureType.MasterSkillRecover)
            if ready and ready == 1 and curPower == 0 then
                local skillId = lsvcFeature:GetFeatureSkillID(FeatureType.MasterSkillRecover)
                table.insert(sorted_skills,{nil,skillId,0,FeatureType.MasterSkillRecover})
            end
        end
        --空裔技能 点选 cd好了就放 选择离自己最近的非队长属性的格子
        if lsvcFeature:HasFeatureType(FeatureType.MasterSkill) then
            local curPower,ready = lsvcFeature:GetFeatureSkillCurPower(FeatureType.MasterSkill)
            if ready and ready == 1 and curPower == 0 then
                local skillId = lsvcFeature:GetFeatureSkillID(FeatureType.MasterSkill)
                table.insert(sorted_skills,{nil,skillId,0,FeatureType.MasterSkill})
            end
        end
        --卡牌 模块有n个技能，通过选牌释放，需要在这里根据规则筛选出来
        if lsvcFeature:HasFeatureType(FeatureType.Card) then
            local skillId = self:_FindFeatureCardSkillID()
            if skillId then
                table.insert(sorted_skills,{nil,skillId,0,FeatureType.Card})
            end
        end
    end

    --按释放顺序排序[越小优先]
    local svcCfg = self._configService
    table.sort(
        sorted_skills,
        function(a, b)
            local order1 = svcCfg:GetSkillConfigData(a[2]):GetAutoFightSkillOrder()
            local order2 = svcCfg:GetSkillConfigData(b[2]):GetAutoFightSkillOrder()
            if order1 == order2 then
                local teamCmpt = teamEntity:Team()
                local teamIdx1 = teamCmpt:GetTeamIndexByPetPstID(a[3]) or 0--P5合击技处理，没有光灵，同优先级排在光灵技能前
                local teamIdx2 = teamCmpt:GetTeamIndexByPetPstID(b[3]) or 0--P5合击技处理，没有光灵，同优先级排在光灵技能前
                return teamIdx1 < teamIdx2
            end
            return order1 < order2
        end
    )

    local caster = nil
    local skillID = 0
    local petID = 0

    for _, v in ipairs(sorted_skills) do
        local e = v[1]
        local skillId = v[2]
        local petId = v[3]
        --计算技能释放条件是否满足
        -- Log.debug("[AutoFight] Check Active SKill = ", skillId, ", PetID = ", petID)
        ---@type SkillConfigData
        local skillCfgData = svcCfg:GetSkillConfigData(skillId)
        local subSkillList = skillCfgData:GetSubSkillIDList()
        --P5合击技
        if self:_IsFeatureSkill(skillId) then
            if self:_CheckFeatureSkillCondition(TT,e,skillId,env) then
                caster = e
                skillID = skillId
                petID = petId
                break
            end
        else
            if #subSkillList > 0 then
                --子技能相关处理
                if self:_CheckSubSkillCondition(TT, e, subSkillList, env) then
                    caster = e
                    skillID = env.subSkillID
                    petID = petId
                    break
                end
            elseif self:_CheckSkillCondition(TT, e, skillId, env) then
                caster = e
                skillID = skillId
                petID = petId
                break
            end
        end
    end
    if nil == caster and not self:_IsFeatureSkill(skillID) then
        return nil
    end
    return AutoSkillCastData:New(caster, skillID, petID, env.PickUpGridPos, env.SelectTeamPos, env.PickUpExtraParam)
end

---返回主状态机的状态
function AutoFightService:_GetFsmStateID()
    ---@type GameFSMComponent
    local gameFsmCmpt = self._world:GameFSM()
    if gameFsmCmpt then
        return gameFsmCmpt:CurStateID()
    end

    return GameStateID.Invalid
end

---手动释放的机关技能
---目前仅处理了风船机关，新增手动机关技能时需要扩展
---@return AutoSkillCastData
function AutoFightService:_FindTrapSkill()
    --选机关
    local group = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    ---@type Entity
    local caster = nil
    for i, e in ipairs(group:GetEntities()) do
        local power = e:Attributes():GetAttribute("TrapPower") or 0
        ---@type TrapComponent
        local trapComponent = e:Trap()
        local canAutoSkill = (trapComponent:GetCantAutoSkill() == nil or trapComponent:GetCantAutoSkill() == 0)
        if power > 0 and canAutoSkill then
            caster = e
            break
        end
    end

    if nil == caster then
        return
    end

    --选技能
    local skillID = 0
    --风船核心
    if caster and caster:Trap():IsAircraftCore() then
        skillID = self:_FindAircraftCoreSkillID(caster)
        if not self:_CanCastTrapSkill(caster, skillID) then
            return
        end
    end

    --根据回合数释放主动技（N15赛车）
    local env = self._env
    if caster and caster:Trap():IsCastSkillByRound() then
        skillID = self:_FindRoundkillID(caster)
        if not self:_CanCastTrapSkill(caster, skillID, env) then
            return
        end
    end

    return AutoSkillCastData:New(caster, skillID, nil, env.PickUpGridPos, env.SelectTeamPos, env.PickUpExtraParam)
end

---释放光灵召唤的机关技能
---@param petPstID number
---@return AutoSkillCastData
function AutoFightService:_FindPetTrapSkill(petEntity)
    --选机关
    ---@type Entity
    local caster = nil
    ---@type Entity[]
    local petEntityIDList = {}
    if petEntity then
        table.insert(petEntityIDList, petEntity:GetID())
    else
        local pets = self._env.TeamEntity:Team():GetTeamPetEntities()
        for _, petEntity in ipairs(pets) do
            table.insert(petEntityIDList, petEntity:GetID())
        end
    end

    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:Trap():IsPetTrapCastSkill() and e:HasSummoner() then
            local summonEntityID = e:Summoner():GetSummonerEntityID()
            ---@type Entity
            local summonEntity = e:GetSummonerEntity()
            --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
            if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                summonEntityID = summonEntity:GetSuperEntity():GetID()
            end
            if table.icontains(petEntityIDList, summonEntityID) then
                --判定机关是否被覆盖，若被覆盖，则无法释放技能
                local isCovered = false
                local trapPos = e:GetGridPosition()
                if self._utilScopeSvc:IsPosHaveMonsterOrPet(trapPos) then
                    isCovered = true
                end
                local power = e:Attributes():GetAttribute("TrapPower") or 0
                if power > 0 and not isCovered then
                    caster = e
                    break
                end
            end
        end
    end

    if nil == caster then
        return
    end

    --选技能
    local skillID = 0
    skillID = self:_FindQingTongTrapSkillID(caster)
    if not self:_CanCastTrapSkill(caster, skillID) then
        return
    end

    local env = self._env
    return AutoSkillCastData:New(caster, skillID, nil, env.PickUpGridPos, env.SelectTeamPos, env.PickUpExtraParam)
end

---选择风船机关技能
---@param caster Entity
function AutoFightService:_FindAircraftCoreSkillID(caster)
    local skillID = 0
    ---@type TrapComponent
    local trapCmpt = caster:Trap()
    local activeSkillID = trapCmpt:GetActiveSkillID()

    local damageSkillID = activeSkillID[1]
    local healSkillID = activeSkillID[2]
    local shieldSkillID = activeSkillID[3]

    --伤害技能
    local _, targetIds = self:_CalcSkillScopeResultAndTargets(caster, damageSkillID)
    if #targetIds > 0 then
        for i, id in ipairs(targetIds) do
            local e = self._world:GetEntityByID(id)
            local hp = e:Attributes():GetCurrentHP()
            ---这里直接用了原始数据，对么？
            local maxhp = e:Attributes():GetAttribute("MaxHP")
            if hp < maxhp * 0.4 then
                skillID = damageSkillID
                return skillID
            end
        end
    end
    --护盾技能
    local com = caster:BuffComponent()
    if com and not com:HasBuffEffect(BuffEffectType.LayerShield) then
        skillID = shieldSkillID
        return skillID
    end
    --回血技能
    local hp = caster:Attributes():GetCurrentHP()
    ---这里直接用了原始数据，对么？
    local hpMax = caster:Attributes():GetAttribute("MaxHP")
    if hp / hpMax < 0.7 then
        skillID = healSkillID
        return skillID
    end

    return skillID
end

---根据选择机关技能
---@param caster Entity
function AutoFightService:_FindRoundkillID(caster)
    ---@type AttributesComponent
    local attrCmpt = caster:Attributes()
    local curRound = attrCmpt:GetAttribute("CurrentRound")

    ---@type TrapComponent
    local trapCmpt = caster:Trap()
    local activeSkillID = trapCmpt:GetActiveSkillID()

    local skillID = activeSkillID[curRound]
    if not skillID then
        skillID = 0
    end

    return skillID
end

---选择清瞳机关技能
---@param caster Entity
function AutoFightService:_FindQingTongTrapSkillID(caster)
    local skillID = 0
    ---@type TrapComponent
    local trapCmpt = caster:Trap()
    local activeSkillIDs = trapCmpt:GetActiveSkillID()

    local damageSkillID = activeSkillIDs[1] or 0
    local convertSkillID = activeSkillIDs[2] or 0

    --格子属性判断，清瞳使用水格子
    local trapPos = caster:GetGridPosition()
    if PieceType.Blue ~= self._boardServiceLogic:GetPieceType(trapPos) then
        skillID = convertSkillID
    else
        skillID = damageSkillID
    end
    return skillID
end

---是否可以释放机关技能
---判断能量、本回合释放次数
function AutoFightService:_CanCastTrapSkill(caster, skillID, env)
    if skillID <= 0 then
        return false
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local power = caster:Attributes():GetAttribute("TrapPower") or 0
    local count = caster:Attributes():GetAttribute("SkillCount") or 0
    if power >= skillConfigData:GetSkillTriggerParam() and count > 0 then
        -- local oneRoundLimit = caster:Attributes():GetAttribute("OneRoundLimit") or 1
        --策划需求：自动战斗中每回合只能释放一次
        local oneRoundLimit = 1
        local castSkillRound = caster:Attributes():GetAttribute("CastSkillRound")
        ---@type BattleStatComponent
        local battleStatCmpt = self._world:BattleStat()
        local curRound = battleStatCmpt:GetLevelTotalRoundCount()
        for _, round in ipairs(castSkillRound) do
            if round == curRound then
                oneRoundLimit = oneRoundLimit - 1
            end
        end
        if oneRoundLimit > 0 then
            --可以释放，补充释放条件
            local pickUpType = skillConfigData:GetSkillPickType()
            if pickUpType == SkillPickUpType.None then
            elseif pickUpType == SkillPickUpType.Instruction then
                local skillTags = skillConfigData:GetSkillTag()
                --转色技能
                if table.icontains(skillTags, PetSkillTag.FixedPieceColor) then
                    local posList, gridList, tarList, pickUpExtraParam = self:_CalcTrapPickupPosList(caster, skillID)

                    --需要设置pickup组件的参数，否则无法释放主动技
                    env.PickUpGridPos = posList
                    env.PickUpExtraParam = pickUpExtraParam
                end
            end

            return true
        end
    end

    return false
end

---释放机关技能
function AutoFightService:_CastTrapSkill(TT, caster, skillID, pickUpGridPos)
    -- 放技能
    if skillID <= 0 then
        return false
    end
    Log.debug("[AutoFight] CastTrapSkill skillID=", skillID)

    --普通状态，进入预览状态
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UITrapSkillVisible, true, caster:GetID())

    --等待进入大招预览阶段
    while GameStateID.PreviewActiveSkill ~= self:_GetFsmStateID() do
        YIELD(TT, 100)
    end

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.FakeInput,
        {
            ui = "UIWidgetTrapSkill",
            input = "_OnShowSelectSkill",
            args = { skillID }
        }
    )

    YIELD(TT, 500)

    --点击释放
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.FakeInput,
        {
            ui = "UIWidgetTrapSkill",
            input = "btnGoOnClick",
            args = {}
        }
    )

    ---提取boardEntity
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()

    local configSvc = self._configService
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(skillID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    --通知执行主动技
    if pickUpType == SkillPickUpType.None then
    elseif pickUpType == SkillPickUpType.Instruction then
        if pickUpGridPos then
            for i, pos in ipairs(pickUpGridPos) do
                Log.debug("pickup pos ", Vector2.Pos2Index(pos))
                pickUpTargetCmpt:SetPickUpTargetType(pickUpType)
                pickUpTargetCmpt:SetPickUpGridPos(pos)
                pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, -1)
                renderBoardEntity:ReplacePickUpTarget()
                YIELD(TT, 500)
            end
        end

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillConfirm", args = {} }
        )
    end

    YIELD(TT, 500)

    while GameStateID.ActiveSkill ~= self:_GetFsmStateID() do
        YIELD(TT, 100)
    end

    return true
end

--pickExtraParam 黑拳赛 对方罗伊 使用技能，需要在计算格子时附带是否点到了指定机关，在这里设置到消息；本地罗伊在点选中处理
function AutoFightService:_CastActiveSkill(TT, caster, skillID, petID, pickUpGridPos, selectTeamPos, pickExtraParam)
    Log.debug("[AutoFight] CastActiveSkill caster=", caster:GetID(), " skillID=", skillID)

    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        --我方的释放过程
        self:_LocalPlayerCastActiveSkill(TT, caster, skillID, petID, pickUpGridPos, selectTeamPos)
    else
        --敌方的释放过程
        self:_RemotePlayerCastActiveSkill(TT, caster, skillID, petID, pickUpGridPos, selectTeamPos, pickExtraParam)
    end
    --等待主动技开始
    while GameStateID.ActiveSkill ~= self:_GetFsmStateID() do
        if self._localLastCastActiveError then
            break
        end
        if GameStateID.WaitInput == self:_GetFsmStateID() then
            self._localLastCastActiveError = true
            ---@type BattleStatComponent
            local battleStatCmpt = self._world:BattleStat()
            local curRound = battleStatCmpt:GetLevelTotalRoundCount()
            self:_RecordLocalCastActiveSkillError(curRound,skillID)
            break
        end
        YIELD(TT, 100)
    end
end

---本地队伍光灵释放技能
---通过event调用UI的方法，模拟玩家点击ui的操作进行释放
---@param petEntity Entity
function AutoFightService:_LocalPlayerCastActiveSkill(TT, petEntity, skillID, petID, pickUpGridPos, selectTeamPos)
    --local matchPet = petEntity:MatchPet():GetMatchPet()
    --local featureList = matchPet:GetFeatureList() or {feature = {}}
    --if featureList.feature[FeatureType.Scan] then
    --    local featureLogicComponent = self._world:GetBoardEntity():LogicFeature()
    --    local scanActiveSkillType = featureLogicComponent:GetScanActiveSkillType()
    --    if scanActiveSkillType ~= ScanFeatureActiveSkillType.SummonTrap then
    --        GameGlobal.EventDispatcher():Dispatch(GameEventType.ScanFeatureSaveInfo, {
    --            skillType = ScanFeatureActiveSkillType.SummonTrap
    --        })
    --    end
    --end

    --普通状态，进入预览状态
    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 3)
    --等待预览
    while GameStateID.PreviewActiveSkill ~= self:_GetFsmStateID() do
        YIELD(TT, 100)
    end
    YIELD(TT, 500)

    --小秘境（多列头像），点头像前先切换列（如果需要）
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AutoFightCheckSwitchPetColumn, petID)
    YIELD(TT, 100)

    local configSvc = self._configService
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(skillID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()

    ---提取boardEntity
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()

    --通知执行主动技
    if pickUpType == SkillPickUpType.None then
        if selectTeamPos and #selectTeamPos > 0 then
            if skillConfigData:GetAutoFightPickPosPolicy() == PickPosPolicy.PetBonai then
                ---@type Entity
                local eTeam = petEntity:Pet():GetOwnerTeamEntity()
                local petPstID = petEntity:PetPstID():GetPstID()
                local cmd =
                CastSelectTeamOrderPositionCommand.GenerateCommand(eTeam:GetID(), petPstID, selectTeamPos[1])
                self._world:Player():SendCommand(cmd)
            end
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AutoFightCastSkill, skillID, pickUpType, petID)
    elseif pickUpType == SkillPickUpType.LinkLine then
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {
                ui = "UIWidgetBattlePet",
                uiid = self._world.BW_WorldInfo:GetPetData(petID).uiid,
                input = "OnUp",
                args = {}
            }
        )

        YIELD(TT, 1000)
        --如果是多技能，需要点技能图标
        local isMultiSkill, skillIndex = self:_CheckIsMultiActiveSkill(petEntity, skillID)
        if isMultiSkill then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.FakeInput,
                { ui = "UIWidgetPetMultiActiveSkill", input = "SubSkillOnClick", args = { skillIndex } }
            )
            YIELD(TT, 1000)
        end

        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        ---@type PreviewLinkLineService
        local linkLineSvc = self._world:GetService("PreviewLinkLine")
        local showPath = {}
        for i, pos in ipairs(pickUpGridPos) do
            if i == 1 then
                pickUpTargetCmpt:SetPickUpTargetType(pickUpType)
                pickUpTargetCmpt:SetPickUpGridPos(pos)
            end
            table.insert(showPath, pos)

            ---本地立即更新连线
            previewEntity:ReplacePreviewLinkLine(showPath, PieceType.Blue, PieceType.None)
            linkLineSvc:NotifyPickUpTargetChange()

            YIELD(TT, 100)
        end
        
        ---@type LinkageRenderService
        local linkageSvc = self._world:GetService("LinkageRender")
        linkageSvc:DestroyTouchPosEffect()
        
        YIELD(TT, 500)
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillConfirm", args = {} }
        )
    else
        -- GameGlobal.EventDispatcher():Dispatch(
        --     GameEventType.FakeInput,
        --     {
        --         ui = "UIWidgetBattlePet",
        --         uiid = self._world.BW_WorldInfo:GetPetData(petID).uiid,
        --         input = "OnDown",
        --         args = {}
        --     }
        -- )
        -- YIELD_FRAME(TT, 2)

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {
                ui = "UIWidgetBattlePet",
                uiid = self._world.BW_WorldInfo:GetPetData(petID).uiid,
                input = "OnUp",
                args = {}
            }
        )
        YIELD(TT, 1000)
        --如果是多技能，需要点技能图标
        local isMultiSkill,skillIndex = self:_CheckIsMultiActiveSkill(petEntity,skillID)
        if not isMultiSkill then
            --变体 ui复用多技能
            isMultiSkill,skillIndex = self:_CheckIsVariantActiveSkill(petEntity,skillID)
        end
        if isMultiSkill then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.FakeInput,
                { ui = "UIWidgetPetMultiActiveSkill", input = "SubSkillOnClick", args = {skillIndex} }
            )
            YIELD(TT,1000)
        end

        local findPickError = false
        local tryPickCount = #pickUpGridPos
        for i, pos in ipairs(pickUpGridPos) do
            Log.debug("pickup pos ", Vector2.Pos2Index(pos))
            pickUpTargetCmpt:SetPickUpTargetType(pickUpType)
            pickUpTargetCmpt:SetPickUpGridPos(pos)
            pickUpTargetCmpt:SetCurActiveSkillInfo(skillID, petID)
            renderBoardEntity:ReplacePickUpTarget()
            YIELD(TT, 500)
            if self._usePickCheck then
                local curPickEnough = self:_CheckLocalCastActiveSkillPickEnough(i,petEntity,pickUpType)
                if not curPickEnough then
                    findPickError = true
                    break
                end
            end
        end

        YIELD(TT, 500)
        if self._usePickCheck then
            local pickEnough = self:_CheckLocalCastActiveSkillPickEnough(tryPickCount,petEntity,pickUpType)
            local stateError = false
            if GameStateID.WaitInput == self:_GetFsmStateID() then
                stateError = true
            end
            self._localLastCastActiveError = false
            if not stateError then
                if pickEnough and not findPickError then
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.FakeInput,
                        { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillConfirm", args = {} }
                    )
                else
                    Log.error("autofight pick error!!!")
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.FakeInput,
                        { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillCancel", args = {} }
                    )
                    self._localLastCastActiveError = true
                    local errorStep = ActivePickSkillCheckErrorStep.AutoPickOnPickError
                    local errorType = 0
                    if findPickError then
                        errorType = ActivePickSkillCheckErrorType.AutoPickFail
                    elseif not pickEnough then
                        errorType = ActivePickSkillCheckErrorType.AutoPickFail
                    end
                    
                    self:_OnLocalCastActivePickSkillFail(errorStep,errorType,skillID,petEntity,pickUpGridPos)
                end
            else
                self._localLastCastActiveError = true
                local errorStep = ActivePickSkillCheckErrorStep.AutoPickOnStateError
                local errorType = ActivePickSkillCheckErrorType.AutoPickStateError
                self:_OnLocalCastActivePickSkillFail(errorStep,errorType,skillID,petEntity,pickUpGridPos)
            end
            if self._localLastCastActiveError then
                ---@type BattleStatComponent
                local battleStatCmpt = self._world:BattleStat()
                local curRound = battleStatCmpt:GetLevelTotalRoundCount()
                self:_RecordLocalCastActiveSkillError(curRound,skillID)
            end
        else
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.FakeInput,
                { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillConfirm", args = {} }
            )
        end
    end
end
function AutoFightService:_CheckIsMultiActiveSkill(petEntity,skillId)
    local isMultiSkill = false
    local skillIndex = 1
    ---@type SkillInfoComponent
    local skillInfoCmpt = petEntity:SkillInfo()
    local activeSkillID = skillInfoCmpt:GetActiveSkillID()
    local extraSkillList = skillInfoCmpt:GetExtraActiveSkillIDList()
    if extraSkillList and (#extraSkillList > 0) then
        isMultiSkill = true
        if skillId == activeSkillID then
            skillIndex = 1
        else
            for index, extraSkillId in ipairs(extraSkillList) do
                if skillId == extraSkillId then
                    skillIndex = index + 1
                    break
                end
            end
        end
    end
    return isMultiSkill,skillIndex
end
function AutoFightService:_CheckIsVariantActiveSkill(petEntity,skillId)
    local isMultiSkill = false
    local skillIndex = 1
    ---@type SkillInfoComponent
    local skillInfoCmpt = petEntity:SkillInfo()
    local activeSkillID = skillInfoCmpt:GetActiveSkillID()
    local variantSkillInfo = skillInfoCmpt:GetVariantActiveSkillInfo()
    if variantSkillInfo then
        isMultiSkill = true
        if skillId == activeSkillID then
            skillIndex = 1
        else
            local variantSkillList = variantSkillInfo[activeSkillID]
            if variantSkillList then
                for index, variantSkillId in ipairs(variantSkillList) do
                    if skillId == variantSkillId then
                        skillIndex = index + 1
                        break
                    end
                end
            else
            end
        end
    end
    return isMultiSkill,skillIndex
end
function AutoFightService:_CheckLocalCastActiveSkillPickEnough(tryPickCount,petEntity,pickUpType)
    local pickEnough = true
    if petEntity then
        if petEntity:HasPreviewPickUpComponent() then
            ---@type PreviewPickUpComponent
            local previewPickUpComponent = petEntity:PreviewPickUpComponent()
            local ignoreCheck = previewPickUpComponent:IsIgnorePickCheck()
            if ignoreCheck then
                return true
            end
            local pickGrids = previewPickUpComponent:GetAllValidPickUpGridPos()
            local pickGridsCount = #pickGrids
            if pickGridsCount  then
                if pickGridsCount ~= tryPickCount then
                    if pickUpType == SkillPickUpType.PickOnePosAndRotate then--狗兄弟，同一个位置会点多次，但记录只会有一个
                        pickEnough = (pickGridsCount == 1)
                    else
                        pickEnough = false
                    end
                end
            end
        else
            pickEnough = false
        end
    end
    return pickEnough
end
function AutoFightService:_RecordLocalCastActiveSkillError(curRound,skillID)
    if not self._localActiveErrorRecord then
        self._localActiveErrorRecord = {}
    end
    if not self._localActiveErrorRecord[curRound] then
        self._localActiveErrorRecord[curRound] = {}
    end
    local roundReceod = self._localActiveErrorRecord[curRound]
    table.insert(roundReceod,skillID)
end
function AutoFightService:_CheckLocalCastActiveSkillErrorCurRound(curRound,skillID)
    if self._localActiveErrorRecord then
        if self._localActiveErrorRecord[curRound] then
            local roundReceod = self._localActiveErrorRecord[curRound]
            if table.icontains(roundReceod,skillID) then
                return true
            end
        end
    end
    return false
end

function AutoFightService:_RemotePlayerCastActiveSkill(
    TT,
    petEntity,
    skillID,
    petPstID,
    pickUpGridPos,
    selectTeamPos,
    pickExtraParam)
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()

    if pickUpType == SkillPickUpType.None then
        if selectTeamPos and #selectTeamPos > 0 then
            if skillConfigData:GetAutoFightPickPosPolicy() == PickPosPolicy.PetBonai then
                ---@type TeamComponent
                local cTeam = petEntity:Pet():GetOwnerTeamEntity():Team()
                cTeam:SetSelectedTeamOrderPosition(selectTeamPos[1])
            end
        end
        local cmd = CastActiveSkillCommand:New()
        --cmd.EntityID = self._env.TeamEntity:GetID()
        cmd:SetCmdActiveSkillID(skillID)
        cmd:SetCmdCasterPstID(petPstID)
        --self._env.TeamEntity:PushCommand(cmd)
        self._world:Player():SendCommand(cmd)
    else
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = petEntity:PreviewPickUpComponent()
        if not previewPickUpComponent then
            petEntity:AddPreviewPickUpComponent()
            previewPickUpComponent = petEntity:PreviewPickUpComponent()
        end
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
        for i, pos in ipairs(pickUpGridPos) do
            local direction = scopeCalculator:GetDirection(pos, self._env.PlayerPos)
            previewPickUpComponent:AddGridPos(pos)
            previewPickUpComponent:AddDirection(direction, pos)
        end
        previewPickUpComponent:AddPickExtraParamList(pickExtraParam)
        local cmd = CastPickUpActiveSkillCommand:New()
        --cmd.EntityID = self._env.TeamEntity:GetID()
        cmd:SetCmdActiveSkillID(skillID)
        cmd:SetCmdCasterPstID(petPstID)
        cmd:SetCmdPickUpResult(pickUpGridPos)
        cmd:SetPickUpDirectionResult(
            previewPickUpComponent:GetPickUpDirectionPos(),
            previewPickUpComponent:GetAllDirection(),
            previewPickUpComponent:GetLastPickUpDirection()
        )
        cmd:SetReflectDir(previewPickUpComponent:GetReflectDir())
        cmd:SetCmdPickUpExtraParamResult(previewPickUpComponent:GetAllPickExtraParam())
        self._world:Player():SendCommand(cmd)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.EnemyPetCastActiveSkill, petPstID)
end

---计算点选格子
---返回：点选坐标列表，攻击范围列表，目标列表
function AutoFightService:_CalcPickupPosList(TT, petEntity, activeSkillID)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local boardService = self._world:GetService("BoardLogic")
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local skillTags = skillConfigData:GetSkillTag()
    ---@type Vector2[]
    local validGirdList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, petEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    --以防万一，把extraBoard加到invalidGridList中
    for _, extraPos in ipairs(extraBoardPosRange) do
        table.insert(invalidGridList,extraPos)
    end

    --点选策略
    local policy = skillConfigData:GetAutoFightPickPosPolicy()
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    local pickUpType = skillConfigData:GetSkillPickType()
    local casterPos = petEntity:GridLocation().Position
    local casterPosIndex = self:_Pos2Index(casterPos)
    local petColor = petEntity:Element():GetPrimaryType()

    local invalidGridDict = {}
    for _, invalidPos in ipairs(invalidGridList) do
        invalidGridDict[self:_Pos2Index(invalidPos)] = true
    end
    local validPosIdxList = {}
    local validPosList = {}
    for _, validPos in ipairs(validGirdList) do
        local validPosIdx = self:_Pos2Index(validPos)
        if not invalidGridDict[validPosIdx] then
            validPosIdxList[validPosIdx] = true
            validPosList[#validPosList + 1] = validPos
        end
    end

    --出口点选规则
    local levelPolicy = self._env.LevelPolicy
    if levelPolicy == LevelPosPolicy.GotoExitPos and table.icontains(skillTags, PetSkillTag.Transport) and
            self._env.ExitPos
    then
        local targetPos = nil --如果传送点比玩家位置都远就不传送了
        local exitPos = self._env.ExitPos
        local neareastDistance = (casterPos.x - exitPos.x) ^ 2 + (casterPos.y - exitPos.y) ^ 2
        for i, pos in ipairs(validPosList) do
            local dis = (pos.x - exitPos.x) ^ 2 + (pos.y - exitPos.y) ^ 2
            if dis < neareastDistance then
                neareastDistance = dis
                targetPos = pos
            end
        end
        return { targetPos }, {}, {}
    end

    --结果
    --点选策略处理
    local pickPosList,attackPosList,targetIdList,extraParam = self:CalcPickUpByPolicy(TT,petEntity,activeSkillID,policy,policyParam)
    if pickPosList then
        return pickPosList,attackPosList,targetIdList,extraParam
    else
        return {},{},{}
    end
end

---计算机关的点选格子
---返回：点选坐标列表，攻击范围列表，目标列表
function AutoFightService:_CalcTrapPickupPosList(trapEntity, activeSkillID)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local boardService = self._world:GetService("BoardLogic")
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local skillTags = skillConfigData:GetSkillTag()
    ---@type Vector2[]
    local validGirdList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpValidScopeList, trapEntity)
    ---@type Vector2[]
    local invalidGridList = utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, trapEntity)

    ---可点选的数量
    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    local pickUpType = skillConfigData:GetSkillPickType()
    local petColor = 0

    local invalidGridDict = {}
    for _, invalidPos in ipairs(invalidGridList) do
        invalidGridDict[self:_Pos2Index(invalidPos)] = true
    end
    local validPosIdxList = {}
    local validPosList = {}
    for _, validPos in ipairs(validGirdList) do
        local validPosIdx = self:_Pos2Index(validPos)
        if not invalidGridDict[validPosIdx] then
            validPosIdxList[validPosIdx] = true
            validPosList[#validPosList + 1] = validPos
        end
    end

    ---@type Entity
    local teamEntity = self._env.TeamEntity
    local casterPos = teamEntity:GridLocation().Position

    --结果
    local pickPosList = {} --点选格子
    local targetIdList = {} --攻击目标
    local attackPosList = {} --攻击范围

    --现在只有一种机关会点选，这里使用距离队伍最近的点，
    local posList, attackPosList, targetIdList =
    self:_CalPickPosPolicy_NearestPos(trapEntity, activeSkillID, casterPos, validPosIdxList, pickUpNum, petColor)
    return posList, attackPosList, targetIdList
end

--点选格子颜色
function AutoFightService:_CalcPickUpColor(petEntity, activeSkillID, validGirdList)
    local env = self._env
    local results = {}
    local selectedColor = {}
    for _, pos in ipairs(validGirdList) do
        local posIdx = self:_Pos2Index(pos)
        local color = env.BoardPosPieces[posIdx]
        if not selectedColor[color] then
            selectedColor[color] = true
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
            end
        end
    end

    return results
end

--点选n个位置并以其为中心计算范围
function AutoFightService:_CalcPickUpPosAndRange(petEntity, activeSkillID, validGirdList)
    local env = self._env
    local results = {}

    --随机点选位置
    table.shuffle(validGirdList)
    for _, pos in ipairs(validGirdList) do
        local posIdx = self:_Pos2Index(pos)
        if env.BoardPosPieces[posIdx] then
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
            end
        end
    end

    return results
end

--点选单位位置1，传送到点选位置2
function AutoFightService:_CalcPickUpPosAndTeleport(petEntity, activeSkillID, validGirdList)
    local env = self._env

    local results = {}
    --随机点选位置
    table.shuffle(validGirdList)
    local playerPosIdx = self:_Pos2Index(env.PlayerPos)
    --第一个点
    local firstPickUpPos = validGirdList[1]
    if not firstPickUpPos then
        return results
    end

    local secondPos
    local battleSvc = self._world:GetService("Battle")
        
    --第二个点写死，离我最近的空格子
    local connect = env.ConnectMap[playerPosIdx]
    for i = 1, 8 do
        local posIdx = connect[i]
        if posIdx then
            local pos = self:_Index2Pos(posIdx)
            if pos then
                local targetEntityList = battleSvc:FindMonsterEntityInPos(pos)
                if #targetEntityList == 0 and (firstPickUpPos ~= pos) then--且没有怪
                    secondPos = self:_Index2Pos(posIdx)
                    break
                end
            end
        end
    end
    if secondPos then
        table.insert(results, { firstPickUpPos, { 1 }, { firstPickUpPos }, secondPos })
    end
    return results
end

--施法者位置为起点点选方向
function AutoFightService:_CalcPickUpDirection(petEntity, activeSkillID, validGirdList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    --随机点选位置
    table.shuffle(validGirdList)

    local selectedDirection = {}
    for _, pos in ipairs(validGirdList) do
        local posIdx = self:_Pos2Index(pos)
        local direction = scopeCalculator:GetDirection(pos, casterPos)
        if table.icontains(selectedDirection, direction) then
            --方向不变不计算
        elseif env.BoardPosPieces[posIdx] then
            table.insert(selectedDirection, direction)
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
            end
        end
    end

    return results
end

--点选第一个点为基础，点选第二个方向
function AutoFightService:_CalcPickUpPosAndDirection(petEntity, activeSkillID, validGirdList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    --随机点选位置
    table.shuffle(validGirdList)

    --第一个点
    for _, firstPickUpPos in ipairs(validGirdList) do
        --第二个点写死的四个方向,选中点为中心的周围4个方向的点
        local directionGridList = {}
        table.insert(directionGridList, Vector2(firstPickUpPos.x + 0, firstPickUpPos.y + 1))
        table.insert(directionGridList, Vector2(firstPickUpPos.x + 1, firstPickUpPos.y + 0))
        table.insert(directionGridList, Vector2(firstPickUpPos.x + 0, firstPickUpPos.y - 1))
        table.insert(directionGridList, Vector2(firstPickUpPos.x - 1, firstPickUpPos.y + 0))

        for _, secondPos in ipairs(directionGridList) do
            local posIdx = self:_Pos2Index(secondPos)
            if env.BoardPosPieces[posIdx] then
                local scope_result, target_ids =
                self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, { firstPickUpPos, secondPos })
                --目标数量
                if #target_ids > 0 then
                    table.insert(results, { firstPickUpPos, target_ids, scope_result:GetAttackRange(), secondPos })
                end
            end
        end
    end

    return results
end

---@param centerPos Vector2
---@param dir Vector2
local function GetTwoSideOffset(centerPos, dir)
    local ret = {}

    if dir.x ~= 0 then
        table.insert(ret, Vector2(centerPos.x, centerPos.y + 1))
        table.insert(ret, Vector2(centerPos.x, centerPos.y - 1))
    elseif dir.y ~= 0 then
        table.insert(ret, Vector2(centerPos.x + 1, centerPos.y))
        table.insert(ret, Vector2(centerPos.x - 1, centerPos.y))
    end
    return ret
end

--点选第一个点为主方向，点选第二个方向
function AutoFightService:_CalcPickUpLineAndDirection(petEntity, activeSkillID, validGirdList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    --随机点选位置
    table.shuffle(validGirdList)

    --第一个点（十字方向）
    for _, firstPickUpPos in ipairs(validGirdList) do
        --第二个点 为主方向的两侧
        local directionGridList = {}
        local mainDir = firstPickUpPos - casterPos
        local sidePos = GetTwoSideOffset(firstPickUpPos, mainDir)
        for _, sideGrid in ipairs(sidePos) do
            table.insert(directionGridList, sideGrid)
        end

        for _, secondPos in ipairs(directionGridList) do
            local posIdx = self:_Pos2Index(secondPos)
            if env.BoardPosPieces[posIdx] then
                local scope_result, target_ids =
                self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, { firstPickUpPos, secondPos })
                --目标数量
                if #target_ids > 0 then
                    table.insert(results, { firstPickUpPos, target_ids, scope_result:GetAttackRange(), secondPos })
                end
            end
        end
    end

    return results
end

---SkillPickUpType.PickOnePosAndRotate 点选类型的计算
---（狗兄弟）
---@param petEntity Entity
function AutoFightService:_CalcPickUpPosAndRotate(petEntity, activeSkillID, validGirdList, dirCount)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    --随机点选位置
    table.shuffle(validGirdList)
    petEntity:AddPreviewPickUpComponent()
    local pickUpCmpt = petEntity:PreviewPickUpComponent()
    local dirs = { 1, 2 } --ReflectDirectionType
    if dirCount == 4 then
        dirs[3] = 3
        dirs[4] = 4
    end
    --第一个点
    for _, dir in ipairs(dirs) do
        pickUpCmpt:SetReflectDir(dir)
        for _, pickUpPos in ipairs(validGirdList) do
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickUpPos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pickUpPos, target_ids, scope_result:GetAttackRange(), dir })
                return results --策划说打到人就行
            end
        end
    end

    return results
end

--露比主动技 点脚下切换推拉，auto不处理 点周围一圈是选择方向（分十字方向和斜向）切换技能范围
---@param petEntity Entity
function AutoFightService:_CalcPickUpSwitch(petEntity, activeSkillID, validGridList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    local pickDirPos = {}
    if validGridList then
        for _, gridPos in ipairs(validGridList) do
            local hitBackDirType = scopeCalculator:GetDirection(gridPos, casterPos)
            local pickDirType = PickDirTypeForScope.NONE
            if hitBackDirType then
                if self:_IsCrossDir(hitBackDirType) then
                    pickDirType = PickDirTypeForScope.CROSS
                    pickDirPos[pickDirType] = { hitBackDirType, gridPos }
                elseif self:_IsXDir(hitBackDirType) then
                    pickDirType = PickDirTypeForScope.XSHAPE
                    pickDirPos[pickDirType] = { hitBackDirType, gridPos }
                else
                    pickDirType = PickDirTypeForScope.NONE
                end
            else
                pickDirType = scopeParam.defaultDirType
            end
        end
    end
    petEntity:AddPreviewPickUpComponent()
    ---@type PreviewPickUpComponent
    local pickUpCmpt = petEntity:PreviewPickUpComponent()
    ---@type HitBackDirectionType
    local dirs = { 2, 3 }
    for dirType, record in pairs(pickDirPos) do --不能改ipairs
        pickUpCmpt:AddDirection(record[1], record[2])
        local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, casterPos)
        --目标数量
        if #target_ids > 0 then
            table.insert(results, { record[2], target_ids, scope_result:GetAttackRange() })
        end
    end
    return results
end

function AutoFightService:_CalcPickUpPosAndRange(petEntity, activeSkillID, validGirdList)
    local env = self._env
    local results = {}

    --随机点选位置
    table.shuffle(validGirdList)
    for _, pos in ipairs(validGirdList) do
        local posIdx = self:_Pos2Index(pos)
        if env.BoardPosPieces[posIdx] then
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
            end
        end
    end

    return results
end

function AutoFightService:_IsCrossDir(dirType)
    if dirType == HitBackDirectionType.Down or dirType == HitBackDirectionType.Up or
        dirType == HitBackDirectionType.Left or
        dirType == HitBackDirectionType.Right
    then
        return true
    end
    return false
end

function AutoFightService:_IsXDir(dirType)
    if dirType == HitBackDirectionType.RightUp or dirType == HitBackDirectionType.RightDown or
        dirType == HitBackDirectionType.LeftUp or
        dirType == HitBackDirectionType.LeftDown
    then
        return true
    end
    return false
end

--计算技能范围
function AutoFightService:_CalcSkillScopeResult(
    petEntity,
    skillConfigData,
    scopeType,
    scopeParam,
    centerType,
    targetType,
    centerPos)
    local playerBodyArea = petEntity:BodyArea():GetArea()
    local casterDir = petEntity:GridLocation():GetGridDir()
    local casterPos = petEntity:GridLocation().Position
    if not centerPos then
        centerPos = casterPos
    end

    --随机范围改为全屏范围，防止计算随机数导致不同步
    if IsRandomSkillScopeType(scopeType) then
        scopeType = SkillScopeType.FullScreen
    end
    local scopeCalculator = self._utilScopeSvc:GetSkillScopeCalc()

    --先找技能中心点
    ---@type SkillScopeResult
    local result =
    scopeCalculator:ComputeScopeRange(
        scopeType,
        scopeParam,
        centerPos,
        playerBodyArea,
        casterDir,
        targetType,
        casterPos,
        petEntity
    )

    local filterPassParam =
    SkillScopeFilterPassParam:New(
        {
            casterPos = casterPos,
            casterBodyAreaArray = playerBodyArea,
            world = self._world
        }
    )

    self._scopeFilterDevice:DoFilter(result, skillConfigData:GetScopeFilterParam(), filterPassParam)
    return result
end

--计算技能范围和目标
function AutoFightService:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, centerPos)
    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    ---@type SkillScopeType
    local scopeType = skillConfigData:GetSkillScopeType()
    local scopeParam = skillConfigData:GetSkillScopeParam()
    local centerType = skillConfigData:GetSkillScopeCenterType()
    local targetType = skillConfigData:GetSkillTargetType()

    --替换技能范围
    local skillScopeAndTarget = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    if skillScopeAndTarget and
            ( skillScopeAndTarget.useType == AutoFightScopeUseType.Replace or
                    skillScopeAndTarget.useType == AutoFightScopeUseType.ReplaceTargetAndTrapCount)  then
        scopeType = skillScopeAndTarget.scopeType
        scopeParam = skillScopeAndTarget.scopeParam
        centerType = skillScopeAndTarget.centerType
        targetType = skillScopeAndTarget.targetType
    end

    --选board改成选怪物，否则选出来的target是board
    if targetType == SkillTargetType.Board then
        targetType = SkillTargetType.Monster
    end

    --技能范围
    local result =
    self:_CalcSkillScopeResult(petEntity, skillConfigData, scopeType, scopeParam, centerType, targetType, centerPos)
    --选技能目标
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local targetIds = targetSelector:DoSelectSkillTarget(petEntity, targetType, result, activeSkillID)

    --排除魔免怪物
    for i = #targetIds, 1, -1 do
        local targetID = targetIds[i]
        local targetEntity = self._world:GetEntityByID(targetID)
        if targetEntity and targetEntity:HasBuff() and not buffLogicSvc:CheckCanBeMagicAttack(petEntity, targetEntity) then
            table.remove(targetIds, i)
        end
    end
    if skillScopeAndTarget and skillScopeAndTarget.useType == AutoFightScopeUseType.ReplaceTargetAndTrapCount then
        local trapID = skillScopeAndTarget.trapID
        local count = skillScopeAndTarget.trapCount
        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        local trapPosList = trapSvc:FindTrapPosByTrapID(trapID)
        if #trapPosList<count then
            targetIds={}
        end
    end
    return result, targetIds
end

--检查技能释放条件是否满足
--[[
    "释放条件说明：
    随机洗版/倾向型洗版：需要技能计算范围内的主元素格子少于整体的35%时才释放。
    如果有一条至少6格的通路，能攻击到至少2个敌人或1个Boss敌人，并且通路颜色允许队伍中至少2个光灵出战，则不释放技能。
    无损洗版/定向转色：至少有1个可以转色的格子。
    伤害：需要技能至少能作用到1个敌人。
    治疗：需要队伍血量低于90%。[可配]
    格子数下限：需要技能计算范围内的主属性格子数大于等于X%。（微丝）
    格子数上限：需要技能计算范围内的主属性格子数小于等于X%。
    CD积攒上限：如果技能CD完成，并且已经积攒X回合了，则本回合跳过的释放条件，直接释放（对洗版和转色无效）。
    释放方法说明：
    直接释放：无特殊的释放方法，直接释放技能，或随机一个点/方向释放技能。
    选择作用点：选择技能范围内作用敌人格子数最多的点或者从自身出发的某方向，视技能而定选择的数量和类型
    选择最近点：选择自己周围最近的N个非主属性点，视技能而定选择的数量
    原地释放：选择格子的技能，选择光灵脚下的格子
    不释放：自动战斗时不会释放此技能。"
--]]
function AutoFightService:_CheckSkillCondition(TT, caster, skillID, env)
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local condition = skillConfigData:GetAutoFightCondition()
    local skillScopeAndTarget = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    ---@type SkillScopeType
    local scopeType = skillConfigData:GetSkillScopeType()
    local skillTags = skillConfigData:GetSkillTag()
    local pickUpType = skillConfigData:GetSkillPickType()
    local petColor = caster:Element():GetPrimaryType()
    env.MVP = nil
    ---@type Entity
    local teamEntity = self._env.TeamEntity

    --随机洗板
    if table.icontains(skillTags, PetSkillTag.RandPieceColor) then
        if self._randPieceColor or self._lastConvertColor > 0 then
            return false
        end
    end

    --转色技能的颜色都是星灵主属性的颜色
    if table.icontains(skillTags, PetSkillTag.FixedPieceColor) then
        if self._randPieceColor then
            return false
        end
        --同一回合的转色不能冲突
        if self._lastConvertColor > 0 and self._lastConvertColor ~= petColor then
            return false
        end
    end

    local attackTargetCnt = 0
    local attackGridCnt = 0
    local gridColorCnt = {}
    local posList = {}
    local gridList = {}
    local tarList = {}
    local pickUpExtraParam = {}
    if pickUpType == SkillPickUpType.None then
        local result, targetIds = self:_CalcSkillScopeResultAndTargets(caster, skillID)
        attackTargetCnt = #targetIds
        gridList = result:GetAttackRange()
        attackGridCnt = #gridList
        --技能范围内的各种颜色格子计数
        for _, pos in ipairs(result:GetWholeGridRange()) do
            local posIdx = self:_Pos2Index(pos)
            local pieceType = env.BoardPosPieces[posIdx]
            if pieceType then
                gridColorCnt[pieceType] = (gridColorCnt[pieceType] or 0) + 1
            end
        end
        -- 主动技通过UI选定一个光灵位置，这个需求有别于我们的Pickup（格子点选）自成一派，因为是单独光灵的专属需求，为改动更小，沿用了SkillPickUpType.None
        local policy = skillConfigData:GetAutoFightPickPosPolicy()
        if policy == PickPosPolicy.PetBonai then
            env.SelectTeamPos = { 1 }
        end
    else
        local t1 = os.clock()
        posList, gridList, tarList, pickUpExtraParam = self:_CalcPickupPosList(TT, caster, skillID)
        local t2 = os.clock()
        Log.debug("[AutoFight]_CalcPickupPosList() use time=", (t2 - t1) * 1000, " skillID=", skillID)
        --点选失败
        if #posList == 0 then
            return false
        end

        attackGridCnt = #gridList
        attackTargetCnt = #tarList
        --需要设置pickup组件的参数，否则无法释放主动技
        env.PickUpGridPos = posList
        env.PickUpExtraParam = pickUpExtraParam
    end

    --出口点点选
    if self._env.LevelPolicy == LevelPosPolicy.GotoExitPos and table.icontains(skillTags, PetSkillTag.Transport) and
        self._env.ExitPos
    then
        return true
    end

    --伤害：需要技能至少能作用到1个敌人
    if table.icontains(skillTags, PetSkillTag.Attack) and attackTargetCnt == 0 then
        return false
    end

    --转色：至少有一个可转色的格子
    if table.icontains(skillTags, PetSkillTag.FixedPieceColor) and attackGridCnt == 0 then
        return false
    end

    --[[
        AlwaysFalse 条件为假
        AlwaysTrue 真
        PlayerHP 玩家血量百分比
        MonsterMinHP 怪物最小血量百分比
        MonsterMaxHP 怪物最大血量百分比
        AttackGrid 技能命中格子数
        AttackTarget 技能命中目标数
        PowerfullRound 大招积攒回合数
        ScopeGridCount 技能范围内某颜色格子数
        ChainPathEvalue 路径评估值
        NotTeamLeader 不是队长时释放
        SanHPPercent san值+san值抵扣HP百分比
    --]]
    local checkResult = true
    if condition then
        for k, v in pairs(condition.conds) do
            if k == "AlwaysFalse" then
                condition.conds[k] = "false"
            elseif k == "AlwaysTrue" then
                condition.conds[k] = "true"
            elseif k == "PlayerHP" then --玩家血量百分比
                local playerHP = teamEntity:Attributes():GetCurrentHP()
                ---这里直接用了原始数据，对么？
                local maxHP = teamEntity:Attributes():CalcMaxHp()
                --condition.conds[k] = playerHP / maxHP --秘境里，team属性的当前生命值可能不对
                ---@type CalcDamageService
                local lsvcCalcDamage = self._world:GetService("CalcDamage")
                local teamHP, teamMaxHP = lsvcCalcDamage:GetTeamLogicHP(teamEntity)
                condition.conds[k] = teamHP / teamMaxHP
            elseif k == "MonsterMinHP" or k == "MonsterMaxHP" then --怪物血量百分比
                local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
                local minblood = 1
                local maxblood = 0
                for i, e in ipairs(group:GetEntities()) do
                    local hp = e:Attributes():GetCurrentHP()
                    local maxhp = e:Attributes():CalcMaxHp()
                    local p = hp / maxhp
                    if p < minblood then
                        minblood = p
                    end
                    if p > maxblood then
                        maxblood = p
                    end
                end
                condition.conds["MonsterMinHP"] = minblood
                condition.conds["MonsterMaxHP"] = maxblood
            elseif k == "AttackGrid" then --技能命中格子数
                condition.conds[k] = attackGridCnt
            elseif k == "AttackTarget" then --技能命中怪物数
                condition.conds[k] = attackTargetCnt
            elseif k == "PowerfullRound" then --大招积攒回合数
                condition.conds[k] = teamEntity:ActiveSkill():GetPowerfullRoundCount(caster:GetID()) or 0
            elseif k == "ScopeGridCount" then --技能范围内主属性格子数
                --技能范围可能有特殊处理，目前微丝是独立范围算格子数
                if skillScopeAndTarget and skillScopeAndTarget.scopeType then
                    local effScopeResult =
                    self:_CalcSkillScopeResult(
                        caster,
                        skillConfigData,
                        skillScopeAndTarget.scopeType,
                        skillScopeAndTarget.scopeParam,
                        skillScopeAndTarget.centerType,
                        skillScopeAndTarget.targetType
                    )
                    gridColorCnt = {}
                    --技能范围内的各种颜色格子计数
                    for _, pos in ipairs(effScopeResult:GetAttackRange()) do
                        local posIdx = self:_Pos2Index(pos)
                        local pieceType = env.BoardPosPieces[posIdx]
                        if pieceType then
                            gridColorCnt[pieceType] = (gridColorCnt[pieceType] or 0) + 1
                        end
                    end
                end
                condition.conds[k] = gridColorCnt[petColor] or 0
            elseif k == "ChainPathEvalue" then --路径评估值
                --路径评估
                local chainPath, pieceType, evalue = self:GetAutoChainPath(TT, teamEntity)
                condition.conds[k] = evalue
            elseif k == "NotTeamLeader" then
                local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
                condition.conds[k] = (teamLeaderEntity:GetID() ~= caster:GetID()) and ("true") or ("false")
            elseif k == "SanHPPercent" then
                ---@type FeatureServiceLogic
                local lsvcFeature = self._world:GetService("FeatureLogic")
                ---@type FeatureSanActiveSkillCanCastContext
                local context = {}
                context.scopeGridCount = #gridList
                if not lsvcFeature:IsActiveSkillCanCast(caster, skillID, context) then
                    condition.conds[k] = 0
                else
                    local requireSanVal, requireHPPercent = lsvcFeature:CalcActiveSkillSanCost(caster, skillID, context)
                    local currentVal = lsvcFeature:GetSanValue()
                    if currentVal >= requireSanVal and requireHPPercent == 0 then
                        condition.conds[k] = 1--如果san值本来就够用，这里设置成1是让这条判定通过的
                    else
                        ---@type CalcDamageService
                        local lsvcCalcDamage = self._world:GetService("CalcDamage")
                        local teamHP, teamMaxHP = lsvcCalcDamage:GetTeamLogicHP(teamEntity)
                        local percent = (teamHP - teamMaxHP * requireHPPercent) / teamMaxHP
                        condition.conds[k] = percent
                    end
                end
            elseif k == "CheckJiero" then
                --例：CheckJiero<5
                condition.conds[k] = self:_CheckCondition_PetJiero()
            elseif k == "CheckLingEn" then
                --例：CheckLingEn<1
                condition.conds[k] = self:_CheckCondition_PetLingEn(caster, skillID)
            elseif k == "CheckLegendEnergy" then
                --例：CheckLegendEnergy>10
                condition.conds[k] = self:_CheckCondition_LegendEnergy(caster)
            elseif k == "PetHP" then --施法者光灵血量百分比--秘境需要
                local petHP = caster:Attributes():GetCurrentHP()
                local petMaxHP = caster:Attributes():CalcMaxHp()
                condition.conds[k] = petHP / petMaxHP
            end
        end
        checkResult = condition:callback()
    end

    --条件检查
    if not checkResult then
        return false
    end

    --随机洗板
    if table.icontains(skillTags, PetSkillTag.RandPieceColor) then
        self._randPieceColor = true
        env.MVP = nil
    end

    --转色技能记录
    if table.icontains(skillTags, PetSkillTag.FixedPieceColor) then
        self._lastConvertColor = petColor
        env.MVP = nil
    end

    return true
end
--模块技能
function AutoFightService:_CheckFeatureSkillCondition(TT, caster, skillID, env)
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local condition = skillConfigData:GetAutoFightCondition()
    local skillScopeAndTarget = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    ---@type SkillScopeType
    local scopeType = skillConfigData:GetSkillScopeType()
    local skillTags = skillConfigData:GetSkillTag()
    local pickUpType = skillConfigData:GetSkillPickType()
    local triggerExtraParam = skillConfigData:GetSkillTriggerExtraParam()
    env.MVP = nil
    ---@type Entity
    local teamEntity = self._env.TeamEntity
    local attackTargetCnt = 0
    local attackGridCnt = 0
    local gridColorCnt = {}

    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")

    local posList = {}
    local gridList = {}
    local tarList = {}
    local pickUpExtraParam = {}
    local featureType = FeatureType.PersonaSkill
    if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType] then
        featureType = triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType]
    end
    if FeatureType.PersonaSkill == featureType then
        return true
    elseif FeatureType.MasterSkillRecover == featureType then
        return true
    elseif FeatureType.MasterSkill == featureType then
        --空裔技能 点选 cd好了就放 选择离自己最近的非队长属性的格子
        caster = lsvcFeature:GetFeatureSkillHolderEntity(featureType)
        posList, gridList, tarList, pickUpExtraParam = self:_CalcPickupPosList(TT, caster, skillID)
        --点选失败
        if #posList == 0 then
            return false
        end

        attackGridCnt = #gridList
        attackTargetCnt = #tarList
        --需要设置pickup组件的参数，否则无法释放主动技
        env.PickUpGridPos = posList
        env.PickUpExtraParam = pickUpExtraParam
    elseif FeatureType.Card == featureType then
        return true
    end
    return true
end
---希诺普：第一个点找最近的非绿色格，第二个点找点选范围中非绿色格 （可点选范围随点击数量变化）
---希诺普点选大致流程：
---     全图范围内点选一格，点选后可点选范围变化（如变为第一个点选格的十字范围内）
---     在新范围内点击第二个点，这两个点之间组成的矩形为技能范围
---第一个点没找到则取消，第二个点找不到非绿色格子时默认用二阶段可点击坐标的第一个位置
function AutoFightService:_CalPickPosPolicyPetXiNuoPu(petEntity, activeSkillID, casterPos)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local scopeParamList = skillConfigData._pickUpValidScopeList
    local casterPosIndex = self:_Pos2Index(casterPos)

    local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}
    --根据已点选数量 取不同范围
    if #scopeParamList > 0 then
        local totalScopeParam = scopeParamList[1]
        if totalScopeParam:GetScopeType() == SkillScopeType.ScopeByPickNum then
            local subScopeParamList = totalScopeParam:GetScopeParamData()
            if subScopeParamList then
                --第一个点 找最近的非绿色格子
                local subParam = subScopeParamList[1]
                ---技能范围
                ---@type SkillPreviewScopeParam
                local validScopeParam =
                SkillPreviewScopeParam:New(
                    {
                        TargetType = subParam.targetType,
                        ScopeType = subParam.scopeType,
                        ScopeCenterType = subParam.scopeCenterType,
                        TargetTypeParam = subParam.targetTypeParam
                    }
                )
                validScopeParam:SetScopeParamData(subParam.scopeParam)

                local validGirdList = utilScopeSvc:BuildScopeGridList({ validScopeParam }, petEntity)
                local invalidGridList =
                utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)
                local invalidGridDict = {}
                for _, invalidPos in ipairs(invalidGridList) do
                    invalidGridDict[self:_Pos2Index(invalidPos)] = true
                end
                local validPosIdxList = {}
                local validPosList = {}
                for _, validPos in ipairs(validGirdList) do
                    local validPosIdx = self:_Pos2Index(validPos)
                    if not invalidGridDict[validPosIdx] then
                        validPosIdxList[validPosIdx] = true
                        validPosList[#validPosList + 1] = validPos
                    end
                end
                local firstPickPos
                for _, off in ipairs(ringMax) do
                    local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
                    if validPosIdxList[posIdx] then
                        local pos = self:_Index2Pos(posIdx)
                        local color = env.BoardPosPieces[posIdx]
                        if color and color ~= PieceType.Green then
                            firstPickPos = pos
                            break
                        end
                    end
                end
                if firstPickPos then
                    --第二个点 在已选择一个点后的有效范围内找非绿色点
                    subParam = subScopeParamList[2]
                    ---技能范围
                    local validScopeParam =
                    SkillPreviewScopeParam:New(
                        {
                            TargetType = subParam.targetType,
                            ScopeType = subParam.scopeType,
                            ScopeCenterType = subParam.scopeCenterType,
                            TargetTypeParam = subParam.targetTypeParam
                        }
                    )
                    validScopeParam:SetScopeParamData(subParam.scopeParam)
                    validGirdList = utilScopeSvc:BuildScopeGridListMultiPick({ validScopeParam }, petEntity, { firstPickPos })
                    local validPosIdxList = {}
                    local validPosList = {}
                    for _, validPos in ipairs(validGirdList) do
                        local validPosIdx = self:_Pos2Index(validPos)
                        if not invalidGridDict[validPosIdx] then
                            validPosIdxList[validPosIdx] = true
                            validPosList[#validPosList + 1] = validPos
                        end
                    end
                    local secondPickPos
                    for _, pos in ipairs(validPosList) do
                        if firstPickPos ~= pos then
                            if not secondPickPos then
                                secondPickPos = pos
                            end
                            local posIdx = self:_Pos2Index(pos)
                            local color = env.BoardPosPieces[posIdx]
                            if color and color ~= PieceType.Green then
                                secondPickPos = pos
                                break
                            end
                        end
                    end
                    if secondPickPos then
                        table.insert(pickPosList, firstPickPos)
                        table.insert(pickPosList, secondPickPos)

                        retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPosList)
                    end
                end
            end
        end
    end
    return pickPosList, retScopeResult, retTargetIds
end

---在有效点选范围内，从玩家位置由近及远找几个可以点选的位置
---返回点选列表，攻击范围列表（由每次点选计算的攻击范围组成），目标列表（由每次点选计算的目标列表组成）
---一般是点选格子转色技能用，例：伯利恒主动技
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_NearestPos(
    petEntity,
    activeSkillID,
    casterPos,
    validPosIdxList,
    pickUpNum,
    petColor)
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local casterPosIndex = self:_Pos2Index(casterPos)
    local env = self._env
    local posList = {}
    local targetIdList = {} --攻击目标
    local attackPosList = {} --攻击范围
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            --排除同色格子
            if env.BoardPosCanMove[posIdx] and env.BoardPosPieces[posIdx] ~= petColor then
                local result, targetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
                table.appendArray(attackPosList, result:GetAttackRange())
                table.appendArray(targetIdList, targetIds)
                posList[#posList + 1] = pos
                if #posList >= pickUpNum then
                    break
                end
            end
        end
    end
    return posList, attackPosList, targetIdList
end

---艾米：路径的终点
---试算出本次连线路径，以路径终点为点选位置
---返回点选列表，攻击范围列表，目标列表
---@param petEntity Entity
---@param activeSkillID number
function AutoFightService:_CalPickPosPolicy_MovePathEndPos(TT, petEntity, activeSkillID)
    local env = self._env
    local attackPosList = {}
    local chainPath, pieceType, evalue = self:GetAutoChainPath(TT, env.TeamEntity)
    local pos = chainPath[#chainPath]

    --MSG31563
    local isBlockedSummonTrap = self._boardServiceLogic:IsPosBlock(pos, BlockFlag.MonsterLand)
    local isBlockedLinkLine = self._boardServiceLogic:IsPosBlock(pos, BlockFlag.LinkLine)
    if #chainPath == 1 or isBlockedSummonTrap or isBlockedLinkLine then
        return {}, {}, {}
    end

    local result, targetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
    attackPosList = result:GetAttackRange()
    return { pos }, attackPosList, targetIds
end

--加百列：水火雷中选择格子数最多的格子
---遍历有效范围内的所有格子，统计非绿色格子的数量，选择数量最多的颜色，取点选坐标
function AutoFightService:_CalPickPosPolicy_PetJiaBaiLie(validPosList)
    local env = self._env
    local targetIdList = {}
    local _pieceCnt = { 0, 0, 0, 0, 0 }
    local _pickPos = {}
    for _, pos in ipairs(validPosList) do
        local posIdx = self:_Pos2Index(pos)
        local color = env.BoardPosPieces[posIdx]
        if color and color ~= PieceType.Green then
            _pieceCnt[color] = _pieceCnt[color] + 1
            _pickPos[color] = pos
        end
    end
    local maxCnt, maxPos = 0, nil
    for color, cnt in ipairs(_pieceCnt) do
        if cnt > maxCnt then
            maxCnt = cnt
            maxPos = _pickPos[color]
        end
    end
    return { maxPos }, { maxPos }, targetIdList
end

--罗伊：范围内最近的非黄色格子，格子上是否有指定机关会影响能量消耗
---罗伊三觉后主动技根据是否到了自己的转色机关，消耗不同
---从玩家位置由近及远找非黄色格子，如果需要判断消耗（三觉后），则还有根据选中位置是否有转色机关计算实际消耗，并判断
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetLuoYi(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    ---@type UtilDataServiceShare
    local udsvc = self._world:GetService("UtilData")

    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local casterPosIndex = self:_Pos2Index(casterPos)

    local needCheckPower = false
    local powerIfNoTrap
    local tarTrapId
    local extraParam = skillConfigData:GetSkillTriggerExtraParam()
    if extraParam then
        if extraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then
            needCheckPower = true
            powerIfNoTrap = extraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
            local pickType = skillConfigData:GetSkillPickType()
            if pickType == SkillPickUpType.PickDiffPowerInstruction then
                local pickParams = skillConfigData:GetSkillPickParam()
                tarTrapId = pickParams[3]
            end
        end
    end
    local legendPower = 0
    if needCheckPower then
        ---@type AttributesComponent
        local attributeCmpt = petEntity:Attributes()
        if attributeCmpt then
            legendPower = attributeCmpt:GetAttribute("LegendPower")
        end
    end

    local pickExtraParam = {}
    local firstPickPos
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local color = env.BoardPosPieces[posIdx]
            if color and color ~= PieceType.Yellow then
                --判断机关和能量
                if needCheckPower then
                    local bPickTrap = false
                    local traps = udsvc:GetTrapsAtPos(pos)
                    if traps then
                        for index, e in ipairs(traps) do
                            if tarTrapId == e:Trap():GetTrapID() then
                                bPickTrap = true
                                break
                            end
                        end
                    end
                    if not bPickTrap then
                        if legendPower >= powerIfNoTrap then
                            firstPickPos = pos
                            table.insert(pickExtraParam, SkillTriggerTypeExtraParam.PickPosNoCfgTrap)
                            break
                        end
                    end
                else
                    firstPickPos = pos
                    break
                end
            end
        end
    end
    if firstPickPos then
        return { firstPickPos }, { firstPickPos }, {}, pickExtraParam
    else
        return {}, {}, {}, {}
    end
end

---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetLen(policyParam, petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local pickPosList = {}
    local atkPosList = {}
    local targetIds = {}
    local extraParam = {}

    local greatestHPVal = 0
    ---@type Entity|nil
    local greatestHPValEntity
    local posIndexEntityIDDic = {}
    ---@type Entity[]
    local monsterGlobalEntityGroup = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    if self._world:MatchType() == MatchType.MT_BlackFist then
        monsterGlobalEntityGroup = {petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()}
    end
    --魔方
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    for _, e in ipairs(monsterGlobalEntityGroup) do
        local isSelectable = true
        if e:HasBuff() then
            isSelectable = not e:BuffComponent():HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget)
        end
        if (not e:HasDeadMark()) and isSelectable then
            local hp = e:Attributes():GetCurrentHP()
            local tv2BodyArea = e:BodyArea():GetArea()
            local v2GridPos = e:GetGridPosition()
            local eid = e:GetID()
            local hasValidBodyPos = false
            for _, v2Relative in ipairs(tv2BodyArea) do
                ---@type Vector2
                local v2 = v2GridPos + v2Relative
                if not table.intable(extraBoardPosRange, v2) then
                    local index = Vector2.Pos2Index(v2)
                    posIndexEntityIDDic[index] = eid
                    hasValidBodyPos = true
                end
            end
            
            if hasValidBodyPos then
                if hp > greatestHPVal then
                    greatestHPVal = hp
                    greatestHPValEntity = e
                end
            end
        end
    end

    if not greatestHPValEntity then
        Log.debug(self._className, "自动主动技释放：场上没怪")
        return pickPosList, atkPosList, targetIds, extraParam
    end

    local greatestHPValEntityID = greatestHPValEntity:GetID()
    Log.debug(self._className, "自动主动技释放：必然包含目标：", greatestHPValEntityID)
    --覆盖方式推算：在确保技能范围能够覆盖这个血量最高的目标的同时，尽可能推算出覆盖单位更多的范围
    local greatestHPValGridPos = greatestHPValEntity:GetGridPosition()
    if table.intable(extraBoardPosRange, greatestHPValGridPos) then--魔方boss gridPos不在bodyArea中
        --从bodyArea中重选一个位置
        local v2GridPos = greatestHPValGridPos
        local tv2BodyArea = greatestHPValEntity:BodyArea():GetArea()
        local validList = {}
        for _, v2Relative in ipairs(tv2BodyArea) do
            ---@type Vector2
            local v2 = v2GridPos + v2Relative
            if not table.intable(extraBoardPosRange, v2) then
                table.insert(validList,v2)
            end
        end
        --选一个左下角吧
        if #validList > 0 then
            table.sort(validList,
                function (a, b) 
                    if a.x ~= b.x then
                        return a.x < b.x
                    else
                        return a.y < b.y
                    end
                end
            )
            greatestHPValGridPos = validList[1]
        else--正常不会有else
            return pickPosList, atkPosList, targetIds, extraParam
        end
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local testResult = {}
    local resultIndex = 0
    -- 参数是两个为一组的范围偏移，如2, 2表示<x, y>到<x+2, y+2>的连线划定矩形内，-2, -2表示<x, y>到<x-2, y-2>，etc.
    for i = 1, #policyParam, 2 do
        local policyXOffset = policyParam[i]
        local policyYOffset = policyParam[i + 1]
        local gridPosX = greatestHPValGridPos.x
        local gridPosY = greatestHPValGridPos.y
        local gridPosOffsetX = gridPosX + policyXOffset
        local gridPosOffsetY = gridPosY + policyYOffset
        local pickPos2 = Vector2.New(gridPosOffsetX, gridPosOffsetY)
        -- 如果这个理论终点不是有效格子，就不往下算了
        if utilData:IsValidPiecePos(pickPos2) then
            if not self:_IsPosInExtraBoard(pickPos2,extraBoardPosRange) then
                resultIndex = resultIndex + 1
                local result = {
                    greatestHPValEntityCount = 0,
                    otherMonsterEntityCount = 0,
                    index = resultIndex,
                    x1 = gridPosX,
                    x2 = gridPosOffsetX,
                    y1 = gridPosY,
                    y2 = gridPosOffsetY,
                    targetIDs = {}
                }
                --这里这么取一下上下限，不然如果给出的下限比上限低，循环就没用了
                local minX = math.min(gridPosX, gridPosOffsetX)
                local maxX = math.max(gridPosX, gridPosOffsetX)
                local minY = math.min(gridPosY, gridPosOffsetY)
                local maxY = math.max(gridPosY, gridPosOffsetY)
                for x = minX, maxX do
                    for y = minY, maxY do
                        local v2 = Vector2.New(x, y)
                        ---@type number[]
                        local tMonsterList = utilData:FindEntityByPosAndType(v2, EnumTargetEntity.Monster)
                        if self._world:MatchType() == MatchType.MT_BlackFist then
                            local eTeam = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                            if eTeam:GetGridPosition() == v2 then
                                tMonsterList = {eTeam:GetID()}
                            end
                        end
                        for _, eid in ipairs(tMonsterList) do
                            -- targetIDs去重
                            if not table.icontains(result.targetIDs, eid) then
                                table.insert(result.targetIDs, eid)
                            end

                            if eid == greatestHPValEntityID then
                                result.greatestHPValEntityCount = result.greatestHPValEntityCount + 1
                            else
                                result.otherMonsterEntityCount = result.otherMonsterEntityCount + 1
                            end
                        end
                    end
                end
                table.insert(testResult, result)
            end
        end
    end

    table.sort(testResult, function (a, b)
        -- 排序规则：尽最大可能选中【绝对生命值最大的单位】的格子
        if a.greatestHPValEntityCount ~= b.greatestHPValEntityCount then
            return a.greatestHPValEntityCount > b.greatestHPValEntityCount
        else
            -- 在保证尽最大可能选中主要目标的基础上，圈到其他单位的数量越多越好
            if a.otherMonsterEntityCount ~= b.otherMonsterEntityCount then
                return a.otherMonsterEntityCount > b.otherMonsterEntityCount
            else
                return a.index < b.index
            end
        end
    end)

    local finalResult = testResult[1]
    local pickPosA = Vector2.New(finalResult.x1, finalResult.y1)
    local pickPosB = Vector2.New(finalResult.x2, finalResult.y2)

    -- 计算连线构成的矩形atkPosList
    local minX = math.min(pickPosA.x, pickPosB.x)
    local maxX = math.max(pickPosA.x, pickPosB.x)
    local minY = math.min(pickPosA.y, pickPosB.y)
    local maxY = math.max(pickPosA.y, pickPosB.y)
    for x = minX, maxX do
        for y = minY, maxY do
            local v2 = Vector2.New(x, y)
            if utilData:IsValidPiecePos(v2) then
                table.insert(atkPosList, v2)
            end
        end
    end

    return {pickPosA, pickPosB}, atkPosList, finalResult.targetIDs, extraParam
end

--雨森：首先选择怪物周围一圈内的机关所在位置；若无，则取距离自己最近的怪物一圈距离自己最近的位置；若均无，则终止释放
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicyPetYuSen(petEntity, activeSkillID, casterPos)
    local env = self._env

    --获取技能中配置的机关ID
    local trapID = 0
    ---@type SkillSummonTrapEffectParam
    local stpSummonTrap = nil
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local skillEffectArray = skillConfigData:GetSkillEffect()
    for _, skillEffect in ipairs(skillEffectArray) do
        if skillEffect:GetEffectType() == SkillEffectType.SummonTrap then
            stpSummonTrap = skillEffect
            trapID = stpSummonTrap:GetTrapID()
            if type(trapID) == "table" then
                trapID = trapID[1]
            end
            break
        end
    end

    --获取攻击目标
    ---@type Entity[]
    local targetEntityList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
        table.insert(targetEntityList, enemyTeam)
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(targetEntityList, monsterEntity)
            end
        end
    end

    --获取雨森召唤的机关（刀）
    ---@type Entity[]
    local trapEntityList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID and e:HasSummoner() and
            e:Summoner():GetSummonerEntityID() == petEntity:GetID()
        then
            table.insert(trapEntityList, e)
        end
    end

    --检查目标周围一圈是否存在召唤的机关并保存机关格子
    local pickupPosList = {}
    for _, targetEntity in pairs(targetEntityList) do
        ---@type Vector2[]
        local posList = self:GetPosListAroundBodyArea(targetEntity, 1)
        for _, trapEntity in pairs(trapEntityList) do
            ---@type Vector2
            local trapPos = trapEntity:GridLocation():GetGridPos()
            if table.icontains(posList, trapPos) then
                ---@type BoardComponent
                local boardCmpt = self._world:GetBoardEntity():Board()
                local es =
                boardCmpt:GetPieceEntities(
                    trapPos,
                    function(e)
                        return e:HasTeam() or e:HasMonsterID()
                    end
                )
                if #es == 0 and not self._boardServiceLogic:IsPosBlock(trapPos, BlockFlag.LinkLine) then
                    table.insert(pickupPosList, trapPos)
                end
            end
        end
    end

    local pickPosList = {}
    --雨森主动技为伤害技能，需有一个目标，此处特殊处理，将自身填充进目标，只为计数，不会作为目标ID使用
    local targetIDs = {}
    table.insert(targetIDs, petEntity:GetID())

    --格子数量>0, 随机一个，并返回
    if #pickupPosList > 0 then
        pickPosList = table.randomn(pickupPosList, 1)
        return pickPosList, pickPosList, targetIDs
    end

    --找到距离玩家最近的目标
    ---@type SkillScopeCalculator
    local scopeCalculator = self._utilScopeSvc:GetSkillScopeCalc()
    ---@type SkillScopeTargetSelector
    local tarSelector = self._world:GetSkillScopeTargetSelector()
    local posList = self._utilSvc:GetCloneBoardGridPos()
    ---@type SkillScopeResult
    local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, petEntity, posList, posList)
    local nearstTargetIDs = tarSelector:DoSelectSkillTarget(petEntity, SkillTargetType.NearestMonster, skillScopeResult)
    if #nearstTargetIDs < 1 then
        return pickPosList, pickPosList, targetIDs
    end
    local targetID = nearstTargetIDs[1]
    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetID)

    --怪物周围一圈距离玩家最近的可召唤机关的点
    ---@type Vector2[]
    local posList = self:GetPosListAroundBodyArea(targetEntity, 1)
    for _, pickPos in pairs(posList) do
        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        if stpSummonTrap:GetBlock() == 0 or trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
            table.insert(pickupPosList, pickPos)
        end
    end
    HelperProxy:SortPosByCenterPosDistance(casterPos, pickupPosList)
    for i = 2, #pickupPosList do
        pickupPosList[i] = nil
    end
    return pickupPosList, pickupPosList, targetIDs
end

--顺序检查子技能的释放条件，返回可释放的子技能
function AutoFightService:_CheckSubSkillCondition(TT, e, subSkillList, env)
    local svcCfg = self._configService
    ---@type Entity
    local petEntity = e
    local petPstID = petEntity:PetPstID():GetPstID()
    local sorted_skills = {}
    for i = 1, #subSkillList do
        local skillId = subSkillList[i]
        ---@type SkillConfigData
        local skillConfigData = svcCfg:GetSkillConfigData(skillId)

        --判断子技能是否满足释放条件，由于父技能已经判断可以释放，此处略过一般性检查
        --判断是否存在机关ID
        local cfgExtraParam = skillConfigData:GetSkillTriggerExtraParam()
        if cfgExtraParam then
            local trapID = cfgExtraParam[SkillTriggerTypeExtraParam.TrapID]
            if trapID then
                ---@type TrapServiceLogic
                local trapServiceLogic = self._world:GetService("TrapLogic")
                if not trapServiceLogic:IsTrapCovered(trapID, petPstID) then
                    table.insert(sorted_skills, { petEntity, skillId, petPstID, i })
                end
            end
        else
            table.insert(sorted_skills, { petEntity, skillId, petPstID, i })
        end
    end

    --按释放顺序排序[越小优先]
    table.sort(
        sorted_skills,
        function(a, b)
            local order1 = svcCfg:GetSkillConfigData(a[2]):GetAutoFightSkillOrder()
            local order2 = svcCfg:GetSkillConfigData(b[2]):GetAutoFightSkillOrder()
            if order1 == order2 then
                return a[4] < b[4]
            end
            return order1 < order2
        end
    )

    for _, v in ipairs(sorted_skills) do
        local skillId = v[2]

        --计算技能释放条件是否满足
        if self:_CheckSkillCondition(TT, petEntity, skillId, env) then
            env.subSkillID = skillId
            return true
        end
    end

    return false
end

--是否可以攻击目标
function AutoFightService:_CanAttack(trapPos, targetPosList)
    ---@type SkillScopeCalculator
    local scopeCalculator = self._utilScopeSvc:GetSkillScopeCalc()
    local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.Rhombus, { 2 }, trapPos)
    local attackRange = scopeResult:GetAttackRange()
    local targetInRange = table.union(attackRange, targetPosList)
    if #targetInRange == 0 then
        return false
    end

    return true
end

--清瞳：检查是否需要重新召唤机关
function AutoFightService:_IsNeedSummonTrap(petEntity, trapID, pieceType, targetPosList)
    --获取清瞳召唤的机关
    ---@type Entity[]
    local trapEntityList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:TrapID():GetTrapID() == trapID and e:HasSummoner() then
            local summonEntityID = e:Summoner():GetSummonerEntityID()
            ---@type Entity
            local summonEntity = e:GetSummonerEntity()
            --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
            if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                summonEntityID = summonEntity:GetSuperEntity():GetID()
            end
            if summonEntityID == petEntity:GetID() then
                table.insert(trapEntityList, e)
            end
        end
    end

    --场上没有机关，直接返回，需要重新召唤
    if #trapEntityList == 0 then
        return true, nil
    end

    ---@type Entity
    local trapEntity = trapEntityList[1]
    local trapPos = trapEntity:GetGridPosition()

    --机关被覆盖，直接返回，需要重新召唤
    if self._utilScopeSvc:IsPosHaveMonsterOrPet(trapPos) then
        return true, trapPos
    end

    --机关和阻挡连线的机关重合时，需要重新召唤
    if self._utilScopeSvc:IsPosBlock(trapPos, BlockFlag.LinkLine) then
        return true, trapPos
    end

    --格子颜色已是配置颜色，直接返回，需要重新召唤
    if pieceType == self._boardServiceLogic:GetPieceType(trapPos) then
        return true, trapPos, true
    end

    --检查机关菱形十二格范围内，是否有怪物存在，若不存在，则返回，需要重新召唤
    if not self:_CanAttack(trapPos, targetPosList) then
        return true, trapPos
    end

    return false, trapPos
end

--清瞳：攻击目标的对应范围内是否存在非配置属性格子，若pieceType为nil，则不进行格子属性匹配
function AutoFightService:_CalcMatchPickPos(casterPos, posListTab, trapID, pieceType)
    for _, posList in ipairs(posListTab) do
        --去重
        posList = table.unique(posList)
        --排序
        HelperProxy:SortPosByCenterPosDistance(casterPos, posList)

        ---@type TrapServiceLogic
        local trapSvc = self._world:GetService("TrapLogic")
        for _, pickPos in pairs(posList) do
            if trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
                if not pieceType then
                    return pickPos
                end
                if pieceType and pieceType ~= self._boardServiceLogic:GetPieceType(pickPos) then
                    return pickPos
                end
            end
        end
    end

    return nil
end

--清瞳：怪物周围一圈距离自己最近的非蓝色格子或点击机关所在位置
--觉一：怪物周围一圈距离自己最近的非蓝色格子
--觉三：如果已经召唤了机关，判断机关所在格子是否是水格子，若不是，则选择机关位置；若是则执行觉一的规则
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicyPetQingTong(petEntity, activeSkillID, casterPos)
    local pickPosList = {}
    --此处特殊处理，将自身填充进目标，只为计数，不会作为目标ID使用
    local targetIDs = {}
    table.insert(targetIDs, petEntity:GetID())

    --获取技能中配置的点选参数
    local trapID = 0
    local pieceType = 0
    local canPickTrap = false
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local pickPosPolicyParam = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    if pickPosPolicyParam and pickPosPolicyParam.useType == AutoFightScopeUseType.PickPosPolicy then
        trapID = pickPosPolicyParam.trapID
        pieceType = pickPosPolicyParam.pieceType
        canPickTrap = pickPosPolicyParam.canPickTrap
    end

    --获取攻击目标
    ---@type Entity[]
    local targetEntityList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local enemyTeam = teamEntity:Team():GetEnemyTeamEntity()
        table.insert(targetEntityList, enemyTeam)
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(targetEntityList, monsterEntity)
            end
        end
    end

    --获取目标所占格子、周围一圈格子、周围两圈格子
    local targetPosList = {}
    local squareRing1PosList = {}
    local squareRing2PosList = {}
    for _, targetEntity in pairs(targetEntityList) do
        local targetPos = targetEntity:GridLocation():GetGridPos()
        local bodyArea = targetEntity:BodyArea():GetArea()
        for _, value in pairs(bodyArea) do
            local workPos = targetPos + value
            table.insert(targetPosList, workPos)
        end
        local ring1 = self:GetPosListAroundBodyArea(targetEntity, 1)
        table.appendArray(squareRing1PosList, ring1)
        local ring2 = self:GetPosListAroundBodyArea(targetEntity, 2)
        table.appendArray(squareRing2PosList, ring2)
    end

    --判定是否需要更换机关位置
    local needSummon, trapPos, matchPieceType = self:_IsNeedSummonTrap(petEntity, trapID, pieceType, targetPosList)
    if canPickTrap and not needSummon and trapPos then
        --不需要重新召唤，则返回机关位置作为点选对象
        table.insert(pickPosList, trapPos)
        return pickPosList, pickPosList, targetIDs
    end

    local squareRingListTab = {}
    table.insert(squareRingListTab, squareRing1PosList)
    table.insert(squareRingListTab, squareRing2PosList)

    --检查目标周围是否存在可召唤机关的非配置属性格子
    local pickPos = self:_CalcMatchPickPos(casterPos, squareRingListTab, trapID, pieceType)
    if pickPos then
        table.insert(pickPosList, pickPos)
        return pickPosList, pickPosList, targetIDs
    end

    --若机关格子存在，且机关脚下为配置属性格子，判断是否可攻击到目标，若能攻击目标，则返回机关格子
    if canPickTrap and needSummon and trapPos and matchPieceType then
        if self:_CanAttack(trapPos, targetPosList) then
            table.insert(pickPosList, trapPos)
            return pickPosList, pickPosList, targetIDs
        end
    end

    --检查目标周围是否存在可召唤机关的格子(去除格子属性限制)
    pickPos = self:_CalcMatchPickPos(casterPos, squareRingListTab, trapID)
    if pickPos then
        table.insert(pickPosList, pickPos)
        return pickPosList, pickPosList, targetIDs
    end

    --获取全棋盘
    ---@type Vector2[]
    local vec2BoardMax = {}
    local boardRingMax = self._boardServiceLogic:GetCurBoardRingMax()
    for _, boardPos in ipairs(boardRingMax) do
        local vec2Pos = Vector2(boardPos[1], boardPos[2])
        table.insert(vec2BoardMax, vec2Pos)
    end
    --去除玩家位置
    table.removev(vec2BoardMax, casterPos)
    --排序
    HelperProxy:SortPosByCenterPosDistance(casterPos, vec2BoardMax)
    ---@type TrapServiceLogic
    local trapSvc = self._world:GetService("TrapLogic")
    for _, pickPos in pairs(vec2BoardMax) do
        if trapSvc:CanSummonTrapOnPos(pickPos, trapID) then
            table.insert(pickPosList, pickPos)
            return pickPosList, pickPosList, targetIDs
        end
    end

    return pickPosList, pickPosList, targetIDs
end

--贾尔斯：选择全场绝对血量最低的怪物攻击，在能攻击到的前提下优先选玩家所在的格子施放。
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetGiles(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local minHp = 1
    local targetEntity = nil
    for i, e in ipairs(group:GetEntities()) do
        if not e:HasDeadMark() then
            local hp = e:Attributes():GetCurrentHP()
            if not targetEntity or hp < minHp then
                minHp = hp
                targetEntity = e
            end
        end
    end

    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
    end

    if not targetEntity then
        return {}, {}, {}
    end

    -- local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local pickPos = nil

    --先在身形的周围找是否有玩家坐标
    local targetGridPos = targetEntity:GridLocation():GetGridPos()
    local bodyArea = targetEntity:BodyArea():GetArea()
    local dirs = {Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)}
    for _, value in ipairs(bodyArea) do
        local workPos = targetGridPos + value
        for _, dir in ipairs(dirs) do
            local targetPos = workPos + dir
            if targetPos == casterPos then
                pickPos = targetPos
                -- table.insert(pickPosList, workPos)
                break
            end
        end

        if pickPos then
            break
        end
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()
    --周围没有玩家，随便一个点
    if not pickPos then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        for _, dir in ipairs(dirs) do
            local targetPos = targetGridPos + dir
            if utilDataSvc:IsValidPiecePos(targetPos) then
                if not self:_IsPosInExtraBoard(targetPos,extraBoardPosRange) then
                    pickPos = targetPos
                    break
                end
            end
        end
    end

    retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPos)

    return {pickPos}, retScopeResult:GetAttackRange(), retTargetIds
end

---@param entity Entity
---@param ringCount number
---@return Vector2[]
function AutoFightService:GetPosListAroundBodyArea(entity, ringCount)
    local v2SelfGridPos = entity:GetGridPosition()
    local bodyArea = entity:BodyArea():GetArea()
    local v2SelfDir = entity:GetGridDirection()

    ---@type SkillScopeCalculator
    local scopeCalc = SkillScopeCalculator:New(self._utilScopeSvc)
    local scopeResult = scopeCalc:ComputeScopeRange(
        SkillScopeType.AroundBodyArea,
        { 0, ringCount },
        v2SelfGridPos,
        bodyArea,
        v2SelfDir,
        SkillTargetType.Monster,
        v2SelfGridPos
    )

    return scopeResult:GetAttackRange()
end
---@param utilSvc UtilDataServiceShare
function AutoFightService:_IsPosCanPick(pos,checkBadGrid,checkExtraBoard,utilSvc,extraBoardPosRange)
    if checkBadGrid then
        if self:_IsPosBadGrid(pos,utilSvc) then
            return false
        end
    end
    if checkExtraBoard then
        if self:_IsPosInExtraBoard(pos,extraBoardPosRange) then
            return false
        end
    end
    return true
end
---@param utilSvc UtilDataServiceShare
function AutoFightService:_IsPosBadGrid(pos,utilSvc)
    if not utilSvc then
        utilSvc = self._world:GetService("UtilData")
    end
    if utilSvc:IsBadGridPos(pos) then
        return true
    end
    return false
end
function AutoFightService:_IsPosInExtraBoard(pos,extraBoardPosRange)
    if not extraBoardPosRange then
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        extraBoardPosRange = utilData:GetExtraBoardPosList()
    end
    if table.intable(extraBoardPosRange, pos) then
        return true
    end
    return false
end
--薇丝：先选择BOSS，没有BOSS再选择小怪。同级内优先选择有指定buff的存活目标，没有带buff的再选择血量绝对值最高的。
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetVice(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local targetEntity = nil
    ---@type UtilDataServiceShare
    local utilSvc = self._world:GetService("UtilData")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()

    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
    else
        --先选择目标群，优先boss
        local bossEntityList = {}
        local targetEntityList = {}
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster(petEntity)
        for i, e in ipairs(monsterList) do
            local gridPos = e:GridLocation():GetGridPos()
            local bodyArea = e:BodyArea():GetArea()
            local hasCacPickPos = false
            for _, value in pairs(bodyArea) do
                local workPos = gridPos + value
                if self:_IsPosCanPick(workPos,true,true,utilSvc,extraBoardPosRange) then
                    hasCacPickPos = true
                    break
                end
            end
            --脚下有一个可以点的位置才能被
            if hasCacPickPos then
                if e:HasBoss() then
                    table.insert(bossEntityList, e)
                end
                table.insert(targetEntityList, e)
            end
        end

        if table.count(bossEntityList) > 0 then
            targetEntityList = bossEntityList
        end

        ---@type SkillConfigData
        local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
        local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()

        --先找有指定buff的
        for i, e in ipairs(targetEntityList) do
            ---@type BuffComponent
            local buffCmp = e:BuffComponent()
            if buffCmp then
                local buffEffect = policyParam[1]
                if buffCmp:HasBuffEffect(buffEffect) then
                    targetEntity = e
                    break
                end
            end
        end

        --找血量绝对值最高的
        if not targetEntity then
            local maxHP = 0
            for i, e in ipairs(targetEntityList) do
                local hp = e:Attributes():GetCurrentHP()
                if not targetEntity or hp > maxHP then
                    maxHP = hp
                    targetEntity = e
                end
            end
        end
    end

    if not targetEntity then
        return {}, {}, {}
    end

    local retScopeResult = {}
    local retTargetIds = {}
    local pickPos = targetEntity:GridLocation():GetGridPos()
    --如果gridPos不可以点  换一个点
    if not self:_IsPosCanPick(pickPos,true,true,utilSvc,extraBoardPosRange) then
        local bodyArea = targetEntity:BodyArea():GetArea()
        for _, value in pairs(bodyArea) do
            local workPos = pickPos + value
            local isCanPickPos = self:_IsPosCanPick(workPos,true,true,utilSvc,extraBoardPosRange)
            if isCanPickPos then
                pickPos = workPos
                break
            end
        end
    end

    retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPos)

    return {pickPos}, retScopeResult:GetAttackRange(), retTargetIds
end

function AutoFightService:_CalPickPosPolicy_FeatureMasterSkill(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local env = self._env
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local teamColor = PieceType.Yellow
    local teamPos = casterPos
    ---@type Entity
    local teamEntity = self._env.TeamEntity
    if teamEntity then
        local teamLeaderEntity = teamEntity:Team():GetTeamLeaderEntity()
        teamColor = teamLeaderEntity:Element():GetPrimaryType()
        teamPos = teamEntity:GetGridPosition()
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local casterPosIndex = self:_Pos2Index(teamPos)

    local pickExtraParam = {}
    local firstPickPos
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local color = env.BoardPosPieces[posIdx]
            if color and color ~= teamColor then
                firstPickPos = pos
                break
            end
        end
    end
    if firstPickPos then
        return { firstPickPos }, { firstPickPos }, {}, pickExtraParam
    else
        return {}, {}, {}, {}
    end
end

function AutoFightService:_PetKaLian_CanGridConvertToRed(pos, casterPos)
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")
    if not utilScope:IsValidPiecePos(pos) then
        return false
    end

    -- 需求如是，如果转色范围包含了施法者的当前坐标，认为“将当前位置转色为红色”
    if pos == casterPos then
        return true
    end

    if not lsvcBoard:GetCanConvertGridElement(pos) then
        return false
    end

    -- 已经是红色就不算是可以转为红色了
    if lsvcBoard:GetPieceType(pos) == PieceType.Red then
        return false
    end

    return true
end

---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetSPKaLian_NoDamage(TT, petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")

    local tInfo = {}
    for _, v2 in ipairs(validPosList) do
        local convertCount = 0
        local convertPos = {}
        --原先的转色范围与点选和逻辑结果有关，这里两者都没有，所以单独写一个
        local dir = utilScope:GetStandardDirection8D(v2 - casterPos)
        local posForward = v2 + dir
        local posBackward = v2 - dir
        if self:_PetKaLian_CanGridConvertToRed(posForward, casterPos) then
            convertCount = convertCount + 1
            table.insert(convertPos, posForward)
        end
        if self:_PetKaLian_CanGridConvertToRed(posBackward, casterPos) then
            convertCount = convertCount + 1
            table.insert(convertPos, posBackward)
        end
        -- 如果这个位置无法生成新的火格子，则不释放技能，因此后续的逻辑都不用算了
        if convertCount > 0 then
            local tMonsters, tMonsterPos
            if self._world:MatchType() ~= MatchType.MT_BlackFist then
                tMonsters, tMonsterPos = utilScope:SelectNearestMonsterOnPos(v2, 1)
            else
                local enemyTeamEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                tMonsters = {enemyTeamEntity}
                tMonsterPos = {enemyTeamEntity:GetGridPosition()}
            end

            local candidateInfo = {
                index = #tInfo,
                pos = v2,
                convertCount = convertCount,
                convertPos = convertPos,
                nearestMonsterCount = (#tMonsters),
                nearestMonsterDistance = (#tMonsterPos > 0) and Vector2.Distance(v2, tMonsterPos[1]) or nil,
            }
            table.insert(tInfo, candidateInfo)
        end
    end

    if #tInfo == 0 then
        return {}, {}, {}, {}
    end

    table.sort(tInfo, function (a, b)
        --转色数量最大
        if a.convertCount ~= b.convertCount then
            return a.convertCount > b.convertCount
        end

        --距离怪物最近
        if a.nearestMonsterDistance ~= b.nearestMonsterDistance then
            return a.nearestMonsterDistance < b.nearestMonsterDistance
        end

        return a.index < b.index -- 保底
    end)

    local final = tInfo[1]

    return {final.pos}, final.convertPos, {}, {} --单纯的瞬移+转色
end

---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetSPKaLian_WithDamage(TT, petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")

    local configSvc = self._configService
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(activeSkillID)

    local tInfo = {}
    for _, v2 in ipairs(validPosList) do
        local convertCount = 0
        --原先的转色范围与点选和逻辑结果有关，这里两者都没有，所以单独写一个
        local dir = utilScope:GetStandardDirection8D(v2 - casterPos)
        local posForward = v2 + dir
        local posBackward = v2 - dir
        if self:_PetKaLian_CanGridConvertToRed(posForward, casterPos) then
            convertCount = convertCount + 1
        end
        if self:_PetKaLian_CanGridConvertToRed(posBackward, casterPos) then
            convertCount = convertCount + 1
        end
        -- 如果这个位置无法生成新的火格子，则不释放技能，因此后续的逻辑都不用算了
        if convertCount > 0 then
            local tMonsters, tMonsterPos
            if self._world:MatchType() ~= MatchType.MT_BlackFist then
                tMonsters, tMonsterPos = utilScope:SelectNearestMonsterOnPos(v2, 1)
                YIELD(TT)
            else
                local enemyTeamEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                tMonsters = {enemyTeamEntity}
                tMonsterPos = {enemyTeamEntity:GetGridPosition()}
            end

            ---@type SkillScopeCalculator
            local scopeCalculator = utilScope:GetSkillScopeCalc()
            local attackRangeScopeResult = scopeCalculator:ComputeScopeRange(
                    SkillScopeType.AngleFreeLine,
                    {widthThreshold=1,noExtend=1},
                    v2,
                    petEntity:BodyArea():GetArea(),
                    petEntity:GetGridDirection(),
                    SkillTargetType.MonsterTrap,
                    petEntity:GetGridPosition(),
                    petEntity
            )
            local attackRange = attackRangeScopeResult:GetAttackRange() or {}

            --选技能目标
            local targetSelector = self._world:GetSkillScopeTargetSelector()
            local targetIds = targetSelector:DoSelectSkillTarget(petEntity, SkillTargetType.Monster,attackRangeScopeResult,activeSkillID) or {}

            local candidateInfo = {
                index = #tInfo, --排序保底数据
                pos = v2,
                convertCount = convertCount,
                nearestMonsterCount = (#tMonsters),
                nearestMonsterDistance = (#tMonsterPos > 0) and Vector2.Distance(v2, tMonsterPos[1]) or nil,
                attackRange = attackRange,
                targetIds = targetIds
            }
            table.insert(tInfo, candidateInfo)
        end
    end

    if #tInfo == 0 then
        return {}, {}, {}, {}
    end

    table.sort(tInfo, function (a, b)
        --可转色格子较多者优先
        if a.convertCount ~= b.convertCount then
            return a.convertCount > b.convertCount
        end

        local countA = #(a.targetIds)
        local countB = #(b.targetIds)

        --转色格子数相同时，同时攻击到的怪物多者优先
        if countA ~= countB then
            return countA > countB
        end

        return a.index < b.index --纯保底
    end)

    local final = tInfo[1]
    YIELD(TT)

    return {final.pos}, final.attackRange, final.targetIds, {} --单纯的瞬移+转色
end

---@return Vector2
function AutoFightService:_GetReinhardtRange(pos)
    local retPos={}
    table.insert(retPos, pos+Vector2(0,0))
    table.insert(retPos, pos+Vector2(0,1))
    table.insert(retPos, pos+Vector2(0,-1))
    table.insert(retPos, pos+Vector2(1,0))
    table.insert(retPos, pos+Vector2(-1,0))
    return retPos
end

--莱因哈特：场上摆放数量标记，每个标记能攻击配置范围，选择能攻击到格子数量最多的位置
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetReinhardt(petEntity, activeSkillID,policyParam, casterPos, validPosList, validPosIdxList,pickUpNum)
    local targetEntity = {}
    local targetPosList = {}

    if self._world:MatchType() == MatchType.MT_BlackFist then
        targetEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
        local pos = targetEntity:GetGridPosition()
        local posIndex= Vector2.Pos2Index(pos)
        targetPosList[posIndex] = targetEntity:GetID()
    else
        ---@type Entity[]
        local groupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
        for i, v in ipairs(groupEntities) do
            ---@type BodyAreaComponent
            local areaCmpt = v:BodyArea()
            local pos = v:GetGridPosition()
            local areaList = areaCmpt:GetArea()
            for i, area in ipairs(areaList) do
                local newPos = area+pos
                local posIndex= Vector2.Pos2Index(newPos)
                targetPosList[posIndex] = v:GetID()
            end
        end
    end
    local pickPos = {}
    while pickUpNum >0 do
        local attackPosCount =0
        local pickUpPos = nil
        for i, pos in ipairs(validPosList) do
            ---@type Vector2[]
            local range = self:_GetReinhardtRange(pos)
            local tmpAPC =0
            for i, v in ipairs(range) do
                local index = Vector2.Pos2Index(v)
                if targetPosList[index] then
                    tmpAPC = tmpAPC + 1
                end
            end
            if tmpAPC> attackPosCount and not table.Vector2Include(pickPos,pos) then
                attackPosCount = tmpAPC
                pickUpPos = pos
            end
        end
        if  not pickUpPos then
            while not pickUpPos do
                local count = #validPosList
                local index = math.random(1,count)
                local pos = validPosList[index]
                if not table.Vector2Include(pickPos,pos) then
                    pickUpPos= pos
                    break
                end
            end
            --for i, pos in pairs(validPosList) do
            --    if not table.Vector2Include(pickPos,pos) then
            --        pickUpPos = pos
            --    end
            --end
        end
        pickUpNum = pickUpNum -1
        table.insert(pickPos,pickUpPos)
    end
    return pickPos,pickPos,{}
end
---@param skillData AutoSkillCastData
function AutoFightService:_CastFeatureSkill(TT, skillData)
    Log.debug("[AutoFight] _CastFeatureSkill skillID=", skillData.m_nSkillID)

    if self._world:GetGameTurn() == GameTurnType.LocalPlayerTurn then
        --我方的释放过程
        self:_LocalPlayerCastFeatureSkill(TT, skillData)
    else
        --敌方的释放过程 暂时没有
        --self:_RemotePlayerCastPersonaSkill(TT, caster, skillID, petID, pickUpGridPos, selectTeamPos, pickExtraParam)
    end
    --等待合击技开始
    while GameStateID.PersonaSkill ~= self:_GetFsmStateID() do
        YIELD(TT, 100)
    end
end


---本地队伍释放合击技
---通过event调用UI的方法，模拟玩家点击ui的操作进行释放
---@param skillData AutoSkillCastData
function AutoFightService:_LocalPlayerCastFeatureSkill(TT, skillData)
    --普通状态，进入预览状态
    self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 3)
    --等待预览
    while GameStateID.PreviewActiveSkill ~= self:_GetFsmStateID() do
        YIELD(TT, 100)
    end
    YIELD(TT, 500)

    local configSvc = self._configService
    ---@type SkillConfigData
    local skillConfigData = configSvc:GetSkillConfigData(skillData.m_nSkillID)
    ---@type SkillPickUpType
    local pickUpType = skillConfigData:GetSkillPickType()
    local triggerExtraParam = skillConfigData:GetSkillTriggerExtraParam()
    local featureType = FeatureType.PersonaSkill
    if triggerExtraParam and triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType] then
        featureType = triggerExtraParam[SkillTriggerTypeExtraParam.FeatureType]
    end
    
    --通知执行合击技
    if FeatureType.PersonaSkill == featureType then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AutoFightCastPersonaSkill)
    elseif FeatureType.MasterSkillRecover == featureType then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AutoFightCastPersonaSkill,featureType)
    elseif FeatureType.MasterSkill == featureType then
        local pickUpGridPos = skillData.m_listPickUpPos
        ---提取boardEntity
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            {
                ui = "UIWidgetFeatureMasterSkill",
                input = "OnClickUI",
                args = {}
            }
        )
        YIELD(TT, 1000)
        for i, pos in ipairs(pickUpGridPos) do
            Log.debug("pickup pos ", Vector2.Pos2Index(pos))
            pickUpTargetCmpt:SetPickUpTargetType(pickUpType)
            pickUpTargetCmpt:SetPickUpGridPos(pos)
            local petID = 0
            pickUpTargetCmpt:SetCurActiveSkillInfo(skillData.m_nSkillID, petID)
            renderBoardEntity:ReplacePickUpTarget()
            YIELD(TT, 500)
        end

        YIELD(TT, 500)

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.FakeInput,
            { ui = "UIWidgetChooseTarget", input = "HandleActiveSkillConfirm", args = {} }
        )
    elseif FeatureType.Card == featureType then
        local cardCostType = triggerExtraParam[SkillTriggerTypeExtraParam.CardCost]
        if cardCostType then
            ---@type FeatureServiceLogic
            local lsvcFeature = self._world:GetService("FeatureLogic")
            ---@type FeatureEffectParamCard
            local featureData = lsvcFeature:GetFeatureData(FeatureType.Card)
            local cardUiType = featureData:GetUiType()--杰诺 皮肤改ui
            local cardUiName = "UIWidgetFeatureCard"
            local cardInfoUiName = "UIWidgetFeatureCardInfo"
            if cardUiType == FeatureCardUiType.Skin1 then
                cardUiName = "UIWidgetFeatureCard_L"
                cardInfoUiName = "UIWidgetFeatureCardInfo_L"
            end
            local costList = lsvcFeature:GetCostCardListByType(cardCostType)
            if costList then
                GameGlobal.EventDispatcher():Dispatch(
                    GameEventType.FakeInput,
                    {
                        ui = cardUiName,
                        input = "OnClickUI",
                        args = {}
                    }
                )
                YIELD(TT, 1000)
                for _,cardType in ipairs(costList) do
                    GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.FakeInput,
                        {
                            ui = cardInfoUiName,
                            input = "AutoCardImgOnClick",
                            args = {cardType}
                        }
                    )
                    YIELD(TT, 500)
                end
                YIELD(TT, 500)
                GameGlobal.EventDispatcher():Dispatch(
                        GameEventType.FakeInput,
                        {
                            ui = cardInfoUiName,
                            input = "OnCastClick",
                            args = {}
                        }
                    )
            end
        end
    end
end

--菲雅：能量>=2，释放两次主动技
---@param petEntity Entity
---@param activeSkillID number
function AutoFightService:_CalPickPosPolicyPetFeiYa(petEntity, activeSkillID)
    local pickPosList = {}
    local targetIDs = {}
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    --主动技释放次数检查
    if self._castActiveSkillCount == 0 then
        --未释放过，需要当前能量值>=2才允许释放
        if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
            local legendPower = petEntity:Attributes():GetAttribute("LegendPower")
            local canCast = legendPower >= 2 * skillConfigData:GetSkillTriggerParam()
            if not canCast then
                self._castActiveSkillCount = 0
                return pickPosList, pickPosList, targetIDs
            end
        end
    end

    --将所有怪物按血量排序
    ---@type Entity[]
    local enemyEntities = {}
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for i, e in ipairs(monsterGroup:GetEntities()) do
        if not e:HasDeadMark() then
            table.insert(enemyEntities, e)
        end
    end

    --黑拳赛特殊处理
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if petEntity then
        if petEntity:HasTeam() then
            teamEntity = petEntity
        elseif petEntity:HasPet() then
            teamEntity = petEntity:Pet():GetOwnerTeamEntity()
        end
    end    
    if self._world:MatchType() == MatchType.MT_BlackFist then
        table.insert(enemyEntities, teamEntity:Team():GetEnemyTeamEntity())
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local extraBoardPosRange = utilData:GetExtraBoardPosList()

    local minHPEntityID = 0
    local minHP = MAX_INT_32
    local minHPEntityPos = nil
    for _, e in ipairs(enemyEntities) do
        ---@type GridLocationComponent
        local gridLocCmpt = e:GridLocation()
        local pickPos = gridLocCmpt:GetGridPos()        
        if utilData:IsValidPiecePos(pickPos) then
            local isCanPickPos = self:_IsPosCanPick(pickPos, true, true, utilData, extraBoardPosRange)
            if not isCanPickPos then
                local bodyArea = e:BodyArea():GetArea()
                for _, value in pairs(bodyArea) do
                    local workPos = pickPos + value
                    isCanPickPos = self:_IsPosCanPick(workPos, true, true, utilData, extraBoardPosRange)
                    if isCanPickPos then
                        pickPos = workPos
                        break
                    end
                end
            end
            if isCanPickPos then
                local hp = e:Attributes():GetCurrentHP()
                if minHP > hp then
                    minHP = hp
                    minHPEntityPos = pickPos
                    minHPEntityID = e:GetID()
                end
            end
        end  
    end

    if minHPEntityPos then
        table.insert(pickPosList, minHPEntityPos)
        table.insert(targetIDs, minHPEntityID)
        self._castActiveSkillCount = self._castActiveSkillCount + 1
        if self._castActiveSkillCount == 2 then
            self._castActiveSkillCount = 0
        end
    end

    return pickPosList, pickPosList, targetIDs
end

--卡牌模块技能 选技能
function AutoFightService:_FindFeatureCardSkillID()
    --1技能 三牌相同 buffA加给队长；2技能 三牌不同 buffB加给队尾；3技能 两牌相同一牌不同，回san
    --1.队长没有buffA，且卡牌足够，则释放1技能
    --2.队尾没有buffB，且卡牌足够，则释放2技能
    --3.如果卡牌足够，释放3技能
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    local skillList = lsvcFeature:GetAvailableCardSkillList()--排序好的可用的卡牌技能id列表
    if skillList and #skillList > 0 then
        return skillList[1]
    else
        return
    end
end
--法官：地图上没有石膏机关，则在周围两圈随机释放；如果有，则选择能摧毁最多石膏机关的位置
function AutoFightService:_CalPickPosPolicyPetJudge(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local env = self._env
    local petEntityID = petEntity:GetID()
    local petTraps = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:HasSummoner() then
            ---@type Entity
            local summonEntity = e:GetSummonerEntity()
            if summonEntity and summonEntity:HasSuperEntity() then
                summonEntity = summonEntity:GetSuperEntity()
            end
            if summonEntity then
                local summonEntityID = summonEntity:GetID()
                if petEntityID == summonEntityID then
                    table.insert(petTraps,e)
                end
            end
        end
    end
    local pickPos = nil
    local pickScopeRange = nil
    if #petTraps == 0 then
        --自身周围两圈随机释放
        local ringNum = 2
        local posList = self:GetPosListAroundBodyArea(petEntity, ringNum)
        --随机点选位置
        table.shuffle(posList)
        for _, pos in ipairs(posList) do
            local posIdx = self:_Pos2Index(pos)
            if validPosIdxList[posIdx] then
                pickPos = pos
                break
            end
        end
        if pickPos then
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPos)
            pickScopeRange = scope_result:GetAttackRange()
        end
    else
        --能摧毁最多机关的位置
        --随机点选位置
        table.shuffle(validPosList)
        local results = {}
        for _, pos in ipairs(validPosList) do
            local posIdx = self:_Pos2Index(pos)
            if env.BoardPosPieces[posIdx] then
                local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pos)
                --目标数量
                if #target_ids > 0 then
                    table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
                end
            end
        end
        
        if #results > 0 then
            table.sort(
                results,
                function(a, b)
                    return #a[2] > #b[2]
                end
            )
            local tarResult = results[1]
            pickPos = tarResult[1]
            pickScopeRange = tarResult[3]
        end
    end
    if pickPos then
        return {pickPos},pickScopeRange,{petEntityID}
    else
        return {},{},{}
    end
end

function AutoFightService:_CalPickPosPolicyPet1601701(petEntity, activeSkillID, casterPos, policyParam)
    local env = self._env
    local petEntityID = petEntity:GetID()

    local pickPos = nil
    local pickScopeRange = nil
    local leftPos = casterPos.x-1
    local rightPos =casterPos.x+1
    ---@type BoardServiceLogic
    local boardSvc = self._world:GetService("BoardLogic")
    local maxY=boardSvc:GetCurBoardMaxY()
    local leftLine,rightLine={},{}
    local leftCount,rightCount= 0,0
    local spPieceType = policyParam[1]
    for i = 1, maxY do
        local newPos = Vector2(leftPos,i)
        local pieceType =boardSvc:GetPieceType(newPos)
        if pieceType and pieceType~= PieceType.None then
            table.insert(leftLine,newPos)
            if pieceType == spPieceType then
                leftCount = leftCount +1
            end
        end
        newPos = Vector2(rightPos,i)
        pieceType =boardSvc:GetPieceType(newPos)
        if pieceType and pieceType~= PieceType.None then
            table.insert(rightLine,newPos)
            if pieceType == spPieceType then
                rightCount = rightCount +1
            end
        end
    end
    local curLine
    if leftCount> rightCount then
        curLine = leftLine
    else
        curLine = rightLine
    end
    if #curLine ==0 then
        if #leftLine>0 then
            curLine = leftLine
        else
            curLine = rightLine
        end
    end
    local pickUpPos
    ---@type BattleService
    local battleSvc = self._world:GetService("Battle")
    for i, pos in ipairs(curLine) do
        local targetEntityList = battleSvc:FindMonsterEntityInPos(pos)
        if #targetEntityList ~= 0 then
            pickUpPos = pos
        end
    end
    if not pickUpPos then
        local index = math.random(1,#curLine)

        pickUpPos = curLine[index]
    end

    local maxX = boardSvc:GetCurBoardMaxX()
    local leftEdgeLen = math.abs(maxX-pickUpPos.x-1)
    local rightEdgeLen = math.abs(maxX-pickUpPos.x+1)
    local dirPos
    if leftEdgeLen<rightEdgeLen then
        dirPos = Vector2(pickUpPos.x-1,pickUpPos.y)
    else
        dirPos = Vector2(pickUpPos.x+1,pickUpPos.y)
    end
    return {pickUpPos,dirPos},{pickUpPos,dirPos},{}
end

---@param petEntity Entity
function AutoFightService:_CalPickPosPolicyPet1601751(petEntity, activeSkillID, policyParam, casterPos, validPosList, validPosIdxList)
    local eTeam = petEntity:Pet():GetOwnerTeamEntity()
    ---@type CalcDamageService
    local lsvcCalcDamage = self._world:GetService("CalcDamage")
    local teamHP, teamMaxHP = lsvcCalcDamage:GetTeamLogicHP(eTeam)
    local percent = teamHP / teamMaxHP
    if percent >= 0.5 then
        local autoActiveSkillCount = petEntity:PetRender():GetPet1601751HPAboveLimitAutoCastActiveCount()
        --50%+血量自动放过一次之后便不再释放
        if autoActiveSkillCount > 0 then
            return {}, {}, {}
        end

        local pickPos, atkPos, targetList = self:_CalPickupPosPolicyPet1601751SummonHealTrap(petEntity, activeSkillID, policyParam, casterPos, validPosList, validPosIdxList)
        petEntity:PetRender():TickPet1601751HPAboveLimitAutoCastActiveCount()
        return pickPos, atkPos, targetList
    else
        ---@type Entity[]
        local globalTrapGroupEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
        local tSelectedTrap = {}
        for _, e in ipairs(globalTrapGroupEntities) do
            if (not e:HasDeadMark()) and (e:TrapID():GetTrapID() == policyParam.healTrapID) and (table.Vector2Include(validPosList, e:GetGridPosition())) then
                table.insert(tSelectedTrap, e)
            end
        end
        if #tSelectedTrap > 0 then
            local firstTrap = table.remove(tSelectedTrap, 1)
            local trapGridPos = firstTrap:GetGridPosition()
            return {trapGridPos}, {trapGridPos}, {}
        else
            local pickPos, atkPos, targetList = self:_CalPickupPosPolicyPet1601751SummonHealTrap(petEntity, activeSkillID, policyParam, casterPos, validPosList, validPosIdxList)
            return pickPos, atkPos, targetList
        end
    end
end

function AutoFightService:_CalPickupPosPolicyPet1601751SummonHealTrap(petEntity, activeSkillID, policyParam, casterPos, validPosList, validPosIdxList)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local pool = {}
    for _, v2 in ipairs(validPosList) do
        local tTrapEntities = utilData:GetAllTrapEntitiesAtPosByTrapID(v2, policyParam.healTrapID)
        if #tTrapEntities == 0 then
            table.insert(pool, v2)
        end
    end

    if #pool == 0 then
        return {}, {}, {}
    end

    local luckyPosIndex = math.random(1, #pool)
    local luckyPos = table.remove(pool, luckyPosIndex)
    return {luckyPos}, {luckyPos}, {}
end

function AutoFightService:_OnLocalCastActivePickSkillFail(errorStep,errorType,activeSkillID,petEntity,pickUpGridPos)
    local pickPosList = {}
    if petEntity then
        if petEntity:HasPreviewPickUpComponent() then
            ---@type PreviewPickUpComponent
            local previewPickUpComponent = petEntity:PreviewPickUpComponent()
            if previewPickUpComponent then
                pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
            end
        end
    end
    local cmd = ClientExceptionReportCommand.CreateAutoFightPickErrorReport(activeSkillID,errorStep,errorType,pickPosList,pickUpGridPos)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClientExceptionReport, cmd)
end

function AutoFightService:ClearPetActiveSkillTempData()
    local globalPetRenderEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Pet)
    for _, e in ipairs(globalPetRenderEntities) do
        local cPetRender = e:PetRender()
        if cPetRender then
            cPetRender:ClearPet1601751HPAboveLimitAutoCastActiveCount()
        end
    end
end
--仲胥 1技能 选离队伍最近的非火格子（无怪、可召唤机关）召唤机关
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetZhongxuMain(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    ---@type UtilDataServiceShare
    local udsvc = self._world:GetService("UtilData")

    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local casterPosIndex = self:_Pos2Index(casterPos)
    local firstPickPos
    local blackFistEnemyPos = nil
    if self._world:MatchType() == MatchType.MT_BlackFist then
        if petEntity:HasPet() then
            local enemy = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
            blackFistEnemyPos = enemy:GetGridPosition()
        end
    end
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local color = env.BoardPosPieces[posIdx]
            if color and color ~= PieceType.Red then
                if self._world:MatchType() == MatchType.MT_BlackFist then
                    if blackFistEnemyPos ~= pos then
                        firstPickPos = pos
                        break
                    end
                else
                    local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(pos)
                    if not isHasMonster then
                        firstPickPos = pos
                        break
                    end
                end
            end
        end
    end
    if firstPickPos then
        return { firstPickPos }, { firstPickPos }, {}
    else
        return {}, {}, {}
    end
end

--仲胥 2技能 先点1技能召唤的机关，然后随意一个方向，点方向上可以点的最远格子（只有释放1技能的回合可用,指有机关）
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function AutoFightService:_CalPickPosPolicy_PetZhongxuExtra(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    ---@type Entity
    local trapEntity = nil
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:HasSummoner() and e:Summoner():GetSummonerEntityID() == petEntity:GetID() then
            trapEntity = e
            break
        end
    end
    if not trapEntity then
        return {}, {}, {}
    end
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    ---@type SkillScopeType
    local scopeType = SkillScopeType.ZhongxuForceMovementPickRange
    local scopeParam = nil
    local centerType = nil
    local targetType = nil
    --替换技能范围
    local skillScopeAndTarget = skillConfigData:GetAutoFightSkillScopeTypeAndTargetType()
    if skillScopeAndTarget and ( skillScopeAndTarget.useType == AutoFightScopeUseType.PickPosPolicy)  then
        scopeParam = skillScopeAndTarget.ScopeParam
    else
        return {}, {}, {}
    end
    local centerPos = trapEntity:GetGridPosition()--机关位置作为第一点击位置
    local firstPickPos = centerPos
    --技能范围
    local result = self:_CalcSkillScopeResult(petEntity, skillConfigData, scopeType, scopeParam, centerType, targetType, centerPos)
    if result then
        local attackRange = result:GetAttackRange()
        --取四个方向上最远的点，然后随机
        local upPos = nil
        local downPos = nil
        local leftPos = nil
        local rightPos = nil
        for index, rangePos in ipairs(attackRange) do
            if not upPos or rangePos.y > upPos.y then
                upPos = rangePos
            end
            if not downPos or rangePos.y < downPos.y then
                downPos = rangePos
            end
            if not leftPos or rangePos.x < leftPos.x then
                leftPos = rangePos
            end
            if not rightPos or rangePos.x > rightPos.x then
                rightPos = rangePos
            end
        end
        local secondPickRange = {}
        if upPos then
            table.insert(secondPickRange,upPos)
        end
        if downPos then
            table.insert(secondPickRange,downPos)
        end
        if leftPos then
            table.insert(secondPickRange,leftPos)
        end
        if rightPos then
            table.insert(secondPickRange,rightPos)
        end
        local secondPickRangeCount = #secondPickRange
        if secondPickRangeCount == 0 then
            return {}, {}, {}
        end
        local secondPosIndex = math.random(1, secondPickRangeCount)
        local secondPickPos = secondPickRange[secondPosIndex]
        local pickPosList = {}
        table.insert(pickPosList,firstPickPos)
        table.insert(pickPosList,secondPickPos)
        return pickPosList,pickPosList,{}
    end
    return {}, {}, {}
end

function AutoFightService:_CalPickPosPolicy_PetYeliyaMain(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local env = self._env
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local scopeParamList = skillConfigData._pickUpValidScopeList
    local casterPosIndex = self:_Pos2Index(casterPos)
    local checkDamageSkillID = 30018411
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()
    if policyParam then
        if policyParam.checkDamageSkillID then
            checkDamageSkillID = tonumber(policyParam.checkDamageSkillID)
        end
    end

    local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local tmpPickList = {}
    --根据已点选数量 取不同范围
    if #scopeParamList > 0 then
        local totalScopeParam = scopeParamList[1]
        if totalScopeParam:GetScopeType() == SkillScopeType.ScopeByPickNum then
            local subScopeParamList = totalScopeParam:GetScopeParamData()
            if subScopeParamList then
                --第一个点 优先选范围内的强化格，没有强化格的时候选能打到最多目标的点
                local subParam = subScopeParamList[1]
                ---技能范围
                ---@type SkillPreviewScopeParam
                local validScopeParam =
                    SkillPreviewScopeParam:New(
                        {
                            TargetType = subParam.targetType,
                            ScopeType = subParam.scopeType,
                            ScopeCenterType = subParam.scopeCenterType,
                            TargetTypeParam = subParam.targetTypeParam
                        }
                    )
                validScopeParam:SetScopeParamData(subParam.scopeParam)

                local validGirdList = utilScopeSvc:BuildScopeGridList({ validScopeParam }, petEntity)
                local invalidGridList =
                utilScopeSvc:BuildScopeGridList(skillConfigData._pickUpInvalidScopeList, petEntity)
                local invalidGridDict = {}
                for _, invalidPos in ipairs(invalidGridList) do
                    invalidGridDict[self:_Pos2Index(invalidPos)] = true
                end
                local validPosIdxList = {}
                local validPosList = {}
                for _, validPos in ipairs(validGirdList) do
                    local validPosIdx = self:_Pos2Index(validPos)
                    if not invalidGridDict[validPosIdx] then
                        validPosIdxList[validPosIdx] = true
                        validPosList[#validPosList + 1] = validPos
                    end
                end
                local firstPickPos
                local lastPickPos
                local lastPickSuperGrid = false
                local testPickPos = nil
                --第一个点 先找范围内强化格
                testPickPos = self:_YeliyaFindValidPosWithSuperGrid(petEntity,casterPos,validPosIdxList,tmpPickList)
                if testPickPos then
                    firstPickPos = testPickPos
                    lastPickPos = testPickPos
                    lastPickSuperGrid = true
                    table.insert(tmpPickList, firstPickPos)
                else
                    --没找到强化格，则找能攻击到敌人的点（取目标最多的位置）
                    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,casterPos,validPosIdxList,tmpPickList,checkDamageSkillID)
                    if testPickPos then
                        firstPickPos = testPickPos
                        lastPickPos = testPickPos
                        lastPickSuperGrid = false
                        table.insert(tmpPickList, firstPickPos)
                    else
                        --都没有就不放了
                        return {},{},{}
                    end
                end
                --后续点
              
                if firstPickPos then
                    if not lastPickSuperGrid then--第一个不是点的强化格，则没有后续点击了
                    else
                        --循环 点到强化格就继续找
                        local subPickFinish = false
                        local maxFindTimes = 30--限制一下循环
                        local findNextTimes = 0
                        subParam = subScopeParamList[2]
                        ---技能范围
                        local validScopeParam =
                            SkillPreviewScopeParam:New(
                                {
                                    TargetType = subParam.targetType,
                                    ScopeType = subParam.scopeType,
                                    ScopeCenterType = subParam.scopeCenterType,
                                    TargetTypeParam = subParam.targetTypeParam
                                }
                            )
                        validScopeParam:SetScopeParamData(subParam.scopeParam)
                        while not subPickFinish do
                            findNextTimes = findNextTimes + 1
                            if findNextTimes > maxFindTimes then
                                subPickFinish = true
                                break
                            end
                            if lastPickSuperGrid then
                                --后续点 优先强化格，没有则向最近的敌人靠近
                                local subScopeResult = self._utilScopeSvc:CalcSKillPreviewScopeResult(validScopeParam, lastPickPos, petEntity)
                                local validGirdList = subScopeResult:GetAttackRange()
                                --validGirdList = utilScopeSvc:BuildScopeGridListMultiPick({ validScopeParam }, petEntity, tmpPickList)
                                local validPosIdxList = {}
                                local validPosList = {}
                                for _, validPos in ipairs(validGirdList) do
                                    local validPosIdx = self:_Pos2Index(validPos)
                                    if not invalidGridDict[validPosIdx] then
                                        validPosIdxList[validPosIdx] = true
                                        validPosList[#validPosList + 1] = validPos
                                    end
                                end
                                local nextPickPos
                                testPickPos = self:_YeliyaFindValidPosWithSuperGrid(petEntity,lastPickPos,validPosIdxList,tmpPickList)
                                if testPickPos then
                                    nextPickPos = testPickPos
                                    lastPickPos = testPickPos
                                    lastPickSuperGrid = true
                                    table.insert(tmpPickList, nextPickPos)
                                else
                                    --没找到强化格，则找能攻击到敌人的点（取目标最多的位置）
                                    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,lastPickPos,validPosIdxList,tmpPickList,checkDamageSkillID)
                                    if testPickPos then
                                        nextPickPos = testPickPos
                                        lastPickPos = testPickPos
                                        lastPickSuperGrid = false
                                        table.insert(tmpPickList, nextPickPos)
                                    else
                                        --都没有 找离怪最近
                                        testPickPos = self:_YeliyaFindValidPosNearToMonster(petEntity,lastPickPos,validPosIdxList,validPosList, tmpPickList)
                                        if testPickPos then
                                            nextPickPos = testPickPos
                                            lastPickPos = testPickPos
                                            lastPickSuperGrid = false
                                            table.insert(tmpPickList, nextPickPos)
                                        end
                                    end
                                    --后续没有点到强化格就不继续了
                                    subPickFinish = true
                                end
                            end
                        end
                    end
                    if tmpPickList and #tmpPickList > 0 then
                        pickPosList = tmpPickList
                        --retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPosList)
                    end
                end
            end
        end
    end
    return pickPosList, retScopeResult, retTargetIds
end
function AutoFightService:_CalPickPosPolicy_PetYeliyaExtra(petEntity, activeSkillID, casterPos, validPosList, validPosIdxList)
    local boardService = self._world:GetService("BoardLogic")
    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(activeSkillID)
    local checkDamageSkillID = 30018411
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()
    if policyParam then
        if policyParam.checkDamageSkillID then
            checkDamageSkillID = tonumber(policyParam.checkDamageSkillID)
        end
    end

    local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local testPickPos = nil
    local tmpPickList = {}
    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,casterPos,validPosIdxList,tmpPickList,checkDamageSkillID)
    if testPickPos then
        table.insert(pickPosList, testPickPos)
        --retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPosList)
    else
        return {},{},{}
    end
    return pickPosList, retScopeResult, retTargetIds
end
function AutoFightService:_YeliyaFindValidPosWithSuperGrid(petEntity,centerPos,validPosIdxList,alreadyPickList)
    local pickPos = nil
    ---@type UtilDataServiceShare
    local utilDataSvc = self._utilSvc
    ---@type BoardServiceLogic
    local boardService = self._boardServiceLogic
    local ringMax = boardService:GetCurBoardRingMax()
    local centerPosIndex = self:_Pos2Index(centerPos)
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(centerPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            if not table.icontains(alreadyPickList,pos) then
                local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                if not isBlockedLinkLine then
                    local traps = utilDataSvc:GetTrapsAtPos(pos)
                    if traps then
                        for index, e in ipairs(traps) do
                            if e:Trap():IsSuperGrid() then
                                pickPos = pos
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return pickPos
end
function AutoFightService:_YeliyaFindValidPosWithMaxTargetCount(petEntity,centerPos,validPosIdxList,alreadyPickList,checkDamageSkillID)
    local pickPos = nil

    checkDamageSkillID = 30018411
    ---@type BoardServiceLogic
    local boardService = self._boardServiceLogic
    local ringMax = boardService:GetCurBoardRingMax()
    local centerPosIndex = self:_Pos2Index(centerPos)
    local maxTargetCount = 0
    local maxTargetPos = nil
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(centerPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            if not table.icontains(alreadyPickList,pos) then
                local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                if not isBlockedLinkLine then
                    local result, targetIds = self:_CalcSkillScopeResultAndTargets(petEntity, checkDamageSkillID, pos)
                    if targetIds then
                        local targetCount = #targetIds
                        if targetCount > maxTargetCount then
                            maxTargetCount = targetCount
                            maxTargetPos = pos
                        end
                    end
                end
            end
        end
    end
    if maxTargetPos then
        pickPos = maxTargetPos
    end
    return pickPos
end
function AutoFightService:_YeliyaFindValidPosNearToMonster(petEntity,centerPos,validPosIdxList,validPosList,alreadyPickList)
    local pickPos = nil

    ---@type BuffLogicService
    local buffLogicSvc = self._world:GetService("BuffLogic")
    ---@type BoardServiceLogic
    local boardService = self._boardServiceLogic
    local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local validEnemyList = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemyTeam = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
        table.insert(validEnemyList,enemyTeam)
    else
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                table.insert(validEnemyList,monsterEntity)
            end
        end
    end
    if validEnemyList and #validEnemyList > 0 then
        --先找个离中心点最近的怪
        local enemyPosList = {}
        for index, enemyEntity in ipairs(validEnemyList) do
            local enemyPos = enemyEntity:GetGridPosition()
            local tv2BodyArea = enemyEntity:BodyArea():GetArea()
            for _, v2Relative in ipairs(tv2BodyArea) do
                ---@type Vector2
                local v2 = enemyPos + v2Relative
                table.insert(enemyPosList,v2)
            end
        end
        local sortedEnemyPosList = HelperProxy:SortPosByCenterPosDistance(centerPos, enemyPosList)
        if sortedEnemyPosList and #sortedEnemyPosList > 0 then
            local nearestPos = sortedEnemyPosList[1]
            local sortedValidPosList = HelperProxy:SortPosByCenterPosDistance(nearestPos, validPosList)
            if sortedValidPosList then
                for index, pos in ipairs(sortedValidPosList) do
                    if not table.icontains(alreadyPickList,pos) then
                        local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                        if not isBlockedLinkLine then
                            pickPos = pos
                            break
                        end
                    end
                end
            end
        end
    end
    return pickPos
end