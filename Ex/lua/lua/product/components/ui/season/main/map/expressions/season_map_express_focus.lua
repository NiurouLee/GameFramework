---@class SeasonMapExpressFocus:SeasonMapExpressBase
_class("SeasonMapExpressFocus", SeasonMapExpressBase)
SeasonMapExpressFocus = SeasonMapExpressFocus

function SeasonMapExpressFocus:Constructor(cfg, eventPoint)
    self._content = self._cfg.Focus
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonCameraBase
    self._seasonCamera = self._seasonManager:SeasonCameraManager():SeasonCamera()
    ---@type SeasonExpressFocusType
    self._focusType = SeasonExpressFocusType.Center
end

function SeasonMapExpressFocus:Update(deltaTime)
    if self._state == SeasonExpressState.Playing then
        if self._targetPosition then
            if self._focusType == SeasonExpressFocusType.Left then
                self._targetPosition.x = self._rawTargetPositionX - self:GetFocusOffsetX()
            elseif self._focusType == SeasonExpressFocusType.Right then
                self._targetPosition.x = self._rawTargetPositionX + self:GetFocusOffsetX()
            end
            local p1 = self._seasonCamera:ConstraintPosition(self._targetPosition)
            local p2 = Vector3(self._seasonCamera:Position().x, self._targetPosition.y, self._seasonCamera:Position().z)
            if Vector3.Distance(p1, p2) <= 0.01 then
                local isDone = true
                if self._sizeScale then
                    if Mathf.Abs(self._seasonCamera:Size() - self._seasonCamera:GetSize()) > 0.01 then
                        isDone = false
                    end
                end
                if isDone then
                    self._targetPosition = nil
                    self._state = SeasonExpressState.Over
                    self:_Next()
                    self._seasonManager:UnLock("focus")
                end
            else
                self._seasonCamera:SetPosition(self._targetPosition)
            end
        end
    end
end

function SeasonMapExpressFocus:Dispose()
end

--播放表现内容
function SeasonMapExpressFocus:Play(param)
    SeasonMapExpressFocus.super.Play(self, param)
    if self._content then
        ---@type SeasonExpressFocusObjType
        local focusObjType = self._content.type
        local value = self._content.value
        self._focusType = self._content.focusType or SeasonExpressFocusType.Center
        self._sizeScale = self._content.sizeScale
        self._targetPosition = nil
        if focusObjType == SeasonExpressFocusObjType.Player then
            ---@type SeasonPlayer
            local player = self._seasonManager:SeasonPlayerManager():GetPlayer()
            self._targetPosition = Vector3(player:Position().x, 0, player:Position().z)
        elseif focusObjType == SeasonExpressFocusObjType.EventPoint then
            local eventPoint = self._seasonManager:SeasonMapManager():GetEventPoint(value)
            if eventPoint then
                self._targetPosition = Vector3(eventPoint:Position().x, 0, eventPoint:Position().z)
            end
        elseif focusObjType == SeasonExpressFocusObjType.Position then
            self._targetPosition = Vector3(value.x, 0, value.z)
        end
        if self._targetPosition then
            self._rawTargetPositionX = self._targetPosition.x
            self._seasonCamera:Focus(self._targetPosition)
            if self._sizeScale then
                self._seasonCamera:SetRecordSize(self._seasonCamera:Size())
                self._seasonCamera:SetSize(self._seasonCamera:MinSize())
            end
            self._state = SeasonExpressState.Playing
            self._seasonManager:Lock("focus")
        else
            self._state = SeasonExpressState.Over
            self:_Next()
        end
    end
end

---聚焦偏移量
function SeasonMapExpressFocus:GetFocusOffsetX()
    local camera = self._seasonCamera:Camera()
    local aspect = camera.aspect
    local size = camera.orthographicSize
    local cameraWidth = size * aspect
    local bangWidth = ResolutionManager.BangWidth()
    local blackWidth = ResolutionManager.BlackWidth()
    local width = bangWidth + blackWidth
    width = UnityEngine.Screen.width - width * 2
    local percent = ((width / 2) - ((width - 694) / 2)) / width
    return percent * cameraWidth * 2
end