_class("UIBossHPInfo", UICustomWidget)
---@class UIBossHPInfo : UICustomWidget
UIBossHPInfo = UIBossHPInfo

function UIBossHPInfo:Constructor()
    self._pstId = 0
    self._tplId = 0
end

function UIBossHPInfo:OnShow()
    self._go = self:GetGameObject()
    self._txtBoss = self:GetUIComponent("UILocalizationText", "txtBoss")
    self._txtBossName = self:GetUIComponent("UILocalizationText", "txtBossName")
    self._rtRect = self:GetUIComponent("RectTransform", "txtBossName")
    self._revolvingText = self:GetUIComponent("RevolvingTextWithDynamicScroll", "RevolvingText")
    self._revolvingTextGo = self:GetGameObject("RevolvingText")
    self._sldWhiteHp = self:GetUIComponent("Slider", "sldWhiteHp")
    ---@type UnityEngine.UI.Slider
    self._sldRedHp = self:GetUIComponent("Slider", "sldRedHp")
    ---@type UnityEngine.RectTransform
    self._sldRedHpRectTransform = self:GetUIComponent("RectTransform", "sldRedHp")
    ---@type UnityEngine.UI.Image
    self._imgFillRed = self:GetUIComponent("Image", "imgFillRed")
    self._txtHpPercent = self:GetUIComponent("UILocalizationText", "txtHpPercent")
    ---@type UnityEngine.UI.Image
    self._imgElement = self:GetUIComponent("Image", "imgElement")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "head")
    self._rawImage = self:GetUIComponent("RawImage", "head")

    ---@type UnityEngine.UI.Image
    self._monsterType = self:GetUIComponent("Image", "monsterType")

    self._bossLayoutGroup = self:GetGameObject("BossLayoutGroup")
    ---@type UnityEngine.RectTransform
    self._bossLayoutGroupRectTransform = self:GetUIComponent("RectTransform", "BossLayoutGroup")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattleAtlas = self:GetAsset("InnerUI.spriteatlas", LoadType.SpriteAtlas)
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlasProperty = self:GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    ---@type DG.Tweening.Tweener
    self._tnrWhiteHP = nil
    self:AttachEvent(GameEventType.UpdateBossRedHp, self.UpdateBossRedHp)
    self:AttachEvent(GameEventType.UpdateBossWhiteHp, self.UpdateBossWhiteHp)
    self:AttachEvent(GameEventType.UpdateBossShield, self.UpdateBossShield)
    self:AttachEvent(GameEventType.ChangeBossHPLock, self.ChangeBossHpLock)
    self:AttachEvent(GameEventType.ChangeBossHPBuffButtonRayCast, self.ChangeBossHPBuffButtonRayCast)
    self:AttachEvent(GameEventType.UpdateBossNameAndElement, self.UpdateBossNameAndElement)
    self:AttachEvent(GameEventType.UpdateWorldBossHP, self.UpdateWorldBossHP)
    self:AttachEvent(GameEventType.TeamHPChange, self.UpdateTeamHPChange)
    self:AttachEvent(GameEventType.UpdateBossElement, self.UpdateBossElement)
    self:AttachEvent(GameEventType.UpdateAntiActiveSkill, self.UpdateAntiActiveSkill)
    --buff
    self.buttonOpenBuff = self:GetUIComponent("Button", "buttonOpenBuff")
    ---@type UnityEngine.UI.Graphic
    self._buttonImage = self:GetUIComponent("Graphic", "buttonOpenBuff")
    self.buffWindowRoot = self:GetGameObject("buffWindowRoot")
    self.buffWindowRootPath = self:GetUIComponent("UISelectObjectPath", "buffWindowRoot")
    ---@type UIBossBuffInfo
    self.buffWindowRootPath:SpawnObjects("UIBossBuffInfo", 1)

    ---
    ---@type UISelectObjectPath
    local buffRootPath = self:GetUIComponent("UISelectObjectPath", "buffRoot")
    if buffRootPath then
        ---@type UIHPBuffInfo
        self._uiBossHPBuffInfo = buffRootPath:SpawnObject("UIHPBuffInfo")
    end

    local energyLayerRoot = self:GetUIComponent("UISelectObjectPath", "energyLayerRoot")
    if energyLayerRoot then
        ---@type UIBossHPEnergyInfo
        self._uiBossHPEnergyInfo = energyLayerRoot:SpawnObject("UIBossHPEnergyInfo")
    end

    --精英词缀
    ---@type UISelectObjectPath
    local eliteRootPath = self:GetUIComponent("UISelectObjectPath", "eliteRoot")
    if eliteRootPath then
        ---@type UIBossHPEliteInfo
        self._uIBossHPEliteInfo = eliteRootPath:SpawnObject("UIBossHPEliteInfo")
    end

    --HarmReduction
    self._harmReductionRoot = self:GetGameObject("harmReductionRoot")
    self._harmReductionRootPath = self:GetUIComponent("UISelectObjectPath", "harmReductionRoot")
    self._harmReductionRootPath:SpawnObject("UIBossHarmReductionInfo")

    ---@type UnityEngine.UI.Image
    self._shieldImg = self:GetUIComponent("Image", "shield")

    ---@type UnityEngine.GameObject
    self.worldBossGO = self:GetGameObject("WorldBoss")
    if self.worldBossGO then
        self.worldBossGO:SetActive(false)
        ---@type UnityEngine.GameObject
        self.sldYellowHpGO = self:GetGameObject("sldYellowHp")
        self.sldYellowHpGO:SetActive(false)
        ---@type UnityEngine.UI.Image
        self._imageWhiteBackground = self:GetUIComponent("Image", "WhiteBackground")
        ---@type UnityEngine.UI.Image
        self._imageRedBackground = self:GetUIComponent("Image", "RedBackground")
        ---@type UILocalizationText
        self._txtTotalDamageNum = self:GetUIComponent("UILocalizationText", "totalDamageNumText")
        self._totalDamageNum = 0
        self._txtTotalDamageNum:SetText("0")
        ---@type UILocalizationText
        self._txtTotalDamageNumGray = self:GetUIComponent("UILocalizationText", "totalDamageNumTextGray")
        self._txtTotalDamageNumGray:SetText(UIActivityHelper.AddZeroFrontNum(8, self._totalDamageNum))

        ---@type UILocalizationText
        self._txtCurStageNum = self:GetUIComponent("UILocalizationText", "curStageNumText")
        self._txtCurStageNum:SetText("x1")
        ---@type UnityEngine.UI.Image
        self._imgFillWhite = self:GetUIComponent("Image", "imgFillWhite")
        ---@type UnityEngine.UI.Image
        self._imgFillYellow = self:GetUIComponent("Image", "imgFillYellow")
        ---@type UnityEngine.UI.Slider
        self._sldYellowHp = self:GetUIComponent("Slider", "sldYellowHp")
        ---@type UnityEngine.GameObject
        self.sldWhiteHpGO = self:GetGameObject("sldWhiteHp")

        ---@type UnityEngine.U2D.SpriteAtlas
        self._uiAtlas = self:GetAsset("UIBattle.spriteatlas", LoadType.SpriteAtlas)
    end

    self._sldGreyHp = self:GetUIComponent("Slider", "sldGreyHp")
    self:AttachEvent(GameEventType.UpdateBossGreyHP, self.UpdateBossGreyHP)
    self._sldCurseHpBgRect = self:GetUIComponent("RectTransform", "sldCurseHpBg")
    self._sldCurseHpBgGo = self:GetGameObject("sldCurseHpBg")
    self._curseHpGo = self:GetGameObject("curseHp")
    self._curseHpRect = self:GetUIComponent("RectTransform","curseHp")
    self:AttachEvent(GameEventType.UpdateBossCurseHP, self.UpdateBossCurseHP)
    ---@type UnityEngine.GameObject
    self._passiveSkillInfoIconGO = self:GetGameObject("infoIcon")
    self._passiveSkillInfoIconGO:SetActive(false)
    self._hasPassiveSkillInfo = false
    self.passiveSkillInfoWinRoot = self:GetGameObject("passiveSkillInfoWinRoot")
    self.passiveSkillInfoWinRootPath = self:GetUIComponent("UISelectObjectPath", "passiveSkillInfoWinRoot")
    ---@type UIMonsterPassiveInfo
    self.passiveSkillInfoWinRootPath:SpawnObjects("UIMonsterPassiveInfo", 1)

    ---@type UnityEngine.GameObject
    self._antiActiveSkillRoot = self:GetGameObject("AntiActiveSkillRoot")
    if self._antiActiveSkillRoot then
        self._antiActiveSkillRoot:SetActive(false)
        ---@type UILocalizationText
        self._txtAntiActiveSkillCount = self:GetUIComponent("UILocalizationText", "antiActiveSkillCount")
    end
