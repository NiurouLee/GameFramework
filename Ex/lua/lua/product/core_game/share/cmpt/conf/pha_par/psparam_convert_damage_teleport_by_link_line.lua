--[[------------------------------------------------------------------------------------------
    ConvertDamageTeleportByLinkLine = 99, --蒂娜主动技表现
]]
--------------------------------------------------------------------------------------------
require "skill_phase_param_base"

---@class SkillPhaseConvertDamageTeleportByLinkLineParam: SkillPhaseParamBase
_class("SkillPhaseConvertDamageTeleportByLinkLineParam", SkillPhaseParamBase)
SkillPhaseConvertDamageTeleportByLinkLineParam = SkillPhaseConvertDamageTeleportByLinkLineParam

function SkillPhaseConvertDamageTeleportByLinkLineParam:Constructor(t)
    self._cameraEffID = t.cameraEffID
    self._cameraEffAnimOut = t.cameraEffAnimOut

    self._sceneEffID = t.sceneEffID
    self._sceneEffPos = Vector2.zero
    if t.sceneEffPos then
        self._sceneEffPos = Vector2(t.sceneEffPos.x, t.sceneEffPos.y)
    end
    self._sceneEffAnimIn = t.sceneEffAnimIn
    self._sceneEffAnimIdle = t.sceneEffAnimIdle
    self._sceneEffAnimOut = t.sceneEffAnimOut
    self._startAudioID = t.startAudioID

    self._convertEffID = t.convertEffID
    self._convertEffAnimOut = t.convertEffAnimOut
    self._convertAudioID = t.convertAudioID

    self._beginDelayTime = t.beginDelayTime
    self._moveSpeedTime = t.moveSpeedTime
    self._moveAnim = t.moveAnim
    self._moveTrailEffect = t.moveTrailEffect

    self._teleportDelayTime = t.teleportDelayTime
    self._teleportAudioID = t.teleportAudioID
    self._disappearEffID = t.disappearEffID
    self._disappearTime = t.disappearTime
    self._appearEffID = t.appearEffID
    self._appearDelayTime = t.appearDelayTime

    self._attackAnim = t.attackAnim
    self._attackAudioID = t.attackAudioID
    self._gatherEffIDList = t.gatherEffIDList or {}
    self._attackEffID = t.attackEffID
    self._attackEffDelayTime = t.attackEffDelayTime
    self._attackEffTime = t.attackEffTime

    self._hitAnim = t.hitAnim
    self._hitDelayTime = t.hitDelayTime

    self._sceneOutDelayTime = t.sceneOutDelayTime
    self._endDelayTime = t.endDelayTime
end

--
function SkillPhaseConvertDamageTeleportByLinkLineParam:GetCacheTable()
    local t = {}
    if self._cameraEffID and self._cameraEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._cameraEffID].ResPath, 1 })
    end
    if self._sceneEffID and self._sceneEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._sceneEffID].ResPath, 1 })
    end
    if self._convertEffID and self._convertEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._convertEffID].ResPath, 2 })
    end
    if self._disappearEffID and self._disappearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._disappearEffID].ResPath, 1 })
    end
    if #self._gatherEffIDList > 0 then
        for _, value in ipairs(self._gatherEffIDList) do
            if value and value > 0 then
                table.insert(t, { Cfg.cfg_effect[value].ResPath, 1 })
            end
        end
    end
    if self._appearEffID and self._appearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._appearEffID].ResPath, 1 })
    end
    if self._attackEffID and self._attackEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._attackEffID].ResPath, 1 })
    end
    return t
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetCacheAudio()
    local t = {}

    if self._startAudioID and self._startAudioID > 0 then
        table.insert(t, self._startAudioID)
    end

    if self._convertAudioID and self._convertAudioID > 0 then
        table.insert(t, self._convertAudioID)
    end

    if self._teleportAudioID and self._teleportAudioID > 0 then
        table.insert(t, self._teleportAudioID)
    end

    if self._attackAudioID and self._attackAudioID > 0 then
        table.insert(t, self._attackAudioID)
    end

    return t
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetPhaseType()
    return SkillViewPhaseType.ConvertDamageTeleportByLinkLine
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetCameraEffID()
    return self._cameraEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetCameraEffAnimOut()
    return self._cameraEffAnimOut
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneEffID()
    return self._sceneEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneEffPos()
    return self._sceneEffPos
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneEffAnimIn()
    return self._sceneEffAnimIn
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneEffAnimIdle()
    return self._sceneEffAnimIdle
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneEffAnimOut()
    return self._sceneEffAnimOut
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetStartAudioID()
    return self._startAudioID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetConvertEffID()
    return self._convertEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetConvertEffAnimOut()
    return self._convertEffAnimOut
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetConvertAudioID()
    return self._convertAudioID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetBeginDelayTime()
    return self._beginDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetMoveSpeedTime()
    return self._moveSpeedTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetMoveAnim()
    return self._moveAnim
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetMoveTrailEffect()
    return self._moveTrailEffect
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetTeleportDelayTime()
    return self._teleportDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetTeleportAudioID()
    return self._teleportAudioID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetDisappearEffID()
    return self._disappearEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetDisappearTime()
    return self._disappearTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAppearEffID()
    return self._appearEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAppearDelayTime()
    return self._appearDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAttackAnim()
    return self._attackAnim
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAttackAudioID()
    return self._attackAudioID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetGatherEffIDList()
    return self._gatherEffIDList
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAttackEffID()
    return self._attackEffID
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAttackEffDelayTime()
    return self._attackEffDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetHitAnim()
    return self._hitAnim
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetHitDelayTime()
    return self._hitDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetAttackEffTime()
    return self._attackEffTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetSceneOutDelayTime()
    return self._sceneOutDelayTime
end

function SkillPhaseConvertDamageTeleportByLinkLineParam:GetEndDelayTime()
    return self._endDelayTime
end
