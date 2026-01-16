---@class UIHomelandAquarium:UIController
_class("UIHomelandAquarium", UIController)
UIHomelandAquarium = UIHomelandAquarium

function UIHomelandAquarium:LoadDataOnEnter(TT, res, uiParams)
    ---@type UIBuildRaiseFishDatas
    self._raiseFishDatas = UIBuildRaiseFishDatas:New()
end

function UIHomelandAquarium:OnShow(uiParams)
    ---@type HomeBuilding
    local building = uiParams[1]

    local buildID = building:GetBuildId()
    self._buildPstID = building:GetBuildPstId()

    --水族箱鱼的最大数量
    self._maxFishCount = Cfg.cfg_item_aquarium_area[buildID].MaxFishCount

    -------------------

    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, false)
    self._fishLoader = self:GetUIComponent("UISelectObjectPath", "FishList")
    self._raiseFishLoader = self:GetUIComponent("UISelectObjectPath", "RaiseFishList")
    self._fishCountLabel = self:GetUIComponent("UILocalizationText", "FishCount")
    self._btnOpenFish = self:GetGameObject("BtnOpenFish")
    self._btnCloseFish = self:GetGameObject("BtnCloseFish")
    self._bottomTran = self:GetUIComponent("RectTransform", "Bottom")
    self._btnOpenFish:SetActive(true)
    self._btnCloseFish:SetActive(false)
    self:RefreshUI()
    self._isChange = false

    GameGlobal.EventDispatcher():Dispatch(GameEventType.EnterFindTreasure)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandMainUI, false, true)
end

function UIHomelandAquarium:OnHide()
    ---@type UIHomelandModule
    local homeLandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type HomelandClient
    local homelandClient = homeLandModule:GetClient()

    --被顶号或者被踢下线
    if not homelandClient then
        return
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowHideHomelandMainUI, true, true)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshInteractUI)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetInteractPointUIStatus, true)
    if self._isChange then
        HomelandWishingConst.ForceUpdateAquariumFishData()
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AquariumRefreshFish, self._buildPstID)
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ExitFindTreasure)

    local cameraMgr = homelandClient:CameraManager()
    ---@type HomelandFollowCameraController
    local followCameraController = cameraMgr:FollowCameraController()
    followCameraController:LeaveFocusUseAngles()

    ---@type HomelandMainCharacterController
    local characterController = homelandClient:CharacterManager():MainCharacterController()
    characterController:SetForbiddenMove(false)
end

function UIHomelandAquarium:RefreshUI()
    --背包里有的（总的减去许愿池和其他水族箱）
    local remainFishs = self._raiseFishDatas:GetRemainFish()
    local count = #remainFishs
    self._fishLoader:SpawnObjects("UIBuildRaiseFishItem", count)
    ---@type UIBuildRaiseFishItem[]
    local items = self._fishLoader:GetAllSpawnList()
    for i = 1, count do
        items[i]:Refresh(self, remainFishs[i])
    end

    --当前水族箱饲养的
    local aquariumFishs = self._raiseFishDatas:GetCurAquariumFish(self._buildPstID)
    self._raiseFishLoader:SpawnObjects("UIBuildRaiseFishWishFishItem", self._maxFishCount)
    ---@type UIBuildRaiseFishWishFishItem[]
    local items = self._raiseFishLoader:GetAllSpawnList()
    for i = 1, self._maxFishCount do
        if i <= table.count(aquariumFishs) then
            items[i]:Refresh(self, aquariumFishs[i])
        else
            items[i]:ShowBackGround(true)
        end
    end

    --当前饲养/饲养上限
    self._fishCountLabel:SetText(
        StringTable.Get(
            "str_homeland_raise_fish_count_tips",
            self._raiseFishDatas:GetCurAquariumFishCount(self._buildPstID),
            self._maxFishCount
        )
    )
end

---@param raiseFishData UIHomelandAquariumData
function UIHomelandAquarium:RaiseFish(raiseFishData)
    if self._raiseFishDatas:GetCurAquariumFishCount(self._buildPstID) >= self._maxFishCount then
        return
    end
    local fishData = self._raiseFishDatas:AddAquariumFish(self._buildPstID, raiseFishData)
    self:RefreshUI()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.AquariumAddFish,
        self._buildPstID,
        fishData:GetId(),
        fishData:GetInstanceId()
    )
    self._isChange = true
end

---@param raiseFishData UIHomelandAquariumData
function UIHomelandAquarium:UnRaiseFish(raiseFishData)
    self._raiseFishDatas:RemoeAquariumFish(self._buildPstID, raiseFishData)
    self:RefreshUI()
    GameGlobal.EventDispatcher():Dispatch(
        GameEventType.AquariumRemoveFish,
        self._buildPstID,
        raiseFishData:GetInstanceId()
    )
    self._isChange = true
end

function UIHomelandAquarium:BtnCloseOnClick(go)
    self:CloseDialog()
end

function UIHomelandAquarium:BtnRaiseOnClick(go)
    GameGlobal.TaskManager():StartTask(self.UpdateWishingFish, self)
end

function UIHomelandAquarium:UpdateWishingFish(TT)
    self:Lock("UIHomelandAquarium_UpdateWishingFish")
    ---@type HomelandModule
    local homelandModlue = GameGlobal.GetModule(HomelandModule)
    local fishTable = {}
    local raiseFishs = self._raiseFishDatas:GetCurAquariumFish(self._buildPstID)
    for i = 1, #raiseFishs do
        ---@type UIHomelandAquariumData
        local raiseData = raiseFishs[i]
        local id = raiseData:GetId()
        if not fishTable[id] then
            fishTable[id] = 1
        else
            fishTable[id] = fishTable[id] + 1
        end
    end
    ---@type AsyncRequestRes
    local ret = homelandModlue:ApplyUpdateFishTankAllFish(TT, self._buildPstID, fishTable)
    if ret:GetSucc() then
        if table.count(fishTable) <= 0 then
            ToastManager.ShowHomeToast(StringTable.Get("str_homeland_raise_fish_empty"))
        else
            ToastManager.ShowHomeToast(StringTable.Get("str_homeland_raise_success"))
        end
        self._isChange = true
    else
        Log.error("养鱼错误  errorCode = " .. ret:GetResult())
    end
    self:UnLock("UIHomelandAquarium_UpdateWishingFish")
end

function UIHomelandAquarium:BtnCloseFishOnClick()
    self:SetPanelStatus(true)
end

function UIHomelandAquarium:BtnOpenFishOnClick()
    self:SetPanelStatus(false)
end

function UIHomelandAquarium:SetPanelStatus(status)
    self._btnCloseFish:SetActive(not status)
    self._btnOpenFish:SetActive(status)
    if status then
        local pos = Vector2(0, 0)
        self._bottomTran.anchoredPosition = pos
    else
        local pos = Vector2(0, -292)
        self._bottomTran.anchoredPosition = pos
    end
end
