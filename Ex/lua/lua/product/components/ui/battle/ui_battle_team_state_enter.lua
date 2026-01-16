_class("UIBattleTeamStateEnter", UICustomWidget)
---@class UIBattleTeamStateEnter : UICustomWidget
UIBattleTeamStateEnter = UIBattleTeamStateEnter

function UIBattleTeamStateEnter:Constructor()
    self._sldSpriteNames = {
        Normal = {"thread_jingdu1_frame", "thread_jingdu2_frame", "thread_jingdu3_frame"}, --背景，进度条，块
        Fire = {"thread_jingdu4_frame", "thread_jingdu5_frame", "thread_jingdu6_frame"},
        Stun = {"thread_jingdu1_frame", "thread_jingdu7_frame", "thread_jingdu8_frame"},
        Benumb = {"thread_jingdu9_frame", "thread_jingdu10_frame", "thread_jingdu3_frame"}
    }
end

function UIBattleTeamStateEnter:OnShow()
    ---@type UnityEngine.UI.Image
    self._hpFill = self:GetUIComponent("Image", "hpFill")
    ---@type UnityEngine.UI.Image
    self._shieldFill = self:GetUIComponent("Image", "shieldFill")
    ---@type UnityEngine.UI.Image
    self._damageFill = self:GetUIComponent("Image", "damageFill")
    ---@type UnityEngine.UI.Image
    self._overfillShieldFill = self:GetUIComponent("Image", "overfillShield")
    ---@type UnityEngine.RectTransform
    self._overfillShieldAnchor = self:GetUIComponent("RectTransform", "overfillShieldAnchor")

    ---@type UnityEngine.UI.Slider
    self._sldTeamState = self:GetUIComponent("Slider", "sldTeamState")
    ---@type UnityEngine.UI.Image
    self._imgSldBG = self:GetUIComponent("Image", "imgSldBG")
    ---@type UnityEngine.UI.Image
    self._imgSldFill = self:GetUIComponent("Image", "imgSldFill")
    ---@type UnityEngine.UI.Image
    self._imgSldFollow = self:GetUIComponent("Image", "imgSldFollow")
    self._teamStateTxt = self:GetUIComponent("UILocalizationText", "TeamStateText")
    self._teamStateNumberTxt = self:GetUIComponent("UILocalizationText", "TeamStateNumberText")
    ---@type RawImageLoader
    self._imgLogo = self:GetUIComponent("RawImageLoader", "imgLogo")
    ---@type UnityEngine.Transform
    self._teamStateGO = self:GetGameObject("TeamState").transform.parent ---队伍状态结点
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    ---@type DG.Tweening.Tweener
    self._tnr = nil
    self._changeTeamLeaderImage = self:GetUIComponent("Image", "ChangeTeamLeader")
    ---@type UILocalizationText
    self._changeTeamLeaderCountTxt = self:GetUIComponent("UILocalizationText", "count")
    --允许模拟输入
    self.enableFakeInput = true

    local leftCount = ConfigServiceHelper.GetChangeTeamLeaderCount()
    self._changeTeamLeaderCount = leftCount
    local strCount = tostring(self._changeTeamLeaderCount)
    if leftCount == -1 then
        strCount = "∞"
    end
    self._changeTeamLeaderCountTxt:SetText(strCount)
    self._changeTeamLeaderCountTxtGO = self:GetGameObject("count")
    -- 灼烧效果
    self._burnEff1 = self:GetGameObject("eff_hong_lizi")
    self._burnEff2 = self:GetGameObject("uieff_hong_huo")
    self._burnMesh = self:GetGameObject("uieff_hong")
    self._burnEff1:SetActive(false)
    self._burnEff2:SetActive(false)
    self._burnMesh:SetActive(false)

    -- 眩晕效果
    self._stunEff = self:GetGameObject("uieff_lan_lizi")
    self._stunMesh = self:GetGameObject("uieff_lan")
    self._stunEff:SetActive(false)
    self._stunMesh:SetActive(false)

    -- 麻痹
    self._benumbEff = self:GetGameObject("eff_light_lizi")
    self._benumbMesh = self:GetGameObject("uieff_huang")
    self._benumbEff:SetActive(false)
    self._benumbMesh:SetActive(false)

    --自动战斗状态
    self._autoFightState = false
    self._autoFightForbiddenStr = StringTable.Get("str_battle_forbidden_operation_in_autofight")

    --event
    self:AttachEvent(GameEventType.TeamHPChange, self.OnTeamHPChange)
    self:AttachEvent(GameEventType.AutoFight, self._AutoFight)
    self:AttachEvent(GameEventType.UIChangeTeamLeaderLeftCount, self._ChangeTeamLeaderLeftCount)

    local l_MatchEnterData = self:GetModule(MatchModule)
    local nLeaderModuleId = GameModuleID.MD_ChangeLeader
    -- 如果是资源本需要特叔处理
    if l_MatchEnterData:GetMatchType() == MatchType.MT_ResDungeon then
        nLeaderModuleId = GameModuleID.MD_ResChangeLeader
    end

    local l_RoleModule = self:GetModule(RoleModule)
    if l_RoleModule:CheckModuleUnlock(nLeaderModuleId) == false then
        self._changeTeamLeaderImage.sprite = self._atlas:GetSprite("thread_junei_icon13")
        self._changeTeamLeaderCountTxtGO:SetActive(false)
    else
        self._changeTeamLeaderImage.sprite = self._atlas:GetSprite("thread_junei_icon12")
        self._changeTeamLeaderCountTxtGO:SetActive(true)
    end
