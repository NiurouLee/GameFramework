--region dc define

--- @class NotifyObjectType
local NotifyObjectType = {
    NOT_INVALID = 0,
    NOT_PLAYER = 1,
    NOT_MATCH = 2,
}
_enum("NotifyObjectType", NotifyObjectType)

--- @class NotifyInfoType
local NotifyInfoType = {
    NT_ServerStart = 0, --服务器启动完成
    NT_ModuleUnlock = 1, --解锁功能
    NT_RoleLogin = 2, --登录
    NT_RoleLogout = 3, --登出
    NT_RoleLevelUp = 4, --角色升级
    NT_PlayerShare = 5, --分享
    NT_AddItem = 6, --获得物品
    NT_DelItem = 7, --消耗物品
    NT_AddPet = 8, --获得星灵
    NT_AddRelic = 9, --获得圣物
    NT_QuestGrowthDay = 10, --成长任务天数变更
    NT_QuestComplete = 11, --完成任务
    NT_QuestTaken = 12, --完成任务且领奖
    NT_QuestConfigUpdate = 13, --任务配置更新
    NT_QuestVigPoint = 14, --任务活跃度
    NT_QuestAchPoint = 15, --任务成就点
    NT_CHAT = 16, --聊天
    NT_AirRoomLevelUp = 17, --风船升级
    NT_AirRoomCollect = 18, --风船收集物品
    NT_AirFireflySpeedUp = 19, --风船萤火加速
    NT_AirPhyPoint2Firefly = 20, --风船兑换萤火
    NT_PetLevelUp = 21, --星灵升级
    NT_PetGradeUp = 22, --星灵突破
    NT_PetAwakeUp = 23, --星灵觉醒
    NT_PetAffinityUp = 24, --星灵好感度升级
    NT_PetEnterAirRoom = 25, --星灵入驻
    NT_PetInteract = 26, --星灵交互
    NT_PetGivePresent = 27, --星灵送礼
    NT_Gamble = 28, --抽卡
    NT_ShopBuy = 29, --商店购买
    NT_Story = 30, --完成剧情
    NT_BattleEnd = 31, --战斗结算
    NT_MissionWin = 32, --主线关结算
    NT_ExtMissionWin = 33, --番外结算
    NT_ResDungeonWin = 34, --资源本结算
    NT_MazeWin = 35, --迷宫结算
    NT_MazeRest = 36, --使用休息室
    NT_ChangeGuider = 37, --更换一次看板娘
    NT_TowerWin = 38, -- 尖塔
    NT_SYNC_PLAYERDATA = 39,
    NT_PLAYER_CHOOSE_ROLE = 40, -- 选择角色结束
    NT_FIRST_PASS_MISSION = 41, -- 首通主线关卡
    NT_COMPLETE_STORY_EVENT = 42, -- 完成随机剧情
    NT_COMPLETE_QUEST_CHAT = 43, -- 完成终端
    NT_AIRCRAFT_TOUCH_PET = 44, -- 摸了星灵一下
    NT_ClearHeadImageLock = 45, -- 头像解锁
    NT_AmendRoleName = 46, -- 玩家改名
    NT_AircraftUpdateAmusement = 47, -- 风船娱乐区升级
    NT_QuestCondRoleLogin = 48, -- 任务条件登录类刷新 可以是玩家持续在线过了节点时间时记为一次登录
    NT_FriendListUpdate = 49, -- 好友列表发生变更
    NT_MAZE_RESET = 50, -- 秘境重置
    NT_HELP_PET_ADD = 51, -- 增加上阵星灵
    NT_HELP_PET_HELP = 52, -- 有人用了我的助战星灵
    NT_RefreshFriendList = 53, -- 通知刷新一下好友列表(目前用在上线时检查好友数量有没有变多 刷新任务状态)
    NT_PetEquipUp = 54, -- 星灵装备等级升级
    NT_ItemSmelt = 55, -- 道具熔炼
    NT_DispatchFinish = 56, -- 派遣完成
    NT_AmbientUpdate = 57, -- 氛围值变更
    NT_AddBook = 58, -- 增加书籍
    NT_PresentPet = 59, -- 星灵给玩家送礼
    NT_VisitPet = 60, -- 星灵拜访风船
    NT_ItemSubmit = 61, -- 提交物品计数
    NT_TaleTaskCFGUpdate = 62, -- 传说光灵任务配置更新
    NT_MissionVictoryCostPower = 63, -- 关卡胜利消耗体力
    NT_CamMissionWin = 64, -- 活动关卡胜利
    NT_StageCostPoint = 65, -- 关卡真正消耗的体力
    NT_CampaignStory = 66, -- 完成活动剧情
    NT_Lottery = 67, -- 活动扭蛋
    NT_CampaignCostPoint = 68, -- 活动关卡消耗体力
    NT_ChangeDayTime = 69, -- 已经达到了ChangeDayTime
    NT_UNLOCK_ADVANCED_REWARD = 70, -- 解锁精英版奖励
    NT_CAM_MISSION_WIN_AFFIX = 71, -- 使用词条通关活动关卡
    NT_BUY_CAMP_GIFT = 72, -- 直购BP系统礼包
    NT_CAM_MINI_GAME_SCORE = 73, -- 刨冰小游戏关卡积分更新
    NT_CAM_SUMMER_II_SCORE = 74, -- 夏活二关卡积分更新
    NT_UNLOCK_BP = 75, -- 激活BP
    NT_CAM_RES_HELP_DEC = 76, -- 减少助力次数
    NT_AP_COST = 77, -- 行动点消耗 
    NT_ARRIVE_TIME = 78, -- 到达时间 
    NT_CAM_BUILD = 79, --  重建
    NT_WorldBossLevel = 80, -- 世界BOSS段位
    NT_WorldBossMatchEnd = 81, -- 参与世界boss
    NT_CAM_CHALLENGE_MISSION_SCORE = 82, -- N12挑战关卡积分更新
    NT_PetSkinUnlockCG = 83, -- 光灵皮肤剧情解锁
    NT_Dormitory_Pet_CheckIn = 84, --光灵入住宿舍
    NT_Dormitory_Pet_CheckOut = 85, --光灵离开宿舍
    NT_HomeLandArchUpdate = 86, --家园建筑数据发生变化
    NT_HomeLandFinishChatId = 87, -- 星灵完成某段对话
    NT_HomeLandFinishEvent = 88, -- 完成某个家园事件
    NT_HomeLandFishing = 89, -- 钓到鱼
    NT_HomeLandFell = 90, -- 砍树
    NT_HomeLandMining = 91, -- 挖矿
    NT_HomeLandMakingFurniture = 92, -- 制作家具
    NT_HomeLandPickUpTree = 93, -- 收获奇异树
    NT_HomeLandExpChange = 94, -- 家园经验变化
    NT_HomeLandPutArch = 95, -- 家园放置建筑
    NT_HomeLandTreasure = 96, -- 家园挖宝
    NT_HomeLandShopping = 97, -- 家园购物
    NT_HomeLandCost = 98, -- 家园消耗代币
    NT_HomeLandOrder = 99, -- 家园下订单
    NT_HomeLandPutFish = 100, -- 家园放置鱼
    NT_HomeLandPutCoins = 101, -- 家园投许愿币
    NT_HomeLandSign = 102, -- 家园签到
    NT_HomeLandTalkPets = 103, -- 家园光灵对话
    NT_HomeLandDairy = 104, -- 家园完成日记簿
    NT_HomeLandDormitoryPets = 105, -- 家园入驻光灵
    NT_HomeLandPlantTree = 106, -- 家园种植奇异树
    NT_HomeLandTaskUpdate = 107, -- 家园主任务变更
    NT_DifficultyMissionEnd = 108, --困难关卡matchend
    NT_ChallengeFishingEnd = 109, --挑战钓鱼结束更新任务计数
    NT_HomeLandGroupTaskStory = 110, -- 家园任务组任务观看剧情
    NT_HomeLandAddDrawing = 111, -- 家园活动图纸
    NT_CampaignReviewProgress = 112, -- 活动回顾积分点进度
    NT_CampaignReviewCfgUpdate = 113, -- 回顾活动相关配置更新
    NT_CampaignAVGComplateEnding = 114, -- avg活动完成某个结局
    NT_CampaignAVGChooseManual = 115, -- avg活动选择了某选项
    NT_FinishTaskAction = 116, -- 主动任务完成产生的行为
    NT_CleanHangPoint = 117, -- 清理主建筑挂点
    NT_SailingMissionEnd = 118, --大航海关卡matchend
    NT_TaskGroupReward = 119, --任务组领取奖励
    NT_HomeLandNoUnlockArch = 120, --建筑没有解锁
    NT_AirRoomLevelDown = 121, --风船降级
    NT_ConditionComplete = 122, --通用条件达成
    NT_ConditionCfgUpdate = 123, --通用条件相关配置更新
    NT_ConditionAccept = 124, --通用条件接收成功
    NT_ConditionProgressUpdate = 125, --通用条件进度更新
    NT_QuestProgressUpdate = 126, --通用条件进度更新
    NT_WorldBossLevelUp = 127, --世界BOSS段位升级
    NT_UIMainLobbyOnShow = 128, --客户端登陆完成
    NT_SailingGetReward = 129, --领取大航海层数奖励
    NT_MedalReward = 130, --获取勋章
    NT_BloodsuckerMatchEnd = 131, --吸血鬼关卡结算
    NT_IdolRoundUpdate = 132, --偶像养成回合变更
    NT_IdolCompleteEnding = 133, --偶像养成完成结局
    NT_IdolCompleteEvent = 134, --偶像养成完成约定事件
    NT_CampaignRefreshDay = 135, --活动登录天数刷新 
    NT_ComponentRefreshDay = 136, -- 活动组件登录天数刷新 
    NT_PostStationSubmitOrder = 137, --驿站提交订单
    NT_DetectiveSubmitEnding = 138, --侦探游戏提交结局
    NT_DetectiveSubmitItem = 139, --侦探游戏提交道具（线索，碎片）
    NT_QuestWeekPoint = 140, --周活跃变更
    NT_PetEquipRefineLvUp = 141, -- 星灵装备精炼等级升级
    NT_ObtainPhoto = 142, --获得家园图鉴
    NT_CampaignEntrustCompleteEvent = 143, --委托小游戏完成事件
    NT_PopstarMatchEnd = 144, --消灭星星关卡结算
    NT_ClientCountQuest = 145, --客户端计数类任务
    NT_CampainMission = 146, --/赛季关卡
    NT_EightPetsMissionProfLimit = 147, --八人玩法编队上阵某职业数量
    NT_SimulationOperationUpgradeArch = 148, --升级模拟经营建筑
    NT_SurveyCompleteEvent = 149, --调查玩法事件更新
    --！！！！！！！在上面加，记得改改下面的数字！！！！！！！！！！

    --！！！！！！改下面！！！！改下面！！！改下面！！！！！改下面！！！
    NT_Count = 150, -- 总数
    NT_All = 151, -- 监听全部通知d
}
_enum("NotifyInfoType", NotifyInfoType)

