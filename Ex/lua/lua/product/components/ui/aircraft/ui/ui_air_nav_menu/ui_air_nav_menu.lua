---@class UIAirNavMenu:UICustomWidget
_class("UIAirNavMenu", UICustomWidget)
UIAirNavMenu = UIAirNavMenu

function UIAirNavMenu:OnShow(uiParams)
    self._assetCount = 0
    self._enterlvCount = 0
    self._storyCount = 0
    self._discoveryCount = 0

    self._allCount = 0
    self._lastAllCount = 0

    self._circleOpen = false

    self._isDetailOpen = false

    self._atlas = self:GetAsset("UIAircraftMainUI.spriteatlas", LoadType.SpriteAtlas)

    self._count2pos = {
        [1] = {[1] = Vector2(-260, 10)},
        [2] = {[1] = Vector2(-250, 105), [2] = Vector2(-250, -55)},
        [3] = {[1] = Vector2(-190, 200), [2] = Vector2(-260, 10), [3] = Vector2(-175, -180)},
        [4] = {[1] = Vector2(-145, 240), [2] = Vector2(-250, 105), [3] = Vector2(-240, -55), [4] = Vector2(-135, -205)}
    }

    self._state2name = {
        [AirNavMenuBtnState.Asset] = "str_aircraft_quality_menu_asset_collect",
        [AirNavMenuBtnState.Room] = "str_aircraft_quality_menu_enter_lv",
        [AirNavMenuBtnState.Story] = "str_aircraft_quality_menu_pet_story",
        [AirNavMenuBtnState.Discovery] = "str_aircraft_quality_menu_discovery_finish"
    }

    self._state2icon = {
        [AirNavMenuBtnState.Asset] = "wind_tongyong_icon25",
        [AirNavMenuBtnState.Room] = "wind_tongyong_icon26",
        [AirNavMenuBtnState.Story] = "wind_tongyong_icon24",
        [AirNavMenuBtnState.Discovery] = "wind_tongyong_icon23"
    }

    self._state2circleColor = {
        [AirNavMenuBtnState.Asset] = Color(34 / 255, 200 / 255, 242 / 255, 1),
        [AirNavMenuBtnState.Room] = Color(115 / 255, 230 / 255, 128 / 255, 1),
        [AirNavMenuBtnState.Story] = Color(249 / 255, 142 / 255, 71 / 255, 1),
        [AirNavMenuBtnState.Discovery] = Color(246 / 255, 215 / 255, 85 / 255, 1)
    }

    self._state2maskImg = {
        [AirNavMenuBtnState.Asset] = "wind_tongyong_fang3",
        [AirNavMenuBtnState.Room] = "wind_tongyong_fang4",
        [AirNavMenuBtnState.Story] = "wind_tongyong_fang2",
        [AirNavMenuBtnState.Discovery] = "wind_tongyong_fang1"
    }

    self._module = GameGlobal.GetModule(AircraftModule)

    self._btnState = AirNavMenuBtnState.All

    --显示优先级，asset，enter，discovery
    self._showSpaceId = {}

    self._navAnim = {
        [1] = "uieff_aircraftNav_Panel_Show",
        [2] = "uieff_aircraftNav_Panel_Hide"
    }

    self.maxCountTime_start = 0
    self.maxCountTime_end = 20
    self.maxCountTime_Gaps = self.maxCountTime_end - self.maxCountTime_start
end

function UIAirNavMenu:SetData(main, focusRoom, focusPet)
    self:GetComponent()

    ---@type AircraftMain
    self._main = main

    self:GetAirNavMenuData()

    self._allCount = self._assetCount + self._enterlvCount + self._storyCount + self._discoveryCount

    self._lastAllCount = self._allCount

    self._focusRoom = focusRoom
    self._focusPet = focusPet

    if self._allCount > 0 then
        self._CountPanel:SetActive(true)
        self._allCountTex:SetText(self._allCount)
    else
        self._isDetailOpen = false
        self._CountPanel:SetActive(false)
    end
end

--通过碰撞盒算ui宽高
function UIAirNavMenu:CalcMaskImgSizeWithPosZ(BoxColliderSizeX, BoxColliderSizeY)
    local k = 26
    local sizeX = BoxColliderSizeX * k
    local sizeY = BoxColliderSizeY * k
    return Vector2(sizeX, sizeY)
end

