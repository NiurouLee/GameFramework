--[[----------------------------------------------------------
    SkillPreselectTargetSystem_Render 预选敌
]] ------------------------------------------------------------
---@class SkillPreselectTargetSystem_Render:ReactiveSystem
_class("SkillPreselectTargetSystem_Render", ReactiveSystem)
SkillPreselectTargetSystem_Render = SkillPreselectTargetSystem_Render

---@param world MainWorld
function SkillPreselectTargetSystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param world MainWorld
function SkillPreselectTargetSystem_Render:GetTrigger(world)
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
function SkillPreselectTargetSystem_Render:Filter(entity)
    ---@type AutoFightService
    local autoSvc = self._world:GetService("AutoFight")
    return entity:HasPreviewChainPath() and not autoSvc:IsRunning()
end

function SkillPreselectTargetSystem_Render:ExecuteEntities(entities)
    local teamEntity = self._world:Player():GetPreviewTeamEntity()
    for _, e in ipairs(entities) do
        ---@type Entity
        local entity = e
        ---@type PreviewChainPathComponent
        local chainPathCmpt = entity:PreviewChainPath()
        local path = chainPathCmpt:GetPreviewChainPath()
        local pieceType = chainPathCmpt:GetPreviewPieceType()
        local firstElementType,firstElementIndex = chainPathCmpt:GetFirstElementData()

        if path ~= nil and next(path) then
            self:_SelectPreviewChainTarget(teamEntity, pieceType,firstElementType)
        end
    end
end

---选择连锁技目标
---@param teamEntity Entity
function SkillPreselectTargetSystem_Render:_SelectPreviewChainTarget(teamEntity, pieceType,firstElementType)
    ---@type Entity
    local prvwEntity = self._world:GetPreviewEntity()

    ---先清空队列
    ---@type PreviewChainSelectPetComponent
    local selectPetCmpt = prvwEntity:PreviewChainSelectPet()
    selectPetCmpt:ClearPreviewChainSelectPet()

    --选出要出战的星灵列表
    local battlePetList = self:_SelectPetList(teamEntity, pieceType,firstElementType)

    for _, petEntityID in ipairs(battlePetList) do
        ---当前需要施法的连锁技能ID
        local chainSkillID = self:_GetPetChainSkillIDByChainPathCount(petEntityID)
        if chainSkillID > 0 then
            selectPetCmpt:AddPreviewChainSelectPet(petEntityID)
            selectPetCmpt:AddPreviewChainSelectPetSkillID(petEntityID, chainSkillID)

            local scopeResult = self:_CalcChainSkillScopeAndTarget(petEntityID, chainSkillID)

            ---加到预览要使用的列表里
            selectPetCmpt:AddPreviewChainSelectPetScopeResult(petEntityID, scopeResult)
        end
    end
end

---为宝宝的连锁技选取攻击格子
function SkillPreselectTargetSystem_Render:_CalcChainSkillScopeAndTarget(petEntityID, chainSkillID)
    ---取划线路径的最后一个点
    local castSkillPos = self:_GetChainSkillCastPos()

    ---算出一个范围结果
    ---@type SkillScopeResult
    local scopeResult = self:_CalcChainSkillScopeResult(petEntityID, chainSkillID, castSkillPos)

    ---算范围内的目标列表
    local targetIDList = self:_CalcScopeResultTargetList(petEntityID, chainSkillID, scopeResult)

    scopeResult = self:ReplaceScopeResult(scopeResult, petEntityID, chainSkillID, castSkillPos)
    ---根据位置匹配出需要加到范围内的目标ID
    self:_FillSkillScopeResult(scopeResult, targetIDList)

    return scopeResult
end

---@param scopeResult SkillScopeResult
function SkillPreselectTargetSystem_Render:_FillSkillScopeResult(scopeResult, targetIDList)
    local attackRange = scopeResult:GetAttackRange()
    for _, gridPos in ipairs(attackRange) do
        for _, targetEntityID in ipairs(targetIDList) do
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            ---@type GridLocationComponent
            local gridLocationCmpt = targetEntity:GridLocation()
            ---@type BodyAreaComponent
            local bodyAreaCmpt = targetEntity:BodyArea()
            local bodyAreaList = bodyAreaCmpt:GetArea()

            for i, bodyArea in ipairs(bodyAreaList) do
                local curBodyPos =
                    Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                if curBodyPos == gridPos then
                    scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                end
            end
        end
    end
end

