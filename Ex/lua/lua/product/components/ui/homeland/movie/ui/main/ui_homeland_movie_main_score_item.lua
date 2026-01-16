---@class UIHomelandMovieMainScoreItem:UICustomWidget
_class("UIHomelandMovieMainScoreItem", UICustomWidget)
UIHomelandMovieMainScoreItem = UIHomelandMovieMainScoreItem

function UIHomelandMovieMainScoreItem:Constructor()
    self._data = nil
    self._movieID = nil
    self._rewardList = {}  --奖励列表
end

function UIHomelandMovieMainScoreItem:OnShow(uiParams)
    self._uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:InitWidget()
end

function UIHomelandMovieMainScoreItem:InitWidget()
    self._scoreMainBG = self:GetUIComponent("RawImageLoader","scoreMainBG")
    self._socretMainText = self:GetUIComponent("UILocalizationText","socketMainText")
    self._socretText = self:GetUIComponent("UILocalizationText","socketText")
    self._isGet = self:GetGameObject("isGet")
end

function UIHomelandMovieMainScoreItem:Dispose()
end

--设置数据
function UIHomelandMovieMainScoreItem:SetData(data,movieId)
    self._data = data
    self._movieID = movieId
    self:SetInfo()
    self:CheckRewardReceive()
end

--获得奖励id
function UIHomelandMovieMainScoreItem:GetData()
    return self._data[2]
end

--设置数据
function UIHomelandMovieMainScoreItem:SetInfo()
    local itemId = self._data[2]
    local cfg = Cfg.cfg_item[itemId]
    self._scoreMainBG:LoadImage(cfg.Icon)
    self._socretMainText:SetText(self._data[3])

    local score = self._data[1] * 0.5
    if score % 1 == 0.5 then
        self._socretText:SetText(score)
    else
        self._socretText:SetText(math.floor(score))
    end
end

--设置是否获得
---@param isGet boolean 
function UIHomelandMovieMainScoreItem:SetIsGet(isGet)
    self._isGet:SetActive(isGet)
end

--检查奖励是否被领取
function UIHomelandMovieMainScoreItem:CheckRewardReceive()
    local receivedList = MovieDataManager:GetInstance():GetMovieRewardByID(self._movieID)  --已获得奖励id列表
    for i,v in pairs(receivedList) do
        if self._data[1] == v then
            self:SetIsGet(true)
            return
        end
    end
    self:SetIsGet(false)
end

function UIHomelandMovieMainScoreItem:ScoreBgOnClick(go)
    self:ShowDialog("UIItemTipsHomeland", self._data[2], go, true)
end