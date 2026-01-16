--[[------------------------------------------------------------------------------------------
    MonsterDropConfigData : 怪物掉落数据
]] --------------------------------------------------------------------------------------------

---@class MonsterDropConfigData: Object
_class("MonsterDropConfigData", Object)
MonsterDropConfigData = MonsterDropConfigData

function MonsterDropConfigData:Constructor()
end

---提取怪物掉落物ID
---@param dropID number
---@return number
function MonsterDropConfigData:GetMonsterDropItemID(dropID)
    local monsterDropConfig = Cfg.cfg_monster_drop[dropID]
    return monsterDropConfig.DropItem
end

---掉落最小值
function MonsterDropConfigData:GetMonsterDropMinCount(dropID)
    local monsterDropConfig = Cfg.cfg_monster_drop[dropID]
    return monsterDropConfig.MinCount
end

---掉落最大值
function MonsterDropConfigData:GetMonsterDropMaxCount(dropID)
    local monsterDropConfig = Cfg.cfg_monster_drop[dropID]
    return monsterDropConfig.MaxCount
end

---掉落概率
function MonsterDropConfigData:GetMonsterDropProbability(dropID)
    local monsterDropConfig = Cfg.cfg_monster_drop[dropID]
    return monsterDropConfig.Probability
end