function SkillPreselectTargetSystem_Render:_CalcScopeResultTargetList(petEntityID, chainSkillID, scopeResult)
    ---@type SkillScopeTargetSelector
    local selector = SkillScopeTargetSelector:New(self._world)

    ---@type Entity
    local castEntity = self._world:GetEntityByID(petEntityID)

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, castEntity)
    local skillTargetType = skillConfigData:GetSkillTargetType()

    local entityIDArray = selector:DoSelectSkillTarget(castEntity, skillTargetType, scopeResult, chainSkillID)

    return entityIDArray
end

---计算连锁技的范围
function SkillPreselectTargetSystem_Render:_CalcChainSkillScopeResult(petEntityID, chainSkillID, castSkillPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityID)

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(chainSkillID, petEntity)

    ---@type SkillScopeResult
    local scopeResult = utilScopeSvc:CalcSkillScopeForChainSkillPreview(skillConfigData, castSkillPos, petEntity)

    return scopeResult
end

---找到连线最后一个点作为连锁技的施法点
function SkillPreselectTargetSystem_Render:_GetChainSkillCastPos()
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()

    local chainPathList = previewChainPathCmpt:GetPreviewChainPath()
    local chainTotalCount = previewChainPathCmpt:GetPreviewChainTotalCount()

    --取划线路径的最后一个点
    local casterPos = chainPathList[chainTotalCount]

    return casterPos
end

