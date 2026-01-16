--[[
    世界boss：段位详情UI数据
]]
---@class DUIWorldBossDanDetailCell
_class("DUIWorldBossDanDetailCell", Object)
---@class DUIWorldBossDanDetailCell:Object
DUIWorldBossDanDetailCell = DUIWorldBossDanDetailCell
function DUIWorldBossDanDetailCell:Constructor(cfg,danInfo)
    self._danCfg = cfg
    ---@type DanInfo
    self._danInfo = danInfo
    self._danId = -1
    if self._danCfg then
        self._danId = self._danCfg.ID
    end
end

---@public
---获取段位id
function DUIWorldBossDanDetailCell:GetDanId()
    return self._danId
end
---@public
---获取段位id
function DUIWorldBossDanDetailCell:GetDanRankLevel()
    if self._danCfg then
        return self._danCfg.RankLevel
    end
end

---@public
---晋级条件
function DUIWorldBossDanDetailCell:GetDanCondition()
    if self._danCfg then
        if self._danCfg.RankLevel > 0 then--传奇
            local topDanName = UIWorldBossHelper.GetDanName(self._danId - 1,0)
            local outStr = StringTable.Get("str_world_boss_dan_detail_lengend_condition",StringTable.Get(topDanName),self._danCfg.RankLevel)
            return outStr
        else
            local outStr = self:_FormatNeedDamageNumStr(self._danCfg.NeedDamage)
            return outStr
        end
    end
end
function DUIWorldBossDanDetailCell:_FormatNeedDamageNumStr(num)
    local preZero = UIActivityHelper.GetZeroStrFrontNum(7,num)
    local fmtStr = string.format("<color=#696969>%s</color><color=#e7d3ac>%s</color>",preZero,tostring(num))
    return fmtStr
end
---@public
---传奇段位显示当前第一名伤害
function DUIWorldBossDanDetailCell:GetDanExtraInfo()
    if self._danCfg then
        if self._danCfg.RankLevel > 0 then--传奇
            if self._danInfo then
                if self._danInfo.rank_first_damage > 0 then
                    return StringTable.Get("str_world_boss_dan_detail_top_one_score",self._danInfo.rank_first_damage)
                end
            end
        end
    end
end
---@public
---徽章图标
function DUIWorldBossDanDetailCell:GetDanBadgeBase()
    if self._danCfg then
        return self._danCfg.DanBadgeBase
    end
end
---@public
---奖励列表
function DUIWorldBossDanDetailCell:GetDanRewards()
    if self._danCfg then
        local rewardVec = self._danCfg.Rewards
        if rewardVec then
            local roleAssetList = {}
            for index, value in ipairs(rewardVec) do
                ---@type RoleAsset
                local asset = RoleAsset:New()
                asset.assetid = value[1]
                asset.count = value[2]
                table.insert(roleAssetList,asset)
            end
            return roleAssetList
        end
    end
end

---@public
---获取段位id
function DUIWorldBossDanDetailCell:GetDanName()
    if self._danCfg then
        return self._danCfg.DanName
    end
end
function DUIWorldBossDanDetailCell:IsPlusDan()
    local bPlus = false
    if self._danCfg then
        if self._danCfg.IsPlusDan then
            if self._danCfg.IsPlusDan == 1 then
                bPlus = true
            end
        end
    end
    return bPlus
end

---@public
---是否是当前段位
function DUIWorldBossDanDetailCell:IsPlayerCurDanData()
    local curDan = self._danInfo.cur_dan
    local curRank = self._danInfo.my_rank
    if UIWorldBossHelper.IsNoDan(curDan,curRank) then
        return false
    end
    if curRank > 0 and self._danCfg.RankLevel > 0 then
        return true
    end
    if curRank == 0 and self._danCfg.RankLevel == 0 then
        return (curDan == self._danCfg.ID)
    else
        return false
    end
end