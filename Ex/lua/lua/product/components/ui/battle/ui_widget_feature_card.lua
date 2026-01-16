--
---@class UIWidgetFeatureCard : UICustomWidget
_class("UIWidgetFeatureCard", UICustomWidget)
UIWidgetFeatureCard = UIWidgetFeatureCard
--初始化
function UIWidgetFeatureCard:OnShow(uiParams)
    self:InitWidget()
end
function UIWidgetFeatureCard:OnHide()
    if self._player then
        if self._player:IsPlaying() then
            self._player:Stop()
        end
    end
    if self._timerHandler then
        GameGlobal.Timer():CancelEvent(self._timerHandler)
        self._timerHandler = nil
    end
end
--获取ui组件
function UIWidgetFeatureCard:InitWidget()
    --允许模拟输入
    self.enableFakeInput = true
    --generated--
    ---@type UnityEngine.UI.Image
    self._imageNormal = self:GetUIComponent("Image", "ImageNormal")
    self._imageNormalGo = self:GetGameObject("ImageNormal")
    self._imageWarningGo = self:GetGameObject("ImageWarning")
    self._imageNotFullFrontGo = self:GetGameObject("ImageNotFullFront")
    self._imageFullFrontGo = self:GetGameObject("ImageFullFront")
    ---@type UnityEngine.UI.Image
    self._uIWidgetFeatureCard = self:GetUIComponent("Image", "UIWidgetFeatureCard")

    ---@type UnityEngine.Animation
    self._anim = self:GetUIComponent("Animation", "UIWidgetFeatureCard")
    ---@type UnityEngine.GameObject
    --self._cardInfoGenGo = self:GetGameObject("CardInfoGen")
    ---@type UILocalizationText
    self._cardCountText = self:GetUIComponent("UILocalizationText", "CardCountText")
    ---@type UICustomWidgetPool 技能UI widget pool
    self._cardInfoPool = self:GetUIComponent("UISelectObjectPath", "CardInfoGen")
    ---@type UIWidgetFeatureCardInfo 技能UI
    --self._cardUI = self._cardInfoPool:SpawnObject("UIWidgetFeatureCardInfo")

    self._skillID = 0
    ---@type UIBattle
    self._uiBattle = nil
    self._switchTimeEvent = nil
    self._switchTimeLength = 100 --切换头像的延迟时间
    self:InitLocalData()
    self:RegisterEvent()
    --generated end--
end
function UIWidgetFeatureCard:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIWidgetFeatureCard:InitLocalData()
    self._cardAnimNames = {
        [FeatureCardType.A]="UIWidgetFeatureCard_sun",
        [FeatureCardType.B]="UIWidgetFeatureCard_moon",
        [FeatureCardType.C]="UIWidgetFeatureCard_star",
    }
end
function UIWidgetFeatureCard:RegisterEvent()
    self:AttachEvent(GameEventType.FeatureUIPlayDrawCard, self._OnFeatureUIPlayDrawCard)
    self:AttachEvent(GameEventType.FeatureUIRefreshCardNum, self._OnFeatureUIRefreshCardNum)
end
function UIWidgetFeatureCard:_OnFeatureUIPlayDrawCard(cardType)
    local cardAnimName = self._cardAnimNames[cardType]
    if cardAnimName then
        self._player = EZTL_Player:New()
        local tl =
            EZTL_Sequence:New(
            {
                EZTL_PlayAnimation:New(self._anim, cardAnimName),
                EZTL_Callback:New(
                    function()
                        self:RefreshCardNum()
                    end
                )
            },
            "抽牌ui动效"
        )
        self._player:Play(tl)
    end
end
function UIWidgetFeatureCard:_OnFeatureUIRefreshCardNum()
    --tmp
    self:RefreshCardNum()
end
function UIWidgetFeatureCard:SetUIBattle(uiBattle)
    self._uiBattle = uiBattle
end
function UIWidgetFeatureCard:GetUIBattle()
    return self._uiBattle
end
--设置数据
---@param skillInitData FeatureEffectParamCard
function UIWidgetFeatureCard:SetData(skillInitData)
    self._cardInitData = skillInitData
    self._skillDic = self._cardInitData:GetCardSkillDic()
    self:RefreshCardNum()
end
--
function UIWidgetFeatureCard:RefreshCardNum()
    local cardNum = FeatureServiceHelper.GetCurCardCount()
    self._cardCountText:SetText(cardNum)
    if cardNum > 0 then
        self._imageNormalGo:SetActive(false)
        self._imageWarningGo:SetActive(true)
        self._imageFullFrontGo:SetActive(true)
        self._imageNotFullFrontGo:SetActive(false)
    else
        self._imageNormalGo:SetActive(true)
        self._imageWarningGo:SetActive(false)
    end
end
--按钮点击
function UIWidgetFeatureCard:UIWidgetFeatureCardOnClick(go)
    if self:IsAutoFighting() then
        return
    end
    self:OnClickUI()
