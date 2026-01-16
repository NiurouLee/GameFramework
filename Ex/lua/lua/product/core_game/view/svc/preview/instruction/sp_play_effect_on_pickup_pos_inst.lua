require("sp_base_inst")
_class("SkillPreviewPlayEffectOnPickupPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayEffectOnPickupPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayEffectOnPickupPosInstruction = SkillPreviewPlayEffectOnPickupPosInstruction

function SkillPreviewPlayEffectOnPickupPosInstruction:Constructor(params)
    self._effectID = tonumber(params.effectID)
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
    assert(Cfg.cfg_effect[self._effectID], "预览指令PlayEffectOnPickupPos需要有效的effectID")
end

function SkillPreviewPlayEffectOnPickupPosInstruction:GetCacheResource()
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
function SkillPreviewPlayEffectOnPickupPosInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = previewContext:GetWorld():GetService("PreviewActiveSkill")
    local world = casterEntity:GetOwnerWorld()

    local useEffectID = self._effectID
    local skinId = 1
    if casterEntity:MatchPet() then
        skinId = casterEntity:MatchPet():GetMatchPet():GetSkinId()
        if skinId and self._skinUseEffectMap[skinId] then
            useEffectID = self._skinUseEffectMap[skinId]
        end
    end

    local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(useEffectID, previewContext:GetPickUpPos())
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())
end
