--[[------------------------------------------------------------------------------------------
    PreviewMonsterActionSystem_Render : 预览怪物行动
]]
--------------------------------------------------------------------------------------------
---@class PreviewMonsterActionSystem_Render: ReactiveSystem
_class("PreviewMonsterActionSystem_Render", ReactiveSystem)
PreviewMonsterActionSystem_Render = PreviewMonsterActionSystem_Render
---@class  PreviewMonsterType
local PreviewMonsterType = {
    SkillRange = 1, --
    SkillRangeWithAttackRange = 2, --
    ProSkillRange = 3, --
    DeathAreaRange = 4, --
    Tips = 5, --
    SkillRangeWithArrow =6,--
}
_enum("PreviewMonsterType", PreviewMonsterType)
function PreviewMonsterActionSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._neighbourArray = {
        Vector2(0, 1),
        Vector2(1, 0),
        Vector2(0, -1),
        Vector2(-1, 0)
    }

    self._arrowResPathDic = {}
    self._arrowResPathDic[ElementType.ElementType_Blue] = "eff_gezi_hybs_yulan_bai.prefab"
    self._arrowResPathDic[ElementType.ElementType_Red] = "eff_gezi_hybs_yulan_bai.prefab"
    self._arrowResPathDic[ElementType.ElementType_Green] = "eff_gezi_hybs_yulan_bai.prefab"
    self._arrowResPathDic[ElementType.ElementType_Yellow] = "eff_gezi_hybs_yulan_bai.prefab"

    self._outlineResPath = "eff_gezi_bossyj_normal.prefab"
    self._outlineProResPath = "eff_gezi_bossyj_pro.prefab"
    self._attackAreaResPath = "eff_gezi_hybs_yulan_honggezi.prefab"
    self._deathAreaResPath = "eff_gezi_bossyj_sj.prefab"

    ---@type ConfigService
    self._configService = world:GetService("Config")
end

function PreviewMonsterActionSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.PreviewMonsterAction)
    local c = Collector:New({ group }, { "AddedOrRemoved" })
    return c
end

---@param entity Entity
function PreviewMonsterActionSystem_Render:Filter(entity)
    return true
end

function PreviewMonsterActionSystem_Render:ExecuteEntities(entities)
    ---现在约定的是，只会在boardentity上挂怪物预览相关
    for i = 1, #entities do
        local boardEntity = entities[i]
        if boardEntity:HasPreviewMonsterAction() then
            ---@type PreviewMonsterActionComponent
            local previewCmpt = boardEntity:PreviewMonsterAction()
            local isShow = previewCmpt:IsShowMonsterAction()
            local monsterEntityID = previewCmpt:GetMonsterEntityID()
            if isShow then

                self:_ShowMonsterAction(monsterEntityID, boardEntity)
            else
                ---隐藏改成同步了
            end
        else
            Log.debug("[Preview] 预览怪物技能： 时机不到")
        end
    end
end

function PreviewMonsterActionSystem_Render:_ShowMonsterAction(monsterEntityID, boardEntity)
    local monsterEntity = self._world:GetEntityByID(monsterEntityID)

    ---有buff标志  不显示技能预览
    ---@type BuffViewComponent
    local buffView = monsterEntity:BuffView()
    if buffView and buffView:HasBuffEffect(BuffEffectType.NotShowPreviewSkill) then
        return
    end

    ---@type MonsterIDComponent
    local cMonsterID = monsterEntity:MonsterID()
    local monsterID = cMonsterID:GetMonsterID()

    ---@type ConfigService
    local configService = self._configService
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local hybridMode, hybridParam = monsterConfigData:GetHybridSkillPreviewMode(monsterID)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local hasReplacePreviewSkill = utilDataSvc:IsAIChangePreviewSkillID(monsterEntity)

    if hybridMode > 0 and not hasReplacePreviewSkill then
        self:_StartHybridSkillPreview(monsterEntityID, boardEntity, hybridMode, hybridParam)
    else
        self:_StartPlainSkillPreview(monsterEntityID, boardEntity)
    end
end

function PreviewMonsterActionSystem_Render:_StartPlainSkillPreview(monsterEntityID, boardEntity)
    local monsterEntity = self._world:GetEntityByID(monsterEntityID)

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    local monsterSkillID = utilDataSvc:GetAIPreviewSkillID(monsterEntity)
    if 0 == monsterSkillID then
        Log.fatal("[Preview]，怪物技能预览时发现技能编号非法： monsterEntityID = " .. monsterEntityID)
    end

    local skillConfig = BattleSkillCfg(monsterSkillID)
    if (not skillConfig) or not (skillConfig.ViewID) then
        Log.fatal("[Preview] 无技能表现，不预览")
        return
    end

    self:_ShowSkillPreview(monsterEntity, monsterSkillID)
end

