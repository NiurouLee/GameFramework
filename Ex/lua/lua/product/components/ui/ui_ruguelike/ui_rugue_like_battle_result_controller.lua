_class("UIRugueLikeBattleResultController", UIController)
---@class UIRugueLikeBattleResultController:UIController
UIRugueLikeBattleResultController = UIRugueLikeBattleResultController

function UIRugueLikeBattleResultController:OnShow(uiParams)
    ---@type UILocalizationText
    self._dialogLeftGO = self:GetGameObject("DialogLeft")
    self._dialogRightGO = self:GetGameObject("DialogRight")

    self._dialogLeftTxt = self:GetUIComponent("UILocalizationText", "DialogTextLeft")
    self._dialogRightTxt = self:GetUIComponent("UILocalizationText", "DialogTextRight")

    self._completeen = self:GetGameObject("completeen")
    local eng = HelperProxy:GetInstance():IsInEnglish()
    self._completeen:SetActive(not eng)

    self._isWin = uiParams[1] or false

    ---@type MatchEnterData
    local matchEnterData = self:GetModule(MatchModule):GetMatchEnterData()
    ---@type JoinedPlayerInfo
    local localPlayerInfo = matchEnterData:GetLocalPlayerInfo()
    local petID = localPlayerInfo.pet_list[1].pet_pstid
    ---@type PetModule
    local petModule = self:GetModule(PetModule)

    self._petData = petModule:GetPet(petID)

    --拿到对局结束得mazeresult
    local gameMatchModule = self:GetModule(GameMatchModule)
    ---@type MazeResult
    local matchResult = UI_MatchResult:New()

    matchResult = gameMatchModule:GetMachResult()

    --奖励信息
    self._itemTab = matchResult.rewards

    ---@type UISelectObjectPath
    self._selectItemInfoPool = self:GetUIComponent("UISelectObjectPath", "ItemInfoPool")
    ---@type UISelectInfo
    self._selectItemInfo = self._selectItemInfoPool:SpawnObject("UISelectInfo")

    self:AttachEvent(GameEventType.ShowItemTips, self.ShowItemTips)

    self:InitAwards()

    self:PlayAudio()

    self:TalkMsg()

    self:StaticBody()

    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)
end

function UIRugueLikeBattleResultController:OnHide()
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowItemTips)
end

--奖励物品
function UIRugueLikeBattleResultController:InitAwards()
    ---金币 道具奖励
    ---@type UICustomWidgetPool
    self._itemPool = self:GetUIComponent("UISelectObjectPath", "Items")

    local itemTabCount = table.count(self._itemTab)

    Log.debug("[error] mazeResult --> itemTabCount is " .. itemTabCount .. " !")

    self._itemPool:SpawnObjects("UIWidgetResultReward", itemTabCount)
    ---@type table<int, UIWidgetResultReward>
    local items = self._itemPool:GetAllSpawnList()

    local itemCfg = Cfg.cfg_item

    --奖励
    for i = 1, itemTabCount do
        local roleAsset = self._itemTab[i]
        Log.debug("[error] mazeResult --> index is " .. i .. " roleAsset.assetid is " .. roleAsset.assetid .. " !")

        items[i]:Init(roleAsset.count, roleAsset.assetid, false)
        --items[i]:Init(roleAsset.count, 3100001,true)
    end
end

--左右气泡
function UIRugueLikeBattleResultController:TalkMsg()
    ---临时数据
    local cfg = nil
    local phraseId = self._petData:GetSkinId()
    cfg = Cfg.pet_phrase[phraseId]
    if not cfg then
        ---@type Pet
        phraseId = self._petData:GetTemplateID()
        cfg = Cfg.pet_phrase[phraseId]
    end
    if cfg == nil then
        Log.fatal("### cfg_pet_phrase is nil ! id --> ", phraseId)
    end
    if cfg.Dir == nil then
        Log.fatal("### cfg_pet_phrase Dir is nil ! id --> ", phraseId)
    end
    local left = cfg.Dir == 0
    local useDialogTxt = left and self._dialogLeftTxt or self._dialogRightTxt
    if cfg.Pos == nil then
        Log.fatal("### cfg_pet_phrase Pos is nil ! id --> ", phraseId)
    end
    local pos = cfg.Pos
    local posTbl = table.tonumber(string.split(pos, "|"))
    if left then
        self._dialogLeftGO.transform.localPosition = Vector2(posTbl[1], posTbl[2])
    else
        self._dialogRightGO.transform.localPosition = Vector2(posTbl[1], posTbl[2])
    end
    self._dialogLeftGO:SetActive(left)
    self._dialogRightGO:SetActive(not left)

    local str = self._isWin and cfg.CompletePhrase or cfg.FailPhrase
    useDialogTxt:SetText(HelperProxy:GetInstance():ReplacePlayerName(StringTable.Get(str)))

    ---@type UnityEngine.UI.ContentSizeFitter
    local csf = useDialogTxt.transform.parent:GetComponent("ContentSizeFitter")
    local rect = useDialogTxt.rectTransform.parent:GetComponent("RectTransform")
    local textWidth = 570
    if useDialogTxt.preferredWidth >= textWidth then
        csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained
        rect.sizeDelta = Vector2(textWidth, rect.sizeDelta.y)
    else
        csf.horizontalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize
    end
end

--背景立绘
function UIRugueLikeBattleResultController:StaticBody()
    --self._goCG = self:GetGameObject("imgRole").transform.parent
    self._goCG = self:GetGameObject("imgRole").transform
    ---@type MultiplyImageLoader
    self._imgRole = self:GetUIComponent("MultiplyImageLoader", "imgRole")

    ----全身静态立绘
    local cg = self._petData:GetPetBattleResultCG(PetSkinEffectPath.BODY_BATTLE_RESULT)
    if not cg then
        cg = self._petData:GetPetStaticBody(PetSkinEffectPath.BODY_BATTLE_RESULT)
    end
    self._imgRole:Load(cg, "white")
    --暂时使用通用结算界面的配置
    UICG.SetTransform(self._goCG, "UIBattleResultComplete", cg)
end

--播放语音
function UIRugueLikeBattleResultController:PlayAudio()
    local tplID = self._petData:GetTemplateID()
    local pm = GameGlobal.GetModule(PetAudioModule)
    pm:PlayPetAudio("BattleSucceed", tplID)
end

--切换到主界面
function UIRugueLikeBattleResultController:bgOnClick()
    --退出返回地图
    GameGlobal:GetInstance():ExitCoreGame()
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Maze_Enter, "mj_01")
end

function UIRugueLikeBattleResultController:ShowItemTips(itemID, pos)
    self._selectItemInfo:SetData(itemID, pos)
end
