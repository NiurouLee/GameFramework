--
---@class UIWidgetPetArea : UICustomWidget
_class("UIWidgetPetArea", UICustomWidget)
UIWidgetPetArea = UIWidgetPetArea
--初始化
function UIWidgetPetArea:OnShow(uiParams)
    self._playBTAnim = false
    self:InitWidget()
    self:InitImg()
end

function UIWidgetPetArea:InitImg()
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    self._matchType = matchEnterData:GetMatchType()
    if self._matchType == MatchType.MT_MiniMaze then
        self.teamSelected1Img.sprite = self._uiBattlePartnerSprite:GetSprite("N25_mchb_di09")
        self.teamSelected2Img.sprite = self._uiBattlePartnerSprite:GetSprite("N25_mchb_di09")
        self.teamNotSelected1Img.sprite = self._uiBattlePartnerSprite:GetSprite("N25_mchb_di10")
        self.teamNotSelected2Img.sprite = self._uiBattlePartnerSprite:GetSprite("N25_mchb_di10")
        self.switchBG.sprite = self._uiBattlePartnerSprite:GetSprite("N25_mchb_di11")
        self.switchIcon.sprite =  self._uiBattlePartnerSprite:GetSprite("N25_mchb_di08")
    elseif self._matchType == MatchType.MT_EightPets then
        self.teamSelected1Img.sprite = self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di38")
        self.teamSelected2Img.sprite = self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di38")
        self.teamNotSelected1Img.sprite = self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di37")
        self.teamNotSelected2Img.sprite = self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di37")
        self.switchBG.sprite = self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di36")
        self.switchIcon.sprite =  self._uiBattlePartnerSprite:GetSprite("epg_gqxq_di39")
    end
end

--获取ui组件
function UIWidgetPetArea:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.petInfoPool = self:GetUIComponent("UISelectObjectPath", "PetInfoPool")
    ---@type UICustomWidgetPool
    self.petpool = self:GetUIComponent("UISelectObjectPath", "petpool")
    self.petPoolLayout = self:GetUIComponent("GridLayoutGroup", "petpool")
    self.petPoolContentSizeFitter = self:GetUIComponent("ContentSizeFitter", "petpool")
    self._guideWidgetPetIndex = -1
    ---@type UnityEngine.U2D.SpriteAtlas
    self._uiBattlePartnerSprite = self:GetAsset("UIBattlePartner.spriteatlas", LoadType.SpriteAtlas)
    --多列模式

    ---@type UnityEngine.Animation
    self.switchBGAnim = self:GetUIComponent("Animation", "SwitchBg")
    ---@type UnityEngine.Animation
    self.switchIconAnim = self:GetUIComponent("Animation", "SwitchIcon")

    self.switchBtnGo = self:GetGameObject("SwitchColumn")
    ---@type UnityEngine.UI.Image
    self.switchBtnImg = self:GetUIComponent("Image", "SwitchBtnImg")
    ---@type UnityEngine.UI.Image
    self.switchBG = self:GetUIComponent("Image", "SwitchBg")

    ---@type UnityEngine.UI.Image
    self.teamSelected1Img = self:GetUIComponent("Image", "TeamSelected1")
    ---@type UnityEngine.UI.Image
    self.teamNotSelected1Img =self:GetUIComponent("Image", "TeamNotSelected1")

    ---@type UnityEngine.UI.Image
    self.teamSelected2Img = self:GetUIComponent("Image", "TeamSelected2")
    ---@type UnityEngine.UI.Image
    self.teamNotSelected2Img =self:GetUIComponent("Image", "TeamNotSelected2")
    ---@type UnityEngine.UI.Image
    self.switchIcon = self:GetUIComponent("Image", "SwitchIcon")




    self.petPoolTransform = self:GetUIComponent("RectTransform", "petpool")
    self.multiColumnMaskTransform = self:GetUIComponent("RectTransform", "MultiColumnMask")
    self.multiColumnMaskGo = self:GetGameObject("MultiColumnMask")
    self.rootTransform = self:GetUIComponent("RectTransform", "Root")

    self.switchTeam1Go = self:GetGameObject("SwitchTeam1")
    self.switchTeam2Go = self:GetGameObject("SwitchTeam2")
    self.teamSelected1Go = self:GetGameObject("TeamSelected1")
    self.teamNotSelected1Go = self:GetGameObject("TeamNotSelected1")
    self.teamSelected2Go = self:GetGameObject("TeamSelected2")
    self.teamNotSelected2Go = self:GetGameObject("TeamNotSelected2")
    
    self._matRes = {}
    

    self._curColumn = 1
    self._maxColumn = 2
    self._petCountPerColumn = 4
    --generated end--
end

