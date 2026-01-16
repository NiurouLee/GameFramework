--[[
    @新手引导 焦点复制人
]]
---@class UIGuideCircleModelController:UIController
_class("UIGuideCircleModelController", UIController)
UIGuideCircleModelController = UIGuideCircleModelController

function UIGuideCircleModelController:Constructor()
end

function UIGuideCircleModelController:OnShow(uiParams)
    GuideHelper.GuideLoadLock(false, "Circle")
    self.canClick = false
    self.backs = {}
    for i = 1, 4 do
        local back = self:GetUIComponent("RectTransform", "Back" .. i)
        self.backs[i] = back
    end
    self.circle = self:GetUIComponent("RectTransform", "circle")
    self.animation = self:GetUIComponent("Animation", "animation")
    self.ltTitleTxt = self:GetUIComponent("UILocalizationText", "lttitle")
    self.rtTitleTxt = self:GetUIComponent("UILocalizationText", "rttitle")
    self.ldTitleTxt = self:GetUIComponent("UILocalizationText", "ldtitle")
    self.rdTitleTxt = self:GetUIComponent("UILocalizationText", "rdtitle")
    self.ltDescTxt = self:GetUIComponent("UILocalizationText", "ltdesc")
    self.rtDescTxt = self:GetUIComponent("UILocalizationText", "rtdesc")
    self.ldDescTxt = self:GetUIComponent("UILocalizationText", "lddesc")
    self.rdDescTxt = self:GetUIComponent("UILocalizationText", "rddesc")
    self.ltGO = self:GetGameObject("lt")
    self.ltGO:SetActive(false)
    self.rtGO = self:GetGameObject("rt")
    self.rtGO:SetActive(false)
    self.ldGO = self:GetGameObject("ld")
    self.ldGO:SetActive(false)
    self.rdGO = self:GetGameObject("rd")
    self.rdGO:SetActive(false)
    self.ltAllGO = self:GetGameObject("ltall")
    self.ltAllGO:SetActive(false)
    self.rtAllGO = self:GetGameObject("rtall")
    self.rtAllGO:SetActive(false)
    self.ldAllGO = self:GetGameObject("ldall")
    self.ldAllGO:SetActive(false)
    self.rdAllGO = self:GetGameObject("rdall")
    self.rdAllGO:SetActive(false)
    self.continueGO = self:GetGameObject("continue")
    self.maskGO = self:GetGameObject("mask")
    self.maskGO:SetActive(true)
    self.maskRect = self:GetUIComponent("RectTransform", "mask")
    self.continueGO:SetActive(false)

    self._l_t_txt = self:GetUIComponent("RectTransform", "ltdesc")
    self._l_d_txt = self:GetUIComponent("RectTransform", "lddesc")
    self._r_t_txt = self:GetUIComponent("RectTransform", "rtdesc")
    self._r_d_txt = self:GetUIComponent("RectTransform", "rddesc")

    self.p_black = self:GetGameObject("p_black")
    self.p_black_mask = self:GetUIComponent("RectTransform", "p_black_mask")
    ---@type UnityEngine.UI.Image
    self.p_black_masked = self:GetUIComponent("Image", "p_black_masked")

    self.data = uiParams[1]
    ---@type UnityEngine.Transform
    self.target = uiParams[2]
    local onShowEnd = uiParams[3]

    self:SetCirclePos()

    self.animation:Play("UIeff_Guide_baha_2")
    -- if self.data.ismask == true then
    --     self.maskGO:SetActive(true)
    -- else
    --     self.maskGO:SetActive(false)
    -- end
    self:RefreshShow()
    self._isShow = true
    self:StartTask(
        function(TT)
            YIELD(TT, 1000)
            if not self._isShow then
                return
            end
            self:RefreshTxt()
            self.animation:Play("UIeff_Guide_baha_1")
            YIELD(TT, 800)
            if not self._isShow then
                return
            end
            self.continueGO:SetActive(true)
            self.canClick = true
        end
    )
    if onShowEnd then
        onShowEnd()
    end

    self:AttachEvent(GameEventType.UIBlackChange, self.SetCirclePos)
end

function UIGuideCircleModelController:SetCirclePos()
    local pos = self:ConvertScreentPos(self.target)
    -----------------------------------
    --圆圈的占地
    local gaps_x = 200
    local leftRight = 50
    local min = 350
    local max = 700
    local black = self:GetBlackWidth()
    local right_less_x = ResolutionManager.RealWidth() - pos.x - gaps_x - leftRight - black
    if right_less_x < min then
        --right_less_x = 350
    elseif right_less_x > max then
        right_less_x = max
    end
    local left_less_x = pos.x - gaps_x - leftRight - black
    if left_less_x < min then
        --left_less_x = 350
    elseif left_less_x > max then
        left_less_x = max
    end

    self._l_t_txt.sizeDelta = Vector2(left_less_x, self._l_t_txt.sizeDelta.y)
    self._l_d_txt.sizeDelta = Vector2(left_less_x, self._l_d_txt.sizeDelta.y)
    self._r_t_txt.sizeDelta = Vector2(right_less_x, self._r_t_txt.sizeDelta.y)
    self._r_d_txt.sizeDelta = Vector2(right_less_x, self._r_d_txt.sizeDelta.y)
    self._l_x = left_less_x
    self._r_x = right_less_x
    -----------------------------------
    self.p_black_mask.anchoredPosition = Vector2(pos.x - self.maskRect.sizeDelta.x * 0.56, pos.y - self.maskRect.sizeDelta.y * 0.56) 
    self.p_black_mask.sizeDelta = self.maskRect.sizeDelta
    self.circle.anchoredPosition = pos
    self.maskRect.anchoredPosition = pos
end

