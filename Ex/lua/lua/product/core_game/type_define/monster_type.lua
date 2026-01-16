---@class MonsterType
MonsterType = {
	None = 0,
	Normal = 1,     --普普通通毫无特点的小怪
	Boss = 2,       --Boss
	HitFly = 3,     --击飞小怪
    WorldBoss = 4,  --世界Boss,无限血量
}
_enum("MonsterType", MonsterType)

---@class MonsterBornType
MonsterBornType = MonsterBornType
_enum("MonsterBornType", {
	None = 0,
	Normal = 1,     --普普通通
	AfterFury = 2,       --狂暴后
})