--房间星灵数据
function UIAirNavMenu:GetAirNavMenuData()
    --初始化导航栏
    --资源收取
    local roomList = self._module:GetAllRooms()
    self._assetCount = 0
    self._assetRoomList = {}
    for spaceid, room in pairs(roomList) do
        local roomType = room:GetRoomType()
        if roomType ~= AirRoomType.DispatchRoom then
            local canCollect = room:CanCollect()
            -- if roomType == AirRoomType.TacticRoom then
            --     canCollect = room:NavMenuCanCollect()
            -- else
            --     canCollect = room:CanCollect()
            -- end
            if canCollect then
                self._assetCount = self._assetCount + 1
                table.insert(self._assetRoomList, room)
            end
        end
    end
    --可升级入住
    self._enterlvCount = 0
    self._enterLvRoomList = {}
    for i = 1, 16 do
        local canLvUp = self._module:CanRoomLevelUp(i)
        if canLvUp then
            self._enterlvCount = self._enterlvCount + 1
        end
        local canEnter = self._module:CanRoomSettlePet(i)
        if canEnter then
            self._enterlvCount = self._enterlvCount + 1
        end
        local canBuild = self._main:GetRoomCanBuildForNav(i)
        if canBuild then
            self._enterlvCount = self._enterlvCount + 1
        end

        if canLvUp or canEnter or canBuild then
            local lv = canLvUp
            local enter = canEnter
            local data = {}
            data.lv = canLvUp
            data.enter = canEnter
            data.build = canBuild
            data.spaceid = i
            table.insert(self._enterLvRoomList, data)
        end
    end

    --获取触发的随机剧情数量
    -- local storyCount = self._main:GetRandomStoryTriggerCount()
    -- local storys = self._main:GetRandomStoryPets()
    -- local storyPets = {}
    -- for key, value in pairs(storys) do
    --     local petid = value.petid
    --     local pet = self._main:GetPetByTmpID(petid)
    --     table.insert(storyPets, pet)
    -- end
    --拜访和送礼星灵
    local _pets =
        self._main:GetPets(
        function(pet)
            ---@type AircraftPet
            local _pet = pet
            if
                _pet:IsGiftPet() or (_pet:IsVisitPet() and _pet:HasVisitGift()) or
                    _pet:GetState() == AirPetState.RandomEvent
             then
                return true
            else
                return false
            end
        end,
        true
    )
    self._storyPets = {}
    for i = 1, table.count(_pets) do
        local _pet = _pets[i]
        local _petData = {}
        if _pet:IsVisitPet() then
            _petData.isVisitPet = true
        else
            _petData.isVisitPet = false
        end
        _petData.pet = _pet

        table.insert(self._storyPets, _petData)
    end
    self._storyCount = table.count(self._storyPets)

    --探索室
    self._discoveryCount = 0
    self._discoveryList = {}
    -- if roomList and table.count(roomList) then
    --     for _, room in pairs(roomList) do
    --         local roomType = room:GetRoomType()
    --         if roomType == AirRoomType.DispatchRoom then
    --             --可拍次数
    --             local dispatchCount = room:GetDispatchCount()

    --             --可拍队伍数
    --             local dispatchTeamCount = room:GetDispatchTeamCount()
    --             local roomCfg = room:GetRoomConfig()
    --             local lessTeamCount = roomCfg.TeamMax - dispatchTeamCount

    --             --可拍星灵数
    --             local lessPetCount = math.modf((table.count(room:GetDispatchPetList()) / 5) + 0.05)

    --             --取最小值
    --             local showNumber = dispatchCount
    --             if lessTeamCount < showNumber then
    --                 showNumber = lessTeamCount
    --             end
    --             if lessPetCount < showNumber then
    --                 showNumber = lessPetCount
    --             end

    --             if room:HasCompleteTask() or showNumber > 0 then
    --                 local addCount = room:GetCompleteCount()
    --                 local finishRoom = false
    --                 if addCount and addCount > 0 then
    --                     finishRoom = true
    --                 end
    --                 self._discoveryCount = self._discoveryCount + addCount + showNumber
    --                 local data = {}
    --                 data.room = room
    --                 data.finish = finishRoom
    --                 table.insert(self._discoveryList, data)
    --             end
    --         end
    --     end
    -- end
end

function UIAirNavMenu:RefreshData()
    self:GetAirNavMenuData()
    self._allCount = self._assetCount + self._enterlvCount + self._storyCount + self._discoveryCount

    if self._allCount > 0 then
        self._CountPanel:SetActive(true)
        self:AllCountAnim()
    else
        if self._isDetailOpen then
            self:CloseNavMenu()
        end
        self._isDetailOpen = false
        self._CountPanel:SetActive(false)
    end

    if self._isDetailOpen then
        self:CreateCircleData()

        self:SpawnBtnItems(false)

        self:ShowAllEff()
    end
end
function UIAirNavMenu:AllCountAnim()
    self.accTime = 0
    self._tweening = true
end