function UIGuideCircleModelController:GetBlackWidth()
    local bangWidth = ResolutionManager.BangWidth()
    local configBangWidth = math.ceil(ResolutionManager.ConfigBangWidth())
    if configBangWidth <= 0 then
        --编辑器或非异形屏情况
        configBangWidth = 100
    end
    local r_w = ResolutionManager.RealWidth()
    local r_h = ResolutionManager.RealHeight()
    local j_w = r_h * 16 / 9
    local det_w = (r_w - j_w) * 0.5
    if det_w < 0 then
        det_w = 0
    end
    if configBangWidth > det_w then
        configBangWidth = det_w
    end

    local bangWidthPercent
    if configBangWidth <= 0 then
        bangWidthPercent = 0
    else
        bangWidthPercent = bangWidth / configBangWidth * 100
    end

    if bangWidthPercent > 100 then
        bangWidthPercent = 100
    end
    return bangWidthPercent
end
-- body
function UIGuideCircleModelController:ConvertScreentPos(target)
    local screenPos = InnerGameHelperRender.WorldPos2ScreenPos(target.position)
    local sw = ResolutionManager.ScreenWidth()
    local rw = ResolutionManager.RealWidth()
    -- local rw = ResolutionManager.RealWidth()
    local factor = rw / sw
    local sx, sy = screenPos.x * factor, screenPos.y * factor
    screenPos = Vector2(sx + self.data.offset[1], sy + self.data.offset[2])
    return screenPos
end
function UIGuideCircleModelController:OnHide()
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Entity)
    self._isShow = false
end
function UIGuideCircleModelController:RefreshShow()
    if self.data.lt then
        self.ltAllGO:SetActive(true)
    else
        self.ltAllGO:SetActive(false)
    end

    if self.data.rt then
        self.rtAllGO:SetActive(true)
    else
        self.rtAllGO:SetActive(false)
    end
    if self.data.lb then
        self.ldAllGO:SetActive(true)
    else
        self.ldAllGO:SetActive(false)
    end
    if self.data.rb then
        self.rdAllGO:SetActive(true)
    else
        self.rdAllGO:SetActive(false)
    end
end
function UIGuideCircleModelController:RefreshTxt()
    -- local use_l_t = false
    -- local use_l_d = false
    -- local use_r_t = false
    -- local use_r_d = false

    if self.data.lt then
        -- use_l_t = true
        self.ltGO:SetActive(true)
        self.ltTitleTxt:SetText(StringTable.Get(self.data.lttitle))
        self.ltDescTxt:SetText(StringTable.Get(self.data.lt))
    else
        self.ltGO:SetActive(false)
    end

    if self.data.rt then
        -- use_r_t = true
        self.rtGO:SetActive(true)
        self.rtTitleTxt:SetText(StringTable.Get(self.data.rttitle))
        self.rtDescTxt:SetText(StringTable.Get(self.data.rt))
    else
        self.rtGO:SetActive(true)
    end
    if self.data.lb then
        -- use_l_d = true
        self.ldGO:SetActive(true)
        self.ldTitleTxt:SetText(StringTable.Get(self.data.lbtitle))
        self.ldDescTxt:SetText(StringTable.Get(self.data.lb))
    else
        self.ldGO:SetActive(false)
    end
    if self.data.rb then
        -- use_r_d = true
        self.rdGO:SetActive(true)
        self.rdTitleTxt:SetText(StringTable.Get(self.data.rbtitle))
        self.rdDescTxt:SetText(StringTable.Get(self.data.rb))
    else
        self.rdGO:SetActive(false)
    end

    -- local change_l = false
    -- local change_r = false
    -- if use_l_t then
    --     local l_t_txt_width = self.ltDescTxt.preferredWidth

    --     if l_t_txt_width < self._l_x then
    --         self._l_x = l_t_txt_width
    --         change_l = true
    --     end
    -- end
    -- if use_l_d then
    --     local l_d_txt_width = self.ldDescTxt.preferredWidth

    --     if l_d_txt_width < self._l_x then
    --         self._l_x = l_d_txt_width
    --         change_l = true
    --     end
    -- end
    -- if use_r_t then
    --     local r_t_txt_width = self.rtDescTxt.preferredWidth

    --     if r_t_txt_width < self._r_x then
    --         self._r_x = r_t_txt_width
    --         change_r = true
    --     end
    -- end
    -- if use_r_d then
    --     local r_d_txt_width = self.rdDescTxt.preferredWidth

    --     if r_d_txt_width < self._r_x then
    --         self._r_x = r_d_txt_width
    --         change_r = true
    --     end
    -- end
    -- if change_l then
    --     self._l_t_txt.sizeDelta = Vector2(self._l_x, self._l_t_txt.sizeDelta.y)
    --     self._l_d_txt.sizeDelta = Vector2(self._l_x, self._l_d_txt.sizeDelta.y)
    -- end
    -- if change_r then
    --     self._r_t_txt.sizeDelta = Vector2(self._r_x, self._r_t_txt.sizeDelta.y)
    --     self._r_d_txt.sizeDelta = Vector2(self._r_x, self._r_d_txt.sizeDelta.y)
    -- end
end

function UIGuideCircleModelController:btnOnClick()
    self:OnClickBack()
end
function UIGuideCircleModelController:circleOnClick()
    self:OnClickBack()
end
function UIGuideCircleModelController:Back1OnClick()
    self:OnClickBack()
end

function UIGuideCircleModelController:Back2OnClick()
    self:OnClickBack()
end

function UIGuideCircleModelController:Back3OnClick()
    self:OnClickBack()
end

function UIGuideCircleModelController:Back4OnClick()
    self:OnClickBack()
end

function UIGuideCircleModelController:OnClickBack()
    if self.canClick then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Circle)
        self:CloseDialog()
    end
end
