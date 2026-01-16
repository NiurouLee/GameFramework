--关卡难度数据
_class("UIN9SubjectLevelGradeData", Object)
---@class UIN9SubjectLevelGradeData:Object
UIN9SubjectLevelGradeData = UIN9SubjectLevelGradeData

---@param subjectComponentInfo SubjectComponentInfo
function UIN9SubjectLevelGradeData:Constructor(cfg, subjectComponentInfo)
    self._levelId = cfg.LevelId
    self._grade = cfg.Grade
    self._gradeId = cfg.GradeId
    self._des = StringTable.Get(cfg.Des)
    self._name = StringTable.Get(cfg.Name)
    self._levelType = cfg.LevelType
    self._failedCount = cfg.FailedCount
    self._openType = cfg.OpenType
    self._answerTime = cfg.AnswerTime
    self._rewards = cfg.Reward
    self._positionIndex = cfg.PositionIndex
    local gradeCft = Cfg.cfg_subject_level_grade{ID = self._gradeId}
    self._subjectLibaray = {}
    local library = gradeCft[1].SubjectLibrary
    if library then
        local preMaxIndex = 0
        for i = 1, #library do
            if library[i][1] <= preMaxIndex then
                Log.exception("cfg_subject_level_grade 题库列表配置错误:", self._gradeId)
            else
                for j = library[i][1], library[i][2] do
                    self._subjectLibaray[#self._subjectLibaray + 1] = j
                end
                preMaxIndex = library[i][2]
            end
        end
    end
    self._selectRole = gradeCft[1].SelectRole

    --服务器数据
    self._hasComplete = false
    local rewarded_levels = subjectComponentInfo.rewarded_levels
    for i = 1, #rewarded_levels do
        if rewarded_levels[i].level_id == self._levelId and rewarded_levels[i].grade == self._grade then
            self._hasComplete = true
            break
        end
    end

    local levels = subjectComponentInfo.levels
    self._openTime = 0
    if levels then
        for k, v in pairs(levels) do
            if v.level_id == self._levelId and v.grade == self._grade then
                self._openTime = v.opentime
                if not self._openTime then
                    self._openTime = 0
                end
                break
            end
        end
    end
end

--获取难度
function UIN9SubjectLevelGradeData:GetGrade()
    return self._grade
end

--获取描述
function UIN9SubjectLevelGradeData:GetDes()
    return self._des
end

--获取名字
function UIN9SubjectLevelGradeData:GetName()
    return self._name
end

--获取关卡类型
function UIN9SubjectLevelGradeData:GetLevelType()
    return self._levelType
end

--获取最大失败的次数
function UIN9SubjectLevelGradeData:GetFailedCount()
    return self._failedCount
end

--获取关卡开启类型
function UIN9SubjectLevelGradeData:GetOpenType()
    return self._openType
end

--获取关卡开启时间
function UIN9SubjectLevelGradeData:GetOpenTime()
    return self._openTime
end

--获取关卡奖励
function UIN9SubjectLevelGradeData:GetRewards()
    return self._rewards
end

--获取关卡位置
function UIN9SubjectLevelGradeData:GetPositionIndex()
    return self._positionIndex
end

--关卡是否完成
function UIN9SubjectLevelGradeData:GetHasComplete()
    return self._hasComplete
end

--关卡答题时间
function UIN9SubjectLevelGradeData:GetAnswerTime()
    return self._answerTime
end

--生成题目列表
function UIN9SubjectLevelGradeData:GenSubject()
    local tmpCfgs = {}
    for i = 1, #self._subjectLibaray do
        local cfgs = Cfg.cfg_subject_library{ID = self._subjectLibaray[i]}
        local cfg = cfgs[1]
        local grade = cfg.Grade
        if not tmpCfgs[grade] then
            tmpCfgs[grade] = {}
        end
        tmpCfgs[grade][#tmpCfgs[grade] + 1] = cfg
    end
    local subject = {}
    local preMaxIndex = 0
    for i = 1, #self._selectRole do
        if self._selectRole[i][1] <= preMaxIndex then
            Log.exception("cfg_subject_level_grade 选择规则错误配置错误:", self._gradeId)
        else
            if self._selectRole[i][3] then
                local cfgs = tmpCfgs[self._selectRole[i][3]]
                if #cfgs <= 0 then
                    Log.exception("cfg_subject_level_grade 题目数量不够，策划之前拍过胸脯说题目数量一定会够:", self._gradeId)
                    break
                end
                for j = self._selectRole[i][1], self._selectRole[i][2] do
                    local index = math.random(1, #cfgs)
                    subject[#subject + 1] = UIN9SubjectData:New(cfgs[index])
                    table.remove(cfgs, index)
                    if #cfgs <= 0 then
                        Log.exception("cfg_subject_level_grade 题目数量不够，策划之前拍过胸脯说题目数量一定会够:", self._gradeId)
                        break
                    end
                end
            else
                Log.exception("cfg_subject_level_grade 选择规则错误配置错误:", self._gradeId)
            end
            preMaxIndex = self._selectRole[i][2]
        end
    end
    return subject
end

--关卡数据
_class("UIN9SubjectLevelData", Object)
---@class UIN9SubjectLevelData:Object
UIN9SubjectLevelData = UIN9SubjectLevelData

---@param subjectComponentInfo SubjectComponentInfo
function UIN9SubjectLevelData:Constructor(cfgs, subjectComponentInfo)
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)

    self._historyRecord = subjectComponentInfo.test_score --历史答对的题的数量，只针对测试关有效
    self._gradeLevel = 0 --评级等级，服务器数据，客户端计算，只针对测试关卡有效
    if self._historyRecord ~= nil and self._historyRecord > 0 then
        self._gradeLevel = UIN9Const.GetGradeLevel(self._historyRecord)
    end

    self._levelGrades = {}
    if not cfgs then
        return
    end

    for k, v in pairs(cfgs) do
        local gradeData = UIN9SubjectLevelGradeData:New(v, subjectComponentInfo)
        self._levelGrades[#self._levelGrades + 1] = gradeData
    end

    table.sort(self._levelGrades, function(a, b)
        return a:GetGrade() < b:GetGrade()
    end)
end

--关卡是否解锁
function UIN9SubjectLevelData:IsOpen()
    if #self._levelGrades <= 0 then
        return false
    end

    ---@type UIN9SubjectLevelGradeData
    local levelGradeData = self._levelGrades[1]

    local openType = levelGradeData:GetOpenType()
    
    if openType == 2 then --时间解锁
        local openTime = levelGradeData:GetOpenTime()
        local nowTime = self._timeModule:GetServerTime() / 1000
        if nowTime >= openTime then
            return true
        end
        return false
    end

    return true
end

function UIN9SubjectLevelData:GetOpenTimeStr()
    if #self._levelGrades <= 0 then
        return ""
    end

    local openTime = self._levelGrades[1]:GetOpenTime()
    local nowTime = self._timeModule:GetServerTime() / 1000
    local seconds = math.floor(openTime - nowTime)

    if seconds < 0 then
        seconds = 0
    end  
       
    if seconds == 0 then
        return ""
    end   
    
    local timeStr = ""
    -- 剩余时间超过24小时，显示N天XX小时。
    -- 剩余时间超过1分钟，显示N小时XX分钟。
    -- 剩余时间小于1分数，显示＜1分钟。
    local day = math.floor(seconds / 3600 / 24)
    if day > 0 then
        seconds = seconds - day * 3600 * 24
        local hour = math.floor(seconds / 3600)
        timeStr = StringTable.Get("str_activity_n9_day", day)
        if hour > 0 then
            timeStr = timeStr .. StringTable.Get("str_activity_n9_hour", hour)
        end
    else
        if seconds >= 60 then
            local hour = math.floor(seconds / 3600)
            seconds = seconds - hour * 3600
            if hour > 0 then
                timeStr = StringTable.Get("str_activity_n9_hour", hour)
            end
            local minus = math.floor(seconds / 60)
            if minus then
                timeStr = timeStr .. StringTable.Get("str_activity_n9_minus", minus)
            end
        else
            timeStr = StringTable.Get("str_activity_n9_less_minus")
        end
    end

    return timeStr
end

--获取历史答对的题的数量，只针对测试关有效
function UIN9SubjectLevelData:GetHistoryRecord()
    return self._historyRecord
end

--获取评级等级，服务器数据，客户端计算，只针对测试关卡有效
function UIN9SubjectLevelData:GetGradeLevelStr()
    return UIN9Const.GetGradeLevelStr(self._gradeLevel)
end

--获取位置索引
function UIN9SubjectLevelData:GetPositionIndex()
    if #self._levelGrades <= 0 then
        return -1
    end
    return self._levelGrades[1]:GetPositionIndex()
end

--获取关卡名字
function UIN9SubjectLevelData:GetLevelName()
    if #self._levelGrades <= 0 then
        return ""
    end
    return self._levelGrades[1]:GetName()
end

--获取关卡描述
function UIN9SubjectLevelData:GetDes()
    if #self._levelGrades <= 0 then
        return ""
    end
    return self._levelGrades[1]:GetDes()
end

--获取关卡类型 1：普通关卡 2：测试关卡
function UIN9SubjectLevelData:GetLevelType()
    if #self._levelGrades <= 0 then
        return ""
    end
    return self._levelGrades[1]:GetLevelType()
end

--获取关卡相应难度数据
function UIN9SubjectLevelData:GetLeveGrade(grade)
    local levelType = self:GetLevelType()
    if levelType == 2 then
        return self._levelGrades[1]
    end
    for i = 1, #self._levelGrades do
        if grade == self._levelGrades[i]:GetGrade() then
            return self._levelGrades[i]
        end
    end
    return nil
end

--获取关卡所有难度
function UIN9SubjectLevelData:GetLevelGradeList()
    local gradeList = {}
    for i = 1, #self._levelGrades do
        gradeList[#gradeList + 1] = self._levelGrades[i]:GetGrade()
    end
    return gradeList
end

--获取关卡难度数量
function UIN9SubjectLevelData:GetLevelGradCount()
    local gradeList = self:GetLevelGradeList()
    return #gradeList
end

--获取完成了的难度数量
function UIN9SubjectLevelData:GetCompleteGradeCount()
    local count = 0
    for i = 1, #self._levelGrades do
        if self._levelGrades[i]:GetHasComplete() then
            count = count + 1
        end
    end
    return count
end

--难度是否完成
function UIN9SubjectLevelData:GradeComplete(grade)
    for i = 1, #self._levelGrades do
        if grade == self._levelGrades[i]:GetGrade() then
            return self._levelGrades[i]:GetHasComplete()
        end
    end
    return false
end

function UIN9SubjectLevelData:GetGradeCount()
    return table.count(self._levelGrades)
end

--关卡总数据
_class("UIN9SubjectLevelDatas", Object)
---@class UIN9SubjectLevelDatas:Object
UIN9SubjectLevelDatas = UIN9SubjectLevelDatas

---@param subjectComponentInfo SubjectComponentInfo
function UIN9SubjectLevelDatas:Constructor(subjectComponentInfo)
    self._levels = {}
    local cfgs =  ConfigServiceHelper.GetConfigMessageByAttr(Cfg.cfg_subject_level, "ComponentID",101010208)
    if not cfgs then
        return
    end

    --key: levelid value:{关卡难度配置}
    local levelCfgs = {}
    for k, v in pairs(cfgs) do
        local levelId = v.LevelId
        if not levelCfgs[levelId] then
            levelCfgs[levelId] = {}
        end
        levelCfgs[levelId][#levelCfgs[levelId] + 1] = v
    end

    for k, v in pairs(levelCfgs) do
        local levelData = UIN9SubjectLevelData:New(v, subjectComponentInfo)
        self._levels[#self._levels + 1] = levelData
    end
end

--获取所有关卡数据
function UIN9SubjectLevelDatas:GetLevelDatas()
    return self._levels
end