function UIWidgetPetArea:_InitSwitchTeamArea()
    self._matRes = {}
    ---@type UILocalizedTMP
    self.teamNumSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumSel1")
    ---@type UILocalizedTMP
    self.teamTextSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextSel1")
    ---@type UILocalizedTMP
    self.teamNumSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumSel2")
    ---@type UILocalizedTMP
    self.teamTextSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextSel2")
    ---@type UILocalizedTMP
    self.teamNumNotSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumNotSel1")
    ---@type UILocalizedTMP
    self.teamTextNotSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextNotSel1")
    ---@type UILocalizedTMP
    self.teamNumNotSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumNotSel2")
    ---@type UILocalizedTMP
    self.teamTextNotSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextNotSel2")
    ---@type UILocalizedTMP
    self.teamNumNotSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumNotSel1")
    ---@type UILocalizedTMP
    self.teamTextNotSel1TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextNotSel1")
    ---@type UILocalizedTMP
    self.teamNumNotSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamNumNotSel2")
    ---@type UILocalizedTMP
    self.teamTextNotSel2TextTmp = self:GetUIComponent("UILocalizedTMP", "TeamTextNotSel2")


    self.teamNumSel1TextTmpMat = self:SetFontMat( self.teamNumSel1TextTmp ,"battle_switch_team_selected_text_mt.mat")
    self.teamTextSel1TextTmpMat = self:SetFontMat( self.teamTextSel1TextTmp ,"battle_switch_team_selected_text_mt.mat")
    self.teamNumSel2TextTmpMat =self:SetFontMat( self.teamNumSel2TextTmp ,"battle_switch_team_selected_text_mt.mat")
    self.teamTextSel2TextTmpMat = self:SetFontMat( self.teamTextSel2TextTmp ,"battle_switch_team_selected_text_mt.mat")

    if self._matchType == MatchType.MT_MiniMaze then
        ---外发光 ---E92020 233/255,32/255,32/255
        self.teamNumSel1TextTmpMat:SetColor("_UnderlayColor",Color.New(233/255,32/255,32/255,255))
        self.teamTextSel1TextTmpMat:SetColor("_UnderlayColor",Color.New(233/255,32/255,32/255,255))
        self.teamNumSel2TextTmpMat:SetColor("_UnderlayColor",Color.New(233/255,32/255,32/255,255))
        self.teamTextSel2TextTmpMat:SetColor("_UnderlayColor",Color.New(233/255,32/255,32/255,255))
        --颜色 ---FFF4ED  255/255,244/255,237/255
        self.teamTextSel1TextTmp.color=Color.New(255/255,244/255,237/255,1)
        self.teamNumSel1TextTmp.color=Color.New(255/255,244/255,237/255,1)
        self.teamTextSel2TextTmp.color=Color.New(255/255,244/255,237/255,1)
        self.teamNumSel2TextTmp.color=Color.New(255/255,244/255,237/255,1)
        --颜色 ---821E28 130/255,30/255,40/255
        self.teamNumNotSel1TextTmp.color =Color.New(130/255,30/255,40/255,1)
        self.teamTextNotSel1TextTmp.color = Color.New(130/255,30/255,40/255,1)
        self.teamNumNotSel2TextTmp.color =Color.New(130/255,30/255,40/255,1)
        self.teamTextNotSel2TextTmp.color = Color.New(130/255,30/255,40/255,1)
    elseif self._matchType == MatchType.MT_EightPets then
        ---外发光 ---221009 34/255,16/255,9/255,0.5
        self.teamTextSel1TextTmpMat:SetColor("_UnderlayColor",Color.New(34/255,16/255,9/255,0.5))
        self.teamTextSel2TextTmpMat:SetColor("_UnderlayColor",Color.New(34/255,16/255,9/255,0.5))
        self.teamNumSel1TextTmpMat:SetColor("_UnderlayColor",Color.New(34/255,16/255,9/255,0.5))
        self.teamNumSel2TextTmpMat:SetColor("_UnderlayColor",Color.New(34/255,16/255,9/255,0.5))
        ---颜色 ---FFE0D2 255/255,224/255,210/255
        self.teamTextSel1TextTmp.color=Color.New(255/255,224/255,210/255,1)
        self.teamNumSel1TextTmp.color=Color.New(255/255,224/255,210/255,1)
        self.teamTextSel2TextTmp.color=Color.New(255/255,224/255,210/255,1)
        self.teamNumSel2TextTmp.color=Color.New(255/255,224/255,210/255,1)
        ---颜色 ---241D1E 36/255,29/255,30/255
        self.teamNumNotSel2TextTmp.color =Color.New(36/255,29/255,30/255,1)
        self.teamNumNotSel1TextTmp.color =Color.New(36/255,29/255,30/255,1)
        self.teamTextNotSel1TextTmp.color = Color.New(36/255,29/255,30/255,1)
        self.teamTextNotSel2TextTmp.color = Color.New(36/255,29/255,30/255,1)
    end

    self:_RefreshSwitchTeamAreaState(true)
end

function UIWidgetPetArea:_RefreshSwitchTeamAreaStateCoroutine(TT,init)
    if self._curColumn == 1 then
        if not init then
            self.switchIconAnim:Play("uieffanim_UIWidgetPetArea_SwitchIcon")
            YIELD(TT,100)
            self.teamSelected1Go:SetActive(true)
            self.teamNotSelected1Go:SetActive(true)
            self.teamSelected2Go:SetActive(true)
            self.teamNotSelected2Go:SetActive(true)
            self._playBTAnim = true
            self.switchBGAnim:Play("uieffanim_UIWidgetPetArea_team2")
            YIELD(TT)
            self.switchTeam1Go.transform:SetAsLastSibling()
            YIELD(TT,300)
        end
        self.teamSelected1Go:SetActive(true)
        self.teamNotSelected1Go:SetActive(false)
        self.teamSelected2Go:SetActive(false)
        self.teamNotSelected2Go:SetActive(true)
        self.switchTeam1Go.transform:SetAsLastSibling()
        self._playBTAnim = false
    else
        if not init then
            self.switchIconAnim:Play("uieffanim_UIWidgetPetArea_SwitchIcon")
            YIELD(TT,100)
            self.teamSelected1Go:SetActive(true)
            self.teamNotSelected1Go:SetActive(true)
            self.teamSelected2Go:SetActive(true)
            self.teamNotSelected2Go:SetActive(true)
            self._playBTAnim = true
            self.switchBGAnim:Play("uieffanim_UIWidgetPetArea_team1")
            YIELD(TT)
            self.switchTeam2Go.transform:SetAsLastSibling()
            YIELD(TT,300)
        end
        self.teamSelected1Go:SetActive(false)
        self.teamNotSelected1Go:SetActive(true)
        self.teamSelected2Go:SetActive(true)
        self.teamNotSelected2Go:SetActive(false)
        self.switchTeam2Go.transform:SetAsLastSibling()
        self._playBTAnim = false
    end
end

function UIWidgetPetArea:_RefreshSwitchTeamAreaState(init)
    GameGlobal.TaskManager():CoreGameStartTask(self._RefreshSwitchTeamAreaStateCoroutine,self,init)
end
---@return UnityEngine.Material
function UIWidgetPetArea:SetFontMat(lable,resname) 
    local res  = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    table.insert(self._matRes ,res)
    if not res  then 
        return 
    end 
    local obj  = res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
    return lable.fontMaterial
    --lable.fontMaterial:SetColor("_UnderlayColor",Color.New(233/255,20/255,20/255,255))
end
function UIWidgetPetArea:OnHide()
    self._matRes = {}
end
function UIWidgetPetArea:SwitchColumnOnClick()
    local petCount = #self._petList
    if petCount <= self._petCountPerColumn or self._playBTAnim then
        return
    end
    if self:IsAutoFighting() then
        self:ShowAutoFightForbiddenMsg()
        return
    end
    self:_SwitchColumn()
end
function UIWidgetPetArea:_SwitchColumn()
    self._curColumn = self._curColumn + 1
    if self._curColumn > self._maxColumn then
        self._curColumn = 1
    end
    self:_RefreshSwitchTeamAreaState()
    local curPos = self.petPoolTransform.anchoredPosition
    local oriY = 10
    local curY = oriY + (self._curColumn - 1) * 720
    self.petPoolTransform.anchoredPosition = Vector2(curPos.x,curY)
    if GameGlobal.UIStateManager():IsShow("UIBattleChangeTeamLeader") then
        GameGlobal.UIStateManager():CloseDialog("UIBattleChangeTeamLeader")
        self:ShowChangeTeamLeaderData()
    end
