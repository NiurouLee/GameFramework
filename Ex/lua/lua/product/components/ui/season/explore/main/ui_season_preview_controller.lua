--
---@class UISeasonPreviewController : UIController
_class("UISeasonPreviewController", UIController)
UISeasonPreviewController = UISeasonPreviewController

---@param res AsyncRequestRes
function UISeasonPreviewController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonPreviewController:OnShow(uiParams)
    self:InitWidget()
    self.previewId = uiParams[1]
    self:OnValue()
end

--获取ui组件
function UISeasonPreviewController:InitWidget()
    ---@type UICustomWidgetPool
    local topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtns")
    ---@type UICommonTopButton
    self._backBtns = topBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        nil,
        true
    )

    ---@type RawImageLoader
    self.bg = self:GetUIComponent("RawImageLoader", "bg")
    ---@type RawImageLoader
    self.petImage = self:GetUIComponent("RawImageLoader", "petImage")
    ---@type RawImageLoader
    self.titleBg = self:GetUIComponent("RawImageLoader", "titleBg")
    ---@type RawImageLoader
    self.countdownBg = self:GetUIComponent("RawImageLoader", "countdownBg")

    ---@type UILocalizationText
    self.txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    ---@type UILocalizationText
    self.txtcontent = self:GetUIComponent("UILocalizationText", "txtcontent")
    ---@type UILocalizationText
    self.txtCountdown = self:GetUIComponent("UILocalizationText", "txtCountdown")
end

function UISeasonPreviewController:OnValue()
    local cfg =  Cfg.cfg_season_preview[self.previewId]
    if not cfg then
        Log.error("err UISeasonPreviewController can't cfg_season_preview find  with id = " .. self.previewId)
        return
    end
    self.bg:LoadImage(cfg.PopBg)
    self.petImage:LoadImage(cfg.PopPetImg)
    self.titleBg:LoadImage(cfg.PopTitleImg)
    self.countdownBg:LoadImage(cfg.PopTimeImg)

    self.txtTitle:SetText(StringTable.Get(cfg.PopTitleTxt))
    self.txtcontent:SetText(StringTable.Get(cfg.PopContentTxt))
    self.txtCountdown:SetText(StringTable.Get("str_season_preview_open_time",cfg.SeasonOpenTime))
end