function UIAirNavMenu:Update(dms)
    if self._tweening then
        self.accTime = self.accTime + dms

        local tweenCount = (self.accTime - self.maxCountTime_start) / self.maxCountTime_Gaps
        if self.accTime >= self.maxCountTime_end then
            tweenCount = 1
            self._tweening = false
        end
        if tweenCount <= 1 and tweenCount >= 0 then
            local cRec =
                DG.Tweening.DOVirtual.EasedValue(
                self._lastAllCount,
                self._allCount,
                tweenCount,
                DG.Tweening.Ease.OutQuad
            )
            self._allCountTex:SetText(math.floor(cRec))
        end
        if not self._tweening then
            self._lastAllCount = self._allCount
        end
    end

    if self._circleOpen then
        if self._roomEffs and #self._roomEffs > 0 then
            for i = 1, #self._roomEffs do
                if i <= #self._storyPets then
                    local effItem = self._roomEffs[i]
                    local pet = self._storyPets[i].pet
                    local petGo = pet:GameObject()
                    local pos = self:GetPosWithGameObject(petGo)
                    effItem:FlushPos(pos)
                end
            end
        end
        if self._roomEffsOutLine and #self._roomEffsOutLine > 0 then
            for i = 1, #self._roomEffsOutLine do
                if i <= #self._storyPets then
                    local effItem = self._roomEffsOutLine[i]
                    local pet = self._storyPets[i].pet
                    local petGo = pet:GameObject()
                    local pos = self:GetPosWithGameObject(petGo)
                    effItem:FlushPos(pos)
                end
            end
        end
        if self._roomEffsHead and #self._roomEffsHead > 0 then
            for i = 1, #self._roomEffsHead do
                if i <= #self._storyPets then
                    local effItem = self._roomEffsHead[i]
                    local pet = self._storyPets[i].pet
                    local petGo = pet:GameObject()
                    local pos = self:GetPosWithGameObject(petGo)
                    effItem:FlushPos(pos)
                end
            end
        end
    end
end

function UIAirNavMenu:GetComponent()
    self._btnPool = self:GetUIComponent("UISelectObjectPath", "itemPool")

    self._allCountTex = self:GetUIComponent("UILocalizationText", "allCount")

    self._assetRoomEffPool = self:GetUIComponent("UISelectObjectPath", "assetRoomEffPool")
    self._enterRoomEffPool = self:GetUIComponent("UISelectObjectPath", "enterRoomEffPool")
    self._storyPetEffPool = self:GetUIComponent("UISelectObjectPath", "storyPetEffPool")
    self._discoveryRoomEffPool = self:GetUIComponent("UISelectObjectPath", "discoveryRoomEffPool")
    self._storyPetCircleEffPool = self:GetUIComponent("UISelectObjectPath", "storyPetCircleEffPool")
    self._storyPetCircleEffPoolOutLine = self:GetUIComponent("UISelectObjectPath", "storyPetCircleEffPoolOutLine")

    self._assetRoomEffPoolGo = self:GetGameObject("assetRoomEffPool")
    self._enterRoomEffPoolGo = self:GetGameObject("enterRoomEffPool")
    self._storyPetEffPoolGo = self:GetGameObject("storyPetEffPool")
    self._discoveryRoomEffPoolGo = self:GetGameObject("discoveryRoomEffPool")
    self._storyPetCircleEffPoolGo = self:GetGameObject("storyPetCircleEffPool")
    self._storyPetCircleEffPoolOutLineGo = self:GetGameObject("storyPetCircleEffPoolOutLine")
    self._alpha = self:GetGameObject("alpha")

    self._CountPanel = self:GetGameObject("CountPanel")
    self._CountPanel:SetActive(true)
    self._normalGo = self:GetGameObject("normal")
    self._normalGo:SetActive(true)
    self._detailGo = self:GetGameObject("detail")
    self._detailGo:SetActive(false)
    self._circlrImgGo = self:GetGameObject("circlrBg")
    self._circlrImg = self:GetUIComponent("Image", "circlrBg")
    self._circlrImgGo:SetActive(false)
    self._maskGo = self:GetGameObject("mask")
    self._maskRect = self:GetUIComponent("RectTransform", "mask")
    self._maskGo:SetActive(false)

    self._circleAnim = self:GetUIComponent("Animation", "CountPanel")
    self._canvasGroup = self:GetUIComponent("CanvasGroup", "mask")
    self._iconRect = self:GetUIComponent("RectTransform", "normalIcon")
    self._iconImg = self:GetUIComponent("Image", "normalIcon")
end

--是否打开详细数量
function UIAirNavMenu:_CheckNormalDetailActive()
    self._detailGo:SetActive(self._isDetailOpen)
    self._maskGo:SetActive(self._isDetailOpen)
    self._normalGo:SetActive(not self._isDetailOpen)
    --self._normalIcon:SetActive(not self._isDetailOpen)
end

