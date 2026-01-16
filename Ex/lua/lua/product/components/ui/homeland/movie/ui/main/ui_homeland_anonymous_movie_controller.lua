---@class UIHomelandAnonymousMovieController:UIController
_class("UIHomelandAnonymousMovieController", UIController)
UIHomelandAnonymousMovieController = UIHomelandAnonymousMovieController

function UIHomelandAnonymousMovieController:Constructor()
    self._movieCfgData = MovieDataHelper:New()
    self._widgets={}
    self._anonymousID=nil

    self.received=false

    
end

function UIHomelandAnonymousMovieController:OnShow(uiParams)
    self._anonymousID=uiParams[1]
    self:InitWidget()
    self:_UIItemSetData(self._anonymousID)
   
    self:SetData(self._anonymousID)
end

function UIHomelandAnonymousMovieController:OnHide()
    
end

function UIHomelandAnonymousMovieController:InitWidget()
    self._petHead=self:GetUIComponent("Image","petHead")
    self._nameText = self:GetUIComponent("UILocalizationText", "nameText")
    self._acceptBtnImage = self:GetUIComponent("Image", "acceptBtn")
    self._acceptBtn = self:GetGameObject("acceptBtn")
    self._received = self:GetGameObject("received")
    self._nextBtn = self:GetGameObject("nextBtn")
    self._btnBack = self:GetGameObject("btnBack")
    self._assestContent = self:GetUIComponent("UISelectObjectPath","Content")
    self._assestObject = self:GetGameObject("Content")
    self._letterText=self:GetUIComponent("UILocalizationText","letterText")
    self._topText = self:GetUIComponent("UILocalizationText", "topText")
    self._acceptTxt = self:GetUIComponent("UILocalizationText", "acceptTxt")
    self._receivedTxt = self:GetUIComponent("UILocalizationText", "receivedTxt")
    self._nextTxt = self:GetUIComponent("UILocalizationText", "nextTxt")
    self._atlas = self:GetAsset("UIMovieSecond.spriteatlas", LoadType.SpriteAtlas)
end

function UIHomelandAnonymousMovieController:_UIItemSetData(anonymousID)
    self._letterCfg = Cfg.cfg_homeland_anonymous_letter[anonymousID]
    self._petHead.sprite = self._atlas:GetSprite(self._letterCfg.PetIcon)
    self._nameText:SetText(StringTable.Get(self._letterCfg.PetName))
    self._letterText:SetText(StringTable.Get(self._letterCfg.Text))

    self._topText:SetText(StringTable.Get("str_movie_letter_text_4"))
    self._receivedTxt:SetText(StringTable.Get("str_movie_letter_text_5"))
    self._acceptTxt:SetText(StringTable.Get("str_movie_letter_text_6"))
    self._nextTxt:SetText(StringTable.Get("str_movie_letter_text_7"))
end

function UIHomelandAnonymousMovieController:SetAnonymousData(anonymousID)

    self._letterCfg = Cfg.cfg_homeland_anonymous_letter[anonymousID]
    local assest = self._letterCfg.Rewards
    return assest
end

function UIHomelandAnonymousMovieController:SetData(anonymousID)

    local itemInfo = self:SetAnonymousData(anonymousID)

    --local assest = self._letterCfg.Rewards
    -- self._widgets = self._assestContent:SpawnObjects("UIHomelandAnonymousMovieItem", #itemInfo)
    self._assestContent:SpawnObjects("UIHomelandAnonymousMovieItem", #itemInfo)
    self._widgets = self._assestContent:GetAllSpawnList()

    local index = 1
    for i, v in pairs(itemInfo) do
        self._widgets[index]:SetData(v,self.received)
        index = index + 1
    end
end

function UIHomelandAnonymousMovieController:AcceptBtnOnClick(TT)
    --奖励图标显示已经领取
    -- self.received=true
    -- self:SetData(self._anonymousID)
    self:OnAcceptClick()
    
end

function UIHomelandAnonymousMovieController:NextBtnOnClick(TT)

    self._received:SetActive(false)
    self._nextBtn:SetActive(false)
    self._acceptBtn:SetActive(true)

    self._movieDataHelper = MovieDataHelper:New()
    local type,nextID
    type,nextID=self._movieDataHelper:ShowOrNot()
    self:_UIItemSetData(nextID)
    self:SetData(nextID)
    self._anonymousID = nextID
end

function UIHomelandAnonymousMovieController:OnAcceptClick()

    GameGlobal.TaskManager():StartTask(self.HandleGetAnonymousLetterRewardTask, self,self._anonymousID)
end

--获得奖励剧本
function UIHomelandAnonymousMovieController:HandleGetAnonymousLetterRewardTask(TT,anonymous_letter_id)
    ---@type HomelandModule
    local homeModule = GameGlobal.GetModule(HomelandModule)
    local result,asset = homeModule:HandleGetAnonymousLetterReward(TT, anonymous_letter_id)


    if result:GetSucc() then
        self._acceptBtn:SetActive(false)
        self._received:SetActive(true)

        --奖励弹窗
        if #asset > 0 then
            GameGlobal.UIStateManager():ShowDialog("UIHomeShowAwards", asset, nil,
            false,
            nil
        )
        end
        --奖励图标显示已经领取
        self.received=true
        self:SetData(anonymous_letter_id)

        --查看是否保存了数据
        local Anonymouslist = homeModule:GetAnonymousLetterRreward()
        if Anonymouslist~=nil then
            for i, v in ipairs(Anonymouslist) do
                if anonymous_letter_id==v then
                    Log.fatal("数据保存成功")
                end
            end
        end

        self._movieDataHelper = MovieDataHelper:New()
        local type,nextID
        type,nextID=self._movieDataHelper:ShowOrNot()
        if type then
            self._nextBtn:SetActive(true)
            --匿名内容数据刷新
            self.received=false

        else
            --显示返回按钮
            self._btnBack:SetActive(true)
        end

    else
        Log.fatal("获取奖励失败,错误码" .. result.m_result)
    end

end

--返回
function UIHomelandAnonymousMovieController:BtnBackOnClick(TT)
    local controller = GameGlobal.UIStateManager():GetController("UIHomelandMovieMainController")--测试
    local cfg = Cfg.cfg_homeland_movie_tag{}
    local tag = cfg[2].MovieId
    controller:InitDramaList(tag)--这里是有个问题所以调了两次，不然第一个剧本会没有被选择且点击不了
    controller:InitDramaList()
    self:CloseDialog()
end

