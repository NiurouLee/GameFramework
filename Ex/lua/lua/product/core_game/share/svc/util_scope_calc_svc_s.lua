--[[------------------------------------------------------------------------------------------
    UtilScopeCalcServiceShare : 只读计算服务
    此对象里的服务只能返回计算结果，禁止修改传入的参数
]] --------------------------------------------------------------------------------------------
require('switch_body_area_dir_type')

_class("UtilScopeCalcServiceShare", Object)
---@class UtilScopeCalcServiceShare: Object
UtilScopeCalcServiceShare = UtilScopeCalcServiceShare

function UtilScopeCalcServiceShare:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillScopeCalculator
    self._skillScopeCalc = SkillScopeCalculator:New(self)

    self._gridFilter = SkillScopeDefaultFilter:New()

    ---划线选敌计算器
    ---@type ChainPathTargetSelector
    self._chainPathTargetSelector = ChainPathTargetSelector:New(self._world)

    ---技能目标选择器
    ---@type SkillScopeTargetSelector
    self._skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()

    --技能目标排序
    ---@type SkillEffectTargetSorter
    self._skillEffectTargetSorter = SkillEffectTargetSorter:New(self._world)
end

---@param hitbackDirType HitBackDirectionType
function UtilScopeCalcServiceShare:SortHitbackTargetByDirType(enemyIDList, hitbackDirType, casterPos)
    self._skillEffectTargetSorter:_SortHitbackTargetByDirType(enemyIDList, hitbackDirType, casterPos)
end

function UtilScopeCalcServiceShare:_GetRandomNumber(m, n)
    ---@type RandomServiceLogic
    local randomService = self._world:GetService("RandomLogic")
    return randomService:LogicRand(m, n)
end

--region 拾取

---局内 根据技能的点选类型计算技能范围
---@param scopeParam table SkillConfigData.GetSkillScopeParam()
function UtilScopeCalcServiceShare:CalcCenterPosAndBodyArea(centerType, casterPos, PlayerBodyArea, scopeParam)
    local centerPos = casterPos
    local bodyArea = PlayerBodyArea
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    if not centerType or centerType == SkillScopeCenterType.CasterPos then --什么都不做
    elseif centerType == SkillScopeCenterType.Component then
        centerPos = self:GetComponentCenterPos()
    elseif centerType == SkillScopeCenterType.PickUpGridPos then
        local retPos = self:GetPickUpGridPosCenterPos()
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.PickUpMultiGridPos then
        local retPos = self:GetPickUpMultiGridPosCenterPos()
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.SelectNeareat2Pet then
        centerPos = self:_SelectNeareat2Pet(casterPos, scopeParam, teamEntity)
    elseif centerType == SkillScopeCenterType.ChainSkillPickUpGridPos then
        ---@type LogicPickUpComponent
        local logicPickUpCmpt = teamEntity:LogicPickUp()
        centerPos = logicPickUpCmpt:GetLogicCurPickUpGridSafePos()
    elseif centerType == SkillScopeCenterType.FirstPickUpGridPos then
        local retPos = self:GetFirstPickUpGridPosCenterPos()
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.CastBombPos then
        centerPos = self:_CalcBombPos(teamEntity, casterPos, scopeParam)
    elseif centerType == SkillScopeCenterType.RoundBeginPlayerPos then
        centerPos = self._world:BattleStat():GetRoundBeginPlayerPos()
    elseif centerType == SkillScopeCenterType.PlayerPos then
        local playerPos = teamEntity:GetGridPosition()
        centerPos = playerPos
    elseif centerType == SkillScopeCenterType.NearestPetChessPos then
        centerPos = self:GetNearestPetChessPosCenterPos(casterPos)
    elseif centerType == SkillScopeCenterType.NearestPosToCasterInPickMonster then
        local retPos = self:GetNearestPosToCasterInPickMonster()
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.PickUpMonsterPos then
        local retPos = self:GetPickUpMonsterPosCenterPos()
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.PickUpMonsterPosAndCasterPos then
        local retPos = self:GetPickUpMonsterPosAndCasterPosCenterPos()
        if retPos then
            centerPos = retPos
        end
    end

    return centerPos, bodyArea
end

----
----@return Vector2
function UtilScopeCalcServiceShare:GetFirstPickUpGridPosCenterPos()
    -- local petPstID = nil
    -- ---@type Entity
    -- local teamEntity = self._world:Player():GetCurrentTeamEntity()
    -- ---@type LogicPickUpComponent
    -- local logicPickUpCmpt = teamEntity:LogicPickUp()
    -- petPstID = logicPickUpCmpt:GetLogicPetPstid()

    -- ---@type UtilDataServiceShare
    -- local utilDataSvc = self._world:GetService("UtilData")
    -- local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)

    -- local petEntity = self._world:GetEntityByID(petEntityId)
    -- ---@type ActiveSkillPickUpComponent
    -- local activeSkillPickUpComponent = petEntity:ActiveSkillPickUpComponent()
    -- if activeSkillPickUpComponent then
    --     local centerPos = activeSkillPickUpComponent:GetFirstValidPickUpGridPos()
    --     return centerPos
    -- end

    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关或模块释放的点选主动技，petPstID=-1，entityID有值
    end

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local centerPos = activeSkillPickUpComponent:GetFirstValidPickUpGridPos()
            return centerPos
        end
    end
end

-----
----@return Vector2
function UtilScopeCalcServiceShare:GetPickUpMultiGridPosCenterPos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关释放的点选主动技，petPstID=-1，entityID有值
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local centerPos = activeSkillPickUpComponent:GetAllValidPickUpGridPos()
            return centerPos
        end
    end
end

----
------@return Vector2
function UtilScopeCalcServiceShare:GetPickUpGridPosCenterPos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关释放的点选主动技，petPstID=-1，entityID有值
    end

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local centerPos = activeSkillPickUpComponent:GetLastPickUpGridPos()
            return centerPos
        end
    end
end

----
---@return Vector2[]
function UtilScopeCalcServiceShare:GetComponentCenterPos()
    local posList = {}
    local g = self._world:GetGroup(self._world.BW_WEMatchers.ScopeCenter)
    for _, e in ipairs(g:GetEntities()) do
        if not e:HasDeadMark() then --标记死亡的实体不作为技能中心点（有些机关如落雷符文死亡后，不会立即销毁，会统一销毁，标记死亡的就不会作为中心点了）
            local area = e:BodyArea():GetArea()
            for _, posArea in ipairs(area) do
                local pos = e:GridLocation():GetGridPos() + posArea
                table.insert(posList, pos)
            end
        end
    end
    return posList
end

---获取距离怪物最近的我方棋子位置
---@param casterPos Vector2
---@return Vector2
function UtilScopeCalcServiceShare:GetNearestPetChessPosCenterPos(casterPos)
    local petEntityIDList = self:GetSortChessPetByMonsterPos(casterPos)
    ---@type Entity
    local entity = self._world:GetEntityByID(petEntityIDList[1])
    local pos = entity:GetGridPosition()
    return pos
end

---计算预览的中心点和包围盒
function UtilScopeCalcServiceShare:CalcPreviewCenterPosAndBodyArea(
    centerType,
    casterPos,
    PlayerBodyArea,
    scopeParam,
    casterEntity)
    local centerPos = casterPos
    local bodyArea = PlayerBodyArea
    if not centerType or centerType == SkillScopeCenterType.CasterPos then --什么都不做
    elseif centerType == SkillScopeCenterType.Component then
        local posList = {}
        local g = self._world:GetGroup(self._world.BW_WEMatchers.ScopeCenter)
        for _, e in ipairs(g:GetEntities()) do
            if not e:HasDeadMark() then --标记死亡的实体不作为技能中心点（有些机关如落雷符文死亡后，不会立即销毁，会统一销毁，标记死亡的就不会作为中心点了）
                local area = e:BodyArea():GetArea()
                for _, posArea in ipairs(area) do
                    local pos = e:GridLocation():GetGridPos() + posArea
                    table.insert(posList, pos)
                end
            end
        end
        centerPos = posList --Vector2[]
    elseif centerType == SkillScopeCenterType.PickUpGridPos then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            centerPos = previewPickUpComponent:GetLastPickUpGridPos()
        end
    elseif centerType == SkillScopeCenterType.PickUpMultiGridPos then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            centerPos = previewPickUpComponent:GetAllValidPickUpGridPos()
        end
    elseif centerType == SkillScopeCenterType.SelectNeareat2Pet then
        local teamEntity = self._world:Player():GetCurrentTeamEntity()
        centerPos = self:_SelectNeareat2Pet(casterPos, scopeParam, teamEntity)
    elseif centerType == SkillScopeCenterType.ChainSkillPickUpGridPos then
        ---@type Entity
        local renderBoardEntity = self._world:GetRenderBoardEntity()
        ---@type PickUpTargetComponent
        local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
        centerPos = pickUpTargetCmpt:GetCurPickUpGridSafePos()
    elseif centerType == SkillScopeCenterType.CastBombPos then
        centerPos = self:_PreviewCalcBombPos(casterPos, scopeParam)
    elseif centerType == SkillScopeCenterType.FirstPickUpGridPos then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            centerPos = previewPickUpComponent:GetFirstValidPickUpGridPos()
        end
    elseif centerType == SkillScopeCenterType.NearestPetChessPos then
        centerPos = self:GetNearestPetChessPosCenterPos(centerPos)
    elseif centerType == SkillScopeCenterType.NearestPosToCasterInPickMonster then
        local retPos = self:PreviewGetNearestPosToCasterInPickMonster(casterEntity)
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.PickUpMonsterPos then
        local retPos = self:PreviewGetPickUpMonsterPosCenterPos(casterEntity)
        if retPos then
            centerPos = retPos
        end
    elseif centerType == SkillScopeCenterType.PickUpMonsterPosAndCasterPos then
        local retPos = self:PreviewGetPickUpMonsterPosAndCasterPosCenterPos(casterEntity)
        if retPos then
            centerPos = retPos
        end
    end
    return centerPos, bodyArea
end
function UtilScopeCalcServiceShare:AutoFightCalcBombPos(casterPos, pickUpGridPos)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local dir = pickUpGridPos - casterPos
    if dir.x > 0 then
        dir.x = 1
    end
    if dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    end
    if dir.y < 0 then
        dir.y = -1
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local maxX = boardServiceLogic:GetCurBoardMaxX()
    local maxY = boardServiceLogic:GetCurBoardMaxY()
    local max = math.max(maxX, maxY)
    local centerPos = casterPos
    for i = 1, max do
        local pos = casterPos + dir * i
        if not self:IsValidPiecePos(pos) then
            centerPos = pos - dir
            break
        end
        if utilDataSvc:IsPosBlock(pos, BlockFlag.LinkLine) or utilDataSvc:GetPieceType(pos) == PieceType.None then
            centerPos = pos
            break
        end
    end
    return centerPos
end
function UtilScopeCalcServiceShare:_PreviewCalcBombPos(casterPos, scopeParam)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type PreviewEnvComponent
    local env = self._world:GetPreviewEntity():PreviewEnv()
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type PickUpTargetComponent
    local pickUpTargetCmpt = renderBoardEntity:PickUpTarget()
    local petPstID = pickUpTargetCmpt:GetPetPstid()

    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)

    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()

    local pickUpGridPos = pickUpTargetCmpt:GetCurPickUpGridPos()
    local dir = pickUpGridPos - casterPos
    if dir.x > 0 then
        dir.x = 1
    end
    if dir.x < 0 then
        dir.x = -1
    end
    if dir.y > 0 then
        dir.y = 1
    end
    if dir.y < 0 then
        dir.y = -1
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local maxX = boardServiceLogic:GetCurBoardMaxX()
    local maxY = boardServiceLogic:GetCurBoardMaxY()
    local max = math.max(maxX, maxY)
    local centerPos = casterPos
    for i = 1, max do
        local pos = casterPos + dir * i
        if not self:IsValidPiecePos(pos) then
            centerPos = pos - dir
            break
        end
        if utilDataSvc:IsPosBlock(pos, BlockFlag.LinkLine) or utilDataSvc:GetPieceType(pos) == PieceType.None then
            centerPos = pos
            break
        end
    end
    return centerPos
