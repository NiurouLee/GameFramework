---@class UIHomelandMovieTagItem:UICustomWidget
_class("UIHomelandMovieTagItem", UICustomWidget)
UIHomelandMovieTagItem = UIHomelandMovieTagItem

function UIHomelandMovieTagItem:Constructor()
    ---@Type cfg_homeland_movice
    self._data = nil
    self._callBack = nil
    self._isLocked = true  --是否锁定
    self._select = false
    self._redState = false --红点
    self._pstid = nil
    self._isLeave = false  --是否是离开
    self._isBeSelected = false  --是否之前被选中
    self._atlas = self:GetAsset("UIMovieSecond.spriteatlas", LoadType.SpriteAtlas)
end

function UIHomelandMovieTagItem:OnShow(uiParams)
    self:InitWidget()
end

function UIHomelandMovieTagItem:OnHide()
    -- if self._redState and self._isBeSelected then
    --     self:_RemoveRedPoint()
    -- end
end

function UIHomelandMovieTagItem:InitWidget()

    self._text = self:GetUIComponent("UILocalizationText","Text")
    self._tag = self:GetUIComponent("Image","Tag")
    self._redPoint = self:GetGameObject("redPoint")
end

function UIHomelandMovieTagItem:Dispose()
end

function UIHomelandMovieTagItem:SetData(data,index,callback)
    self._data = data
    self.index=index
    self._callBack=callback

    self:SetInfo()
    self:SetRed()
end

--设置当前数据
function UIHomelandMovieTagItem:SetInfo()
    self._tag.sprite = self._atlas:GetSprite("dy_xzjb_di17")

    if self._data.Title then
        self._text:SetText(StringTable.Get(self._data.Title))
    else
        Log.fatal("未配置标签")
    end
    --加载红点

end

function UIHomelandMovieTagItem:SetRed()
    local cfg = Cfg.cfg_homeland_movice {}
    local id=self._data.MovieId

    for _, v in ipairs(id) do
        if self:CheckRed(cfg[v]) then
            self._redPoint:SetActive(true)
            break
        else
            self._redPoint:SetActive(false)
        end
    end
end

function UIHomelandMovieTagItem:TagOnClick()

    if self._callBack then
        self._callBack(self)
    end
    
    local cfg = Cfg.cfg_homeland_movice {}
    local a=self.index
    Log.fatal("点击"..a)
    local id=self._data.MovieId
    local controller = GameGlobal.UIStateManager():GetController("UIHomelandMovieMainController")
    controller:InitDramaList(id)

    for _, v in ipairs(id) do
        if self:CheckRed(cfg[v]) then
            self._redPoint:SetActive(true)
            break
        else
            self._redPoint:SetActive(false)
        end
    end

    

end

--设置是否被选中
function UIHomelandMovieTagItem:SetSelected(isSelected)

    if isSelected then
        self._tag.sprite = self._atlas:GetSprite("dy_xzjb_di16")
        self._text.color = Color(255/255 , 255/255 , 255/255)

    else
        self._tag.sprite = self._atlas:GetSprite("dy_xzjb_di17")
        self._text.color = Color(107/255 , 107/255 , 107/255)

    end
    

    -- --self._select:SetActive(isSelected)
    -- if self._isLeave then
    --     --self._redState = false
    --     --self._newImg:SetActive(false)
    -- end
    -- if self._isBeSelected and not isSelected then
    --     --之前被选中 且现在没被选中
    -- end
    -- if isSelected and not self._isBeSelected then
    --     self._isBeSelected = true
    --     --self._rect.anchoredPosition = Vector2(0,30)
    -- elseif isSelected and self._isBeSelected then
    -- else
    --     self._isBeSelected = false
    --     --self._rect.anchoredPosition = Vector2(0,0)
    -- end
    -- self._isLeave = isSelected
end


function UIHomelandMovieTagItem:CheckRed(data)

    self._redState= MovieDataManager:GetInstance():CheckMovieNew(data)
    return self._redState
end

-- function UIHomelandMovieTagItem:MovieBtnOnClick()
--     self:_RemoveRedPoint()

--     if self._callBack then
--         self._callBack(self)
--     end
-- end

-- function UIHomelandMovieTagItem:_RemoveRedPoint()
--     self:StartTask(
--         function(TT)
--             if self._pstid then
--                 local itemModule = GameGlobal.GetModule(ItemModule)
--                 itemModule:SetItemUnnewOverlay(TT, self._pstid)
--                 itemModule:SetItemUnnew(TT,self._pstid)
--             end
--         end
--     )
-- end