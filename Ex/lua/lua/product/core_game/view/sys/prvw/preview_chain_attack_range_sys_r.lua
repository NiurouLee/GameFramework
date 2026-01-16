--[[----------------------------------------------------------
    渲染连锁技攻击范围system
]] ------------------------------------------------------------
---@class PreviewChainAttackRangeSystem_Render:ReactiveSystem
_class("PreviewChainAttackRangeSystem_Render", ReactiveSystem)
PreviewChainAttackRangeSystem_Render = PreviewChainAttackRangeSystem_Render

---@param world World
function PreviewChainAttackRangeSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type ConfigService
    self._configService = world:GetService("Config")
end

---@param world World
function PreviewChainAttackRangeSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.PreviewChainPath)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PreviewChainAttackRangeSystem_Render:Filter(entity)
    ---@type AutoFightService
    local autoSvc = self._world:GetService("AutoFight")
    if autoSvc:IsRunning() then 
        return false
    end

    ---战棋模式下也不需要连锁技范围
    if self._world:MatchType() == MatchType.MT_Chess then 
        return false
    end

    return entity:HasPreviewChainPath() 
end

function PreviewChainAttackRangeSystem_Render:ExecuteEntities(entities)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type PreviewChainSkillRangeComponent
    self.previewChainSkillRangeCmpt = reBoard:PreviewChainSkillRange()

    --先删掉连锁技范围entity
    self:_DestroyChainSkillRange()

    ---@type ChainSkillRangeOutlineEntityDic
    self.chainSkillRangeDic = self.previewChainSkillRangeCmpt:GetChainSkillRangeOutlineDic()

    ---@type ChainPreviewMonsterBehaviorComponent
    self.chainPreviewMonsterBehaviorCmpt = reBoard:ChainPreviewMonsterBehavior()

    for i = 1, #entities do
        self:_RenderChainAttackRange(entities[i])
    end
end

local OutlineDirType = {Up = 1, Down = 2, Left = 3, Right = 4, LeftUp = 5, RightUp = 6, RightDown = 7, LeftDown = 8}
local OutlineType = {Short = 1, LeftShort = 2, RightShort = 3, Long = 4}

