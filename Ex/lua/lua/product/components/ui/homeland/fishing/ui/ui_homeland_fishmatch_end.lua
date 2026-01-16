---@class UIHomelandFishMatchEnd:UIController
_class("UIHomelandFishMatchEnd", UIController)
UIHomelandFishMatchEnd = UIHomelandFishMatchEnd

function UIHomelandFishMatchEnd:OnShow(uiParams)
    ---@type FishMatchEndType
    self._res = uiParams[1]
    self._playerGoal = uiParams[2]
    self._petGoal = uiParams[3]
    
    ---@type HomelandFishMatch
    self._match = HomelandFishMatchManager:GetInstance():GetCurFishMatch()
    self._matchID = self._match:GetMainID()

    self._pun = self:GetUIComponent("Image", "pun")
    self._scorePet1 = self:GetUIComponent("Image", "scorePet1")
    self._scorePet2 = self:GetUIComponent("Image", "scorePet2")
    self._scorePlayer1 = self:GetUIComponent("Image", "scorePlayer1")
    self._scorePlayer2 = self:GetUIComponent("Image", "scorePlayer2")
    self._winObj = self:GetGameObject("win")
    self._loseObj = self:GetGameObject("lose")
    self._achieveObj = self:GetGameObject("achieve")
    self._ani = self:GetUIComponent("Animation", "ani")
    self._atlas = self:GetAsset("UIHomelandFishMatch.spriteatlas", LoadType.SpriteAtlas)

    ---@type UIHomelandModule
    self._homeLandModule = GameGlobal.GetUIModule(HomelandModule)

    GameGlobal.UIStateManager():Lock("UIHomelandFishMatchEnd")
    Log.fatal("=================锁定UIHomelandFishMatchEnd====================")

    GameGlobal.TaskManager():CoreGameStartTask(self._FishMatchEnd,self)
end

--比赛结束页面被点击
function UIHomelandFishMatchEnd:MatchResOnClick()
    Log.debug("===================UIHomelandFishMatchEnd MatchResOnClick==============")
    local cfg = Cfg.cfg_homeland_fishmatch_main[self._matchID]
    local reward = cfg.AwardID
    if (self._res == FishMatchEndType.MATCHEND_WIN and self._match:GetWinTimes() == 1 ) or self._res == FishMatchEndType.MATCHEND_COMPLETE then
        --第一次钓鱼胜利或者比赛完成 可获得奖励
        if reward then
            local rewardList = {}
            for i = 1, #reward do
                local roleAsset = RoleAsset:New()
                roleAsset.assetid = reward[i][1]
                roleAsset.count = reward[i][2]
                table.insert(rewardList, roleAsset)
            end
            local txt = StringTable.Get("str_homeland_fishmatch_matchres_win")
            GameGlobal.UIStateManager():ShowDialog("UIHomeShowAwards", rewardList,function()
                self:SwitchPlayerIdle()
                self:SwitchState(UIStateType.UIHomeland)
                self._match:FishMatchEndReset()
            end,true,txt)
        else
            --没有奖励
            self:SwitchPlayerIdle()
            self:SwitchState(UIStateType.UIHomeland)
            self._match:FishMatchEndReset()
        end
    else
        --非第一次胜利 不可获得奖励
        self:SwitchPlayerIdle()
        self:SwitchState(UIStateType.UIHomeland)
        self._match:FishMatchEndReset()
    end
end

