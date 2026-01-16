---@class UIHomelandModule:UIModule
_class("UIHomelandModule", UIModule)
UIHomelandModule = UIHomelandModule

function UIHomelandModule:Constructor()
    ---@type boolean 是否在家园中
    self._running = false
    ---@type HomelandClient 家园客户端主体
    self._homelandClient = nil

    ---@type FriendHomelandInfo 拜访好友简单数据
    self._visitInfo = nil

    ---@type UIHomeVisitInfo 拜访好友简单数据
    self._uiVisitInfo = nil

    --升级信息缓存，服务器推送之后不立刻弹窗，缓存推送信息，需要的地方手动获取缓存弹升级提示
    self._levelUpCache = 0

    --enter后代替切换ui执行的callback
    self._enterCallback = nil
end

function UIHomelandModule:ShowDialog(name, ...)
    GameGlobal.UIStateManager():ShowDialog(name, ...)
end

function UIHomelandModule:CloseDialog(name)
    GameGlobal.UIStateManager():CloseDialog(name)
end

function UIHomelandModule:IsRunning()
    return self._running
end

---@param cur_tick number 当前毫秒
function UIHomelandModule:Update(curTick)
    self._homelandClient:Update(curTick)

    --LogWrapper.LogDebug("cur tick in homeland:"..cur_tick)
end

---加载家园
function UIHomelandModule:LoadHomeland()
    HomeLoading.Self()
end

---加载家园美术编辑场景
function UIHomelandModule:LoadHomelandScene()
    HomeLoading.Self_Art()
end

---进入家园
function UIHomelandModule:EnterHomeland(TT, isVisit)
    Log.debug("[homeland loading] UIHomelandModule EnterHomeland start")
    self:AttachEvent(GameEventType.BeforeRelogin, self.LeaveHomeland)
    if isVisit then
        self._homelandClient = HomelandVisitClient:New()
    else
        self._homelandClient = HomelandClient:New()
    end
    self._homelandClient:Init(TT)
    self._homelandClient:OnEnterHomeland()
    self._running = true
    self:AttachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self._OnLevelInfoChanged)
    Log.debug("[homeland loading] UIHomelandModule EnterHomeland end")
end

function UIHomelandModule:SetEnterCallback(callback)
    self._enterCallback = callback
end

function UIHomelandModule:GetEnterCallback()
    return self._enterCallback
end

---离开家园
function UIHomelandModule:LeaveHomeland()
    self:ClearLevelupTip()
    self:DetachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self._OnLevelInfoChanged)
    self:DetachEvent(GameEventType.BeforeRelogin, self.LeaveHomeland)

    MovieFatherSon:Dispose()
    self._homelandClient:Dispose()
    self._homelandClient = nil

    self._visitInfo = nil
    self._uiVisitInfo = nil

    self._running = false
end

---@return HomelandClient
function UIHomelandModule:GetClient()
    return self._homelandClient
end

--存放事件信息
function UIHomelandModule:SetEventInfo(list, num)
    self._eventList = list
    self._eventNum = num
end

function UIHomelandModule:GetEventInfo()
    return self._eventList, self._eventNum
end

--设置拜访好友家园信息
function UIHomelandModule:SetVisitInfo(info)
    self._visitInfo = info
    if info then
        self._uiVisitInfo = UIHomeVisitInfo:New(info)
    end
    HomelandVisitHelper.RefreshVistAquariumFish()
end

---@return FriendHomelandInfo
function UIHomelandModule:GetVisitInfo()
    return self._visitInfo
end

---@return WishingPoolData
function UIHomelandModule:GetVisitPoolInfo()
    if self._visitInfo then
        return self._visitInfo.wishing_pool_info
    end
    return nil
end

---@return UIHomeVisitInfo
function UIHomelandModule:GetVisitUIInfo()
    return self._uiVisitInfo
end