---@param previewEntity Entity
function PreviewChainAttackRangeSystem_Render:_RenderChainAttackRange(previewEntity)
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    if chainPath == nil then
        return
    end

    local chainPathNum = #chainPath
    local lastChainPathPoint = chainPath[chainPathNum]

    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()

    ---@type PreviewChainSelectPetComponent
    local selectPetCmpt = previewEntity:PreviewChainSelectPet()
    local petIDList = selectPetCmpt:GetRenderPetList()

    local previewIndex = 0
    local previewPstIDAndSkill = {}
    for _, petEntityID in ipairs(petIDList) do
        local petEntity = self._world:GetEntityByID(petEntityID)

        local chainSkillID = selectPetCmpt:GetPreviewChainSelectPetSkillID(petEntityID)
        ---@type SkillTargetSelectionMode
        local skillSelectMode, preViewType, scopeType = self:_GetSkillPreviewMode(chainSkillID)
        ---@type SkillScopeResult
        local scopeResult = selectPetCmpt:GetPreviewChainSelectPetScopeResult(petEntityID)

        ---@type UtilDataServiceShare
        local utilSvc = self._world:GetService("UtilData")
        ---@type PieceType
        local outlinePieceType = utilSvc:GetEntityElementType(petEntity)

        local atkRange = scopeResult:GetAttackRange()
        if atkRange then
            local hasTarget = true
            previewIndex = previewIndex + 1
            self.previewChainSkillRangeCmpt:AddChainSkillAttackElementType(previewIndex, outlinePieceType)
            --Log.fatal("PetTID:",petEntity:PetPstID():GetTemplateID(),"Index:",previewIndex)
            if preViewType ~= SkillPreviewType.AddHPChainSkill then
                if
                    preViewType == SkillPreviewType.ScopeSingleChainSkill or
                        ----策划配置了错误的技能范围和表现范围然后并不想改 只能特化一个
                        (preViewType == SkillPreviewType.ScopeSingleChainSkillInScope54 and
                            scopeType == SkillScopeType.NearestInSquareRing)
                 then
                    local allTargetIDs = scopeResult:GetTargetIDs()
                    if next(allTargetIDs) then
                        self:_CreateSingleEntitySnipeEffect(previewIndex, allTargetIDs)
                        self.chainSkillRangeDic:AddPetChainSkillOutlineRange(previewIndex)
                        self:_CreateOutlineRangeEntity(
                            scopeResult:GetAttackRange(),
                            PieceType.None,
                            previewIndex,
                            lastChainPathPoint,
                            scopeResult:GetCenterPos()
                        )
                        self:_AddPetPreviewTypeByPreviewIndex(previewIndex, PreviewChainSkillType.RangeAndSingleEntity)
                        table.insert(previewPstIDAndSkill, {
                            pstID = petEntity:PetPstID():GetPstID(),
                            index = petEntity:SkillInfo():GetChainSkillLevel(chainSkillID)
                        })
                    else
                        hasTarget = false
                        --Log.fatal("ChainSkill  NoTarget Type:SingleAndScope")
                        previewIndex = previewIndex - 1
                    end
                elseif preViewType == SkillPreviewType.SkillEffect191InChain then
                    ---@type SkillConfigData 连锁技数据
                    local skillConfigData = self._configService:GetSkillConfigData(chainSkillID)
                    ---@type UtilDataServiceShare
                    local utilData = self._world:GetService("UtilData")
                    local effectArray = utilData:GetLatestEffectParamArray(petEntityID, chainSkillID)
                    local is191Found = false

                    local centerScopeResult
                    for _, effect in ipairs(effectArray) do
                        if effect:GetEffectType() == SkillEffectType.DynamicCenterDamage then
                            is191Found = true

                            local centerScopeType = effect:GetCenterScopeType()
                            local centerScopeParam = effect:GetCenterScopeParam()  -- parsed by ctor
                            ---@type UtilScopeCalcServiceShare
                            local utilScopeSvc = self._world:GetService("UtilScopeCalc")
                            ---@type SkillScopeCalculator
                            local scopeCal = SkillScopeCalculator:New(utilScopeSvc)
                            centerScopeResult = scopeCal:ComputeScopeRange(
                                    centerScopeType,
                                    centerScopeParam,
                                    lastChainPathPoint or petEntity:GetGridPosition(),
                                    petEntity:BodyArea():GetArea(),
                                    petEntity:GetGridDirection(),
                                    SkillTargetType.Monster,
                                    petEntity:GetGridPosition(),
                                    petEntity
                            )
                            break
                        end
                    end

                    if not is191Found then
                        hasTarget = false
                        previewIndex = previewIndex - 1
                    else
                        self.chainSkillRangeDic:AddPetChainSkillOutlineRange(previewIndex)
                        self:_CreateOutlineRangeEntity(
                                centerScopeResult:GetAttackRange(),
                                outlinePieceType,
                                previewIndex,
                                lastChainPathPoint,
                                centerScopeResult:GetCenterPos()
                        )
                        self:_AddPetPreviewTypeByPreviewIndex(previewIndex, PreviewChainSkillType.Range)
                        table.insert(previewPstIDAndSkill, {
                            pstID = petEntity:PetPstID():GetPstID(),
                            index = petEntity:SkillInfo():GetChainSkillLevel(chainSkillID)
                        })
                    end
                else
                    --暂时只有取最近的不画范围框
                    if skillSelectMode == SkillTargetSelectionMode.Grid then
                        self.chainSkillRangeDic:AddPetChainSkillOutlineRange(previewIndex)
                        self:_CreateOutlineRangeEntity(
                            scopeResult:GetAttackRange(),
                            outlinePieceType,
                            previewIndex,
                            lastChainPathPoint,
                            scopeResult:GetCenterPos()
                        )
                        self:_AddPetPreviewTypeByPreviewIndex(previewIndex, PreviewChainSkillType.Range)
                        table.insert(previewPstIDAndSkill, {
                            pstID = petEntity:PetPstID():GetPstID(),
                            index = petEntity:SkillInfo():GetChainSkillLevel(chainSkillID)
                        })
                    elseif skillSelectMode == SkillTargetSelectionMode.Entity then
                        local allTargetIDs = scopeResult:GetTargetIDs()
                        if next(allTargetIDs) then
                            self:_CreateSingleEntitySnipeEffect(previewIndex, allTargetIDs)
                            self:_AddPetPreviewTypeByPreviewIndex(previewIndex, PreviewChainSkillType.SingleEntity)
                            table.insert(previewPstIDAndSkill, {
                                pstID = petEntity:PetPstID():GetPstID(),
                                index = petEntity:SkillInfo():GetChainSkillLevel(chainSkillID)
                            })
                        else
                            hasTarget = false
                            --Log.fatal("ChainSkill  NoTarget Type:Single")
                            previewIndex = previewIndex - 1
                        end
                    end
                end
            else
                self:_AddAddHPPet(previewIndex, petEntity)
                self:_AddPetPreviewTypeByPreviewIndex(previewIndex, PreviewChainSkillType.AddHP)
                table.insert(previewPstIDAndSkill, {
                    pstID = petEntity:PetPstID():GetPstID(),
                    index = petEntity:SkillInfo():GetChainSkillLevel(chainSkillID)
                })
            end
            if hasTarget then
                self.previewChainSkillRangeCmpt:AddPreviewPetID(previewIndex, petEntity:GetID())
            end
        end
    end

    for _, data in ipairs(previewPstIDAndSkill) do
        local pstID = data.pstID
        local index = data.index
        self._world:EventDispatcher():Dispatch(GameEventType.UpdateBuffLayerActiveSkillEnergyPreview, {
            pstID = pstID,
            index = index,
        })
    end

    if previewIndex > 0 then
        --Log.fatal("ReSetPreviewIndex")
        self.previewChainSkillRangeCmpt:SetPreviewTypeIndex(1)
        self.previewChainSkillRangeCmpt:SetPreviewStartTime(0)
    end
    if previewIndex > 1 then
        self.previewChainSkillRangeCmpt:SetChainSkillRangeFlash(true)
    else
        --Log.fatal("PreviewIndex:",previewIndex)
        self.previewChainSkillRangeCmpt:SetChainSkillRangeFlash(false)
    end

    self.chainPreviewMonsterBehaviorCmpt:SetChainPath(chainPath)
    self.chainPreviewMonsterBehaviorCmpt:SetNeedRefresh(true)