-- 家园任务组任务观看掩码
--- @class HomeLandGroupTaskStoryMask
local HomeLandGroupTaskStoryMask = {
    HomeLandGroupTaskStoryMask_None = 0x00, -- 没观看剧情
    HomeLandGroupTaskStoryMask_Before = 0x01, -- 前置剧情
    HomeLandGroupTaskStoryMast_After = 0x02, -- 后置剧情
}
_enum("HomeLandGroupTaskStoryMask", HomeLandGroupTaskStoryMask)

--region INotifyInfo define
---@class INotifyInfo:Object
_class("INotifyInfo",Object)
INotifyInfo = INotifyInfo

 function INotifyInfo:Constructor()
    self.player_id = 0
end
--region dc custom INotifyInfo
--endregion dc custom INotifyInfo
---@private
INotifyInfo._proto = {
    [1] = {"player_id", "int64"},
}
--endregion

--region NotifyData define
---@class NotifyData:INotifyInfo
_class("NotifyData",INotifyInfo)
NotifyData = NotifyData

 function NotifyData:Constructor()
    self.obj_type = 0
    self.obj_id = 0
    self.notify_type = 0
    self.class_name = ""
    self.class_data = ""
end
---@private
NotifyData._proto = {
    [1] = {"obj_type", "int"},
    [2] = {"obj_id", "int64"},
    [3] = {"notify_type", "int"},
    [4] = {"class_name", "string"},
    [5] = {"class_data", "buffer"},
}
--endregion

--endregion dc define
