---@class UISimpleTransitionComponent:UIComponent
_class( "UISimpleTransitionComponent", UIComponent )


function UISimpleTransitionComponent:Constructor()
    self._fadeTime = 1 / 3
    
    self._moveTime = 1 / 2
    self._moveDistance = 50
end

function UISimpleTransitionComponent:AfterShow(TT)
    self:PlayEnterAnim(TT)
end
function UISimpleTransitionComponent:BeforeHide(TT)
    self:PlayLeaveAnim(TT)
end

---@private
function UISimpleTransitionComponent:PlayEnterAnim(TT)
    local safeAreaNode = self.uiController:GetGameObject().transform:Find("UICanvas/SafeArea")
    if not safeAreaNode then
        return
    end

    local canvasGroup = safeAreaNode.gameObject:GetComponent(typeof(UnityEngine.CanvasGroup))
    if not canvasGroup then
        canvasGroup = safeAreaNode.gameObject:AddComponent(typeof(UnityEngine.CanvasGroup))
    end

    self._safeAreaNode = safeAreaNode
    self._canvasGroup = canvasGroup

    self._canvasGroup.alpha = 0
    self._canvasGroup:DOFade(1, self._fadeTime)

    self._safeAreaNode.localPosition = Vector3(0, -self._moveDistance, 0)
    self._safeAreaNode:DOLocalMoveY(0, self._moveTime):SetEase(DG.Tweening.Ease.OutCirc)

    YIELD(TT, self._moveTime * 1000)
end
---@private
function UISimpleTransitionComponent:PlayLeaveAnim(TT)
    if not self._canvasGroup then
        return
    end

    self._canvasGroup:DOFade(0, self._fadeTime)
    YIELD(TT, self._fadeTime * 1000)
end