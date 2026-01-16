--[[
    @新手引导 弹窗类对话引导
]]
---@class UIGuidePopController:UIController
_class("UIGuidePopController", UIController)
UIGuidePopController = UIGuidePopController

function UIGuidePopController:Constructor()
end

function UIGuidePopController:OnShow(uiParams)
    GuideHelper.GuideLoadLock(false, "Pop")
    self.anim = self:GetGameObject().transform:GetComponent("Animation")
    self.anim:Play("uieff_uiGuidePop_In")
    self:StartTask(
        function(TT)
            YIELD(TT, 1000)
            self.anim:Play("uieff_uiGuidePop_HangOn")
        end
    )
    self.titleTxt = self:GetUIComponent("UILocalizationText", "title")
    -- self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    self.extraTxt = self:GetUIComponent("UILocalizationText", "extra")
    self.btnTxt = self:GetUIComponent("UILocalizationText", "btntxt")
    self.btnTxt:SetText(StringTable.Get("str_guide_pop_close"))

    -- self.btn = self:GetUIComponent("Button", "btnclose")
    self.btnGO = self:GetGameObject("btnclose")
    -- self.btnImage = self:GetUIComponent("Image", "btnclose")
    self.uiWeakKuang = self:GetGameObject("UIWeakKuang")
    self.uiWeakKuang:SetActive(false)

    self.id = uiParams[1].guideParam
    self.data = uiParams[1].data
    self:Refresh()
    --暂停bgm
    -- AudioManager.Instance:PauseBGM()

    local url = ResourceManager:GetInstance():GetAssetPath(self.cfg.movie .. ".mp4", LoadType.VideoClip)
    
    Log.debug("[guide movie] move url ", url)

    ---@type UnityEngine.Video.VideoPlayer
    self._vp = self:GetUIComponent("VideoPlayer", "VideoPlayer")
    self._vp.gameObject:SetActive(true)
    self._vp.url = url
    self._vp.targetCamera = GameGlobal.UIStateManager():GetControllerCamera("UIGuidePopController")
    self._vp:Play()
    self._vp.loopPointReached = self._vp.loopPointReached + self._LoopPointReached
end
function UIGuidePopController:_LoopPointReached()
    local controller = GameGlobal.UIStateManager():GetController("UIGuidePopController")
    if controller then
        controller._vp:Stop()
        controller._vp:Play()
    end
end
-- body
function UIGuidePopController:Refresh()
    self.cfg = Cfg.cfg_guide_pop[self.id]
    self.titleTxt:SetText(StringTable.Get(self.cfg.title))
    self.descTxt:SetText(StringTable.Get(self.cfg.desc))
    self.extraTxt:SetText(StringTable.Get(self.cfg.extra))
    -- self.btn.enabled = false
    -- self.btnImage.color = Color.gray
    self.btnGO:SetActive(false)
    self.time = 0
end

function UIGuidePopController:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Pop)
    self._vp.loopPointReached = self._vp.loopPointReached - self._LoopPointReached
    --继续bgm
    -- AudioManager.Instance:UnpauseBGM()
end

function UIGuidePopController:OnUpdate(deltaTimeMS)
    if self.time == nil then
        return
    end
    self.time = self.time + deltaTimeMS
    -- if not self.btnEnable then
    --     local second = 3 - math.floor(self.time / 1000)
    -- end
    if self.time >= 3000 then
        -- self.btnImage.color = Color.white
        self.btnGO:SetActive(true)
    -- self.btn.enabled = true
    -- self.btnEnable = true
    end
    if self.time >= 5000 then
        self.uiWeakKuang:SetActive(true)
    end
end

function UIGuidePopController:btncloseOnClick(go)
    -- if self.btnEnable then
    GameGlobal.UAReportForceGuideEvent("GuideStepClick",{
         self.data.guide or -1,
         self.data.step or -1,
         self.data.step
        })
    self.anim:Play("uieff_uiGuidePop_Out")
    self:StartTask(
        function(TT)
            YIELD(TT, 500)
            self:CloseDialog()
        end
    )
    -- end
end
