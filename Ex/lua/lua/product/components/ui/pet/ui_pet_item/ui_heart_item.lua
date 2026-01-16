---@class UIHeartItem : UICustomWidget
_class("UIHeartItem", UICustomWidget)
UIHeartItem = UIHeartItem
function UIHeartItem:Constructor()
    ---@type Pet
    self._heartItemInfo = nil
    self._callBack = nil

    ---@type PetModule
    self._petModule = GameGlobal.GameLogic():GetModule(PetModule)
end

function UIHeartItem:OnShow()
    self._uiHeartItemAtlas = self:RootUIOwner():GetAsset("UIHeartItem.spriteatlas", LoadType.SpriteAtlas)
    self.atlasProperty = self:RootUIOwner():GetAsset("Property.spriteatlas", LoadType.SpriteAtlas)
    self._atlasAwake = self:RootUIOwner():GetAsset("UIAwake.spriteatlas", LoadType.SpriteAtlas)
    self._tryGo = self:GetGameObject("Try")
    self._tryGo:SetActive(false)
    self._firstPassGo = self:GetGameObject("FirstPass")
    self._firstPassGo:SetActive(false)
    self._lvPart = self:GetGameObject("LVPart")
    
    --刻度对应血量
    self._dialLine2Hp = Cfg.cfg_global["UIWidgetBattlePet_dialLine2Hp"].IntValue or 200
    self._bigDiaLine = Cfg.cfg_global["UIWidgetBattlePet_bigDiaLine"].IntValue or 5

    ---@type UnityEngine.UI.Image
    self._firstAttIcon = self:GetUIComponent("Image", "firstAttribute")
    ---@type UnityEngine.UI.Image
    self._secondAttribute = self:GetUIComponent("Image", "secondAttribute")
    self._firstGo = self:GetGameObject("first")
    self._secondGo = self:GetGameObject("second")

    self._nameText = self:GetUIComponent("UILocalizationText", "name")
    self._lvValueText = self:GetUIComponent("UILocalizationText", "lvValue")

    self._logo = self:GetUIComponent("RawImageLoader", "logo")

    self._rawimage = self:GetUIComponent("RawImageLoader", "drawIcon")

    self._gradeIcon = self:GetUIComponent("Image", "grade")

    ---@type UnityEngine.UI.Image
    self._qualityIcon = self:GetUIComponent("Image", "qualityIcon")

    --能量,探索用
    self._power = self:GetGameObject("power")
    self._powerValue = self:GetUIComponent("UILocalizationText", "powerValue")

    self._anim = self:GetUIComponent("Animation", "anim")

    --new抽卡用
    self._new = self:GetGameObject("new")
    self._new:SetActive(false)

    self._select = self:GetGameObject("select")
    self._diLayer = self:GetGameObject("diLayer")
    ---@type Graphic
    self._interactTarget = self:GetUIComponent("Graphic", "diLayer")

    self._stars = self:GetGameObject("stars")

    self._hp = self:GetGameObject("hp")
    self._hpvalue = self:GetUIComponent("Image", "hpvalue")
    self._hpvalueRect = self:GetUIComponent("RectTransform", "dialLines")
    self._hpbg = self:GetUIComponent("Image", "hpbg")
    self._dialLines = self:GetUIComponent("UISelectObjectPath", "dialLines")
    self._grayMask = self:GetGameObject("grayMask")

    self._animRoot = self:GetUIComponent("RectTransform", "animRoot")
    self._root = self:GetUIComponent("CanvasGroup", "root")
    self._animRoot = self:GetUIComponent("RectTransform","animRoot")

    --switch
    self._switchCount = self:GetGameObject("switchCount")
    self._switchCountTex = self:GetUIComponent("UILocalizationText", "switchCountTex")
    self._switchMask = self:GetGameObject("switchCountMask")

    self._redPoint = self:GetGameObject("redPoint")

    self:ShowRedPoint(false)

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._diLayer),
        UIEvent.Press,
        function()
            self._select:SetActive(true)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._diLayer),
        UIEvent.Release,
        function()
            self._select:SetActive(false)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self._diLayer),
        UIEvent.EndDrag,
        function()
            self._select:SetActive(false)
        end
    )

    self:AttachEvent(GameEventType.CheckCardNew, self.CheckCardNew)
    self:AttachEvent(GameEventType.PetDataChangeEvent, self.PetDataChangeEvent)
