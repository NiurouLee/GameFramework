---赛季玩法关卡数据 战斗关可能会包含两关 普通难度和高难
---@class UISeasonLevelData:Object
_class("UISeasonLevelData", Object)
UISeasonLevelData = UISeasonLevelData

---@param group number
---@param point SeasonMapEventPoint
---@param lineCpt SeasonMissionComponent
function UISeasonLevelData:Constructor(group, point, lineCpt)
    self._groupIdx = group
    local levelCfg = point:GetMissionCfg()
    self._lineCpt = lineCpt

    self._missionID = levelCfg.ID
    --战斗关区分难度 自动补全另一种难度
    if levelCfg.OrderID == UISeasonLevelDiff.Normal then
        self._normalLevel = levelCfg
        -- local cfgs = Cfg.cfg_season_mission { GroupID = self._groupIdx, OrderID = UISeasonLevelDiff.Hard }
        -- if #cfgs ~= 1 then
        --     Log.exception("赛季玩法战斗关难度配置错误,无法获取高难关:", self._groupIdx)
        -- end
        -- self._hardLevel = cfgs[1]
    elseif levelCfg.OrderID == UISeasonLevelDiff.Hard then
        self._hardLevel = levelCfg
        -- local cfgs = Cfg.cfg_season_mission { GroupID = self._groupIdx, OrderID = UISeasonLevelDiff.Normal }
        -- if #cfgs ~= 1 then
        --     Log.exception("赛季玩法战斗关难度配置错误,无法获取普通关:", self._groupIdx)
        -- end
        -- self._normalLevel = cfgs[1]
    else
        Log.exception("赛季玩法战斗关难度配置错误:", levelCfg.ID, levelCfg.OrderID)
    end
    self._awards = {} --通关奖励
end

---普通或战斗关 添加难度
---@param point SeasonMapEventPoint
function UISeasonLevelData:AddDiffLevel(point)
    local levelCfg = point:GetMissionCfg()
    if levelCfg.OrderID == UISeasonLevelDiff.Normal then
        if self._normalLevel then
            Log.exception("赛季玩法战斗关难度配置错误,普通难度重复:", levelCfg.ID)
        end
        self._normalLevel = levelCfg
    elseif levelCfg.OrderID == UISeasonLevelDiff.Hard then
        if self._hardLevel then
            Log.exception("赛季玩法战斗关难度配置错误,高难难度重复:", levelCfg.ID)
        end
        self._hardLevel = levelCfg
    else
        Log.exception("赛季玩法战斗关难度配置错误Add:", levelCfg.ID, levelCfg.OrderID)
    end
end

--默认难度关卡id
function UISeasonLevelData:GetCurMissionID()
    return self._missionID
end

---@param diff UISeasonLevelDiff 该难度关卡配置
function UISeasonLevelData:GetMissionCfgByDiff(diff)
    if diff == UISeasonLevelDiff.Normal then
        return self._normalLevel
    elseif diff == UISeasonLevelDiff.Hard then
        return self._hardLevel
    end
end

---@param diff UISeasonLevelDiff 该难度通关星数
function UISeasonLevelData:GetStarByDiff(diff)
    local id = self:GetMissionCfgByDiff(diff).ID
    return self._lineCpt:GetPassStar(id)
end

---@param diff UISeasonLevelDiff 该难度关卡固定通关奖励
function UISeasonLevelData:GetAwardsByDiff(diff)
    local cfg = self:GetMissionCfgByDiff(diff)
    if not self._awards[diff] then
        local awardCfg = {
            FirstDropId = cfg.FirstDropId and cfg.FirstDropId[1],
            PassFixDropId = cfg.PassFixDropId and cfg.PassFixDropId[1],
            CPassRandomAward = nil,
            ThreeStarDropId = cfg.ThreeStarDropId and cfg.ThreeStarDropId[1]
        }
        self._awards[diff] = UICommonHelper:GetInstance():GetDropByAwardType(AwardType.Pass, awardCfg, true)
    end
    return self._awards[diff]
end

---@param diff UISeasonLevelDiff 该难度是否已通关
function UISeasonLevelData:IsPassDiff(diff)
    local cfg = self:GetMissionCfgByDiff(diff)
    return self._lineCpt:IsPassCamMissionID(cfg.ID)
end

function UISeasonLevelData:CheckUnlock()
    self._isUnlock = self:_FitPreCondition(self._normalLevel.NeedMission) and
        self:_FitPreCondition(self._hardLevel.NeedMission)
end

---是否已经解锁 普通和困难都要满足前置条件
function UISeasonLevelData:IsUnlock()
    return self._isUnlock
end

--是否满足前置条件
function UISeasonLevelData:_FitPreCondition(cond)
    if string.isnullorempty(cond) then
        --不配视为无条件解锁
        return true
    end
    if string.find(cond, "|") then
        --or
        local subConds = string.split(cond, "|")
        for _, c in ipairs(subConds) do
            local missionID = tonumber(c)
            if self._lineCpt:IsPassCamMissionID(missionID) then
                return true --或 任意一个通关即视为满足条件
            end
        end
        return false --全部未通关
    elseif string.find(cond, "&") then
        --and
        local subConds = string.split(cond, "&")
        for _, c in ipairs(subConds) do
            local missionID = tonumber(c)
            if not self._lineCpt:IsPassCamMissionID(missionID) then
                return false --与 任意一个未通关即视为未满足条件
            end
        end
        return true --全部通关
    else
        --不包含逻辑关系符
        local missionID = tonumber(cond)
        return self._lineCpt:IsPassCamMissionID(missionID)
    end
end
