--[[------------------------------------------------------------------------------------------
    处理怪物和机关预览的功能
]] --------------------------------------------------------------------------------------------

_class("PreviewMonsterTrapService", BaseService)
---@class PreviewMonsterTrapService:BaseService
PreviewMonsterTrapService = PreviewMonsterTrapService

function PreviewMonsterTrapService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
end

function PreviewMonsterTrapService:Initialize()
end

function PreviewMonsterTrapService:Dispose()
end

function PreviewMonsterTrapService:CheckPreviewMonsterAction(posTouch, offset)
    local isTouchMonster, touchMonsterEntityID = self:IsClickMonster(posTouch, offset)
    if isTouchMonster then
        self:ClearPreviewMonster(posTouch)
        self:ClearPreviewTrap(posTouch)
        self:ShowInUIBar(touchMonsterEntityID)
        self:_ShowPreviewMonsterAction(touchMonsterEntityID, posTouch, offset)
        return
    end
    local isTouchTrap, touchTrapEntityID = self:IsClickTrap(posTouch, offset)
    if isTouchTrap then
        ---守护机关也不现实血条,暂时没有显示血条的机关就干掉了
        --self:ShowInUIBar(touchTrapEntityID)
        self:ClearPreviewMonster(posTouch)
        self:ClearPreviewTrap(posTouch)
        self:_ShowPreviewTrapAction(touchTrapEntityID, posTouch, offset)
        return
    end
    self:ClearMonsterTrapPreview()
end

function PreviewMonsterTrapService:ClearMonsterTrapPreview()
    if self:ClearPreviewMonster() then
        self:HideHideInUIBar()
        return
    end

    if self:ClearPreviewTrap() then
        self:HideHideInUIBar()
        return
    end
end

function PreviewMonsterTrapService:IsClickMonster(touchPosition, offset)
    ---@type PreviewEnvComponent
    local previewEnvCmpt = self._world:GetPreviewEntity():PreviewEnv()
    local clickCount = previewEnvCmpt:GetMonsterClickCount()
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(group:GetEntities()) do
        ---@type BuffViewComponent
        local buffView = e:BuffView()
        if e:IsOnGridPosition(touchPosition) then
            if EDITOR then
                ---@type AIDebugModule
                local aiDebugModule = GameGlobal.GetModule(AIDebugModule)
                aiDebugModule:SetSelectMonsterID(e:MonsterID():GetMonsterID(), e:GetID())
            end
            if not buffView:HasBuffEffect(BuffEffectType.NotShowBossHP) then
                if e:HasRide() then
                    if e:Ride():IsOnlyRiderCanClick() then
                        --骑乘，则只有骑乘者返回
                        if e:Ride():GetRiderID() == e:GetID() then
                            return true, e:GetID()
                        end
                    else
                        --根据点击次数返回骑乘者或坐骑ID
                        local isRider = math.fmod(clickCount, 2) == 0
                        if isRider then
                            previewEnvCmpt:SetMonsterClickCount(clickCount + 1)
                            return true, e:Ride():GetRiderID()
                        else
                            previewEnvCmpt:SetMonsterClickCount(clickCount + 1)
                            return true, e:Ride():GetMountID()
                        end
                    end
                else
                    previewEnvCmpt:SetMonsterClickCount(0)
                    return true, e:GetID()
                end
            end
        end
    end
    previewEnvCmpt:SetMonsterClickCount(0)
    return false, nil
end

function PreviewMonsterTrapService:IsClickTrap(posTouch, offset)
    local listFindTrapID = {}
    listFindTrapID = self:_FindTrapByPos(posTouch)

    if table.count(listFindTrapID) > 0 then
        ---@type SortedArray
        local sortTrapID = self:_SortByTrapLevel(listFindTrapID)
        ---@type ConfigService
        local configService = self._world:GetService("Config")
        ---如果同一个格子上有多个机关，显示最上层的配置了机关的预览tips
        for i = 1, sortTrapID:Size() do
            ---@type SortData_TrapLevel
            local sortData = sortTrapID:GetAt(i)
            ---@type Entity
            local entityTrap = sortData:GetTrapEntity()
            local utilSvc = self._world:GetService("UtilData")
            local skillID = utilSvc:GetTrapPreviewSkillID(entityTrap)
            if skillID and skillID > 0 then
                ---@type SkillConfigData 主动技配置数据
                local skillConfigData = configService:GetSkillConfigData(skillID, entityTrap)
                ---下回合可攻击范围
                ---@type SkillPreviewType
                local skillPreviewType = skillConfigData:GetSkillPreviewType()
                if SkillPreviewType.Tips == skillPreviewType or SkillPreviewType.ScopeAndTips == skillPreviewType or
                    SkillPreviewType.TrapActiveSkill == skillPreviewType or
                    SkillPreviewType.TrapDesc == skillPreviewType or
                    SkillPreviewType.TrapScopeAndTips == skillPreviewType or
                    SkillPreviewType.PetTrapMoveArrow == skillPreviewType
                then
                    return true, sortData:GetTrapID()
                end
            else
                ---@type TrapConfigData
                local trapConfigData = configService:GetTrapConfigData()
                if trapConfigData:IsShowDescTips(entityTrap:TrapRender():GetTrapID()) then
                    return true, sortData:GetTrapID()
                end
            end
        end
    end
    return false, nil
