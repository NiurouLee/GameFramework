--
---@class UIWidgetAutoFight : UICustomWidget
_class("UIWidgetAutoFight", UICustomWidget)
UIWidgetAutoFight = UIWidgetAutoFight
--初始化
function UIWidgetAutoFight:OnShow(uiParams)
    --允许模拟输入
    self.enableFakeInput = true
    self:InitWidget()
end
--获取ui组件
function UIWidgetAutoFight:InitWidget()
    --generated--
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    ---@type string 自动按钮的普通sprite name
    self._autoBtnNormalSpriteName = "thread_junei_btn3"
    ---@type string 自动按钮的按下sprite name
    self._autoBtnPressedSpriteName = "thread_junei_btn4"
    self._autoBtnLockSpriteName = "thread_zd_suo1"

    ---@type bool 自动状态
    self:SetIsAutoFighting(false)
    self._banAutoFightBtn = false
    self._goAutoFightMask = self:GetGameObject("imgAutoFightMask") --自动战斗蒙版
    self._goAutoFightMask:SetActive(false)
    self._autoFightBtn = self:GetGameObject("btnAutoFight")
    self._autoFightImage = self:GetUIComponent("Image", "btnAutoFight")

    self._autoFightForbiddenStr = StringTable.Get("str_battle_forbidden_operation_in_autofight")

    self.autoParam = self:CheckAutoEnable()
    if self.autoParam.bShow then
        self._autoFightBtn:SetActive(true)
        if self.autoParam.bEnable then
            --todo-- 换图片
            self._autoFightImage.sprite = self._uiAtlas:GetSprite(self._autoBtnNormalSpriteName)
            -- self._autoFightImage.color = Color.white
            if self.autoParam.bSerialRunning then
                self:BtnAutoFightOnClick()
            end
        else
            --todo-- 换图片
            self._autoFightImage.sprite = self._uiAtlas:GetSprite(self._autoBtnLockSpriteName)
            -- self._autoFightImage.color = Color.gray
        end
    else
        self._autoFightBtn:SetActive(false)
    end

    self._autoBtnPool = self:GetUIComponent("UISelectObjectPath", "auto")
    self._manualBtns = self:GetGameObject("manual")
    
    self:RegisterEvent()
    --generated end--
end
--设置数据
function UIWidgetAutoFight:SetData(matchEnterData,chessPanelPool)
    if matchEnterData:GetMatchType() == MatchType.MT_Chess and (chessPanelPool--[[FIXME:打过整包更新ab后应该删除这个条件]]) then
        self:GetGameObject("fightCtrl"):SetActive(false)
        self:GetGameObject("chessRTBtn"):SetActive(true)
        ---@type UICustomWidgetPool
        local timeSpeedPool = self:GetUIComponent("UISelectObjectPath", "chessTimeSpeed")
        self.timeSpeed = timeSpeedPool:SpawnObject("UIBattleTimeSpeed")
    else
        self:GetGameObject("fightCtrl"):SetActive(true)
        self:GetGameObject("chessRTBtn"):SetActive(false)
        ---@type UICustomWidgetPool
        local timeSpeedPool = self:GetUIComponent("UISelectObjectPath", "timeSpeed")
        self.timeSpeed = timeSpeedPool:SpawnObject("UIBattleTimeSpeed")
    end
    local serialMd = self:GetModule(SerialAutoFightModule)
    if serialMd:IsRunning() then
        --自动战斗开启
        if not self:IsAutoFighting() then
            self:BtnAutoFightOnClick()
        end
    end
    if serialMd:IsRunning() and serialMd:GetTotalCount() > 1 then
        self._autoBtn = self._autoBtnPool:SpawnObject("UIWidgetSerialButton")
        self._autoBtn:SetData(OpenUISerialFightInfoState.InGame)
        self._manualBtns:SetActive(false)
    end
    self:AttachEvent(GameEventType.CancelSerialAutoFight, self.OnCancelSerialAutoFight)
end
function UIWidgetAutoFight:RegisterEvent()
    self:AttachEvent(GameEventType.BanAutoFightBtn, self.OnBanAutoFightBtn)
    self:AttachEvent(GameEventType.GuidePlayerShow, self.OnGuidePlayerShow)