end

function UIHeartItem:PlayFadeInAnim()
    self._anim:Play("uieff_HeartSpiritItem_FadeIn")
end

function UIHeartItem:ResetInAnim()
    self._root.alpha = 1
end

function UIHeartItem:PetDataChangeEvent(pstid_list)
    if pstid_list then
        for key, value in pairs(pstid_list) do
            if value == self._petPstID then
                self._heartItemInfo = self._petModule:GetPet(self._petPstID)
                self:ShowInfo()
                break
            end
        end
    end
end

function UIHeartItem:OnHide()
    self:DetachEvent(GameEventType.CheckCardNew, self.CheckCardNew)
    self:DetachEvent(GameEventType.PetDataChangeEvent, self.PetDataChangeEvent)

    self._heartItemInfo = nil
    self._callBack = nil
    self._rawimage = nil
    self._qualityIcon = nil
    self._lvValueText = nil

    self._nameText = nil

    self._firstAttIcon = nil
    self._secondAttribute = nil

    self._gradeIcon = nil
    self._uiHeartItemAtlas = nil
end
---@param skinEffectPath PetSkinEffectPath
function UIHeartItem:SetData(pet, callBack, showNew, fristIn, teamType, skinEffectPath, isHelp, isSpPet, isFastSelect)
    if fristIn then
        self._anim:Play()
    end
    self._callBack = callBack
    if not pet then
        return
    end
    self._heartItemInfo = pet
    self._petPstID = pet:GetPstID()

    self._showNew = false
    if showNew then
        self._showNew = showNew
    end

    self._fromMaze = (teamType and teamType == TeamOpenerType.Maze)
    self._fromAir = (teamType and teamType == TeamOpenerType.Air)

    self._skinEffectPath = skinEffectPath
    self._isHelp = isHelp
    self._isSpPet = isSpPet
    self._isFastSelect = isFastSelect
    self:ShowInfo()

    self:CheckCardNew()

    self._interactTarget.raycastTarget = self._callBack ~= nil

    if teamType == TeamOpenerType.Vampire then
        self._lvPart:SetActive(false)
        if UIN25VampireUtil.IsTryPet(self._heartItemInfo:GetTemplateID()) then --是否是试用光灵
            self._tryGo:SetActive(true)
        else
            self._tryGo:SetActive(false)
        end
        if UIN25VampireUtil.PetCompleteFirstPass(self._heartItemInfo:GetTemplateID()) then  --是否通关
            self._firstPassGo:SetActive(true)
        else
            self._firstPassGo:SetActive(false)
        end
    end
end

