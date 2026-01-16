--[[-------------------------------------
    HPDisplaySystem_Render 血条血量刷新机制
--]] -------------------------------------
---@class HPDisplaySystem_Render:ReactiveSystem
_class("HPDisplaySystem_Render", ReactiveSystem)
HPDisplaySystem_Render = HPDisplaySystem_Render

function HPDisplaySystem_Render:Constructor(world)
    ---@type MainWorld
    self._world = world
    self._hpGroup = world:GetGroup(world.BW_WEMatchers.HP)
end

function HPDisplaySystem_Render:TearDown()
end

function HPDisplaySystem_Render:GetTrigger(world)
    return Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.HP)
        },
        {
            "Added"
        }
    )
end

function HPDisplaySystem_Render:Filter(entity)
    return entity:HasHP() and entity:HasView()
end

function HPDisplaySystem_Render:ExecuteEntities(entities)
    ---@type TimeService
    self._timeService = self._world:GetService("Time")

    for i, e in ipairs(entities) do
        self:_TryIntializeHPCacheComponent(e)
        self:_RefreshHpBar(e)
    end
end

---@param entity Entity
function HPDisplaySystem_Render:_RefreshHPSlider(entity, whitehp, redhp, maxhp, greyHP)
    if self._world:MatchType() == MatchType.MT_Chess and (entity:HasChessPet() or entity:HasMonsterID()) then
        self:_RefreshHpBar_Chess(entity, whitehp, redhp, maxhp)
        return
    end

    ---@type HPComponent
    local hpCmpt = entity:HP()

    local hasBoss = entity:HasBoss()
    ---@type BuffViewComponent
    local buffCmpt = entity:BuffView()
    --身上有buff标志 自己显示在BOSS血条（映镜的墙壁）
    local curShowBossHP = buffCmpt and buffCmpt:HasBuffEffect(BuffEffectType.CurShowBossHP)
    --填充比例
    local white = hpCmpt:GetWhiteImageComponent()
    local red = hpCmpt:GetRedImageComponent()

    if hasBoss then
        ---@type MonsterShowRenderService
        local sMonsterShowRender = self._world:GetService("MonsterShowRender")
        local isVice = sMonsterShowRender:IsViceBoss(entity)
        if isVice then
            red.color = Color.gray
        else
            red.color = Color.white
        end
    end

    local redHpPercent = redhp / maxhp
    local whiteHpPercent = whitehp / maxhp
    --当血量<1%时，显示1%
    if redhp > 0 and redHpPercent < 0.01 then
        redHpPercent = 0.01
    end
    if whitehp > 0 and whiteHpPercent < 0.01 then
        whiteHpPercent = 0.01
    end

    if redhp > 0 then
        local lastRedPercent = hpCmpt:GetLastRedPercent()
        local diff = math.abs(lastRedPercent - redHpPercent)
        if diff >= 0.01 then
            red.fillAmount = redHpPercent
            hpCmpt:SetLastRedPercent(redHpPercent)
        end

        local lastWhitePercent = hpCmpt:GetLastWhitePercent()
        local whiteDiff = math.abs(lastWhitePercent - whiteHpPercent)
        if whiteDiff >= 0.01 then
            --白血条减少动画
            white:DOFillAmount(whiteHpPercent, 0.3)
            hpCmpt:SetLastWhitePercent(whiteHpPercent)
        end
    else
        red.fillAmount = 0
        hpCmpt:SetLastRedPercent(0)
        white:DOFillAmount(0, 0.3)
        hpCmpt:SetLastWhitePercent(0)
    end

    local greyHPUI = hpCmpt:GetGreyImageComponent()
    if greyHPUI then
        greyHPUI.fillAmount = (greyHP + redhp) / maxhp
    end
    --Log.debug("[DisplayHP] MaxHP:",maxhp,"HP:",redhp,"Percent:",redHpPercent,"EntityID:",entity:GetID())
end

