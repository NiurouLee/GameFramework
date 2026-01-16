require("base_ins_r")
---@class PlayTargetAddBuffInstruction: BaseInstruction
_class("PlayTargetAddBuffInstruction", BaseInstruction)
PlayTargetAddBuffInstruction = PlayTargetAddBuffInstruction

function PlayTargetAddBuffInstruction:Constructor(paramList)
    self._buffID = tonumber(paramList["buffID"])
    self._buffEffectType = tonumber(paramList["buffEffectType"])
    if paramList["animName"] then
        self._animName = paramList["animName"]
    end
    if paramList["effectId"] then
        self._effectId = tonumber(paramList["effectId"])
    end
    if paramList["stageIndex"] then
        self._stageIndex = tonumber(paramList["stageIndex"])
    end
    self._isRemove = false
    if paramList["remove"] then
        self._isRemove = true
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayTargetAddBuffInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type PlayBuffService
    local playBuffService = world:GetService("PlayBuff")

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    local targetEntityID = phaseContext:GetCurTargetEntityID()

    local buffResultArray =
        skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AddBuff, self._stageIndex)
    if not buffResultArray then
        return
    end
    local targetEntity = world:GetEntityByID(targetEntityID)
    if targetEntity == nil then
        return
    end

    for _, v in pairs(buffResultArray) do
        local eid = v:GetEntityID()
        local buffArray = v:GetAddBuffResult()
        if targetEntityID == eid and buffArray then
            for _, seq in pairs(buffArray) do
                Log.debug("PlayTargetAddBuff entityid=", eid, " buffseq=", seq, " isRemove=", self._isRemove)

                ---@type BuffViewInstance
                local buffViewInst = targetEntity:BuffView():GetBuffViewInstance(seq)
                if buffViewInst then --找不到说明buff挂上立即被卸载了
                    local buffID = buffViewInst:BuffID()
                    local buffEffectType = buffViewInst:GetBuffEffectType()
                    local buffMatch = self._buffID and self._buffID == buffID or self._buffEffectType == buffEffectType
                    if buffMatch then
                        if self._animName then
                            targetEntity:SetAnimatorControllerTriggers({self._animName})
                        end
                        if self._effectId then
                            local effect = world:GetService("Effect"):CreateEffect(self._effectId, targetEntity)
                        end
                        if self._isRemove then
                            playBuffService:PlayRemoveBuff(TT, buffViewInst, NTBuffUnload:New())
                        else
                            if v:GetBuffInitLayer() then
                                targetEntity:BuffView():SetBuffValue(buffViewInst._buffLayerName, v:GetBuffInitLayer())
                            end
                            playBuffService:PlayAddBuff(TT, buffViewInst, casterEntity:GetID())
                        end
                    end
                end
            end
        end
    end
end

function PlayTargetAddBuffInstruction:GetCacheResource()
    local t = {}
    if self._effectId and self._effectId > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectId].ResPath, 1})
    end
    return t
end
