--虚实之扉主界面
---@class UISeasonExploreMainController : UIController
_class("UISeasonExploreMainController", UIController)
UISeasonExploreMainController = UISeasonExploreMainController

---@param res AsyncRequestRes
function UISeasonExploreMainController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonExploreMainController:OnShow(uiParams)
    self.seasonModule = GameGlobal.GetModule(SeasonModule)
    self:InitWidget()
    self._timerHolder = UITimerHolder:New()
    self:_OnValue()
    self:AttachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
end

function UISeasonExploreMainController:OnHide()
    self._timerHolder:Dispose()
    self:DetachEvent(GameEventType.ItemCountChanged, self.OnItemCountChange)
end

--获取ui组件
function UISeasonExploreMainController:InitWidget()
    ---@type UICustomWidgetPool
    local topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtns")
    ---@type UICommonTopButton
    self._backBtns = topBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIMain)
        end,
        function() --help
            UISeasonHelper.ShowSeasonHelperBook(2)
        end,
        nil,
        false,
        function() --show hide ui
            self:FocusSeasonBg()
        end
    )

    ---@type UILocalizationText
    self.previewName = self:GetUIComponent("UILocalizationText", "previewName")
   
    ---@type RawImageLoader
    self.previewPet = self:GetUIComponent("RawImageLoader", "preViewPet")
    ---@type UILocalizationText
    self.previewCountDown = self:GetUIComponent("UILocalizationText", "previewCountDown")
    ---@type UILocalizationText
    self.coinNum = self:GetUIComponent("UILocalizationText", "coinNum")
    self.coinNumTop = self:GetUIComponent("UILocalizationText", "coinNumTop")

    self.imgCoin = self:GetUIComponent("Image", "imgCoin")

    ---@type UnityEngine.GameObject
    self.previewBtnGo = self:GetGameObject( "previewBtn")

    ---@type UnityEngine.GameObject
    self.newCollectionGo = self:GetGameObject("newCollection")

    ---@type UnityEngine.GameObject
    self.newMealGo = self:GetGameObject("newMeal")

    ---@type UnityEngine.GameObject
    self.newPreviewGo = self:GetGameObject("newPreview")

    ---@type UnityEngine.GameObject
    self.newExchangeGo = self:GetGameObject("newExchange")

    ---@type UnityEngine.GameObject
    self.showBtnGo = self:GetGameObject("showBtn")

    ---@type UnityEngine.GameObject
    self.contentGo = self:GetGameObject("content")


    ---@type RawImageLoader
    self.curSeasonImage = self:GetUIComponent("RawImageLoader", "curSean")
    self.curSeasonImageGo = self:GetGameObject("curSean")

    local topTipsPool = self:GetUIComponent("UISelectObjectPath", "toptips")
    self._topTipsInfo = topTipsPool:SpawnObject("UITopTipsContext")
    self.tipsPos = self:GetGameObject("tipsPos")
    self.curCountDownTxt = self:GetUIComponent("UILocalizationText", "curCountDownTxt")
end

function UISeasonExploreMainController:_OnValue()
    --preview
    self:RefreshPreview()
    --cur seaon
    self:RefrshCurSeason()
    --刷新New
    self:RefreshNews()
    --刷新代币商店按钮信息
    self:RefreshExchangeInfo()
end

function UISeasonExploreMainController:FocusSeasonBg()
    self.showBtnGo:SetActive(true)
    self.contentGo:SetActive(false)
end

function UISeasonExploreMainController:RefrshCurSeason()
    self.seasonId = nil
    ---@type campaign_sample
    local curSample = self.seasonModule:GetCurSeasonSample()
    self.seasonId = curSample.id

    local svrTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001
    if svrTime > curSample.begin_time and svrTime < curSample.end_time then
        --open
        self.curSeasonImageGo:SetActive(true)
        local cfg = Cfg.cfg_season_campaign_client[self.seasonId]
        if cfg then
            self.curSeasonImage:LoadImage(cfg.Theme)
        else
            Log.error("can't find cfg_season_campaign_client with id = " .. self.seasonId)
            self.curSeasonImageGo:SetActive(false)
        end
    
        --当前赛季倒计时
        local closeTime = curSample.end_time
        local timerName = "SeasonCountDown"
        local function countDown()
            local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
            local time = math.ceil(closeTime - now)
            local timeStr = UIActivityHelper.GetFormatTimerStr(time)
            if self._curSeasontimeString ~= timeStr then
                self.curCountDownTxt:SetText(StringTable.Get("str_season_clsoe_countdown", timeStr))
                self._curSeasontimeString = timeStr
            end
            if time < 0 then
                self._timerHolder:StopTimer(timerName)
                self.curCountDownTxt:SetText("")
                self.curSeasonImageGo:SetActive(false)
            end
        end
        countDown()
        self._timerHolder:StartTimerInfinite(timerName, 1000, countDown)
    else
        --close
        self.curSeasonImageGo:SetActive(false)
    end