end

function UIBossHPInfo:OnHide()
    self:DetachEvent(GameEventType.UpdateBossRedHp, self.UpdateBossRedHp)
    self:DetachEvent(GameEventType.UpdateBossWhiteHp, self.UpdateBossWhiteHp)
    self:DetachEvent(GameEventType.ChangeBossHPLock, self.ChangeBossHpLock)
    self:DetachEvent(GameEventType.UpdateBossNameAndElement, self.UpdateBossNameAndElement)
    self:DetachEvent(GameEventType.ChangeBossHPBuffButtonRayCast, self.ChangeBossHPBuffButtonRayCast)
    self:DetachEvent(GameEventType.UpdateWorldBossHP, self.UpdateWorldBossHP)
    self:DetachEvent(GameEventType.UpdateBossElement, self.UpdateBossElement)
    self:DetachEvent(GameEventType.UpdateBossGreyHP, self.UpdateBossGreyHP)
    self:DetachEvent(GameEventType.UpdateBossCurseHP, self.UpdateBossCurseHP)
    self:DetachEvent(GameEventType.UpdateAntiActiveSkill, self.UpdateAntiActiveSkill)
end

function UIBossHPInfo:SetActive(state)
    self._go:SetActive(state)
end

---@param t UIBossHPInfoData 表{pstId = number, tplId = number, isVice = bool}\
---@param arr table 记录4个血条的UIBossHPInfo[]
function UIBossHPInfo:Flush(t, isWorldBoss)
    self._pstId = t.pstId
    self._go:SetActive(true)
    if t.isVice then
        self._imgFillRed.color = Color.gray
    else
        self._imgFillRed.color = Color.white
    end
    self:UpdateBossNameAndElement(t.tplId, t.HPBarType, self._pstId, t.matchPet, t.curElement, t.hpEnergyVal, t.maxHPEnergyVal)
    local percent = t.percent or 1

    --Init
    self:UpdateBossRedHp(self._pstId, percent)
    self:UpdateBossWhiteHp(self._pstId, percent, true)
    self:UpdateBossHpPercent(self._pstId, percent, t.hP, t.maxHP, t.attack)
    self:UpdateBossShield(self._pstId, t.shieldValue, t.hP, t.maxHP)
    self:UpdateBossGreyHP(self._pstId, t.greyVal, t.hP, t.maxHP)
    self:UpdateBossCurseHP(self._pstId, t.showCurseHp,t.curseHpVal, t.hP, t.maxHP)

    self._hpLockSepList = t.sepHPList
    self._hpLockUnlockedList = t.sepHpUnlockedList
    if self._hpLockSepList then
        ---@type UnityEngine.GameObject
        local Redgo = self:GetGameObject("Fill Area")
        local hpMaxWidth = Redgo.transform.rect.width
        ---@type UICustomWidgetPool
        self._lockList = self:GetUIComponent("UISelectObjectPath", "lockList")
        self._lockList:SpawnObjects("UICustomWidget", #self._hpLockSepList)
        local lockGOList = self._lockList:GetAllSpawnList()
        for i = 1, #self._hpLockSepList do
            local sepPer = self._hpLockSepList[i]
            local offsetX = 0
            if sepPer >= 50 then
                offsetX = (sepPer - 50) * hpMaxWidth / 100
            else
                offsetX = (50 - sepPer) * hpMaxWidth / 100 * -1
            end
            ---@type UnityEngine.GameObject
            local go = lockGOList[i]:GetGameObject()
            go.transform.localPosition = Vector3(offsetX, 0, 0)
            ---@type UIView
            local uiview = go:GetComponent("UIView")
            ---@type UnityEngine.GameObject
            local lockGO = uiview:GetGameObject("Lock")
            local bLock = true
            if self._hpLockUnlockedList and table.icontains(self._hpLockUnlockedList,i) then
                bLock = false
            end
            lockGO:SetActive(bLock)
            ---@type UnityEngine.GameObject
            local unlockGO = uiview:GetGameObject("UnLock")
            unlockGO:SetActive(not bLock)
        end
    end

    if self._uiBossHPBuffInfo and t.pstId then
        self._uiBossHPBuffInfo:SetBossData(t.pstId)
    end
    if isWorldBoss then
        self:InitWorldBossHP(t)
    end
    self:FlushPassiveSkillInfo(t.tplId)
end

function UIBossHPInfo:FlushPassiveSkillInfo(tplID)
    ---@type MonsterConfigData
    local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
    local have = monsterConfigData:IsHasPassiveSkillInfo(tplID)
    self._passiveSkillInfoIconGO:SetActive(have)
    self._hasPassiveSkillInfo = have
    ---@type UIMonsterPassiveInfo[]
    local lst = self.passiveSkillInfoWinRootPath:GetAllSpawnList()
    if lst and table.count(lst) > 0 then
        lst[1]:SetCanvasShow(false)
    end
end

function UIBossHPInfo:ChangeBossHpLock(index, state)
    if self._lockList then
        local lockGOList = self._lockList:GetAllSpawnList()
        if lockGOList == nil or lockGOList[index] == nil then
            return
        end
        local go = lockGOList[index]:GetGameObject()
        ---@type UIView
        local uiview = go:GetComponent("UIView")
        ---@type UnityEngine.GameObject
        local lockGO = uiview:GetGameObject("Lock")
        lockGO:SetActive(state)
        ---@type UnityEngine.GameObject
        local unlockGO = uiview:GetGameObject("UnLock")
        unlockGO:SetActive(not state)
    end
end

function UIBossHPInfo:UpdateBossRedHp(entityID, redHpPercent)
    if entityID ~= self._pstId then
        return
    end
    self._sldRedHp.value = redHpPercent
end

function UIBossHPInfo:UpdateBossShield(entityID, shieldValue, redhp, maxhp)
    if not self._shieldImg then
        return
    end
    if entityID ~= self._pstId then
        return
    end
    if shieldValue == nil or shieldValue <= 0 then
        self._shieldImg.gameObject:SetActive(false)
        return
    end

    self._shieldImg.gameObject:SetActive(true)

    ---@type UnityEngine.RectTransform
    local shieldRectTransform = self._shieldImg.rectTransform

    local greenRectTransform = self._sldRedHpRectTransform
    local hpMaxWidth = self._sldRedHpRectTransform.rect.width
    local hpMaxHeight = shieldRectTransform.rect.height
    local shieldPercent = shieldValue / maxhp
    if shieldPercent > 1 then
        shieldPercent = 1
    end

    ---护盾条的长度
    local shieldWidth = shieldPercent * hpMaxWidth
    shieldRectTransform.sizeDelta = Vector2(shieldWidth, hpMaxHeight)

    local hpPercent = redhp / maxhp
    local hpWidth = hpPercent * hpMaxWidth

    local hpAndShield = redhp + shieldValue
    if hpAndShield < maxhp then
        ---护盾条的位置，应该在血条的结束位置
        local posX = -hpMaxWidth / 2 + hpWidth
        shieldRectTransform.localPosition = Vector3(posX, 0, 0)
    else
        local posX = -hpMaxWidth / 2 + (hpMaxWidth - shieldWidth)
        shieldRectTransform.localPosition = Vector3(posX, 0, 0)
    end
end

function UIBossHPInfo:UpdateBossElement(element, entityID)
    if entityID ~= self._pstId then
        return
    end
    local spriteStr = Cfg.cfg_pet_element[element].Icon
    if spriteStr then
        self._imgElement.sprite =
            self.atlasProperty:GetSprite(UIPropertyHelper:GetInstance():GetColorBlindSprite(spriteStr .. "_battle"))
        self._imgElement.gameObject:SetActive(true)
    else --存在无属性的BOSS（装备副本）
        self._imgElement.gameObject:SetActive(false)
    end
end

---@param hpBarType HPBarType
function UIBossHPInfo:UpdateBossNameAndElement(tplId, hpBarType, entityID, matchPet,curElement, hpEnergyVal, maxEnergyVal)
    if entityID ~= self._pstId then
        return
    end
    local name, elementType, icon = self:GetNameAndElement(tplId, hpBarType, matchPet)
    if curElement then--可能释放了属性转换技能
        elementType = curElement
    end
    local bossElement = 0
    self._hpBarType = hpBarType
    if
        hpBarType == HPBarType.EliteBoss or hpBarType == HPBarType.Boss or hpBarType == HPBarType.NormalMonster or
            hpBarType == HPBarType.EliteMonster or
            HPBarType.BlackFist
     then
        self._tplId = tplId

        if self._txtBossName then
            self._txtBossName.text = StringTable.Get(name)

            local width = self._txtBossName.preferredWidth
            local rootWdth = 254
            --重新刷新文字width，解决多文字怪物变成少文字怪物时候显示长度还是多文字的长度
            self._rtRect.sizeDelta = Vector2(width, 50)

            if width <= 124 then
                rootWdth = 254
            elseif width >= 244 then
                rootWdth = 376
            else
                rootWdth = width + 130
            end

            --刷新
            self._bossLayoutGroupRectTransform.sizeDelta = Vector2(rootWdth, 99)

            if self._revolvingText then
                self._revolvingText:OnRefreshRevolving()
            end
        end
        bossElement = elementType
        --新头像
        self._imgIcon:LoadImage(icon)

        if hpBarType == HPBarType.EliteBoss or hpBarType == HPBarType.Boss then
            self._monsterType.color = Color(255 / 255, 12 / 255, 2 / 255, 1)
            self._txtBoss.color = Color(255 / 255, 12 / 255, 2 / 255, 1)
            self._txtBoss:SetText(StringTable.Get("str_battle_boss"))
        elseif hpBarType == HPBarType.EliteMonster then
            self._monsterType.color = Color(174 / 255, 79 / 255, 255 / 255, 1)
            self._txtBoss.color = Color(174 / 255, 79 / 255, 255 / 255, 1)
            self._txtBoss:SetText(StringTable.Get("str_battle_elite"))
        elseif hpBarType == HPBarType.NormalMonster then
            self._monsterType.color = Color(154 / 255, 154 / 255, 154 / 255, 1)
            self._txtBoss.color = Color(154 / 255, 154 / 255, 154 / 255, 1)
            self._txtBoss:SetText(StringTable.Get("str_battle_monster"))
        elseif hpBarType == HPBarType.BlackFist then
            self._monsterType.color = Color(174 / 255, 79 / 255, 255 / 255, 1)
            self._txtBoss.color = Color(174 / 255, 79 / 255, 255 / 255, 1)
            self._txtBoss:SetText(StringTable.Get("str_battle_pet"))
        end
    end
    self:UpdateBossElement(bossElement, entityID)
    --刷新buff
    if self._uiBossHPBuffInfo and self._pstId then
        self._uiBossHPBuffInfo:SetBossData(self._pstId)
    end

    --默认关闭
    self._uIBossHPEliteInfo:OnHide()

    local eliteInfoWidth = BattleConst.UIBossHPEliteInfoDefaultWidth
    if hpEnergyVal and maxEnergyVal then
        eliteInfoWidth = eliteInfoWidth - maxEnergyVal * BattleConst.UIBossHPEnergyItemWidth
        self._uiBossHPEnergyInfo:SetData(entityID, hpEnergyVal, maxEnergyVal)
    end
    --刷新精英词缀
    if self._uIBossHPEliteInfo and (hpBarType == HPBarType.EliteBoss or hpBarType == HPBarType.EliteMonster) then
        self._uIBossHPEliteInfo:SetWidth(eliteInfoWidth, false)
        -- ---@type MonsterConfigData
        -- local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
        -- local eliteIDArray = monsterConfigData:GetEliteIDArray(tplId) or {}
        local eliteIDArray = BattleStatHelper.GetEliteIDArray(entityID, tplId)
        self._uIBossHPEliteInfo:OnSetData(eliteIDArray)
    end

    --刷新减伤信标
    ---@type BuffViewInstance
    local harmReductionInstance = InnerGameHelperRender.GetSingleBuffByBuffEffect(self._pstId, BuffEffectType.HarmReduction)
    ---@type BuffViewInstance
    local coffinMusumeInstance = InnerGameHelperRender.GetSingleBuffByBuffEffect(self._pstId, BuffEffectType.CoffinMusume)
    ---@type BuffViewInstance
    local coffinMusumeAtkDefInstance = InnerGameHelperRender.GetSingleBuffByBuffEffect(self._pstId, BuffEffectType.CoffinMusumeAtkDef)
    self._harmReductionRoot.gameObject:SetActive((harmReductionInstance ~= nil) or (coffinMusumeInstance ~= nil) or (coffinMusumeAtkDefInstance ~= nil))

    if self._bossLayoutGroup then
        UIHelper.RefreshLayout(self._bossLayoutGroup:GetComponent("RectTransform"))
    end
    self:FlushPassiveSkillInfo(tplId)
end

function UIBossHPInfo:UpdateBossWhiteHp(entityID, whiteHpPercent, isInit)
    if entityID ~= self._pstId then
        return
    end

    if self._tnrWhiteHP then
        self._tnrWhiteHP:Complete()
    end

    if whiteHpPercent > 0 and whiteHpPercent < 0.01 then
        whiteHpPercent = 0.01
    end

    if isInit then
        self._sldWhiteHp.value = whiteHpPercent
    else
        self._tnrWhiteHP = self._sldWhiteHp:DOValue(whiteHpPercent, 0.3)
    end

    --舒摩尔同步血量不超过血量最高者，这里向下取整
    self.whiteHpPercent = math.floor(whiteHpPercent * 100)
    self:UpdateBossHpPercent(entityID)
    --if BattleStatHelper.GetHandleShumolHPUI() > 0 then
    --    local maxPercent = 0
    --    for i, v in ipairs(self._bossHpArr) do
    --        if v ~= self then
    --            local p = v:GetWhiteHpPercent()
    --            if p > maxPercent then
    --                maxPercent = p
    --            end
    --        end
    --    end
    --    if self.whiteHpPercent > maxPercent then
    --        self.whiteHpPercent = maxPercent
    --    end
    --end
    self:GreyName(whiteHpPercent)
end

function UIBossHPInfo:UpdateBossHpPercent(entityID)
    if entityID ~= self._pstId then
        return
    end

    local match = GameGlobal.GetModule(MatchModule)
    local enterData = match:GetMatchEnterData()

    -- TODO: 战棋UI制作最后要清理一下之前临时加进去的东西
    local chessGroup = self:GetGameObject("chessHPGroup")
    if chessGroup then
        chessGroup:SetActive(false)
    end
    self._txtHpPercent:SetText(table.concat({self.whiteHpPercent, "%"}))
end

function UIBossHPInfo:GetWhiteHpPercent()
    return self.whiteHpPercent
end

function UIBossHPInfo:GreyName(hpPercent)
    if self._rawImage then
        if hpPercent <= 0 then
            self._rawImage.material:SetFloat("_LuminosityAmount", 1)
        else
            self._rawImage.material:SetFloat("_LuminosityAmount", 0)
        end
    end

    -- if self._txtBoss and self._txtBossName then
    --     local curColor = Color.white
    --     if hpPercent <= 0 then
    --         local gray = 146 / 255
    --         curColor = Color(gray, gray, gray)
    --     else
    --         curColor = Color.white
    --     end
    --     self._txtBoss.color = curColor
    --     self._txtBossName.color = curColor
    --     if self._revolvingTextGo then
    --         local txts = self._revolvingTextGo.gameObject:GetComponentsInChildren(typeof(UILocalizationText), true)
    --         for i = 0, txts.Length - 1 do
    --             txts[i].color = curColor
    --         end
    --     end
    -- end
end

--buff
function UIBossHPInfo:buttonOpenBuffOnClick()
    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIBossHPInfo", input = "buttonOpenBuffOnClick", args = {}}
    )
    ---@type UIBossBuffInfo[]
    local lst = self.buffWindowRootPath:GetAllSpawnList()
    if lst and table.count(lst) > 0 then
        lst[1]:Init(self._pstId, self._tplId, self._hpBarType)
    end