end

function UIBattleTeamStateEnter:OnHide()
    self:DetachEvent(GameEventType.TeamHPChange, self.OnTeamHPChange)
    self:DetachEvent(GameEventType.AutoFight, self._AutoFight)
    self:DetachEvent(GameEventType.UIChangeTeamLeaderLeftCount, self._ChangeTeamLeaderLeftCount)
    if self._tnr then
        self._tnr:Kill(false)
        self._tnr = nil
    end
end

function UIBattleTeamStateEnter:SetTeamLeader(petData)
    ---@type MatchPet
    self._leaderPetData = MatchPet:New(petData)
    self._imgLogo:LoadImage(self._leaderPetData:GetPetLogo())
end

function UIBattleTeamStateEnter:Init(pet_list, teamBuffList)
    local initHp = 0
    local initCurHP = 0
    ---@type PetModule
    local petModule = self:GetModule(PetModule)
    for i = 1, #pet_list do
        local petID = pet_list[i].pet_pstid
        if petID ~= FormationPetPlaceType.FormationPetPlaceType_None then
            -----@type MatchPet
            --local pet = petModule:GetPet(petID)
            local pet = MatchPet:New(pet_list[i])
            initHp = initHp + pet:GetPetHealth() ---初始血量
            initCurHP = initCurHP + pet:GetPetCurHealth()
        end
    end
    self._teamBuffList = teamBuffList

    -- 初始盾值（如果有的话）是从哪儿取？
    local teamHealthBlock = {
        isLocalTeam = true,
        currentHP = initCurHP,
        maxHP = initHp,
        shield = 0,
        hitpoint = initCurHP
    }

    self:OnTeamHPChange(teamHealthBlock)

    self._teamStateTxt:SetText(StringTable.Get("str_battle_state_normal"))
    self._teamStateNumberTxt:SetText("100%")
    ---@type MatchPet
    self._leaderPetData = MatchPet:New(pet_list[1])
    self._imgLogo:LoadImage(self._leaderPetData:GetPetLogo())

    if GameGlobal:GetInstance().GetModule(MatchModule):GetMatchType() == MatchType.MT_Maze then
        local per = initCurHP / initHp
        if per <= 0 then
            per = 0
        elseif per <= 0.01 then
            per = 1
        else
            per = math.floor(per * 100 + 0.5)
        end
        local perText = per .. "%"
        self._teamStateNumberTxt:SetText(perText)
    end
    self:CorrectFollowPos(initCurHP, initHp)
