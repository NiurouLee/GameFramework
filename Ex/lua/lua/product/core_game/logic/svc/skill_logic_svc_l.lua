--[[------------------
    技能逻辑的公共服务对象
--]] ------------------
_class("SkillLogicService", BaseService)
---@class SkillLogicService:BaseService
SkillLogicService = SkillLogicService

function SkillLogicService:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")
    ---技能效果计算器

    ---@type WorldRunPostion
    self._runPos = self._world:GetRunningPosition()
end

function SkillLogicService:Initialize()
    ---划线选敌计算器
    ---@type ChainPathTargetSelector
    self._chainPathTargetSelector = ChainPathTargetSelector:New(self._world)

    ---普攻计算器
    ---@type NormalSkillCalculator
    self._normalSkillCalculator = NormalSkillCalculator:New(self._world)

    ---连锁技计算器
    ---@type ChainSkillCalculator
    self._chainSkillCalculator = ChainSkillCalculator:New(self._world)

    ---技能目标选择器
    ---@type SkillScopeTargetSelector
    self._skillScopeTargetSelector = self._world:GetSkillScopeTargetSelector()

    ---主动技计算器
    self._activeSkillCalculator = ActiveSkillCalculator:New(self._world)

    ---是否使用技能计算器，这个开关用来一键打开或关闭重构后的技能逻辑机制
    self._useSkillCaclulator = true
end

---根据连线，为本次划线选择普通攻击目标
---@param actorEntity Entity
function SkillLogicService:SelectNormalAttackTarget(actorEntity)
    self._chainPathTargetSelector:DoSelectNormalAttackTarget(actorEntity)
end

---为出战队伍里的每一个队员计算普攻伤害
---@param actorEntity Entity
function SkillLogicService:CalcNormalSkillDamage(actorEntity)
    self._normalSkillCalculator:DoCalculateNormalSkill(actorEntity)
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2RNormalAttackData(self._normalSkillCalculator, actorEntity)
end

---为出战队伍里的每一个成员计算连锁技能伤害
---@param teamEntity Entity 主角Entity
function SkillLogicService:CalcChainSkillDamage(teamEntity, skillCastPos)
    self._chainSkillCalculator:DoCalculateChainSkill(teamEntity, skillCastPos)
end