---
function HPDisplaySystem_Render:_RefreshHpBar_Chess(entity, whitehp, redhp, maxhp)
    ---@type HPComponent
    local hpCmpt = entity:HP()

    local hasBoss = entity:HasBoss()
    ---@type BuffViewComponent
    local buffCmpt = entity:BuffView()
    --身上有buff标志 自己显示在BOSS血条（映镜的墙壁）
    local curShowBossHP = buffCmpt and buffCmpt:HasBuffEffect(BuffEffectType.CurShowBossHP)

    local redHpPercent = redhp / maxhp
    local whiteHpPercent = whitehp / maxhp

    local white = hpCmpt:GetWhiteImageComponent()
    white.fillAmount = 0
    local red = hpCmpt:GetRedImageComponent()
    red.fillAmount = 0

    local csTextChessHP = hpCmpt:GetUICSTextChessHP()
    if csTextChessHP then
        csTextChessHP:SetText(redhp)
    end

    local csgoChessAttackTarget = hpCmpt:GetUICSGOChessAttackTarget()
    local csgoChessRecoverTarget = hpCmpt:GetUICSGOChessRecoverTarget()
    if csgoChessAttackTarget then
        local isTargeted = hpCmpt:GetChessTargetedMark()
        local isRecover = hpCmpt:GetChessRecoverMark()
        csgoChessAttackTarget:SetActive(isTargeted and not isRecover)
        csgoChessRecoverTarget:SetActive(isTargeted and isRecover)
    end

    if redhp <= 0 then
        hpCmpt:GetChessHPRed1().fillAmount = 0
        hpCmpt:GetChessHPWhite1().fillAmount = 0
        hpCmpt:GetChessHPRed2().fillAmount = 0
        hpCmpt:GetChessHPWhite2().fillAmount = 0
    else
        if maxhp <= BattleConst.HUDUI_ChessHPSecondBarThreshold then
            hpCmpt:GetChessHPRed2().fillAmount = 0
            hpCmpt:GetChessHPWhite2().fillAmount = 0

            local lastRedPercent = hpCmpt:GetLastRedPercent()
            local diff = math.abs(lastRedPercent - redHpPercent)
            if diff >= 0.01 then
                hpCmpt:SetLastRedPercent(redHpPercent)

                local red1Percent = redhp / maxhp
                hpCmpt:GetChessHPRed1().fillAmount = red1Percent
            end

            local lastWhitePercent = hpCmpt:GetLastWhitePercent()
            local whiteDiff = math.abs(lastWhitePercent - whiteHpPercent)
            if whiteDiff >= 0.01 then
                hpCmpt:SetLastWhitePercent(whiteHpPercent)
                --白血条减少动画
                local white1Percent = whitehp / maxhp
                hpCmpt:GetChessHPWhite1():DOFillAmount(white1Percent, 0.3)
            end
        else
            local lastRedPercent = hpCmpt:GetLastRedPercent()
            local diff = math.abs(lastRedPercent - redHpPercent)
            if diff >= 0.01 then
                hpCmpt:SetLastRedPercent(redHpPercent)
                local v1 = math.min(BattleConst.HUDUI_ChessHPSecondBarThreshold, redhp)
                local percent1 = math.max(0, v1 / BattleConst.HUDUI_ChessHPSecondBarThreshold)
                local v2 = redhp - BattleConst.HUDUI_ChessHPSecondBarThreshold
                local percent2 = math.max(0, v2 / BattleConst.HUDUI_ChessHPSecondBarThreshold)

                hpCmpt:GetChessHPRed1().fillAmount = percent1
                hpCmpt:GetChessHPRed2().fillAmount = percent2
            end

            local lastWhitePercent = hpCmpt:GetLastWhitePercent()
            local whiteDiff = math.abs(lastWhitePercent - whiteHpPercent)
            if whiteDiff >= 0.01 then
                hpCmpt:SetLastWhitePercent(whiteHpPercent)
                --白血条减少动画
                local v1 = math.min(BattleConst.HUDUI_ChessHPSecondBarThreshold, whitehp)
                local percent1 = math.max(0, v1 / BattleConst.HUDUI_ChessHPSecondBarThreshold)
                local v2 = whitehp - BattleConst.HUDUI_ChessHPSecondBarThreshold
                local percent2 = math.max(0, v2 / BattleConst.HUDUI_ChessHPSecondBarThreshold)

                hpCmpt:GetChessHPWhite1().fillAmount = percent1
                hpCmpt:GetChessHPWhite2().fillAmount = percent2
            end
        end
    end

    --当血量<1%时，显示1%
    if redhp > 0 and redHpPercent < 0.01 then
        redHpPercent = 0.01
    end
    if whitehp > 0 and whiteHpPercent < 0.01 then
        whiteHpPercent = 0.01
    end
    ---如果是boss，需要刷新一次UI上的大血条
    if hasBoss or curShowBossHP then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, entity:GetID(), redHpPercent, redhp, maxhp)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, entity:GetID(), whiteHpPercent, whitehp, maxhp)
    end
end

---
function HPDisplaySystem_Render:_RefreshChessRedHP1(hpCmpt, redhp, maxhp)
end