end

function UIBossHPInfo:ChangeBossHPBuffButtonRayCast(state)
    self._buttonImage.raycastTarget = state
end

function UIBossHPInfo:GetImageSp(imageName)
    return self._uiAtlas:GetSprite(imageName)
    --return InnerGameHelperRender:GetInstance():GetImageFromInnerUI(imageName)
end

function UIBossHPInfo:SetRedHPImage(imageName)
    self._imgFillRed.sprite = self:GetImageSp(imageName)
end

function UIBossHPInfo:SetYellowHPImage(imageName)
    self._imgFillYellow.sprite = self:GetImageSp(imageName)
end

function UIBossHPInfo:GetImageName(imageID)
    local cfg = Cfg.cfg_world_boss_hp_image[imageID]
    if not cfg then
        Log.fatal("ImageID :", imageID, "invalid not in cfg_world_boss_hp_image")
    end
    return cfg.ImageName
end

function UIBossHPInfo:InitWorldBossHP(t)
    self._isCurWorldBossStyle = true
    local redHPImageID = t.worldBossCurImageID
    local yellowHPImageID = t.worldBossPreImageID
    local redImageName = self:GetImageName(redHPImageID)
    local yellowImageID = self:GetImageName(yellowHPImageID)
    self:SetRedHPImage(redImageName)
    self:SetYellowHPImage(yellowImageID)
    self.sldYellowHpGO:SetActive(true)
    self.worldBossGO:SetActive(true)
    self._sldYellowHp.value = 1
    self._sldRedHp.value = 0
    self._txtHpPercent.text = "0%"
    self._sldWhiteHp.value = 0
    self.sldWhiteHpGO:SetActive(false)