function UIHeartItem:ShowInfo()
    local animPos
    if self._isSpPet and not self._isFastSelect then
        animPos = Vector2(0,-10)
    else
        animPos = Vector2(0,-64)
    end
    self._animRoot.anchoredPosition = animPos

    local petBody = self._heartItemInfo:GetPetBody(self._skinEffectPath)
    if petBody then
        ---@type RawImageLoader
        self._rawimage:LoadImage(petBody)
    end

    --name
    self._nameText:SetText(StringTable.Get(self._heartItemInfo:GetPetName()))

    if self._fromMaze then
        self._lvValueText.gameObject:SetActive(false)
    else
        self._lvValueText.gameObject:SetActive(true)
        --level
        local petLevel = self._heartItemInfo:GetPetLevel()
        self._lvValueText:SetText(StringTable.Get("str_pet_config_level") .. petLevel)
    end

    self:GetMazePower(self._fromMaze)

    --switch
    self:GetSwitchCount()

    --logo
    self._logo:LoadImage(self._heartItemInfo:GetPetLogo())

    local petStar = self._heartItemInfo:GetPetStar()
    self._qualityIcon.sprite = self._uiHeartItemAtlas:GetSprite("map_biandui_pin" .. petStar)

    self:ShowAwakenAndGradeIcon()

    --element
    local cfg_pet_element = Cfg.cfg_pet_element {}
    if cfg_pet_element then
        self._firstAttIcon.sprite =
            self.atlasProperty:GetSprite(
            UIPropertyHelper:GetInstance():GetColorBlindSprite(
                cfg_pet_element[self._heartItemInfo:GetPetFirstElement()].Icon
            )
        )
        if self._heartItemInfo:GetPetSecondElement() and self._heartItemInfo:GetPetSecondElement() > 0 then
            self._secondGo:SetActive(true)

            self._secondAttribute.sprite =
                self.atlasProperty:GetSprite(
                UIPropertyHelper:GetInstance():GetColorBlindSprite(
                    cfg_pet_element[self._heartItemInfo:GetPetSecondElement()].Icon
                )
            )
        else
            self._secondGo:SetActive(false)
        end
    end

    self:_SetEquipLv()
    self:_SetJobIcon()
end

function UIHeartItem:_SetEquipLv()
    local obj = UIWidgetHelper.SpawnObject(self, "_equipLv", "UIPetEquipLvIcon")
    obj:SetData(self._heartItemInfo, true)
end

function UIHeartItem:_SetJobIcon()
    local obj = UIWidgetHelper.SpawnObject(self, "_jobIcon", "UIPetJobIcon")
    obj:SetData(self._heartItemInfo, 2)
end

function UIHeartItem:CheckCardNew()
    --ShowNew只在列表用
    if self._showNew then
        ---@type PetModule
        self._new:SetActive(self._petModule:BeNewPet(self._heartItemInfo:GetTemplateID()))
    end
end

--卡带,战斗模拟器
function UIHeartItem:GetSwitchCount()
    local fromAir = self._fromAir
    self._switchCount:SetActive(fromAir and not self._isHelp)
    if fromAir and not self._isHelp then
        local airModule = GameGlobal.GetModule(AircraftModule)
        local countMax = Cfg.cfg_aircraft_values[35].IntValue or 2
        local room = airModule:GetRoomByRoomType(AirRoomType.TacticRoom)
        local count = room:GetPetRemainFightNum(self._petPstID)
        local countStr = ""
        if count <= 0 then
            countStr = "<color=#f34141>" .. count .. "/" .. countMax .. "</color>"
        else
            countStr = count .. "<color=#f34141>/</color>" .. countMax
        end
        self._switchCountTex:SetText(countStr)

        self._switchMask:SetActive(count <= 0)
    end
end