end

--计算炸弹落点
function UtilScopeCalcServiceShare:_CalcBombPos(teamEntity, casterPos, scopeParam)
    local centerPos = casterPos

    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)
    local petEntity = self._world:GetEntityByID(petEntityId)
    ---@type ActiveSkillPickUpComponent
    local activeSkillPickUpComponent = petEntity:ActiveSkillPickUpComponent()
    if activeSkillPickUpComponent then
        local pickUpPos = activeSkillPickUpComponent:GetLastPickUpGridPos()
        local dir = pickUpPos - casterPos
        if dir.x > 0 then
            dir.x = 1
        end
        if dir.x < 0 then
            dir.x = -1
        end
        if dir.y > 0 then
            dir.y = 1
        end
        if dir.y < 0 then
            dir.y = -1
        end
        ---@type BoardServiceLogic
        local boardServiceLogic = self._world:GetService("BoardLogic")
        local maxX = boardServiceLogic:GetCurBoardMaxX()
        local maxY = boardServiceLogic:GetCurBoardMaxY()
        local max = math.max(maxX, maxY)
        for i = 1, max do
            local pos = casterPos + dir * i
            if not self:IsValidPiecePos(pos) then
                centerPos = pos - dir
                break
            end
            if utilDataSvc:IsPosBlock(pos, BlockFlag.LinkLine) or utilDataSvc:GetPieceType(pos) == PieceType.None then
                centerPos = pos
                break
            end
        end
    end
    return centerPos
end

function UtilScopeCalcServiceShare:_SelectNeareat2Pet(casterPos, scopeParam, teamEntity)
    if scopeParam then
        local tPos = scopeParam:GetScopeCenterParam()
        if tPos then
            local posTeam = teamEntity:GridLocation():GetGridPos()
            local distance = 999
            local pos = nil
            for i, p in ipairs(tPos) do
                local posParam = Vector2(p[1], p[2])
                local dis = Vector2.Distance(posParam, posTeam)
                if distance > dis then
                    distance = dis
                    pos = posParam
                end
            end
            local posArr = tPos[1]
            return pos or Vector2(posArr[1], posArr[2])
        end
    end
    return casterPos
end

--endregion 拾取

--计算技能范围，需要考虑占多个格子的情况
---@param skillConfigData SkillConfigData
---@param casterPos Vector2 施法者位置
---@param bodyArea Vector2[] 占位数组
---@param entity Entity 中心实体
---@return SkillScopeResult
function UtilScopeCalcServiceShare:CalcSkillScope(skillConfigData, casterPos, casterEntity, casterDir)
    --local t1 = os.clock()
    local playerBodyArea = casterEntity:BodyArea():GetArea()
    local dir = casterDir or casterEntity:GridLocation():GetGridDir()
    local scopeResult =
    self._skillScopeCalc:CalcSkillScope(skillConfigData, casterPos, dir, playerBodyArea, casterEntity)
    --local usetime = (os.clock() - t1) * 1000
    --Log.prof("[AutoFight] CalcSkillScope() skillID=", skillConfigData:GetID(), " use time=", usetime)
    return scopeResult
end

function UtilScopeCalcServiceShare:CalcSkillScopeForChainSkillPreview(skillConfigData, playerGridPos, casterEntity)
    return self._skillScopeCalc:CalcSkillScopeForChainSkillPreview(skillConfigData, playerGridPos, casterEntity)
end

---计算技能预览的范围
---@param scopeParam SkillPreviewScopeParam
---@return SkillScopeResult
function UtilScopeCalcServiceShare:CalcScopeResult(scopeParam, casterEntity)
    local casterPos = casterEntity:GridLocation():CenterNoOffset()

    ---@type SkillScopeResult
    local scopeResult = self:CalcSKillPreviewScopeResult(scopeParam, casterPos, casterEntity)
    ---暂时只取有效范围
    return scopeResult
end

---计算技能预览的范围
----@param skillPreviewScopeParam SkillPreviewScopeParam
----@param casterEntity Entity
function UtilScopeCalcServiceShare:CalcSKillPreviewScopeResult(skillPreviewScopeParam, casterPos, casterEntity)
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local dir = casterEntity:GridLocation():GetGridDir()
    ---@type SkillScopeResult
    local scopeResult =
    self._skillScopeCalc:CalcSkillPreviewScope(casterPos, dir, casterBodyArea, skillPreviewScopeParam, casterEntity)

    return scopeResult
end

--计算技能效果的范围
---@param skillEffectParam SkillEffectParamBase
---@param casterPos Vector2
---@param casterEntity Entity
function UtilScopeCalcServiceShare:CalcSkillEffectScopeResult(skillEffectParam, casterPos, casterEntity)
    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local dir = casterEntity:GridLocation():GetGridDir()
    return self._skillScopeCalc:CalcSkillEffectScope(casterPos, dir, casterBodyArea, skillEffectParam, casterEntity)
end

function UtilScopeCalcServiceShare:GetSkillScopeCalc()
    return self._skillScopeCalc
end

--region 局内外区别显

--- 这是一个override，因此接口本身予以保留，实际逻辑搬走
function UtilScopeCalcServiceShare:IsValidPiecePos(pos)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local isValidGrid = utilData:IsValidPiecePos(pos)
    return isValidGrid
end

function UtilScopeCalcServiceShare:IsPosBlock(pos, blockFlag)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local isBlocked = utilData:IsPosBlock(pos, blockFlag)
    return isBlocked
end

function UtilScopeCalcServiceShare:GetBlockGridTrapPosList(blockType)
    if not blockType then
        blockType = BlockFlag.Skill
    end
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posList = boardServiceLogic:GetPosListByFlag(blockType)
    return posList
end

--怪物使用的阻挡移动，这里要包含玩家脚下，所以不能使用LinkLine，因为玩家脚下可以LinkLine
function UtilScopeCalcServiceShare:GetBlockMovePosList()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posList = boardServiceLogic:GetPosListByFlag(BlockFlag.MonsterLand)
    return posList
end

--endregion 局内外区别显

--region scope

---@param limit number
---@return table<number,Entity>,table<number,Vector2>
function UtilScopeCalcServiceShare:SelectAllMonster(casterEntity, limit)
    ---@type table<number,Entity>
    local monsters = {}
    ---@type table<number,Vector2>
    local monsters_pos = {}
    if casterEntity and self._world:MatchType() == MatchType.MT_BlackFist then
        if casterEntity:HasSuperEntity() then
            casterEntity = casterEntity:GetSuperEntity()
        elseif casterEntity:HasSummoner() then
            casterEntity = casterEntity:GetSummonerEntity()
        end
        if casterEntity:HasPet() then
            local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
            local enemyEntity = teamEntity:Team():GetEnemyTeamEntity()
            monsters[1] = enemyEntity
            monsters_pos[1] = enemyEntity:GetGridPosition()
        end
        return monsters, monsters_pos
    end
    ---@type Group
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monster_group:GetEntities()) do
        if not e:HasDeadMark() then
            ---@type BuffComponent
            local buffComponent = e:BuffComponent()
            if buffComponent and not buffComponent:HasBuffEffect(BuffEffectType.NotBeSelectedAsSkillTarget) then
                local monster_grid_location_cmpt = e:GridLocation()
                local bodyAreaList = e:BodyArea():GetArea()
                if not limit or #monsters < limit then
                    table.insert(monsters, e)
                    for _, bodyArea in ipairs(bodyAreaList) do
                        local pos = monster_grid_location_cmpt.Position + bodyArea
                        table.insert(monsters_pos, pos)
                    end
                end
            end
        end
    end
    return monsters, monsters_pos
end

---@param casterEntity Entity
---
function UtilScopeCalcServiceShare:SelectMonsterWithBuff(buffEffectType, casterEntity, have)
    ---@type table<number,Entity>
    local monsters = {}
    ---@type table<number,Vector2>
    local monsters_pos = {}

    local targets = {}
    if self._world:MatchType() == MatchType.MT_BlackFist then
        targets = { casterEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity() }
    else
        ---@type Group
        local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        targets = monster_group:GetEntities()
    end
    for _, e in ipairs(targets) do
        local monster_grid_location_cmpt = e:GridLocation()
        if e:BuffComponent() and (have == 1 and e:BuffComponent():HasBuffEffect(buffEffectType)) or
            (have == 0 and not e:BuffComponent():HasBuffEffect(buffEffectType))
        then
            table.insert(monsters, e)
            table.insert(monsters_pos, monster_grid_location_cmpt.Position)
        end
    end
    return monsters, monsters_pos
end

