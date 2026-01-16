---迷失之地UIMODULE
---@class UILostLandModule:UIModule
_class("UILostLandModule", UIModule)
UILostLandModule = UILostLandModule

function UILostLandModule:Dispose()
end
function UILostLandModule:Constructor()
    self._module = GameGlobal.GetModule(LostAreaModule)

    self._nextTime = 0

    --暂定5个
    self._pet_award_count = 5

    ---@type UILostLandFilterType
    self._filterType = UILostLandFilterType.OR

    ---@type UILostLandEnterData
    self._currentEnterData = nil

    self:CreateConditionFunc()
end

--推荐奖励最大数量
function UILostLandModule:GetPetAwardCount()
    return self._pet_award_count
end
--推荐奖励
---@return RoleAsset
function UILostLandModule:GetPetAwardInfo()
    return self._recommend_reward
end
--当前选择的难度
function UILostLandModule:GetCurrentEnterData()
    return self._currentEnterData
end

--初始化难度数据
function UILostLandModule:InitEnterData()
    ---@type UILostLandEnterData[]
    self._enterList = {}
    self._enter_cfg_map = self._module:GetLostAreaDesignConfig()
    self._level_cfg_map = self._module:GetLostAreaLevelGroupConfig()
    self._nextTime, self._enterStatusMap = self._module:GetDifficultyStatusData()
    self:CreateEnterData()

    for key, value in pairs(self._enter_cfg_map) do
        self._recommend_reward = value.recommend_reward
        self._recommendList = value.recommend_cond
    end
end

function UILostLandModule:CreateEnterData()
    for id, status in pairs(self._enterStatusMap) do
        local cfg = self._enter_cfg_map[id]
        local enterData = UILostLandEnterData:New(id, status, cfg, self._level_cfg_map)
        table.insert(self._enterList, enterData)
    end
    table.sort(
        self._enterList,
        function(a, b)
            return a:GetType() < b:GetType()
        end
    )
end

--region 创建关卡数据
---@param missionStatusMap table<number,MissionInfo>
function UILostLandModule:CreateMissionMap(missionStatusMap)
    Log.debug("###[UILostLandModule] 创建关卡数据")
    ---@type table<number,UILostLandMissionData>
    self._missionMap = {}
    self._currentStageID = nil

    local enterData = self:GetCurrentEnterData()
    local missionTable = enterData:GetMissionTable()
    for i = 1, #missionTable do
        local group = missionTable[i]
        for j = 1, #group do
            local missionid = group[j]
            local info = missionStatusMap[missionid]
            if not self._currentStageID then
                if info.pass_time <= 0 then
                    self._currentStageID = missionid
                end
            end

            local missionData = self:CreateMissionDataByMissionID(missionid, info, self._currentStageID)
            self._missionMap[missionid] = missionData
        end
    end
    if not self._currentStageID then
        --全部通关那最后一个
        local group = missionTable[#missionTable]
        local stage = group[#group]
        self._currentStageID = stage
    end
end
---@param missionInfo MissionInfo
function UILostLandModule:CreateMissionDataByMissionID(missionid, missionInfo, currentid)
    local cfg = self:GetLevelCfgByID(missionid)
    local missionData = UILostLandMissionData:New(missionid, cfg, missionInfo, currentid)
    return missionData
end
function UILostLandModule:GetCurrentStageID()
    return self._currentStageID
end
--endregion

--region 选择难度
--选择了难度
function UILostLandModule:ChooseEnter(enterData)
    GameGlobal.UIStateManager():Lock("UILostLandModule:ChooseEnter")
    GameGlobal.TaskManager():StartTask(self._OnChooseEnter, self, enterData)
end
function UILostLandModule:_OnChooseEnter(TT, enterData)
    local enterid = enterData:GetEnterID()
    local res = self._module:RequestLostAreaChooseWeekDifficulty(TT, enterid)
    GameGlobal.UIStateManager():UnLock("UILostLandModule:ChooseEnter")
    if res:GetSucc() then
        --成功，先创建关卡数据，再进入关卡界面
        local missionStatusMap = self._module:GetLostAreadifficultyMission()
        self._currentEnterData = enterData
        self:CreateMissionMap(missionStatusMap)
        GameGlobal.UIStateManager():SwitchState(UIStateType.UILostLandStage)
    else
        Log.error("###[UILostLandModule] UILostLandModule:_OnChooseEnter fail ! result --> ", res:GetResult())
    end
end

--endregion

--region 时间重置相关
--重置时间到
---@param resetDialog UILostLandResetTimeDialog 从哪个界面重置的
function UILostLandModule:ResetTime(resetDialog)
    GameGlobal.UIStateManager():Lock("UILostLandModule:ResetTime")
    GameGlobal.TaskManager():StartTask(self._OnResetTime, self, resetDialog)
end
function UILostLandModule:_OnResetTime(TT, resetDialog)
    local res = self._module:RequestLostAreadifficultyStatus(TT)
    GameGlobal.UIStateManager():UnLock("UILostLandModule:ResetTime")
    if res:GetSucc() then
        self:InitEnterData()
        self:ResetTimeEvent(resetDialog)
    else
        Log.error("###[UILostLandModule] RequestLostAreadifficultyStatus fail ! result --> ", res:GetResult())
    end
end
function UILostLandModule:ResetTimeEvent(resetDialog)
    if resetDialog == UILostLandResetTimeDialog.Main then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnLostLandTimeReset)
    elseif resetDialog == UILostLandResetTimeDialog.Stage then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UILostLandMain, true)
    elseif resetDialog == UILostLandResetTimeDialog.BattleEnd then
        GameGlobal.UIStateManager():SwitchState(UIStateType.UILostLandMain, true)
    end