end

function UISeasonExploreMainController:RefreshPreview()
    local cfg, openTime = UISeasonExploreHelper.GetPreviewCfg()
    self.preViewCfg = cfg
    self.previewBtnGo:SetActive(self.preViewCfg ~= nil)
    if not self.preViewCfg then
        return
    end
    self.previewPet:LoadImage(self.preViewCfg.PetIcon)
    self.previewName:SetText(self.preViewCfg.Title)
    --countDown
    local timerName = "PreviewCountDown"
    local function countDown()
        local now = self:GetModule(SvrTimeModule):GetServerTime() / 1000
        local time = math.ceil(openTime - now)
        local timeStr = UIActivityHelper.GetFormatTimerStr(time)
        if self._timeString ~= timeStr then
            self.previewCountDown:SetText(StringTable.Get("str_season_preview_countdown", timeStr))
            self._timeString = timeStr
        end
        if time < 0 then
            self._timerHolder:StopTimer(timerName)
        end
    end
    countDown()
    self._timerHolder:StartTimerInfinite(timerName, 1000, countDown)
end


function UISeasonExploreMainController:RefreshNews()
    --preview New
    local previewNew = false
    if self.preViewCfg then
        previewNew = not UISeasonExploreHelper.IsPreviewHasClicked(self.preViewCfg.ID)
    end
    self.newPreviewGo:SetActive(previewNew)

    local collectionNew =  UISeasonExploreHelper.IsSeasonCgHasNew() or UISeasonExploreHelper.IsSeasonMusicHasNew()  or UISeasonExploreHelper.IsSeasonRareItemHasNew()
    self.newCollectionGo:SetActive(collectionNew)

end

function UISeasonExploreMainController:RefreshExchangeInfo()
    local coinType = RoleAssetID.RoleAssetHistory
    local cfg  = Cfg.cfg_top_tips[coinType]
    if cfg then
        local atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
        self.imgCoin.sprite = atlas:GetSprite(cfg.Icon)
    end
    local itemModule = self:GetModule(ItemModule)
    local countStr = HelperProxy:GetInstance():Format9999W(itemModule:GetItemCount(coinType))
    self.coinNum:SetText(countStr)
    self.coinNumTop:SetText(countStr)
end

function UISeasonExploreMainController:OnItemCountChange()
    self:RefreshExchangeInfo()
end

--按钮点击
function UISeasonExploreMainController:CollectionBtnOnClick(go)
    self:ShowDialog("UISeasonCollectionController", function ()
        self:RefreshNews()
    end)
end

--按钮点击
function UISeasonExploreMainController:MedalBtnOnClick(go)
    self:ShowDialog("UIMedalGroupListController")
end

--按钮点击
function UISeasonExploreMainController:PreviewBtnOnClick(go)
    if self.preViewCfg then
        UISeasonExploreHelper.SetPreviewAsClicked(self.preViewCfg.ID)
        self.newPreviewGo:SetActive(false)
        self:ShowDialog("UISeasonPreviewController", self.preViewCfg.ID)
    end
end

--按钮点击
function UISeasonExploreMainController:ExChangeBtnOnClick(go)
    GameGlobal.GetUIModule(SeasonModule):EnterExchangeShopSeasonTab()
end

--按钮点击
function UISeasonExploreMainController:ReviewBtnOnClick(go)
end

--按钮点击
function UISeasonExploreMainController:StartBtnOnClick(go)
    local curSample = self.seasonModule:GetCurSeasonSample()
    local svrTime = GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001
    if svrTime > curSample.begin_time and svrTime < curSample.end_time then
        --open
        GameGlobal.GetUIModule(SeasonModule):OpenSeasonThemeUI()
    else
        ToastManager.ShowToast(StringTable.Get("str_season_no_tips"))
    end
end

--按钮点击
function UISeasonExploreMainController:ShowBtnOnClick(go)
    self.showBtnGo:SetActive(false)
    self.contentGo:SetActive(true)
end


function UISeasonExploreMainController:PlotBtnOnClick(go)
    local plotId = Cfg.cfg_global["season_system_first_plot"].IntValue
    GameGlobal.UIStateManager():ShowDialog("UIStoryController", plotId)
end


function UISeasonExploreMainController:ImgCoinOnClick(go)
    local coinType = RoleAssetID.RoleAssetHistory
    self._topTipsInfo:SetData(coinType, self.tipsPos)
end