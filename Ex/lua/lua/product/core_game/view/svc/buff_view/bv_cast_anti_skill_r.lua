--[[
    播放技能表现
]]
_class("BuffViewCastAntiSkill", BuffViewBase)
BuffViewCastAntiSkill = BuffViewCastAntiSkill



function BuffViewCastAntiSkill:PlayView(TT, notify)
    ---@type BuffResultCastAntiSkill
    local result = self._buffResult

    local skillID = result:GetSkillID()
    local startTask = result:GetStartTask()
    ---@type Entity
    local skillHolder = self._world:GetEntityByID(result:GetSkillHolderID())
    local skillResult = result:GetSkillResult()
    skillHolder:SkillRoutine():SetResultContainer(skillResult)


    local playSkillSvc = self._world:GetService("PlaySkill")
    local configSvc = self._world:GetService("Config")
    local skillConfigData = configSvc:GetSkillConfigData(skillID, skillHolder)
    local skillPhaseArray = skillConfigData:GetSkillPhaseArray()
    if startTask == 0 then
        playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, skillID)
    else
        --在buff表里配置 startTask=1 的技能不会卡传进来的TT
        GameGlobal.TaskManager():CoreGameStartTask(
                function(TT)
                    playSkillSvc:_SkillRoutineTask(TT, skillHolder, skillPhaseArray, skillID)
                end
        )
    end
end