end
---替换血条图案
function UIBossHPInfo:SwitchWorldBossHPStage(newRedImageID, newYellowImageID)
    local redImageName = self:GetImageName(newRedImageID)
    local yellowImageID = self:GetImageName(newYellowImageID)
    Log.fatal("RedImage:", redImageName, " YellowImage:", yellowImageID)
    self:SetRedHPImage(redImageName)
    self:SetYellowHPImage(yellowImageID)
    self._sldWhiteHp.value = 0
    self._sldRedHp.value = 0
    self._txtHpPercent.text = "0%"
end

---changeInfoList = { redHP=0, whiteHP=0, changeStage=true, nextStage=2}
function UIBossHPInfo:UpdateWorldBossHP(pstID, changeInfoList, damage, stage)
    if pstID ~= self._pstId then
        return
    end
    ---这是掉血的逻辑
    --if self._tnrWhiteHP then
    --    self._tnrWhiteHP:Complete()
    --end
    --self._totalDamageNum = self._totalDamageNum + damage
    --self._txtTotalDamageNum:SetText(tostring(self._totalDamageNum))
    --self._txtCurStageNum:SetText(tostring(stage))
    --for index, info in ipairs(changeInfoList) do
    --    if self._tnrWhiteHP then
    --        self._tnrWhiteHP:Complete()
    --    end
    --    self._sldRedHp.value = info.redHP
    --    self._tnrWhiteHP = self._sldWhiteHp:DOValue(info.whiteHP, 0.3)
    --    if info.changeStage then
    --        if self._tnrWhiteHP then
    --            self._tnrWhiteHP:Complete()
    --        end
    --        self:SwitchWorldBossHPStage(info.redImageID, info.yellowImageID)
    --    end
    --end
    self._totalDamageNum = self._totalDamageNum + damage
    self._txtTotalDamageNum:SetText(tostring(self._totalDamageNum))
    self._txtTotalDamageNumGray:SetText(UIActivityHelper.AddZeroFrontNum(8, self._totalDamageNum))
    self._txtCurStageNum:SetText("x" .. tostring(stage))
    for index, info in ipairs(changeInfoList) do
        if info.redHP > 0 and info.redHP < 0.01 then
            info.redHP = 0.01
        end
        self._sldRedHp.value = info.redHP
        local percent = math.floor(info.redHP * 100)
        self._txtHpPercent.text = percent .. "%"
        if info.changeStage then
            self:SwitchWorldBossHPStage(info.redImageID, info.yellowImageID)
        end
    end