---以释放者的坐标为原点 找到离它最近的limit个怪物 返回怪物和怪物的坐标
---暂时逻辑是 当两个怪物距离相同时 随机取一个
---@param caster_pos Vector2
---@param limit number
---@return table<number,Entity>,table<number,Vector2>
---@param casterEntity Entity
function UtilScopeCalcServiceShare:SelectNearestMonsterInRangeOnPos(casterEntity, caster_pos, limit, range)
    local targetIDArray = {}

    if self._world:MatchType() == MatchType.MT_BlackFist then
        if casterEntity:HasSuperEntity() then
            casterEntity = casterEntity:SuperEntityComponent():GetSuperEntity()
        end
        if casterEntity:HasSummoner() then
            casterEntity = casterEntity:GetSummonerEntity()
        end
        local teamEntity = casterEntity:Pet():GetOwnerTeamEntity()
        local enemy = teamEntity:Team():GetEnemyTeamEntity()
        if table.icontains(range, enemy:GetGridPosition()) then
            targetIDArray[#targetIDArray + 1] = enemy:GetID()
        end
        return targetIDArray
    end
    if limit == -1 then
        ---@type BoardServiceLogic
        local boardService = self._world:GetService("BoardLogic")
        local distance_monster = {}
        local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        limit = #monster_group:GetEntities()
    end
    ---@type SkillScopeTargetSelector
    local skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()
    local selectedMonsterIds = {}
    for _, skillRangePos in ipairs(range) do
        local targetIDInSkillRangeList = skillScopeTargetSelector:_CalcMonsterInSkillRange(skillRangePos)
        for _, v in ipairs(targetIDInSkillRangeList) do
            if v > 0 then
                selectedMonsterIds[#selectedMonsterIds + 1] = v
            end
        end
    end

    ---去重
    selectedMonsterIds = table.unique(selectedMonsterIds)
    local sortMonsterList = self:SortMonstersListByPos(caster_pos, selectedMonsterIds)
    for i, id in ipairs(sortMonsterList) do
        if i > limit then
            break
        end
        table.insert(targetIDArray, id.monster_e:GetID())
    end
    return targetIDArray
end

---以释放者的坐标为原点 找到离它最近的limit个怪物 返回怪物和怪物的坐标
---暂时逻辑是 当两个怪物距离相同时 随机取一个
---@param caster_pos Vector2
---@param limit number
---@return table<number,Entity>,table<number,Vector2>
function UtilScopeCalcServiceShare:SelectNearestMonsterOnPos(caster_pos, limit)
    if limit == -1 then
        ---@type BoardServiceLogic
        local boardService = self._world:GetService("BoardLogic")
        local distance_monster = {}
        local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        limit = #monster_group:GetEntities()
    end

    ---@type table<number,Entity>
    local monsters = {}
    ---@type table<number,Vector2>
    local monsters_pos = {}
    ---@type table table = {dis=number,monster_e=Entity,pos=Vector2}
    local distance_monster = self:SortMonstersByPos(caster_pos,true)

    ---@type SkillScopeTargetSelector
    local skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()

    for _, element in ipairs(distance_monster) do
        ---@type Entity
        local monsterEntity = element.monster_e
        local curHP = monsterEntity:Attributes():GetCurrentHP()
        if #monsters < limit and not monsterEntity:HasDeadMark() and curHP > 0 and
            skillScopeTargetSelector:SelectConditionFilter(monsterEntity)
        then
            table.insert(monsters, element.monster_e)
            table.insert(monsters_pos, element.pos)
        end
    end
    return monsters, monsters_pos
end

function UtilScopeCalcServiceShare:SortMonstersListByPos(target_pos, monsterIDList, nearestForMultiGridMonster)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local distance_monster = {}
    for _, entityID in ipairs(monsterIDList) do
        ---@type Entity
        local e = self._world:GetEntityByID(entityID)
        local position = e:GridLocation().Position
        --如果不在场地内 则攻击不到 **麦格芬起飞不受伤害**
        if utilData:IsValidPiecePos(position) then
            if nearestForMultiGridMonster then
                local pos = position
                local distance = Vector2.Distance(pos, target_pos)
                local tBodyArea = e:BodyArea():GetArea()
                for _, v2RelativeBody in ipairs(tBodyArea) do
                    local v2 = v2RelativeBody + position
                    local newDis = Vector2.Distance(v2, target_pos)
                    if distance > newDis then
                        distance = newDis
                        pos = v2
                    end
                end
                table.insert(distance_monster, { dis = distance, monster_e = e, pos = pos })
            else
                local distance = Vector2.Distance(position, target_pos)
                table.insert(distance_monster, { dis = distance, monster_e = e, pos = position })
            end
        end
    end

    local function get_index(c, p)
        if p.x - c.x == 0 and p.y - c.y > 0 then
            return 1
        end
        if p.x - c.x > 0 and p.y - c.y > 0 then
            return 2
        end
        if p.x - c.x > 0 and p.y - c.y == 0 then
            return 3
        end
        if p.x - c.x > 0 and p.y - c.y < 0 then
            return 4
        end
        if p.x - c.x == 0 and p.y - c.y < 0 then
            return 5
        end
        if p.x - c.x < 0 and p.y - c.y < 0 then
            return 6
        end
        if p.x - c.x < 0 and p.y - c.y == 0 then
            return 7
        end
        if p.x - c.x < 0 and p.y - c.y > 0 then
            return 8
        end
        return 1
    end

    local function cmp_fun(ele1, ele2)
        if ele1.dis == ele2.dis then
            return get_index(target_pos, ele1.pos) < get_index(target_pos, ele2.pos)
        else
            return ele1.dis < ele2.dis
        end
    end

    table.sort(distance_monster, cmp_fun)
    return distance_monster
end
--按体型和距离排序
function UtilScopeCalcServiceShare:SortMonstersListByBodyAreaAndPos(target_pos, monsterIDList, nearestForMultiGridMonster)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local distance_monster = {}
    for _, entityID in ipairs(monsterIDList) do
        ---@type Entity
        local e = self._world:GetEntityByID(entityID)
        local position = e:GridLocation().Position
        --如果不在场地内 则攻击不到 **麦格芬起飞不受伤害**
        if utilData:IsValidPiecePos(position) then
            local tBodyArea = e:BodyArea():GetArea()
            local bodyAreaSize = #tBodyArea
            if nearestForMultiGridMonster then
                local pos = position
                local distance = Vector2.Distance(pos, target_pos)
                for _, v2RelativeBody in ipairs(tBodyArea) do
                    local v2 = v2RelativeBody + position
                    local newDis = Vector2.Distance(v2, target_pos)
                    if distance > newDis then
                        distance = newDis
                        pos = v2
                    end
                end
                table.insert(distance_monster, { dis = distance, monster_e = e, pos = pos, size = bodyAreaSize })
            else
                local distance = Vector2.Distance(position, target_pos)
                table.insert(distance_monster, { dis = distance, monster_e = e, pos = position, size = bodyAreaSize })
            end
        end
    end

    local function get_index(c, p)
        if p.x - c.x == 0 and p.y - c.y > 0 then
            return 1
        end
        if p.x - c.x > 0 and p.y - c.y > 0 then
            return 2
        end
        if p.x - c.x > 0 and p.y - c.y == 0 then
            return 3
        end
        if p.x - c.x > 0 and p.y - c.y < 0 then
            return 4
        end
        if p.x - c.x == 0 and p.y - c.y < 0 then
            return 5
        end
        if p.x - c.x < 0 and p.y - c.y < 0 then
            return 6
        end
        if p.x - c.x < 0 and p.y - c.y == 0 then
            return 7
        end
        if p.x - c.x < 0 and p.y - c.y > 0 then
            return 8
        end
        return 1
    end

    local function cmp_fun(ele1, ele2)
        if ele1.size == ele2.size then
            if ele1.dis == ele2.dis then
                return get_index(target_pos, ele1.pos) < get_index(target_pos, ele2.pos)
            else
                return ele1.dis < ele2.dis
            end
        else
            return ele1.size < ele2.size
        end
    end

    table.sort(distance_monster, cmp_fun)
    return distance_monster
end
--按照与Pos距离对Monster排序
---@param target_pos Vector2
---@return table table = {dis=number,monster_e=Entity,pos=Vector2}
function UtilScopeCalcServiceShare:SortMonstersByPos(target_pos, nearestForMultiGridMonster)
    local monster_group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    local monsterIDList = {}
    for _, e in ipairs(monster_group:GetEntities()) do
        table.insert(monsterIDList, e:GetID())
    end
    return self:SortMonstersListByPos(target_pos, monsterIDList, nearestForMultiGridMonster)
end

--根据pieceType类型找到最近centerPos的maxCount个数的格子坐标
---@param centerPos Vector2
---@param pieceTypeList PieceType[]
---@param maxCount number
function UtilScopeCalcServiceShare:FindPieceElementByTypeCountAndCenter(centerPos, pieceTypeList, maxCount, excludeTrap, excludePosList)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    return utilCalcSvc:FindPieceElementByTypeCountAndCenter(centerPos, pieceTypeList, maxCount, nil, nil, excludeTrap, excludePosList)
end

--在给定的格子areaGridList内根据pieceType类型选出所有格子坐标
---@param areaGridList Vector2[]
---@param pieceTypeList PieceType[]
---@param excludeTrap number
function UtilScopeCalcServiceShare:FindPieceElementByTypeAndArea(areaGridList, pieceTypeList, excludeTrap)
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    return utilCalcSvc:FindPieceElementByTypeAndArea(areaGridList, pieceTypeList, excludeTrap)
end

function UtilScopeCalcServiceShare:ChangeGameFSMState2PickUp()
    local gameFsmCmpt = self._world:GameFSM()
    local gameFsmStateID = gameFsmCmpt:CurStateID()
    if gameFsmStateID == GameStateID.PreviewActiveSkill then
        self._world:EventDispatcher():Dispatch(GameEventType.PreviewActiveSkillFinish, 3)
        self._world:EventDispatcher():Dispatch(GameEventType.PickUPValidGridShowChooseTarget, true)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnClickWhenPickUp)
    end
end

function UtilScopeCalcServiceShare:IsPosHaveMonsterOrPet(pos)
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    local es =
    boardCmpt:GetPieceEntities(
        pos,
        function(e)
            return e:HasTeam() or e:HasMonsterID()
        end
    )

    return #es > 0
end

---注意：这里的空格子指的是能走上去的格子！使用前需注意策划要的空格子有多空！
function UtilScopeCalcServiceShare:GetEmptyPieces(fixedRange)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local posTable = {}
    --人
    local teamGroup = self._world:GetGroup(self._world.BW_WEMatchers.Team)
    for i, e in ipairs(teamGroup:GetEntities()) do
        local player_pos = e:GridLocation().Position
        if not posTable[player_pos.x] then
            posTable[player_pos.x] = {}
        end
        posTable[player_pos.x][player_pos.y] = true
    end
    --陷阱
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            local trapPos = e:GridLocation().Position
            if not posTable[trapPos.x] then
                posTable[trapPos.x] = {}
            end
            posTable[trapPos.x][trapPos.y] = true
        end
    end
    --怪（不能划线的格子可满足）
    local blockPosList = boardServiceLogic:GetPosListByFlag(BlockFlag.LinkLine)
    if blockPosList then
        for i, pos in ipairs(blockPosList) do
            if not posTable[pos.x] then
                posTable[pos.x] = {}
            end
            posTable[pos.x][pos.y] = true
        end
    end

    local validPos
    if fixedRange then
        validPos = fixedRange
    else
        validPos = boardServiceLogic:GetPlayerAreaPosList()
    end
    local target_area_grid = {}
    for i, pos in ipairs(validPos) do
        if not posTable[pos.x] or not posTable[pos.x][pos.y] then
            table.insert(target_area_grid, pos)
        end
    end

    return target_area_grid
end

---@return Vector2[]
function UtilScopeCalcServiceShare:GetAllValidGridPosList()
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetPlayerAreaPosList()
end

--endregion scope

--region 连锁技目标选择

---根据连线，选择队伍，并为出战队伍的每一位成员选择攻击目标
---@param actorEntity Entity
---@param pieceType PieceType 划线颜色
function UtilScopeCalcServiceShare:SelectTarget(actorEntity, pieceType)
    self._chainPathTargetSelector:DoSelectTarget(actorEntity, pieceType)
end

--endregion 连锁技目标选择

--region SkillLogic

---给外部提供的接口，用于计算范围内的目标
---@param castEntity Entity
---@param targetType SkillTargetType 技能目标类型
---@param scopeResult SkillScopeResult
function UtilScopeCalcServiceShare:SelectSkillTarget(
    castEntity,
    targetType,
    scopeResult,
    skillID,
    skillEffectTargetTypeParam)
    return self._skillScopeTargetSelector:DoSelectSkillTarget(
        castEntity,
        targetType,
        scopeResult,
        skillID,
        skillEffectTargetTypeParam
    )
end

function UtilScopeCalcServiceShare:BuildScopeGridList_CheckPosFunc(onlyCanmove, notDoor, canConvert, pos,enemyTeamPos,boardServiceLogic, notExit)
    if canConvert and self:IsPosBlock(pos, BlockFlag.ChangeElement) then
        return
    end
    if onlyCanmove and (self:IsPosBlock(pos, BlockFlag.LinkLine) or pos == enemyTeamPos) then
        return
    end
    if notDoor and boardServiceLogic:IsDoor(pos) then
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    if notExit and utilDataSvc:IsPosExit(pos) then
        return
    end
    return true
end

----@return Vector2[]
----@param scopeParamList SkillPreviewScopeParam[]
function UtilScopeCalcServiceShare:BuildScopeGridList(scopeParamList, casterEntity)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local enemyTeamPos
    if self._world:MatchType() == MatchType.MT_BlackFist then
        enemyTeamPos = casterEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity():GetGridPosition()
    end

    local casterPos = casterEntity:GridLocation():CenterNoOffset()
    ---@type Vector2
    local scopeGirdList = {}
    for _, scopeParam in ipairs(scopeParamList) do
        ---@type SkillScopeResult
        local scopeResult = self:CalcSKillPreviewScopeResult(scopeParam, casterPos, casterEntity)
        local scopeList = scopeResult:GetAttackRange()
        local realScopeList = {}
        for i, pos in ipairs(scopeList) do
            if self:BuildScopeGridList_CheckPosFunc(scopeParam:GetOnlyCanMove(), scopeParam:GetNotDoor(), scopeParam:GetCanConvert(),
                    pos, enemyTeamPos, boardServiceLogic, scopeParam:GetNotExit()) then
                realScopeList[Vector2.Pos2Index(pos)] = true
            end
        end

        --dump(scopeResult:GetAttackRange())
        for v2Idx, _ in pairs(realScopeList) do --不能改ipairs
            local pos = Vector2.Index2Pos(v2Idx)
            table.insert(scopeGirdList, pos)
        end
    end

    return scopeGirdList
end

function UtilScopeCalcServiceShare:IsPosHasMonster(pos)
	if not pos then
        return false, nil
	end
    ----@type Entity[]
    local monsterEntityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(monsterEntityList) do
        local monsterEntityID = e:GetID()
        local monsterPos = e:GetGridPosition()
        local monster_body_area_cmpt = e:BodyArea()
        local monster_body_area = monster_body_area_cmpt:GetArea()
        for i, bodyArea in ipairs(monster_body_area) do
            if (monsterPos.x + bodyArea.x) == pos.x and (monsterPos.y + bodyArea.y) == pos.y then
                return true, monsterEntityID
            end
        end
    end

    return false, nil
end

---根据施法者的坐标 按照方向和距离排序技能范围
function UtilScopeCalcServiceShare:SortSkillRangeByDirectionAndDistance(casterPos, skillRangePos)
    local sortGridList = {}
    for _, gridPos in ipairs(skillRangePos) do
        local direction = gridPos - casterPos
        local directionName = nil
        if direction.x == 0 and direction.y > 0 then
            -- directionName = "Up"
            directionName = 1
        elseif direction.x == 0 and direction.y < 0 then
            -- directionName = "Down"
            directionName = 2
        elseif direction.x > 0 and direction.y == 0 then
            -- directionName = "Rgiht"
            directionName = 3
        elseif direction.x < 0 and direction.y == 0 then
            -- directionName = "Left"
            directionName = 4
        end

        if directionName then
            if not sortGridList[directionName] then
                sortGridList[directionName] = {}
            end

            table.insert(sortGridList[directionName], gridPos)
        end
    end

    if table.count(sortGridList) > 0 then
        for _, gridPosList in pairs(sortGridList) do --不能改ipairs
            table.sort(
                gridPosList,
                function(a, b)
                    local disA = Vector2.Distance(a, casterPos)
                    local disB = Vector2.Distance(b, casterPos)
                    return disA < disB
                end
            )
        end
    end

    return sortGridList
end

----@param skillConfigData SkillConfigData
----@param casterEntity Entity
---@return Vector2[]
function UtilScopeCalcServiceShare:CalcSkillResultByConfigData(skillConfigData, casterEntity)
    ---技能范围
    local targetType = skillConfigData:GetSkillTargetType()
    local targetTypeParam = skillConfigData:GetSkillTargetTypeParam()
    local scopeParam =
    SkillPreviewScopeParam:New(
        {
            TargetType = targetType,
            ScopeType = skillConfigData:GetSkillScopeType(),
            ScopeCenterType = skillConfigData:GetSkillScopeCenterType(),
            TargetTypeParam = targetTypeParam
        }
    )
    scopeParam:SetScopeParamData(skillConfigData:GetSkillScopeParam())
    local scopeResult = self:CalcScopeResult(scopeParam, casterEntity)
    return scopeResult:GetAttackRange()
end

function UtilScopeCalcServiceShare:GetEntityDistanceInfoArray(entityIDs, v2CenterPos)
    local tTargetDistanceInfo = {}
    for _, targetID in ipairs(entityIDs) do
        local e = self._world:GetEntityByID(targetID)
        if e then
            ---@type Vector2
            local v2GridPos = e:GetGridPosition()
            local distance = Vector2.Distance(v2GridPos, v2CenterPos)
            table.insert(
                tTargetDistanceInfo,
                {
                    targetID = targetID,
                    gridPos = v2GridPos,
                    distance = distance,
                    entity = e
                }
            )
        end
    end

    local scopeCalc = self:GetSkillScopeCalc()
    table.sort(
        tTargetDistanceInfo,
        function(a, b)
            if a.distance ~= b.distance then
                return a.distance < b.distance
            end

            local HBDTa = scopeCalc:GetDirection(a.gridPos, v2CenterPos)
            local HBDTb = scopeCalc:GetDirection(b.gridPos, v2CenterPos)
            if HBDTa ~= HBDTb then
                return HBDTa < HBDTb
            end

            --骑乘
            if a.entity:HasRide() then
                ---@type RideComponent
                local rideCmpt = a.entity:Ride()
                return a.targetID == rideCmpt:GetRiderID()
            end
        end
    )

    return tTargetDistanceInfo
end

function UtilScopeCalcServiceShare:GetEntityDistanceInfoArrayByPosDic(entityIDs, v2CenterPos, posDic)
    local tTargetDistanceInfo = {}
    for _, targetID in ipairs(entityIDs) do
        local e = self._world:GetEntityByID(targetID)
        if e then
            ---@type Vector2
            -- local v2GridPos = e:GetGridPosition()
            local v2GridPos = (posDic[targetID]) and (table.remove(posDic[targetID], 1)) or (nil)
            if v2GridPos then
                local distance = Vector2.Distance(v2GridPos, v2CenterPos)
                table.insert(
                    tTargetDistanceInfo,
                    {
                        targetID = targetID,
                        gridPos = v2GridPos,
                        distance = distance,
                        entity = e
                    }
                )
            end
        end
    end

    local scopeCalc = self:GetSkillScopeCalc()
    table.sort(
        tTargetDistanceInfo,
        function(a, b)
            if a.distance ~= b.distance then
                return a.distance < b.distance
            end

            local HBDTa = scopeCalc:GetDirection(a.gridPos, v2CenterPos)
            local HBDTb = scopeCalc:GetDirection(b.gridPos, v2CenterPos)
            if HBDTa ~= HBDTb then
                return HBDTa < HBDTb
            end

            --骑乘
            if a.entity:HasRide() then
                ---@type RideComponent
                local rideCmpt = a.entity:Ride()
                return a.targetID == rideCmpt:GetRiderID()
            end
        end
    )

    return tTargetDistanceInfo
end

---@param blockFlag BlockFlag
function UtilScopeCalcServiceShare:GetSpBlockRange(blockFlag)
    ---@type Vector2[]
    local range = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    local arr = board:GetBlockFlagArray()
    for x, col in pairs(arr) do --不能改ipairs
        for y, block in pairs(col) do --不能改ipairs
            local grid = Vector2(x, y)
            if not boardServiceLogic:IsPosBlock(grid, blockFlag) then
                table.insert(range, grid)
            end
        end
    end
    return range
end

---@return Vector2[]
function UtilScopeCalcServiceShare:GetFullScreenCanSummonTrapRange()
    return self:GetSpBlockRange(BlockFlag.SummonTrap)
end

function UtilScopeCalcServiceShare:GetFullScreenCanChangeElementRange()
    return self:GetSpBlockRange(BlockFlag.ChangeElement)
end

---根据给定的中心坐标将场面划分为4个象限
function UtilScopeCalcServiceShare:GetBoardQuadrantsByCenter(centerPos, casterEntity, excludeSelf)
    local baseScopeCalc = SkillScopeCalculator:New(self)
    local fullScreenCalc = SkillScopeCalculator_FullScreen:New(baseScopeCalc)
    ---@type SkillScopeResult
    local platformScopeResult =
    fullScreenCalc:CalcRange(
        SkillScopeType.FullScreen,
        excludeSelf and 1 or 0,
        centerPos,
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        SkillTargetType.Board,
        centerPos
    )

    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    local rt, rb, lb, lt = utilCalcSvc:DivideGridsByQuadrant(platformScopeResult:GetAttackRange(), centerPos)

    return {
        [BoardQuadrant.RightTop] = rt,
        [BoardQuadrant.RightBottom] = rb,
        [BoardQuadrant.LeftBottom] = lb,
        [BoardQuadrant.LeftTop] = lt
    }
end

----@return Vector2[]
----@param scopeParamList SkillPreviewScopeParam[]
function UtilScopeCalcServiceShare:BuildScopeGridListMultiPick(scopeParamList, casterEntity, pickPosList)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local enemyTeamPos
    if self._world:MatchType() == MatchType.MT_BlackFist then
        enemyTeamPos = casterEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity():GetGridPosition()
    end
    local casterPos = pickPosList
    --casterEntity:GridLocation():CenterNoOffset()
    ---@type Vector2
    local scopeGirdList = {}
    for _, scopeParam in ipairs(scopeParamList) do
        ---@type SkillScopeResult
        local scopeResult = self:CalcSKillPreviewScopeResult(scopeParam, casterPos, casterEntity)
        local scopeList = scopeResult:GetAttackRange()
        local realScopeList = {}
        for i, pos in ipairs(scopeList) do
            if self:BuildScopeGridList_CheckPosFunc(scopeParam:GetOnlyCanMove(), scopeParam:GetNotDoor(), scopeParam:GetCanConvert(),
                    pos, enemyTeamPos, boardServiceLogic, scopeParam:GetNotExit()) then
                realScopeList[Vector2.Pos2Index(pos)] = true
            end
        end

        --dump(scopeResult:GetAttackRange())
        for v2Idx, _ in pairs(realScopeList) do --不能改ipairs
            local pos = Vector2.Index2Pos(v2Idx)
            table.insert(scopeGirdList, pos)
        end
    end

    return scopeGirdList
end

--获取可召唤机关的机关格子
--规则一：先排除无法召唤机关的格子
--规则二：再排除和指定机关相同level的格子
--若范围为空，则取消规则二
function UtilScopeCalcServiceShare:GetTrapPiecesExceptTrapID(trapID, fixedRange)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    --陷阱格子
    local trapPosList = self:_GetTrapPosList(fixedRange)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    --去除阻挡召唤的格子
    local canSummonTrapPosList = {}
    for _, pos in ipairs(trapPosList) do
        if not utilDataSvc:IsPosBlock(pos, BlockFlag.SummonTrap) then
            table.insert(canSummonTrapPosList, pos)
        end
    end

    --去除相同和指定trapID相同level的格子
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type TrapConfigData
    local trapConfigData = configService:GetTrapConfigData()
    local trapData = trapConfigData:GetTrapData(trapID)
    local posList = {}
    ---@type TrapServiceLogic
    local trapServiceLogic = self._world:GetService("TrapLogic")
    local onlyViewTrap = trapServiceLogic:IsViewTrapLevel(trapData.TrapLevel)
    for _, pos in ipairs(canSummonTrapPosList) do
        local es =
        boardCmpt:GetPieceEntities(
            pos,
            function(e)
                return e:HasTrap() and not e:HasDeadMark() and (e:Trap():GetTrapLevel() == trapData.TrapLevel and not onlyViewTrap)
            end
        )
        if #es == 0 then
            table.insert(posList, pos)
        end
    end

    if #posList == 0 then
        posList = canSummonTrapPosList
    end

    return posList
end

---找有机关的位置
function UtilScopeCalcServiceShare:_GetTrapPosList(fixedRange)
    local trapPosList = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for i, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() then
            local trapPos = e:GridLocation().Position
            if not table.icontains(trapPosList, trapPos) then
                if fixedRange then --指定范围
                    if table.icontains(fixedRange, trapPos) then
                        table.insert(trapPosList, trapPos)
                    end
                else
                    table.insert(trapPosList, trapPos)
                end
            end
        end
    end
    return trapPosList
end

---@param monsterPos Vector2
---@return number[]
function UtilScopeCalcServiceShare:GetSortChessPetByMonsterPos(monsterPos)
    ---@type Entity[]
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.ChessPet)
    local entityInfoList = {}
    for i, entity in ipairs(entityList) do
        local hp = entity:Attributes():GetCurrentHP()
        local dis = Vector2.Distance(monsterPos, entity:GetGridPosition())
        table.insert(entityInfoList, { entity = entity, hp = hp, dis = dis, id = entity:GetID() })
    end

    table.sort(
        entityInfoList,
        function(a, b)
            if (a.dis ~= b.dis) then
                return a.dis < b.dis
            else
                if (a.hp ~= b.hp) then
                    return a.hp < b.hp
                else
                    return a.id < b.id
                end
            end
        end
    )
    local retEntityIDList = {}
    for i, v in ipairs(entityInfoList) do
        table.insert(retEntityIDList, v.id)
    end
    return retEntityIDList