--缓存好友和日志列表，因为这两个接口每分钟最多调用一次
function UIHomelandModule:ReqFriendList(TT)
    local needReq = false
    local now = GetSvrTimeNow()
    if self._reqFriendTime then
        if now - self._reqFriendTime > 60 then
            needReq = true
        end
    else
        needReq = true
    end

    if needReq then
        ---@type table<number, social_info_mobile>
        local allFriends = GameGlobal.GetModule(SocialModule):GetFriendList(TT)
        if not allFriends then
            Log.fatal("获取所有好友列表失败")
            return nil
        end
        local module = GameGlobal.GetModule(HomelandModule)
        local fres, fdata = module:HomelandVisitListReq(TT)
        if not fres:GetSucc() then
            Log.fatal("获取家园好友列表失败：", fres:GetResult())
            ToastManager.ShowHomeToast(module:GetVisitErrorMsg(fres:GetResult()))
            return nil
        end
        local lres
        ---@type CEventHomelandVisitLogReply
        local ldata
        lres, ldata = module:HomelandVisitLogReq(TT)
        if not lres:GetSucc() then
            Log.fatal("获取日志列表失败：", lres:GetResult())
            ToastManager.ShowHomeToast(module:GetVisitErrorMsg(lres:GetResult()))
            return nil
        end
        self._friendList = {}
        for _, value in pairs(fdata.visit_list) do
            ---@type visit_simple_info
            local visit_info = value
            local social_info = allFriends[visit_info.pstid]
            local friend = UIHomeFriendData:New(social_info, visit_info)
            table.insert(self._friendList, friend)
        end
        self._logList = {}
        for _, value in pairs(ldata.log_list.curday_list) do
            ---@type homelandVisitLogOnce
            local log_info = value
            local log = UIHomeVisitLog:New(log_info)
            table.insert(self._logList, log)
        end
        for _, value in pairs(ldata.log_list.log_list) do
            ---@type homelandVisitLogOnce
            local log_info = value
            local log = UIHomeVisitLog:New(log_info)
            table.insert(self._logList, log)
        end
        self._reqFriendTime = now
    end

    return self._friendList, self._logList
end

---@return cfg_item_tool_upgrade
function UIHomelandModule:GetCurrentToolCfg(toolType)
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    local axeCfgs = Cfg.cfg_item_tool_upgrade { ToolType = toolType }
    for _, cfg in pairs(axeCfgs) do
        local items = itemModule:GetItemByTempId(cfg.ID)
        if table.count(items) > 0 then
            return cfg
        end
    end
end

--拜访，为好友浇水
---@param breed HomelandBreedLand
function UIHomelandModule:Visit_Water(breed, point, interactBtn)
    if breed:Visit_IsWatered() then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_visit_has_watered"))
        return
    end
    local host = self._visitInfo.pstid
    GameGlobal.TaskManager():StartTask(self._Water, self, host, breed, point, interactBtn)
end

---@param breed HomelandBreedLand
---@param interactBtn UIInteractPoint
function UIHomelandModule:_Water(TT, host, breed, point, interactBtn)
    local pstID = breed:PstID()
    local module = GameGlobal.GetModule(HomelandModule)
    GameGlobal.UIStateManager():Lock("UIHomeVisitReqWater")
    local res, data = module:HomelandAccCultivateReq(TT, host, pstID)
    GameGlobal.UIStateManager():UnLock("UIHomeVisitReqWater")
    self._visitInfo.cultivation_info = data.newInfo
    if not res:GetSucc() then
        ToastManager.ShowHomeToast(module:GetVisitErrorMsg(res:GetResult()))
        return
    end
    GameGlobal.UIStateManager():Lock("PlayWaterAction")
    interactBtn:GetGameObject():SetActive(false)
    self._homelandClient:CharacterManager():MainCharacterController():Action_Water(TT, point)
    breed:HideWaterEft(TT)
    interactBtn:GetGameObject():SetActive(true)
    ToastManager.ShowHomeToast(StringTable.Get("str_homeland_visit_water_success"))
    GameGlobal.UIStateManager():UnLock("PlayWaterAction")
end