end
function UIWidgetAutoFight:CheckAutoEnable()
    return GameGlobal.GetUIModule(MatchModule):CheckAutoEnable()
end
function UIWidgetAutoFight:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIWidgetAutoFight:SetIsAutoFighting(isAutoFighting)
    GameGlobal.GetUIModule(MatchModule):SetIsAutoFighting(isAutoFighting)
end
function UIWidgetAutoFight:OnBanAutoFightBtn(val)
    self._banAutoFightBtn = val
end
--按钮点击
function UIWidgetAutoFight:BtnAutoFightOnClick(go)
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        { ui = "UIWidgetAutoFight", input = "BtnAutoFightOnClick", args = {} }
    )

    if self.autoParam.bShow == false then
        return
    end
    if self.autoParam.bEnable == false then
        ToastManager.ShowToast(StringTable.Get(self.autoParam.disableMsg))
        return
    end

    
    ---@type GameStateID
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    --UI禁用
    if self._banAutoFightBtn then
        --幻境状态下弹提示
        if coreGameStateID == GameStateID.MirageEnter or coreGameStateID == GameStateID.MirageWaitInput or
            coreGameStateID == GameStateID.MirageRoleTurnor or coreGameStateID == GameStateID.MirageMonsterTurn or
            coreGameStateID == GameStateID.MirageEnd
        then
            ToastManager.ShowToast(StringTable.Get("str_battle_auto_disable_BossYou"))
        end
        return
    end
    --预览状态下禁用
    if coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget or
        coreGameStateID == GameStateID.PickUpChainSkillTarget
    then
        return
    end

    self:SetIsAutoFighting(not self:IsAutoFighting())

    GameGlobal.UAReportForceGuideEvent(
        "FightClick",
        {
            "BtnAutoFightOnClick",
            self:IsAutoFighting() and 1 or 0
        },
        false,
        true
    )

    if self:IsAutoFighting() then
        self._autoFightImage.sprite = self._uiAtlas:GetSprite(self._autoBtnPressedSpriteName)
    else
        self._autoFightImage.sprite = self._uiAtlas:GetSprite(self._autoBtnNormalSpriteName)
    end
    self._goAutoFightMask:SetActive(self:IsAutoFighting())
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AutoFight, self:IsAutoFighting())

    --一次连续自动战斗的时候取消连续自动战斗
    local md = GameGlobal.GetModule(SerialAutoFightModule)
    if not self:IsAutoFighting() and md:IsRunning() then
        md:CancelSerialAutoFight()
        ToastManager.ShowToast(StringTable.Get("str_battle_serial_fight_finished"))
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
end
--按钮点击
function UIWidgetAutoFight:ImgAutoFightMaskOnClick(go)
    ToastManager.ShowToast(self._autoFightForbiddenStr)
end
function UIWidgetAutoFight:OnCancelSerialAutoFight()
    if self._autoBtn then
        self._autoBtn:Hide()
    end
    self._manualBtns:SetActive(true)
end
function UIWidgetAutoFight:GetSpeedBtn()
    if self.timeSpeed then
        self.timeSpeed:ForceDefaultSpeed()
        return self.timeSpeed:GetGameObject("img")
    end
end

function UIWidgetAutoFight:OnGuidePlayerShow()
    local trigger = false
    if self.autoParam.bShow then
        if self.autoParam.bEnable then
            if self.autoParam.bTriggerGuideBattle then
                trigger = true
            else
                trigger = false
            end
        end
    end

    if not trigger then
        return
    end
    local guideModule = self:GetModule(GuideModule)
    if guideModule:GuideInProgress() then
        return
    end
    local matchModule = GameGlobal.GetModule(MatchModule)
    local enterData = matchModule:GetMatchEnterData()

    local matchType = enterData:GetMatchType()
    -- 主线
    if matchType == MatchType.MT_Mission then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideMissionAutoBattle)
    elseif matchType == MatchType.MT_ResDungeon then --  资源本
        GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideResAutoBattle)
    end
end

function UIWidgetAutoFight:GetCurMainStateID()

end