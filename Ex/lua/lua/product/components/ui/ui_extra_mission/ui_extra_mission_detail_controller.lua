---@class UIExtraMissionDetailController:UIController
_class("UIExtraMissionDetailController", UIController)
UIExtraMissionDetailController = UIExtraMissionDetailController

function UIExtraMissionDetailController:LoadDataOnEnter(TT, res, uiParams)
    --self._needAnim = true
    self.items = {}

    self._cfg_extra_mission = Cfg.cfg_extra_mission {}
    if self._cfg_extra_mission == nil then
        Log.fatal("[error] extraMission --> cfg_extra_mission is nil !")
    end

    --星灵番外ID的list
    self._extraMissionIDList = {}
    self:GetAllExtraMissionID()
    self._extraMissionIDCount = table.count(self._extraMissionIDList)

    ---@type ExtMissionModule
    self._module = GameGlobal.GetModule(ExtMissionModule)

    if uiParams[1] then
        self._extraMissionID = uiParams[1]
    else
        self._extraMissionIndex = self:GetPetListViewIndex()
        self._extraMissionID = self._extraMissionIDList[self._extraMissionIndex]
    end

    local res = self._module:Request_GetDetail_ExtMission(TT, self._extraMissionID)
    if res:GetSucc() then
        res:SetSucc(true)
    else
        res:SetSucc(false)
        Log.fatal("###ext -- UIExtraMissionDetailController:LoadDataOnEnter res false !")
    end
end

function UIExtraMissionDetailController:OnShow(uiParams)
    local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:SwitchState(UIStateType.UIExtraSelect)
        end,
        nil
    )

    self:GetComponents()

    --1:无参，2:番外ID,3:番外关卡id
    if uiParams[1] then
        self._inState = 2
        --self._raw:SetActive(false)
        self._extraMissionID = uiParams[1]
    else
        self._inState = 1
    end

    self:GetExtData()
end

function UIExtraMissionDetailController:UI_GetCurExtData()
    local stageid = 0
    local cfg = self._cfg_extra_mission[self._extraMissionID]
    if cfg then
        local taskList = cfg.ExtTaskList
        for i = 1, #taskList do
            local stars = self._module:UI_GetExtTaskState(self._extraMissionID, taskList[i])
            if stars < 0 then
                return stageid
            else
                stageid = taskList[i]
            end
        end
    end
end

--获取组建
function UIExtraMissionDetailController:GetComponents()
    self._leftArrow = self:GetGameObject("leftArrow")
    self._rightArrow = self:GetGameObject("rightArrow")
    ---@type UnityEngine.Animation
    self._anim = self:GetUIComponent("Animation", "uiAnim")
    self._bg = self:GetUIComponent("RawImageLoader", "bg")
    self._raw = self:GetGameObject("RawImage")
end

--检查左右箭头的显示
function UIExtraMissionDetailController:CheckArrowState()
    if self._extraMissionIndex <= 1 then
        self._leftArrow:SetActive(false)
    else
        self._leftArrow:SetActive(true)
    end
    if self._extraMissionIndex >= self._extraMissionIDCount then
        self._rightArrow:SetActive(false)
    else
        self._rightArrow:SetActive(true)
    end
end

--释放
function UIExtraMissionDetailController:Dispose()
    self._backBtns = nil
    self._rightArrow = nil
    self._leftArrow = nil
    self._backBtns = nil
end

--初始化番外信息
function UIExtraMissionDetailController:GetExtData()
    if self._inState == 1 then
        --if self._needAnim then
        --    self._anim:Play("uieff_ExtraMissionDetail_In")
        --end
        self._extraMissionIndex = self:GetPetListViewIndex()
        self._extraMissionID = self._extraMissionIDList[self._extraMissionIndex]
    elseif self._inState == 2 then
        self._extraMissionIndex = self:GetRextraMissionIdex(self._extraMissionID)
    end
    self._downOldIdx = self._extraMissionIndex

    self:InitExtraMissionList()

    self:SelectDownItem()

    self:CheckArrowState()

    local bg = self._cfg_extra_mission[self._extraMissionID].ExtMissionBigImg
    self._bg:LoadImage(bg)