end

---
function UIBossHPInfo:UpdateBossGreyHP(entityID, value, redhp, maxHP)
    if entityID ~= self._pstId then
        return
    end

    value = value or 0
    redhp = redhp or 0
    maxHP = maxHP or 1

    self._sldGreyHp.value = ((value + redhp) / maxHP) or 0
end
function UIBossHPInfo:UpdateBossCurseHP(entityID,bShow, value, redhp, maxHP)
    if entityID ~= self._pstId then
        return
    end
    if not self._sldCurseHpBgGo then
        return
    end
    if not value then
        bShow = false
        value = 0
    end
    value = value or 0
    redhp = redhp or 0
    maxHP = maxHP or 1

    self._sldCurseHpBgGo:SetActive(bShow)
    self._curseHpGo:SetActive(bShow)
    local percent = value / maxHP
    if percent > 1 then
        percent = 1
    end
    
    local hpMaxWidth = self._sldRedHpRectTransform.rect.width
    local hpMaxHeight = self._sldRedHpRectTransform.rect.height
    ---长度
    local curseHpWidth = percent * hpMaxWidth
    self._curseHpRect.sizeDelta = Vector2(curseHpWidth, hpMaxHeight)
    local curseHpBgLeftOff = 31--图片左边有部分空白
    local curseHpBgWidth = curseHpWidth + curseHpBgLeftOff
    local curseHpBgMaxHeight = self._sldCurseHpBgRect.rect.height
    self._sldCurseHpBgRect.sizeDelta = Vector2(curseHpBgWidth, curseHpBgMaxHeight)
