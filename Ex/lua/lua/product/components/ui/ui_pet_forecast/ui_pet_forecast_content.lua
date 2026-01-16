require("ui_side_enter_center_content_base")

---@class UIPetForecastContent : UISideEnterCenterContentBase
_class("UIPetForecastContent", UISideEnterCenterContentBase)
UIPetForecastContent = UIPetForecastContent

function UIPetForecastContent:DoInit(params)
end

function UIPetForecastContent:DoShow()
    ---@type UIPetForecastDataLoader
    self._dataLoader = UIPetForecastDataLoader:New()
    -- self.data = self.mSignIn:GetPredictionData()
    self.data = self._data  -- UISideEnterCenterContentBase:OnInit() 中传入

    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIPetForecast.spriteatlas", LoadType.SpriteAtlas)
    ---@type RawImageLoader
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    ---@type UICustomWidgetPool
    self.pieces = self:GetUIComponent("UISelectObjectPath", "pieces")
    ---@type UICustomWidgetPool
    self.info = self:GetUIComponent("UISelectObjectPath", "info")
    self.goInfo = self:GetGameObject("info")
    ---@type UnityEngine.RectTransform
    self.b = self:GetUIComponent("RectTransform", "b")
    ---@type UnityEngine.UI.Image
    self.bgTitle = self:GetUIComponent("Image", "bgTitle")
    self.title = self:GetGameObject("title")
    self.titleEn = self:GetGameObject("titleEn")
    ---@type UnityEngine.UI.ScrollRect
    self.sv = self:GetUIComponent("ScrollRect", "sv")
    ---@type UnityEngine.UI.Image
    self.imgLeftTime = self:GetUIComponent("Image", "imgLeftTime")
    ---@type UnityEngine.UI.Image
    self.imgClock = self:GetUIComponent("Image", "imgClock")
    ---@type UILocalizationText
    self.txtLeftTimeHint = self:GetUIComponent("UILocalizationText", "txtLeftTimeHint")
    ---@type UILocalizationText
    self.txtLeftTime = self:GetUIComponent("UILocalizationText", "txtLeftTime")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")

    ---@type UICustomWidgetPool
    self.view1 = self:GetUIComponent("UISelectObjectPath", "view1")

    -- Share Btn
    self:_ShareBtn_InitWidget()

    self:AttachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self:AttachEvent(GameEventType.RolePropertyChanged, self.ItemCountChanged)

    self.te =
        UIActivityHelper.StartTimerEvent(
        self.te,
        function()
            self:FlushLeftTime()
        end
    )

    self.curSelectDay = 0

    self.fsm = StateMachineManager:GetInstance():CreateStateMachine("StatePetForecast", StatePetForecast)
    self.fsm:SetData(self)
    self.fsm:Init(StatePetForecast.Init)

    -- Clear New
    if self._data and self._data.id > 0 then
        local id = self._data.id
        local key = UIPetForecastEnter.GetLocalDBKey(id)
        LocalDB.SetInt(key, 1)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CampaignComponentStepChange, -1, nil, nil)
    end
end

function UIPetForecastContent:DoHide()
    UIWidgetHelper.ClearWidgets(self, "_tipsPool")
    self:Close()

    self._pieceList = self._pieceList or {}
    for _, v in ipairs(self._pieceList) do
        v:Select(false)
    end

    self.te = UIActivityHelper.CancelTimerEvent(self.te)
    self:DetachEvent(GameEventType.ShowItemTips, self.ShowTips)
    self:DetachEvent(GameEventType.RolePropertyChanged, self.ItemCountChanged)
end

function UIPetForecastContent:DoDestroy()
end

-----------------------------------------------------------------------------------

function UIPetForecastContent:RequestPrediction(TT)
    local lockName = "UIPetForecastContent_RequestPrediction"
    self:Lock(lockName)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    self._data = self._dataLoader:LoadData(TT, res)
    self:Flush()
    self:UnLock(lockName)
end

function UIPetForecastContent:Init()
    local eng = HelperProxy:GetInstance():IsInEnglish()
    if eng then
        self.title:SetActive(false)
        self.titleEn:SetActive(true)
    else
        self.title:SetActive(true)
        self.titleEn:SetActive(false)
    end
    self.imgLeftTime.sprite = self.atlas:GetSprite(self.data.imgLeftTime)
    self.b.anchoredPosition = self.data.posTitle
    self.b.sizeDelta = self.data.sizeTitle
end