end
function UIBattleTeamStateEnter:ShowChangeTeamLeaderData()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowChangeTeamLeaderData)
end
function UIBattleTeamStateEnter:TeamStateOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIBattleTeamStateEnter", input = "TeamStateOnClick", args = {}}
    )
    if self._autoFightState then
        ToastManager.ShowToast(self._autoFightForbiddenStr)
        return
    end

    self:ShowDialog(
        "UIBattleTeamState",
        self._leaderPetData,
        self._teamStateGO,
        self.curHP,
        self.maxHP,
        self._teamBuffList
    )
end

--- callback: GameEventType.TeamHPChange
function UIBattleTeamStateEnter:OnTeamHPChange(teamHealthBlock)
    if teamHealthBlock.isLocalTeam then
        self:_RefreshTeamUIHP(teamHealthBlock)
        self:_RefreshTeamShield(teamHealthBlock)
    end
end

function UIBattleTeamStateEnter:_RefreshTeamUIHP(teamHealthBlock)
    local nHP = teamHealthBlock.currentHP
    local nMaxHP = teamHealthBlock.maxHP
    local nHitpoint = teamHealthBlock.hitpoint

    if nHP < 0 then
        nHP = 0
    end
    if nHP > nMaxHP then
        nHP = nMaxHP
    end

    self.maxHP = nMaxHP
    self.curHP = nHP
    --四舍五入显示
    local hpPercent = math.floor(nHP / nMaxHP * 100 + 0.5)
    hpPercent = hpPercent - hpPercent % 1
    if hpPercent == 0 and nHP > 0 then
        hpPercent = 1
    end
    self.hpPercent = hpPercent
    self._hpFill.fillAmount = hpPercent * 0.01
    -- self:CorrectFollowPos(nHP, nMaxHP)
    self:CorrectEffValue()
    self._teamStateNumberTxt:SetText(string.format("%d%%", hpPercent))

    local hitpointPercent = nHitpoint / nMaxHP
    if hitpointPercent < 0.01 then
        hitpointPercent = 0.01
    end
    self._damageFill:DOFillAmount(hitpointPercent, 0.3)

    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.ShowHideLowHpWarning,
        hpPercent <= BattleConst.LowHpWarningPercent
    )
end

function UIBattleTeamStateEnter:_RefreshTeamShield(teamHealthBlock)
    local nHP = teamHealthBlock.currentHP
    local nMaxHP = teamHealthBlock.maxHP
    local nShield = teamHealthBlock.shield or 0

    local nOverfillShield = math.max(0, nHP + nShield - nMaxHP)

    if nOverfillShield <= 0 then
        self._shieldFill.fillAmount = math.max((nHP + nShield) / nMaxHP, 0.01)
        self._overfillShieldFill.fillAmount = 0
    else
        self._shieldFill.fillAmount = 1

        --[[
            _SEARCH_THIS_IN_CODE_FYI_
            解释一下界面中溢出盾的显示实现：
            * overfillShieldAnchor 是一个遮罩，锚点被设置为【宽度减小时自右向左收回】的效果
              通过控制它的宽度，可以遮挡护盾条，实现溢出护盾【以当前血量位置为起点】的需求
              本来在矩形遮罩完全满足需要的情况下，使用RectMask2D组件，不需要额外的mask图资源
              但在设置父节点至其他界面时会有问题，所以用空Image+Mask组成
            * overfillShield 是真正的护盾图，被设置为【根据数值自右向左填充】的效果
              通过控制它的填充，可以实现【溢出盾显示和扣除】的需求
            * _SEARCH_THIS_IN_CODE_FYI_ 是一个没有功能的节点，只是为了让你看到这段文本才放在那。

            为计算方便，素材宽度被写成了常量，如果资源大小变了，需要改一下常量的值。
            当这段逻辑变化时，请同时修改注释。
        ]]
        local anchorVal = math.max(nHP / nMaxHP, 0.01)
        local sizeDelta = self._overfillShieldAnchor.sizeDelta
        self._overfillShieldAnchor.sizeDelta =
            Vector2(anchorVal * BattleConst.UIBattleTeamStateEnter_ShieldBarWidth, sizeDelta.y)

        local fillVal = 1
        if nOverfillShield < nHP then
            fillVal = 1 - ((nHP - nOverfillShield) / nMaxHP)
        end
        self._overfillShieldFill.fillAmount = fillVal
    end