end

function PreviewMonsterTrapService:ClearPreviewMonster()
    local reBoard = self._world:GetRenderBoardEntity()
    if EDITOR then
        ---@type AIDebugModule
        local aiDebugModule = GameGlobal.GetModule(AIDebugModule)
        aiDebugModule:ClearSelectMonsterID()
    end
    if reBoard:HasPreviewMonsterAction() then
        ---@type PreviewMonsterActionComponent
        local previewCmpt = reBoard:PreviewMonsterAction()
        if previewCmpt:IsShowMonsterAction() then
            local entityID = previewCmpt:GetMonsterEntityID()
            local e = self._world:GetEntityByID(entityID)
            Log.notice("Entity ID:", e:GetID(), "GridPosition:", tostring(e:GridLocation().Position))
            reBoard:ReplacePreviewMonsterAction(false, entityID)
            self:_HidePreviewMonster(entityID, reBoard)
            return true
        end
    end
    return false
end

function PreviewMonsterTrapService:HidePreviewTrap()
    --Log.fatal("HideTrapAction")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    renderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
    ---因世界boss的芭芭拉使用了格子动画的'silver'，这里需要还原回去
    self._world:GetService("PreviewActiveSkill"):_RevertAllConvertElement(true)
    ---@type PreviewMonsterTrapService
    local prvwActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    prvwActiveSkillSvc:HideSkillTips()
end

function PreviewMonsterTrapService:ClearPreviewTrap()
    local reBoard = self._world:GetRenderBoardEntity()
    if reBoard:HasPreviewTrapAction() then
        ---@type PreviewTrapActionComponent
        local previewCmpt = reBoard:PreviewTrapAction()
        if previewCmpt:IsShowTrapAction() then
            reBoard:ReplacePreviewTrapAction()
            previewCmpt:ShowTrapAction(false)
            self:HidePreviewTrap()
            return true
        end
    end
    return false
end

function PreviewMonsterTrapService:_ShowPreviewMonsterAction(monsterEntityID, touchPosition, offset)
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    reBoard:ReplacePreviewMonsterAction(true, monsterEntityID)
    ---@type PreviewMonsterActionComponent
    local previewCmpt = reBoard:PreviewMonsterAction()
    --previewCmpt:ShowMonsterAction(true)
    --previewCmpt:SetMonsterEntityID(monsterEntityID)
    previewCmpt:SetTouchPosition(touchPosition, offset)
end

function PreviewMonsterTrapService:_ShowPreviewTrapAction(trapEntityID, touchPosition, offset)
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    if not reBoard:HasPreviewTrapAction() then
        reBoard:AddPreviewTrapAction()
    end
    reBoard:ReplacePreviewTrapAction()
    ---@type PreviewTrapActionComponent
    local previewCmpt = reBoard:PreviewTrapAction()
    previewCmpt:ShowTrapAction(true)
    previewCmpt:SetTrapPreviewData(trapEntityID, touchPosition, offset)
end