end
---@param matchPet MatchPet
function UIBossHPInfo:GetNameAndElement(tplId, type, matchPet)
    if
        type == HPBarType.EliteMonster or type == HPBarType.NormalMonster or type == HPBarType.Boss or
            type == HPBarType.EliteBoss
     then
        ---@type MonsterConfigData
        local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
        local cfgMonsterObject = monsterConfigData:GetMonsterObject(tplId)
        local cfgMonsterClass = monsterConfigData:GetMonsterClass(tplId)
        if cfgMonsterObject then
            local name = cfgMonsterClass.Name
            local element = cfgMonsterObject.ElementType
            local icon = cfgMonsterClass.HeadIcon
            return name, element, icon
        end
    elseif type == HPBarType.BlackFist then
        local petcfg = Cfg.cfg_pet[tplId]
        local element = matchPet:GetPetFirstElement()
        local headIconName = matchPet:GetPetHead(PetSkinEffectPath.HEAD_ICON_CHAIN_SKILL_PREVIEW)
        return petcfg.Name, element, headIconName
    end
end

function UIBossHPInfo:UpdateTeamHPChange(args)
    if args.isLocalTeam then
        return
    end
    local maxHP = args.maxHP
    local redHP = args.currentHP / maxHP
    if args.currentHP > 0 and redHP < 0.01 then
        redHP = 0.01
    end
    local whiteHP = args.hitpoint / maxHP
    local shieldValue = args.shield
    local entityID = args.entityID

    self:UpdateBossRedHp(entityID, redHP)
    self:UpdateBossWhiteHp(entityID, whiteHP)
    self:UpdateBossShield(entityID, shieldValue, args.currentHP, maxHP)
    self:UpdateBossCurseHP(entityID, args.showCurseHp,args.curseHpVal, args.currentHP, maxHP)