----@param monsterEntity Entity
function PreviewMonsterActionSystem_Render:_ShowSkillPreview(monsterEntity, monsterSkillID)
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = self._configService:GetSkillConfigData(monsterSkillID, monsterEntity)
    ---下回合可攻击范围
    ---@type SkillPreviewType
    local skillPreviewType = skillConfigData:GetSkillPreviewType()

    local skillPreviewParam = skillConfigData:GetSkillPreviewParam()
    local dirCount = 0
    local previewUserCenter = nil
    local lessMobility  = nil
    local calcMobiUseBlock= nil
    if skillPreviewParam and skillPreviewParam ~= 0 then
        dirCount = skillPreviewParam.Direction
        previewUserCenter = skillPreviewParam.PreviewUserCenter
        lessMobility =  skillPreviewParam.LessMobility
        calcMobiUseBlock = skillPreviewParam.CalcMobiUseBlock
    end
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
    if SkillPreviewType.Scope == skillPreviewType then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        ---@type ConfigService
        local configsvc = self._world:GetService("Config")
        local monsterMobility = utilDataSvc:GetAIMobilityConfig(monsterEntity)
        if lessMobility and monsterMobility<= lessMobility then
            local listWalkRange = { [1] = monsterEntity:GetGridPosition() }
            self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter,lessMobility)
        else
            local listWalkRange = self:_ShowArrow(monsterEntity,lessMobility,calcMobiUseBlock)
            self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter,lessMobility)
        end

    elseif SkillPreviewType.Tips == skillPreviewType then
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    elseif SkillPreviewType.ScopeAndTips == skillPreviewType then
        local listWalkRange = self:_ShowArrow(monsterEntity,lessMobility)
        self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    elseif SkillPreviewType.ReplaceOtherSkillScopeAndTips == skillPreviewType then
        local replaceSkillConfigData = self._configService:GetSkillConfigData(skillPreviewParam.SkillID, monsterEntity)
        local listWalkRange = self:_ShowArrow(monsterEntity,lessMobility)
        self:_ShowSkillRange(monsterEntity, replaceSkillConfigData, listWalkRange, dirCount, previewUserCenter)
        previewActiveSkillService:_ShowSkillTips(replaceSkillConfigData)
    elseif SkillPreviewType.ScopeWithCasterPos == skillPreviewType then
        local listWalkRange = { [1] = monsterEntity:GetGridPosition() }
        self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
    elseif SkillPreviewType.ScopeWithCasterPosAndTips == skillPreviewType then
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
        local casterPos = monsterEntity:GetGridPosition()
        if previewUserCenter then
            for _, v in ipairs(previewUserCenter) do
                if v.x ~= casterPos.x and v.y ~= casterPos.y then
                    casterPos = Vector2(v.x, v.y)
                    break
                end
            end
        end
        local listWalkRange = { [1] = casterPos }
        self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
    elseif SkillPreviewType.ScopeAndEffectScope == skillPreviewType then
        local effectIndex = skillPreviewParam.effectIndex
        if not effectIndex then
            Log.fatal("Skill Preview Config Failed SkillID:", monsterSkillID)
        end
        self:_ShowSkillRangeWithEffect(effectIndex, skillConfigData, monsterEntity)
    elseif SkillPreviewType.ScopeAndEffectScopeAndTips == skillPreviewType then
        local effectIndex = skillPreviewParam.effectIndex
        if not effectIndex then
            Log.fatal("Skill Preview Config Failed SkillID:", monsterSkillID)
        end
        self:_ShowSkillRangeWithEffect(effectIndex, skillConfigData, monsterEntity)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    elseif SkillPreviewType.ScopeAndTipsAndMoveParam == skillPreviewType then
        self:_ShowArrowPreviewParam(monsterEntity, skillPreviewParam)
        local listWalkRange = {}
        self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    elseif SkillPreviewType.ScopeCanConfig == skillPreviewType then
        if table.icontains(skillPreviewParam, PreviewMonsterType.SkillRange) then
            local listWalkRange = {}
            self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        end
        if table.icontains(skillPreviewParam, PreviewMonsterType.DeathAreaRange) then
            self:_ShowDeathRange(monsterEntity, skillConfigData)
        end
        if table.icontains(skillPreviewParam, PreviewMonsterType.Tips) then
            previewActiveSkillService:_ShowSkillTips(skillConfigData)
        end
        if table.icontains(skillPreviewParam, PreviewMonsterType.SkillRangeWithAttackRange) then
            local listWalkRange = { [1] = monsterEntity:GetGridPosition() }
            self:_SkillRangeWithAttackRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        end
        if table.icontains(skillPreviewParam, PreviewMonsterType.SkillRangeWithArrow) then
            local listWalkRange = self:_ShowArrowCheckBlock(monsterEntity)
            self:_SkillRangeWithAttackRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        end
    elseif SkillPreviewType.ScopeSilverGrid == skillPreviewType then
        local listWalkRange = self:_ShowArrow(monsterEntity)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
        self:_ShowSkillRangeAsSilverGrid(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
    elseif SkillPreviewType.ScopeAndTipsAndArrowWithMoveParam == skillPreviewType then
        local listWalkRange = self:_ShowArrowWithMoveParam(monsterEntity, skillPreviewParam)
        self:_ShowSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount, previewUserCenter)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    elseif SkillPreviewType.N29DrillerMoveAttack == skillPreviewType then
        self:_ShowDrillerMoveAttack(monsterEntity,skillConfigData)
    elseif SkillPreviewType.TeleportRangeAndDamageRange == skillPreviewType then
        --TeleportScope = {scopeType = xx,scopeParam = {}},DamageScopeSkillID=xxx
        --用于显示每格上攻击范围的技能id
        ---@type SkillConfigData 主动技配置数据
        local damageAreaSkillConfigData = self._configService:GetSkillConfigData(skillPreviewParam.DamageScopeSkillID, monsterEntity)
        local listWalkRange = self:_ShowArrowPreviewParamSub(monsterEntity, skillPreviewParam.TeleportScope)
        self:_ShowSkillRange(monsterEntity, damageAreaSkillConfigData, listWalkRange, dirCount, previewUserCenter)
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    end
end