---@param entity Entity
function HPDisplaySystem_Render:_RefreshShield(entity, whitehp, redhp, maxhp, shieldValue)
    ---@type HPComponent
    local hpCmpt = entity:HP()

    ---@type UnityEngine.UI.Image
    local shieldImg = hpCmpt:GetShieldImageComponent()
    if shieldImg == nil then
        return
    end

    if shieldValue == nil or shieldValue <= 0 then
        shieldImg.gameObject:SetActive(false)
        if self._lastShieldValue ~= shieldValue then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.UpdateBossShield,
                entity:GetID(),
                shieldValue,
                redhp,
                maxhp
            )
        end
        return
    end

    shieldImg.gameObject:SetActive(true)

    ---@type UnityEngine.RectTransform
    local shieldRectTransform = shieldImg.rectTransform

    ---@type UnityEngine.UI.Image
    local redImg = hpCmpt:GetRedImageComponent()
    local greenRectTransform = redImg.rectTransform
    local hpMaxWidth = redImg.rectTransform.rect.width
    local hpMaxHeight = redImg.rectTransform.rect.height
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

    self._lastShieldValue = shieldValue
end
---@param entity Entity
function HPDisplaySystem_Render:_RefreshCurseHp(entity, whitehp, redhp, maxhp, showCurseHp, curseHpValue)
    ---@type HPComponent
    local hpCmpt = entity:HP()

    ---@type UnityEngine.UI.Image
    local curseHpImg = hpCmpt:GetCurseHpImageComponent()
    if curseHpImg == nil then
        return
    end

    if not showCurseHp then
        curseHpImg.gameObject:SetActive(false)
        if self._lastCurseHpValue ~= curseHpValue then
            GameGlobal.EventDispatcher():Dispatch(
                GameEventType.UpdateBossCurseHP,
                entity:GetID(),
                showCurseHp,
                curseHpValue,
                redhp,
                maxhp
            )
        end
        return
    end

    curseHpImg.gameObject:SetActive(true)

    ---@type UnityEngine.RectTransform
    local curseHpRectTransform = curseHpImg.rectTransform

    ---@type UnityEngine.UI.Image
    local redImg = hpCmpt:GetRedImageComponent()
    local greenRectTransform = redImg.rectTransform
    local hpMaxWidth = redImg.rectTransform.rect.width
    local hpMaxHeight = redImg.rectTransform.rect.height
    local curseHpPercent = curseHpValue / maxhp
    if curseHpPercent > 1 then
        curseHpPercent = 1
    end

    ---长度
    local curseHpWidth = curseHpPercent * hpMaxWidth
    curseHpRectTransform.sizeDelta = Vector2(curseHpWidth, hpMaxHeight)

    self._lastCurseHpValue = curseHpValue