end

----@return Vector2[]
function UtilScopeCalcServiceShare:GetTargetSquareRing(entityID, ringCount)
    ---@type Entity
    local monsterEntity = self._world:GetEntityByID(entityID)
    local pos = monsterEntity:GetGridPosition()
    local bodyArea = monsterEntity:BodyArea():GetArea()
    local posList = ComputeScopeRange.ComputeRange_SquareRing(pos, #bodyArea, ringCount)
    return posList
end

---@return Vector2[]
---@param entity Entity
function UtilScopeCalcServiceShare:GetMonsterAroundCanMovePosList(entity,offset)
    if not offset then
        offset = Offset8
    end
    local ret = {}
    local pos = entity:GetGridPosition()
    local raceType = entity:MonsterID():GetMonsterRaceType()
    local effectCalcSvc = self._world:GetService("SkillEffectCalc")
    local blockFlag = effectCalcSvc:_TransBlockByRaceType(raceType)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local boardSvc = self._world:GetService("BoardLogic")
    for i, v in ipairs(offset) do
        local newPos = Vector2(pos.x + v[1], pos.y + v[2])
        if (newPos.x ~= pos.x or newPos.y ~= pos.y) then
            ---需要是一个可连通的格子才行
            if utilDataSvc:IsValidPiecePos(newPos) and not boardSvc:IsPosBlock(newPos, blockFlag) and
                    not utilDataSvc:IsPosHasSpTrap(newPos, TrapType.BadGrid)
            then
                ---Log.fatal("GetPosAroundSameTypePosList NewPos:", tostring(newPos),"NewType:",type,"SourcePos:", tostring(pos),"SourceType:",pieceType)
                table.insert(ret, newPos)
            end
        end
    end
    return ret
end

---@return Vector2[]
function UtilScopeCalcServiceShare:GetPosAroundSameTypePosList(pos, pieceType)
    local ret = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local boardSvc = self._world:GetService("BoardLogic")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    for x = -1, 1 do
        for y = -1, 1 do
            local newPos = Vector2(pos.x + x, pos.y + y)
            if (newPos.x ~= pos.x or newPos.y ~= pos.y) then
                ---需要是一个可连通的格子才行
                if utilDataSvc:IsValidPiecePos(newPos) and not boardSvc:IsPosBlock(newPos, BlockFlag.LinkLine) and
                    not utilDataSvc:IsPosHasSpTrap(newPos, TrapType.BadGrid)
                then
                    local type = board:GetPieceType(newPos)
                    if type == pieceType or type == PieceType.Any then
                        ---Log.fatal("GetPosAroundSameTypePosList NewPos:", tostring(newPos),"NewType:",type,"SourcePos:", tostring(pos),"SourceType:",pieceType)
                        table.insert(ret, newPos)
                    end
                end
            end
        end
    end
    return ret
end

---@return table<number,Entity>,table<number,Vector2>
function UtilScopeCalcServiceShare:SelectAllChessPet()
    ---@type table<number,Entity>
    local chessPets = {}
    local chessPets_pos = {}
    local chessPet_group = self._world:GetGroup(self._world.BW_WEMatchers.ChessPet)
    for _, e in ipairs(chessPet_group:GetEntities()) do
        if not e:HasDeadMark() then
            local monster_grid_location_cmpt = e:GridLocation()
            local bodyAreaList = e:BodyArea():GetArea()
            table.insert(chessPets, e)
            for _, bodyArea in ipairs(bodyAreaList) do
                local pos = monster_grid_location_cmpt.Position + bodyArea
                table.insert(chessPets_pos, pos)
            end
        end
    end
    return chessPets, chessPets_pos
end

function UtilScopeCalcServiceShare:IsTargetInScope(targetID, scopeList)
    ---@type Entity
    local e = self._world:GetEntityByID(targetID)
    local monster_grid_location_cmpt = e:GridLocation()
    local monster_body_area_cmpt = e:BodyArea()
    local monster_body_area = monster_body_area_cmpt:GetArea()
    for i, bodyArea in ipairs(monster_body_area) do
        local curMonsterBodyPos = monster_grid_location_cmpt.Position + bodyArea
        if table.Vector2Include(scopeList, curMonsterBodyPos) then
            return true
        end
    end
    return false
end

---@param scopeList Vector2[]
---@return number[]
function UtilScopeCalcServiceShare:ChessMonsterSelectTarget(scopeList, targetCount)
    ---@type Entity[]
    local entityList = self._world:GetGroupEntities(self._world.BW_WEMatchers.ChessPet)

    local inScopeTargetList = {}
    for i, e in ipairs(entityList) do
        if self:IsTargetInScope(e:GetID(), scopeList) then
            local hp = e:Attributes():GetCurrentHP()
            local id = e:GetID()
            table.insert(inScopeTargetList, { id = id, hp = hp })
        end
    end
    if #inScopeTargetList > targetCount then
        table.sort(
            inScopeTargetList,
            function(a, b)
                if a.hp ~= b.hp then
                    return a.hp < b.hp
                end
                return a.id < b.id
            end
        )
    end
    local retList = {}
    for i, v in ipairs(inScopeTargetList) do
        if i > targetCount then
            break
        end
        table.insert(retList, v.id)
    end
    return retList
end

---用点选坐标获取棋子的朝向
function UtilScopeCalcServiceShare:GetChessEntityGridDirWithPickUpPos(entity, pickUpPos, targetMovePos)
    -- local curPos = entity:GetGridPosition()
    if not targetMovePos then
        targetMovePos = entity:GetGridPosition()
    end

    local bodyArea = entity:BodyArea():GetArea()
    local dir = pickUpPos - targetMovePos
    if table.count(bodyArea) == 4 or Vector2.Distance(targetMovePos, pickUpPos) > 1 then
        -- local vectors = {Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)}
        -- local minIdx, minAngle = 1, 180
        -- local vec = pickUpPos - targetMovePos
        -- for i, v in ipairs(vectors) do
        --     local angle = Vector2.Angle(vec, v)
        --     if minAngle > angle then
        --         minAngle = angle
        --         minIdx = i
        --     end
        -- end
        -- dir = vectors[minIdx]

        --

        ---@type ChessPetComponent
        local chessPetCmpt = entity:ChessPet()
        local attackSkill = chessPetCmpt:GetAttackSkillID()
        ---@type ConfigService
        local cfgSvc = self._world:GetService("Config")
        ---@type SkillConfigData
        local attackSkillConfigData = cfgSvc:GetSkillConfigData(attackSkill, entity)
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")

        local vectors = { Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1) }
        for i, dir in ipairs(vectors) do
            ---@type SkillScopeResult
            local scopeResultSelect = utilScopeSvc:CalcSkillScope(attackSkillConfigData, targetMovePos, entity, dir)
            local selectRange = scopeResultSelect:GetAttackRange()
            if table.intable(selectRange, pickUpPos) then
                return dir
            end
        end
    end

    return dir