end

--拿到第一个未完成星灵的下标
---@return int 下标
function UIExtraMissionDetailController:GetPetListViewIndex()
    local index = 1
    for i = 1, #self._extraMissionIDList do
        local state = self._module:UI_GetExtMissionState(self._extraMissionIDList[i])
        if state ~= 3 then
            index = i
            return index
        end
    end
    return 1
end

--通过关卡id获取下标
function UIExtraMissionDetailController:GetStageIndex(stageid)
    if self._extraMissionID ~= 0 then
        local stages = self._cfg_extra_mission[self._extraMissionID].ExtTaskList
        for i = 1, #stages do
            if stages[i] == stageid then
                return i
            end
        end
    end
    return 1
end

--通过章节id获取下标
function UIExtraMissionDetailController:GetRextraMissionIdex(id)
    for i = 1, #self._extraMissionIDList do
        if self._extraMissionIDList[i] == id then
            return i
        end
    end
    return 1
end

function UIExtraMissionDetailController:OnHide()
    self._extraMissionScrollView:Dispose()
end

--初始化两个列表
function UIExtraMissionDetailController:InitExtraMissionList()
    --上方list
    self._extraMissionScrollView =
        H3DScrollViewHelper:New(
        self,
        "ExtraMissionscrollView",
        "UIExtraMissionDetailItem",
        function(index, uiwidget)
            return self:OnShowItemUp(index, uiwidget)
        end,
        nil
    )
    self._extraMissionScrollView:SetGroupChangedCallback(
        function(index, item)
            self:ShowItemDataUp(index + 1)
        end
    )

    local safeArea = self:GetUIComponent("RectTransform", "SafeArea")

    self._extraMissionScrollView:Init(self._extraMissionIDCount, self._extraMissionIndex, safeArea.rect.size)

    local hor = self:GetUIComponent("UISelectObjectPath", "headerPool")
    hor:SpawnObjects("UIExtraMissionPetHeaderItem", #self._extraMissionIDList)
    ---@type UICustomWidget[]
    local hors = hor:GetAllSpawnList()
    ---@type UIExtraMissionPetHeaderItem[]
    self._downItemsPool = {}
    for i = 1, #hors do
        table.insert(self._downItemsPool, hors[i])
        self:OnShowItemDown(i, hors[i])
    end

    local horGo = self:GetGameObject("headerPool")
    local scro = horGo.transform.parent.parent
    local scrollWidth = scro.rect.width

    local width = horGo:GetComponent("RectTransform").rect.width

    if width < scrollWidth then
        horGo:GetComponent("ContentSizeFitter").enabled = false
        horGo:GetComponent("RectTransform").sizeDelta = Vector2(scro.rect.width, 200)
        horGo:GetComponent("HorizontalLayoutGroup").childAlignment = UnityEngine.TextAnchor.MiddleCenter
    else
        horGo:GetComponent("ContentSizeFitter").enabled = true
        horGo:GetComponent("HorizontalLayoutGroup").childAlignment = UnityEngine.TextAnchor.MiddleLeft
    end
end

--下方列表赋值
function UIExtraMissionDetailController:OnShowItemDown(index, uiwidget)
    uiwidget:SetData(
        index,
        self._extraMissionIDList[index],
        function(index)
            self:ItemClickDown(index)
        end
    )
end

--改变上方列表得currentIndex
function UIExtraMissionDetailController:ChangeUpListState()
    self._extraMissionScrollView:MovePanelToIndex(self._extraMissionIndex)
end

--上方列表滑动改变当前章节
function UIExtraMissionDetailController:ShowItemDataUp(index)
    if index == self._extraMissionIndex then
        return
    end
    self._extraMissionID = self._extraMissionIDList[index]
    self._extraMissionIndex = index

    self:SelectDownItem()

    self:CheckArrowState()

    local bg = self._cfg_extra_mission[self._extraMissionID].ExtMissionBigImg
    self._bg:LoadImage(bg)
end

--改变下方列表得currentIndex
function UIExtraMissionDetailController:SelectDownItem()
    self._downItemsPool[self._downOldIdx]:Select(false)
    self._downItemsPool[self._extraMissionIndex]:Select(true)
    self._downOldIdx = self._extraMissionIndex
end

--下方列表的点击
function UIExtraMissionDetailController:ItemClickDown(index)
    if index == self._extraMissionIndex then
        return
    end

    self._extraMissionID = self._extraMissionIDList[index]
    self._extraMissionIndex = index
    self:SelectDownItem()

    self:ChangeUpListState()

    self:CheckArrowState()

    local bg = self._cfg_extra_mission[self._extraMissionID].ExtMissionBigImg
    self._bg:LoadImage(bg)
end

--打开关卡详情
function UIExtraMissionDetailController:OpenStageDetail(stageId)
    self:SwitchState(UIStateType.UIExtraMissionStage, self._extraMissionID, stageId)
end

--获取全部章节列表
function UIExtraMissionDetailController:GetAllExtraMissionID()
    local time_mod = GameGlobal.GameLogic():GetModule(SvrTimeModule)
    if time_mod == nil then
        Log.error("UAReportForceGuideEvent time_mod == nil")
        return
    end
    local servertime = math.floor(time_mod:GetServerTime() / 1000)
    if self._cfg_extra_mission then
        local index = 1
        for key, value in HelperProxy:GetInstance():pairsByKeys(self._cfg_extra_mission) do
            local timestamp = 0
            if value.UnlockTime then
                -- local _, _, y, m, d, _hour, _min, _sec =
                --     string.find(value.UnlockTime, "(%d+)-(%d+)-(%d+)%s*(%d+):(%d+):(%d+)")
                --转化为时间戳
                timestamp = LoginModule:GetTimeStampByTimeStr(value.UnlockTime, Enum_DateTimeZoneType.E_ZoneType_GMT)
            -- timestamp = os.time({year = y, month = m, day = d, hour = _hour, min = _min, sec = _sec})
            end
            if servertime >= timestamp or value.UnlockTime == nil then
                self._extraMissionIDList[index] = key
                index = index + 1
            end
        end
    end
end

--上方列表Item赋值
function UIExtraMissionDetailController:OnShowItemUp(index, item)
    local extraMissionID = self._extraMissionIDList[index]
    local callback = function(idx)
        self:UpListItemClick(idx)
    end

    ---@param index int 下标
    ---@param extraMissionID int 副本ID
    ---@param callback function 副本点击
    item:SetData(index, extraMissionID, callback)
    table.insert(self.items, item)
end

--上方列表的章节点击事件
function UIExtraMissionDetailController:UpListItemClick(idx)
    if self._extraMissionIndex == idx then
        local state
        local key = tostring(GameGlobal.GameLogic():GetOpenId()) .. tostring(self._extraMissionID)

        local newState = UnityEngine.PlayerPrefs.HasKey(key)
        local newValue = UnityEngine.PlayerPrefs.GetInt(key)
        if newState and newValue == 1 then
            state = EnumExtMissionState.New
        else
            state = self._module:UI_GetExtMissionState(self._extraMissionID)
        end

        if state == EnumExtMissionState.Disable then
            local tipStr = ""
            local res, args = self._module:UI_GetLockReason(self._extraMissionID)
            ---@type EnumLockReason
            if res == EnumLockReason.Lock_error then
                tipStr = "UpListItemClick --> res == EnumLockReason.Lock_error !"
            elseif res == EnumLockReason.Lock_extTask then --番外
                --先根据关卡id取副本id
                local _extraMisionID
                local _cfg_extMission = Cfg.cfg_extra_mission {}
                if _cfg_extMission then
                    for key, value in pairs(_cfg_extMission) do
                        for i = 1, table.count(value.ExtTaskList) do
                            if value.ExtTaskList[i] == args then
                                _extraMisionID = key
                                break
                            end
                        end
                        if _extraMisionID then
                            break
                        end
                    end
                end
                local extraMissionCfg = Cfg.cfg_extra_mission[_extraMisionID]
                if extraMissionCfg then
                    local stageCount = table.count(extraMissionCfg.ExtTaskList)
                    tipStr =
                        StringTable.Get("str_extra_mission_public_depend_extra_mission_task") ..
                        StringTable.Get(extraMissionCfg.ExtMissionName) ..
                            StringTable.Get("str_extra_mission_stage_index_" .. stageCount)
                    StringTable.Get("str_extra_mission_public_depend_behind")
                end
            elseif res == EnumLockReason.Lock_level then --等级
                if args then
                    tipStr = args .. StringTable.Get("str_extra_mission_public_depend_level")
                end
            elseif res == EnumLockReason.Lock_mission then --主线
                local missionCfg = Cfg.cfg_mission[args]
                if missionCfg then
                    tipStr =
                        StringTable.Get("str_extra_mission_public_depend_mission_task") ..
                        missionCfg.Chapter[1] ..
                            "-" .. missionCfg.Chapter[2] .. StringTable.Get("str_extra_mission_public_depend_behind")
                end
            else
                tipStr = StringTable.Get("str_extra_mission_public_chapter_is_lock")
                Log.fatal("###[uiextmission] - other state ..." .. res)
            end
            ToastManager.ShowToast(tipStr)
        elseif state == EnumExtMissionState.New then
            local key = tostring(GameGlobal.GameLogic():GetOpenId()) .. tostring(self._extraMissionID)

            if UnityEngine.PlayerPrefs.HasKey(key) then
                local newValue = UnityEngine.PlayerPrefs.GetInt(key)
                if newValue == 1 then
                    self._module:UI_ClearNewExtMission(self._extraMissionID)
                    UnityEngine.PlayerPrefs.SetInt(key, 0)
                    self:ChangeDownListNewState()
                end
            end

            self:OpenStageDetail()
        else
            self:OpenStageDetail()
        end
    end
end

--取消下方列表item得new
function UIExtraMissionDetailController:ChangeDownListNewState()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HideNew, self._extraMissionID)
end

function UIExtraMissionDetailController:leftArrowBtnOnClick()
    local idx = self._extraMissionIndex - 1
    if idx > 0 then
        self:ItemClickDown(idx)
    end
end
function UIExtraMissionDetailController:rightArrowBtnOnClick()
    local idx = self._extraMissionIndex + 1
    if idx <= #self._extraMissionIDList then
        self:ItemClickDown(idx)
    end
end

--初始化数据
function UIExtraMissionDetailController:Constructor()
    self._extraMissionIndex = 0
end

-----------------------------------------------------------------------------------------------
--获取关卡所属的章节
function UIExtraMissionDetailController:GetExtraMissionByStageID(stageID)
    for i = 1, #self._extraMissionIDList do
        local ext = self._cfg_extra_mission[self._extraMissionIDList[i]]
        if ext then
            for j = 1, #ext.ExtTaskList do
                if ext.ExtTaskList[j] == stageID then
                    return i
                end
            end
        end
    end
    return 0
end

function UIExtraMissionDetailController:GetItem(index)
    return self.items[index] and self.items[index]:GetGameObject("bg")
end

function UIExtraMissionDetailController:GetScroll()
    return self:GetUIComponent("ScrollRect", "ExtraMissionscrollView")
end