end
---@param e Entity
---@param hpComponent HPComponent
function HPDisplaySystem_Render:_CreateHPSep(e, hpComponent)
    local sepList = hpComponent:GetHPLockSepList()
    if hpComponent:IsInitSep() or #sepList == 0 then
        return
    end
    ---@type UISelectObjectPath
    local sepT = hpComponent:GetSepImageComponent()
    local sepPool = UICustomWidgetPool:New(self, sepT)
    sepPool:SpawnObjects("UICustomWidget", #sepList)
    local sepUIList = sepPool:GetAllSpawnList()
    hpComponent:SetSepPoolWidget(sepPool)
    hpComponent:SetInitSepState(true)
    ---@type UnityEngine.UI.Image
    local redImg = hpComponent:GetRedImageComponent()
    local hpMaxWidth = redImg.rectTransform.rect.width
    for i = 1, #sepList do
        local sepPer = sepList[i]
        local offsetX = 0
        if sepPer >= 50 then
            offsetX = (sepPer - 50) * hpMaxWidth / 100
        else
            offsetX = (50 - sepPer) * hpMaxWidth / 100 * -1
        end
        ---@type UnityEngine.GameObject
        local go = sepUIList[i]:GetGameObject()
        go.transform.localPosition = Vector3(offsetX, 0, 0)
    end
end

---刷新血条
function HPDisplaySystem_Render:_RefreshHpBar(e)
    ---@type HPComponent
    local hpCmpt = e:HP()

    local redhp = hpCmpt:GetRedHP()
    local whitehp = hpCmpt:GetWhiteHP()
    local maxhp = hpCmpt:GetMaxHP()
    local greyHP = hpCmpt:GetGreyHP()
    local shieldValue = hpCmpt:GetShieldValue()
    local showCurseHp = hpCmpt:GetShowCurseHp()
    local curseHpValue = hpCmpt:GetCurseHpValue()

    local slider_entity_id = hpCmpt:GetHPSliderEntityID()
    local slider_entity = self._world:GetEntityByID(slider_entity_id)
    if not slider_entity then
        return
    end
    local go = slider_entity:View().ViewWrapper.GameObject
    if hpCmpt:IsShowHPSlider() then
        self:_RefreshHPSlider(e, whitehp, redhp, maxhp, greyHP)
        self:_RefreshShield(e, whitehp, redhp, maxhp, shieldValue)
        self:_RefreshCurseHp(e, whitehp, redhp, maxhp, showCurseHp, curseHpValue)
        self:_CreateHPSep(e, hpCmpt) --锁血怪物在用
        self:_RefreshTrapHPSep(e, hpCmpt, redhp, maxhp) --机关次数血条
    else
        go:SetActive(false)
    end

    --UI顶部大血条刷新逻辑
    local hasBoss = e:HasBoss()
    ---@type BuffViewComponent
    local buffCmpt = e:BuffView()
    --身上有buff标志 自己显示在BOSS血条（映镜的墙壁）
    local curShowBossHP = buffCmpt and buffCmpt:HasBuffEffect(BuffEffectType.CurShowBossHP)

    if hasBoss or curShowBossHP then
        self:_RefreshUIBossHP(e)
    end
    --Log.notice("holder has no view")
end

---@param e Entity
---
function HPDisplaySystem_Render:_TryIntializeHPCacheComponent(e)
    ---@type HPComponent
    local hpCmpt = e:HP()
    if hpCmpt:GetWhiteImageComponent() then
        return
    end

    local sliderEntityID = hpCmpt:GetHPSliderEntityID()
    local sliderEntity = self._world:GetEntityByID(sliderEntityID)
    if not sliderEntity then
        return
    end

    local go = sliderEntity:View().ViewWrapper.GameObject
    local uiview = go:GetComponent("UIView")

    local whiteImgCmpt = uiview:GetUIComponent("Image", "white")
    local redImgCmpt = uiview:GetUIComponent("Image", "red")
    local shieldImg = uiview:GetUIComponent("Image", "shield")
    local sepT = uiview:GetUIComponent("UISelectObjectPath", "Sep")
    local greyImg = uiview:GetUIComponent("Image", "grey")
    local curseHpImg = uiview:GetUIComponent("Image", "curseHp")

    hpCmpt:SetHPImageComponent(whiteImgCmpt, redImgCmpt, shieldImg, sepT, greyImg,curseHpImg)

    if (self._world:MatchType() == MatchType.MT_Chess and (e:HasChessPet() or e:HasMonsterID())) then
        self:_TryInitializeChessHPCacheComponent(e, uiview, hpCmpt)
        self:_InitializeHPScaleRuler(e, hpCmpt)
    end
end

---@param uiview UIView
---@param hpCmpt HPComponent
---
function HPDisplaySystem_Render:_TryInitializeChessHPCacheComponent(e, uiview, hpCmpt)
    local chessHP = uiview:GetGameObject("chessHP")
    local chessHPText = uiview:GetUIComponent("UILocalizationText", "chessHPText")
    local chessAttackTarget = uiview:GetGameObject("chessAttackTarget")
    local chessRecoverTarget = uiview:GetGameObject("chessRecoverTarget")
    hpCmpt:SetChessUIComponent(chessHP, chessHPText, chessAttackTarget, chessRecoverTarget)

    hpCmpt:SetChessHPBarGroup(uiview:GetGameObject("ChessHPGroup"))
    hpCmpt:SetChessHPWhite1(uiview:GetUIComponent("Image", "chessWhite1"))
    hpCmpt:SetChessHPRed1(uiview:GetUIComponent("Image", "chessRed1"))
    local selectPathScaleRuler1 = uiview:GetUIComponent("UISelectObjectPath", "ScaleRuler1")
    hpCmpt:SetChessHPScaleRuler1(UICustomWidgetPool:New(nil, selectPathScaleRuler1))
    hpCmpt:SetChessHPWhite2(uiview:GetUIComponent("Image", "chessWhite2"))
    hpCmpt:SetChessHPRed2(uiview:GetUIComponent("Image", "chessRed2"))
    local selectPathScaleRuler2 = uiview:GetUIComponent("UISelectObjectPath", "ScaleRuler2")
    hpCmpt:SetChessHPScaleRuler2(UICustomWidgetPool:New(nil, selectPathScaleRuler2))

    local csgoBuffRoot = uiview:GetGameObject("buffRoot")
    local csrtBuffRoot = csgoBuffRoot:GetComponent("RectTransform")
    local v2AnchoredPos = csrtBuffRoot.anchoredPosition
    v2AnchoredPos.x = v2AnchoredPos.x
    csrtBuffRoot.anchoredPosition = v2AnchoredPos
    
    hpCmpt:GetChessHPBarGroup():SetActive(true)
    chessHP:SetActive(true)
end

---
---@param hpCmpt HPComponent
function HPDisplaySystem_Render:_InitializeHPScaleRuler(e, hpCmpt)
    local maxHP = hpCmpt:GetMaxHP()
    local scaleRuler1 = hpCmpt:GetChessHPScaleRuler1()
    local hpMaxWidth = scaleRuler1.dynamicInfoOfEngine.transform.rect.width
    local halfHPMaxWidth = 0.5 * hpMaxWidth
    local offset = hpMaxWidth / maxHP
    if maxHP <= BattleConst.HUDUI_ChessHPSecondBarThreshold then
        local tScaleMark = scaleRuler1:SpawnObjects("UICustomWidget", maxHP - 1)
        for i = 1, #tScaleMark do
            local offsetX = (i * offset) - halfHPMaxWidth
            ---@type UnityEngine.GameObject
            local go = tScaleMark[i]:GetGameObject()
            go.transform.localPosition = Vector3(offsetX, 0, 0)
        end
    end
end

---@param e Entity
---@param hpComponent HPComponent
function HPDisplaySystem_Render:_RefreshTrapHPSep(e, hpComponent, redhp, maxhp)
    if not hpComponent:GetShowTrapSep() then
        return
    end

    if not hpComponent:IsInitTrapSep() then
        ---@type UISelectObjectPath
        local sepT = hpComponent:GetSepImageComponent()

        local sepPool = UICustomWidgetPool:New(self, sepT)
        sepPool:SpawnObjects("UICustomWidget", maxhp - 1)
        hpComponent:SetSepPoolWidget(sepPool)
        hpComponent:SetInitTrapSepState(true)

        local sepPoolList = sepPool:GetAllSpawnList()

        ---@type UnityEngine.UI.Image
        local redImg = hpComponent:GetRedImageComponent()
        local hpMaxWidth = redImg.rectTransform.rect.width
        for i = 1, maxhp - 1 do
            local sepPer = math.floor(i / maxhp * 100)
            local offsetX = 0
            if sepPer >= 50 then
                offsetX = (sepPer - 50) * hpMaxWidth / 100
            else
                offsetX = (50 - sepPer) * hpMaxWidth / 100 * -1
            end
            ---@type UnityEngine.GameObject
            local go = sepPoolList[i]:GetGameObject()
            go.transform.localPosition = Vector3(offsetX, 0, 0)
        end
    end

    local sepPoolWidget = hpComponent:GetSepPoolWidget()
    if not sepPoolWidget then
        return
    end

    local sepPoolList = sepPoolWidget:GetAllSpawnList()

    for i = 1, table.count(sepPoolList) do
        local show = i < redhp
        sepPoolList[i]:GetGameObject():SetActive(show)
    end
end

function HPDisplaySystem_Render:_RefreshUIBossHP(e)
    ---@type HPComponent
    local hpCmpt = e:HP()

    local redhp = hpCmpt:GetRedHP()
    local whitehp = hpCmpt:GetWhiteHP()
    local maxhp = hpCmpt:GetMaxHP()
    local greyHP = hpCmpt:GetGreyHP()
    local shieldValue = hpCmpt:GetShieldValue()
    local showCurseHp = hpCmpt:GetShowCurseHp()
    local curseHpValue = hpCmpt:GetCurseHpValue()

    local redHpPercent = redhp / maxhp
    local whiteHpPercent = whitehp / maxhp
    --当血量<1%时，显示1%
    if redhp > 0 and redHpPercent < 0.01 then
        redHpPercent = 0.01
    end
    if whitehp > 0 and whiteHpPercent < 0.01 then
        whiteHpPercent = 0.01
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossRedHp, e:GetID(), redHpPercent, redhp, maxhp)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossWhiteHp, e:GetID(), whiteHpPercent, whitehp, maxhp)
    local greyVal = e:HP():GetGreyHP()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossGreyHP, e:GetID(), greyVal, redhp, maxhp)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossCurseHP, e:GetID(), showCurseHp, curseHpValue, redhp, maxhp)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossShield, e:GetID(), shieldValue, redhp, maxhp)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateBossCurseHP, e:GetID(), showCurseHp, curseHpValue, redhp, maxhp)
end
