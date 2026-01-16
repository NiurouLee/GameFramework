---@class UIHomelandMovieClosingController:UIController
_class("UIHomelandMovieClosingController", UIController)
UIHomelandMovieClosingController = UIHomelandMovieClosingController

function UIHomelandMovieClosingController:OnShow(uiParams)
    self._record = uiParams[1]
    self._closingItem = uiParams[2]
    self._scoreList= uiParams[3]
    self._homelandMovieClosingManager = uiParams[4]

    self:AttachEvent(GameEventType.UIHomelandMovieSaved, self.OnMovieSaved)
    self._atlas = self:GetAsset("UIHomelandMovie.spriteatlas", LoadType.SpriteAtlas)

    self:_GetComponents()
    self:_OnValue()
end

function UIHomelandMovieClosingController:OnHide()
    self._bsController:StopShowBulletScreen()

    if self._timeEvent then
        GameGlobal.Timer():CancelEvent(self._timeEvent)
        self._timeEvent = nil
    end

    if self._AudioGoodId then
        AudioHelperController.StopUISound(self._AudioGoodId)
        self._AudioGoodId = nil
    end

end

function UIHomelandMovieClosingController:_GetComponents()
    self._totalScoreList = self:GetGameObject("totalScoreList")
    self._actorScoreList = self:GetGameObject("actorScoreList")
    self._sceneScoreList = self:GetGameObject("sceneScoreList")
    self._skillScoreList = self:GetGameObject("skillScoreList")

    self._BulletScreen = self:GetUIComponent("UISelectObjectPath", "BulletScreen")
    self._SaveBtnObj = self:GetGameObject("SaveBtnObj")
    self._SavedTipObj = self:GetGameObject("SavedTip")
    self._qiubuEvaluateTex = self:GetUIComponent("UILocalizationText", "qiubuEvaluateTex")
    self._qiubuEvaluateIcon = self:GetUIComponent("Image", "qiubuEvaluateIcon")

    self._resultRawImage = {}
    self._resultRawImage[1] = self:GetGameObject( "ResultRawImage1")
    self._resultRawImage[2] = self:GetGameObject("ResultRawImage2")
    self._resultRawImage[3] = self:GetGameObject("ResultRawImage3")
    self._resultRawImage[4]= self:GetGameObject("ResultRawImage4")

    self._totalScoreIcon = self:GetGameObject("totalScoreIcon")
end

function UIHomelandMovieClosingController:_OnValue()

    self._SaveBtnObj:SetActive(not self._record)

    self:SetScoreStar(self._totalScoreList, self._scoreList.totalScore, true)
    self:SetScoreStar(self._actorScoreList, self._scoreList.actorScore)
    self:SetScoreStar(self._sceneScoreList, self._scoreList.itemScore)
    self:SetScoreStar(self._skillScoreList, self._scoreList.optionScore)

    self._bsController = self._BulletScreen:SpawnObject("UIHomelandBulletScreenController")
    self._bsController:SetData(
        self._closingItem.BSRefreshTime, 
        self._closingItem.BSMoveSpeed, 
        self._scoreList.actorScore,
        self._scoreList.itemScore,
        self._scoreList.optionScore,
        self._scoreList.totalScore
    )
    self._bsController:BeginShowBulletScreen()
    --处理结算表现todo
    self._qiubuEvaluateTex:SetText(StringTable.Get(self._closingItem.Description))
    self._qiubuEvaluateIcon.sprite = self._atlas:GetSprite(self._closingItem.DescIcon)
    self._resultRawImage[self._closingItem.Condition]:SetActive(true)

    if self._closingItem.Condition == 4 then --庆祝10293
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioCelebrate)
    elseif self._closingItem.Condition == 3 then  --很好10117 HomelandAudioGood
        AudioHelperController.RequestUISoundSync(CriAudioIDConst.HomelandAudioCelebrate)
        self._AudioGoodId = AudioHelperController.PlayUISoundResource(CriAudioIDConst.HomelandAudioCelebrate, true)
    elseif self._closingItem.Condition == 2 then  --普通10116
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioNormal)
    elseif self._closingItem.Condition == 1 then  --悲伤1716
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.HomelandAudioLose)
    end

    if self._AudioGoodId then
        self._timeEvent = GameGlobal.Timer():AddEvent(
        2000,
        function()
            AudioHelperController.StopUISound(self._AudioGoodId)
            self._AudioGoodId = nil
            self._timeEvent = nil
        end
    )
    end

end

function UIHomelandMovieClosingController:SetScoreStar(listObj, score, isTotal)
    local integerScore = math.floor(score)
    for i = 0, listObj.transform.childCount - 1 do
        local star = listObj.transform:GetChild(i)
        local sc = i + 1
        if sc <= integerScore then
            star:Find("Full").gameObject:SetActive(true)
        elseif (i + 0.5) <= score then
            star:Find("Half").gameObject:SetActive(true)
        end
    end
    
    if isTotal and integerScore == 5 then
        self._totalScoreIcon:SetActive(true)
    end
end

function UIHomelandMovieClosingController:OnMovieSaved()
    self._SaveBtnObj:SetActive(false)
    self._SavedTipObj:SetActive(true)
end

function UIHomelandMovieClosingController:SaveBtnOnClick()
    self:ShowDialog("UIHomelandMovieSaveName", MoviePrepareData:GetInstance():GetPstId())
end

function UIHomelandMovieClosingController:FinishBtnOnClick()
    self._bsController:StopShowBulletScreen()
    local mHomeland = GameGlobal.GetModule(HomelandModule)
    local mUIHomeland = mHomeland:GetUIModule()
    GameGlobal.TaskManager():StartTask(function(TT)
        mUIHomeland:EnterHomelandAfterMovieMaker(TT)
    end) 
end