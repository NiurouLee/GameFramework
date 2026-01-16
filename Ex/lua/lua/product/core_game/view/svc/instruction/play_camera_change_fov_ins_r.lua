require("base_ins_r")
---@class PlayCameraChangeFovInstruction: BaseInstruction
_class("PlayCameraChangeFovInstruction", BaseInstruction)
PlayCameraChangeFovInstruction = PlayCameraChangeFovInstruction

function PlayCameraChangeFovInstruction:Constructor(paramList)
    self._time = tonumber(paramList["time"])
    self._fov = tonumber(paramList["fov"])
    self._block = tonumber(paramList["block"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayCameraChangeFovInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()
    --获取摄像机
    local mainCamera = world:MainCamera():Camera()
    --移动摄像机
    local cameraTran = mainCamera.transform
    local curFieldOfView = mainCamera.fieldOfView

    local startTime = GameGlobal:GetInstance():GetCurrentTime()

    self._timerHandler =
        GameGlobal.Timer():AddEventTimes(
        0,
        TimerTriggerCount.Infinite,
        function()
            local curTime = GameGlobal:GetInstance():GetCurrentTime()
            local percent = (curTime - startTime) / self._time
            if curTime - startTime >= self._time then
                percent = 1
                if self._timerHandler then
                    GameGlobal.Timer():CancelEvent(self._timerHandler)
                    self._timerHandler = nil
                end
            end

            local fov = DG.Tweening.DOVirtual.EasedValue(curFieldOfView, self._fov, percent, DG.Tweening.Ease.Linear)

            mainCamera.fieldOfView = fov
        end
    )

    if self._block == 1 then
        YIELD(TT, self._time)
    end
end
