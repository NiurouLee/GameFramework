require("notify_extends")

require("base_ins_r")

--[[
    临时指令，等表现出来肯定是得大改的
]]

_class("PlayWeikeNotifyInstruction", BaseInstruction)
---@class PlayWeikeNotifyInstruction : BaseInstruction
PlayWeikeNotifyInstruction = PlayWeikeNotifyInstruction


local notifyClsDic = {
    [NotifyType.Pet1601781SkillHolder1] = NTPet1601781SkillHolder1,
    [NotifyType.Pet1601781SkillHolder2] = NTPet1601781SkillHolder2,
    [NotifyType.Pet1601781SkillHolder3] = NTPet1601781SkillHolder3,
}


---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayWeikeNotifyInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectResult_WeikeNotify[]
    local results = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.WeikeNotify)
    for _, result in ipairs(results) do
        local notifyType = result:GetNotifyType()
        local skillType = result:GetSkillType()
        local casterPos = result:GetCasterPos()
        local multiCastCount = result:GetMultiCastCount()
        local notifyCls = notifyClsDic[notifyType]
        if notifyCls then
            local notify = notifyCls:New(skillType, casterPos, multiCastCount)
            world:GetService("PlayBuff"):PlayBuffView(TT, notify)
        end
    end
end