function PreviewMonsterTrapService:ShowInUIBar(entityID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type Entity
    local entity = self._world:GetEntityByID(entityID)
    if self:IsNeedShowUIHPBar(entityID) then
        ---@type HPComponent
        local HPCmpt = entity:HP()
        local maxHP = HPCmpt:GetMaxHP()
        local HP = HPCmpt:GetRedHP()
        local hpPercent = HP / maxHP
    local shieldValue = HPCmpt:GetShieldValue()
        local templateID
        local hpBarType
        local elementType
        local sepHPList = entity:HP():GetHPLockSepList()
        local sepHpUnlockedList = entity:HP():GetHPLockUnlockedIndexList()
        local showCurseHp = HPCmpt:GetShowCurseHp()
        local curseHpVal = HPCmpt:GetCurseHpValue()
        local isWorldBoss = false
        local worldBossCurHPImageID = 0
        local worldBossPreHPImageID = 0
        local worldBossCurStageHpPercent = 0
        local worldBossTotalDamage = 0
        local worldBossCurStage = 0

        if entity:MonsterID() then
            templateID = entity:MonsterID():GetMonsterID()
            ---@type MonsterIDComponent
            local cMonsterId = entity:MonsterID()
            if cMonsterId:IsWorldBoss() then
                ---@type MonsterConfigData
                --local monsterConfigData = self._configService:GetMonsterConfigData()
                --local stage, imageData = monsterConfigData:GetWorldBossConfig(templateID)
                isWorldBoss = true
                local hpCmpt = entity:HP()
                worldBossCurHPImageID = hpCmpt:GetCurStageImage()
                worldBossPreHPImageID = hpCmpt:GetPreStageImage()
                worldBossCurStageHpPercent = 1 - hpCmpt:GetCurStageHPPercent()
                worldBossTotalDamage = BattleStatHelper.GetMonsterBeHitDamageValue(entityID)
                worldBossCurStage = hpCmpt:GetCurStage()
            end
            if entity:HasBoss() then
                if entity:MonsterID():IsEliteMonster() then
                    hpBarType = HPBarType.EliteBoss
                else
                    hpBarType = HPBarType.Boss
                end
            else
                if entity:MonsterID():IsEliteMonster() then
                    hpBarType = HPBarType.EliteMonster
                else
                    hpBarType = HPBarType.NormalMonster
                end
            end

            elementType = utilDataSvc:GetEntityAttributeByName(entity, "Element")
        end
        if entity:TrapID() then
            templateID = entity:TrapID():GetTrapID()
            hpBarType = HPBarType.Trap
        end

        local greyVal = utilDataSvc:GetEntityBuffValue(entity, "GreyHPValue") or 0

        local hpEnergyBuffEffectType = utilDataSvc:GetEntityBuffValue(entity, "HPEnergyBuffEffectType")
        local hpEnergyVal = 0
        local maxHPEnergyVal = 0
        if hpEnergyBuffEffectType then
            hpEnergyVal = utilDataSvc:GetBuffLayer(entity, hpEnergyBuffEffectType)
            ---@type BuffViewInstance
            local bvinst = InnerGameHelperRender.GetSingleBuffByBuffEffect(entityID, hpEnergyBuffEffectType)
            if bvinst then
                maxHPEnergyVal = bvinst:BuffConfigData():GetMaxLayerCount()
            end
            maxHPEnergyVal = math.max(hpEnergyVal, maxHPEnergyVal)
        end
        ---@class UIBossHPInfoData
        local info = {
            pstId = entityID,
            tplId = templateID,
            HPBarType = hpBarType,
            sepHPList = sepHPList,
            sepHpUnlockedList = sepHpUnlockedList,
            entity = entity,
            percent = hpPercent,
            hP = HP,
            HP = HP,
            maxHP = maxHP,
            shieldValue = shieldValue,
            curElement = elementType,
            attack = utilDataSvc:GetEntityAttack(entity) or 0, -- 如果不判断，GetAttack内部会nil * number
            greyVal = greyVal,
            hpEnergyVal = hpEnergyVal,
            maxHPEnergyVal = maxHPEnergyVal,
            showCurseHp = showCurseHp,
            curseHpVal = curseHpVal,
            --世界boss 处理
            isWorldBoss = isWorldBoss,
            worldBossCurImageID = worldBossCurHPImageID,
            worldBossPreImageID = worldBossPreHPImageID,
            worldBossCurStageHpPercent = worldBossCurStageHpPercent,
            worldBossTotalDamage = worldBossTotalDamage,
            worldBossCurStage = worldBossCurStage,
        }
        GameGlobal.EventDispatcher():Dispatch(GameEventType.PreviewMonsterReplaceHPBar, info)
    end
end

function PreviewMonsterTrapService:HideHideInUIBar()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RevokePreviewMonsterReplaceHPBar)
end

function PreviewMonsterTrapService:_HidePreviewMonster(monsterEntityID, boardEntity)
    ---@type PreviewMonsterActionComponent
    local previewCmpt = boardEntity:PreviewMonsterAction()
    previewCmpt:KillPreviewTask()

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---@type Entity[]
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterAttackRange)

    renderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
    ---@type PreviewMonsterTrapService
    local previewActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    ---previewActiveSkillSvc:AllPieceDoConvert("Normal")
    self._world:GetService("MonsterShowRender"):MonsterGridAnimDown()

    ---@type PreviewMonsterTrapService
    local previewActiveSkillSvc = self._world:GetService("PreviewActiveSkill")
    previewActiveSkillSvc:HideSkillTips()
    self:_RemoveMonsterAttackText(monsterEntityID)

    --SkillEffectType.ShowWarningArea做技能预警   然后点击取消的话  这个effectResult还存在  需要清除掉 否则会刷出来
    local monsterEntity = self._world:GetEntityByID(monsterEntityID)
    if monsterEntity then
        ---@type SkillEffectResultContainer
        local resContainer = monsterEntity:SkillRoutine():GetResultContainer()
        if resContainer then
            resContainer:Clear()
        end
    end
