--
---@class UISeasonBubble : UIController
_class("UISeasonBubble", UIController)
UISeasonBubble = UISeasonBubble

---@param res AsyncRequestRes
function UISeasonBubble:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

function UISeasonBubble:OnShow(uiParams)
    self._bubbles = uiParams[1]
    self._callBack = uiParams[2]
    self._index = 1
    self:_GetComponents()
    self:_OnValue()
end

function UISeasonBubble:_GetComponents()
    ---@type UnityEngine.Animation
    self._animation = self:GetUIComponent("Animation", "Animation")
    ---@type UnityEngine.RectTransform
    self._dialogRect = self:GetUIComponent("RectTransform", "Dialog")
    ---@type UILocalizationText
    self._content = self:GetUIComponent("UILocalizationText", "Content")
end

function UISeasonBubble:_OnValue()
    ---@type SeasonManager
    local mgr = self:GetUIModule(SeasonModule):SeasonManager()
    ---@type SeasonPlayer
    local player = mgr:SeasonPlayerManager():GetPlayer()
    ---@type UnityEngine.Camera
    local camera = mgr:SeasonCameraManager():Camera()
    local point = camera:WorldToScreenPoint(player:Position())
    local res, pos = UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._dialogRect.parent.parent,
    point,
    GameGlobal.UIStateManager():GetControllerCamera("UISeasonBubble"),
    nil)
    self._dialogRect.anchoredPosition = Vector2(pos.x, pos.y + 120)
    self:_RefershText()
end

function UISeasonBubble:_RefershText()
    local str = self._bubbles[self._index]
    if str then
        self._content:SetText(StringTable.Get(str))
    end
end

function UISeasonBubble:NextBtnOnClick(go)
    self._index = self._index + 1
    if self._index <= #self._bubbles then
        self:_RefershText()
    else
        self:Close()
    end
end

function UISeasonBubble:Close()
    self:Lock("UISeasonBubbleClose")
    self:StartTask(
        function (TT)
            self._animation:Play("uianim_UISeasonBubble_out")
            YIELD(TT, 500)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UISeasonBubble)
            self:CloseDialog()
            if self._callBack then
                self._callBack{}
            end
            self:UnLock("UISeasonBubbleClose")
        end
    )
end