end
--重置剩余时间
function UILostLandModule:GetResetTime()
    return self._nextTime
end
--endregion

--时间转文本
function UILostLandModule:Time2Tex(sec)
    local timeStr = ""
    local minAll = sec // 60
    local min = minAll % 60
    local hourAll = minAll // 60
    local hour = hourAll % 24
    local day = hourAll // 24
    if day and day > 0 then
        timeStr = StringTable.Get("str_lost_land_reset_time_day_and_hour", day, hour)
        return timeStr
    end
    if hour and hour > 0 then
        timeStr = StringTable.Get("str_lost_land_reset_time_hour_and_min", hour, min)
        return timeStr
    end
    if min and min > 0 then
        timeStr = StringTable.Get("str_lost_land_reset_time_only_min", min)
        return timeStr
    end
    timeStr = StringTable.Get("str_lost_land_reset_time_only_sec")
    return timeStr
end

--进入玩法界面,放在module中，因为不确定切哪个界面，但是都要请求数据，所以不在界面获取数据，在这里统一处理
--region 进入玩法界面
function UILostLandModule:SwitchState()
    GameGlobal.UIStateManager():Lock("UILostLandModule:SwitchState")
    GameGlobal.TaskManager():StartTask(self._OnSwitchState, self)
end
function UILostLandModule:_OnSwitchState(TT)
    local res = self._module:RequestLostAreadifficultyStatus(TT)
    GameGlobal.UIStateManager():UnLock("UILostLandModule:SwitchState")
    if res:GetSucc() then
        self:InitEnterData()
        --获取完数据，判断进哪个界面
        self:_ShowDialog()
    else
        Log.error(
            "###[UILostLandModule] self._module:RequestLostAreadifficultyStatus fail ! result --> ",
            res:GetResult()
        )
    end
end
function UILostLandModule:_ShowDialog()
    local choose = false
    for key, value in pairs(self._enterStatusMap) do
        --如果已经选择了,进关卡，否则进主界面
        if value == DifficultyStatus.DS_ThisWeekChoosed then
            self._currentEnterData = self:GetEnterDataByID(key)
            choose = true
            break
        end
    end
    if choose then
        --如果进关卡还需要请求一下关卡的通关数据
        GameGlobal.UIStateManager():Lock("UILostLandModule:_ShowDialog")
        GameGlobal.TaskManager():StartTask(self._OnShowDialog, self)
    else
        GameGlobal.UIStateManager():SwitchState(UIStateType.UILostLandMain)
    end
