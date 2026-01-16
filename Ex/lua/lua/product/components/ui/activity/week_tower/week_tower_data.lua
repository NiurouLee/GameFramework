
--------------------------通关状态
---@class WeekTowerMissionBattleStatus
local WeekTowerMissionBattleStatus = {
    Pass = 1,--已通关
    Battle = 2,--可打
    Lock = 3 --未解锁
}
_enum("WeekTowerMissionBattleStatus", WeekTowerMissionBattleStatus)

----------------------------难度数据
_class("WeekTowerDiffData", Object)
---@class WeekTowerDiffData:Object
WeekTowerDiffData = WeekTowerDiffData

function WeekTowerDiffData:Constructor(lock,missionList,diff)
    self._lock = lock
    self._misisonList = missionList
    self._diff = diff
    self._sprites = {}
    local sprite1
    local sprite2
    local sprite3

    if diff == WeekTowerDiffEnum.Easy then
        sprite1 = "lose_dificultad_btn03"
        sprite2 = "lose_dificultad_btn02"
        sprite3 = "lose_dificultad_btn01"
        self._name = "str_week_tower_easy"
        self._upColor = "#b1ac96"
    elseif diff == WeekTowerDiffEnum.Normal then
        sprite1 = "lose_dificultad_btn06"
        sprite2 = "lose_dificultad_btn05"
        sprite3 = "lose_dificultad_btn04"
        self._name = "str_week_tower_norm"
        self._upColor = "#797a7f"
    elseif diff == WeekTowerDiffEnum.Diff then
        sprite1 = "lose_dificultad_btn09"
        sprite2 = "lose_dificultad_btn08"
        sprite3 = "lose_dificultad_btn07"
        self._name = "str_week_tower_diff"
        self._upColor = "#867979"
    end
    self._sprites[1] = sprite1
    self._sprites[2] = sprite2
    self._sprites[3] = sprite3
end
function WeekTowerDiffData:MissionList()
    return self._misisonList
end
function WeekTowerDiffData:Lock()
    return self._lock
end
function WeekTowerDiffData:Sprites()
    return self._sprites
end
function WeekTowerDiffData:Name()
    return StringTable.Get(self._name)
end
function WeekTowerDiffData:UpColor()
    return self._upColor
end

----------------------------关卡数据
_class("WeekTowerMissionData", Object)
---@class WeekTowerMissionData:Object
WeekTowerMissionData = WeekTowerMissionData

function WeekTowerMissionData:Constructor(cfg,pass)
    if pass then
        self:SetPassState(WeekTowerMissionBattleStatus.Pass)
    else
        self:SetPassState(WeekTowerMissionBattleStatus.Lock)
    end
    
    local cfg_line_mission = cfg
    self._id = cfg_line_mission.CampaignMissionId

    local cfg_campaign_mission = Cfg.cfg_campaign_mission[self._id]
    if not cfg_campaign_mission then
        Log.error("###[WeekTowerMissionData] cfg_campaign_mission is nil ! id --> ",self._id)
    end

    self._levelid = cfg_campaign_mission.FightLevel
    self._type = cfg_campaign_mission.Type
    self._word = cfg_campaign_mission.BaseWordBuff
    self._award = self:_GetSortedArr(AwardType.First, cfg_campaign_mission, StageAwardType.First)
    --周常塔的名字需要切割开，|，前面是n-m，后面是’训练‘
    local nameStr = cfg.DependName
    if nameStr then
        local nameStrs = string.split(nameStr,"|")
        self._missionName = StringTable.Get(nameStrs[2])
        self._missionName2 = StringTable.Get(nameStrs[1])
    else
        self._missionName = ""
        self._missionName2 = ""
    end
    self._recommendLv = cfg_campaign_mission.RecommendLV
    self._recommendGrade = cfg_campaign_mission.RecommendAwaken

    local params = cfg_line_mission.CustomParams
    if not params or table.count(params) <= 0 then
        Log.error("###[WeekTowerMissionData] CustomParams is nil ! id --> ",self._id)
    end
    self._diff = params[1][1]
    self._groupIdx = params[1][2]
    self._groupInnerIdx = params[1][3]
    if not cfg_line_mission.NodePrefabName then
        Log.error("###[WeekTowerMissionData] NodePrefabName is nil ! id --> ",self._id)
    end
    self._widgetName = cfg_line_mission.NodePrefabName
end
--首通奖励
function WeekTowerMissionData:_GetSortedArr(awardType, cfg, stageAwardType)
    local list = UICommonHelper:GetInstance():GetDropByAwardType(awardType, cfg)
    local vecSort = SortedArray:New(Algorithm.COMPARE_CUSTOM, DiscoveryStage._LessComparer)
    if list then
        for i, v in ipairs(list) do
            local award = Award:New()
            award:InitWithCount(v.ItemID, v.Count, v.Type)
            award:FlushType(stageAwardType)
            vecSort:Insert(award)
        end
    end
    return vecSort.elements
end
function WeekTowerMissionData:GetDiff()
    return self._diff
end
function WeekTowerMissionData:SetPassState(state)
    self._pass = state
end
--状态
function WeekTowerMissionData:GetPassTime()
    return self._pass
end
--战斗id
function WeekTowerMissionData:GetLevelID()
    return self._levelid
end
--关卡类型
function WeekTowerMissionData:GetType()
    return self._type
end
--关卡id
function WeekTowerMissionData:GetID()
    return self._id
end
--词条
function WeekTowerMissionData:GetWord()
    return self._word
end
--奖励
function WeekTowerMissionData:GetAward()
    return self._award
end
--关卡名字
function WeekTowerMissionData:GetMissionName()
    return self._missionName
end
--关卡名字2
function WeekTowerMissionData:GetMissionName2()
    return self._missionName2
end
--推荐等级
function WeekTowerMissionData:GetRecommendLv()
    return self._recommendLv
end
--推荐觉醒等级
function WeekTowerMissionData:GetRecommendGrade()
    return self._recommendGrade
end
--路点上下
function WeekTowerMissionData:GetNodeUpOrDown()
    return self._groupIdx % 2
end
--prefab名字
function WeekTowerMissionData:GetWidgetName()
    return self._widgetName
end

--是否显示竖线，（组内第一个，第一组除外）
function WeekTowerMissionData:ShowLineY()
    local groupIdx = self._groupIdx
    if groupIdx ~= 1 then
        if self._groupInnerIdx == 1 then
            return true
        end
    end
    return false
end
--获取路点icon
function WeekTowerMissionData:GetNodeIcon()
    return self._icon
end
function WeekTowerMissionData:GetNodeIconMask()
    return self._iconMask
end