---@param castEntity Entity
---@param skillType SkillType
function SkillLogicService:CalcSkillEffect(castEntity, skillID, skillType, overrideScopeResult)
    --记录同步信息
    self._world:GetSyncLogger():Trace({ key = "CalcSkillEffect", casterID = castEntity:GetID(), skillID = skillID })
    ---范围计算
    ---@type ConfigService
    local configService = self._configService
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillConfigData 主动技配置数据
    local skillConfigData = configService:GetSkillConfigData(skillID)
    local targetType = skillConfigData:GetSkillTargetType()

    local casterPos = castEntity:GridLocation().Position
    local casterDir = castEntity:GridLocation().Direction
    ---@type SkillScopeResult
    local scopeResult

    ---Buff释放技能之前的通知
    ---注意：这种方式判断不了skillHolder="self"这种情况，不过目前大多数都不是这样配置的
    if castEntity:EntityType():IsSkillHolder() then
        self._world:GetService("Trigger"):Notify(NTBuffCastSkillAttackBegin:New(castEntity, skillID))
    end

    --如果技能范围是展示上一次计算的类型
    ---@type AIComponentNew
    local aiCmpt = castEntity:AI()
    if aiCmpt then
        scopeResult = aiCmpt:GetSkillScopeResult()
    end
    if not scopeResult then
        scopeResult = utilScopeSvc:CalcSkillScope(skillConfigData, casterPos, castEntity, casterDir)
    end
    --Log.fatal("launchskill casterPos:",casterPos.x," ",casterPos.y," ",Log.traceback())
    if scopeResult == nil then
        Log.error("scopeResult==nil!! skillID=", skillID)
        return
    end
    ---@type SkillEffectResultContainer
    local skillResult = castEntity:SkillContext():GetResultContainer()
    skillResult:Clear()
    scopeResult:ClearTargetIDs()
    skillResult:SetSkillID(skillID)

    ----这里有可能需要根据点选类型修改选的范围  TODO 删掉这里没用了
    self:_ModifyScopeResult(castEntity, scopeResult)

    if overrideScopeResult then
        Log.info("CalcSkillEffect: scope override by caller. ")
        scopeResult = overrideScopeResult
    end

    ---先选技能目标
    local targetEntityIDArray =
    self._skillScopeTargetSelector:DoSelectSkillTarget(castEntity, targetType, scopeResult, skillID)
    if targetEntityIDArray then
        local pos2ID = {}
        for _, targetEntityID in ipairs(targetEntityIDArray) do
            scopeResult:AddTargetID(targetEntityID)
            ---@type Entity
            local targetEntity = self._world:GetEntityByID(targetEntityID)
            if targetEntity:HasBodyArea() and targetEntity:HasGridLocation() then
                ---@type GridLocationComponent
                local gridLocationCmpt = targetEntity:GridLocation()
                ---@type BodyAreaComponent
                local bodyAreaCmpt = targetEntity:BodyArea()
                local bodyAreaList = bodyAreaCmpt:GetArea()

                for i, bodyArea in ipairs(bodyAreaList) do
                    local curBodyPos =
                    Vector2(gridLocationCmpt.Position.x + bodyArea.x, gridLocationCmpt.Position.y + bodyArea.y)
                    local posIdx = Vector2.Pos2Index(curBodyPos)
                    if not pos2ID[posIdx] then
                        pos2ID[posIdx] = {}
                    end
                    table.insert(pos2ID[posIdx], targetEntityID)
                end
            end
        end
        for _, gridPos in ipairs(scopeResult:GetAttackRange()) do
            if gridPos._className == 'Vector2' then
                local targetEntityIDs = pos2ID[Vector2.Pos2Index(gridPos)]
                if targetEntityIDs then
                    for _, targetEntityID in ipairs(targetEntityIDs) do
                        scopeResult:AddTargetIDAndPos(targetEntityID, gridPos)
                    end
                end
            else --安洁尔特殊范围
                for _, pos in ipairs(gridPos) do
                    local targetEntityIDs = pos2ID[Vector2.Pos2Index(pos)]
                    if targetEntityIDs then
                        for _, targetEntityID in ipairs(targetEntityIDs) do
                            scopeResult:AddTargetIDAndPos(targetEntityID, pos)
                        end
                    end
                end
            end
        end
    end

    skillResult:SetScopeResult(scopeResult)
    if skillType and skillType == SkillType.Active then
        if castEntity:HasPetPstID() then
            local notifyData = NTActiveSkillAttackStart:New(castEntity)
            notifyData:InitSkillResult(skillID, scopeResult)
            ---@type BattleStatComponent
            local battleStateCmpt = self._world:BattleStat()
            battleStateCmpt:SetLastActiveSkillID(skillID)
            battleStateCmpt:SetLastActiveSkillCasterID(castEntity:GetID())
            self._world:GetService("Trigger"):Notify(notifyData)
        end
    end
    
    if castEntity:HasMonsterID() then
        self._world:GetService("Trigger"):Notify(NTMonsterSkillDamageStart:New(castEntity, skillID))
    end

    ---主动技计算流程
    self._activeSkillCalculator:DoCalculateSkill(castEntity)

    if castEntity:HasMonsterID() then
        self._world:GetService("Trigger"):Notify(NTMonsterSkillDamageEnd:New(castEntity, skillID))
    end
    
    ---Buff释放技能之后的通知
    if castEntity:EntityType():IsSkillHolder() then
        self._world:GetService("Trigger"):Notify(NTBuffCastSkillAttackEnd:New(castEntity, skillID))
    end
end

--数据发给表现层
function SkillLogicService:UpdateRenderSkillRoutine(casterEntity, key)
    ---@type L2RService
    local svc = self._world:GetService("L2R")
    svc:L2ROneSkillData(casterEntity, key)
    casterEntity:ReplaceSkillContext()
end

---对ScopeResult根据需要执行修改,这个方法实际上是临时写法
---背景：卡戎这个星灵在做的时候，ScopeType是给预览使用的，而真正在执行技能计算的时候要取
---pickup组件里的数据作为scopeResult
---TODO：修改卡戎的预览范围计算方法，通过预览类型指出预览范围，让scopeType的意义回归到真实技能计算上
---可给scopeType增加一种pickup类型，当计算这种范围时，取的是pickup相关组件上的数据
---@param casterEntity Entity 施法者
---@param scopeResult SkillScopeResult 范围
function SkillLogicService:_ModifyScopeResult(casterEntity, scopeResult)
    if not casterEntity:HasPetPstID() then
        return
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()

    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillConfigData
    local skillConfigData = self._configService:GetSkillConfigData(skillID)
    --TODO 阿克希亚扫描模块处理 这里根本没用上那就可以删掉了

    local attackRange = nil

    if attackRange ~= nil then
        scopeResult:SetAttackRange(attackRange)
    end
end

---计算施法位置
---施法位置可能就是施法者当前的位置，也可能是玩家点选的位置，也可能是怪将要施法的位置
---总之不一定是施法者当前的位置
---@param casterEntity Entity
---@return Vector2 施法位置
function SkillLogicService:_CalcSkillCastPos(casterEntity)
    if casterEntity:HasPetPstID() then
        ---星灵，有可能需要看下主动技
    else
    end
end