end

---@param dir Vector2
function UtilScopeCalcServiceShare:GetDirectionTypeByVector2(dir)
    if dir.x == 0 and dir.y == 1 then
        return DirectionType.Up
    elseif dir.x == 0 and dir.y == -1 then
        return DirectionType.Down
    elseif dir.x == 1 and dir.y == 0 then
        return DirectionType.Right
    elseif dir.x == -1 and dir.y == 0 then
        return DirectionType.Left
    elseif dir.x == 1 and dir.y == 1 then
        return DirectionType.RightUp
    elseif dir.x == -1 and dir.y == 1 then
        return DirectionType.LeftUp
    elseif dir.x == -1 and dir.y == -1 then
        return DirectionType.LeftDown
    elseif dir.x == 1 and dir.y == -1 then
        return DirectionType.RightDown
    end
end

---@param entity Entity
---@return DirectionType
function UtilScopeCalcServiceShare:GetEntityRenderDirType(entity)
    ---@type Vector2
    local dir = entity:GetRenderGridDirection()
    return self:GetDirectionTypeByVector2(dir)
end

---@param entity Entity
---@return DirectionType
function UtilScopeCalcServiceShare:GetEntityDirType(entity)
    ---@type Vector2
    local dir = entity:GetGridDirection()
    return self:GetDirectionTypeByVector2(dir)
end

---@param dirType  DirectionType
---@return Vector2
function UtilScopeCalcServiceShare:GetDirByDirType(dirType)
    if dirType == DirectionType.Up then
        return Vector2(0, 1)
    elseif dirType == DirectionType.Down then
        return Vector2(0, -1)
    elseif dirType == DirectionType.Left then
        return Vector2(-1, 0)
    elseif dirType == DirectionType.Right then
        return Vector2(1, 0)
    end
end

---@param entity Entity
---@return Vector2
function UtilScopeCalcServiceShare:GetVectorDirByBodyArea(entity)
    ---@type BodyAreaComponent
    local bodyAreaCmpt = entity:BodyArea()
    local bodyArea = bodyAreaCmpt:GetArea()
    local pos = bodyArea[2]
    local dirType
    if pos == Vector2(0, -1) then
        dirType = DirectionType.Up
    elseif pos == Vector2(1, 0) then
        dirType = DirectionType.Left
    elseif pos == Vector2(0, 1) then
        dirType = DirectionType.Down
    elseif pos == Vector2(-1, 0) then
        dirType = DirectionType.Right
    end
    local dir = self:GetDirByDirType(dirType)
    return dir
end

---@param casterEntity Entity
---@param casterPos Vector2
---@return Vector2[]
function UtilScopeCalcServiceShare:GetNightKing_Skill1A(casterEntity, casterPos, dirType)
    --local dirType =self:GetEntityDirType(casterEntity)
    ---@type Vector2[]
    local addRangeList = {}
    if dirType == DirectionType.Up then
        addRangeList = { Vector2(-1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), }
    elseif dirType == DirectionType.Down then
        addRangeList = { Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(1, 0), }
    elseif dirType == DirectionType.Left then
        addRangeList = { Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), }
    elseif dirType == DirectionType.Right then
        addRangeList = { Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), Vector2(0, -1), }
    end
    local rangList = {}
    for i, p in ipairs(addRangeList) do
        local newPos = Vector2(p.x + casterPos.x, p.y + casterPos.y)
        table.insert(rangList, newPos)
    end
    return rangList
end

---夜王的甩尾技能判断左右的方向
---@param casterEntity Entity
---@param casterPos Vector2
---@return Vector2[],Vector2[]
function UtilScopeCalcServiceShare:GetNightKing_SkillCScope(casterEntity, casterPos)
    local dirType = self:GetEntityDirType(casterEntity)
    ---@type Vector2[]
    local leftScope = {}
    ---@type Vector2[]
    local rightScope = {}
    ---@type UtilDataServiceShare
    local utilDataCalcSvc = self._world:GetService("UtilData")
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        local range1, range2 = {}, {}
        for y = -1, 1 do
            for x = -2, BattleConst.BoardMaxLen * -1, -1 do
                local newPos = Vector2(x + casterPos.x, y + casterPos.y)
                if utilDataCalcSvc:IsValidPiecePos(newPos) then
                    table.insert(range1, newPos)
                end
            end
        end
        for y = -1, 1 do
            for x = 2, BattleConst.BoardMaxLen do
                local newPos = Vector2(x + casterPos.x, y + casterPos.y)
                if utilDataCalcSvc:IsValidPiecePos(newPos) then
                    table.insert(range2, newPos)
                end
            end
        end
        if dirType == DirectionType.Up then
            leftScope = range1
            rightScope = range2
        elseif dirType == DirectionType.Down then
            leftScope = range2
            rightScope = range1
        end

    elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
        local range1, range2 = {}, {}
        for x = -1, 1 do
            for y = -2, BattleConst.BoardMaxLen * -1, -1 do
                local newPos = Vector2(x + casterPos.x, y + casterPos.y)
                if utilDataCalcSvc:IsValidPiecePos(newPos) then
                    table.insert(range1, newPos)
                end
            end
        end
        for x = -1, 1 do
            for y = 2, BattleConst.BoardMaxLen do
                local newPos = Vector2(x + casterPos.x, y + casterPos.y)
                if utilDataCalcSvc:IsValidPiecePos(newPos) then
                    table.insert(range2, newPos)
                end
            end
        end
        if dirType == DirectionType.Left then
            leftScope = range1
            rightScope = range2
        elseif dirType == DirectionType.Right then
            leftScope = range2
            rightScope = range1
        end
    end
    return leftScope, rightScope
end

---@param casterEntity Entity
---@param targetEntity Entity
---@return Vector2,Vector2
function UtilScopeCalcServiceShare:GetTailFlickSwitchBodyArea(casterEntity, targetEntity)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SwitchBodyAreaDirType
    local switchDirType = self:GetNightKingTailFlickSwitchBodyAreaDirType(casterEntity, casterPos, targetEntity)
    ---@type DirectionType
    local dirType = self:GetEntityDirType(casterEntity)
    ---@type Vector2,Vector2
    local newDir, newBodyArea = self:GetNewDirBySwitchDirType(switchDirType, dirType)
    return newDir, newBodyArea, switchDirType
end

---@return boolean
function UtilScopeCalcServiceShare:IsNightKingCanCounterAttack(casterEntity, targetEntity)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SwitchBodyAreaDirType
    local switchDirType = self:GetNightKingCounterAttackSwitchBodyAreaDirType(casterEntity, casterPos, targetEntity)
    return switchDirType ~= SwitchBodyAreaDirType.None