function UIPetForecastContent:Flush(isShow)
    if not self.data then
        Log.warn("### self.data nil.")
        return
    end
    self.bgTitle.sprite = self.atlas:GetSprite(self.data.bgTitle)

    self:FlushLeftTimeColor()
    self:FlushLeftTime()
    self:FlushDesc()

    local mainBg = self.data:GetMainBG()
    self:GetGameObject("mainBg"):SetActive(mainBg ~= nil)
    if mainBg then
        UIWidgetHelper.SetRawImage(self, "mainBg", mainBg)
    end

    self._bg:LoadImage(self.data:GetBG())

    if isShow == nil then
        isShow = self.data:IsAllAccepted() and self.data:HasNewPieceImage()
    end

    local len = table.count(self.data.pieces)
    self.pieces:SpawnObjects("UIPetForecastItem", len)
    ---@type UIPetForecastItem[]
    local pieceList = self.pieces:GetAllSpawnList()
    self._pieceList = pieceList
    for i, ui in ipairs(pieceList) do
        ui:Flush(
            i,
            function(day)
                if day < 1 or day > len then
                    Log.fatal("### invalid param. day = ", day)
                    return
                end
                if pieceList[self.curSelectDay] then
                    pieceList[self.curSelectDay]:Select(false)
                end
                if self.curSelectDay == day then
                    self.curSelectDay = 0
                    self:FlushDesc()
                else
                    pieceList[day]:Select(true)
                    self.curSelectDay = day
                    self:FlushDesc()
                end
            end,
            isShow,
            function ()
                if self.data:IsAllAccepted() then
                    self:_SetShareBtn()
                end
            end
        )
    end

    if self.data:IsAllAccepted() then
        self:_SetShareBtn()

        self.goInfo:SetActive(true)
        if self.data.pets then
            local lenPets = table.count(self.data.pets)
            self.info:SpawnObjects("UIDrawCardPetInfoLoader", lenPets)
            ---@type UIDrawCardPetInfoLoader[]
            local pets = self.info:GetAllSpawnList()
            self.view1:SpawnObjects("UIPetForecastViewItem", lenPets)
            ---@type UIPetForecastViewItem[]
            local views = self.view1:GetAllSpawnList()
            for i, v in ipairs(pets) do
                local pet = self.data.pets[i]
                v:SetData(
                    2,
                    pet.petId,
                    Vector2.zero,
                    function(id)
                        self:ShowDialog("UIShopPetDetailController", id)
                    end
                )
                local go = v:GetGameObject()
                local tran = go:GetComponent(typeof(UnityEngine.RectTransform))
                local v05 = Vector2.one * 0.5
                tran.anchorMin = v05
                tran.anchorMax = v05
                tran.anchoredPosition = pet.pos
                --
                views[i]:Flush(pet.petId)
            end
        else
            -- Log.warn("### cfg_prediction.pets nil. self.cfgId=", self.cfgId)
        end
    else
        self.goInfo:SetActive(false)
    end
end

function UIPetForecastContent:FlushLeftTimeColor()
    local colorBG, colorHint, color = self.data:GetLeftTimeColor()
    self.imgLeftTime.color = colorBG
    self.imgClock.color = colorHint
    self.txtLeftTimeHint.color = colorHint
    self.txtLeftTime.color = color
end

function UIPetForecastContent:FlushLeftTime()
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < self.data.endTime then
        local leftSeconds = UICommonHelper.CalcLeftSeconds(self.data.endTime)
        local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
        if d >= 1 then
            self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_d_h", math.floor(d), math.floor(h)))
        else
            if h >= 1 then
                self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_h_m", math.floor(h), math.floor(m)))
            else
                if m >= 1 then
                    self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_m", math.floor(m)))
                else
                    self.txtLeftTime:SetText(StringTable.Get("str_prediction_left_time_m", "<" .. 1))
                end
            end
        end
    else
        self.txtLeftTime:SetText(StringTable.Get("str_prediction_error_code_1"))
        UIActivityHelper.CancelTimerEvent(self.te)
    end
end

---@param curSelectDay number 当前选中的第N天拼图，0表示未选中
function UIPetForecastContent:FlushDesc()
    --获取角色名
    local name = GameGlobal.GetModule(RoleModule):GetName()
    if string.isnullorempty(name) then
        name = StringTable.Get("str_guide_moren_name")
    end
    local str = ""
    if self.curSelectDay == 0 then
        str = StringTable.Get("str_prediction_info_" .. self.data.id, name)
    else
        str = StringTable.Get("str_prediction_info_" .. self.data.id .. "_" .. self.curSelectDay, name)
    end
    self.txtDesc:SetText(str)
    self.sv.verticalNormalizedPosition = 1
end

function UIPetForecastContent:ShowTips(matid, pos)
    UIWidgetHelper.SetAwardItemTips(self, "_tipsPool", matid, pos)
end

function UIPetForecastContent:Close()
    self.fsm:ChangeState(StatePetForecast.NewUnlockClose)
end

function UIPetForecastContent:ItemCountChanged()
    self:StartTask(self.RequestPrediction, self)
end

--region ShareBtn

function UIPetForecastContent:_ShareBtn_InitWidget()
    self._shareBtnGo = self:GetGameObject("ShareBtn")
    self._shareBtnGo:SetActive(false)
    self._bgGo = self:GetGameObject("bg")
    self._bGo = self:GetGameObject("b")
    self._rbGo = self:GetGameObject("rb")
    self._shareBgGo = self:GetGameObject("shareBg")
    self._shareBgGo:SetActive(false)
    
    ---@type UnityEngine.RectTransform
    self.regionRect = self:GetUIComponent("RectTransform", "region")
end

