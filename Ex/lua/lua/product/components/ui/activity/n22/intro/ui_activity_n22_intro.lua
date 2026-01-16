--活动说明有通用界面，N11 单独处理
---@class UIActivityN22Intro:UIController
_class("UIActivityN22Intro", UIController)
UIActivityN22Intro = UIActivityN22Intro

function UIActivityN22Intro:OnShow(uiParams)
    self._param = uiParams[1] or "nil"
    self._cfg = Cfg.cfg_activityintro[self._param]
    if self._cfg == nil then
        Log.fatal("###[UIActivityN22Intro] self._cfg is nil. param --> ", self._param)
    end
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "anim")
    ---@type UICustomWidgetPool
    self.Content = self:GetUIComponent("UILocalizationText", "Content")
    self._TitleText = self:GetUIComponent("UILocalizationText", "txtTitle")

    self:Flush()

    self:_PlayAnim(
           "uieff_UIN22Intro_in",
            500,
            function()
               -- self:_CheckGuide()
            end
        )
   
end

function UIActivityN22Intro:OnHide()

end
function UIActivityN22Intro:Flush()
    --self.Content:SetText(StringTable.Get(self._cfg.Intro))
    --self._TitleText:SetText(StringTable.Get(self._cfg.Title))
end

--region OnClick
function UIActivityN22Intro:BtnCloseOnClick(go)
    self:_PlayAnim(
        "uieff_UIN22Intro_out",
         100,
         function()
            self:CloseDialog()
         end
     )
end
function UIActivityN22Intro:BgOnClick(go)

end 
--endregion

function UIActivityN22Intro:_PlayAnim(animName, time, callback)

    self:Lock("UIActivityN22IntroAni")
    self.anim:Play(animName)
    self:StartTask(
        function(TT)
            YIELD(TT, time)
            self:UnLock("UIActivityN22IntroAni")
            if callback then
                callback()
            end
        end,
        self
    )
end
