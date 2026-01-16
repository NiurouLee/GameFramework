---剧情出现时机类型
---@class StoryShowType
local StoryShowType = {
	None = 0,
	BeginAfterCreateScene = 1, --关卡开始时，场景出现后
	BeginAfterBoardShow = 2, --关卡开始时，棋盘铺开后
	BeginAfterMonsterShow = 3, --关卡开始时，怪物刷新后
	WaveAndRoundBeginPlayerRound = 4, --特定波次的特定回合玩家行动前
	WaveAndRoundAfterPlayerRound = 5, --特定波次的特定回合玩家行动后,死亡前
	WaveAndRoundBeginMonsterRound = 6, --特定波次的特定回合怪物行动前
	WaveAndRoundAfterMonsterRound = 7, --特定波次的特定回合怪物行动后，死亡前
	AfterAllMonsterDeadBeginExitGame = 8, --关卡结束，怪物死亡退出前
	BeginMonsterShow = 9, --特定怪物出场刷新后
	AfterMonsterDead = 10, --特定怪物死亡,播死亡动画前
	MonsterCastSkill =11, --特定怪物释放技能时
	BeginAfterMasterShowBeginTeamShow= 12,--关卡开始时，队长登场后队员出场前
}
_enum("StoryShowType", StoryShowType)

---@class StoryTipsSpeakerType
local StoryTipsSpeakerType ={
	None=0,
	Pet=1,
	Monster=2,
}
_enum("StoryTipsSpeakerType", StoryTipsSpeakerType)

---@class StoryMonsterShowType
local StoryMonsterShowType={
	None=0,
	AfterShow=1,      ---怪物刷新后
	BeginDeadAnimation=2, ---怪物死亡动画前
}

_enum("StoryMonsterShowType", StoryMonsterShowType)

---@class StoryBannerShowType
local StoryBannerShowType={
	None = 0,
	Normal = 1, ---普通
	HalfPortrait = 2, --薇丝半身像
	HomelandGuide = 3 --家园
}

_enum("StoryBannerShowType", StoryBannerShowType)