--等级或经验改变
function UIHomelandModule:_OnLevelInfoChanged(deltaLevel, curLevel)
    self._levelUpCache = deltaLevel
    self._curLevel = curLevel
    Log.notice("等级和经验消息推送:", deltaLevel)
end

--检查是否有升级提示
function UIHomelandModule:TryPopLevelUpTip()
    if self._levelUpCache > 0 then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_level_up", self._curLevel))
        self._levelUpCache = 0
        return true
    end
    return false
end

function UIHomelandModule:ClearLevelupTip()
    self._levelUpCache = 0
end

---种树交互点 点击 如果是收获则直接弹结果 否则进入种树界面
function UIHomelandModule:OnBreedInteract(breedBuild)
    local homelandModule = self:GetModule(HomelandModule)
    local svrTimeModule = self:GetModule(SvrTimeModule)
    local defaultType = HomelandBreedUIType.Mutation
    local breedState = HomelandBreedState.None
    local buildingPstId = breedBuild:GetArchitecture().pstid
    ---@type CultivationInfo
    local cultivationInfo = homelandModule:GetHomelandInfo().cultivation_info
    local landCultivationInfo = cultivationInfo.land_cultivation_infos[buildingPstId]
    if landCultivationInfo then
        local remainTime = homelandModule:GetLandEndTime(landCultivationInfo) - svrTimeModule:GetServerTime() * 0.001
        if #landCultivationInfo.client_info.mutation_cultivation > 0 then
            defaultType = HomelandBreedUIType.Mutation
            if remainTime <= 0 then
                breedState = HomelandBreedState.MutationReap
            else
                breedState = HomelandBreedState.Mutationing
            end
        end
        if #landCultivationInfo.client_info.directional_cultivation > 0 then
            defaultType = HomelandBreedUIType.Clone
            if remainTime <= 0 then
                breedState = HomelandBreedState.CloneReap
            else
                breedState = HomelandBreedState.Cloning
            end
        end

        if #landCultivationInfo.client_info.state_change_cultivation > 0 then
            defaultType = HomelandBreedUIType.StateChg
            breedState = HomelandBreedState.StateChgReap
        end
    end
    local mainSeedData = nil
    local mutationSeedData = nil
    local cbFunc = function()
    end
    --交互点收获 直接弹奖励
    if breedState == HomelandBreedState.MutationReap then
        ---@type MutationCultivation
        local mutationData = nil
        if landCultivationInfo then
            mutationData = landCultivationInfo.client_info.mutation_cultivation[1]
        end
        if mutationData then
            mainSeedData = Cfg.cfg_item[mutationData.main_seed_id]
            mutationSeedData = Cfg.cfg_item[mutationData.second_seed_id]
        end
    elseif breedState == HomelandBreedState.CloneReap then
        ---@type DirectionalCultivation
        local directionalCultivation = nil
        if landCultivationInfo then
            directionalCultivation = landCultivationInfo.client_info.directional_cultivation[1]
        end
        if directionalCultivation then
            mainSeedData = Cfg.cfg_item[directionalCultivation.seed_id]
            mutationSeedData = mainSeedData
        end
    elseif breedState == HomelandBreedState.StateChgReap then
        ---@type StateChangeCultivation
        local chgStateData = nil
        if landCultivationInfo then
            chgStateData = landCultivationInfo.client_info.state_change_cultivation[1]
        end
        if chgStateData then
            mainSeedData = Cfg.cfg_item[chgStateData.tree_id]
        end
    end


    if breedState == HomelandBreedState.MutationReap or breedState == HomelandBreedState.CloneReap or
        breedState == HomelandBreedState.StateChgReap then --交互点收获 直接弹奖励
        GameGlobal.TaskManager():StartTask(
            function(TT)
                local res, items, exp, first = homelandModule:HandlePickupCultivation(TT, buildingPstId)
                if res:GetSucc() then
                    if exp > 0 then
                        ---@type RoleAsset
                        local roleAsset = {}
                        roleAsset.exp = true
                        roleAsset.first = first
                        roleAsset.assetid = -1
                        roleAsset.count = exp
                        --table.insert(items, 1, roleAsset)
                    end
                    self:ShowDialog("UIHomelandBreedResult", mainSeedData, mutationSeedData, items, cbFunc, defaultType)
                    breedBuild:Clear()
                    if exp > 0 then
                        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_forge_add_exp", exp))
                    end
                    YIELD(TT, 1000)
                    ---@type UIHomelandModule
                    self:TryPopLevelUpTip()
                end
            end,
            self
        )
    else
        breedBuild:ShowDialog("UIHomelandBreed", breedBuild)
    end
    Log.info("BuildBase Show Breed UI", breedState)