end
--region Event
function UIWidgetPetArea:RegisterEvent()
    self:AttachEvent(GameEventType.PetPowerChange, self.OnPetPowerChange)
    self:AttachEvent(GameEventType.PetExtraPowerChange, self.OnPetPowerChangeForExtra)
    self:AttachEvent(GameEventType.PetLegendPowerChange, self.OnPetLegendPowerChange)
    self:AttachEvent(GameEventType.PetActiveSkillGetReady, self.OnPetActiveSkillGetReady)
    self:AttachEvent(GameEventType.PetExtraActiveSkillGetReady, self.OnPetExtraActiveSkillGetReady)
    self:AttachEvent(GameEventType.PetActiveSkillCancelReady, self.OnPetActiveSkillCancelReady)
    self:AttachEvent(GameEventType.PetExtraActiveSkillCancelReady, self.OnPetExtraActiveSkillCancelReady)
    self:AttachEvent(GameEventType.PetPowerAndWatchChange, self.OnPetPowerAndWatchChange)

    self:AttachEvent(GameEventType.SetHeadMaskAlpha, self.OnPetHeadMaskAlpha)
    self:AttachEvent(GameEventType.UIChangeTeamLeader, self._UIChangeTeamLeader)
    self:AttachEvent(GameEventType.CallUIChangeTeamOrderView, self.OnCallUIChangeTeamOrderView)
    self:AttachEvent(GameEventType.AddNewBattlePet, self.AddMiddleEnterPet)
    self:AttachEvent(GameEventType.UICancelActiveSkillSwitchTimer, self.CancelActiveSkillSwitchTimer)
    self:AttachEvent(GameEventType.UIShowChangeTeamLeaderData, self.ShowChangeTeamLeaderData)
    self:AttachEvent(GameEventType.UIExclusivePetHeadMaskAlpha, self.OnExclusivePetHeadMaskAlpha)
    if self._isFromMaze then--所以RegisterEvent要做SetData中
        self:AttachEvent(GameEventType.OnPetHpChangedInMaze, self.OnPetHpChangedInMaze)
        -- 表现移到了MainStateSystem:_DoRenderPetDead 走统一的表现队列
        -- self:AttachEvent(GameEventType.OnPetDeadChangeHeadPos, self.OnPetDeadChangeHeadPos)
    end
    self:AttachEvent(GameEventType.AutoFightCheckSwitchPetColumn, self.AutoFightCheckSwitchPetColumn)
    self:AttachEvent(GameEventType.ShowHideUiMultiPowerInfoByIndex, self.ShowHideUiMultiPowerInfoByIndex)
end

---@param matchEnterData MatchEnterData
function UIWidgetPetArea:SetMultiColumnByMatchEnterData(matchEnterData)
    if matchEnterData:GetMatchType() == MatchType.MT_MiniMaze or
            matchEnterData:GetMatchType() == MatchType.MT_EightPets
    then
        self._useMultiColumn = true
    end
end

function UIWidgetPetArea:SetMultiColumnByPetCount(petCount)
    if petCount > self._petCountPerColumn+1 then
        self._useMultiColumn = true
    else
        self._useMultiColumn = false
    end
end

--设置数据
function UIWidgetPetArea:SetData(uiBattle)
    --临时直接调用uibattle的方法，后续去掉，sjs_todo
    ---@type UIBattle
    self._uiBattle = uiBattle
    --pet数据来自petmodule
    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    self._isFromMaze = (matchEnterData:GetMatchType() == MatchType.MT_Maze)
    self._isMiniMaze = (matchEnterData:GetMatchType() == MatchType.MT_MiniMaze)
    self:SetMultiColumnByMatchEnterData(matchEnterData)

    ---@type LuaMatchPlayerInfo
    local localPlayerInfo = matchEnterData:GetLocalPlayerInfo()
    local matchPets = matchEnterData:GetLocalMatchPets()
    self._matchPets = matchPets
    self.petPool = self:GetUIComponent("UISelectObjectPath", "petpool")
    self.petPoolLayout = self:GetUIComponent("GridLayoutGroup", "petpool")
    local petCount = 0
    for i = 1, #localPlayerInfo.pet_list do
        if localPlayerInfo.pet_list[i].pet_pstid ~= FormationPetPlaceType.FormationPetPlaceType_None then
            petCount = petCount + 1
        end
    end

    self.petPoolLayout.constraintCount = petCount
    self.petPool:SpawnObjects("UIWidgetBattlePet", petCount)
    ---@type table<int, UIWidgetBattlePet> 宝宝UIWidget列表
    self.uiWidgetBattlePets = self.petPool:GetAllSpawnList()
    self._petDatas = {}
    self._petWidgets = {}
    self.itemsTweenerTab = {}
    local index = 1

    for i = 1, #localPlayerInfo.pet_list do
        local petID = localPlayerInfo.pet_list[i].pet_pstid
        if petID ~= FormationPetPlaceType.FormationPetPlaceType_None then
            ----@type MatchPet
            local pet = matchPets[petID]
            self._petDatas[petID] = pet
            self._petWidgets[petID] = self.uiWidgetBattlePets[index]
            pet.uiid = index
            self.itemsTweenerTab[index] = nil
            self.uiWidgetBattlePets[index]:InitUIWidgetPet(
                index,
                petID,
                pet,
                function(index, skillId, maxPower, leftPower, canCast, go)
                    self:OnPetClickCallBack(index, skillId, maxPower, leftPower, canCast, go)
                end,
                function(go)
                    self:OnPetSwitchCallBack(go)
                end,
                function(index, uiDataArray, go, isVariantSkillList, lastClickIndex)
                    self:OnPetMultiSkillClickCallBack(index,uiDataArray, go, isVariantSkillList, lastClickIndex)
                end,
                function(go)
                    self:OnPetMultiSkillSwitchCallBack(go)
                end,
                self._uiBattle
            )
            index = index + 1
        end
    end
    self._lastPreviewPetId = nil

    local gridTransform = self:GetUIComponent("RectTransform", "petpool")
    -- if petCount > 5 then
    --     gridTransform.localScale = Vector3(0.5,0.5,1)
    -- else
    --     gridTransform.localScale = Vector3(1,1,1)
    -- end
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(gridTransform)
    self._petHeadItemPosTab = {}
    for i = 1, #self.uiWidgetBattlePets do
        local pos = self.uiWidgetBattlePets[i]:GetGameObject():GetComponent("RectTransform").anchoredPosition
        self._petHeadItemPosTab[i] = pos
    end
    --local contentSize = self:GetUIComponent("ContentSizeFitter", "petpool")
    self.petPoolContentSizeFitter.enabled = false
    self.petPoolLayout.enabled = false

    ---长按光灵头像后，显示光灵的详情界面
    self:SpawnPetInfoUI()

    ---@type MatchPetInfo[]
    self._petList = {}
    self._petList = localPlayerInfo.pet_list


    self:RegisterEvent()

    self:SetColumnMode()
end
function UIWidgetPetArea:SetColumnMode()
    if self._useMultiColumn then
        self.switchBtnGo:SetActive(true)
        self:_InitSwitchTeamArea()
        self.multiColumnMaskGo:SetActive(true)
        self.petPoolTransform.parent = self.multiColumnMaskTransform

        local curPos = self.petPoolTransform.anchoredPosition
        local tarY = 10--遮一下技能就绪特效
        self.petPoolTransform.anchoredPosition = Vector2(curPos.x,tarY)
    else
        self.switchBtnGo:SetActive(false)
        self.multiColumnMaskGo:SetActive(false)
        self.petPoolTransform.parent = self.rootTransform
    end
