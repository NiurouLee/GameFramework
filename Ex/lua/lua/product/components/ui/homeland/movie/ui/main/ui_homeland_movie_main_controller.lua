---@class UIHomelandMovieMainController:UIController
_class("UIHomelandMovieMainController", UIController)
UIHomelandMovieMainController = UIHomelandMovieMainController

function UIHomelandMovieMainController:Constructor()
    ---@type HomelandModule
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    ---@type UIHomelandModule
    self.mUIHomeland = self.mHomeland:GetUIModule()
    ---@type HomelandClient
    self.homelandClient = self.mUIHomeland:GetClient()

    self._movieList = nil  --剧本列表
    self._movieData = nil  --剧本信息
    self._movieWidgets = {}  --剧本组件表
    self._scoreWidgets = {}  --奖励组件表
    self._curMovieWidget = nil --当前电影组件
    self._pstID = nil  --电影开拍唯一ID
    self._homelandModule = GameGlobal.GetModule(HomelandModule)
    self._hasHistory = false --是否有历史记录
    ---@type BuildBase
    self._build = nil  --建筑对象
    self._atlas = self:GetAsset("UIHomelandMovie.spriteatlas", LoadType.SpriteAtlas)
    self._isHide = false  --是否处于隐藏状态
    self._preRawImageName = nil  --上一张背景图
    self._fadeTime = 0.5 --淡化时间
    

end

function UIHomelandMovieMainController:OnShow(param)
    self._build = param[1]
    AudioHelperController.PlayBGM(CriAudioIDConst.BGMN17, AudioConstValue.BGMCrossFadeTime)
    self:InitWidget()
    self:ShowMovieTag()
    self:GetMovieTag()
    --self:InitDramaList()

    self._movieDataHelper = MovieDataHelper:New()
    local type,AnonymousId=self._movieDataHelper:ShowOrNot()
    if type then
        self:ShowAnonymous(AnonymousId)
    end

end
function UIHomelandMovieMainController:InitWidget()
    self._movieTitle = self:GetUIComponent("UILocalizationText", "movieTitle")
    --self._movieTitleRollingText = self:GetUIComponent("RollingText", "movieTitle")
    self._movieContent = self:GetUIComponent("UILocalizationText", "movieContent")
    self._contentRect = self:GetUIComponent("RectTransform", "introContent")
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._scores = self:GetUIComponent("UISelectObjectPath","scores")
    self._movieBG = self:GetUIComponent("RawImageLoader","movieBG")
    self._movieBGPre = self:GetUIComponent("RawImageLoader","movieBGPre")
    self._movieRawBG = self:GetUIComponent("RawImage","movieBG")
    self._movieRawBGPre = self:GetUIComponent("RawImage","movieBGPre")
    self._playbackBtn = self:GetUIComponent("Image","playbackBtn")
    self._camera = self:GetUIComponent("Image","camera")
    self._chooseText = self:GetUIComponent("UILocalizationText", "chooseText")
    self._root = self:GetGameObject("root")
    self._anim = self:GetUIComponent("Animation", "anim")
    self._tagContent = self:GetUIComponent("UISelectObjectPath", "TagContent")
    
end

function UIHomelandMovieMainController:OnHide()
end

--返回
function UIHomelandMovieMainController:BtnBackOnClick(TT)
    self:CloseDialog()
    AudioHelperController.PlayBGM(CriAudioIDConst.BGMEnterHomeland, AudioConstValue.BGMCrossFadeTime)
end

--选择剧本
function UIHomelandMovieMainController:ChooseMovieOnClick(TT)
    if self._movieData then
        GameGlobal.TaskManager():StartTask(function (TT)
            self:MakingMovie(TT, self._movieData)
        end)
    else
        Log.fatal("选择剧本失败 没有剧本信息")
    end
end

function UIHomelandMovieMainController:MakingMovie(TT,data)
    local homelandModule = GameGlobal.GetModule(HomelandModule)
    local reply,psdId = homelandModule:HandleEnterMakingMovice(TT,data.ID)

    if reply:GetSucc() then
        MoviePrepareData:GetInstance():SetMovieData(data.ID,psdId,self._build)
        Log.fatal(homelandModule.movice_pstid)
        self.mUIHomeland:EnterMoviePrepare(TT)
    else
        if reply.m_result == HomeLandErrorType.E_MOVICE_NOT_UNLOCK then
            ToastManager.ShowHomeToast(StringTable.Get(Cfg.cfg_homeland_movice[data.ID].Achieve))
        end
        Log.fatal("选择剧本请求异常")
    end
end

--todo判断一下有没有匿名剧本
function UIHomelandMovieMainController:ShowAnonymous(AnonymousId)
    self:ShowDialog("UIHomelandAnonymousPopController",AnonymousId)

end
--拍摄详情
function UIHomelandMovieMainController:ChooseActorOnClick()
    self:ShowDialog("UIHomelandMovieActorController",self._movieData)
end

--回放按钮
function UIHomelandMovieMainController:PlayBackbtnOnClick()
    if self._hasHistory then
        self:ShowDialog("UIHomelandMoviePlaybackController",self._movieData,self._build)
    else
        ToastManager.ShowHomeToast(StringTable.Get("str_movie_toast_Nohistory"))
    end
end

--初始化电影标签
function UIHomelandMovieMainController:ShowMovieTag()
    local cfg = Cfg.cfg_homeland_movie_tag{}
    local tag={}
    for i, v in ipairs(cfg) do
        table.insert(tag,v.ID)
    end
    local len = #tag
    local index = 1
    self._movieWidgets = self._tagContent:SpawnObjects("UIHomelandMovieTagItem",len)

    for i,v in pairs(cfg )do
        self._movieWidgets[index]:SetData(v,index,
        function(item)
            self:OnTagClicked(item)
        end)
        if index == 1 then
            self:OnTagClicked(self._movieWidgets[index])
        end
        index = index + 1
    end
    --self:InitDramaList()