end

--进入家园时打开某个界面
function UIHomelandModule:ShowStartDialog()
    if self._dialog then
        local name = self._dialog.name
        local param = self._dialog.param
        GameGlobal.UIStateManager():ShowDialog(name, param)
        self._dialog = nil
    end
end

function UIHomelandModule:SetDialog(dialogName, dialogParam)
    self._dialog = {}
    self._dialog.name = dialogName
    self._dialog.param = dialogParam
end

--剧情测试
function UIHomelandModule:SaveStoryList(saveList)
    if saveList then
        self._saveStoryList_test = saveList
    else
        return self._saveStoryList_test
    end
end

--进入拍电影准备阶段
function UIHomelandModule:EnterMoviePrepare(TT)
    local fatehrBuilding = MoviePrepareData:GetInstance():GetFatherBuild()
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomelandMoviePrepareMainController)
    while GameGlobal.UIStateManager():IsLocked() do
        YIELD(TT)
    end
    self._homelandClient:StartBuild()
    self._homelandClient:BuildManager():SetBuildEditorMode(BuildEditorMode.MakeMovieOther)
    self._homelandClient:BuildManager():SetFatherBuildingForMakeMovie(fatehrBuilding)
    self._homelandClient:BuildManager():ShowArea(false)

    self:ClearWallAndFloorInScene(fatehrBuilding)
end

--进入拍电影
function UIHomelandModule:EnterMovieMaker(TT)
--    -- MovieDataManager:GetInstance():SendDataToServer()
--     GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland)
--     while GameGlobal.UIStateManager():CurUIStateType() ~= UIStateType.UIHomeland do
--         YIELD(TT)
--     end
    self._homelandClient:SetLockGlobalCamera(nil)
    self._homelandClient:FinishBuild(TT)
    MoviePrepareData:GetInstance():EnsurePrepareArchList()
    --清理场景中光灵，清理场景中道具
    HomelandMoviePrepareManager:GetInstance():ShowAll(false)
    local movieID = MoviePrepareData:GetInstance():GetMovieId()
    local petList = {}
    local endList = HomelandMoviePrepareManager:GetInstance():GetSelectedData(MoviePrepareType.PT_Actor)
    for _, v in pairs(endList) do
        table.insert(petList, v:GetItemId())
    end
    local storyID = MovieDataManager:GetInstance():GetMovieStoryID(movieID, petList)
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIHomeMovieStoryController .. "DirectIn",
        function()
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeMovieStoryController, storyID, false, false, false, true, false)
            self._homelandClient:BuildManager():ShowArea(false)
        end
    )
end

