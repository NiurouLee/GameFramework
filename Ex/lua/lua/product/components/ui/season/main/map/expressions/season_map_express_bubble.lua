---@class SeasonMapExpressBubble:SeasonMapExpressBase
_class("SeasonMapExpressBubble", SeasonMapExpressBase)
SeasonMapExpressBubble = SeasonMapExpressBubble

function SeasonMapExpressBubble:Constructor(cfg, eventPoint)
    self._content = self._cfg.Bubble
end

function SeasonMapExpressBubble:Update(deltaTime)
    
end

function SeasonMapExpressBubble:Dispose()
end

--播放表现内容
function SeasonMapExpressBubble:Play(param)
    SeasonMapExpressBubble.super.Play(self, param)
    if self._content then
        self._state = SeasonExpressState.Playing
        local topui = GameGlobal.UIStateManager():IsTopUI("UISeasonMain")
        if topui then
            self:_OnCallBack()
        else
            self._callBack = GameHelper:GetInstance():CreateCallback(self._OnCallBack, self)
            GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.SeasonTryShowEventBubble, self._callBack)
            ---@type UISeasonModule
            local uiSeasonModule = GameGlobal.GetUIModule(SeasonModule)
            uiSeasonModule:AppendWaitShowBubbleCallback(self._callBack)
        end
    end
end
function SeasonMapExpressBubble:_OnCallBack()
    GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.SeasonTryShowEventBubble, self._callBack)
    GameGlobal.UIStateManager():ShowDialog(
            "UISeasonBubble",
            self._content,
            function()
                self._state = SeasonExpressState.Over
                self:_Next()
            end
        )
end