--显示类型对应的背景圆
function UIAirNavMenu:_ShowCircleBg()
    self._circlrImgGo:SetActive(self._btnState ~= AirNavMenuBtnState.All)
    if self._btnState ~= AirNavMenuBtnState.All then
        self._circlrImg.color = self._state2circleColor[self._btnState]
    end
end

--创建按钮的数据
function UIAirNavMenu:CreateCircleData()
    self._showCount = 0
    self._showTab = {}
    if self._assetCount > 0 then
        self._showCount = self._showCount + 1
        local tab = {}
        tab.state = AirNavMenuBtnState.Asset
        tab.count = self._assetCount
        self._showTab[#self._showTab + 1] = tab
    end
    if self._enterlvCount > 0 then
        self._showCount = self._showCount + 1
        local tab = {}
        tab.state = AirNavMenuBtnState.Room
        tab.count = self._enterlvCount
        self._showTab[#self._showTab + 1] = tab
    end
    if self._storyCount > 0 then
        self._showCount = self._showCount + 1
        local tab = {}
        tab.state = AirNavMenuBtnState.Story
        tab.count = self._storyCount
        self._showTab[#self._showTab + 1] = tab
    end
    if self._discoveryCount > 0 then
        self._showCount = self._showCount + 1
        local tab = {}
        tab.state = AirNavMenuBtnState.Discovery
        tab.count = self._discoveryCount
        self._showTab[#self._showTab + 1] = tab
    end
end

--显示按钮
function UIAirNavMenu:SpawnBtnItems(needAnim)
    self._btnPool:SpawnObjects("UIAirNavMenuBtnItem", #self._showTab)
    ---@type UIAirNavMenuBtnItem[]
    local pools = self._btnPool:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]

        if i <= self._showCount then
            item:GetGameObject():SetActive(true)

            local idx = i
            local state = self._showTab[i].state
            local count = self._showTab[i].count
            local icon = self._atlas:GetSprite(self._state2icon[state])
            local name = self._state2name[state]
            local pos = self._count2pos[self._showCount][i]
            local cb = function(state)
                self:OnItemClick(state)
            end
            item:SetData(idx, state, self._btnState, count, icon, name, pos, cb)

            if needAnim then
                local yieldTime = (idx - 1) * 33
                item:PlayAnim_In(yieldTime)
            end
        else
            item:GetGameObject():SetActive(false)
        end
    end
end
function UIAirNavMenu:CloseAllEff()
    self._assetRoomEffPoolGo:SetActive(false)
    self._enterRoomEffPoolGo:SetActive(false)
    self._storyPetEffPoolGo:SetActive(false)
    self._discoveryRoomEffPoolGo:SetActive(false)
    self._storyPetCircleEffPoolGo:SetActive(false)
    self._storyPetCircleEffPoolOutLineGo:SetActive(false)
    self._alpha:SetActive(false)
end
--显示全部eff
function UIAirNavMenu:ShowAllEff()
    self:GetAirNavMenuData()

    self._assetRoomEffPoolGo:SetActive(true)
    self._enterRoomEffPoolGo:SetActive(true)
    self._storyPetEffPoolGo:SetActive(true)
    self._discoveryRoomEffPoolGo:SetActive(true)
    self._storyPetCircleEffPoolGo:SetActive(false)
    self._storyPetCircleEffPoolOutLineGo:SetActive(false)
    self._alpha:SetActive(false)

    self:ShowStoryPetEff()
    if self._btnState == AirNavMenuBtnState.Story then
        self:ShowStoryPetCircleEff()
    end
    self:ShowDiscoveryRoomEff()
    self:ShowAssetRoomEff()
    self:ShowEnterLvRoomEff()
    --默认选中(删掉)
    -- if self._showCount == 1 then
    --     self:OnItemClick(self._showTab[1].state)
    -- end
end

--资源收取的eff点击回调
---@param room AircraftRoom
function UIAirNavMenu:OnEffAssetRoomClick(room)
    Log.debug("###[UIAirNavMenu] OnEffAssetRoomClick !")
    local clickRoom = room
    local roomType = room:GetRoomType()
    if roomType == AirRoomType.TacticRoom then
        --跳转战术室
        self:OnEffDiscoveryRoomClick(room)
    else 
        self:Lock("UIAirNavMenu:CollectOneAsset")
        local spaceid = clickRoom:SpaceId()
        self:CloseNavMenu()
        GameGlobal.TaskManager():StartTask(self.OnOnEffAssetRoomClick, self, spaceid)
    end
end
function UIAirNavMenu:OnOnEffAssetRoomClick(TT, spaceid)
    Log.debug("###[UIAirNavMenu] OnOnEffAssetRoomClick !")
    local res, msg = self._module:RequestCollectAsset(TT, spaceid)
    self:UnLock("UIAirNavMenu:CollectOneAsset")
    if res and res:GetSucc() then
        --通知主界面刷新导航栏数据,还要通知3dui刷新，所以刷新风船整个数据
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRefreshMainUI)

        Log.debug("###[UIAirNavMenu] CollectAllAsset  Succ!")

        ---@type CEventAircraftRoomOperateResult
        local matList = msg.asset
        self:ShowDialog("UIGetItemController", matList)
    else
        self:GetAssetFailTips(res:GetResult())
        Log.error("###[NavMenu]UIAirNavMenu:OnCollectAllAsset result --> ", res:GetResult())
    end
end
--入住升级的eff点击回调
---@param data table @(data = {enter,lv,room})
function UIAirNavMenu:OnEffEnterRoomClick(data)
    self:CloseNavMenu()
    local spaceid = data.spaceid
    if data.build then
        --[[
            --播完关闭动画
            self:Lock("UIAirNavMenu:OnEffEnterRoomClick(data)")
            GameGlobal.Timer():AddEvent(
                400,
                function()
                    self:UnLock("UIAirNavMenu:OnEffEnterRoomClick(data)")
                    --单机一次
                    GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SelectRoom", spaceid)
                end
                )
                ]]
        GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SelectRoom", spaceid)
    else
        --打开升级或入住
        if data.enter then
            GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SetNavMenuData", 1)
        elseif data.lv then
            GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SetNavMenuData", 2)
        end
        --两次selectroom
        GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SelectAndFocusRoom", spaceid)
    end
end
--星灵剧情的eff点击回调
---@param aircraftPet AircraftPet
function UIAirNavMenu:OnStoryPetClick(aircraftPet)
    local cliclPet = aircraftPet

    --聚焦星灵
    if self._focusPet then
        self._focusPet(cliclPet)
    end

    self:CloseNavMenu()
end

--探索室的点击回调
---@param room AircraftRoomBase
function UIAirNavMenu:OnEffDiscoveryRoomClick(room)
    local spaceid = room:SpaceId()
    local clickRoom = self._main:GetRoomBySpaceID(spaceid)
    local roomType = room:GetRoomType()

    --聚焦房间
    if self._focusRoom then
        self._focusRoom(
            clickRoom,
            function()
                GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "SelectRoom", spaceid)

                if roomType == AirRoomType.TacticRoom then
                    --打开战术室
                    GameGlobal.UIStateManager():ShowDialog("UIAircraftTactic")
                elseif roomType == AirRoomType.DispatchRoom then
                    --打开探索室
                    GameGlobal.UIStateManager():ShowDialog("UIDispatchMapController")
                end
            end
        )
    end

    self:CloseNavMenu()
end

--显示可收取资源的房间mask
function UIAirNavMenu:ShowAssetRoomEff()
    ---@type AircraftRoom[]
    local roomList = self._assetRoomList
    local tableCount = table.count(roomList)
    self._assetRoomEffPool:SpawnObjects("UIAirNavMenuAssetRoomEff", tableCount)
    ---@type UIAirNavMenuAssetRoomEff[]
    local roomEffs = self._assetRoomEffPool:GetAllSpawnList()
    for i = 1, #roomEffs do
        local active = true
        if i > tableCount then
            active = false
        else
            local data = roomList[i]
            local spaceid = data:SpaceId()
            if self._showSpaceId[spaceid] then
                active = false
            end
        end

        local effItem = roomEffs[i]
        if active then
            local data = roomList[i]
            local spaceid = data:SpaceId()
            local roomGo = self._main:GetRoomGoSpaceID(spaceid)
            local pos = self:GetPosWithGameObject(roomGo)

            local sizeX = roomGo:GetComponent("BoxCollider").size.x
            local sizeY = roomGo:GetComponent("BoxCollider").size.y
            local size = self:CalcMaskImgSizeWithPosZ(sizeX, sizeY)

            effItem:GetGameObject():SetActive(true)
            effItem:SetData(
                pos,
                size,
                data,
                function(room)
                    self:OnEffAssetRoomClick(room)
                end
            )

            self._showSpaceId[spaceid] = true
        else
            effItem:GetGameObject():SetActive(false)
        end
    end
end
--显示可升级入驻的房间mask
function UIAirNavMenu:ShowEnterLvRoomEff()
    local roomList = self._enterLvRoomList
    local tableCount = table.count(roomList)
    self._enterRoomEffPool:SpawnObjects("UIAirNavMenuEnterRoomEff", tableCount)
    ---@type UIAirNavMenuEnterRoomEff[]
    local roomEffs = self._enterRoomEffPool:GetAllSpawnList()
    for i = 1, #roomEffs do
        local active = true
        if i > tableCount then
            active = false
        else
            local data = roomList[i]
            local spaceid = data.spaceid
            if self._showSpaceId[spaceid] then
                active = false
            end
        end

        local effItem = roomEffs[i]
        if active then
            local data = roomList[i]
            local spaceid = data.spaceid
            local roomGo = self._main:GetRoomGoSpaceID(spaceid)
            local pos = self:GetPosWithGameObject(roomGo)

            local sizeX = roomGo:GetComponent("BoxCollider").size.x
            local sizeY = roomGo:GetComponent("BoxCollider").size.y
            local size = self:CalcMaskImgSizeWithPosZ(sizeX, sizeY)

            effItem:GetGameObject():SetActive(true)
            effItem:SetData(
                pos,
                size,
                data,
                function(data)
                    self:OnEffEnterRoomClick(data)
                end
            )

            self._showSpaceId[spaceid] = true
        else
            effItem:GetGameObject():SetActive(false)
        end
    end
end

--显示剧情星灵mask
function UIAirNavMenu:ShowStoryPetEff()
    local storyPets = self._storyPets
    local tableCount = table.count(storyPets)
    self._storyPetEffPool:SpawnObjects("UIAirNavMenuPetStoryEff", tableCount)
    ---@type UIAirNavMenuPetStoryEff[]
    self._roomEffsHead = self._storyPetEffPool:GetAllSpawnList()
    for i = 1, #self._roomEffsHead do
        local effItem = self._roomEffsHead[i]

        if i <= tableCount then
            ---@type AircraftRandomStoryItem
            ---@type AircraftPet
            local pet = storyPets[i].pet
            local isVisitPet = storyPets[i].isVisitPet

            local petGo = pet:GameObject()

            local pos = self:GetPosWithGameObject(petGo)

            effItem:SetData(
                pos,
                Vector2(0, 0),
                pet,
                isVisitPet,
                function(aircraftPet)
                    self:OnStoryPetClick(aircraftPet)
                end
            )
            effItem:GetGameObject():SetActive(true)
        else
            effItem:GetGameObject():SetActive(false)
        end
    end
end
--显示探索室mask
function UIAirNavMenu:ShowDiscoveryRoomEff()
    local roomList = self._discoveryList
    local tableCount = table.count(roomList)
    self._discoveryRoomEffPool:SpawnObjects("UIAirNavMenuDiscoveryRoomEff", tableCount)
    ---@type UIAirNavMenuDiscoveryRoomEff[]
    local roomEffs = self._discoveryRoomEffPool:GetAllSpawnList()
    for i = 1, #roomEffs do
        local active = true
        if i > tableCount then
            active = false
        else
            local data = roomList[i]
            local _room = data.room
            local spaceid = _room:SpaceId()
            if self._showSpaceId[spaceid] then
                active = false
            end
        end

        local effItem = roomEffs[i]
        if active then
            local data = roomList[i]
            local _room = data.room
            local spaceid = _room:SpaceId()
            local roomGo = self._main:GetRoomGoSpaceID(spaceid)
            local pos = self:GetPosWithGameObject(roomGo)

            local sizeX = roomGo:GetComponent("BoxCollider").size.x
            local sizeY = roomGo:GetComponent("BoxCollider").size.y
            local size = self:CalcMaskImgSizeWithPosZ(sizeX, sizeY)

            effItem:GetGameObject():SetActive(true)
            effItem:SetData(
                pos,
                size,
                data,
                function(data)
                    self:OnEffDiscoveryRoomClick(data)
                end
            )

            self._showSpaceId[spaceid] = true
        else
            effItem:GetGameObject():SetActive(false)
        end
    end
end

--当某个按钮点击
function UIAirNavMenu:OnItemClick(state)
    self._btnState = state
    self:_RefreshBtnState()
    self._showSpaceId = {}
    self:_ShowCircleBg()

    if self._btnState == AirNavMenuBtnState.Asset then
        self:CollectAllAsset()
        return
    end

    self._assetRoomEffPoolGo:SetActive(self._btnState == AirNavMenuBtnState.Asset)
    self._enterRoomEffPoolGo:SetActive(self._btnState == AirNavMenuBtnState.Room)
    self._storyPetEffPoolGo:SetActive(self._btnState == AirNavMenuBtnState.Story)
    self._discoveryRoomEffPoolGo:SetActive(self._btnState == AirNavMenuBtnState.Discovery)
    self._storyPetCircleEffPoolGo:SetActive(self._btnState == AirNavMenuBtnState.Story)
    self._storyPetCircleEffPoolOutLineGo:SetActive(self._btnState == AirNavMenuBtnState.Story)
    self._alpha:SetActive(self._btnState == AirNavMenuBtnState.Story)

    if self._btnState == AirNavMenuBtnState.Room then
        self:ShowEnterLvRoomEff()
    elseif self._btnState == AirNavMenuBtnState.Story then
        self:ShowStoryPetEff()
        self:ShowStoryPetCircleEff()
    elseif self._btnState == AirNavMenuBtnState.Discovery then
        --self:ShowDiscoveryRoomEff()
        local room = self._discoveryList[1].room
        self:OnEffDiscoveryRoomClick(room)
    end
    self._circleOpen = (self._btnState == AirNavMenuBtnState.Story)
end

function UIAirNavMenu:ShowStoryPetCircleEff()
    local storyPets = self._storyPets
    self._storyPetCircleEffPool:SpawnObjects("UIAirNavMenuPetStoryCircleEff", #storyPets)
    ---@type UIAirNavMenuPetStoryCircleEff[]
    self._roomEffs = self._storyPetCircleEffPool:GetAllSpawnList()
    for i = 1, #self._roomEffs do
        local effItem = self._roomEffs[i]
        if i <= #storyPets then
            ---@type AircraftRandomStoryItem
            ---@type AircraftPet
            local pet = storyPets[i].pet
            local petGo = pet:GameObject()
            local pos = self:GetPosWithGameObject(petGo)
            effItem:SetData(pos, Vector2(64, 64), pet)
            effItem:GetGameObject():SetActive(true)
        else
            effItem:GetGameObject():SetActive(false)
        end
    end

    self._storyPetCircleEffPoolOutLine:SpawnObjects("UIAirNavMenuPetStoryCircleEff", #storyPets)
    ---@type UIAirNavMenuPetStoryCircleEff[]
    self._roomEffsOutLine = self._storyPetCircleEffPoolOutLine:GetAllSpawnList()
    for i = 1, #self._roomEffsOutLine do
        local effItem = self._roomEffsOutLine[i]
        if i <= #storyPets then
            ---@type AircraftRandomStoryItem
            ---@type AircraftPet
            local pet = storyPets[i].pet
            local petGo = pet:GameObject()
            local pos = self:GetPosWithGameObject(petGo)
            effItem:SetData(pos, Vector2(66, 66), pet)
            effItem:GetGameObject():SetActive(true)
        else
            effItem:GetGameObject():SetActive(false)
        end
    end
end

--刷新其他按钮按下状态
function UIAirNavMenu:_RefreshBtnState()
    ---@type UIAirNavMenuBtnItem[]
    local pools = self._btnPool:GetAllSpawnList()
    for i = 1, #pools do
        local item = pools[i]
        item:RefreshBtnState(self._btnState)
    end
end

--显示按钮
function UIAirNavMenu:normalBtnOnClick(go)
    if not self._isDetailOpen then
        --关房间信息ui
        GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "ClearCurrentRoom")

        self._isDetailOpen = true

        local currentCameraPos = GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "GetCurrentCameraPos")
        local targetCameraPos =
            GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "GetNavMenuTargetCameraPos")
        local distance = Vector3.Distance(currentCameraPos, targetCameraPos)
        local speed = 0.15
        local moveTime = distance / speed

        GameGlobal.EventDispatcher():Dispatch(
            GameEventType.AircraftMainMoveCameraToNavMenu,
            function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.SetCameraToNavMenuPos)

                self._circleAnim:Play(self._navAnim[1])
                self._canvasGroup.alpha = 0
                self._canvasGroup:DOFade(1, 0.1)
                self:Lock("AirNavMenu_CircleAnim")
                GameGlobal.Timer():AddEvent(
                    500,
                    function()
                        self:UnLock("AirNavMenu_CircleAnim")
                    end
                )

                self:_CheckNormalDetailActive()

                self:CreateCircleData()

                self:SpawnBtnItems(true)

                self:_ShowCircleBg()

                self:CloseAllEff()
                --MSG24738	【必现】（测试_郭简宁）风船，点击导航栏后点击绿色按钮,框会抖一下，附视频，log	4	新缺陷	李学森, 1958	06/08/2021
                GameGlobal.Timer():AddEvent(
                    200,
                    function()
                        self:ShowAllEff()
                    end
                )
            end,
            moveTime
        )
    end