end

--PassiveSkillInfo
function UIBossHPInfo:buttonOpenPassiveSkillInfoOnClick()
    if not self._hasPassiveSkillInfo then
        return
    end
    GameGlobal.GameRecorder():RecordAction(
            GameRecordAction.UIInput,
            {ui = "UIBossHPInfo", input = "buttonOpenPassiveSkillInfoOnClick", args = {}}
    )
    ---@type UIMonsterPassiveInfo[]
    local lst = self.passiveSkillInfoWinRootPath:GetAllSpawnList()
    if lst and table.count(lst) > 0 then
        lst[1]:Init(self._pstId, self._tplId)
    end
end

function UIBossHPInfo:UpdateAntiActiveSkill(entityID, showCD)
    if entityID ~= self._pstId then
        return
    end

    local antiSkillEnabled = InnerGameHelperRender.GetEntityAttribute(entityID, "AntiSkillEnabled")
    local maxCount = InnerGameHelperRender.GetEntityAttribute(entityID, "MaxAntiSkillCountPerRound")
    local antiCD = InnerGameHelperRender.GetEntityAttribute(entityID, "WaitActiveSkillCount")
    -- (本回合剩余>0 and 激活状态) or 传了强制显示的数值
    local show = (maxCount ~= 0 and antiSkillEnabled == 1) or showCD ~= nil
    self._antiActiveSkillRoot.gameObject:SetActive(show)
    if not show then
        return
    end

    local originalCount = InnerGameHelperRender.GetEntityAttribute(entityID, "OriginalWaitActiveSkillCount")
    --初始是1的不显示（max也是1的）,从321这种递减的在1的时候显示
    self._txtAntiActiveSkillCount.gameObject:SetActive(originalCount ~= 1)
    --用于一个buff表现中刷新2次的显示，强制传1来让实际0的时候显示为1
    if showCD then
        antiCD = showCD
    end
    self._txtAntiActiveSkillCount:SetText(antiCD)