--进入拍电影结算
function UIHomelandModule:EnterMovieResult(TT, isRecord)
    local fatehrBuilding = MoviePrepareData:GetInstance():GetFatherBuild()
    local scoreList = {}
    local movieID = MoviePrepareData:GetInstance():GetMovieId()
    --回放处理
    if isRecord then
        local playBackData = MoviePrepareData:GetInstance():GetPlayBackData()
        scoreList.actorScore = playBackData.pet_score / 2
        scoreList.itemScore = playBackData.item_score / 2
        scoreList.optionScore = playBackData.option_score / 2
        scoreList.totalScore = MovieDataManager:GetInstance():CaculateTotalScore(playBackData)
    else
        --提交评分
        MovieDataManager:GetInstance():SendDataToServer(TT)
        local replyData = MovieDataManager:GetInstance():GetReplyClosingData()
        scoreList.actorScore = replyData.pet_score / 2
        scoreList.itemScore = replyData.item_score / 2
        scoreList.optionScore = replyData.option_score / 2
        scoreList.totalScore = MovieDataManager:GetInstance():CaculateTotalScore(replyData)
    end

    local cfgClosingList = Cfg.cfg_homeland_movice_closing{MovieID = movieID}
    local closingItem = nil
    for _, v in pairs(cfgClosingList) do
        local l, r = MovieDataManager:GetInstance():GetClosingCondition(v.Condition)
        local score = MovieDataManager:GetInstance():TransferToStarScore(scoreList.totalScore)
        if score >= l and score < r + 0.01 then
            closingItem = v
            break
        end
    end

    --结算表现
    self._homelandMovieClosingManager = HomelandMovieClosingManager:New()
    self._homelandMovieClosingManager:ShowPetClosing(isRecord, closingItem)
    GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomelandMovieClosingController, isRecord, closingItem, scoreList, self._homelandMovieClosingManager)
    while GameGlobal.UIStateManager():IsLocked() do
        YIELD(TT)
    end
    --获取奖励
    if not isRecord then
        local replyData = MovieDataManager:GetInstance():GetReplyClosingData()
        if table.count(replyData.rewards) ~= 0 then
            GameGlobal.UIStateManager():ShowDialog("UIHomeShowAwards", replyData.rewards, nil,
                false,
                nil
            )
        end
    end


    self._homelandClient:StartBuild()
    self._homelandClient:BuildManager():SetBuildEditorMode(BuildEditorMode.MakeMovieClosing)
    self._homelandClient:BuildManager():SetFatherBuildingForMakeMovie(fatehrBuilding)
    self:FocusPreparePointDirect(fatehrBuilding, MoviePrepareType.PT_Result)
    self._homelandClient:SetLockGlobalCamera(true)
    self._homelandClient:BuildManager():ShowArea(false)

    CutsceneManager.ExcuteCutsceneOut()
end

--拍电影结束返回家园
function UIHomelandModule:EnterHomelandAfterMovieMaker(TT, isRecord, cutSceneOut)
    self._homelandClient:SetLockGlobalCamera(nil)

    AudioHelperController.PlayBGM(CriAudioIDConst.BGMEnterHomeland, AudioConstValue.BGMCrossFadeTime)

    if cutSceneOut then
        CutsceneManager.ExcuteCutsceneOut()
        GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland)
    else
        if self._homelandMovieClosingManager then
            self._homelandMovieClosingManager:StopAnim()
        end
        CutsceneManager.ExcuteCutsceneIn(
            UIStateType.UIHomeMovieStoryController .. "DirectIn",
            function()
                GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeland)
                CutsceneManager.ExcuteCutsceneOut()
            end
        )
    end

    local fatehrBuilding = MoviePrepareData:GetInstance():GetFatherBuild()
    self:RestoreFreeChildrenInScene(fatehrBuilding)
    --拍摄结束后清理所有数据
    if not isRecord then
        HomelandMoviePrepareManager:GetInstance():Dispose()
    end
    self._homelandClient:FinishBuild(TT)
end

--进入电影回放
function UIHomelandModule:EnterRepalyMovie(TT)
    local fatehrBuilding = MoviePrepareData:GetInstance():GetFatherBuild()
    self:ClearWallAndFloorInScene(fatehrBuilding)
    local archlist = MoviePrepareData:GetInstance():GetPrepareArchList()
    self:SetFreeChildren(fatehrBuilding, archlist)

    local movieID = MoviePrepareData:GetInstance():GetMovieId()
    local playBackData = MoviePrepareData:GetInstance():GetPlayBackData()
    local petList = {} 
    for _, v in pairs(playBackData.chose_pets) do
        table.insert(petList, v)
    end
    local storyID = MovieDataManager:GetInstance():GetMovieStoryID(movieID, petList)
    local openTease = MoviePrepareData:GetInstance():GetOpenTease()
    CutsceneManager.ExcuteCutsceneIn(
        UIStateType.UIHomeMovieStoryController .. "DirectIn",
        function()
            GameGlobal.UIStateManager():SwitchState(UIStateType.UIHomeMovieStoryController, storyID, false, false, false, openTease, true)
            self._homelandClient:BuildManager():ShowArea(false)
        end
    )