end
function UIWidgetPetArea:SpawnPetInfoUI()
    ---@type UICustomWidgetPool 宝宝详细信息UI widget pool
    self._petInfoPool = self:GetUIComponent("UISelectObjectPath", "PetInfoPool")
    ---@type UIWidgetPetInfo 宝宝详细信息UI
    self._petInfoUI = self._petInfoPool:SpawnObject("UIWidgetPetInfo")
    self._petInfoUI:GetGameObject():SetActive(false)
end
function UIWidgetPetArea:ResetLayout(TT)
    if self.petPoolLayout then
        self.petPoolLayout.enabled = true
        --local contentSize = self:GetUIComponent("ContentSizeFitter", "petpool")
        self.petPoolContentSizeFitter.enabled = true
        YIELD(TT)
        self.petPoolContentSizeFitter.enabled = false
        self.petPoolLayout.enabled = false
    end
    -- self:StartTask(
    --     function(TT)
    --         if self.petPoolLayout then
    --             self.petPoolLayout.enabled = true
    --             --local contentSize = self:GetUIComponent("ContentSizeFitter", "petpool")
    --             self.petPoolContentSizeFitter.enabled = true
    --             YIELD(TT)
    --             self.petPoolContentSizeFitter.enabled = false
    --             self.petPoolLayout.enabled = false
    --         end
    --     end
    -- )
end
function UIWidgetPetArea:_UIChangeTeamLeader(newPetPstID, oldPetPstID, leftChangeCount, teamOrderBefore, teamOrderAfter)
    ---@type MatchPet
    local pet = self._matchPets[newPetPstID]
    local petName = StringTable.Get(pet:GetPetName())
    local strCount = tostring(leftChangeCount)
    if leftChangeCount == -1 then
        strCount = "∞"
    end
    local text = StringTable.Get("str_battle_change_teamleader_success", petName, strCount)
    ToastManager.ShowToast(text)
end
function UIWidgetPetArea:OnPetSwitchCallBack(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIPetClickToSwitch, go)
end
function UIWidgetPetArea:OnPetMultiSkillSwitchCallBack(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIPetClickToSwitch, go)
end
function UIWidgetPetArea:IsAutoFighting()
    return GameGlobal.GetUIModule(MatchModule):IsAutoFighting()
end
function UIWidgetPetArea:ShowAutoFightForbiddenMsg()
    return GameGlobal.GetUIModule(MatchModule):ShowAutoFightForbiddenMsg()
end

function UIWidgetPetArea:ShowChangeTeamLeaderData()
    if #self.uiWidgetBattlePets < 2 then
        return
    end
    self:CompleteChangeTeamLeaderAnim()
    local petDataList = {}
    --分页的情况下
    local beginIndex = 2
    local endIndex = 5
    if self._useMultiColumn then
        if self._curColumn == 1 then
            beginIndex = 2
            endIndex = self._petCountPerColumn
        else
            beginIndex = (self._curColumn - 1) * self._petCountPerColumn + 1
            endIndex = beginIndex + self._petCountPerColumn - 1
        end
    end
    local setUiIndex = 1
    for i = beginIndex, #self.uiWidgetBattlePets do
        if i <= endIndex then
            local pos = self.uiWidgetBattlePets[i]:GetGameObject():GetComponent("RectTransform").position
            ---@type UnityEngine.Camera
            local uiBattleCam = GameGlobal.UIStateManager():GetControllerCamera("UIBattle")
            local screenPos = uiBattleCam:WorldToScreenPoint(pos)
            local petPstID = self.uiWidgetBattlePets[i].petPstID
            local isDead = self.uiWidgetBattlePets[i].isDead
            local isHelpPet = self.uiWidgetBattlePets[i]._isHelpPet
            local isSealedCurse = self.uiWidgetBattlePets[i].isSealedCurse
            local petData = {
                screenPos = screenPos,
                petPstID = petPstID,
                index = setUiIndex,
                isDead = isDead,
                isHelpPet = isHelpPet,
                isSealedCurse = isSealedCurse
            }
            petDataList[setUiIndex] = petData
            setUiIndex = setUiIndex + 1
        end
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIBattleChangeTeamLeader",
        petDataList,
        function(petPstID)
            self:ChangeTeamLeader(petPstID)
        end,
        self._useMultiColumn,
        function()
            self:SwitchColumnOnClick()
        end
    )
end

function UIWidgetPetArea:ChangeTeamLeader(petPstID)
    local oldPetPstID = self.uiWidgetBattlePets[1].petPstID
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ChangeTeamLeader, petPstID, oldPetPstID)
end
function UIWidgetPetArea:UIBattleChangeHeadPos(idx_a, idx_b)
    local go_a = self.uiWidgetBattlePets[idx_a]
    local go_b = self.uiWidgetBattlePets[idx_b]

    local pos_a = self._petHeadItemPosTab[idx_a]
    local pos_b = self._petHeadItemPosTab[idx_b]

    ---@type UnityEngine.RectTransform
    local rtr_a = go_a.view:GetGameObject():GetComponent("RectTransform")
    ---@type UnityEngine.RectTransform
    local rtr_b = go_b.view:GetGameObject():GetComponent("RectTransform")
    ---@type UnityEngine.GameObject
    local gb_a = go_a.view:GetGameObject()
    ---@type UnityEngine.Transform
    local tr_a = gb_a.transform
    ---@type UnityEngine.GameObject
    local gb_b = go_b.view:GetGameObject()
    ---@type UnityEngine.Transform
    local tr_b = gb_b.transform
    if self._tweener_01 then
        self._tweener_01:Kill()
    end
    if self._tweener_02 then
        self._tweener_02:Kill()
    end

    self.uiWidgetBattlePets[idx_a] = go_b
    self.uiWidgetBattlePets[idx_b] = go_a

    local index = go_a.petIndex
    go_a.petIndex = go_b.petIndex
    go_b.petIndex = index
    go_a.sortIndex, go_b.sortIndex = go_b.sortIndex, go_a.sortIndex
    local sIndex = tr_a:GetSiblingIndex()
    tr_a:SetSiblingIndex(tr_b:GetSiblingIndex())
    tr_b:SetSiblingIndex(sIndex)
    self._tweener_01 = rtr_a:DOAnchorPos(pos_b, 0.5)
    self._tweener_02 = rtr_b:DOAnchorPos(pos_a, 0.5)

    self._tweener_02:OnComplete(
        function()
            self:_Callback_ChangeTeamOrderViewFinished()
        end
    )
