require("base_ins_r")
---@class PlayAddAttachmentInstruction: BaseInstruction
_class("PlayAddAttachmentInstruction", BaseInstruction)
PlayAddAttachmentInstruction = PlayAddAttachmentInstruction

function PlayAddAttachmentInstruction:Constructor(paramList)
    self._attachResName = paramList["attachResName"]
    local cfgRes = string.split(paramList["attachCacheRes"], "|")
    self._attachCacheResList = {}
    for _, v in ipairs(cfgRes) do
        table.insert(self._attachCacheResList, v)
    end
end

function PlayAddAttachmentInstruction:GetCacheResource()
    local t = {}
    if self._attachResName then
        table.insert(t, {self._attachResName .. ".prefab", 1})
    end

    if not self._attachCacheResList then
        return t
    end

    for _, v in pairs(self._attachCacheResList) do
        table.insert(t, {v .. ".prefab", 1})
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayAddAttachmentInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self._attachResName then
        casterEntity:AddAttachmentController(self._attachResName)
    end

    ---@type MaterialAnimationComponent
    local matAniCmpt = nil
    if casterEntity:HasMaterialAnimationComponent() then
        matAniCmpt = casterEntity:MaterialAnimationComponent()
    end
    if not matAniCmpt then
        return
    end

    --为部件添加材质动画控制组件
    ---@type AttachmentControllerComponent
    local attachCmpt = nil
    if casterEntity:HasAttachmentController() then
        attachCmpt = casterEntity:AttachmentController()
    end
    if not attachCmpt then
        return
    end

    ---@type ResRequest
    local resQuest = attachCmpt:GetResRequest()
    if not resQuest then
        return
    end

    ---@type MaterialAnimation
    local attMatAni = resQuest.Obj:GetComponent(typeof(MaterialAnimation))
    if attMatAni then
        UnityEngine.Object.Destroy(attMatAni)
    end
    attMatAni = resQuest.Obj:AddComponent(typeof(MaterialAnimation))

    matAniCmpt:SetAttachmentMaterialAnimation(attMatAni)
end