end

--一键领取收集资源
function UIAirNavMenu:CollectAllAsset()
    --判断有多少个房间可领取，如果只有战术室，则直接打开战术室房间，否则领取全部资源
    Log.debug("###[UIAirNavMenu] CollectAllAsset !")
    if #self._assetRoomList <= 0 then
        Log.error("###[UIAirNavMenu] self._assetRoomList count == 0 , but click all collect !")
        return
    end
    if #self._assetRoomList == 1 then
        local room = self._assetRoomList[1]
        local roomType = room:GetRoomType()
        if roomType == AirRoomType.TacticRoom then
            --跳转战术室
            self:OnEffDiscoveryRoomClick(room)
            return
        end
    end
   
    --领取资源
    self:Lock("UIAirNavMenu:CollectAllAsset")
    GameGlobal.TaskManager():StartTask(self.OnCollectAllAsset, self)
end
function UIAirNavMenu:OnCollectAllAsset(TT)
    local res, msg = self._module:OneKeyCollectAsset(TT)
    Log.debug("###[UIAirNavMenu] OnCollectAllAsset !")
    self:UnLock("UIAirNavMenu:CollectAllAsset")
    if res and res:GetSucc() then
        --通知主界面刷新导航栏数据,还要通知3dui刷新，所以刷新风船整个数据
        GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRefreshMainUI)
        Log.debug("###[UIAirNavMenu] CollectAllAsset  Succ!")

        ---@type CEventAircraftRoomOperateResult
        local matList = msg.asset
        self:ShowDialog("UIGetItemController", matList)
    else
        self:GetAssetFailTips(res:GetResult())
        Log.debug("###[NavMenu]UIAirNavMenu:OnCollectAllAsset result --> ", res:GetResult())
    end