end
function UIWidgetPetArea:CompleteChangeTeamLeaderAnim()
    if self._tweener_01 then
        if not self._tweener_01:IsComplete() then
            self._tweener_01:Complete()
        end
    end
    if self._tweener_02 then
        if not self._tweener_02:IsComplete() then
            self._tweener_02:Complete()
        end
    end
end
--表现移到了MainStateSystem:_DoRenderPetDead 走统一的表现队列
function UIWidgetPetArea:OnPetDeadChangeHeadPos(deadPetList)--似乎已废弃
    table.sort(
        self.uiWidgetBattlePets,
        function(a, b)
            local x = a.sortIndex
            if a:Dead() then
                x = x + 10
            end
            local y = b.sortIndex
            if b:Dead() then
                y = y + 10
            end
            return x < y
        end
    )

    for i = 1, #self.uiWidgetBattlePets do
        self.uiWidgetBattlePets[i]:FlushIndex(i)
    end

    for i = 1, #self.uiWidgetBattlePets do
        ---@type UnityEngine.RectTransform
        local tempTr = self.uiWidgetBattlePets[i].view:GetGameObject():GetComponent("RectTransform")
        if self.itemsTweenerTab[i] then
            self.itemsTweenerTab[i]:Kill()
        end
        ---@type DG.Tweening.Tween
        self.itemsTweenerTab[i] = tempTr:DOAnchorPos(self._petHeadItemPosTab[i], 0.5)
    end
end
--增加星灵的攻防血
function UIWidgetPetArea:_AddPetAtkDefHp(petId, addAtk, addDef, addHp)
    ---@type MatchPet
    local petData = self._petDatas[petId]
    if not petData then
        return
    end
    local atk = petData:GetPetAttack()
    local def = petData:GetPetDefence()
    local hp = petData:GetPetHealth()
    --刷新数据
    petData._maxhp = hp + addHp
    petData._defense = def + addDef
    petData._attack = atk + addAtk
    --刷新血条数据
    if self._petList then
        for _, v in pairs(self._petList) do
            if v.pet_pstid == petId then
                v.attack = v.attack + addAtk
                v.defense = v.defense + addDef
                v.max_hp = v.max_hp + addHp
            end
        end
    end
    return self._petList
end
function UIWidgetPetArea:GetUITeamLeaderPstID()
    return self.uiWidgetBattlePets[1]:GetPetPstID()
end
function UIWidgetPetArea:GetUITeamLeaderName()
    local pstid = self.uiWidgetBattlePets[1]:GetPetPstID()
    ---@type MatchPet
    local petData = self._petDatas[pstid]
    if petData then
        return petData:GetPetName()
    end
end
function UIWidgetPetArea:GetUITeamTailName()
    local tailIndex = #self.uiWidgetBattlePets
    local pstid = self.uiWidgetBattlePets[tailIndex]:GetPetPstID()
    ---@type MatchPet
    local petData = self._petDatas[pstid]
    if petData then
        return petData:GetPetName()
    end
end
function UIWidgetPetArea:SetTeamStateTeamLeader(petData)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UISetTeamStateTeamLeader,petData)
end

function UIWidgetPetArea:_UIChangeTeamOrder_ChangeTeamLeaderCommand(newPetPstID, oldPetPstID)
    -- self:CompleteChangeTeamLeaderAnim()

    for _, v in pairs(self._petList) do
        if v.pet_pstid == newPetPstID then
            self:SetTeamStateTeamLeader(v)
            break
        end
    end

    local oldPstIDArray = {}
    for _, widget in ipairs(self.uiWidgetBattlePets) do
        table.insert(oldPstIDArray, widget.petPstID)
    end

    local curLeaderPstID = self:GetUITeamLeaderPstID()
    if curLeaderPstID ~= oldPetPstID then
        Log.error("UIChangeTeamLeader current leader not match!!")
        return
    end
    local newIndex, oldIndex = 0, 0
    for k, v in pairs(self.uiWidgetBattlePets) do
        if v:IsMyPet(newPetPstID) then
            newIndex = k
        end
        if v:IsMyPet(oldPetPstID) then
            oldIndex = k
        end
    end
    if newIndex == 0 or oldIndex == 0 then
        return
    end
    Log.debug("UIChangeTeamLeader oldIndex=", oldIndex, " newIndex=", newIndex)
    self:UIBattleChangeHeadPos(newIndex, oldIndex)
end

function UIWidgetPetArea:_UIChangeTeamOrder_SwapTeamOrder(casterPetPstID, targetPetPstID)
    -- self:CompleteChangeTeamLeaderAnim()

    local oldPstIDArray = {}
    for _, widget in ipairs(self.uiWidgetBattlePets) do
        table.insert(oldPstIDArray, widget.petPstID)
    end
    --涉及换队长
    local oldLeaderPetPstID
    local newLeaderPetPstID

    local curLeaderPstID = self:GetUITeamLeaderPstID()
    if curLeaderPstID == casterPetPstID then
        oldLeaderPetPstID = casterPetPstID
        newLeaderPetPstID = targetPetPstID
    elseif curLeaderPstID == targetPetPstID then
        oldLeaderPetPstID = targetPetPstID
        newLeaderPetPstID = casterPetPstID
    end
    if oldLeaderPetPstID and newLeaderPetPstID then
        for _, v in pairs(self._petList) do
            if v.pet_pstid == newLeaderPetPstID then
                self:SetTeamStateTeamLeader(v)
                break
            end
        end
    end

    local targetIndex, casterIndex = 0, 0
    for k, v in pairs(self.uiWidgetBattlePets) do
        if v:IsMyPet(targetPetPstID) then
            targetIndex = k
        end
        if v:IsMyPet(casterPetPstID) then
            casterIndex = k
        end
    end
    if targetIndex == 0 or casterIndex == 0 then
        return
    end
    Log.debug("UISwapTeamOrder casterIndex=", casterIndex, " targetIndex=", targetIndex)
    self:UIBattleChangeHeadPos(targetIndex, casterIndex)

end

---@param req BattleTeamOrderViewRequest
function UIWidgetPetArea:OnCallUIChangeTeamOrderView(req)
    local type = req:GetViewType()
    local oldTeamOrder = req:GetOldTeamOrder()
    local newTeamOrder = req:GetNewTeamOrder()

    if type == BattleTeamOrderViewType.Exchange_ChangeTeamLeader then
        local oldPetPstID = oldTeamOrder[1]
        local newPetPstID = newTeamOrder[1]
        self:_UIChangeTeamOrder_ChangeTeamLeaderCommand(newPetPstID, oldPetPstID)
    elseif type == BattleTeamOrderViewType.Exchange_SwapTeamOrder then
        local pstIdA, pstIdB = req:CalSwapPstID()
        if pstIdA and pstIdB then
            self:_UIChangeTeamOrder_SwapTeamOrder(pstIdA, pstIdB)
        end
    elseif type == BattleTeamOrderViewType.FillVacancies_Skill then
        self:_UIChangeTeamOrder_SkillChangeTeamOrder(oldTeamOrder, newTeamOrder)
    elseif type == BattleTeamOrderViewType.FillVacancies_MazePetDead then
        self:_UIChangeTeamOrder_MazePetDead(oldTeamOrder, newTeamOrder)
    elseif type == BattleTeamOrderViewType.ShuffleTeamOrder then
        self:_UIChangeTeamOrder_ShuffleTeamOrder(oldTeamOrder, newTeamOrder)
    end