end

function UIBattleTeamStateEnter:OnChangeBuff(teamBuffList)
    if teamBuffList == nil then
        return
    end

    self._teamBuffList = teamBuffList

    local i = 1
    self:StartTask(
        function(TT)
            YIELD(TT) --等一帧等self._teamBuffList更新
            if #self._teamBuffList <= 0 then
                self.curEffectType = nil
                self._teamStateTxt:SetText(StringTable.Get("str_battle_state_normal"))

                self._imgSldBG.sprite = self._atlas:GetSprite(self._sldSpriteNames.Normal[1])
                self._imgSldFill.sprite = self._atlas:GetSprite(self._sldSpriteNames.Normal[2])
                self._imgSldFollow.sprite = self._atlas:GetSprite(self._sldSpriteNames.Normal[3])
                self:SetEffectActive()
            elseif #self._teamBuffList == 1 then
                self:FlushSldImg(1)
            else
                if self._tnr then
                    self._tnr:Kill(true)
                end
                self._tnr =
                    self._imgSldFollow:DOFade(1, 1):SetLoops(-1, DG.Tweening.LoopType.Restart):OnStepComplete(
                    function()
                        self:FlushSldImg(i)
                        if i < #self._teamBuffList then
                            i = i + 1
                        else
                            i = 1
                        end
                    end
                )
            end
        end,
        self
    )
end

function UIBattleTeamStateEnter:_AutoFight(enable)
    self._autoFightState = enable
end

function UIBattleTeamStateEnter:FlushSldImg(idx)
    if not self._teamBuffList then
        return
    end
    if #self._teamBuffList <= 0 then
        return
    end

    local buffViewInstance = self._teamBuffList[idx]
    if not buffViewInstance then
        return
    end
    local curEffectType = buffViewInstance:GetBuffEffectType()
    local stBuffState = StringTable.Get("str_battle_state_desc") .. StringTable.Get(buffViewInstance:GetBuffName())

    self.curEffectType = curEffectType
    if curEffectType == BuffEffectType.Burn then
        self._imgSldBG.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[1])
        self._imgSldFill.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[2])
        self._imgSldFollow.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[3])
    elseif curEffectType == BuffEffectType.Stun then
        self._imgSldBG.sprite = self._atlas:GetSprite(self._sldSpriteNames.Stun[1])
        self._imgSldFill.sprite = self._atlas:GetSprite(self._sldSpriteNames.Stun[2])
        self._imgSldFollow.sprite = self._atlas:GetSprite(self._sldSpriteNames.Stun[3])
    elseif curEffectType == BuffEffectType.Poison then
        self._imgSldBG.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[1])
        self._imgSldFill.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[2])
        self._imgSldFollow.sprite = self._atlas:GetSprite(self._sldSpriteNames.Fire[3])
    elseif curEffectType == BuffEffectType.Benumb then
        self._imgSldBG.sprite = self._atlas:GetSprite(self._sldSpriteNames.Benumb[1])
        self._imgSldFill.sprite = self._atlas:GetSprite(self._sldSpriteNames.Benumb[2])
        self._imgSldFollow.sprite = self._atlas:GetSprite(self._sldSpriteNames.Benumb[3])
    end
    self._teamStateTxt:SetText(stBuffState)
    self:SetEffectActive()
    self:CorrectEffValue()