end

---@return Vector2,Vector2
function UtilScopeCalcServiceShare:GetCounterAttackSwitchBodyArea(casterEntity, targetEntity)
    ---@type Vector2
    local casterPos = casterEntity:GetGridPosition()
    ---@type SwitchBodyAreaDirType
    local switchDirType = self:GetNightKingCounterAttackSwitchBodyAreaDirType(casterEntity, casterPos, targetEntity)
    ---@type DirectionType
    local dirType = self:GetEntityDirType(casterEntity)
    ---@type Vector2,Vector2
    local newDir, newBodyArea = self:GetNewDirBySwitchDirType(switchDirType, dirType)
    return newDir, newBodyArea, switchDirType
end

function UtilScopeCalcServiceShare:ValidPosInsertList(list, pos)
    ---@type UtilDataServiceShare
    local utilDataCalcSvc = self._world:GetService("UtilData")
    if utilDataCalcSvc:IsValidPiecePos(pos) then
        table.insert(list, pos)
    end
end

function UtilScopeCalcServiceShare:GetNightKingCounterAttackScope(casterEntity, casterPos)
    ----@type DirectionType
    local dirType = self:GetEntityDirType(casterEntity)
    local leftScopeList, rightScopeList, downScopeList = {}, {}, {}
    local symbol = 1
    if dirType == DirectionType.Up or dirType == DirectionType.Left then
        symbol = -1
    end

    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        self:ValidPosInsertList(downScopeList, Vector2(casterPos.x - 1, casterPos.y + symbol))
        self:ValidPosInsertList(downScopeList, Vector2(casterPos.x + 1, casterPos.y + symbol))
        self:ValidPosInsertList(leftScopeList, Vector2(casterPos.x + symbol, casterPos.y))
        self:ValidPosInsertList(rightScopeList, Vector2(casterPos.x + (symbol * -1), casterPos.y))
    end
    if dirType == DirectionType.Left or dirType == DirectionType.Right then
        self:ValidPosInsertList(downScopeList, Vector2(casterPos.x + (symbol * -1), casterPos.y - 1))
        self:ValidPosInsertList(downScopeList, Vector2(casterPos.x + (symbol * -1), casterPos.y + 1))
        self:ValidPosInsertList(leftScopeList, Vector2(casterPos.x, casterPos.y + (symbol)))
        self:ValidPosInsertList(rightScopeList, Vector2(casterPos.x, casterPos.y + (symbol * -1)))
    end

    for a = 2, BattleConst.BoardMaxLen do
        for n = 2, BattleConst.BoardMaxLen do
            for b = n * -1, n do
                if dirType == DirectionType.Left or dirType == DirectionType.Right then
                    self:ValidPosInsertList(downScopeList, Vector2(casterPos.x + (a * symbol * -1), casterPos.y + b))
                    self:ValidPosInsertList(leftScopeList, Vector2(casterPos.x + b, casterPos.y + (symbol * a)))
                    self:ValidPosInsertList(rightScopeList, Vector2(casterPos.x + b, casterPos.y + (symbol * -1 * a)))
                end
                if dirType == DirectionType.Up or dirType == DirectionType.Down then
                    self:ValidPosInsertList(downScopeList, Vector2(casterPos.x + b, casterPos.y + a * symbol))
                    self:ValidPosInsertList(leftScopeList, Vector2(casterPos.x + (symbol * a), casterPos.y + b))
                    self:ValidPosInsertList(rightScopeList, Vector2(casterPos.x + (symbol * a * -1), casterPos.y + b))
                end
            end
        end
    end

    return leftScopeList, rightScopeList, downScopeList
end

function UtilScopeCalcServiceShare:GetNightKingCounterAttackSwitchBodyAreaDirType(casterEntity, casterPos, targetEntity)
    ---@type Vector2[]
    local leftScopeList, rightScopeList, downScopeList = self:GetNightKingCounterAttackScope(casterEntity, casterPos)
    ---@type Vector2
    local targetPos = targetEntity:GetGridPosition()
    if table.Vector2Include(leftScopeList, targetPos) then
        return SwitchBodyAreaDirType.Left
    elseif table.Vector2Include(rightScopeList, targetPos) then
        return SwitchBodyAreaDirType.Right
    elseif table.Vector2Include(downScopeList, targetPos) then
        return SwitchBodyAreaDirType.Turn
    else
        return SwitchBodyAreaDirType.None
    end
end

---@param targetEntity Entity
---@param casterEntity Entity
---@param casterPos Vector2
---@return SwitchBodyAreaDirType
function UtilScopeCalcServiceShare:GetNightKingTailFlickSwitchBodyAreaDirType(casterEntity, casterPos, targetEntity)
    ---@type Vector2[],Vector2[]
    local leftScopeList, rightScopeList = self:GetNightKing_SkillCScope(casterEntity, casterPos)
    ---@type Vector2
    local targetPos = targetEntity:GetGridPosition()

    if table.Vector2Include(leftScopeList, targetPos) then
        return SwitchBodyAreaDirType.Left
    elseif table.Vector2Include(rightScopeList, targetPos) then
        return SwitchBodyAreaDirType.Right
    else
        return SwitchBodyAreaDirType.Turn
    end
end

---根据施法者的当前方向和旋转类型，获得一个新的方向,获得一个新的bodyArea偏移,只支持两格怪
----@param switchDirType SwitchBodyAreaDirType 旋转的类型
---@param casterDirType DirectionType 施法者的当前方向
function UtilScopeCalcServiceShare:GetNewDirBySwitchDirType(switchDirType, casterDirType)
    ---@type Vector2
    local newDir
    ---@type Vector2
    local newBodyArea
    if casterDirType == DirectionType.Up then
        if switchDirType == SwitchBodyAreaDirType.Right then
            newDir = Vector2(1, 0)
            newBodyArea = Vector2(-1, 0)
        elseif switchDirType == SwitchBodyAreaDirType.Left then
            newDir = Vector2(-1, 0)
            newBodyArea = Vector2(1, 0)
        elseif switchDirType == SwitchBodyAreaDirType.Turn then
            newDir = Vector2(0, -1)
            newBodyArea = Vector2(0, 1)
        end
    elseif casterDirType == DirectionType.Down then
        if switchDirType == SwitchBodyAreaDirType.Right then
            newDir = Vector2(-1, 0)
            newBodyArea = Vector2(1, 0)
        elseif switchDirType == SwitchBodyAreaDirType.Left then
            newDir = Vector2(1, 0)
            newBodyArea = Vector2(-1, 0)
        elseif switchDirType == SwitchBodyAreaDirType.Turn then
            newDir = Vector2(0, 1)
            newBodyArea = Vector2(0, -1)
        end
    elseif casterDirType == DirectionType.Left then
        if switchDirType == SwitchBodyAreaDirType.Right then
            newDir = Vector2(0, 1)
            newBodyArea = Vector2(0, -1)
        elseif switchDirType == SwitchBodyAreaDirType.Left then
            newDir = Vector2(0, -1)
            newBodyArea = Vector2(0, 1)
        elseif switchDirType == SwitchBodyAreaDirType.Turn then
            newDir = Vector2(1, 0)
            newBodyArea = Vector2(-1, 0)
        end
    elseif casterDirType == DirectionType.Right then
        if switchDirType == SwitchBodyAreaDirType.Right then
            newDir = Vector2(0, -1)
            newBodyArea = Vector2(0, 1)
        elseif switchDirType == SwitchBodyAreaDirType.Left then
            newDir = Vector2(0, 1)
            newBodyArea = Vector2(0, -1)
        elseif switchDirType == SwitchBodyAreaDirType.Turn then
            newDir = Vector2(-1, 0)
            newBodyArea = Vector2(1, 0)
        end
    end
    Log.fatal("SwitchType:", switchDirType, "DirType:", casterDirType, "NewDir:", newDir, "NewBodyArea:", newBodyArea)
    return newDir, { Vector2(0, 0), newBodyArea }
end

----@param casterEntity Entity
---@param casterPos Vector2
function UtilScopeCalcServiceShare:GetNightKingForwardSkillPos(casterEntity, casterPos)
    ---@type DirectionType
    local dirType = self:GetEntityDirType(casterEntity)
    local leftPos, rightPos
    if dirType == DirectionType.Up then
        leftPos = Vector2(casterPos.x - 1, casterPos.y + 2)
        rightPos = Vector2(casterPos.x + 1, casterPos.y + 2)
    elseif dirType == DirectionType.Down then
        leftPos = Vector2(casterPos.x + 1, casterPos.y - 2)
        rightPos = Vector2(casterPos.x - 1, casterPos.y - 2)
    elseif dirType == DirectionType.Left then
        leftPos = Vector2(casterPos.x - 2, casterPos.y - 1)
        rightPos = Vector2(casterPos.x - 2, casterPos.y + 1)
    elseif dirType == DirectionType.Right then
        leftPos = Vector2(casterPos.x + 2, casterPos.y + 1)
        rightPos = Vector2(casterPos.x + 2, casterPos.y - 1)
    end
    return leftPos, rightPos
end

---夜王设置新方向后位置
---@param casterEntity Entity
---@param dirType DirectionType
----@return Vector2
function UtilScopeCalcServiceShare:GetNewBodyAreaByDirType(dirType)
    local bodyArea
    if dirType == DirectionType.Up then
        bodyArea = Vector2(0, -1)
    elseif dirType == DirectionType.Left then
        bodyArea = Vector2(1, 0)
    elseif dirType == DirectionType.Down then
        bodyArea = Vector2(0, 1)
    elseif dirType == DirectionType.Right then
        bodyArea = Vector2(-1, 0)
    end
    return bodyArea
end

---夜王设置新方向后位置是否合法
---@param casterEntity Entity
---@param dirType DirectionType
function UtilScopeCalcServiceShare:IsNewBodyAreaPosValidByDirType(casterPos, dirType)
    local bodyAreaPos = casterPos + self:GetNewBodyAreaByDirType(dirType)
    return not self:IsPosBlock(bodyAreaPos, BlockFlag.MonsterLand)
end

function UtilScopeCalcServiceShare:GetCurBoardMaxX()
    ---@type BoardServiceLogic
    local svc = self._world:GetService("BoardLogic")
    return svc:GetCurBoardMaxX()
end

function UtilScopeCalcServiceShare:GetCurBoardMaxY()
    ---@type BoardServiceLogic
    local svc = self._world:GetService("BoardLogic")
    return svc:GetCurBoardMaxY()
end

function UtilScopeCalcServiceShare:GetMinMaxGridXByGridY(y)
    ---@type BoardComponent
    local cBoard = self._world:GetBoardEntity():Board()
    return cBoard:GetMinMaxGridXByGridY(y)
end

function UtilScopeCalcServiceShare:GetMinMaxGridYByGridX(x)
    ---@type BoardComponent
    local cBoard = self._world:GetBoardEntity():Board()
    return cBoard:GetMinMaxGridYByGridX(x)
end