end
function UIWidgetFeatureCard:OnClickUI()
    local canCastSkill = true
    if canCastSkill then
        ---只有在局内是等待输入的时候，才能显示主动技弹框
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        local enableInput = GameGlobal:GetInstance():IsInputEnable()

        if coreGameStateID == GameStateID.WaitInput and enableInput == true then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, self._skillID)
            --GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
            self:ShowCardInfoUI()
        elseif coreGameStateID == GameStateID.PreviewActiveSkill or coreGameStateID == GameStateID.PickUpActiveSkillTarget
        then
            if self._switchTimeEvent == nil then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UISwitchActiveSkillUI)
                --切换预览
                self:ShowCardInfoUI()
                
                Log.notice("preclickhead card skill", self._skillID)
                ---先通知战斗，记录一次技能ID
                --GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
                --通知战斗，切换预览
                self._switchTimeEvent = GameGlobal.Timer():AddEvent(
                    self._switchTimeLength,
                    function()
                        self._switchTimeEvent = nil
                        Log.notice("preview card skill", self._skillID)
                    end
                )

                --GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetLastPreviewPetId, self.petPstID)
            else
                Log.notice("still in switch", self._skillID)
            end
        end
    end
end
---显示主动技能释放UI
---@param petWidget UIWidgetBattlePet
---@param skillId number
---@param leftPower number
---@param canCast boolean
function UIWidgetFeatureCard:ShowCardInfoUI()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow,true,FeatureType.Card)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UICancelActiveSkillCast)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PauseGuideWeakLine)
    ---@type SkillConfigData
    --local skillConfigData = self._skillConfigData
    local canCast = true
    local castCb = function(castSkillID, pickUpType,delayCloseMs)
        self:OnCastSkill(castSkillID, pickUpType,delayCloseMs)
    end
    local cancelCb = function(curSkillID)
        self:OnCancelSkill(curSkillID)
    end
    self._uiBattle:GetFeatureCardUI(self._cardInitData:GetUiType()):Init(
    --self._cardUI:Init(
        self._cardInitData,
        castCb,
        cancelCb
    )
    ---@type SkillPickUpType
    --local pickUpType = skillConfigData:GetSkillPickType()
    --self._pickUpType = pickUpType

    --选格子类型的技能，点头像直接开始预览，不需要再点发动按钮
    -- if pickUpType ~= SkillPickUpType.None then
    --     self._isCurPetSkillReady = canCast --暂存当前星灵主动技是否可发动
    --     self:_PreviewPickUpSkill(self._skillID, pickUpType)
    --     --self.cancelActiveSkillBtn:SetActive(false)
    --     self._cardUI:ShowCancelBtn(false)
    -- else
    --     --直接发动类的技能需要点击空白取消
    --     --self.cancelActiveSkillBtn:SetActive(true)
    --     self._cardUI:ShowCancelBtn(true)
    -- end

    --播放语音
    -- local pm = GameGlobal.GetModule(PetAudioModule)
    -- pm:PlayPetAudio("StandBy", petWidget._petTemplateID)

    --self._cardInfoGenGo:SetActive(true)
    self._uiBattle:ShowFeatureCardInfo(true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
end

function UIWidgetFeatureCard:OnCastSkill(castSkillID, pickUpType,delayCloseMs)
    self:Lock("UIAnimOnCast")
    --发动技能后，判断技能类型
    if pickUpType == SkillPickUpType.None then
        --播放技能音效
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CastPersonaSkill, castSkillID)
        --self:ClearPower()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIResetLastPreviewPetId)
        self:HideCardInfoUI(delayCloseMs)
    elseif pickUpType == SkillPickUpType.PickSwitchInstruction then
        Log.fatal("[UIWidgetFeaturePersonaSkill] cast skill pick up type error:", pickUpType)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, true)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
        self:HideCardInfoUI(delayCloseMs)
    else
        Log.fatal("[UIWidgetFeaturePersonaSkill] cast skill pick up type error:", pickUpType)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.EnablePickUpSkillCast, false)
        local petPstID = 0
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActiveSkillPickUp, castSkillID, petPstID)
        self:HideCardInfoUI(delayCloseMs)
    end
end
function UIWidgetFeatureCard:OnCancelSkill(curSkillID)
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.StopPreviewFeatureSkill,
        false,
        true,
        curSkillID,
        FeatureType.Card
    )
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, -1)
    
    self:HideCardInfoUI()
end
---隐藏技能信息界面
function UIWidgetFeatureCard:HideCardInfoUI(delayCloseMs)
    --self._cardInfoGenGo:SetActive(false)
    if delayCloseMs and delayCloseMs > 0 then
        if self._timerHandler then
            GameGlobal.Timer():CancelEvent(self._timerHandler)
            self._timerHandler = nil
        end
        self._timerHandler =  GameGlobal.Timer():AddEvent(delayCloseMs, function()
            self:UnLock("UIAnimOnCast")
            self._uiBattle:ShowFeatureCardInfo(false)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow,false,FeatureType.Card)
        end
        )
    else
        self:UnLock("UIAnimOnCast")
        self._uiBattle:ShowFeatureCardInfo(false)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UIFeatureSkillInfoShow,false,FeatureType.Card)
    end
    
end
function UIWidgetFeatureCard:OnSwitchActiveSkillUI()
    self:HideCardInfoUI()
end