end

function PreviewMonsterTrapService:_RemoveMonsterAttackText(monsterEntityID)
    local monsterEntity = self._world:GetEntityByID(monsterEntityID)
    ---@type EffectHolderComponent
    local holderCmp = monsterEntity:EffectHolder()
    if not holderCmp then
        return
    end
    local idDic = holderCmp:GetEffectIDEntityDic()
    local entityList = idDic[BattleConst.MonsterAttackRangeTextEffect]
    if entityList then
        for k, entityId in pairs(entityList) do
            local entity = self._world:GetEntityByID(entityId)
            if entity then
                self._world:DestroyEntity(entity)
            end
        end
        idDic[BattleConst.MonsterAttackRangeTextEffect] = nil
    end
end

function PreviewMonsterTrapService:IsNeedShowUIHPBar(entityID)
    ---@type Entity
    local entity = self._world:GetEntityByID(entityID)
    if entity:HasBoss() then
        --local gMonster = self._world:GetGroup(self._world.BW_WEMatchers.Boss)
        --local eBossList = gMonster:GetEntities()
        --if table.count(eBossList) >1 then
        --    return entity:HasHP() and entity:HP():IsShowHPSlider()
        --else
        --    return true
        --end
        return true
    else
        return entity:HasHP() and entity:HP():IsShowHPSlider()
    end
end

function PreviewMonsterTrapService:_FindTrapByPos(posTouch)
    local listFindTrapID = {}
    local teTrap = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, eTrap in ipairs(teTrap) do
        if eTrap:TrapRender():IsHasShow() and eTrap:IsViewVisible() then
            local cBodyArea = eTrap:BodyArea()
            local tv2Relative = cBodyArea and cBodyArea:GetArea() or { Vector2.zero }
            local v2GridPos = eTrap:GetGridPosition()
            for __, v2Relative in ipairs(tv2Relative) do
                if posTouch == v2GridPos + v2Relative then
                    table.insert(listFindTrapID, eTrap:GetID())
                end
            end
        end
    end
    return listFindTrapID
end

---根据机关层排序
function PreviewMonsterTrapService:_SortByTrapLevel(listTrapEntityID)
    local sortTrapID = SortedArray:New(Algorithm.COMPARE_CUSTOM, SortData_TrapLevel.CompareByTrapLevel)
    for i = 1, #listTrapEntityID do
        sortTrapID:Insert(SortData_TrapLevel:New(self._world, listTrapEntityID[i]))
    end
    return sortTrapID
end

--region SortData_TrapLevel 机关层排序

_class("SortData_TrapLevel", Object)
---@class SortData_TrapLevel : Object
SortData_TrapLevel = SortData_TrapLevel
---@param world MainWorld
function SortData_TrapLevel:Constructor(world, nEntityID)
    self.m_entityTrap = world:GetEntityByID(nEntityID)
    self.m_nTrapID = nEntityID
end

function SortData_TrapLevel:GetTrapID()
    return self.m_nTrapID
end

function SortData_TrapLevel:GetTrapEntity()
    return self.m_entityTrap
end

---@param sortDataA SortData_TrapLevel
---@param sortDataB SortData_TrapLevel
function SortData_TrapLevel.CompareByTrapLevel(sortDataA, sortDataB)
    ---@type Entity
    local entityA = sortDataA:GetTrapEntity()
    ---@type TrapRenderComponent
    local trapRenderA = entityA:TrapRender()

    ---@type Entity
    local entityB = sortDataB:GetTrapEntity()
    ---@type TrapRenderComponent
    local trapRenderB = entityB:TrapRender()

    ---QA[MSG67415]：先按显示层级配置排序，再按原逻辑排序
    local showLevelA = trapRenderA:GetTrapShowLevel()
    local showLevelB = trapRenderB:GetTrapShowLevel()
    if showLevelA ~= BattleConst.TrapShowLevelDefault or
        showLevelB ~= BattleConst.TrapShowLevelDefault then
        return showLevelA - showLevelB
    end

    ---按TrapLevel排序
    local nTrapLevelA = trapRenderA:GetTrapLevel()
    local nTrapLevelB = trapRenderB:GetTrapLevel()
    return nTrapLevelA - nTrapLevelB ---倒序
end

--endregion SortData_TrapLevel

function PreviewMonsterTrapService:ShowPreviewTrap(trapEntityID, touchPosition, offset)
    self:_ShowPreviewTrapAction(trapEntityID, touchPosition, offset)
end