end
---BattleTeamOrderViewRequest执行结束的回调
---
---调用该函数表示UI当前拿到的换序表现已经处理完毕，可以执行下一个表现请求
---如果表现用到了DOTween，可以用tweener的OnComplete回调来执行它
---
---所有换序表现最后都必须执行它，否则整个队列会卡住
function UIWidgetPetArea:_Callback_ChangeTeamOrderViewFinished()
    InnerGameHelperRender.UICurrentTeamOrderRequestFinished()
end

function UIWidgetPetArea:_UIChangeTeamOrder_SkillChangeTeamOrder(oldTeamOrder, newTeamOrder)
    local uiTeamOrderReverse = {}
    for index, widget in ipairs(self.uiWidgetBattlePets) do
        uiTeamOrderReverse[widget:GetPetPstID()] = index
    end
    local newTeamOrderReverse = {}
    for index, pstID in ipairs(newTeamOrder) do
        newTeamOrderReverse[pstID] = index
    end

    if oldTeamOrder[1] ~= newTeamOrder[1] then
        for _, v in pairs(self._petList) do
            if v.pet_pstid == newTeamOrder[1] then
                self:SetTeamStateTeamLeader(v)
                break
            end
        end
    end

    ---@type DG.Tweening.Tweener[]
    local tweeners = {}
    -- 先发起dotween
    for _, pstID in ipairs(newTeamOrder) do
        local oldIndex = uiTeamOrderReverse[pstID]
        local newIndex = newTeamOrderReverse[pstID]
        if oldIndex ~= newIndex then
            local newPos = self._petHeadItemPosTab[newIndex]
            local csrt = self.uiWidgetBattlePets[oldIndex].view:GetGameObject():GetComponent("RectTransform")
            local tweener = csrt:DOAnchorPos(newPos, BattleConst.UIChangeTeamOrderTweenerTime)
            if tweener then
                table.insert(tweeners, tweener)
            end
        end
    end

    local recordUiWidgets = {}
    local recordUiWidgetsSibling = {}
    for _, widget in ipairs(self.uiWidgetBattlePets) do
        table.insert(recordUiWidgets, widget)
        table.insert(recordUiWidgetsSibling, widget.view:GetGameObject():GetComponent("RectTransform"):GetSiblingIndex())
    end

    for _, pstID in ipairs(newTeamOrder) do
        local newIndex = newTeamOrderReverse[pstID]
        local oldIndex = uiTeamOrderReverse[pstID]
        local oldIndexWidget = recordUiWidgets[oldIndex]
        self.uiWidgetBattlePets[newIndex] = oldIndexWidget

        -- widget对象内部索引更新
        oldIndexWidget:FlushIndex(newIndex)
        self.uiWidgetBattlePets[newIndex].view:GetGameObject():GetComponent("RectTransform"):SetSiblingIndex(
            recordUiWidgetsSibling[newIndex]
        )
    end

    -- 更换self.uiWidgetBattlePets的顺序——两个过程合并的话，循环体内要反复遍历self.uiWidgetBattlePets，根据pstID确定光灵对应的UI
    -- for _, pstID in ipairs(newTeamOrder) do
    --     local oldIndex = uiTeamOrderReverse[pstID]
    --     local newIndex = newTeamOrderReverse[pstID]
    --     if oldIndex ~= newIndex then
    --         -- 交换self.uiWidgetBattlePets的顺序
    --         local oldIndexWidget = self.uiWidgetBattlePets[oldIndex]
    --         local newIndexWidget = self.uiWidgetBattlePets[newIndex]
    --         self.uiWidgetBattlePets[oldIndex] = newIndexWidget
    --         self.uiWidgetBattlePets[newIndex] = oldIndexWidget

    --         -- widget对象内部索引更新
    --         oldIndexWidget:FlushIndex(newIndex)
    --         newIndexWidget:FlushIndex(oldIndex)

    --         -- 交换rectTransform的sibling index，这个index与UGUI的逻辑有关
    --         local oldIndexWidgetSiblingIndex =
    --             oldIndexWidget.view:GetGameObject():GetComponent("RectTransform"):GetSiblingIndex()
    --         local newIndexWidgetSiblingIndex =
    --             newIndexWidget.view:GetGameObject():GetComponent("RectTransform"):GetSiblingIndex()
    --         oldIndexWidget.view:GetGameObject():GetComponent("RectTransform"):SetSiblingIndex(
    --             newIndexWidgetSiblingIndex
    --         )
    --         newIndexWidget.view:GetGameObject():GetComponent("RectTransform"):SetSiblingIndex(
    --             oldIndexWidgetSiblingIndex
    --         )
    --     end
    -- end

    if #tweeners > 0 then
        tweeners[#tweeners]:OnComplete(
            function()
                self:_Callback_ChangeTeamOrderViewFinished()
            end
        )
    else
        -- 如果没有任何tweener，通常情况是没有顺序变化，这样直接算当前表现结束
        self:_Callback_ChangeTeamOrderViewFinished()
    end
end

function UIWidgetPetArea:_UIChangeTeamOrder_MazePetDead(oldTeamOrder, newTeamOrder)
    self:_UIChangeTeamOrder_SkillChangeTeamOrder(oldTeamOrder, newTeamOrder)
end