end

--获得自由区建筑，获取回放建筑数据
---@return Architecture[]
---@param fatherBuilding HomeBuildingFather
function UIHomelandModule:GetFreeChildren(fatherBuilding)
    return MovieFatherSon:OnSavePlayback(fatherBuilding)
end

--场景中清空自由区建筑，建造清空按钮与回放清空
---@param fatherBuilding HomeBuildingFather
function UIHomelandModule:ClearFreeChildrenInScene(fatherBuilding)
    return MovieFatherSon:OnClearFreeArea(fatherBuilding)
end

--场景墙和底板
---@param fatherBuilding HomeBuildingFather
function UIHomelandModule:ClearWallAndFloorInScene(fatherBuilding)
    return MovieFatherSon:OnClearMovie(fatherBuilding)
end

--场景中恢复自由区建筑，回放结束，恢复家园建筑数据
---@param fatherBuilding HomeBuildingFather
function UIHomelandModule:RestoreFreeChildrenInScene(fatherBuilding)
    return MovieFatherSon:OnRestoreHomeBuilding(fatherBuilding)
end

--设置自由区建筑，回放设置电影保存的建筑
---@param fatherBuilding HomeBuildingFather
---@param children Architecture[]
function UIHomelandModule:SetFreeChildren(fatherBuilding, children)
    return MovieFatherSon:OnEnterPlayback(fatherBuilding, children)
end

--控制自由显示区域是否高亮
---@param fatherBuilding HomeBuildingFather
---@param bShow boolean
function UIHomelandModule:ShowHightLightFreeArea(fatherBuilding, bShow)
    --return MovieFatherSon:OnShowFreeArea(fatherBuilding, bShow)
    fatherBuilding:ShowMovieFreeAreaEffect(bShow)
end

---@param fatherBuilding HomeBuildingFather
---@param prepareType MoviePrepareType
function UIHomelandModule:FocusPreparePoint(fatherBuilding, prepareType,callback)
    local point = self:GetPreparePoint(fatherBuilding, prepareType)
    if not point then
        if callback then
            callback()
        end
        return
    end

    self._homelandClient:BuildManager():FocusPoint(point,callback)
end

---@param prepareType MoviePrepareType 
function UIHomelandModule:FocusPreparePointDirect(fatherBuilding, prepareType,callback)
    local point = self:GetPreparePoint(fatherBuilding,prepareType)
    if not point then
        if callback then
            callback()
        end
        return
    end

    self._homelandClient:BuildManager():FocusPointDirect(point)
    if callback then
        callback()
    end
end

---@param prepareType MoviePrepareType 
function UIHomelandModule:GetPreparePoint(fatherBuilding, prepareType)
    local point = nil
    if prepareType == MoviePrepareType.PT_Scene then
        point = fatherBuilding:GetPrepareMovieSceneFocusPoint()
    elseif prepareType == MoviePrepareType.PT_Prop then
        point = fatherBuilding:GetPrepareMoviePropFocusPoint()
    elseif prepareType == MoviePrepareType.PT_Furniture then
        point = fatherBuilding:ChangeSkinFocusPoint()
    elseif prepareType == MoviePrepareType.PT_Actor then
        point = fatherBuilding:GetPrepareMovieActorFocusPoint()
    elseif prepareType == MoviePrepareType.PT_Result then
        point = fatherBuilding:GetPrepareMovieResultFocusPoint()
    else
        Log.error("ERR:UIHomelandModule:GetPreparePoint Can't Support ".. "prepareType")
    end
    return point
end