--钓鱼比赛结束
function UIHomelandFishMatchEnd:_FishMatchEnd(TT)
    local playerText1 = math.floor(self._playerGoal / 10)
    local playerText2 = self._playerGoal % 10
    local petText1 = math.floor(self._petGoal / 10)
    local petText2 = self._petGoal % 10

    if self._res == FishMatchEndType.MATCHEND_CLOSE then
        --中止钓鱼显示失败页面
        Log.fatal("玩家失败")
        self._ani:Play("uieffanim_N24_UIHomelandFishMatchEnd_lose")
        self._pun.sprite = self._atlas:GetSprite("N24_dyds_lose_icon")
        self._scorePet1.sprite = self._atlas:GetSprite("N24_dyds_lose_"..petText1)
        self._scorePet2.sprite = self._atlas:GetSprite("N24_dyds_lose_"..petText2)
        self._scorePlayer1.sprite = self._atlas:GetSprite("N24_dyds_uslose_"..playerText1)
        self._scorePlayer2.sprite = self._atlas:GetSprite("N24_dyds_uslose_"..playerText2)
        self._loseObj:SetActive(true)
        self:SwitchPlayerState(false)
    elseif self._res == FishMatchEndType.MATCHEND_WIN then
        Log.fatal("玩家胜利")
        self._ani:Play("uieffanim_N24_UIHomelandFishMatchEnd_win")
        self._pun.sprite = self._atlas:GetSprite("N24_dyds_win_icon")
        self._scorePet1.sprite = self._atlas:GetSprite("N24_dyds_win_"..petText1)
        self._scorePet2.sprite = self._atlas:GetSprite("N24_dyds_win_"..petText2)
        self._scorePlayer1.sprite = self._atlas:GetSprite("N24_dyds_uswin_"..playerText1)
        self._scorePlayer2.sprite = self._atlas:GetSprite("N24_dyds_uswin_"..playerText2)
        self._winObj:SetActive(true)
        self:SwitchPlayerState(true)
    elseif self._res == FishMatchEndType.MATCHEND_LOSE then
        Log.fatal("玩家失败")
        self._ani:Play("uieffanim_N24_UIHomelandFishMatchEnd_lose")
        self._pun.sprite = self._atlas:GetSprite("N24_dyds_lose_icon")
        self._scorePet1.sprite = self._atlas:GetSprite("N24_dyds_lose_"..petText1)
        self._scorePet2.sprite = self._atlas:GetSprite("N24_dyds_lose_"..petText2)
        self._scorePlayer1.sprite = self._atlas:GetSprite("N24_dyds_uslose_"..playerText1)
        self._scorePlayer2.sprite = self._atlas:GetSprite("N24_dyds_uslose_"..playerText2)
        self._loseObj:SetActive(true)
        self:SwitchPlayerState(false)
    elseif self._res == FishMatchEndType.MATCHEND_COMPLETE then
        Log.fatal("比赛完成")
        self._ani:Play("uieffanim_N24_UIHomelandFishMatchEnd_achieve")
        self._pun.sprite = self._atlas:GetSprite("N24_dyds_achieve_icon")
        self._scorePet1.sprite = self._atlas:GetSprite("N24_dyds_achieve_"..petText1)
        self._scorePet2.sprite = self._atlas:GetSprite("N24_dyds_achieve_"..petText2)
        self._scorePlayer1.sprite = self._atlas:GetSprite("N24_dyds_usachieve_"..playerText1)
        self._scorePlayer2.sprite = self._atlas:GetSprite("N24_dyds_usachieve_"..playerText2)
        self._achieveObj:SetActive(true)
        self:SwitchPlayerState(self._playerGoal > self._petGoal)
    end

    --延迟三秒
    GameGlobal.Timer():AddEvent(3000,function()
        GameGlobal.UIStateManager():UnLock("UIHomelandFishMatchEnd")
        Log.fatal("=================解锁UIHomelandFishMatchEnd====================")
    end)
end

--玩家是否胜利
function UIHomelandFishMatchEnd:SwitchPlayerState(isWin)
    ---@type HomelandClient
    local homelandClient = self._homeLandModule:GetClient()
    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()

    characterController:SetForbiddenMove(true)

    if isWin then
        characterController:SetAnimatorTrigger("IsHappy")
    else
        characterController:SetAnimatorTrigger("IsSigh")
    end
end

--让玩家变成idle状态
function UIHomelandFishMatchEnd:SwitchPlayerIdle()
    Log.debug("===================UIHomelandFishMatchEnd SwitchPlayerIdle==============")
    ---@type HomelandClient
    local homelandClient = self._homeLandModule:GetClient()
    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()

    characterController:SetForbiddenMove(false,HomelandActorStateType.Idle)
    characterController:ResetStateAndAnim()
end
