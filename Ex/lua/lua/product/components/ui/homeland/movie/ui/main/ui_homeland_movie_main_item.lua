---@class UIHomelandMovieMainItem:UICustomWidget
_class("UIHomelandMovieMainItem", UICustomWidget)
UIHomelandMovieMainItem = UIHomelandMovieMainItem

function UIHomelandMovieMainItem:Constructor()
    ---@Type cfg_homeland_movice
    self._data = nil
    self._callBack = nil
    self._isLocked = true  --是否锁定
    self._select = false
    self._pstid = nil
    self._movieData = nil  --服务端电影数据
    self._redState = false --红点
    self._pstid = nil
    self._isLeave = false  --是否是离开
    self._delay = 100
    self._isBeSelected = false  --是否之前被选中
end

function UIHomelandMovieMainItem:OnShow(uiParams)
    self:InitWidget()
end

function UIHomelandMovieMainItem:OnHide()
    if self._redState and self._isBeSelected then
        self:_RemoveRedPoint()
    end
end

function UIHomelandMovieMainItem:InitWidget()
    self._movieBG = self:GetUIComponent("RawImageLoader", "movieBG")
    self._select = self:GetGameObject("select")
    self._lockImg = self:GetGameObject("lockImg")
    self._scoreText = self:GetUIComponent("UILocalizationText","scoreText")
    self._newImg = self:GetGameObject("newImg")
    self._scoreImg = self:GetGameObject("scoreImg")
    self._rect = self:GetUIComponent("RectTransform","root")
    self._animMain = self:GetUIComponent("Animation","anim")
end

function UIHomelandMovieMainItem:Dispose()
end

function UIHomelandMovieMainItem:SetData(data,index,callback)
    self._data = data
    self._callBack = callback

    self._movieData = MovieDataManager:GetInstance():GetMovieDataByID(self._data.ID)
    self:_SetAnimation(self._delay * (index - 1))
    self:SetInfo()
    self:CheckIsLock()
    self:CheckIsNew()
    self:SetSelected(false,true)
end

--获得剧本数据
function UIHomelandMovieMainItem:GetData()
    return self._data
end

--获得得分详情
function UIHomelandMovieMainItem:GetScoreList()
    return self._data.Rewards
end

--获得id
function UIHomelandMovieMainItem:GetID()
    return self._data.ID
end

--设置当前数据
function UIHomelandMovieMainItem:SetInfo(TT)
    self._movieBG:LoadImage(self._data.Poster)
    if self._movieData then
        --设置背景图案
        local score = self._movieData.max_score * 0.5
        if score % 1 == 0.5 then
            self._scoreText:SetText(score)
        else
            self._scoreText:SetText(math.floor(score))
        end
    else
        self._scoreImg:SetActive(false)
    end
end

function UIHomelandMovieMainItem:_SetAnimation(delay)
    UIWidgetHelper.PlayAnimationInSequence(self,
        "anim",
        "anim",
        "UIHomelandMovieMainController_in",
        delay,
        500,
        nil)
end

--检查是否锁定
function UIHomelandMovieMainItem:CheckIsLock()
    --需要判断是否拥有该物品
    self._isLocked = MovieDataManager:GetInstance():CheckMovieLock(self._data)

    self._lockImg:SetActive(self._isLocked)
   
end

--设置是否被选中
function UIHomelandMovieMainItem:SetSelected(isSelected,refresh)
    self._select:SetActive(isSelected)
    if refresh then
        self._isLeave = false
    end
    if self._isLeave then
        self._redState = false
        self._newImg:SetActive(false)
        self:_RemoveRedPoint()
        --设置红点
    end
    if self._isBeSelected and not isSelected then
        --之前被选中 且现在没被选中
        self._animMain:Play("UIHomelandMovieMainController_down")
    end
    if isSelected and not self._isBeSelected then
        self._isBeSelected = true
        self._rect.anchoredPosition = Vector2(0,30)
        self._animMain:Play("UIHomelandMovieMainController_up")
    elseif isSelected and self._isBeSelected then
    else
        self._isBeSelected = false
        self._rect.anchoredPosition = Vector2(0,0)
    end
    self._isLeave = isSelected
end

--检查是否是新获得
function UIHomelandMovieMainItem:CheckIsNew()
    self._redState,self._pstid = MovieDataManager:GetInstance():CheckMovieNew(self._data)
    self._newImg:SetActive(self._redState)
end

function UIHomelandMovieMainItem:MovieBtnOnClick()
    self:_RemoveRedPoint()

    if self._callBack then
        self._callBack(self)
    end
end

function UIHomelandMovieMainItem:_RemoveRedPoint()
    self:StartTask(
        function(TT)
            if self._pstid then
                local itemModule = GameGlobal.GetModule(ItemModule)
                itemModule:SetItemUnnewOverlay(TT, self._pstid)
                itemModule:SetItemUnnew(TT,self._pstid)
            end
        end
    )
end