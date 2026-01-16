require("sp_base_inst")
_class("SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction = SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction

function SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction:Constructor(params)
    self._trapID = tonumber(params.trapID)
    self._effectID = tonumber(params.effectID)
    self._prefab = params["Prefab"]
    self._anim = params["Anim"] or "AtkUltPreview"
    self._scopeParam = {
        TargetType = tonumber(params.scopeTargetType),
        ScopeType = tonumber(params.scopeType),
        ScopeParam = {tonumber(params.scopeParam)},
        ScopeCenterType = tonumber(params.scopeCenterType)
    }
end

function SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction:GetCacheResource()
    return {
        {Cfg.cfg_effect[self._effectID].ResPath, 1}
    }
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayCreateGhostOrSummonOnPickupPosInstruction:DoInstruction(TT, casterEntity, previewContext)
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
            --配置上保证了被选中的机关一定有SummonerComponent，因此不考虑没有该组件的机关
            --注：这里没有SummonerComponent时的结果与SkillEffectCalc_AbsorbTrapsAndDamageByPickupTarget不一致
            if e:HasSummoner() then
                if e:Summoner():GetSummonerEntityID() == casterEntity:GetID() then
                    isOwner = true
                else
                    --[[
                        修改前代码是只判断机关是不是施法者自己的
                        但N24加入的阿克希亚也可以召唤别人的机关，并需要被认为是施法者的
                        考虑到该判断原先的目的是防止吸收【被世界boss化的光灵】和【黑拳赛的对方光灵】所属机关
                        这里添加判断：当施法者是光灵时，自己队伍内的其他光灵召唤的机关，也视为施法者自己召唤的
                    ]]
                    --local casterEntity = self._world:GetEntityByID(casterEntityID)
                    local summonerID = e:Summoner():GetSummonerEntityID()
                    if casterEntity:HasPet() then
                        local cTeam = casterEntity:Pet():GetOwnerTeamEntity():Team()
                        local entities = cTeam:GetTeamPetEntities()
                        for _, petEntity in ipairs(entities) do
                            if summonerID == petEntity:GetID() then
                                isOwner = true
                                break
                            end
                        end
                    end
                end
            else
                isOwner = true
            end
            return isOwner and e:HasTrapRender() and e:TrapRender():GetTrapID() == self._trapID and not e:HasDeadMark()
        end
    )

    if #traps > 0 then
        entitySvc:CreateGhost(pickUpPos, casterEntity, self._anim, self._prefab)
        --重新计算技能范围
        ---@type ConfigService
        local configSvc = world:GetService("Config")
        ---@type SkillConfigHelper
        local helper = configSvc._skillConfigHelper
        ---@type SkillScopeParamParser
        local parser = helper._scopeParamParser
        ---@type SkillPreviewScopeParam
        local scopeParam = SkillPreviewScopeParam:New(self._scopeParam)
        local param = parser:ParseScopeParam(self._scopeParam.ScopeType, self._scopeParam.ScopeParam)
        scopeParam:SetScopeParamData(param)
        ---@type PreviewActiveSkillService
        local previewActiveSkillService = world:GetService("PreviewActiveSkill")
        local scopeResult = previewActiveSkillService:CalcScopeResult(scopeParam, casterEntity)
        previewContext:SetScopeResult(scopeResult:GetAttackRange())
        ---重新计算技能目标
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = world:GetService("UtilScopeCalc")
        local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, self._scopeParam.TargetType, scopeResult)
        previewContext:SetTargetEntityIDList(targetIDList)
    else
        local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(self._effectID, pickUpPos)
        local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
        previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())

        ---清空预览范围和攻击目标
        previewContext:SetScopeResult(nil)
        local targetList = {}
        previewContext:SetTargetEntityIDList(targetList)
    end
end