function UtilScopeCalcServiceShare:GetGridPossessedByTrapType(trapType)
    local tv2Grids = {}
    local globalTrapEntities = self._world:GetGroupEntities(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(globalTrapEntities) do
        if not e:HasDeadMark() then
            local cTrap = e:Trap()
            if cTrap:GetTrapType() == trapType then
                local bodyArea = e:BodyArea():GetArea()
                local v2GridPos = e:GetGridPosition()
                for _, v2Body in ipairs(bodyArea) do
                    table.insert(tv2Grids, v2GridPos + v2Body)
                end
            end
        end
    end

    return tv2Grids
end

function UtilScopeCalcServiceShare:IsPosHasTrapByTrapID(pos, trapID)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    return utilData:IsPosHasTrapByTrapID(pos, trapID)
end

--region SkillEffectType.MonsterMoveGridToSkillRangeFar
---@return Vector2[]
function UtilScopeCalcServiceShare:MonsterGetPosAroundSameTypePosList(pos, pieceType)
    local ret = {}
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local boardSvc = self._world:GetService("BoardLogic")
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()
    for x = -1, 1 do
        for y = -1, 1 do
            local newPos = Vector2(pos.x + x, pos.y + y)
            if (newPos.x ~= pos.x or newPos.y ~= pos.y) then
                ---需要是一个可连通的格子才行
                if utilDataSvc:IsValidPiecePos(newPos) and
                    --not boardSvc:IsPosBlock(newPos, BlockFlag.LinkLine) and
                    not boardSvc:IsPosBlock(newPos, BlockFlag.MonsterLand) and
                    not utilDataSvc:IsPosHasSpTrap(newPos, TrapType.BadGrid)
                then
                    local type = board:GetPieceType(newPos)
                    if type == pieceType or type == PieceType.Any then
                        ---Log.fatal("MonsterGetPosAroundSameTypePosList NewPos:", tostring(newPos),"NewType:",type,"SourcePos:", tostring(pos),"SourceType:",pieceType)
                        table.insert(ret, newPos)
                    end
                end
            end
        end
    end
    return ret
end

--endregion SkillEffectType.MonsterMoveGridToSkillRangeFar

function UtilScopeCalcServiceShare:GetStandardDirection8D(v2)
    local v = v2:Clone()
    if v.x > 0 then
        v.x = 1
    elseif v.x < 0 then
        v.x = -1
    end

    if v.y > 0 then
        v.y = 1
    elseif v.y < 0 then
        v.y = -1
    end

    return v
end

function UtilScopeCalcServiceShare:IsPosCanConvertGridElement(pos)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    return boardServiceLogic:GetCanConvertGridElement(pos)
end

---@return table<number,Vector2[]>,DirectionType
function UtilScopeCalcServiceShare:CalcRangeByPickUpPosList(pickUpPosList)
    if  #pickUpPosList <2 then
        return nil
    end
    ---@type Vector2
    local centerPos = pickUpPosList[1]
    ---@type Vector2
    local dirPos =  pickUpPosList[2]
    local dirType
    local step  = 1
    local max,reverseMax
    if centerPos.x ~= dirPos.x then
        max=self:GetCurBoardMaxX()
        reverseMax = self:GetCurBoardMaxY()
        if centerPos.x>dirPos.x then
            dirType = DirectionType.Left
            step =-1
        elseif centerPos.x<dirPos.x then
            dirType = DirectionType.Right
        end
    elseif centerPos.y ~= dirPos.y then
        max=self:GetCurBoardMaxY()
        reverseMax = self:GetCurBoardMaxX()
        if centerPos.y>dirPos.y then
            dirType = DirectionType.Down
            step = -1
        elseif centerPos.y<dirPos.y then
            dirType = DirectionType.Up
        end
    end
    local ret={}
    local edgeBegin ={}
    local invalidPos = {}
    local totalRange = {}
    for i=0,max do
        --ret[i]={}
        for j=1,reverseMax do
            local pos,prePos
            if dirType == DirectionType.Left or dirType == DirectionType.Right then
                pos = Vector2(centerPos.x+i*step,j)
                prePos = Vector2(centerPos.x+(i-1)*step,j)

            elseif dirType == DirectionType.Up or dirType == DirectionType.Down then
                pos = Vector2(j, centerPos.y+i*step)
                prePos = Vector2(j, centerPos.y+i*step)
            end
            if self:IsValidPiecePos(pos) then
                if i == 0 then
                    table.insert(edgeBegin, pos)
                end
                table.insert(totalRange, pos)
            end
            if self:IsValidPiecePos(pos) ~= PieceType.None and self:IsValidPiecePos(pos) ~= nil and
                self:IsPosCanConvertGridElement(pos) then
                table.insert(ret, pos)

                if self:IsValidPiecePos(prePos) ==nil then
                    if i ~= 0 then
                        table.insert(invalidPos, pos)
                    end
                end
            end
        end
    end

    return ret,dirType,edgeBegin,invalidPos,totalRange
end

function UtilScopeCalcServiceShare:CalcRangeByTrapCenter(param,centerPos,
                                                         bodyArea, casterDir, nTargetType,casterPos,casterEntity)
    local tarpID = param[1]
    local scopeType =  param[2]
    ---@type TrapServiceLogic
    local trapServerLogic = self._world:GetService("TrapLogic")
    ---@type Vector2[]
    local centerPosList = trapServerLogic:FindTrapPosByTrapID(tarpID,false)

    ---@type SkillScopeCalculator
    local  calc = SkillScopeCalculator:New(self)
    if table.count(centerPosList) == 0 then
        return SkillScopeResult:New(SkillScopeType.TrapCenterWithScope, casterPos, {}, {})
    end
    local scpoe_param = {}
    if table.count(param) >=3 then
        scpoe_param = table.sub(param,3,#param)
    end
    local attackRange,wholeRange = {},{}

    for _, pos in ipairs(centerPosList) do
        local result = calc:ComputeScopeRange(scopeType, scpoe_param,pos,bodyArea,casterDir,nTargetType,casterPos,casterEntity)

        table.Vector2Append(attackRange,result:GetAttackRange(),attackRange)
        table.Vector2Append(wholeRange,result:GetWholeGridRange(),wholeRange)
    end
    local result = SkillScopeResult:New(SkillScopeType.TrapsCenterWithScope, casterPos, attackRange, wholeRange)
    return result
end

---@param dirType DirectionType
function UtilScopeCalcServiceShare:Monster2903501FindPlayer(dirType,casterPos,bodyArea)
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")

    local boardMaxX = boardServiceLogic:GetCurBoardMaxX()
    local boardMaxY = boardServiceLogic:GetCurBoardMaxY()
    local maxLen,edgeLen
    ---@type Vector2[]
    local retRange={}
    local off =1
    if dirType == DirectionType.Up or dirType == DirectionType.Down then
        maxLen = boardMaxY
        edgeLen = boardMaxX
        if dirType == DirectionType.Down then
            off = -1
        end
    elseif  dirType == DirectionType.Left or dirType == DirectionType.Right then
        maxLen = boardMaxX
        edgeLen = boardMaxY
        if dirType == DirectionType.Left then
            off = -1
        end
    end
    local bodyAreaOffSet = {}
    for _, v in ipairs(bodyArea) do
        local offset = Vector2(v.x+casterPos.x,v.y+casterPos.y)
        table.insert(bodyAreaOffSet,offset)
    end
    local j = 0
    for i=2,maxLen,2 do
        for _, v in ipairs(bodyAreaOffSet) do
            local newPos
            if  dirType == DirectionType.Up or dirType == DirectionType.Down then
                newPos = Vector2(v.x,v.y+i*off)
            elseif  dirType == DirectionType.Left or dirType == DirectionType.Right then
                newPos = Vector2(v.x+i*off,v.y)
            end
            if boardServiceLogic:IsValidPiecePos(newPos) and  not table.Vector2Include(retRange,newPos) then
                --Log.fatal("InsertPos:",newPos," DirType:",dirType)
                table.insert(retRange,newPos)
            end
        end
        for o = -1 * j, j do
            for _, v in ipairs(bodyAreaOffSet) do
                local newPos
                if dirType == DirectionType.Up or dirType == DirectionType.Down then
                    newPos = Vector2(v.x + o, v.y + i * off)
                elseif dirType == DirectionType.Left or dirType == DirectionType.Right then
                    newPos = Vector2(v.x + i * off, v.y + o)
                end
                if boardServiceLogic:IsValidPiecePos(newPos) and not table.Vector2Include(retRange, newPos) then
                    table.insert(retRange, newPos)
                end
            end
        end
        j= j+1
    end
    return retRange
end


--region 两点间连线-策划公式算法
--[[
    策划公式算法：最早由46号范围的提出者提供
    令起始点为(0, 0)【也就是相对坐标】，此时终点为(a, b)，则直线公式bX - aY = 0
    宽度控制为abs(bx - ay) / roof((a^2+b^2)) < widthThreshold => abs(bx - ay) < (widthThreshold * root(a^2 + b^2))
    其中widthThreshold为配置参数

    所有符合该公式的格子都是有效范围（所以为啥不是直接给一个基于插值的算法）
]]

function UtilScopeCalcServiceShare:P2PAngleFreeLineRange(pos1, pos2, attackRange, wholeRange, bNoExtend, widthThreshold)
    --版面参数
    local pieceXYMap = self._world:GetService("BoardLogic").GridTiles

    local posOnLine = {}

    --region 计算步骤1：计算连线本身
    -- 起始点到终点公式为：令起始点为(0, 0)【也就是相对坐标】，此时终点为(a, b)，则直线公式bX - aY = 0
    -- 此处简化为bX = aY 如果打算使用数学方式的话，Y = (b / a)X，当心这里有一个除法操作
    local casterX = pos1.x
    local casterY = pos1.y

    local pickupDistance = Vector2.Distance(pos2, pos1)
    local relativePickupPos = pos2 - pos1
    local relativePickupX = relativePickupPos.x
    local relativePickupY = relativePickupPos.y

    local a = relativePickupPos.x
    local b = relativePickupPos.y

    for x, tableY in pairs(pieceXYMap) do
        local relativeX = x - casterX

        for y, _ in pairs(tableY) do
            local relativeY = y - casterY

            local v2 = Vector2(x, y)
            -- emmylua的缩进比较奇怪，这里直接用and的方式让代码形状别太奇怪
            local isPosValid = (b * relativeX) == (a * relativeY) -- 符合公式
            isPosValid = isPosValid and ((relativeX * relativePickupX >= 0) and (relativeY * relativePickupY >= 0)) -- 在起始点->终点方向内
            isPosValid = isPosValid and ((not bNoExtend) or Vector2.Distance(v2, pos1) <= pickupDistance) -- 连线是否延申，可选功能
            if isPosValid then
                if not table.icontains(attackRange, v2) then
                    table.insert(attackRange, v2)
                end
                if not table.icontains(wholeRange, v2) then
                    table.insert(wholeRange, v2)
                end
                if not table.icontains(posOnLine, v2) then
                    table.insert(posOnLine, v2)
                end
            end
        end
    end
    --endregion

    --region 计算步骤2：宽度计算
    for _, linePos in ipairs(posOnLine) do
        local disThreshold = Vector2.Distance(linePos, pos1) + widthThreshold
        local relativeLinePos = pos1 - linePos
        local a = relativeLinePos.x
        local b = relativeLinePos.y
        local sqrtLinePos = math.sqrt((a * a) + (b * b))
        local sqrt = sqrtLinePos * widthThreshold

        for x, tableY in pairs(pieceXYMap) do
            local relativeX = casterX - x
            for y, _ in pairs(tableY) do
                local relativeY = casterY - y
                local v2 = Vector2(x, y)
                -- emmylua的缩进比较奇怪，这里直接用and的方式让代码形状别太奇怪
                local isPosValid = (math.abs(b * relativeX - a * relativeY)) < sqrt  -- 符合公式
                isPosValid = isPosValid and (relativeX * a >= 0) and (relativeY * b >= 0) -- 在起始点->终点方向内
                isPosValid = isPosValid and ((not bNoExtend) or (Vector2.Distance(v2, pos1) < disThreshold)) --是否延申，可选功能
                if isPosValid then
                    if not table.Vector2Include(attackRange, v2) then
                        table.insert(attackRange, v2)
                    end
                    if not table.Vector2Include(wholeRange, v2) then
                        table.insert(wholeRange, v2)
                    end
                end
            end
        end
    end
    --endregion
end

--endregion

--按照与Pos距离对(指定id)Trap排序
---@param target_pos Vector2
---@return table table = {dis=number,trap_e=Entity,pos=Vector2}
function UtilScopeCalcServiceShare:SortTrapsByPos(checkIDList,target_pos, nearestForMultiGrid)
    local trap_group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
    local trapIDList = {}
    for _, e in ipairs(trap_group:GetEntities()) do
        local trapID = e:TrapID():GetTrapID()
        if checkIDList then
            if table.icontains(checkIDList,trapID) then
                table.insert(trapIDList, e:GetID())
            end
        else
            table.insert(trapIDList, e:GetID())
        end
    end
    return self:SortTrapsListByPos(target_pos, trapIDList, nearestForMultiGrid)
end
function UtilScopeCalcServiceShare:SortTrapsListByPos(target_pos, trapIDList, nearestForMultiGrid)
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local distance_trap = {}
    for _, entityID in ipairs(trapIDList) do
        ---@type Entity
        local e = self._world:GetEntityByID(entityID)
        local position = e:GridLocation().Position
        if utilData:IsValidPiecePos(position) then
            if nearestForMultiGrid then
                local pos = position
                local distance = Vector2.Distance(pos, target_pos)
                local tBodyArea = e:BodyArea():GetArea()
                for _, v2RelativeBody in ipairs(tBodyArea) do
                    local v2 = v2RelativeBody + position
                    local newDis = Vector2.Distance(v2, target_pos)
                    if distance > newDis then
                        distance = newDis
                        pos = v2
                    end
                end
                table.insert(distance_trap, { dis = distance, trap_e = e, pos = pos })
            else
                local distance = Vector2.Distance(position, target_pos)
                table.insert(distance_trap, { dis = distance, trap_e = e, pos = position })
            end
        end
    end

    local function get_index(c, p)
        if p.x - c.x == 0 and p.y - c.y > 0 then
            return 1
        end
        if p.x - c.x > 0 and p.y - c.y > 0 then
            return 2
        end
        if p.x - c.x > 0 and p.y - c.y == 0 then
            return 3
        end
        if p.x - c.x > 0 and p.y - c.y < 0 then
            return 4
        end
        if p.x - c.x == 0 and p.y - c.y < 0 then
            return 5
        end
        if p.x - c.x < 0 and p.y - c.y < 0 then
            return 6
        end
        if p.x - c.x < 0 and p.y - c.y == 0 then
            return 7
        end
        if p.x - c.x < 0 and p.y - c.y > 0 then
            return 8
        end
        return 1
    end

    local function cmp_fun(ele1, ele2)
        if ele1.dis == ele2.dis then
            return get_index(target_pos, ele1.pos) < get_index(target_pos, ele2.pos)
        else
            return ele1.dis < ele2.dis
        end
    end

    table.sort(distance_trap, cmp_fun)
    return distance_trap
end

---以释放者的坐标为原点 找到离它最近的limit个机关（可以指定机关id列表） 返回机关和机关的坐标
---暂时逻辑是 当两个机关距离相同时 随机取一个
---@param caster_pos Vector2
---@param limit number
---@return table<number,Entity>,table<number,Vector2>
function UtilScopeCalcServiceShare:SelectNearestTrapsOnPos(checkIDList, caster_pos, limit)
    if limit == -1 then
        local trap_group = self._world:GetGroup(self._world.BW_WEMatchers.TrapID)
        limit = #trap_group:GetEntities()
    end
    ---@type table<number,Entity>
    local traps = {}
    local trapIDs = {}
    ---@type table<number,Vector2>
    local traps_pos = {}
    ---@type table table = {dis=number,trap_e=Entity,pos=Vector2}
    local distance_trap = self:SortTrapsByPos(checkIDList,caster_pos,true)

    ---@type SkillScopeTargetSelector
    local skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()

    for _, element in ipairs(distance_trap) do
        ---@type Entity
        local trapEntity = element.trap_e
        --local curHP = trapEntity:Attributes():GetCurrentHP()
        if #traps < limit and not trapEntity:HasDeadMark() and 
            -- curHP > 0 and
            skillScopeTargetSelector:SelectConditionFilter(trapEntity)
        then
            table.insert(traps, element.trap_e)
            table.insert(trapIDs, element.trap_e:GetID())
            table.insert(traps_pos, element.pos)
        end
    end
    return traps, traps_pos,trapIDs
end

---点选的怪物身形中离施法者最近的点
---@param casterPos Vector2
---@return Vector2
function UtilScopeCalcServiceShare:GetNearestPosToCasterInPickMonster()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关释放的点选主动技，petPstID=-1，entityID有值
    end

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local pickPos = activeSkillPickUpComponent:GetLastPickUpGridPos()
            local gridPosList = {pickPos}
            ---技能目标选择器
            ---@type SkillScopeTargetSelector
            local targetSelector = self._world:GetSkillScopeTargetSelector()
            local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, pickPos, gridPosList, gridPosList)
            local targetEntityIDList = targetSelector:DoSelectSkillTarget(casterEntity, SkillTargetType.Monster, skillScopeResult)
            if #targetEntityIDList > 0 then
                local targetID = targetEntityIDList[1]
                local monsterEntity = self._world:GetEntityByID(targetID)
                if monsterEntity then
                    local area = monsterEntity:BodyArea():GetArea()
                    local monsterPos = monsterEntity:GetGridPosition()
                    local posList = {}
                    for _, posArea in ipairs(area) do
                        local pos = monsterPos + posArea
                        table.insert(posList, pos)
                    end
                    local casterPos = casterEntity:GetGridPosition()
                    local nearestPos = nil
                    local nearestDis = -1
                    for index, checkPos in ipairs(posList) do
                        local dis = math.abs(checkPos.x - casterPos.x) + math.abs(checkPos.y - casterPos.y)
                        if (nearestDis < 0) or (dis < nearestDis) then
                            nearestDis = dis
                            nearestPos = checkPos
                        end
                    end
                    if nearestPos then
                        return nearestPos
                    end
                end
            end
        end
    end
end
function UtilScopeCalcServiceShare:PreviewGetNearestPosToCasterInPickMonster(casterEntity)
    if casterEntity then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            local pickPos = previewPickUpComponent:GetLastPickUpGridPos()
            local gridPosList = {pickPos}
            ---技能目标选择器
            ---@type SkillScopeTargetSelector
            local targetSelector = self._world:GetSkillScopeTargetSelector()
            local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, pickPos, gridPosList, gridPosList)
            local targetEntityIDList = targetSelector:DoSelectSkillTarget(casterEntity, SkillTargetType.Monster, skillScopeResult)
            if #targetEntityIDList > 0 then
                local targetID = targetEntityIDList[1]
                local monsterEntity = self._world:GetEntityByID(targetID)
                if monsterEntity then
                    local area = monsterEntity:BodyArea():GetArea()
                    local monsterPos = monsterEntity:GetGridPosition()
                    local posList = {}
                    for _, posArea in ipairs(area) do
                        local pos = monsterPos + posArea
                        table.insert(posList, pos)
                    end
                    local casterPos = casterEntity:GetGridPosition()
                    local nearestPos = nil
                    local nearestDis = -1
                    for index, checkPos in ipairs(posList) do
                        local dis = math.abs(checkPos.x - casterPos.x) + math.abs(checkPos.y - casterPos.y)
                        if (nearestDis < 0) or (dis < nearestDis) then
                            nearestDis = dis
                            nearestPos = checkPos
                        end
                    end
                    if nearestPos then
                        return nearestPos
                    end
                end
            end
        end
    end