end

function UIBattleTeamStateEnter:CorrectFollowPos(hp, maxHp)
    if hp <= 0 or hp >= maxHp then
        self._imgSldFollow.gameObject:SetActive(false)
    else
        self._imgSldFollow.gameObject:SetActive(true)
    end
end

function UIBattleTeamStateEnter:SetEffectActive()
    self._burnEff1:SetActive(self.curEffectType == BuffEffectType.Burn or self.curEffectType == BuffEffectType.Poison)
    self._burnEff2:SetActive(self.curEffectType == BuffEffectType.Burn or self.curEffectType == BuffEffectType.Poison)
    self._burnMesh:SetActive(self.curEffectType == BuffEffectType.Burn or self.curEffectType == BuffEffectType.Poison)

    self._stunEff:SetActive(self.curEffectType == BuffEffectType.Stun)
    self._stunMesh:SetActive(self.curEffectType == BuffEffectType.Stun)

    self._benumbEff:SetActive(self.curEffectType == BuffEffectType.Benumb)
    self._benumbMesh:SetActive(self.curEffectType == BuffEffectType.Benumb)
end

function UIBattleTeamStateEnter:CorrectEffValue()
    local hpPercent = self.hpPercent or 0
    local value = hpPercent / 100
    if self.curEffectType == BuffEffectType.Burn then
        self._burnMesh.transform.localScale = Vector3(1, value, 0)
    elseif self.curEffectType == BuffEffectType.Stun then
        self._stunMesh.transform.localScale = Vector3(1, value, 0)
    elseif self.curEffectType == BuffEffectType.Poison then
        self._burnMesh.transform.localScale = Vector3(1, value, 0)
    elseif self.curEffectType == BuffEffectType.Benumb then
        self._benumbMesh.transform.localScale = Vector3(1, value, 0)
    end
end

function UIBattleTeamStateEnter:ChangeTeamLeaderOnClick()
    if self._autoFightState then
        return
    end
    if self._changeTeamLeaderCount <= 0 and self._changeTeamLeaderCount ~= -1 then
        local text = StringTable.Get("str_battle_left_change_teamleader_count_invlaid")
        ToastManager.ShowToast(text)
        return
    end

    local l_MatchEnterData = self:GetModule(MatchModule)
    local nLeaderModuleId = GameModuleID.MD_ChangeLeader
    -- 如果是资源本需要特叔处理
    if l_MatchEnterData:GetMatchType() == MatchType.MT_ResDungeon then
        nLeaderModuleId = GameModuleID.MD_ResChangeLeader
    end

    local l_RoleModule = self:GetModule(RoleModule)
    if l_RoleModule:CheckModuleUnlock(nLeaderModuleId) == false then
        local functionLockCfg = Cfg.cfg_module_unlock[nLeaderModuleId]
        ToastManager.ShowToast(StringTable.Get(functionLockCfg.Tips))
        return
    end

    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    local enableInput = GameGlobal:GetInstance():IsInputEnable()
    if coreGameStateID == GameStateID.WaitInput and enableInput == true then
        self:ShowChangeTeamLeaderData()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ToggleTeamLeaderChangeUI, true)
    end
end

function UIBattleTeamStateEnter:_ChangeTeamLeaderLeftCount(count)
    self._changeTeamLeaderCount = count
    local strLeft = tostring(self._changeTeamLeaderCount)
    if count == -1 then
        strLeft = "∞"
    end
    self._changeTeamLeaderCountTxt:SetText(strLeft)
end

function UIBattleTeamStateEnter:_GetDisplayHPPercent(curHP, maxHP)
    local displayPct = curHP / maxHP * 100
    displayPct = displayPct - (displayPct % 1) -- 40.25 - (40.25 % 1) => 40.25 - 0.25 => 40.0
    if displayPct < 1 then
        displayPct = 1
    end

    return displayPct
end
