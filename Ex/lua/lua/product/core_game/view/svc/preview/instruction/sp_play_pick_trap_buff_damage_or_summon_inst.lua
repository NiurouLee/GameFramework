require("sp_base_inst")
---菲雅 点到机关时，根据机关上buff的层数显示不同特效和范围 配合技能效果169
_class("SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction = SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction

function SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction:Constructor(params)
    self._trapIDList = {}
    local trapList = params["trapIDList"]
    if trapList then
        local strIDs = string.split(trapList, "|")
        for i,v in ipairs(strIDs) do
            table.insert(self._trapIDList,tonumber(v))
        end
    end
    self._effectIDDic = {}
    if params.effectIDDic then
        local strIDs = string.split(params.effectIDDic, "|")
        for k,effectID in ipairs(strIDs) do
            self._effectIDDic[k] = tonumber(effectID)
        end
    end
    self._summonEffectID = tonumber(params.summonEffectID)
    self._checkBuffEffectType = tonumber(params.checkBuffEffectType)
end

function SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction:GetCacheResource()
    local res = {}
    for i,effectID in pairs(self._effectIDDic) do
        local effRes = {Cfg.cfg_effect[effectID].ResPath, 1}
        table.insert(res,effRes)
    end
    local effRes = {Cfg.cfg_effect[self._summonEffectID].ResPath, 1}
    table.insert(res,effRes)
    return res
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type RenderEntityService
    local entitySvc = world:GetService("RenderEntity")

    local pickUpPos = previewContext:GetPickUpPos()
    local boardCmpt = world:GetBoardEntity():Board()
    local traps =
        boardCmpt:GetPieceEntities(
        pickUpPos,
        function(e)
            local isOwner = false
            local casterEntityID = casterEntity:GetID()
            if e:HasSummoner() then
                local summonEntityID = e:Summoner():GetSummonerEntityID()
                ---@type Entity
                local summonEntity = e:GetSummonerEntity()
                if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                    summonEntityID = summonEntity:GetSuperEntity():GetID()
                end
                if summonEntityID == casterEntityID then
                    isOwner = true
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrapRender() and table.icontains( self._trapIDList,e:TrapRender():GetTrapID()) and not e:HasDeadMark()
        end
    )

    if #traps > 0 then
        --重新计算技能范围
        local scopeResult,buffState = self:_GetScopeResultAndBuffState(previewContext,pickUpPos,traps[1],casterEntity)
        previewContext:SetScopeResult(scopeResult:GetAttackRange())
        ---重新计算技能目标
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = world:GetService("UtilScopeCalc")
        local targetIDList = scopeResult:GetTargetIDs()--utilScopeSvc:SelectSkillTarget(casterEntity, self._scopeParam.TargetType, scopeResult)
        previewContext:SetTargetEntityIDList(targetIDList)

        --特效
        local effectID = self._effectIDDic[buffState]
        if effectID and (effectID > 0) then
            local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(effectID, previewContext:GetPickUpPos())
            local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
            previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())
        end
    else
        local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(self._summonEffectID, pickUpPos)
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())

        ---清空预览范围和攻击目标
        previewContext:SetScopeResult(nil)
        local targetList = {}
        previewContext:SetTargetEntityIDList(targetList)
    end
end
function SkillPreviewPlayPickTrapBuffDamageOrSummonInstruction:_GetScopeResultAndBuffState(previewContext,pickUpPos,trap,casterEntity)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillPreviewEffectCalcService
    local previewEffectCalcService =  world:GetService("PreviewCalcEffect")
    local effect = previewContext:GetEffect(SkillEffectType.PickUpTrapAndBuffDamage)
    ---@type SkillEffectParamPickUpTrapAndBuffDamage
    local skillEffectParam = previewEffectCalcService:CreateSkillEffectParam(SkillEffectType.PickUpTrapAndBuffDamage, effect)
    local skillList = skillEffectParam:GetSkillList()
    --攻击的坐标是点选的坐标
    local attackPos = pickUpPos
    local state = 0
    ---@type UtilDataServiceShare
    local utilSvc = world:GetService("UtilData")
    ---@type BuffLogicService
    local buffLogicService = world:GetService("BuffLogic")
    local buffLayer = buffLogicService:GetBuffLayer(trap, self._checkBuffEffectType)
    state = buffLayer

    if state == 0 then
        return {},state
    end

    if state > table.count(skillList) then
        state = table.count(skillList)
    end
    local skillID = skillList[state]

    ---@type ConfigService
    local configService = world:GetService("Config")
    local skillConfigData = configService:GetSkillConfigData(skillID, casterEntity)
    local scopeType = skillConfigData:GetSkillScopeType()
    local scopeParam = skillConfigData:GetSkillScopeParam()
    local centerType = skillConfigData:GetSkillScopeCenterType()
    local targetType = skillConfigData:GetSkillTargetType()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local casterBodyArea = casterEntity:BodyArea():GetArea()
    local casterDirection = casterEntity:GetGridDirection()

    local scopeResult =
        scopeCalculator:ComputeScopeRange(
        scopeType,
        scopeParam,
        attackPos,
        casterBodyArea,
        casterDirection,
        targetType,
        attackPos,
        casterEntity
    )
    return scopeResult,state
end