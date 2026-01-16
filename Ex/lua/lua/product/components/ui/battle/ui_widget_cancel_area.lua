---@class UIWidgetCancelArea : UICustomWidget
_class("UIWidgetCancelArea", UICustomWidget)
UIWidgetCancelArea = UIWidgetCancelArea

function UIWidgetCancelArea:OnShow()
    ---@type UnityEngine.GameObject
    self._cancelArea = self:GetGameObject("CancelArea")

    ---基类UICustomWidget的Hide方法会自动remove掉这个listener
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._cancelArea),
        UIEvent.Hovered,
        function(go)
            self:OnEnterCancelArea(go)
        end
    )
    self:AttachEvent(GameEventType.ApplicationFocus, self.OnApplicationFocus)
    self:AttachEvent(GameEventType.ShowChainPathCancelArea, self.OnShowChainPathCancelArea)
    self:AttachEvent(GameEventType.HideChainPathCancelArea, self.OnHideChainPathCancelArea)
end

function UIWidgetCancelArea:OnHide()
    Log.notice("cancel hide")
end

function UIWidgetCancelArea:OnEnterCancelArea()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIBattle", input = "OnEnterCancelArea", args = {} }
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.CancelChainPath)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Button)
    self:OnHideChainPathCancelArea()
end

function UIWidgetCancelArea:OnShowChainPathCancelArea()
    --自动战斗不显示取消连线的面板
    if BattleStatHelper.GetAutoFightStat() then
        return
    end
    self._cancelArea:SetActive(true)
end

function UIWidgetCancelArea:OnHideChainPathCancelArea()
    self._cancelArea:SetActive(false)
end

function UIWidgetCancelArea:OnApplicationFocus(isFocus)
    --if EDITOR then
    --	return
    --end
    if not GameGlobal:GetInstance():IsCoreGameRunning() then
        return
    end
    if isFocus then
    else
        if GameGlobal:GetInstance():IsLinkLineState() then
            self:OnEnterCancelArea()
        end
    end
end