end
function UILostLandModule:_OnShowDialog(TT)
    local currentid = self._currentEnterData:GetEnterID()
    local res = self._module:RequestLostAreadifficultyMission(TT, currentid)
    GameGlobal.UIStateManager():UnLock("UILostLandModule:_ShowDialog")
    if res:GetSucc() then
        ---@type table<number,MissionInfo>
        local missionStatusMap = self._module:GetLostAreadifficultyMission()
        self:CreateMissionMap(missionStatusMap)
        GameGlobal.UIStateManager():SwitchState(UIStateType.UILostLandStage)
    else
        Log.error(
            "###[UILostLandModule] self._module:RequestLostAreadifficultyStatus fail ! result --> ",
            res:GetResult()
        )
    end
end
--endregion

--获取玩法数据
function UILostLandModule:GetEnterDataByID(id)
    if self._enterList and #self._enterList then
        for i = 1, #self._enterList do
            local enterData = self._enterList[i]
            local enterid = enterData:GetEnterID()
            if enterid == id then
                return enterData
            end
        end
    end
end

--获取难度配置
function UILostLandModule:GetEnterCfgByID(id)
    local enterCfg = self._enter_cfg_map[id]
    return enterCfg
end
--获取难度数据
function UILostLandModule:GetEnterData()
    return self._enterList
end
--获取关卡数据
function UILostLandModule:GetMissionDataByMissionID(missionid)
    return self._missionMap[missionid]
end
--获取关卡配置
function UILostLandModule:GetLevelCfgByID(stageid)
    return self._level_cfg_map[stageid]
end

--删除数据
function UILostLandModule:DeleteData()
end

--region 本周星灵条件相关
--获取推荐条件，判断一个星灵是否符合
function UILostLandModule:CheckPetRecommend(pstid)
    if self._recommendList and table.count(self._recommendList) > 0 then
        if not self._petModule then
            self._petModule = GameGlobal.GetModule(PetModule)
        end
        ---@type Pet
        local pet = self._petModule:GetPet(pstid)

        for i = 1, #self._recommendList do
            local innerOne = false

            local recommend = self._recommendList[i]
            local condition = recommend.cond1
            local filter = recommend.cond2
            innerOne = self._conditionFunc[condition](filter, pet)

            if self._filterType == UILostLandFilterType.OR then
                if innerOne then
                    return true
                end
            elseif self._filterType == UILostLandFilterType.AND then
                if not innerOne then
                    return false
                end
            end
        end

        if self._filterType == UILostLandFilterType.OR then
            return false
        elseif self._filterType == UILostLandFilterType.AND then
            return true
        end
    else
        Log.error("###[UILostLandModule] self._recommendList is nil or empty !")
    end
end

function UILostLandModule:GetRecommendConditionList()
    return self._recommendList
end

--筛选器
function UILostLandModule:CreateConditionFunc()
    self._conditionFunc = {}
    self._conditionFunc[PetFilterCondType.RFCT_Color] = function(filterColor, pet)
        if not pet then
            return false
        end
        local petColor = pet:GetPetFirstElement()
        if petColor == filterColor then
            return true
        end
        return false
    end
    self._conditionFunc[PetFilterCondType.RFCT_Force] = function(filterForce, pet)
        if not pet then
            return false
        end
        local petTags = pet:GetPetTags()
        for i = 1, #petTags do
            local tag = petTags[i]
            if tag == filterForce then
                return true
            end
        end
        return false
    end
    self._conditionFunc[PetFilterCondType.RFCT_Prof] = function(filterProf, pet)
        if not pet then
            return false
        end
        local petProf = pet:GetProf()
        if petProf == filterProf then
            return true
        end
        return false
    end
end
--endregion

--从哪里重置的
---@class UILostLandResetTimeDialog
local UILostLandResetTimeDialog = {
    Main = 1,
    Stage = 2,
    BattleEnd = 3
}
_enum("UILostLandResetTimeDialog", UILostLandResetTimeDialog)
