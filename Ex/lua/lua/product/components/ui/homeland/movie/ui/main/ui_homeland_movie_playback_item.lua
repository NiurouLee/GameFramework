---@class UIHomelandMoviePlaybackItem:UICustomWidget
_class("UIHomelandMoviePlaybackItem", UICustomWidget)
UIHomelandMoviePlaybackItem = UIHomelandMoviePlaybackItem

function UIHomelandMoviePlaybackItem:Constructor()
    self._actorId = nil
    self._movieData = nil
    self._callBack = nil
    self._altas = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
end

function UIHomelandMoviePlaybackItem:OnShow(uiParams)
    self:InitWidget()
end

function UIHomelandMoviePlaybackItem:InitWidget()
    self._actorHead = self:GetUIComponent("RawImageLoader","actorHead")
    self._actorName = self:GetUIComponent("UILocalizationText","actorName")
    self._actorType = self:GetUIComponent("UILocalizationText","actorType")
end

---@param data number actorId
---@param movieData cfg_homeland_movice 
function UIHomelandMoviePlaybackItem:SetData(data,movieData)
    self._actorId = data
    self._movieData = movieData
    
    self:InitData()
end

--获得数据
function UIHomelandMoviePlaybackItem:GetData()
    return self._actorId
end

--设置数据
function UIHomelandMoviePlaybackItem:InitData()
    --获得角色扮演类型
    local typeText = MovieDataManager:GetInstance():GetMoviePointByID(self._movieData.ID,self._actorId)
    self._actorType:SetText(StringTable.Get(typeText))
    self._actorHead:LoadImage("head1_"..self._actorId)
    self._actorName:SetText(StringTable.Get(Cfg.cfg_item[self._actorId].Name))
end