end
-----
function UtilScopeCalcServiceShare:GetPickUpMonsterPosCenterPos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关释放的点选主动技，petPstID=-1，entityID有值
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local pickPosList = activeSkillPickUpComponent:GetAllValidPickUpGridPos()
            if #pickPosList == 1 then
                local firstCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPosList[1])
                if firstCenterPos then
                    return {firstCenterPos}
                end
            elseif #pickPosList > 1 then
                local centerPos = {}
                for index, pickPos in ipairs(pickPosList) do
                    local pickMonsterCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPos)
                    if pickMonsterCenterPos then
                        table.insert(centerPos,pickMonsterCenterPos)
                    end
                end
                return centerPos
            end
        end
    end
end

-----
function UtilScopeCalcServiceShare:PreviewGetPickUpMonsterPosCenterPos(casterEntity)
    if casterEntity then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            local pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
            if #pickPosList == 1 then
                local firstCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPosList[1])
                if firstCenterPos then
                    return {firstCenterPos}
                end
            elseif #pickPosList > 1 then
                local centerPos = {}
                for index, pickPos in ipairs(pickPosList) do
                    local pickMonsterCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPos)
                    if pickMonsterCenterPos then
                        table.insert(centerPos,pickMonsterCenterPos)
                    end
                end
                return centerPos
            end
        end
    end
end
-----
function UtilScopeCalcServiceShare:GetPickUpMonsterPosAndCasterPosCenterPos()
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()
    ---@type LogicPickUpComponent
    local logicPickUpCmpt = teamEntity:LogicPickUp()
    local petPstID = logicPickUpCmpt:GetLogicPetPstid()
    local entityID = logicPickUpCmpt:GetEntityID()

    if entityID == -1 then
        --星灵施法主动技，entityID=-1，petPstID有值
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        entityID = utilDataSvc:GetEntityIDByPstID(petPstID)
    else
        --机关释放的点选主动技，petPstID=-1，entityID有值
    end
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    local petEntityId = utilDataSvc:GetEntityIDByPstID(petPstID)

    local casterEntity = self._world:GetEntityByID(entityID)
    if casterEntity then
        ---@type ActiveSkillPickUpComponent
        local activeSkillPickUpComponent = casterEntity:ActiveSkillPickUpComponent()
        if activeSkillPickUpComponent then
            local pickPosList = activeSkillPickUpComponent:GetAllValidPickUpGridPos()
            if #pickPosList == 1 then
                local firstCenterPos = casterEntity:GetGridPosition()
                local secondCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPosList[1])
                if firstCenterPos and secondCenterPos then
                    return {firstCenterPos,secondCenterPos}
                end
            elseif #pickPosList > 1 then
                local centerPos = {}
                for index, pickPos in ipairs(pickPosList) do
                    local pickMonsterCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPos)
                    if pickMonsterCenterPos then
                        table.insert(centerPos,pickMonsterCenterPos)
                    end
                end
                return centerPos
            end
        end
    end
end

-----
function UtilScopeCalcServiceShare:PreviewGetPickUpMonsterPosAndCasterPosCenterPos(casterEntity)
    if casterEntity then
        ---@type PreviewPickUpComponent
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        if previewPickUpComponent then
            local pickPosList = previewPickUpComponent:GetAllValidPickUpGridPos()
            if #pickPosList == 1 then
                local firstCenterPos = casterEntity:GetGridPosition()
                local secondCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPosList[1])
                if firstCenterPos and secondCenterPos then
                    return {firstCenterPos,secondCenterPos}
                end
            elseif #pickPosList > 1 then
                local centerPos = {}
                for index, pickPos in ipairs(pickPosList) do
                    local pickMonsterCenterPos = self:_GetPickUpMonsterPos(casterEntity,pickPos)
                    if pickMonsterCenterPos then
                        table.insert(centerPos,pickMonsterCenterPos)
                    end
                end
                return centerPos
            end
        end
    end
end

function UtilScopeCalcServiceShare:_GetPickUpMonsterPos(casterEntity,pickPos)
    local gridPosList = {pickPos}
    ---技能目标选择器
    ---@type SkillScopeTargetSelector
    local targetSelector = self._world:GetSkillScopeTargetSelector()
    local skillScopeResult = SkillScopeResult:New(SkillScopeType.None, pickPos, gridPosList, gridPosList)
    local targetEntityIDList = targetSelector:DoSelectSkillTarget(casterEntity, SkillTargetType.Monster, skillScopeResult)
    if #targetEntityIDList > 0 then
        local targetID = targetEntityIDList[1]
        local monsterEntity = self._world:GetEntityByID(targetID)
        if monsterEntity then
            local monsterPos = monsterEntity:GetGridPosition()
            return monsterPos
        end
    end
end

function UtilScopeCalcServiceShare:SortScopeRangeWithDir(scopeRange, dir)
    if not scopeRange or table.count(scopeRange) == 0 then
        return
    end

    table.sort(
        scopeRange,
        function(a, b)
            if dir == Vector2(0, -1) then
                if a.y == b.y then
                    return a.x < b.x
                end
                return a.y > b.y
            elseif dir == Vector2(0, 1) then
                if a.y == b.y then
                    return a.x < b.x
                end
                return a.y < b.y
            elseif dir == Vector2(-1, 0) then
                if a.x == b.x then
                    return a.y < b.y
                end
                return a.x < b.x
            elseif dir == Vector2(-1, 0) then
                if a.x == b.x then
                    return a.y < b.y
                end
                return a.x > b.x
            end
        end
    )
    return scopeRange
end