end

function UIHomelandMovieMainController:OnTagClicked(item)
    
    if self._curTagWidget then
        if self._curTagWidget==item then
            self.sameClick = true
        else
            self.sameClick = false
        end
        self._curTagWidget:SetSelected(false)
        self._curTagWidget:SetRed()
    end
    self._curTagWidget = item
    self._curTagWidget:SetSelected(true)
end

--进入只加载第一个标签的剧本
function UIHomelandMovieMainController:GetMovieTag()
    
    local cfg = Cfg.cfg_homeland_movie_tag{}
    local tag = cfg[1].MovieId

    self:InitDramaList(tag)
end

--初始化剧本列表
function UIHomelandMovieMainController:InitDramaList(tag)
    if self.sameClick then
        return
    end
    self.refresh = false

    if tag == nil then
        local cfg = Cfg.cfg_homeland_movie_tag{}
        tag = cfg[1].MovieId
    end
    self._movieList = MovieDataManager:GetInstance():GetSortMovieList(tag)

    local len = table.count(self._movieList)
    local index = 1
    self._movieWidgets = self._content:SpawnObjects("UIHomelandMovieMainItem",len)
    
    for i,v in pairs(self._movieList) do
        self._movieWidgets[index]:SetData(v,index,
        function(item)
            self:OnDramaItemClicked(item)
        end)
        if index == 1 then
            self.refresh=true
            --self._curMovieWidget = self._movieWidgets[index]
            self:OnDramaItemClicked(self._movieWidgets[index])
        end
        index = index + 1
    end
    
    self.refresh=false
end

--剧本被点击
---@param item UIHomelandMovieMainItem
function UIHomelandMovieMainController:OnDramaItemClicked(item)
    local data = item:GetData()
    if self._movieData == data then
        return
    end
    self._anim:Play("UIHomelandMovieMainController_scores")
    self._movieData = data
    if self._curMovieWidget then
        self._curMovieWidget:SetSelected(false,self.refresh)
    end
    self._curMovieWidget = item
    self._curMovieWidget:SetSelected(true,self.refresh)
    local history = MovieDataManager:GetInstance():GetMovieHistoryDataByID(self._movieData.ID)
    self._hasHistory = table.count(history) > 0
    if self._hasHistory then
        self._camera.sprite = self._atlas:GetSprite("dy_xzjb_icon06")
        self._playbackBtn.sprite = self._atlas:GetSprite("dy_xzjb_di03")
        self._chooseText.color = Color(128/255,128/255,128/255)
    else
        self._camera.sprite = self._atlas:GetSprite("dy_xzjb_icon07")
        self._playbackBtn.sprite = self._atlas:GetSprite("dy_xzjb_di14")
        self._chooseText.color = Color(229/255,229/255,229/255)
    end
    self:InitDramaInfo(item)
    self._curTagWidget:SetRed()
end

--背景板淡化
function UIHomelandMovieMainController:_FadeBG(rawImage)
    self._movieRawBG:DOFade(1,0)
    if self._preRawImageName then
        self._movieBG:LoadImage(self._preRawImageName)
    else
        self._movieRawBG:DOFade(0,0)
    end
    self._movieBGPre:LoadImage(rawImage)
    self._movieRawBGPre:DOFade(0,0)
    self._movieRawBGPre:DOFade(1,self._fadeTime)
    self._preRawImageName = rawImage
end

--初始化剧本详情
---@param item UIHomelandMovieMainItem
function UIHomelandMovieMainController:InitDramaInfo(item)
    local scoreList = item:GetScoreList()--奖励列表 Rewards
    local len = self:_CountScoreLen(scoreList) --奖励长度
    local index = 1
    local curScore = 0--当前分数段

    
    -- self._movieTitle:SetText(StringTable.Get("str_n24_main_entry_tips"))
    -- self._movieTitleRollingText:RefreshText(StringTable.Get("str_n24_main_entry_tips"))
    self._movieTitle:SetText(StringTable.Get(self._movieData.Name))
    --self._movieTitleRollingText:RefreshText(StringTable.Get(self._movieData.Name))
    self._movieContent:SetText(StringTable.Get(self._movieData.Intro))
    self._contentRect.anchoredPosition = Vector2(0,0)
    self:_FadeBG(self._movieData.Background)
    --初始化奖励
    self._scoreWidgets = self._scores:SpawnObjects("UIHomelandMovieMainScoreItem",len)
    for i,v in pairs(scoreList) do
        if curScore ~= v[1] then
            curScore = v[1]
            self._scoreWidgets[index]:SetData(v,self._movieData.ID)
            index = index + 1
        end
    end
end

--点击介绍
function UIHomelandMovieMainController:ExplainBtnOnClick()
    self:ShowDialog("UIHomelandMovieExplainController",self._movieData)
end

--点击隐藏
function UIHomelandMovieMainController:EyeBtnOnClick()
    self._isHide = true
    self._root:SetActive(false)
end

--点击背景图
function UIHomelandMovieMainController:MovieBGOnClick()
    if self._isHide then
        self._isHide = false
        self._root:SetActive(true)
    end
end

--计算奖励长度
function UIHomelandMovieMainController:_CountScoreLen(list)
    local len = 0
    local curScore = 0
    for i, v in pairs(list) do
        if v[1] ~= curScore then
            curScore = v[1]
            len = len + 1
        end
    end
    return len
end