---根据连线数查找星灵的对应连锁技能ID
function SkillPreselectTargetSystem_Render:_GetPetChainSkillIDByChainPathCount(petEntityID)
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewChainPathComponent
    local previewChainPathCmpt = previewEntity:PreviewChainPath()
    local chainPath = previewChainPathCmpt:GetPreviewChainPath()
    ---@type UtilCalcServiceShare
    local utilCalcSvc = self._world:GetService("UtilCalc")
    ---这个就是连线数
    local chainCount, superGridNum = utilCalcSvc:GetChainDamageRateAtIndex(chainPath, #chainPath)

    ---@type Entity
    local petEntity = self._world:GetEntityByID(petEntityID)

    ---@type SkillInfoComponent
    local skillInfoCmpt = petEntity:SkillInfo()

    local rule = skillInfoCmpt._chainSkillIDSelector:GetRule()
    local tmpChainSkillID = rule[1].Skill
    ---@type ConfigService
    local configSvc = self._world:GetService("Config")
    ---@type SkillConfigData 连锁技数据
    local firstChainConfig = configSvc:GetSkillConfigData(tmpChainSkillID)
    local previewType = firstChainConfig:GetSkillPreviewType()
    if previewType ~= SkillPreviewType.Pet1502051Chain then
        local fix = petEntity:RenderAttributes():GetAttribute("ChainSkillReleaseFix") or 0
        local chainCountMul = petEntity:RenderAttributes():GetAttribute("ChainSkillReleaseMul") or 0

        local fixedChainCount = math.ceil((chainCount + fix) * (1 + chainCountMul))

        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local chainExtraFix = utilData:GetEntityBuffValue(petEntity, "ChangeExtraChainSkillReleaseFixForSkill")
        local skillID = skillInfoCmpt:GetChainSkillConfigID(fixedChainCount, chainExtraFix)
        return skillID
    else
        ---@type PreviewLinkLineService
        local previewLinkLineSvc = self._world:GetService("PreviewLinkLine")
        local skillID, useless = previewLinkLineSvc:CalcReplaceChainPreviewParamsPet1502051(petEntity, chainPath)
        return skillID or 0
    end
end

---无副作用函数
---根据连线，选择出战队伍
---队伍信息会存到RenderBoardEntity的PreviewChainSelectPetComponent组件里
---@param teamEntity Entity
---@param pieceType PieceType
function SkillPreselectTargetSystem_Render:_SelectPetList(teamEntity, pieceType,firstElementType)
    local petResultList = {}

    --队长必须出战
    local teamLeaderEntityID = teamEntity:Team():GetTeamLeaderEntityID()

    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")

    if utilDataSvc:IsTeamLeaderCanAttack(teamEntity, pieceType) then
        petResultList[#petResultList + 1] = teamLeaderEntityID
    end

    ---获取整个队伍的PstID列表
    local teamOrder = teamEntity:Team():GetTeamOrder()
    ---从第二个开始检查是否能出战
    for i = 2, #teamOrder do
        local curPetPstID = teamOrder[i]
        ---找到Pet Entity
        ---@type Entity
        local petEntity = teamEntity:Team():GetPetEntityByPetPstID(curPetPstID)
        if petEntity:HasBuffFlag(BuffFlags.SealedCurse) then
            goto SKILLPRESELECTTARGETSYSTEM_RENDER_SELECTPETLIST_SEALEDCURSE_CONTINUE
        end
        
        local isMatch = false
        local forceMatch = utilDataSvc:GetEntityBuffValue(petEntity,"PetForceMatch")
        if forceMatch then 
            isMatch = true
        else
            ---是否能出战
            isMatch = self:_IsPetEntityMatchPieceType(petEntity, pieceType)
            if not isMatch and firstElementType then
                isMatch = self:_IsPetEntityMatchPieceType(petEntity, firstElementType)
            end
        end

        local PetForcepetForceChain = utilDataSvc:OnCheckPetForceChain(petEntity)
        if (isMatch == true or PetForcepetForceChain == true) and not petEntity:HasPetDeadFlag() then
            ---加到队列里
            petResultList[#petResultList + 1] = petEntity:GetID()
        end

        ::SKILLPRESELECTTARGETSYSTEM_RENDER_SELECTPETLIST_SEALEDCURSE_CONTINUE::
    end

    return petResultList
end

---@param petEntity Entity
function SkillPreselectTargetSystem_Render:_IsPetEntityMatchPieceType(petEntity, pieceType)
    ---@type ElementComponent
    local elementCmpt = petEntity:Element()
    local primaryType = elementCmpt:GetPrimaryType()
    local sencondardType = elementCmpt:GetSecondaryType()

    local primaryMatch = CanMatchPieceType(primaryType, pieceType)
    local secondaryMatch = CanMatchPieceType(sencondardType, pieceType)
    if primaryMatch or secondaryMatch then
        return true
    end

    return false
end

function SkillPreselectTargetSystem_Render:ReplaceScopeResult(scopeResult, petEntityID, chainSkillID, castSkillPos)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(chainSkillID)
    ---@type SkillScopeType
    local scopeType = skillConfigData:GetSkillScopeType()
    ----策划配置了错误的技能范围和表现范围然后并不想改 只能特化一个
    if
        scopeType == SkillScopeType.NearestInSquareRing and
            skillConfigData:GetSkillPreviewType() == SkillPreviewType.ScopeSingleChainSkillInScope54
     then
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        local param = skillConfigData:GetSkillScopeParam()
        local newSkillConfigData = SkillConfigData:New()
        -- MSG57611
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local scopeParamAppender = utilData:GetEntityBuffValue(petEntity, "ChainSkillPreviewScopeParamAppender" .. chainSkillID)
        if scopeParamAppender and type(param) == 'table' then
            local copyScopeParam = {}
            for k, v in pairs(param) do
                copyScopeParam[k] = v
            end
            for index, val in ipairs(scopeParamAppender) do
                copyScopeParam[index] = copyScopeParam[index] + val
            end
            param = copyScopeParam
        end
        newSkillConfigData._scopeParamData = {param[1]}
        newSkillConfigData._scopeType = SkillScopeType.SquareRing
        newSkillConfigData._scopeCenterType = skillConfigData:GetSkillScopeCenterType()
        newSkillConfigData._targetType = skillConfigData:GetSkillTargetType()
        newSkillConfigData._scopeFilterParam = skillConfigData:GetScopeFilterParam()
        ---@type SkillScopeResult
        scopeResult = utilScopeSvc:CalcSkillScope(newSkillConfigData, castSkillPos, petEntity)
    elseif skillConfigData:GetSkillPreviewType() == SkillPreviewType.ScopeSingleChainSkillWithParam then
        ---@type Entity
        local petEntity = self._world:GetEntityByID(petEntityID)
        local newSkillConfigData = SkillConfigData:New()
        local skillPreviewParam = skillConfigData:GetSkillPreviewParam()
        local scopeType = skillPreviewParam.scopeType
        local scopeParam = skillPreviewParam.scopeParam
        -- MSG57611
        ---@type UtilDataServiceShare
        local utilData = self._world:GetService("UtilData")
        local scopeParamAppender = utilData:GetEntityBuffValue(petEntity, "ChainSkillPreviewScopeParamAppender" .. chainSkillID)
        if scopeParamAppender and type(scopeParam) == 'table' then
            local copyScopeParam = {}
            for k, v in pairs(scopeParam) do
                copyScopeParam[k] = v
            end
            for index, val in ipairs(scopeParamAppender) do
                copyScopeParam[index] = copyScopeParam[index] + val
            end
            scopeParam = copyScopeParam
        end
        newSkillConfigData._scopeType = scopeType
        newSkillConfigData._scopeParamData = scopeParam
        newSkillConfigData._scopeCenterType = skillConfigData:GetSkillScopeCenterType()
        newSkillConfigData._targetType = skillConfigData:GetSkillTargetType()
        newSkillConfigData._scopeFilterParam = skillConfigData:GetScopeFilterParam()
        ---@type SkillScopeResult
        scopeResult = utilScopeSvc:CalcSkillScope(newSkillConfigData, castSkillPos, petEntity)
    end
    return scopeResult
end
