require("sp_base_inst")
---@class SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction: SkillPreviewBaseInstruction
_class("SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction", SkillPreviewBaseInstruction)
SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction = SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction

function SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction:Constructor(params)
    local strList = params.trapIDList
    local strIDs = string.split(strList, "|")

    self._trapIDList = {}
    for i = 1, #strIDs do
        local trapID = tonumber(strIDs[i])
        table.insert(self._trapIDList, trapID)
    end

    self._effectID = tonumber(params.effectID)
    self._scopeParam = {
        TargetType = tonumber(params.scopeTargetType),
        ScopeType = tonumber(params.scopeType),
        ScopeParam = { tonumber(params.scopeParam) },
        ScopeCenterType = tonumber(params.scopeCenterType)
    }

    --匹配属性格子时的技能范围
    self._matchType = tonumber(params.matchType)
    self._matchScopeParam = {
        TargetType = tonumber(params.matchScopeTargetType),
        ScopeType = tonumber(params.matchScopeType),
        ScopeParam = { tonumber(params.matchScopeParam) },
        ScopeCenterType = tonumber(params.matchScopeCenterType)
    }


    self._skinUseEffectMap = {}
    if params.skinUseEffectID then--清瞳皮肤 改预览机关特效 临时简单处理
        local splitedStrArray = string.split(params.skinUseEffectID, "|")
        local keyFlag = 1
        local key = nil
        local value = nil
        for i,v in ipairs(splitedStrArray) do
            local num = tonumber(v)
            if keyFlag == 1 then
                key = num
            else
                value = num
                self._skinUseEffectMap[key] = value
            end
            keyFlag = keyFlag + 1
            if keyFlag > 2 then
                keyFlag = 1
            end
        end
    end
end

function SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction:GetCacheResource()
    local res = {}
    local effRes = {Cfg.cfg_effect[self._effectID].ResPath, 1}
    table.insert(res,effRes)
    for i,effectID in pairs(self._skinUseEffectMap) do
        local skinEffRes = {Cfg.cfg_effect[effectID].ResPath, 1}
        table.insert(res,skinEffRes)
    end
    return res
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local pickUpPos = previewContext:GetPickUpPos()
    local boardCmpt = world:GetBoardEntity():Board()
    local traps =
    boardCmpt:GetPieceEntities(
        pickUpPos,
        function(e)
            local isOwner = false
            if e:HasSummoner() then
                local summonEntityID = e:Summoner():GetSummonerEntityID()
                ---@type Entity
                local summonEntity = e:GetSummonerEntity()
                --需判定召唤者是否死亡（例：情报怪死亡后召唤情报）
                if summonEntity and summonEntity:HasSuperEntity() and summonEntity:GetSuperEntity() then
                    summonEntityID = summonEntity:GetSuperEntity():GetID()
                end
                if summonEntityID == casterEntity:GetID() then
                    isOwner = true
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrapRender() and table.icontains(self._trapIDList, e:TrapRender():GetTrapID()) and not e:HasDeadMark()
        end
    )

    if #traps > 0 then
        local isMatchPieceType = false
        if self._matchType then
            ---@type UtilDataServiceShare
            local utilData = world:GetService("UtilData")
            local pieceType = utilData:FindPieceElement(pickUpPos)
            if (pieceType == self._matchType) then
                isMatchPieceType = true
            end
        end

        --重新计算技能范围和目标对象
        if isMatchPieceType then
            self:_CalcSkillScopeAndTarget(self._matchScopeParam, casterEntity, previewContext)
        else
            self:_CalcSkillScopeAndTarget(self._scopeParam, casterEntity, previewContext)
        end
    else
        local useEffectID = self._effectID
        local skinId = 1
        if casterEntity:MatchPet() then
            skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
            if skinId and self._skinUseEffectMap[skinId] then
                useEffectID = self._skinUseEffectMap[skinId]
            end
        end
        local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(useEffectID, pickUpPos)
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())

        ---清空预览范围和攻击目标
        previewContext:SetScopeResult(nil)
        local targetList = {}
        previewContext:SetTargetEntityIDList(targetList)
    end
end

function SkillPreviewPlayShowAtkOrSummonOnPickupPosInstruction:_CalcSkillScopeAndTarget(scopeParam, casterEntity, previewContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type ConfigService
    local configSvc = world:GetService("Config")
    ---@type SkillConfigHelper
    local helper = configSvc._skillConfigHelper
    ---@type SkillScopeParamParser
    local parser = helper._scopeParamParser
    ---@type SkillPreviewScopeParam
    local spScopeParam = SkillPreviewScopeParam:New(scopeParam)
    local param = parser:ParseScopeParam(scopeParam.ScopeType, scopeParam.ScopeParam)
    spScopeParam:SetScopeParamData(param)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = world:GetService("PreviewActiveSkill")
    local scopeResult = previewActiveSkillService:CalcScopeResult(spScopeParam, casterEntity)
    previewContext:SetScopeResult(scopeResult:GetAttackRange())
    ---重新计算技能目标
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = world:GetService("UtilScopeCalc")
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, scopeParam.TargetType, scopeResult)
    previewContext:SetTargetEntityIDList(targetIDList)
end