--探索能量
function UIHeartItem:GetMazePower(fromMaze)
    if not fromMaze then
        self._hp:SetActive(false)
        self._power:SetActive(false)
        return
    end

    ---@type MazeModule
    local mazeModule = self:GetModule(MazeModule)

    --power
    --威能主动技
    local useLegendEnergy = mazeModule:IsPetActiveSkillUseLegendEnergy(self._petPstID)
    if not fromMaze or useLegendEnergy then
        self._power:SetActive(false)
    else
        self._power:SetActive(true)
        local powerCurrent, powerUpper = mazeModule:GetPetPower(self._petPstID)
        if powerCurrent < 0 then
            powerCurrent = powerUpper
        end
        self._powerValue:SetText(powerCurrent)
    end

    --hp
    self._hp:SetActive(true)
    ---@type MazePetInfo
    local mazePet = mazeModule:GetMazePetInfoByPstId(self._petPstID)
    local upper = math.floor(mazeModule:GetCalPetMaxHp(self._petPstID))
    local hp = math.floor(mazePet.blood * upper + 0.5)
    local die = mazePet.is_dead
    self._diaSp1 = self._uiHeartItemAtlas:GetSprite("map_biandui_xuetiao5")
    self._diaSp2 = self._uiHeartItemAtlas:GetSprite("map_biandui_xuetiao4")
    local hpvaluewidth = self._hpvalueRect.sizeDelta.x
    local dialLineCount = math.ceil(upper / self._dialLine2Hp) - 1
    self._dialLines:SpawnObjects("UIHeartMazeHpDialLineItem", dialLineCount)
    ---@type UIHeartMazeHpDialLineItem[]
    local dialLines = self._dialLines:GetAllSpawnList()
    for i = 1, #dialLines do
        local posx = (hpvaluewidth / upper * self._dialLine2Hp * i)
        local middleImg = (i % self._bigDiaLine == 0)
        local show = (hp > (i * self._dialLine2Hp))
        local sp
        if middleImg then
            sp = self._diaSp1
        else
            sp = self._diaSp2
        end
        dialLines[i]:SetData(i, posx, sp, show)
    end

    if die then
        self._hpbg.sprite = self._uiHeartItemAtlas:GetSprite("map_biandui_xuetiao1")
        self._hpvalue.fillAmount = 0
    else
        self._hpbg.sprite = self._uiHeartItemAtlas:GetSprite("map_biandui_xuetiao2")
        self._hpvalue.fillAmount = hp / upper
    end

    self._grayMask:SetActive(die)
end

function UIHeartItem:ShowLogo()
    self._logo:LoadImage(self._heartItemInfo:GetPetLogo())
end

function UIHeartItem:ShowAwakenAndGradeIcon()
    local petStar = self._heartItemInfo:GetPetStar()
    local awakenStep = self._heartItemInfo:GetPetAwakening()

    self._starSp1 = self._uiHeartItemAtlas:GetSprite("spirit_xing3_frame")
    self._starSp2 = self._uiHeartItemAtlas:GetSprite("spirit_xing2_frame")

    local awakenStartIndex = petStar - awakenStep
    self:SetStar(awakenStartIndex, petStar)

    local petId = self._heartItemInfo:GetTemplateID()
    local petGradeLevel = self._heartItemInfo:GetPetGrade()
    self._gradeIcon.sprite = self._atlasAwake:GetSprite(UIPetModule.GetAwakeSpriteName(petId, petGradeLevel))
end

function UIHeartItem:SetStar(awakenStartIndex, max)
    for i = 1, 6 do
        local star = self._stars.transform:GetChild(i - 1).gameObject
        if i > max then
            star:SetActive(false)
        else
            star:SetActive(true)
            local sp
            if i > awakenStartIndex then
                sp = self._starSp1
            else
                sp = self._starSp2
            end
            star:GetComponent("Image").sprite = sp
        end
    end
end

function UIHeartItem:openDetailOnClick(go)
    --self._petModule.uiModule:SetCurSelctPet(self._heartItemInfo)
    -- 播音效
    --AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoudPetDetail)
    if self._showNew then
        self:CancelNew()
    end
    if self._callBack then
        self._callBack(self._petPstID)
    end
end

--取消new
function UIHeartItem:CancelNew()
    local petInfo = self._petModule:GetPet(self._petPstID)
    if self._petModule:BeNewPet(petInfo:GetTemplateID()) then
        self:Lock("UIHeartCancelNew")
        self:StartTask(
            function(TT)
                local res = self._petModule:DelNewPetMark(TT, petInfo:GetTemplateID())
                self:UnLock("UIHeartCancelNew")
                if res:GetSucc() then
                    --已经在module派发
                    --GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckCardNew)
                else
                    Log.fatal("###petModule:DelNewPetMark - msg : ", res:GetResult())
                end
            end,
            self
        )
    end
end

function UIHeartItem:ShowRedPoint(isShow)
    self._redPoint:SetActive(isShow)
end

function UIHeartItem:GetPetTid()
    return self._heartItemInfo:GetTemplateID()
end