function PreviewMonsterActionSystem_Render:_StartHybridSkillPreview(monsterEntityID, boardEntity, mode, param)
    local entity = self._world:GetEntityByID(monsterEntityID)

    local curParam = nil
    ---@type BuffViewComponent
    local buffView = entity:BuffView()
    if buffView then
        curParam = buffView:GetBuffValue("HybridSkillPreviewParam")
    end
    if not curParam then
        curParam = param
    end

    ---@type PreviewMonsterActionComponent
    local cPrvwMstrAct = boardEntity:PreviewMonsterAction()

    local tid
    if mode == MonsterActionHybridPreviewMode.Carousel then
        tid = self:_HybridPreview_Carousel(entity, curParam)
    elseif mode == MonsterActionHybridPreviewMode.RoundBasedCarousel then
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local roundCount = utilDataSvc:GetEntityAIRuntimeData(entity, "RoundCount")
        -- 如果完全没有执行过AI的话要特殊处理
        if (not roundCount) or (roundCount <= 0) then
            roundCount = 0
        end
        roundCount = roundCount + 1
        tid = self:_HybridPreview_RoundBasedCarousel(entity, curParam,roundCount)
    elseif mode == MonsterActionHybridPreviewMode.TotalRoundBasedCarousel then
        local roundCount = BattleStatHelper.GetLevelTotalRoundCount()
        if roundCount > #param then
            roundCount = roundCount%(#param)
            if roundCount ==0 then
                roundCount = #param
            end
        end
        tid = self:_HybridPreview_RoundBasedCarousel(entity, curParam,roundCount)
    elseif mode == MonsterActionHybridPreviewMode.AlphaFixedByRound then
        self:_HybridPreview_AlphaFixedByRound(entity, curParam)
    end

    if type(tid) == "number" then
        cPrvwMstrAct:SetPreviewTaskID(tid)
    end
end

---
function PreviewMonsterActionSystem_Render:_HybridPreview_Carousel(entity, param)
    ---@type MonsterIDComponent
    local cMonsterID = entity:MonsterID()
    local monsterID = cMonsterID:GetMonsterID()
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local monsterSkill = monsterConfigData:GetMonsterSkillIDs(monsterID)

    local skillRow = param[1][1] -- iae| => aaie| 多了一个维度
    local tipSkillIndex = param[2][1] -- iae| => aaie| 多了一个维度

    local skills = monsterSkill[skillRow]
    if not skills then
        return
    end

    if tipSkillIndex and tipSkillIndex > 0 then
        ---@type SkillConfigData 主动技配置数据
        local skillConfigData = self._configService:GetSkillConfigData(skills[tipSkillIndex], entity)

        ---@type PreviewActiveSkillService
        local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
        previewActiveSkillService:_ShowSkillTips(skillConfigData)
    end

    return TaskManager:GetInstance():CoreGameStartTask(self._TaskFnCarousel, self, skills, entity)
end

---
---@param entity Entity
function PreviewMonsterActionSystem_Render:_HybridPreview_RoundBasedCarousel(entity, param,roundCount)
    if roundCount > #param then
        roundCount = 1
    end

    local skillGroup = param[roundCount]
    if not skillGroup or #skillGroup <= 0 then
        return
    end

    return TaskManager:GetInstance():CoreGameStartTask(self._TaskFnCarousel, self, skillGroup, entity)
end

function PreviewMonsterActionSystem_Render:_TaskFnCarousel(TT, tSkillID, casterEntity)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")

    local currentSkillIndex = 1
    while (true) do
        local monsterSkillID = tSkillID[currentSkillIndex]
        self:_ShowSkillPreview(casterEntity, monsterSkillID)
        ---@type SkillConfigData 主动技配置数据
        local skillConfigData = self._configService:GetSkillConfigData(monsterSkillID, casterEntity)

        ---@type PreviewActiveSkillService
        local previewActiveSkillService = self._world:GetService("PreviewActiveSkill")
        previewActiveSkillService:_ShowSkillTips(skillConfigData)

        YIELD(TT, BattleConst.PreviewMonsterInternal)

        renderEntityService:DestroyMonsterPreviewAreaOutlineEntity()
        ---因世界boss的芭芭拉使用了格子动画的'silver'，这里需要还原回去
        self._world:GetService("PreviewActiveSkill"):_RevertAllConvertElement(true)

        currentSkillIndex = ((currentSkillIndex) % (#tSkillID)) + 1
    end
end

function PreviewMonsterActionSystem_Render:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
    local x = 0
    local y = 0

    local onTheRight = true
    local onTheLeft = true
    local onTheTop = true
    local onTheBottom = true

    for _, bodyAreaPos in ipairs(bodyArea) do
        local curAreaPos = monsterPos + bodyAreaPos
        if targetPos.x >= curAreaPos.x then
            onTheLeft = false
        end

        if targetPos.x <= curAreaPos.x then
            onTheRight = false
        end

        if targetPos.y >= curAreaPos.y then
            onTheBottom = false
        end

        if targetPos.y <= curAreaPos.y then
            onTheTop = false
        end
    end

    if onTheLeft then
        x = 1
    elseif onTheRight then
        x = -1
    end

    if onTheTop then
        y = -1
    elseif onTheBottom then
        y = 1
    end

    return Vector2(x, y)
end

---2019-11-22 韩玉信添加：计算行动范围
---@param monsterEntity Entity
function PreviewMonsterActionSystem_Render:_CalcMonsterMoveRange_Han(monsterEntity, bBase, bFilterInvalid,lessMobility,calcMobiUseBlock)
    local monsterBasePos = monsterEntity:GridLocation().Position
    local bodyAreaCmpt = monsterEntity:BodyArea()
    local monsterBodyArea = bodyAreaCmpt:GetArea()
    local nBodyAreaCount = 0
    if bBase then
        nBodyAreaCount = 1
    else
        nBodyAreaCount = #monsterBodyArea
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    ---@type ConfigService
    local configsvc = self._world:GetService("Config")
    local monsterMobility = utilDataSvc:GetAIMobilityConfig(monsterEntity)
    local monsterID = monsterEntity:MonsterID():GetMonsterID()
    local monsterConfigData = configsvc:GetMonsterConfigData()
    local canMove = monsterConfigData:CanMove(monsterID)
    local canTurn = monsterConfigData:CanTurn(monsterID)

    local listWalkRange = nil
    if lessMobility then
        monsterMobility = monsterMobility-lessMobility
    end
    if canMove then
        if monsterMobility >0 then
            listWalkRange = ComputeScopeRange.ComputeRange_WalkMathPos(monsterBasePos, nBodyAreaCount, monsterMobility)
        else
            return {monsterBasePos}
        end
    else
        listWalkRange = ComputeScopeRange.ComputeBodyArea(monsterBasePos, nBodyAreaCount, 0)
    end
    local listReturn = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@param value ComputeWalkPos
    for key, value in pairs(listWalkRange) do
        local posWalk = value:GetPos()
        local isBlocked = false
        if bFilterInvalid then
            isBlocked = utilDataSvc:IsPosBlock(posWalk, monsterEntity:MonsterID():GetMonsterBlockData())
            if isBlocked then
                local posPlayer = self._world:Player():GetPreviewTeamEntity():GetGridPosition()
                if posPlayer == posWalk or utilDataSvc:GetMonsterAtPos(posWalk) then
                    isBlocked = false
                end
            end
            if isBlocked and bBase then
                if table.icontains(monsterBodyArea, posWalk - monsterBasePos) then
                    isBlocked = false
                end
            end
        else
            isBlocked = utilDataSvc:IsValidPiecePos(posWalk)
        end
        if false == isBlocked then
            listReturn[#listReturn + 1] = posWalk
        end
    end
    return listReturn
end



function PreviewMonsterActionSystem_Render:_GetSkillRange(
        monsterEntity,
        skillConfigData,
        listWalkRange,
        dirCount,
        previewUserCenter,lessMobility)
    local monsterBasePos = monsterEntity:GridLocation().Position
    local textPos = nil
    if previewUserCenter then
        for _, v in ipairs(previewUserCenter) do
            if v.x ~= monsterBasePos.x and v.y ~= monsterBasePos.y then
                monsterBasePos = Vector2(v.x, v.y)
                textPos = monsterBasePos
                break
            end
        end
    end

    local nSkillScopeType = skillConfigData:GetSkillScopeType()
    local bOnlyBaseMoveRange = true
    if SkillScopeType.NRowsMColumns == nSkillScopeType then
        bOnlyBaseMoveRange = false
    end
    ---@type Vector2[]
    local monsterBaseMoveRange = nil
    if nil == listWalkRange then
        monsterBaseMoveRange = self:_CalcMonsterMoveRange_Han(monsterEntity, bOnlyBaseMoveRange, true,lessMobility)
    else
        local bodyArea = monsterEntity:BodyArea():GetArea()
        if bOnlyBaseMoveRange and table.count(bodyArea) > 1 and
            (SkillPreviewType.ScopeWithCasterPos ~= skillConfigData:GetSkillPreviewType() and
                SkillPreviewType.ScopeWithCasterPosAndTips ~= skillConfigData:GetSkillPreviewType() and
                SkillPreviewType.ScopeAndTipsAndArrowWithMoveParam ~= skillConfigData:GetSkillPreviewType())
        then
            monsterBaseMoveRange = self:_CalcMonsterMoveRange_Han(monsterEntity, bOnlyBaseMoveRange, true,lessMobility)
        else
            monsterBaseMoveRange = listWalkRange
        end
    end
    ---加入自己的基准坐标
    if false == table.icontains(monsterBaseMoveRange, monsterBasePos) then
        monsterBaseMoveRange[#monsterBaseMoveRange + 1] = monsterBasePos
    end
    local casterDirList = {}
    if dirCount == 4 then
        casterDirList = { Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0) }
    elseif dirCount == 8 then
        casterDirList = {
            Vector2(0, 1),
            Vector2(0, -1),
            Vector2(1, 0),
            Vector2(-1, 0),
            Vector2(1, 1),
            Vector2(1, -1),
            Vector2(-1, 1),
            Vector2(-1, -1)
        }
    else
        casterDirList = {}
    end
    ---对怪物的每个可移动到的格子，计算出可攻击范围
    local skillAttackRange = {}
    for _, movePos in pairs(monsterBaseMoveRange) do
        if #casterDirList > 0 then
            for k, dir in pairs(casterDirList) do
                local range = self:_CreatePreviewRange(skillConfigData, movePos, monsterEntity, dir)
                for _, gridPos in pairs(range) do
                    local alreadyInRange = table.icontains(skillAttackRange, gridPos)
                    if not alreadyInRange then
                        skillAttackRange[#skillAttackRange + 1] = gridPos
                    end
                end
            end
        else
            local range = self:_CreatePreviewRange(skillConfigData, movePos, monsterEntity)
            for _, gridPos in pairs(range) do
                local alreadyInRange = table.icontains(skillAttackRange, gridPos)
                if not alreadyInRange then
                    skillAttackRange[#skillAttackRange + 1] = gridPos
                end
            end
        end
    end

    return skillAttackRange
end

---@param skillConfigData SkillConfigData
function PreviewMonsterActionSystem_Render:_ShowSkillRange(
    monsterEntity,
    skillConfigData,
    listWalkRange,
    dirCount,
    previewUserCenter,
    lessMobility)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    -----创建移动范围显示的高亮Entity
    --for _, gridPos in pairs(skillAttackRange) do
    --    --Log.fatal("skill range ",tostring(gridPos))
    --    renderEntityService:CreateAreaEntity(gridPos, EntityConfigIDRender.MoveRange, nil)
    --end

    ---显示移动范围边框
    local skillAttackRange = self:_GetSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount,
        previewUserCenter,lessMobility)
    renderEntityService:CreatePreviewAreaOutlineEntity(skillAttackRange, EntityConfigIDRender.MoveRange)
    --renderEntityService:CreateAreaOutlineEntity_New(skillAttackRange, EntityConfigIDRender.MoveRange)
    --self:_ShowText(monsterEntity, textPos)
    Log.debug("[Preview] 预览怪物技能： 标示技能范围<" .. skillConfigData:GetSkillName() .. ">")
end

function PreviewMonsterActionSystem_Render:_GetSkillRangeWithAttackRange(
        monsterEntity,
        skillConfigData,
        listWalkRange,
        dirCount,
        previewUserCenter,lessMobility)

    local nSkillScopeType = skillConfigData:GetSkillScopeType()
    local bOnlyBaseMoveRange = true
    if SkillScopeType.NRowsMColumns == nSkillScopeType then
        bOnlyBaseMoveRange = false
    end
    local casterDirList = {}
    if dirCount == 4 then
        casterDirList = { Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0) }
    elseif dirCount == 8 then
        casterDirList = {
            Vector2(0, 1),
            Vector2(0, -1),
            Vector2(1, 0),
            Vector2(-1, 0),
            Vector2(1, 1),
            Vector2(1, -1),
            Vector2(-1, 1),
            Vector2(-1, -1)
        }
    else
        casterDirList = {}
    end
    ---对怪物的每个可移动到的格子，计算出可攻击范围
    local skillAttackRange = {}

    if #casterDirList > 0 then
        for i, movePos in ipairs(listWalkRange) do
            for k, dir in pairs(casterDirList) do
                local range = self:_CreatePreviewRangeUseAttackRange(skillConfigData, movePos, monsterEntity, dir)
                for _, gridPos in pairs(range) do
                    local alreadyInRange = table.icontains(skillAttackRange, gridPos)
                    if not alreadyInRange then
                        skillAttackRange[#skillAttackRange + 1] = gridPos
                    end
                end
            end
        end
    else
        for i, movePos in ipairs(listWalkRange) do
            local range = self:_CreatePreviewRangeUseAttackRange(skillConfigData, movePos, monsterEntity)
            for _, gridPos in pairs(range) do
                local alreadyInRange = table.icontains(skillAttackRange, gridPos)
                if not alreadyInRange then
                    skillAttackRange[#skillAttackRange + 1] = gridPos
                end
            end
        end
    end

    return skillAttackRange
end

function PreviewMonsterActionSystem_Render:_CreatePreviewRangeUseAttackRange(skillConfigData, movePos, monsterEntity, dir)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---对怪物的每个可移动到的格子，计算出可攻击范围
    local skillAttackRange = {}
    ---@type SkillScopeResult
    local rangResult

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    --如果技能范围是展示上一次计算的类型
    rangResult = utilDataSvc:GetAISkillScopeResult(monsterEntity)
    if not rangResult then
        rangResult = utilScopeSvc:CalcSkillScope(skillConfigData, movePos, monsterEntity, dir)
    end
    skillAttackRange = rangResult:GetAttackRange()
    return skillAttackRange
end

function PreviewMonsterActionSystem_Render:_SkillRangeWithAttackRange(
        monsterEntity,
        skillConfigData,
        listWalkRange,
        dirCount,
        previewUserCenter,
        lessMobility)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    -----创建移动范围显示的高亮Entity
    --for _, gridPos in pairs(skillAttackRange) do
    --    --Log.fatal("skill range ",tostring(gridPos))
    --    renderEntityService:CreateAreaEntity(gridPos, EntityConfigIDRender.MoveRange, nil)
    --end

    ---显示移动范围边框
    local skillAttackRange = self:_GetSkillRangeWithAttackRange(monsterEntity, skillConfigData, listWalkRange, dirCount,
            previewUserCenter,lessMobility)
    renderEntityService:CreatePreviewAreaOutlineEntity(skillAttackRange, EntityConfigIDRender.MoveRange)
    --renderEntityService:CreateAreaOutlineEntity_New(skillAttackRange, EntityConfigIDRender.MoveRange)
    --self:_ShowText(monsterEntity, textPos)
    Log.debug("[Preview] 预览怪物技能： 标示技能范围<" .. skillConfigData:GetSkillName() .. ">")
end

function PreviewMonsterActionSystem_Render:_ShowSkillRangeAsSilverGrid(monsterEntity, skillConfigData, listWalkRange,
                                                                       dirCount, previewUserCenter)
    local skillAttackRange = self:_GetSkillRange(monsterEntity, skillConfigData, listWalkRange, dirCount,
        previewUserCenter)
    ---@type PreviewActiveSkillService
    local rsvcPreviewActive = self._world:GetService("PreviewActiveSkill")
    rsvcPreviewActive:DoConvert(skillAttackRange, "Silver")
end

---@param skillRange Vector2
function PreviewMonsterActionSystem_Render:_FilerSkillRange(skillRange)
    local skillAttackRange = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    for _, gridPos in ipairs(skillRange) do
        if utilDataSvc:IsValidPiecePos(gridPos) and
            not utilDataSvc:IsPosBlock(gridPos, BlockFlag.Skill | BlockFlag.SkillSkip)
        then
            skillAttackRange[#skillAttackRange + 1] = gridPos
        end
    end
    return skillAttackRange
end

function PreviewMonsterActionSystem_Render:_CreatePreviewRange(skillConfigData, movePos, monsterEntity, dir)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---对怪物的每个可移动到的格子，计算出可攻击范围
    local skillAttackRange = {}
    local rangResult

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    --如果技能范围是展示上一次计算的类型
    rangResult = utilDataSvc:GetAISkillScopeResult(monsterEntity)
    if not rangResult then
        rangResult = utilScopeSvc:CalcSkillScope(skillConfigData, movePos, monsterEntity, dir)
    end
    skillAttackRange = self:_FilerSkillRange(rangResult:GetWholeGridRange())
    return skillAttackRange
end
----@param monsterEntity Entity
function PreviewMonsterActionSystem_Render:_ShowArrowCheckBlock(monsterEntity,lessMobility,calcMobiUseBlock)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---范围型的，才需要生成下回合可移动范围的箭头
    local monsterPos = monsterEntity:GridLocation().Position
    ---@type BodyAreaComponent
    local bodyAreaCmpt = monsterEntity:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()
    local block
    ---@type MonsterRaceType
    local monsterRaceType = monsterEntity:MonsterID():GetMonsterRaceType()
    if monsterRaceType == MonsterRaceType.Land then
        block = BlockFlag.MonsterLand
    elseif monsterRaceType == MonsterRaceType.Fly then
        block = BlockFlag.MonsterFly
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local elementType = utilDataSvc:GetEntityElementPrimaryType(monsterEntity)

    --local monsterMoveRange = self:_CalcMonsterMoveRange(monsterEntityID)
    local monsterMoveRange = self:_CalcMonsterMoveRange_Han(monsterEntity, false, true,lessMobility,calcMobiUseBlock)
    local retRange = {}
    for i, pos in ipairs(monsterMoveRange) do
        if not utilDataSvc:IsPosBlock(pos,block) then
            table.insert(retRange,pos)
        end
    end
    for _, targetPos in ipairs(retRange) do
        ---2019-12-28 韩玉信根据策划的群聊需求，修改为三角符号不在怪物自己脚下出现
        if false == self:_IsPosInMine(targetPos, monsterPos, bodyArea) then
            local arrowDir = self:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
            renderEntityService:CreateMoveRangeArrowEntity(targetPos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
        end
    end
    Log.debug("[Preview] 预览怪物技能： 标示行动范围<三角箭头>>")
    return retRange
end

function PreviewMonsterActionSystem_Render:_ShowArrow(monsterEntity,lessMobility,calcMobiUseBlock)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---范围型的，才需要生成下回合可移动范围的箭头
    local monsterPos = monsterEntity:GridLocation().Position
    ---@type BodyAreaComponent
    local bodyAreaCmpt = monsterEntity:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local elementType = utilDataSvc:GetEntityElementPrimaryType(monsterEntity)

    --local monsterMoveRange = self:_CalcMonsterMoveRange(monsterEntityID)
    local monsterMoveRange = self:_CalcMonsterMoveRange_Han(monsterEntity, false, true,lessMobility,calcMobiUseBlock)
    for _, targetPos in ipairs(monsterMoveRange) do
        ---2019-12-28 韩玉信根据策划的群聊需求，修改为三角符号不在怪物自己脚下出现
        if false == self:_IsPosInMine(targetPos, monsterPos, bodyArea) then
            local arrowDir = self:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
            renderEntityService:CreateMoveRangeArrowEntity(targetPos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
        end
    end
    Log.debug("[Preview] 预览怪物技能： 标示行动范围<三角箭头>>")
    return monsterMoveRange
end

function PreviewMonsterActionSystem_Render:_ShowArrowPreviewParam(monsterEntity, skillPreviewParam)
    local arrowPosList = {}

    local monsterPos = monsterEntity:GetGridPosition()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local scopeType = skillPreviewParam.scopeType
    local scopeParam = skillPreviewParam.scopeParam

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")

    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult = scopeCalculator:ComputeScopeRange(scopeType, scopeParam, monsterPos, bodyArea)
    local attackRange = scopeResult:GetAttackRange()
    for _, pos in pairs(attackRange) do
        if utilData:IsValidPiecePos(pos) then
            table.insert(arrowPosList, pos)
        end
    end

    for _, targetPos in ipairs(arrowPosList) do
        ---2019-12-28 韩玉信根据策划的群聊需求，修改为三角符号不在怪物自己脚下出现
        if false == self:_IsPosInMine(targetPos, monsterPos, bodyArea) then
            local arrowDir = self:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
            renderEntityService:CreateMoveRangeArrowEntity(targetPos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
        end
    end

    -- return arrowPosList
end
function PreviewMonsterActionSystem_Render:_ShowArrowPreviewParamSub(monsterEntity, skillPreviewParam)
    local arrowPosList = {}

    local monsterPos = monsterEntity:GetGridPosition()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local scopeType = skillPreviewParam.scopeType
    local scopeParam = skillPreviewParam.scopeParam

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")

    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult = scopeCalculator:ComputeScopeRange(scopeType, scopeParam, monsterPos, bodyArea, monsterEntity:GetGridDirection(), SkillTargetType.Team, monsterPos, monsterEntity)
    local attackRange = scopeResult:GetAttackRange()
    for _, pos in pairs(attackRange) do
        if utilData:IsValidPiecePos(pos) then
            table.insert(arrowPosList, pos)
        end
    end

    for _, targetPos in ipairs(arrowPosList) do
        ---2019-12-28 韩玉信根据策划的群聊需求，修改为三角符号不在怪物自己脚下出现
        if false == self:_IsPosInMine(targetPos, monsterPos, bodyArea) then
            local arrowDir = self:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
            renderEntityService:CreateMoveRangeArrowEntity(targetPos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
        end
    end

    return arrowPosList
end

function PreviewMonsterActionSystem_Render:_ShowArrowWithMoveParam(monsterEntity, skillPreviewParam)
    ---@type Vector2[]
    local arrowPosList = {}
    ---@type Vector2[]
    local moveOffsetList = {}
    ---@type Vector2[]
    local canMovePosList = {}

    local monsterPos = monsterEntity:GetGridPosition()
    local bodyArea = monsterEntity:BodyArea():GetArea()

    local moveOffsetPosList = skillPreviewParam.moveOffsetPosList
    if moveOffsetPosList then
        for _, v in ipairs(moveOffsetPosList) do
            local offset = Vector2(v.x, v.y)
            table.insert(moveOffsetList, offset)
            local movePos = monsterPos + offset
            if movePos.x >= skillPreviewParam.minX and movePos.x <= skillPreviewParam.maxX then
                table.insert(canMovePosList, movePos)
            end
        end
    end

    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    for _, offset in ipairs(moveOffsetList) do
        for _, bodyPos in ipairs(bodyArea) do
            local offsetBodyPos = offset + bodyPos
            if not table.icontains(bodyArea, offsetBodyPos) then
                local pos = monsterPos + offsetBodyPos
                if utilData:IsValidPiecePos(pos) and not table.icontains(arrowPosList, pos) then
                    table.insert(arrowPosList, pos)
                end
            end
        end
    end

    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    for _, targetPos in ipairs(arrowPosList) do
        if false == self:_IsPosInMine(targetPos, monsterPos, bodyArea) then
            local arrowDir = self:_CalcMoveArrowDir(monsterPos, bodyArea, targetPos)
            renderEntityService:CreateMoveRangeArrowEntity(targetPos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
        end
    end

    return canMovePosList
end

function PreviewMonsterActionSystem_Render:_IsPosInMine(targetPos, basePos, bodyArea)
    for i = 1, #bodyArea do
        local posWork = basePos + bodyArea[i]
        if targetPos == posWork then
            return true
        end
    end
    return false
end

function PreviewMonsterActionSystem_Render:_ShowSkillRangeWithEffect(effectIndex, skillConfigData, monsterEntity)
    ---@type SkillEffectParamBase
    local effectParam = skillConfigData:GetSkillEffectByIndex(effectIndex)
    effectParam:GetSkillEffectScopeType()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type Vector2
    local casterPos = monsterEntity:GetGridPosition()
    ---@type SkillScopeResult
    local effectScopeResult = utilScopeSvc:CalcSkillEffectScopeResult(effectParam, casterPos, monsterEntity)
    ---@type Vector2[]
    local effectScopeRange = effectScopeResult:GetWholeGridRange()
    ---@type Vector2[]
    local skillScopeRange = self:_CreatePreviewRange(skillConfigData, casterPos, monsterEntity)
    local normalRange = {}
    for _, pos in ipairs(skillScopeRange) do
        if not table.Vector2Include(effectScopeRange, pos) then
            table.insert(normalRange, pos)
        end
    end
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    ---创建移动范围显示的高亮Entity
    for _, gridPos in pairs(effectScopeRange) do
        --Log.fatal("skill range ",tostring(gridPos))
        renderEntityService:CreateAreaEntityFromEntityPool(gridPos, EntityConfigIDRender.MoveRangeGrid)
    end
    ---显示移动范围边框
    --renderEntityService:CreateAreaOutlineEntity_New(normalRange, EntityConfigIDRender.MoveRange)
    renderEntityService:CreatePreviewAreaOutlineEntity(effectScopeRange, EntityConfigIDRender.MoveRangePro)
    renderEntityService:CreatePreviewAreaOutlineEntity(normalRange, EntityConfigIDRender.MoveRange)
    --renderEntityService:CreateAreaOutlineEntity_New(normalRange, EntityConfigIDRender.MoveRange)
end

function PreviewMonsterActionSystem_Render:_ShowDeathRange(monsterEntity, skillConfigData)
    ---@type Vector2
    local casterPos = monsterEntity:GetGridPosition()
    ----@type Vector2[]
    local range = self:_CreatePreviewRange(skillConfigData, casterPos, monsterEntity)
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    for _, pos in ipairs(range) do
        renderEntityService:CreateDeathRangeEntity(pos, EntityConfigIDRender.DeathArea)
    end
end

function PreviewMonsterActionSystem_Render:_GetSkillListByRoundCount(entity)
    --取回合数
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local roundCount = utilDataSvc:GetEntityAIRuntimeData(entity, "RoundCount")

    if (not roundCount) or (roundCount <= 0) then
        roundCount = 0
    end
    roundCount = roundCount + 1

    --去技能组列表
    ---@type MonsterIDComponent
    local cMonsterID = entity:MonsterID()
    local monsterID = cMonsterID:GetMonsterID()

    ---@type MonsterConfigData
    local monsterConfigData = self._configService:GetMonsterConfigData()
    local skillIDs = monsterConfigData:GetMonsterSkillIDs(monsterID)
    if roundCount > #skillIDs then
        roundCount = 1
    end

    local skillGroup = skillIDs[roundCount]
    if not skillGroup or #skillGroup <= 0 then
        return
    end

    return roundCount, skillGroup
end

function PreviewMonsterActionSystem_Render:_HybridPreview_AlphaFixedByRound(entity, param)
    local roundCount, skillIDGroup = self:_GetSkillListByRoundCount(entity)

    local trapID = param[1][1]
    local monsterClassID = param[2][1]

    local skillID = skillIDGroup[1]
    if roundCount == AIAlphaRoundCount.First then
        skillID = self:_CalcSkillIDByTrapInRangeAndRideState(entity, trapID, monsterClassID, skillIDGroup)
    elseif roundCount == AIAlphaRoundCount.Second then
        skillID = self:_CalcSkillIDByRideState(entity, skillIDGroup)
    end

    self:_ShowSkillPreview(entity, skillID)
end

---@param entity Entity
function PreviewMonsterActionSystem_Render:_CheckRideState(entity)
    if entity:HasRide() then
        ---@type RideComponent
        local rideCmpt = entity:Ride()
        local mountID = rideCmpt:GetMountID()

        ---@type Entity
        local mountEntity = self._world:GetEntityByID(mountID)
        if mountEntity then
            if mountEntity:HasMonsterID() then
                return AIRideStateType.RideOnMonster
            elseif mountEntity:HasTrapID() then
                return AIRideStateType.RideOnTrap
            end
        end
    end

    return AIRideStateType.NoRide
end

---@param entity Entity
function PreviewMonsterActionSystem_Render:_CalcSkillIDByTrapInRangeAndRideState(entity, trapID, monsterClassID,
                                                                                 skillIDGroup)
    local skillID = skillIDGroup[AIEntityInTargetRangeType.NoRideInRange]
    ---范围计算
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    local targetType = skillConfigData:GetSkillTargetType()

    local casterPos = entity:GetGridPosition()
    local casterDir = entity:GetGridDirection()
    ---@type SkillScopeResult
    local skillScopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, entity, casterDir)
    ---技能目标选择器
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    --先选目标
    local targetEntityIDList = targetSelector:DoSelectSkillTarget(entity, SkillTargetType.MonsterTrap, skillScopeResult,
        skillID)

    local trapEntityIDs = {}
    for _, targetID in ipairs(targetEntityIDList) do
        ---@type Entity
        local targetEntity = self._world:GetEntityByID(targetID)

        --查找技能目标中是否存在指定的机关
        if targetEntity:HasTrapID() and targetEntity:TrapID():GetTrapID() == trapID then
            table.insert(trapEntityIDs, targetID)
            --检查骑乘状态
            if targetEntity:HasRide() and targetEntity:Ride():GetRiderID() == entity:GetID() then
                return skillIDGroup[AIEntityInTargetRangeType.RideOnTrapInRange]
            end
        end

        --查找技能目标中是否存在指定怪物
        if targetEntity:HasMonsterID() and targetEntity:MonsterID():GetMonsterClassID() == monsterClassID then
            --检查骑乘状态
            if targetEntity:HasRide() and targetEntity:Ride():GetRiderID() == entity:GetID() then
                return skillIDGroup[AIEntityInTargetRangeType.RideOnMonsterInRange]
            end
        end
    end

    if #trapEntityIDs > 0 then
        return skillID
    end

    return skillIDGroup[AIEntityInTargetRangeType.NotInRange]
end

---@param entity Entity
function PreviewMonsterActionSystem_Render:_CalcSkillIDByRideState(entity, skillIDGroup)
    local rideState = self:_CheckRideState(entity)
    local skillID = skillIDGroup[rideState]
    return skillID

    --根据骑乘状态返回技能ID，不显示召唤技能预览
    -- ---@type UtilScopeCalcServiceShare
    -- local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    -- ---@type SkillConfigData 主动技配置数据
    -- local skillConfigData = self._configService:GetSkillConfigData(skillID)
    -- local targetType = skillConfigData:GetSkillTargetType()

    -- local casterPos = entity:GetGridPosition()
    -- local casterDir = entity:GetGridDirection()
    -- ---@type SkillScopeResult
    -- local skillScopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, entity, casterDir)
    -- ---技能目标选择器
    -- ---@type SkillScopeTargetSelector
    -- local targetSelector = self._world:GetSkillScopeTargetSelector()
    -- --先选目标
    -- local targetEntityIDList = targetSelector:DoSelectSkillTarget(entity, targetType, skillScopeResult, skillID)
    -- if #targetEntityIDList > 0 then
    --     return skillID
    -- end

    -- return skillIDGroup[#skillIDGroup]
end

---@param skillConfigData SkillConfigData
function PreviewMonsterActionSystem_Render:_ShowDrillerMoveAttack(monsterEntity,skillConfigData)
    ---范围计算
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type RenderEntityService
    local renderEntityService = self._world:GetService("RenderEntity")
    local casterPos = monsterEntity:GetGridPosition()
    local casterDir = monsterEntity:GetGridDirection()
    ---@type SkillScopeResult
    local skillScopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, monsterEntity, casterDir)
    local walkPosList = skillScopeResult:GetAttackRange()--包含初始位置
    local wholeRange = skillScopeResult:GetWholeGridRange()
    --移动路径 箭头
    local lastMovePos = casterPos
    for _, movePos in ipairs(walkPosList) do
        if movePos ~= casterPos then
            --local arrowDir = movePos - lastMovePos
            local arrowDir = self:_CalcMoveArrowDir(lastMovePos, {Vector2(0,0)}, movePos)
            renderEntityService:CreateMoveRangeArrowEntity(movePos, arrowDir, EntityConfigIDRender.MoveRangeArrow)
            lastMovePos = movePos
        end
    end
    --范围
    renderEntityService:CreatePreviewAreaOutlineEntity(wholeRange, EntityConfigIDRender.MoveRange)
end
