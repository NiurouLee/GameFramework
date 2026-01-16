---@class UIPetSkinsGetCgController : UIController
_class("UIPetSkinsGetCgController", UIController)
UIPetSkinsGetCgController = UIPetSkinsGetCgController
function UIPetSkinsGetCgController:Constructor()
end

function UIPetSkinsGetCgController:OnShow(uiParams)
    --预览模式
    self._viewing = false
    self._first = uiParams[2] or false
    if self._first then
        local tips = StringTable.Get("str_pet_skin_get_cg_tips")
        ToastManager.ShowToast(tips)
    end

    local picName = uiParams[1]
    if not picName then
        Log.error("###[UIPetSkinsGetCgController] picName is nil !")
    end

    self._viewBtnGo = self:GetGameObject("viewBtn")
    self._closeTipGo = self:GetGameObject("closeTipGo")
    self._cg = self:GetUIComponent("RawImageLoader", "cg")
    self._cg:LoadImage(picName)
    self._cgGo = self:GetGameObject("cg")
    self:SetCgWidth()

    if self._first then
        GameGlobal.Timer():AddEvent(
            1000,
            function()
                self._cgGo:SetActive(true)
            end
        )
    else
        self._cgGo:SetActive(true)
    end

    self._scaleRoot = self:GetUIComponent("Transform", "scale")
    ---@type UnityEngine.RectTransform
    self._rect = self:GetUIComponent("RectTransform", "root")

    --缩放系数
    self._scaleK = 0.2
    self._touchScaleK = 0.001

    --缩放限制
    self._scaleMax = 1.5
    self._scaleMin = 0.5

    --移动系数
    self._moveK = 1
    --移动限制
    self._moveMaxX = 1000
    self._moveMinX = -1000
    self._moveMaxY = 500
    self._moveMinY = -500

    --计算鼠标移动位置
    self._mousePos2 = 0
    self._mousePos = 0

    --动作
    self._scaling = false
    self._draging = false

    --手指移动位置
    self._touch0Pos = 0
    self._touch0Pos2 = 0

    --手指间距
    self._touchDis = 0
    self._touchDis2 = 0
    --算移动
    local pixels = Cfg.cfg_aircraft_camera["clickAndDragPixelLength"].Value
    self._startMove = pixels * pixels
    self:Init()
end

function UIPetSkinsGetCgController:SetCgWidth()
    local r_w = ResolutionManager.RealWidth()
    local b_w = ResolutionManager.BlackWidth()
    local currentWidth = r_w - b_w * 2
    local cgRect = self:GetUIComponent("RectTransform", "cg")
    cgRect.sizeDelta = Vector2(currentWidth, cgRect.sizeDelta.y)
end
function UIPetSkinsGetCgController:Init()
    self._mousePresent = GameGlobal.EngineInput().mousePresent
    UnityEngine.Input.multiTouchEnabled = true
end
function UIPetSkinsGetCgController:OnHide()
    self._mousePresent = nil
    UnityEngine.Input.multiTouchEnabled = false
end

function UIPetSkinsGetCgController:bgOnClick(go)
    if self._draging then
        return
    end
    if self._scaling then
        return
    end

    if self._viewing then
        self._viewing = false
        self:SetViewState()
    else
        if self._first then
            self:Lock("UIPetSkinsGetCgController:cgOnClick")
            self:ShowDialog(
                "UIAircraftUnlockFileController",
                StringTable.Get("str_aircraft_review_story"),
                StringTable.Get("str_aircraft_review_story_en")
            )
            self._cgGo:SetActive(false)
            GameGlobal.Timer():AddEvent(
                3000,
                function()
                    GameGlobal.UIStateManager():CloseDialog("UIAircraftUnlockFileController")
                    self:UnLock("UIPetSkinsGetCgController:cgOnClick")
                    self:CloseDialog()
                end
            )
        else
            self:CloseDialog()
        end
    end
end

function UIPetSkinsGetCgController:SetViewState()
    self._closeTipGo:SetActive(not self._viewing)
    self._viewBtnGo:SetActive(not self._viewing)
end

function UIPetSkinsGetCgController:viewBtnOnClick(go)
    self._viewing = true
    self:SetViewState()
end

--防止触发点击bg事件，在ondown时候打开遮罩，up时候去掉
function UIPetSkinsGetCgController:Update(deltaTimeMS)
    if self._viewing then
        if self._mousePresent then
            self:EditorInput(deltaTimeMS / 1000)
        else
            self:TouchInput(deltaTimeMS / 1000)
        end
    end
