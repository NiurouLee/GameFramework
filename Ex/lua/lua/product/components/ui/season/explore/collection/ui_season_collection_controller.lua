--
---@class UISeasonCollectionController : UIController
_class("UISeasonCollectionController", UIController)
UISeasonCollectionController = UISeasonCollectionController

---@param res AsyncRequestRes
function UISeasonCollectionController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonCollectionController:OnShow(uiParams)
    self:InitWidget()
    self:_RefreshCgNew()
    self:_RefreshMusicNew()
    self:_RefreshRareItemNew()
end

--获取ui组件
function UISeasonCollectionController:InitWidget()
    ---@type UICustomWidgetPool
    local topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtns")
    ---@type UICommonTopButton
    self._backBtns = topBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        function()
            --home btn
            local currentStateUI = GameGlobal.UIStateManager():CurUIStateType()
            if currentStateUI == UIStateType.UISeasonExploreMainController then
                self:SwitchState(UIStateType.UIMain)
            else
                GameGlobal.GetUIModule(SeasonModule):ExitSeasonTo(UIStateType.UIMain)
            end
        end
    )

    ---@type UnityEngine.UI.Image
    self.cgBtn = self:GetUIComponent("Image", "CgBtn")
    ---@type UnityEngine.UI.Image
    self.musicBtn = self:GetUIComponent("Image", "MusicBtn")
    ---@type UnityEngine.UI.Image
    self.rareBtn = self:GetUIComponent("Image", "RareBtn")

    ---@type UnityEngine.GameObject
    self.newCg = self:GetGameObject("newCg")
    ---@type UnityEngine.GameObject
    self.newMusic = self:GetGameObject("newMusic")
    ---@type UnityEngine.GameObject
    self.newRare = self:GetGameObject("newRare")
end

--按钮点击
function UISeasonCollectionController:CgBtnOnClick(go)
    self:ShowDialog("UISeasonCgCollectionController", function()
        self:_RefreshCgNew()
    end)
end

--按钮点击
function UISeasonCollectionController:MusicBtnOnClick(go)
    self:ShowDialog("UISeasonMusicCollectionController", function()
        self:_RefreshMusicNew()
    end)
end

--按钮点击
function UISeasonCollectionController:RareBtnOnClick(go)
    self:ShowDialog("UISeasonRareCollectionController", function()
        self:_RefreshRareItemNew()
    end)
end

function UISeasonCollectionController:_RefreshCgNew()
    local hasNew = UISeasonExploreHelper.IsSeasonCgHasNew()
    self.newCg:SetActive(hasNew)
end

function UISeasonCollectionController:_RefreshMusicNew()
    local hasNew = UISeasonExploreHelper.IsSeasonMusicHasNew()
    self.newMusic:SetActive(hasNew)
end

function UISeasonCollectionController:_RefreshRareItemNew()
    local hasNew = UISeasonExploreHelper.IsSeasonRareItemHasNew()
    self.newRare:SetActive(hasNew)
end