end

function PreviewChainAttackRangeSystem_Render:_GetSkillPreviewMode(chainSkillID)
    ---@type SkillConfigData 连锁技数据
    local skillConfigData = self._configService:GetSkillConfigData(chainSkillID)
    local preViewType = skillConfigData:GetSkillPreviewType()
    local scopeType = skillConfigData:GetSkillScopeType()
    ---@type SkillScopeFilterParam
    local skillFilter = skillConfigData:GetScopeFilterParam()
    ---@type SkillTargetSelectionMode
    local skillSelectMode = skillFilter:GetTargetSelectionMode()

    return skillSelectMode, preViewType, scopeType
end

---根据连锁技范围，创建一组entity
function PreviewChainAttackRangeSystem_Render:_CreateOutlineRangeEntity(
    chainAttackGridData,
    pieceType,
    previewIndex,
    lastChainPathPoint,
    centerPos)
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")

    ---@type EntityPoolServiceRender
    local entityPoolService = self._world:GetService("EntityPool")

    local chainAttackRangeCache = {}
    for _, pos in pairs(chainAttackGridData) do
        local x = pos.x
        local t = chainAttackRangeCache[x]
        if not t then
            t = {}
            chainAttackRangeCache[pos.x] = t
        end
        t[pos.y] = true
    end

    local isContainPos = function(posList, pos)
        local t = posList[pos.x]
        if not t then
            return false
        end
        return t[pos.y] == true
    end

    ---@type TransformServiceRenderer
    local tranRenderSvc = self._world:GetService("TransformRenderer")

    ---下面是根据范围覆盖的范围画边界特效，但是很多范围默认不带技能范围中心的scopeResult:GetCenterPos()
    ---添加范围中心为了解决 MSG27758 【必现】（测试_郭简宁）连线至棋盘边界,光灵连锁技预览范围特效显示不全，附截图，log
    ---避免范围重复，添加之前先判断一下，技能范围中心scopeResult:GetCenterPos()是否在技能范围scopeResult:GetAttackRange()内
    if centerPos and centerPos._className == "Vector2" and not table.icontains(chainAttackGridData, centerPos) then
        table.insert(chainAttackGridData, centerPos)
    end

    ---遍历范围里的每一个格子
    --Log.fatal("preview chain skill,entity >>>>>>>>>>>>> :",petEntityID)
    for _, pos in pairs(chainAttackGridData) do
        --Log.fatal("chainAttackGridData >>>>>>>>>",pos.x," ",pos.y)
        ---取出某个格子位置的周边列表
        local roundPosList = boardServiceRender:GetRoundPosList(pos)
        for i = 1, #roundPosList do
            local roundPos = roundPosList[i]
            if (not isContainPos(chainAttackRangeCache, roundPos)) and roundPos ~= lastChainPathPoint then
                --Log.fatal("RoundPos ",roundPos.x," ",roundPos.y)
                ---@type Entity
                local cacheEntity = entityPoolService:GetCacheEntityByConfigID(EntityConfigIDRender.SkillRangeOutline)

                --播放动画
                ---@type SkillRangeOutlineComponent
                local skillRangeOutlineCmp = cacheEntity:SkillRangeOutline()
                skillRangeOutlineCmp:SetIsPreview(true)
                skillRangeOutlineCmp:SetPieceType(pieceType)
                tranRenderSvc:PlaySkillRangeAnim(cacheEntity)

                local outlineDir = roundPos - pos
                local outlineDirType = boardServiceRender:GetOutlineDirType(outlineDir)
                self:_SetOutlineEntityPosAndDir(pos, cacheEntity, outlineDirType, BattleConst.CacheHeight)

                self.chainSkillRangeDic:AddChainSkillRangeOutlineEntityID(previewIndex, cacheEntity:GetID())
            end
        end
    end