function UIWidgetPetArea:_UIChangeTeamOrder_ShuffleTeamOrder(oldTeamOrder, newTeamOrder)
    local uiTeamOrderReverse = {}
    for index, widget in ipairs(self.uiWidgetBattlePets) do
        uiTeamOrderReverse[widget:GetPetPstID()] = index
    end
    local newTeamOrderReverse = {}
    for order, pstId in ipairs(newTeamOrder) do
        newTeamOrderReverse[pstId] = order
    end

    local widgetPetsClone = {}
    for index, widget in ipairs(self.uiWidgetBattlePets) do
        widgetPetsClone[index] = widget
    end
    local indexForSiblingIndex = {}
    for index, widget in ipairs(self.uiWidgetBattlePets) do
        indexForSiblingIndex[index] = widget.view:GetGameObject():GetComponent("RectTransform"):GetSiblingIndex()
    end

    if oldTeamOrder[1] ~= newTeamOrder[1] then
        for _, v in pairs(self._petList) do
            if v.pet_pstid == newTeamOrder[1] then
                self:SetTeamStateTeamLeader(v)
                break
            end
        end
    end

    -- 这个for循环内部的逻辑删减过，原因是这个循环是覆盖了所有宝宝的，不需要像之前的逻辑那样反复交换
    for _, pstID in ipairs(newTeamOrder) do
        local oldIndex = uiTeamOrderReverse[pstID]
        local newIndex = newTeamOrderReverse[pstID]

        local widget = widgetPetsClone[oldIndex] -- widgetPetsClone是按旧顺序clone的
        self.uiWidgetBattlePets[newIndex] = widget

        -- widget对象内部索引更新
        widget:FlushIndex(newIndex)

        -- 交换rectTransform的sibling index，这个index与UGUI的逻辑有关
        widget.view:GetGameObject():GetComponent("RectTransform"):SetSiblingIndex(indexForSiblingIndex[newIndex])
    end

    -- 第一阶段 所有头像去队长位置集合
    local t = {}
    local sequence = DG.Tweening.DOTween.Sequence()
    for _index, widget in ipairs(self.uiWidgetBattlePets) do
        -- sequence:Insert(1, widget.view:GetGameObject():GetComponent("RectTransform"):DOAnchorPos(self._petHeadItemPosTab[1], BattleConst.UIShuffleTeamOrderPhase1Time):SetEase(DG.Tweening.Ease.OutQuad))
        table.insert(
            t,
            widget.view:GetGameObject():GetComponent("RectTransform"):DOAnchorPos(
                self._petHeadItemPosTab[1],
                BattleConst.UIShuffleTeamOrderPhase1Time
            )
        )
    end

    DG.Tweening.DOVirtual.DelayedCall(
        BattleConst.UIShuffleTeamOrderPhase1Time + BattleConst.UIShuffleTeamOrderPhase1Pause,
        function()
            self:_UIChangeTeamOrder_ShuffleTeamOrderPhase2(oldTeamOrder, newTeamOrder)
        end
    )
end

function UIWidgetPetArea:_UIChangeTeamOrder_ShuffleTeamOrderPhase2(oldTeamOrder, newTeamOrder)
    local t = {}
    local sequence = DG.Tweening.DOTween.Sequence()
    for index, widget in ipairs(self.uiWidgetBattlePets) do
        table.insert(
            t,
            widget.view:GetGameObject():GetComponent("RectTransform"):DOAnchorPos(
                self._petHeadItemPosTab[index],
                BattleConst.UIShuffleTeamOrderPhase2Time
            )
        )
        -- sequence:Insert(1, widget.view:GetGameObject():GetComponent("RectTransform"):DOAnchorPos(self._petHeadItemPosTab[index], BattleConst.UIShuffleTeamOrderPhase2Time):SetEase(DG.Tweening.Ease.OutQuad))
    end

    t[#t]:OnComplete(
        function()
            self:_Callback_ChangeTeamOrderViewFinished()
        end
    )
end
function UIWidgetPetArea:OnPetHpChangedInMaze(mazePetInfo)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(mazePetInfo.pet_pstid) then
            self.uiWidgetBattlePets[i]:FlushPetHp(mazePetInfo)
        end
    end
end
function UIWidgetPetArea:CancelActiveSkillSwitchTimer()
    for i = 1, #self.uiWidgetBattlePets do
        self.uiWidgetBattlePets[i]:CancelSwitchTimer()
    end
end
---@param petPstID number
---@param power number
function UIWidgetPetArea:OnPetPowerChange(petPstID, power, effect, logicReady)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnChangePower(power, effect, logicReady)
            break
        end
    end
end
---@param petPstID number
---@param power number
function UIWidgetPetArea:OnPetPowerChangeForExtra(petPstID,extraSkillID, power, effect, logicReady)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnChangePowerForExtraSkill(extraSkillID,power, effect, logicReady)
            break
        end
    end
end

---@param petPstID number
---@param power number
function UIWidgetPetArea:OnPetLegendPowerChange(petPstID, power, effect, logicReady, maxValue)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnChangeLegendPower(power, effect, logicReady, maxValue)
            break
        end
    end
end

---@param petPstID number
function UIWidgetPetArea:OnPetActiveSkillGetReady(petPstID, playReminder, previousReady)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnPowerReady(playReminder, previousReady)
            break
        end
    end
end

---@param petPstID number
function UIWidgetPetArea:OnPetActiveSkillCancelReady(petPstID, addCdAnimation)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnPowerCancelReady(addCdAnimation)
            break
        end
    end
end
---@param petPstID number
function UIWidgetPetArea:OnPetExtraActiveSkillGetReady(petPstID,skillId, playReminder, previousReady)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnPowerReadyForExtraSkill(skillId,playReminder, previousReady)
            break
        end
    end
end

---@param petPstID number
function UIWidgetPetArea:OnPetExtraActiveSkillCancelReady(petPstID, skillId,addCdAnimation)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnPowerCancelReadyForExtraSkill(skillId,addCdAnimation)
            break
        end
    end
end
---@param petPstID number
function UIWidgetPetArea:ShowHideUiMultiPowerInfoByIndex(petPstID, uiIndex,bShow)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:ShowHideUiMultiPowerInfoByIndex(uiIndex,bShow)
            break
        end
    end
end
function UIWidgetPetArea:OnShowPetInfoInish()
    for i = 1, #self.uiWidgetBattlePets do
        self.uiWidgetBattlePets[i]:OnShowPetInfoInish()
    end
end

function UIWidgetPetArea:OnPetHeadMaskAlpha(alpha)
    for i = 1, #self.uiWidgetBattlePets do
        self.uiWidgetBattlePets[i]:OnChangeHeadAlpha(alpha)
    end
end
function UIWidgetPetArea:OnExclusivePetHeadMaskAlpha(alpha, exclusivePetPstID)
    for i = 1, #self.uiWidgetBattlePets do
        if not self.uiWidgetBattlePets[i]:IsMyPet(exclusivePetPstID) then
            self.uiWidgetBattlePets[i]:OnChangeHeadAlpha(alpha)
        else
            self.uiWidgetBattlePets[i]:OnChangeHeadAlpha(0)
        end
    end
end

function UIWidgetPetArea:OnPetPowerAndWatchChange(petPstID, power, isReady, watch)
    for i = 1, #self.uiWidgetBattlePets do
        if self.uiWidgetBattlePets[i]:IsMyPet(petPstID) then
            self.uiWidgetBattlePets[i]:OnChangePowerAndWatch(power, isReady, watch)
            break
        end
    end
end