end

function UIAirNavMenu:GetAssetFailTips(result)
    if result == AircraftEventResult.COLLECT_ASSET_EMPTY or result == AircraftEventResult.COLLECT_ASSET_ERROR_PHY then
        local tips = StringTable.Get("str_physicalpower_error_phy_add_full")
        ToastManager.ShowToast(tips)
    end
end

function UIAirNavMenu:CloseNavMenu()
    self:bgOnClick()
end
function UIAirNavMenu:IsDetailOpen()
    return self._isDetailOpen
end
--关闭按钮
function UIAirNavMenu:bgOnClick(go)
    if self._isDetailOpen then
        self._canvasGroup.alpha = 1
        self._canvasGroup:DOFade(0, 0.1)
        self._circleAnim:Play(self._navAnim[2])
        self:Lock("AirNavMenu_CircleAnim")
        GameGlobal.Timer():AddEvent(
            667,
            function()
                self._showSpaceId = {}
                self._isDetailOpen = false
                self._btnState = AirNavMenuBtnState.All
                self:_CheckNormalDetailActive()
                self:_ShowCircleBg()

                self._circleOpen = false

                --关闭的时候把头像隐藏
                self._petEffHead = self._storyPetEffPool:GetAllSpawnList()
                if self._petEffHead and table.count(self._petEffHead) > 0 then
                    for i = 1, #self._petEffHead do
                        local effItem = self._petEffHead[i]
                        effItem:GetGameObject():SetActive(false)
                    end
                end
                self._petEff = self._storyPetCircleEffPool:GetAllSpawnList()
                if self._petEff and table.count(self._petEff) > 0 then
                    for i = 1, #self._petEff do
                        local effItem = self._petEff[i]
                        effItem:GetGameObject():SetActive(false)
                    end
                end
                self._petEffOut = self._storyPetCircleEffPoolOutLine:GetAllSpawnList()
                if self._petEffOut and table.count(self._petEffOut) > 0 then
                    for i = 1, #self._petEffOut do
                        local effItem = self._petEffOut[i]
                        effItem:GetGameObject():SetActive(false)
                    end
                end

                self._storyPetCircleEffPoolGo:SetActive(false)
                self._storyPetCircleEffPoolOutLineGo:SetActive(false)
                self._alpha:SetActive(false)

                self:UnLock("AirNavMenu_CircleAnim")
            end
        )
    end
