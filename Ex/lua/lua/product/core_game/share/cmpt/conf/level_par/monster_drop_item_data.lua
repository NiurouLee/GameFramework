--[[------------------------------------------------------------------------------------------
    MonsterDropItemConfigData : 局内掉落物配置数据
]] --------------------------------------------------------------------------------------------

_class("MonsterDropItemConfigData", Object)
---@class MonsterDropItemConfigData: Object
MonsterDropItemConfigData = MonsterDropItemConfigData

function MonsterDropItemConfigData:Constructor()
end

---玩家拾取类型
function MonsterDropItemConfigData:GetPickupType(dropItemID)
    local dropConfig = Cfg.cfg_monster_drop_item[dropItemID]
    return dropConfig.PickupType
end

---提取掉落的效果类型
function MonsterDropItemConfigData:GetDropEffectType(dropItemID)
    local dropConfig = Cfg.cfg_monster_drop_item[dropItemID]
    return dropConfig.EffectType
end

---提取掉落的效果参数
function MonsterDropItemConfigData:GetDropEffectParam(dropItemID)
    local dropConfig = Cfg.cfg_monster_drop_item[dropItemID]
    return dropConfig.EffectParam
end
