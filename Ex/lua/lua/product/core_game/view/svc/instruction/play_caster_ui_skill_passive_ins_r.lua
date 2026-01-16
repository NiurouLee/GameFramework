require("base_ins_r")
---处理星灵头像上的被动标志
---@class PlayCasterUISkillPassiveInstruction: BaseInstruction
_class("PlayCasterUISkillPassiveInstruction", BaseInstruction)
PlayCasterUISkillPassiveInstruction = PlayCasterUISkillPassiveInstruction

function PlayCasterUISkillPassiveInstruction:Constructor(paramList)
    self._active = tonumber(paramList["active"])
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCasterUISkillPassiveInstruction:DoInstruction(TT, casterEntity, phaseContext)
    --幻象小怪会使用星灵的普攻表现 但是没有pst组件就返回
    if not casterEntity:PetPstID() then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.ActivatePassive,
        casterEntity:PetPstID():GetPstID(),
        self._active == 1
    )
end
