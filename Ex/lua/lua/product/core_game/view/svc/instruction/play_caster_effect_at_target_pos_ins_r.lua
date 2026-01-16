require("base_ins_r")
---@class PlayCasterEffectAtTargetPosInstruction: BaseInstruction
_class("PlayCasterEffectAtTargetPosInstruction", BaseInstruction)
PlayCasterEffectAtTargetPosInstruction = PlayCasterEffectAtTargetPosInstruction

function PlayCasterEffectAtTargetPosInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._randomDir = tonumber(paramList["randomDir"])
    self._bone = paramList["bone"] or "Hit" --骨点，不配默认是Hit点
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext 当前指令集合的上下文，用于存储数据
function PlayCasterEffectAtTargetPosInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local targetEntityID = phaseContext:GetCurTargetEntityID()
    local targetEntity = world:GetEntityByID(targetEntityID)
    if not targetEntity then
        Log.fatal("### no target, use DataSelect instruction firstly please. skillID=", skillID)
        return
    end
    local targetViewCmpt = targetEntity:View()
    if targetViewCmpt ~= nil then
        local targetHitObj
        if self._bone == "Hit" then
            ---@type PlaySkillService
            local playSkillService = world:GetService("PlaySkill")
            targetHitObj = playSkillService:GetEntityRenderHitTransform(targetEntity)
        else
            local targetGameObject = targetViewCmpt:GetGameObject()
            targetHitObj = GameObjectHelper.FindChild(targetGameObject.transform, self._bone)
        end
        if targetHitObj ~= nil then
            local effectEntity =
                world:GetService("Effect"):CreatePositionEffect(self._effectID, targetHitObj.transform.position)
            if self._randomDir then
                ---目前随机方向效果，策划还不确定要怎么做，所以临时这么写
                local randomDir = Vector3(Mathf.Random(), Mathf.Random(), Mathf.Random())
                effectEntity:SetDirection(randomDir)
            end
        end
    end
end

function PlayCasterEffectAtTargetPosInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