function UIWidgetPetArea:OnPetClickCallBack(index, skillId, maxPower, leftPower, canCast, go)
    local petWidget = self.uiWidgetBattlePets[index]

    if GuideHelper.DontShowMainSkillMission() then
        return
    end

    GameGlobal.UAReportForceGuideEvent(
        "FightClick",
        {
            "OnPetClickCallBack",
            petWidget._petTemplateID
        },
        false,
        true
    )

    if self:IsAutoFighting() and go then
        self:ShowAutoFightForbiddenMsg()
    else
        if self._guideWidgetPetIndex > 0 and self._guideWidgetPetIndex == petWidget.petIndex then
            GameGlobal.EventDispatcher():Dispatch(GameEventType.PreClickPetHead, skillId)
            ---@type UIWidgetBattlePet
            GameGlobal.EventDispatcher():Dispatch(GameEventType.HideCanMoveArrow)
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickPetHead, petWidget.petPstID, petWidget.isReady)
        end
        self:ShowActiveSkillUI(petWidget, skillId, maxPower, leftPower, canCast)
        self:_CheckGuide()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
    end
end
function UIWidgetPetArea:OnPetMultiSkillClickCallBack(index, uiDataArray, go, isVariantSkillList, lastClickIndex)
    local petWidget = self.uiWidgetBattlePets[index]

    if GuideHelper.DontShowMainSkillMission() then
        return
    end

    -- GameGlobal.UAReportForceGuideEvent(
    --     "FightClick",
    --     {
    --         "OnPetClickCallBack",
    --         petWidget._petTemplateID
    --     },
    --     false,
    --     true
    -- )

    if self:IsAutoFighting() and go then
        self:ShowAutoFightForbiddenMsg()
    else
        self:ShowMultiActiveSkillUI(index,petWidget, uiDataArray,isVariantSkillList, lastClickIndex)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ClickUI2ClosePreviewMonster)
    end
end
function UIWidgetPetArea:ShowActiveSkillUI(petWidget, skillId, maxPower, leftPower, canCast)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowActiveSkillUI, petWidget,skillId,maxPower,leftPower,canCast)
end
---@param uiDataArray UIDataActiveSkillUIInfo[]
function UIWidgetPetArea:ShowMultiActiveSkillUI(index,petWidget, uiDataArray,isVariantSkillList, lastClickIndex)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.UIShowMultiActiveSkillUI, index,petWidget,uiDataArray,isVariantSkillList, lastClickIndex)
end
function UIWidgetPetArea:GetPetWidgetByPstID(petPstID)
    return self._petWidgets[petPstID]
end
--region 引导
function UIWidgetPetArea:GetPetBattleBtnHp(_index)
    if self.uiWidgetBattlePets then
        ---@type UIWidgetBattlePet
        for index, value in ipairs(self.uiWidgetBattlePets) do
            if index == _index then
                return value:GetGameObject("hpvalue")
            end
        end
    end
end
function UIWidgetPetArea:GetPetBattleBtnByPetTempId(petTempId)
    if self.uiWidgetBattlePets then
        ---@type UIWidgetBattlePet
        for key, value in pairs(self.uiWidgetBattlePets) do
            if value._petTemplateID == petTempId then
                return value:GetGameObject("TouchArea")
            end
        end
    end
end
--endregion
--小秘境（多列头像），点头像前先切换列（如果需要）
function UIWidgetPetArea:AutoFightCheckSwitchPetColumn(petID)
    if self._useMultiColumn then
        local petCount = #self._petList
        if petCount <= self._petCountPerColumn then 
            return
        end
        if petID then
            local curIndex = 0
            for i = 1, #self.uiWidgetBattlePets do
                if self.uiWidgetBattlePets[i]:IsMyPet(petID) then
                    curIndex = i
                    break
                end
            end
            local belongColumn = math.floor((curIndex-1) / self._petCountPerColumn) + 1
            if belongColumn ~= self._curColumn then
                self:_SwitchColumn()
            end
        end
    end
end
----------------------
--测试 中途加光灵
function UIWidgetPetArea:AddMiddleEnterPet(petInfo,matchPet)
    --local contentSize = self:GetUIComponent("ContentSizeFitter", "petpool")
    self.petPoolContentSizeFitter.enabled = true
    self.petPoolLayout.enabled = true

    ---@type LuaMatchPlayerInfo
    local localPlayerInfo = petInfo
    local petPstID = matchPet:GetPstID()
    self._matchPets[petPstID] = matchPet
    
    local petCount = #self._petList
    petCount = petCount + 1
    table.insert(self._petList,petInfo)

    self.petPoolLayout.constraintCount = petCount
    self.petPool:SpawnObjects("UIWidgetBattlePet", petCount)
    ---@type table<int, UIWidgetBattlePet> 宝宝UIWidget列表
    local uiWidgetBattlePets = self.petPool:GetAllSpawnList()
    local addWidget = uiWidgetBattlePets[#uiWidgetBattlePets]
    self.uiWidgetBattlePets[petCount] = addWidget
    self._petWidgets[petPstID] = addWidget
    self._petDatas[petPstID] = matchPet
    local petIndex = petCount
    matchPet.uiid = petIndex
    addWidget:InitUIWidgetPet(
        petIndex,
        petPstID,
        matchPet,
        function(index, skillId, maxPower, leftPower, canCast, go)
            self:OnPetClickCallBack(index, skillId, maxPower, leftPower, canCast, go)
        end,
        function(go)
            self:OnPetSwitchCallBack(go)
        end,
        function(index, uiDataArray, go, isVariantSkillList, lastClickIndex)
            self:OnPetMultiSkillClickCallBack(index,uiDataArray, go, isVariantSkillList, lastClickIndex)
        end,
        function(go)
            self:OnPetMultiSkillSwitchCallBack(go)
        end,
        self._uiBattle
    )
    --自动战斗时添加 需要处理一下状态
    addWidget:_AutoFight(self:IsAutoFighting())
    addWidget:_ActiveBattlePet()

    local gridTransform = self:GetUIComponent("RectTransform", "petpool")
    -- if petCount > 5 then
    --     gridTransform.localScale = Vector3(0.5,0.5,1)
    -- else
    --     gridTransform.localScale = Vector3(1,1,1)
    -- end
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(gridTransform)
    self._petHeadItemPosTab = {}
    for i = 1, #self.uiWidgetBattlePets do
        local pos = self.uiWidgetBattlePets[i]:GetGameObject():GetComponent("RectTransform").anchoredPosition
        self._petHeadItemPosTab[i] = pos
    end

    --local contentSize = self:GetUIComponent("ContentSizeFitter", "petpool")
    self.petPoolContentSizeFitter.enabled = false
    self.petPoolLayout.enabled = false
end

function UIWidgetPetArea:_CheckGuide()
    ---@type GuideModule
    local guideModule = GameGlobal.GetModule(GuideModule)
    if guideModule:GuideInProgress() then
        ---@type table<number, Guide>
        local guides = guideModule:GetCurGuides()
        if guides then
            for _, guide in pairs(guides) do
                ---@type GuideStep
                local curStep = guide:GetCurStep()
                if curStep and curStep.show then
                    local cfg = curStep:GetBtnGuideCfg()
                    if cfg and cfg.completeRule == GuideCompleteType.OperationComplete then
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.FinishGuideStep, GuideType.Button)
                        return
                    end
                end
            end
        end
    end
end    