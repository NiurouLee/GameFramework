require("main_world")
_class("GMCheat", Object)
GMCheat = GMCheat

function GMCheat:Constructor(world)
    self._world = world
end

function GMCheat:BattleCheatHeroMaxHP()
    ---@type Entity
    local e = self._world:Player():GetLocalTeamEntity()
    local maxhp = 9999999
    e:Attributes():Modify("MaxHP", maxhp)
    e:Attributes():Modify("HP", maxhp)
    if self._world:RunAtClient() then
        e:ReplaceRedAndMaxHP(maxhp, maxhp)
    end
end

function GMCheat:BattleCheatTeamPowerFull(teamEntity)
    if not teamEntity then
        teamEntity = self._world:Player():GetLocalTeamEntity()
    end
    local teamMembers = teamEntity:Team():GetTeamPetEntities()
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type PlayBuffService
    local playBuffService = self._world:GetService("PlayBuff")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")

    for _, e in ipairs(teamMembers) do
        local petPstIDComponent = e:PetPstID()
        local petPstID = petPstIDComponent:GetPstID()
        local activeSkillID = e:SkillInfo():GetActiveSkillID()
        ---@type SkillConfigData
        local skillConfigData = configService:GetSkillConfigData(activeSkillID)

        --传说光灵不处理cd
        if skillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
            local curLegendPower = e:Attributes():GetAttribute("LegendPower")
            local newLegendPower = curLegendPower + 10
            if newLegendPower > BattleConst.LegendPowerMax then
                newLegendPower = BattleConst.LegendPowerMax
            end
            e:Attributes():Modify("LegendPower", newLegendPower)
            self._world:EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, newLegendPower)
        elseif skillConfigData:GetSkillTriggerType() == SkillTriggerType.BuffLayer then
            local costLayer = skillConfigData:GetSkillTriggerParam()
            local extraParam = skillConfigData:GetSkillTriggerExtraParam()
            local buffEffectType = extraParam.buffEffectType
            ---@type BuffLogicService
            local blsvc = self._world:GetService("BuffLogic")
            local currentVal = blsvc:GetBuffLayer(e, buffEffectType)
            blsvc:SetBuffLayer(e, buffEffectType, costLayer, true)
            self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, true)
        else
            e:Attributes():Modify("Power", 0)
            self._world:EventDispatcher():Dispatch(GameEventType.PetPowerChange, petPstID, 0)
        end

        e:Attributes():Modify("Ready", 1)
        self._world:EventDispatcher():Dispatch(GameEventType.PetActiveSkillGetReady, petPstID, true, false)

        local extraSkillList = e:SkillInfo():GetExtraActiveSkillIDList()
        if extraSkillList then
            for _, extraSkillID in ipairs(extraSkillList) do
                ---@type SkillConfigData
                local extraSkillConfigData = configService:GetSkillConfigData(extraSkillID)
                if extraSkillConfigData then
                    --传说光灵不处理cd
                    if extraSkillConfigData:GetSkillTriggerType() == SkillTriggerType.LegendEnergy then
                        local curLegendPower = e:Attributes():GetAttribute("LegendPower")
                        local newLegendPower = curLegendPower + 10
                        if newLegendPower > BattleConst.LegendPowerMax then
                            newLegendPower = BattleConst.LegendPowerMax
                        end
                        e:Attributes():Modify("LegendPower", newLegendPower)
                        self._world:EventDispatcher():Dispatch(GameEventType.PetLegendPowerChange, petPstID, newLegendPower)
                    else
                        utilData:SetPetPowerAttr(e,0,extraSkillID)
                        self._world:EventDispatcher():Dispatch(GameEventType.PetExtraPowerChange, petPstID,extraSkillID, 0,true)
                    end
                    utilData:SetPetSkillReadyAttr(e,1,extraSkillID)
                    self._world:EventDispatcher():Dispatch(GameEventType.PetExtraActiveSkillGetReady, petPstID,extraSkillID, true, false)
                end
                
            end
        end
    end
    ---@type FeatureServiceLogic
    local lsvcFeature = self._world:GetService("FeatureLogic")
    if lsvcFeature then
        self:_BattleCheatFeatureSkillFull(lsvcFeature,FeatureType.PersonaSkill)
        self:_BattleCheatFeatureSkillFull(lsvcFeature,FeatureType.MasterSkill)
        self:_BattleCheatFeatureSkillFull(lsvcFeature,FeatureType.MasterSkillRecover)
        self:_BattleCheatFeatureSkillFull(lsvcFeature,FeatureType.MasterSkillTeleport)
    end
    if playBuffService and self._world:RunAtClient() then
        TaskManager:GetInstance():CoreGameStartTask(playBuffService.PlayAutoAddBuff, playBuffService)
    end
