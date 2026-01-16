require("base_ins_r")
---P5合击技表现专用 特效之上的对话框ui
---UI打开时将UICanvas的camera指向特效里附带的uicamera
---@class PlayShowPersonaTopUiInstruction: BaseInstruction
_class("PlayShowPersonaTopUiInstruction", BaseInstruction)
PlayShowPersonaTopUiInstruction = PlayShowPersonaTopUiInstruction

function PlayShowPersonaTopUiInstruction:Constructor(paramList)
    self._show = tonumber(paramList["show"])
    self._tarCamera = paramList["tarCamera"]
    self._petHead = paramList["petHead"]
    self._petWord = paramList["petWord"]
    self._animName = paramList["anim"]
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayShowPersonaTopUiInstruction:DoInstruction(TT, casterEntity, phaseContext)
    if self._show and (self._show == 1) then
        local effCam = nil
        if self._tarCamera then
            local camera1 = UnityEngine.GameObject.Find(self._tarCamera)
            if camera1 then
                effCam = camera1:GetComponent("Camera")
            end
        end
        GameGlobal.UIStateManager():ShowDialog("UIBattlePersonaSkillEffTop",effCam,self._petHead,self._petWord,false,self._animName)
    else
        GameGlobal.UIStateManager():CloseDialog("UIBattlePersonaSkillEffTop")
    end
end