end
function UIBossHPInfo:PreviewSetWorldBossHP(info)
    if info.pstId ~= self._pstId then
        return
    end
    self._sldGreyHp.value = 0

    self:SwitchWorldBossHPStage(info.worldBossCurImageID, info.worldBossPreImageID)
    self._totalDamageNum = info.worldBossTotalDamage
    self._txtTotalDamageNum:SetText(tostring(self._totalDamageNum))
    self._txtTotalDamageNumGray:SetText(UIActivityHelper.AddZeroFrontNum(8, self._totalDamageNum))
    self._txtCurStageNum:SetText("x" .. tostring(info.worldBossCurStage))
    if info.worldBossCurStageHpPercent > 0 and info.worldBossCurStageHpPercent < 0.01 then
        info.worldBossCurStageHpPercent = 0.01
    end
    self._sldRedHp.value = info.worldBossCurStageHpPercent
    local percent = math.floor(info.worldBossCurStageHpPercent * 100)
    self._txtHpPercent.text = percent .. "%"
end
function UIBossHPInfo:PreviewRevertWorldBossStyle()
    if not self._isCurWorldBossStyle then
        return
    end
    local redImageName = "thread_bosstiao2_frame"
    local yellowImageID = "thread_bosstiao3_frame"
    self:SetRedHPImage(redImageName)
    self:SetYellowHPImage(yellowImageID)
    self.sldYellowHpGO:SetActive(false)
    self.worldBossGO:SetActive(false)
    self.sldWhiteHpGO:SetActive(true)
end