end

function UIAirNavMenu:OnHide()
    -- body
end

--通过go转换为uiPos
function UIAirNavMenu:GetPosWithGameObject(go)
    local tr = go.transform
    ---@type UnityEngine.BoxCollider
    local box = go:GetComponent("BoxCollider")
    local petPos
    if box then
        -- + Vector3(0, 0, -boxCenterZ - boxSizeZ)
        --local boxSizeZ = box.size.z
        --local boxCenterZ = box.center.z
        petPos = tr.position + box.center
    else
        petPos = tr.position
    end

    ---@type UnityEngine.Camera
    local camera3d = self:GetAirCamera3D()
    local screenPos = camera3d:WorldToScreenPoint(petPos)
    local camera2d = self:GetAirCamera2D()
    local res, pos =
        UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self._maskRect, screenPos, camera2d, nil)
    return pos
end
function UIAirNavMenu:GetAirCamera3D()
    return GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "GetAirCamera3D")
end
function UIAirNavMenu:GetAirCamera2D()
    return GameGlobal.UIStateManager():CallUIMethod("UIAircraftController", "GetAirCamera2D")
end
function UIAirNavMenu:ResetIconPos()
    self._iconRect.anchoredPosition = Vector2(-95.2, -5.7)
    self._iconImg.color = Color(1, 1, 1, 1)
end
---@class AirNavMenuBtnState
local AirNavMenuBtnState = {
    All = 0,
    Asset = 1,
    Room = 2,
    Story = 3,
    Discovery = 4
}
_enum("AirNavMenuBtnState", AirNavMenuBtnState)