function UIPetForecastContent:_SetShareBtn()
    local isZh = UIActivityZhHelper.IsZh()
    if isZh == false then -- 国际服
        self._shareBtnGo:SetActive(false)
        return
    end

    local shareModule = self:GetModule(ShareModule)
    self._shareBtnGo:SetActive(shareModule:CanShare())
end

function UIPetForecastContent:ShareBtnOnClick(go)
    self:Lock("UIPetForecastShare")
    self:StartTask(
        function(TT)
            self:_SetShareUI(false)
            YIELD(TT)
            self:ShowDialog("UIShare", 
            "UISideEnterCenterController", 
            ShareAnchorType.CenterRight,
            function ()
                self:_SetShareUI(true)
            end,
            ShareAnchorType.TopCenter,
            nil,
            nil,
            ShareSceneType.CampaignPreView)
            self:UnLock("UIPetForecastShare")
        end,
        self
    )
end

function UIPetForecastContent:_SetShareUI(show)
    self._bgGo:SetActive(show)
    self._bGo:SetActive(show)
    self._rbGo:SetActive(show)
    self._shareBtnGo:SetActive(show)
    self._shareBgGo:SetActive(not show)

    if not self._defaultPos then
        self._defaultPos = self.regionRect.anchoredPosition
    end
    if show then -- 还原
        self:SetCenterUIHide(false)
        self.regionRect.anchoredPosition = self._defaultPos
        self.regionRect.localScale = Vector2(1, 1)
    else -- 截图模式
        self:SetCenterUIHide(true)
        self.regionRect.anchoredPosition = Vector2(self._defaultPos.x, self._defaultPos.y - 140)
        self.regionRect.localScale = Vector2(0.95, 0.95)
    end
end

--endregion

--region PlayPetForecastView
function UIPetForecastContent:IsPlaying()
    if self.isPlaying then
        for _, b in ipairs(self.isPlaying) do
            if b then
                return true
            end
        end
    end
    return false
end

---@param view PetForecastView
function UIPetForecastContent:PlayPetForecastView(view)
    if view and self.data:IsAllAccepted() and self.data:HasNewPieceImage() then
        self.isPlaying = {}
        for i, p in ipairs(view.parallel) do
            self.isPlaying[i] = true
            self:StartTask(
                function(TT)
                    local key = "UIPetForecastPlayPetForecastView" .. i
                    self:Lock(key)
                    for _, command in ipairs(p.commands) do
                        local nameFunc = "PlayPetForecastViewCommand" .. command.name
                        local func = self[nameFunc]
                        if func then
                            func(self, TT, command.params)
                        else
                            Log.fatal("### no function name: ", nameFunc)
                        end
                    end
                    self.isPlaying[i] = false
                    self:UnLock(key)
                end,
                self
            )
        end
    end
end

function UIPetForecastContent:PlayPetForecastViewCommandWait(TT, params)
    if params then
        local ms = tonumber(params[1] or "0")
        YIELD(TT, ms)
    end
end

function UIPetForecastContent:PlayPetForecastViewCommandPlayEffect(TT, params)
    if params then
        local effectName = (params[1] or "") .. ".prefab"
        local nodeName = params[2] or ""
        ---@type UnityEngine.Transform
        local tranParent = self:GetUIComponent("Transform", nodeName)
        if not tranParent then
            Log.error("###[UIPetForecast] no node:", nodeName)
            return
        end
        local tranChild = tranParent:Find(effectName)
        if tranChild then
            tranChild.gameObject:SetActive(true)
        else
            local effReq = ResourceManager:GetInstance():SyncLoadAsset(effectName, LoadType.GameObject)
            if not effReq then
                Log.error("###[UIPetForecast] effReq is nil !")
            end
            self.dictEffect[effectName] = effReq
            local child = effReq.Obj
            child.transform:SetParent(tranParent)
            local rect = child:GetComponent("RectTransform")
            rect.anchoredPosition = Vector2.zero
            rect.localScale = Vector3.one
            child:SetActive(true)
            child.name = effectName
        end
    end
end

function UIPetForecastContent:PlayPetForecastViewCommandPlayAudio(TT, params)
    if params then
        local audioId = tonumber(params[1] or "0")
        AudioHelperController.PlayUISoundAutoRelease(audioId)
    end
end

function UIPetForecastContent:PlayPetForecastViewCommandReplaceImage(TT, params)
    self:Flush(true)
end

function UIPetForecastContent:PlayPetForecastViewCommandPlayAnim(TT, params)
    if params then
        local nodeName = params[1] or ""
        ---@type UnityEngine.Transform
        local tranAnimNode = self:GetUIComponent("Animation", nodeName)
        if not tranAnimNode then
            Log.error("###[UIPetForecast] no node:", tranAnimNode)
            return
        end

        tranAnimNode:Play()
    end
end
--endregion

--region StatePetForecast

--- @class StatePetForecast
local StatePetForecast = {
    Init = 0, -- 0
    Normal = 1, --无新图情况
    NewUnlockLast = 2, --有新图，最后一张解锁后的表现
    NewUnlockNormal = 3, --有新图，全部解锁后新图常规表现
    NewUnlockClose = 4 --有新图，关闭界面表现
}
_enum("StatePetForecast", StatePetForecast)

--endregion