--应用吸收幻象逻辑，这里是纯逻辑，只有服务器会调用，客户端走另外的怪物死亡逻辑
---@param result SkillAbsorbPhantomEffectResult
function SkillLogicService:ApplyAbsorbPhantom(result)
    if result:GetTargetEntityID() then
        ---@type Entity
        local phantom = self._world:GetEntityByID(result:GetTargetEntityID())
        if not phantom:HasPhantomComponent() then
            Log.fatal("目标非幻象，不可吸收")
            return
        end
        ---@type Entity 主身
        local owner = self._world:GetEntityByID(phantom:PhantomComponent():GetOwnerEntityID())
        ---@type DamageInfo
        local damageInfo = DamageInfo:New(result:GetRecoverHP(), DamageType.Recover)
        --回血
        ---@type CalcDamageService
        local calcDamageSvc = self:GetService("CalcDamage")
        calcDamageSvc:AddTargetHP(owner:GetID(), damageInfo)
        result:SetRecoverHP(damageInfo:GetDamageValue())
        result:SetDamageInfo(damageInfo)

        --移除阻挡信息
        ---@type BoardServiceLogic
        local sBoard = self._world:GetService("BoardLogic")
        sBoard:RemoveEntityBlockFlag(phantom, phantom:GridLocation().Position)

        --标记幻象逻辑死亡，等待统一死亡流程处理
        phantom:AddDeadMark()

        ---@type MonsterShowLogicService
        local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")
        sMonsterShowLogic:_DoLogicDead(phantom)
    end
end

--判断技能是否是普攻
function SkillLogicService:CheckNormalSkill(skillID)
    if not skillID or skillID == 0 then
        return false
    end
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    local config = configServer:GetSkillConfigData(skillID)
    if config:GetSkillType() == SkillType.Normal then
        return true
    end
    return false
end

---@param aiEntity Entity
---@param aiResult AISkillResult
function SkillLogicService:CalcAISkillResult(aiEntity, skillID, aiResult)
    ---计算技能数据
    self:CalcSkillEffect(aiEntity, skillID)

    ---将计算好的数据提取出来
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = aiEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:SetSkillID(skillID)
    aiResult:SetResultContainer(skillEffectResultContainer)

    --获取所有的伤害
    local damageResultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage)
    local totalDamage = 0
    if damageResultArray then
        for _, damageResult in ipairs(damageResultArray) do
            totalDamage = totalDamage + damageResult:GetTotalDamage()
        end
    end

    if aiEntity:HasMonsterID() then --怪物普攻和释放技能效果计算
        if totalDamage > 0 then
            self._world:GetService("Trigger"):Notify(NTMonsterAttackOrSkillDamageEnd:New(aiEntity, totalDamage))
        end
    end

    aiEntity:ReplaceSkillContext()

    --格子颜色变化同步表现
    local svc = self._world:GetService("L2R")
    svc:L2RBoardLogicData()
end

---根据连线，选择队伍，并为出战队伍的每一位成员选择攻击目标
---@param teamEntity Entity
---@param pieceType PieceType
function SkillLogicService:SelectTeam(teamEntity, pieceType)
    self._chainPathTargetSelector:DoSelectTeam(teamEntity, pieceType)
end

---@param teamEntity Entity
function SkillLogicService:UpdateTeamGridLocationByChainPath(teamEntity, chainPath)
    ---计算普攻连锁技
    local castPos = chainPath[#chainPath]

    local newDirection = teamEntity:GetGridDirection() --#Glee
    if #chainPath > 1 then
        newDirection = chainPath[#chainPath] - chainPath[#chainPath - 1]
    end
    local pets = teamEntity:Team():GetTeamPetEntities()
    for _, entityPet in ipairs(pets) do
        entityPet:SetGridLocation(castPos, newDirection)
        entityPet:GridLocation():SetMoveLastPosition(castPos)
    end
    teamEntity:SetGridLocation(castPos, newDirection)
    teamEntity:GridLocation():SetMoveLastPosition(castPos)
end

function SkillLogicService:IsSelectEntitySkill(skillID)
    if not skillID or skillID == 0 then
        return false
    end
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    ---@type SkillConfigData
    local config = configServer:GetSkillConfigData(skillID)
    local selectMode = config:GetTargetSelectionModeConfig()
    if selectMode and selectMode == SkillTargetSelectionMode.Entity then
        return true
    end
    return false
end

function SkillLogicService:IsSelectGridSkill(skillID)
    if not skillID or skillID == 0 then
        return false
    end
    ---@type ConfigService
    local configServer = self._world:GetService("Config")
    ---@type SkillConfigData
    local config = configServer:GetSkillConfigData(skillID)
    local selectMode = config:GetTargetSelectionModeConfig()
    if not selectMode or selectMode == SkillTargetSelectionMode.Grid then
        return true
    end
    return false
end