end
---@param lsvcFeature FeatureServiceLogic
function GMCheat:_BattleCheatFeatureSkillFull(lsvcFeature,featureType)
    if lsvcFeature then
        if lsvcFeature:HasFeatureType(featureType) then
            lsvcFeature:SetFeatureSkillCurPower(featureType,0,1)
            self._world:EventDispatcher():Dispatch(GameEventType.PersonaPowerChange, featureType,0, 1)
        end
    end
end
--怪无敌
function GMCheat:BattleCheatMonsterInvincible()
    local _group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local cheatHp = 9999999
    for _, e in ipairs(_group:GetEntities()) do
        e:Attributes():Modify("HP", cheatHp)
        e:Attributes():Modify("MaxHP", cheatHp)
        if self._world:RunAtClient() then
            e:ReplaceRedAndMaxHP(cheatHp, cheatHp)
        end
    end
    Log.fatal("使用作弊按钮怪满血！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！")
end

--人攻击力
function GMCheat:BattleCheatAttackMax(nMaxAttack)
    local teamMembers = self._world:Player():GetLocalTeamEntity():Team():GetTeamPetEntities()
    for _, e in ipairs(teamMembers) do
        e:Attributes():Modify("Attack", nMaxAttack, 99999)
    end
    Log.fatal("使用作弊按钮人满攻击！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！")
end
--测试 中途加光灵
function GMCheat:BattleCheatAddPet(createInfo)
    ---@type MainWorld
    local mainWorld = self._world

    ---@type PartnerServiceLogic
    local lsvcPartner = mainWorld:GetService("PartnerLogic")
    local petEntity,petInfo,matchPet,petRes,hp,maxHP = lsvcPartner:CreateMiddleEnterPet(createInfo)
    if not petEntity then
        return
    end
    local svc = self._world:GetService("L2R")
    local fakePartnerID = 1--这个参数目前没用到，随便填一个
    svc:L2RAddPartnerData(fakePartnerID,petInfo,matchPet,petRes,hp,maxHP)
    Log.fatal("使用作弊按钮加光灵！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！！")
end

--人攻击力回复正常
function GMCheat:BattleCheatGetRight()
    local teamMembers = self._world:Player():GetLocalTeamEntity():Team():GetTeamPetEntities()
    for _, e in ipairs(teamMembers) do
        e:Attributes():RemoveModify("Attack", 99999)
    end
end

-- 杀死所有敌人
function GMCheat:BattleKillMonsters()
    if self._world:MatchType()==MatchType.MT_BlackFist then
        local teamEntity = self._world:Player():GetRemoteTeamEntity()
        teamEntity:Attributes():Modify("HP", 0)
        teamEntity:AddTeamDeadMark()
    end
    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monster_entities = monster_group:GetEntities()
    for _, v in pairs(monster_entities) do
        v:Attributes():Modify("HP", 0)
        sMonsterShowLogic:AddMonsterDeadMark(v)
        if self._world:RunAtClient() then
            v:ReplaceRedHPAndWhitHP(0)
            v:AddDeadFlag()
        end
    end
    sMonsterShowLogic:DoAllMonsterDeadLogic()
    Log.fatal("使用作弊按钮杀死全部怪物！！！！！！！！！！")

    if self._world:RunAtServer() then
        self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 5)
    else
        TaskManager:GetInstance():CoreGameStartTask(
            function(TT)
                ---@type MonsterShowRenderService
                local sMonsterShowRender = self._world:GetService("MonsterShowRender")
                sMonsterShowRender:DoAllMonsterDeadRender(TT)
                self._world:EventDispatcher():Dispatch(GameEventType.WaitInputFinish, 5)
            end
        )
    end
end

--给队长挂buff
function GMCheat:BattleCheatAddBuffHero(buffID)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    ---@type Entity
    local team = self._world:Player():GetLocalTeamEntity()
    local buff = buffLogicService:AddBuff(buffID, team)
    ---@type PlayBuffService
    local player = self._world:GetService("PlayBuff")
    if player and buff and self._world:RunAtClient() then
        TaskManager:GetInstance():CoreGameStartTask(player.PlayAutoAddBuff, player)
    end
end

