--[[
    按回合锁血
]]
---@class ChangeMonsterPreviewSkillType
local ChangeMonsterPreviewSkillType = {
    Notify = 1, ---上一回合触发怪物锁血
}
_enum("ChangeMonsterPreviewSkillType",ChangeMonsterPreviewSkillType)


_class("BuffLogicChangeMonsterPreviewSkill", BuffLogicBase)
---@class BuffLogicChangeMonsterPreviewSkill:BuffLogicBase
BuffLogicChangeMonsterPreviewSkill = BuffLogicChangeMonsterPreviewSkill
function BuffLogicChangeMonsterPreviewSkill:Constructor(buffInstance, logicParam)
    self._targetSkillID = logicParam.targetSkillID
    self._type = logicParam.type
end

function BuffLogicChangeMonsterPreviewSkill:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    if e:HasMonsterID() then
        ---@type AIComponentNew
        local aiCpmt = e:AI()
        local needReplace = false
        if self._type == ChangeMonsterPreviewSkillType.Notify then
            needReplace = true
        end
        if needReplace then
            aiCpmt:SetReplacePreviewSkillID(self._targetSkillID)
        end
    end
end

_class("BuffLogicResetChangePreviewSkill", BuffLogicBase)
---@class BuffLogicResetChangePreviewSkill:BuffLogicBase
BuffLogicResetChangePreviewSkill = BuffLogicResetChangePreviewSkill

function BuffLogicResetChangePreviewSkill:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    if e:HasMonsterID() then
        ---@type AIComponentNew
        local aiCpmt = e:AI()
        aiCpmt:ResetReplacePreviewSkillID()
    end
end