end

function UIPetSkinsGetCgController:TouchInput(deltaTime)
    local touchCount = GameGlobal.EngineInput().touchCount
    local touch0 = nil
    if touchCount > 0 then
        touch0 = GameGlobal.EngineInput().GetTouch(0)
    end
    local touch1 = nil
    if touchCount > 1 then
        touch1 = GameGlobal.EngineInput().GetTouch(1)
    end

    if touch0 and touch0.phase == TouchPhase.Began then
        self._touch0DownPos = touch0.position
    end

    --移动
    if not touch1 then
        if touch0 and touch0.phase == TouchPhase.Moved then
            self._touch0Pos = touch0.position
            if self._touch0Pos2 ~= 0 then
                if self._draging == false and self._touch0DownPos then
                    if (self._touch0Pos - self._touch0DownPos).sqrMagnitude > self._startMove then
                        self._draging = true
                    end
                end

                local offset = self._touch0Pos - self._touch0Pos2
                self._moveGap = offset * self._moveK
                local targetPos = self._rect.anchoredPosition + Vector2(self._moveGap.x, self._moveGap.y)
                if targetPos.x < self._moveMaxX and targetPos.x > self._moveMinX then
                    self._rect.anchoredPosition = Vector2(targetPos.x, self._rect.anchoredPosition.y)
                end
                if targetPos.y < self._moveMaxY and targetPos.y > self._moveMinY then
                    self._rect.anchoredPosition = Vector2(self._rect.anchoredPosition.x, targetPos.y)
                end
            end
            self._touch0Pos2 = self._touch0Pos
        end
    end

    if touchCount == 0 then
        self._draging = false
        self._scaling = false

        self._touchDis = 0
        self._touchDis2 = 0
        self._touchDownDis = 0

        self._touch0Pos = 0
        self._touch0Pos2 = 0
    end

    --缩放
    if touch1 then
        self._scaling = true
        local lastLength =
            Vector2.Distance(touch0.position - touch0.deltaPosition, touch1.position - touch1.deltaPosition)
        local length = Vector2.Distance(touch0.position, touch1.position)
        local offset = length - lastLength
        self._scaleValue = offset * self._touchScaleK
        local targetScale = self._scaleRoot.localScale + Vector3(self._scaleValue, self._scaleValue, self._scaleValue)
        if targetScale.x < self._scaleMax and targetScale.x > self._scaleMin then
            self._scaleRoot.localScale = targetScale
        end
    end
end

function UIPetSkinsGetCgController:EditorInput(deltaTime)
    if GameGlobal.EngineInput().GetMouseButtonDown(0) then
        self._mousePos2 = 0
        self._mousePos = 0
        self._mouseDpwnPos = GameGlobal.EngineInput().mousePosition
    end

    --移动
    if GameGlobal.EngineInput().GetMouseButton(0) then
        self._mousePos = GameGlobal.EngineInput().mousePosition
        if self._mousePos2 ~= 0 then
            if self._draging == false then
                if (self._mousePos - self._mouseDpwnPos).sqrMagnitude > self._startMove then
                    self._draging = true
                end
            end

            local offset = self._mousePos - self._mousePos2
            self._moveGap = offset * self._moveK
            local targetPos = self._rect.anchoredPosition + Vector2(self._moveGap.x, self._moveGap.y)
            if targetPos.x < self._moveMaxX and targetPos.x > self._moveMinX then
                self._rect.anchoredPosition = Vector2(targetPos.x, self._rect.anchoredPosition.y)
            end
            if targetPos.y < self._moveMaxY and targetPos.y > self._moveMinY then
                self._rect.anchoredPosition = Vector2(self._rect.anchoredPosition.x, targetPos.y)
            end
        end
        self._mousePos2 = self._mousePos
    end

    --缩放
    self._scaleLength = GameGlobal.EngineInput().GetAxis("Mouse ScrollWheel")
    if self._scaleLength > 0 or self._scaleLength < 0 then
        local gap = self._scaleLength * self._scaleK
        local targetScale = self._scaleRoot.localScale + Vector3(gap, gap, gap)
        if targetScale.x < self._scaleMax and targetScale.x > self._scaleMin then
            self._scaleRoot.localScale = targetScale
        end
    end

    if GameGlobal.EngineInput().GetMouseButtonUp(0) then
        self._mousePos2 = 0
        self._mousePos = 0
        if self._draging then
            self._draging = false
        end
    end
end