--给怪物挂buff
function GMCheat:BattleCheatAddBuffAllMonsters(buffID)
    ---@type BuffLogicService
    local buffLogicService = self._world:GetService("BuffLogic")
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for i, e in ipairs(group:GetEntities()) do
        local buff = buffLogicService:AddBuff(buffID, e)

        ---@type PlayBuffService
        local player = self._world:GetService("PlayBuff")
        if player and buff and self._world:RunAtClient() then
            TaskManager:GetInstance():CoreGameStartTask(player.PlayAutoAddBuff, player)
        end
    end
end

-- 移出buff
function GMCheat:BattleCheatRemoveBuffHero(buffID)
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local hero = self._world:Player():GetLocalTeamEntity()
    ---@type BuffComponent
    local buffComponent = hero:BuffComponent()
    ---@type PlayBuffService
    local player = self._world:GetService("PlayBuff")
    local buffArray = buffComponent:GetBuffArray()
    if buffArray then
        local notify=NTBuffUnload:New()
        for i, buff in ipairs(buffArray) do
            if buff:BuffID() == buffID then
                buff:Unload(notify)
                if self._world:RunAtClient() then
                    TaskManager:GetInstance():CoreGameStartTask(player.PlayBuffView, player, notify)
                end
            end
        end
    end
end

function GMCheat:BattleCheatChangeAllMonstersHPPercent(hpPercent)
    if not hpPercent then
        hpPercent = 100
    end

    if self._world:MatchType() == MatchType.MT_BlackFist then
        ---@type Entity
        local teamEntity = self._world:Player():GetRemoteTeamEntity()
        ---@type AttributesComponent
        local attributeCmpt = teamEntity:Attributes()
        local maxHp = attributeCmpt:CalcMaxHp()
        local newHP = math.floor(maxHp * hpPercent / 100)
        teamEntity:Attributes():Modify("HP", newHP)
        if self._world:RunAtClient() then
            teamEntity:ReplaceRedHPAndWhitHP(newHP)

            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, teamEntity:GetID(), hpPercent / 100, newHP, maxHp)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, teamEntity:GetID(), hpPercent / 100, newHP, maxHp)
        end
        return
    end

    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(group:GetEntities()) do
        local attributeCmpt = e:Attributes()
        if attributeCmpt then
            local maxHP = attributeCmpt:CalcMaxHp()
            local newHP = math.floor(maxHP * hpPercent / 100)
            e:Attributes():Modify("HP", newHP)
            if self._world:RunAtClient() then
                e:ReplaceRedHPAndWhitHP(newHP)
            end
        end
    end
end

function GMCheat:BattleCheatCreateMonster(id,pos,dir)
    ---@type configService
    local configService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = configService:GetMonsterConfigData()
    local temp = monsterConfigData:GetMonsterObject(id)
    if not temp then
        Log.fatal("MonsterID Invalid ID:", id)
        return
    end

    ---@type MonsterCreationServiceLogic
    local logic = self._world:GetService("MonsterCreationLogic")

    ---@type MonsterShowRenderService
    local render = self._world:GetService("MonsterShowRender")
    ---@type MonsterTransformParam
    local monsterTransformParam = MonsterTransformParam:New(id)
    monsterTransformParam:SetPosition(pos)
    monsterTransformParam:SetForward(dir)
    monsterTransformParam:SetRotation(dir)
    local monsterEntity, _ = logic:CreateMonster(monsterTransformParam)
    if self._world:RunAtClient() then
        GameGlobal.TaskManager():CoreGameStartTask(
            render.ShowSummonMonster,
            render,
            monsterEntity,
            monsterTransformParam
        )
    end
end

function GMCheat:BattleCheatCreateTrap(id,pos,dir)

    ---@type configService
    local configService = self._world:GetService("Config")

    ---@type TrapConfigData
    local trapConfigData = configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(id)
    if not trapData then
        Log.fatal("TrapID Invalid ID:", id)
        return
    end

    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")

    ---@type TrapServiceRender
    local trapServiceRender = self._world:GetService("TrapRender")

    local trap = trapServiceLogic:CreateTrap(id, pos, dir, false)
    if self._world:RunAtClient() then
        local svc = self._world:GetService("L2R")
        svc:L2RBoardLogicData()
        GameGlobal.TaskManager():CoreGameStartTask(trapServiceRender.ShowTraps, trapServiceRender, {trap})
    end
end

