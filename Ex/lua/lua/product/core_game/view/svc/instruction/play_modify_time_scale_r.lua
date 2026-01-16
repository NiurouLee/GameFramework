require("base_ins_r")
---@class PlayModifyTimeScaleInstruction: BaseInstruction
_class("PlayModifyTimeScaleInstruction", BaseInstruction)
PlayModifyTimeScaleInstruction = PlayModifyTimeScaleInstruction

---@class ModifyTimeScaleType
local ModifyTimeScaleType = {
    Reset = 0, ---复位成全局倍速
    SetTimeScale = 1,---设置指定timeScale
 }
 ModifyTimeScaleType = ModifyTimeScaleType
_enum("ModifyTimeScaleType", ModifyTimeScaleType)

function PlayModifyTimeScaleInstruction:Constructor(paramList)
    self._modifyType = tonumber(paramList["type"])
    if self._modifyType == ModifyTimeScaleType.SetTimeScale then
        self._timeScale = tonumber(paramList["timeScale"])
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayModifyTimeScaleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self._modifyType == ModifyTimeScaleType.Reset then 
        GameGlobal.EventDispatcher():Dispatch(GameEventType.BattleTimeSpeed, true)
    elseif self._modifyType == ModifyTimeScaleType.SetTimeScale then
        if self._timeScale then
            HelperProxy:GetInstance():SetGameTimeScale(self._timeScale)
            AudioHelperController.SetInnerGameSoundPlaySpeed(self._timeScale)
        end
    end
end
