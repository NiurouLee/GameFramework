--[[------------------------------------------------------------------------------------------
    BlockFlag 阻挡标记（添加枚举时务必保证为2的整数次幂且唯一）
]] --------------------------------------------------------------------------------------------

---@class BlockFlag
local BlockFlag = {
    None = 0,
    LinkLine = 1 << 1, --阻挡玩家划线
    MonsterLand = 1 << 2, --阻挡陆地怪
    MonsterFly = 1 << 3, --阻挡飞行怪
    DropItem = 1 << 4, --阻挡掉落物
    SkillSkip = 1 << 5, --阻挡技能,仅该位置不受技能影响
    Skill = 1 << 6, --阻挡技能,该位置及之后的位置都不受方向技能影响
    HitBack = 1 << 7, --阻挡击退 MSG57290 深渊不阻挡击退飞行怪 这个标记不再阻挡飞行怪的击退
    SummonTrap = 1 << 8, --阻挡机关生成
    ChangeElement = 1 << 10, --阻挡转色
    Transport = 1 << 11, --阻挡传送带
    FallGrid = 1 << 12, --阻挡格子掉落（掉落格子穿过当前格子）
    MoveBoard = 1 << 13, --阻挡位移地板
    HitBackFly = 1 << 14 --阻挡击退飞行怪
}
_enum("BlockFlag", BlockFlag)

function GetBlockFlagByValue(value)
    ---历史遗留问题：未定义1 << 0，
    ---当配置为0时，本意是None，但却返回了1 << 0
    ---此处统一调整
    if not value or value == 0 then
        return BlockFlag.None
    end

    return 1 << value
end
