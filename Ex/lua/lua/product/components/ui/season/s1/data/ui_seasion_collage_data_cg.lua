---@class UISeasonCollageData_CG:Object 通用的收藏盒数据
_class("UISeasonCollageData_CG", Object)
UISeasonCollageData_CG = UISeasonCollageData_CG

function UISeasonCollageData_CG:Constructor()
    self._Index = nil
    self._ID = nil
    self._Valid = nil           --生效 到达开放时间
    self._IsUnlock = nil        --生效后 满足解锁条件
    self._IsNew = nil           --解锁后 是否没点击过
    self._CanShare = nil        --是否可分享
    self._ShareAwardCount = nil --分享奖励数量 默认分享奖励为光珀
end

function UISeasonCollageData_CG:Index()
    return self._Index
end

function UISeasonCollageData_CG:ID()
    return self._ID
end

function UISeasonCollageData_CG:IsValid()
    return self._Valid
end

function UISeasonCollageData_CG:IsUnlock()
    return self._IsUnlock
end

function UISeasonCollageData_CG:IsNew()
    return self._IsNew
end

function UISeasonCollageData_CG:CanShare()
    return self._CanShare
end

function UISeasonCollageData_CG:ShareAwardCount()
    return self._ShareAwardCount
end
