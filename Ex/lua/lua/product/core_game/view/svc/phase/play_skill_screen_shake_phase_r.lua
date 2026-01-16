require "play_skill_phase_base_r"
--@class PlaySkillScreenShakePhase: Object
_class("PlaySkillScreenShakePhase", PlaySkillPhaseBase)
PlaySkillScreenShakePhase = PlaySkillScreenShakePhase

function PlaySkillScreenShakePhase:PlayFlight(TT, casterEntity, phaseParam)
    --Log.fatal("_PlayScreenShakePhase")
    ---@type SkillPhaseScreenShakeParam
    local screenShakePhaseParam = phaseParam
    ---@type CameraService
    local cameraService = self._world:GetService("Camera")
    local cameraShakeParam =
        CameraShakeParams:New(
        screenShakePhaseParam:GetDelay(),
        screenShakePhaseParam:GetIntensity(),
        screenShakePhaseParam:GetMainVibAngle(),
        screenShakePhaseParam:GetDuration(),
        screenShakePhaseParam:GetVibrato(),
        screenShakePhaseParam:GetDecayRate(),
        screenShakePhaseParam:GetAngleRandomness(),
        screenShakePhaseParam:GetIntenseRandomness()
    )
    cameraService:PlayCameraShake(cameraShakeParam)
end
