---@class UIBuildCollectCoin:UIController
_class("UIBuildCollectCoin", UIController)
UIBuildCollectCoin = UIBuildCollectCoin

function UIBuildCollectCoin:LoadDataOnEnter(TT, res, uiParams)
    self._coinDatas = UIBuildCollectCoinDatas:New()
    self._collectCoinRewards = UIBuildCollectCoinRewardDatas:New()
end

function UIBuildCollectCoin:OnShow(uiParams)
    self._collectCountLabel = self:GetUIComponent("UILocalizationText", "CollectCount")
    self._coinNameLabel = self:GetUIComponent("UILocalizationText", "CoinName")
    self._getWayLabel = self:GetUIComponent("UILocalizationText", "GetWay")
    self._coinDesLabel = self:GetUIComponent("UILocalizationText", "CoinDes")
    self._coinIconLoader = self:GetUIComponent("RawImageLoader", "CoinIcon")
    self._getWayIconLoader = self:GetUIComponent("RawImageLoader", "GetWayIcon")
    ---@type UIBuildCollectCoinData
    self._currentSelectCoinData = nil
    ---@type UIBuildCollectCoinItem
    self._coinLoader = self:GetUIComponent("UISelectObjectPath", "CoinList")
    self._rewardLoader = self:GetUIComponent("UISelectObjectPath", "RewardList")
    self._rewardPanel = self:GetGameObject("RewardPanel")
    self._rewardDesLabel = self:GetUIComponent("UILocalizationText", "RewardDes")
    self:RefreshUI()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, false)
end

function UIBuildCollectCoin:OnHide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshInteractUI)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, true)

    ---@type UIHomelandModule
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    local homelandClient = homeLandModule:GetClient()
    --界面打开状态下断线重登 家园会先销毁然后切换ui
    if not homelandClient then
        return
    end
    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()
    characterController:SetForbiddenMove(false)
end

function UIBuildCollectCoin:RefershData()
    self._coinDatas:Refresh()
    self._collectCoinRewards:Refresh()
end

function UIBuildCollectCoin:GetCollectCoinRewards()
    return self._collectCoinRewards
end

function UIBuildCollectCoin:ShowItemTips(id, go)
    self:ShowDialog("UIItemTipsHomeland", id, go)
end

function UIBuildCollectCoin:SetStatus(active)
    local go = self:GetGameObject()
    local tran = go.transform
    local bg = tran.parent.parent:Find("BGMaskCanvas")
    if bg then
        local bgGo = bg.gameObject
        local canvas = bgGo:GetComponent("Canvas")
        canvas.enabled = active
        local raycaster = bgGo:GetComponent("GraphicRaycaster")
        raycaster.enabled = active
    end
    go:SetActive(active)
end

function UIBuildCollectCoin:RefreshUI()
    self._collectCountLabel:SetText(HomelandWishingConst.GetCollectCoinCounts())
    self:RefreshCoinList()
    self:RefreshCoinInfo()
    self:RefreshRewardTask()
end

function UIBuildCollectCoin:RefreshCoinInfo()
    if not self._currentSelectCoinData then
        self._coinNameLabel:SetText(HomelandWishingConst.GetDefaultCoinfName())
        self._getWayLabel:SetText(HomelandWishingConst.GetDefaultCoinGetWay())
        self._coinDesLabel:SetText(HomelandWishingConst.GetDefaultCoinDes())
        self._coinIconLoader:LoadImage(HomelandWishingConst.GetDefaultCoinIcon())
        self._getWayIconLoader:LoadImage(HomelandWishingConst.GetDefaultCoinGetWayIcon())
    else
        self._coinNameLabel:SetText(self._currentSelectCoinData:GetName())
        self._getWayLabel:SetText(self._currentSelectCoinData:GetGetWay())
        self._coinDesLabel:SetText(self._currentSelectCoinData:GetDes())
        self._coinIconLoader:LoadImage(self._currentSelectCoinData:GetIcon())
        self._getWayIconLoader:LoadImage(self._currentSelectCoinData:GetGetWayIcon())
    end
end

function UIBuildCollectCoin:RefreshCoinList()
    local coinDatas = self._coinDatas:GetCollectCoinDatas()
    local count = #coinDatas
    self._coinLoader:SpawnObjects("UIBuildCollectCoinItem", count)
    ---@type UIBuildCollectCoinItem[]
    local items = self._coinLoader:GetAllSpawnList()
    for i = 1, count do
        items[i]:Refresh(self, coinDatas[i])
    end
end

function UIBuildCollectCoin:RefreshRewardTask()
    ---@type UIBuildCollectCoinRewardData
    local currentTask = self._collectCoinRewards:GetCurrentTask()
    if not currentTask then
        self._rewardPanel:SetActive(false)
        return
    end
    self._rewardPanel:SetActive(true)
    self._rewardDesLabel:SetText(StringTable.Get("str_homeland_collect_coin_reward_des", currentTask:GetWishingCoinCount()))
    local rewards = currentTask:GetRewards()
    local count = #rewards
    self._rewardLoader:SpawnObjects("UIBuildCollectRewardItem", count)
    ---@type UIBuildCollectRewardItem[]
    local items = self._rewardLoader:GetAllSpawnList()
    for i = 1, count do
        items[i]:Refresh(rewards[i], function(id, go)
            self:ShowItemTips(id, go)
        end)
    end
end

---@return UIBuildCollectCoinData
function UIBuildCollectCoin:GetCurrentSelectCoinData()
    return self._currentSelectCoinData
end

---@param currentItem UIBuildCollectCoinItem
function UIBuildCollectCoin:SelectItem(currentItem)
    if currentItem:GetCoinData() == self._currentSelectCoinData then
        return
    end
    
    local items = self._coinLoader:GetAllSpawnList()
    for i = 1, #items do
        items[i]:SetSelectStatus(false)
    end
    currentItem:SetSelectStatus(true)
    self._currentSelectCoinData = currentItem:GetCoinData()
    self:RefreshCoinInfo()
end

function UIBuildCollectCoin:BtnReturnOnClick(go)
    self:CloseDialog()
end

function UIBuildCollectCoin:BtnInfoOnClick(go)
    -- self:ShowDialog("UIHelpController", "UIBuildCollectCoin")
end

function UIBuildCollectCoin:BtnViewRewardOnClick(go)
    self:ShowDialog("UIBuildCollectCoinTask", self._collectCoinRewards)
end