function GMCheat:BattleCheatSetBoardPiece(pieceType)
    if not pieceType then
        pieceType = 1
    end
    ---@type BoardComponent
    local component = self._world:GetBoardEntity():Board()
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local pieceTable = component:ClonePieceTable()
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    for x, col in pairs(pieceTable) do
        for y, v in pairs(col) do
            local grid = Vector2(x, y)
            if boardService:GetCanConvertGridElement(grid) and v ~= PieceType.None then
                boardService:SetPieceTypeLogic(pieceType, grid)
            end
        end
    end

    for x, col in pairs(pieceTable) do
        for y, v in pairs(col) do
            local grid = Vector2(x, y)
            if boardRenderSvc and boardService:GetCanConvertGridElement(grid) and v ~= PieceType.None then
                boardRenderSvc:ReCreateGridEntity(pieceType, grid, false, false, true)
            end
        end
    end
    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

function GMCheat:BattleCheatSetOnePiece(pos, pieceType)
    if not pos then
        return
    end
    if not pieceType then
        pieceType = 1
    end
    ---@type BoardComponent
    local component = self._world:GetBoardEntity():Board()
    local boardService = self._world:GetService("BoardLogic")
    local pieceTable = component:ClonePieceTable()
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    if boardService:GetCanConvertGridElement(pos) then
        boardService:SetPieceTypeLogic(pieceType, pos)
    end

    if boardRenderSvc then
        boardRenderSvc:ReCreateGridEntity(pieceType, pos, false, false, true)
    end
    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

function GMCheat:BattleCheatSetEveryPiece(pieceTypeArray)
    if not pieceTypeArray then
        return
    end
    ---@type BoardComponent
    local component = self._world:GetBoardEntity():Board()
    local boardService = self._world:GetService("BoardLogic")
    local pieceTable = component:ClonePieceTable()
    ---@type BoardServiceRender
    local boardRenderSvc = self._world:GetService("BoardRender")
    for x, col in pairs(pieceTable) do
        for y, v in pairs(col) do
            local grid = Vector2(x, y)
            if boardService:GetCanConvertGridElement(grid) and v ~= PieceType.None then
                boardService:SetPieceTypeLogic(pieceTypeArray[x][y], grid)
            end
        end
    end

    for x, col in pairs(pieceTable) do
        for y, v in pairs(col) do
            local grid = Vector2(x, y)
            if boardRenderSvc and v ~= PieceType.None then
                boardRenderSvc:ReCreateGridEntity(pieceTypeArray[x][y], grid, false, false, true)
            end
        end
    end
    --更新表现数据
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

function GMCheat:BattleCheatChangePetHPPercent(hpPercent)
    if not hpPercent then
        hpPercent = 100
    end

    ---@type Entity
    local teamEntity = self._world:Player():GetLocalTeamEntity()
    ---@type AttributesComponent
    local attributeCmpt = teamEntity:Attributes()
    local maxHp = attributeCmpt:CalcMaxHp()
    local newHP = math.floor(maxHp * hpPercent / 100)
    teamEntity:Attributes():Modify("HP", newHP)

    if self._world:RunAtClient() then
        teamEntity:ReplaceRedHPAndWhitHP(newHP)
        ---@type HPComponent
        local hpCmpt = teamEntity:HP()
        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.TeamHPChange,
            {
                isLocalTeam = true,
                currentHP = hpCmpt:GetRedHP(),
                maxHP = hpCmpt:GetMaxHP(),
                hitpoint = hpCmpt:GetWhiteHP(),
                shield = hpCmpt:GetShieldValue(),
                entityID = teamEntity:GetID(),
                showCurseHp = hpCmpt:GetShowCurseHp(),
                curseHpVal = hpCmpt:GetCurseHpValue()
            }
        )
    end
end

function GMCheat:BattleCheatSetAutoFightComplex(complex)
    local idx = BattleConst.AutoFightMoveEnhanced and 2 or 1
    BattleConst.AutoFightPathComplexity[idx] = complex
end

function GMCheat:BattleCheatSetSanVal(val)
    ---@type MainWorld
    local mainWorld = self._world

    ---@type FeatureServiceLogic
    local lsvcFeature = mainWorld:GetService("FeatureLogic")
    local old = lsvcFeature:GetSanValue()
    local delta = val - old
    lsvcFeature:SetSanValue(val)
    if mainWorld:RunAtClient() then
        ---@type FeatureServiceRender
        local rsvcFeature = mainWorld:GetService("FeatureRender")
        rsvcFeature:NotifySanValueChange(val, old, delta)
    end
end
