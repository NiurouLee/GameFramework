--[[
    播放技能表现
]]
---@class BuffViewCheckAndCastAntiSkill : BuffViewBase
_class("BuffViewCheckAndCastAntiSkill", BuffViewBase)
BuffViewCheckAndCastAntiSkill = BuffViewCheckAndCastAntiSkill

--是否匹配参数
function BuffViewCheckAndCastAntiSkill:IsNotifyMatch(notify)
    return true
end

function BuffViewCheckAndCastAntiSkill:PlayView(TT, notify)
    ---@type BuffResultCheckAndCastAntiSkill
    local result = self._buffResult
    local entityID = result:GetEntityID()
    local resultBuffSeq = result:GetBuffSeq()
    local skillResult = result:GetSkillResult()
    local skillID = result:GetSkillID()

    --释放技能前刷新一次
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)

    -- local targetEntity = self._entity

    -- ---@type PlayBuffService
    -- local playBuffService = self._world:GetService("PlayBuff")

    -- ---@type BuffViewComponent
    -- local buffViewComponent = targetEntity:BuffView()
    -- if buffViewComponent then
    --     local viewIns = buffViewComponent:GetBuffViewInstanceArray()
    --     for _, inst in ipairs(viewIns) do
    --         local nuffSeq = inst:BuffSeq()
    --         if table.intable(resultBuffSeq, nuffSeq) then
    --             playBuffService:PlayAddBuff(TT, inst, targetEntity:GetID())
    --         end
    --     end
    -- end

    if skillID then
        --需要放技能的
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID, 0)

        local skillHolder = self._entity

        skillHolder:SkillRoutine():SetResultContainer(skillResult)

        local playSkillSvc = self._world:GetService("PlaySkill")
        local configSvc = self._world:GetService("Config")
        local skillConfigData = configSvc:GetSkillConfigData(skillID)
        local skillPhaseArray = skillConfigData:GetSkillPhaseArray()
        playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, skillID)
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateAntiActiveSkill, entityID)
end