end

---@param outlineEntity Entity
function PreviewChainAttackRangeSystem_Render:_SetOutlineEntityPosAndDir(
    pos,
    outlineEntity,
    outlineDirType,
    renderHeight)
    local gridOutlineRadius = 0.52
    local outlinePos = pos
    local outlineDir = Vector2(0, 0)
    if outlineDirType == OutlineDirType.Up then
        outlinePos = pos + Vector2(0, gridOutlineRadius)
        outlineDir = Vector2(0, 1)
    elseif outlineDirType == OutlineDirType.Down then
        outlinePos = pos + Vector2(0, -gridOutlineRadius)
        outlineDir = Vector2(0, -1)
    elseif outlineDirType == OutlineDirType.Left then
        outlinePos = pos + Vector2(-gridOutlineRadius, 0)
        outlineDir = Vector2(-1, 0)
    elseif outlineDirType == OutlineDirType.Right then
        outlinePos = pos + Vector2(gridOutlineRadius, 0)
        outlineDir = Vector2(1, 0)
    end
    ---@type BoardServiceRender
    local boardServiceRender = self._world:GetService("BoardRender")
    local locationPos = boardServiceRender:GridPosition2LocationPos(outlinePos, outlineEntity)
    local locationDir = boardServiceRender:GridDir2LocationDir(outlineDir)
    if renderHeight then
        locationPos.y = renderHeight
    end
    ---@type LocationComponent
    local location = outlineEntity:Location()
    if location then
        location:SetPosition(locationPos)
        location:SetDirection(locationDir)
    else
        Log.fatal("### LocationComponent nil")
    end
    ---@type TransformServiceRenderer
    local tranRenderSvc = self._world:GetService("TransformRenderer")
    tranRenderSvc:SetEntityLocation(outlineEntity, locationPos, locationDir)
end

---@param previewChainSkillRangeCmpt PreviewChainSkillRangeComponent
function PreviewChainAttackRangeSystem_Render:_DestroyChainSkillRange()
    ---@type RenderBattleService
    local renderBattleService = self._world:GetService("RenderBattle")
    renderBattleService:ClearChainSkillPreviewRenderData()
end

function PreviewChainAttackRangeSystem_Render:_CreateSingleEntitySnipeEffect(preViewIndex, entityList)
    ----@type EffectService
    local effectSrv = self._world:GetService("Effect")
    for i, id in ipairs(entityList) do
        if not self.previewChainSkillRangeCmpt:HasSnipeEffect(id) then
            local entity = self._world:GetEntityByID(id)
            if entity then
                local effectEntity = effectSrv:CreateEffect(BattleConst.ChainSkillSnipeEffectID, entity, false)
                self.previewChainSkillRangeCmpt:AddSnipeEffect(id, effectEntity)
            else
                Log.fatal("_CreateSingleEntitySnipeEffect failed,holder is null")
            end
        end
        self.previewChainSkillRangeCmpt:AddChainSkillSingleEntityDic(preViewIndex, id)
    end
end

function PreviewChainAttackRangeSystem_Render:_AddAddHPPet(previewIndex, petEntity)
    self.previewChainSkillRangeCmpt:AddChainSkillAddHPPetDic(previewIndex, petEntity:GetID())
end

function PreviewChainAttackRangeSystem_Render:_AddPetPreviewTypeByPreviewIndex(previewIndex, previewType)
    self.previewChainSkillRangeCmpt:SetPreviewTypeByPreviewIndex(previewIndex, previewType)
end
