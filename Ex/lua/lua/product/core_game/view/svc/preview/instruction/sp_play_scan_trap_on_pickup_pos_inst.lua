require("sp_base_inst")

_class("SkillPreviewPlayScanTrapOnPickupPosInstruction", SkillPreviewBaseInstruction)
---@class SkillPreviewPlayScanTrapOnPickupPosInstruction: SkillPreviewBaseInstruction
SkillPreviewPlayScanTrapOnPickupPosInstruction = SkillPreviewPlayScanTrapOnPickupPosInstruction

function SkillPreviewPlayScanTrapOnPickupPosInstruction:GetCacheResource()
    --扫描到的机关是运行时决定的，这里没有直接的cache办法
    --只能寄希望于被扫描机关在其他召唤手段的机制内cache了
    return {}
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param previewContext SkillPreviewContext 当前指令集合的上下文，用于存储数据
function SkillPreviewPlayScanTrapOnPickupPosInstruction:DoInstruction(TT, casterEntity, previewContext)
    ---@type PreviewActiveSkillService
    local previewActiveSkillService = previewContext:GetWorld():GetService("PreviewActiveSkill")
    local world = casterEntity:GetOwnerWorld()
    local scanResult = world:GetService("UtilData"):GetScanSelection()
    local trapID = scanResult.trapID
    if (not trapID) or (not Cfg.cfg_trap[trapID]) then
        return
    end

    local resPath = Cfg.cfg_trap[trapID].ResPath
    ---@type Entity
    local effectEntity = world:GetService("Effect"):CreateEffectEntity()
    effectEntity:ReplaceAsset(NativeUnityPrefabAsset:New(resPath))
    effectEntity:SetPosition(previewContext:GetPickUpPos())--看上去可能不支持多个点选位置
    effectEntity:AddEffect(-1)

    --local effectEntity = world:GetService("Effect"):CreateWorldPositionEffect(self._effectID, previewContext:GetPickUpPos())
    local previewPickUpComponent = casterEntity:PreviewPickUpComponent()
    previewPickUpComponent:AddPickUpEffectEntityID(effectEntity:GetID())
end
