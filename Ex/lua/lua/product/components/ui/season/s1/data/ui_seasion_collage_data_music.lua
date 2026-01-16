---@class UISeasonCollageData_Music:Object 通用的收藏盒数据
_class("UISeasonCollageData_Music", Object)
UISeasonCollageData_Music = UISeasonCollageData_Music

function UISeasonCollageData_Music:Constructor()
    self._Index = nil
    self._ID = nil
    self._Valid = nil    --生效 到达开放时间
    self._IsUnlock = nil --生效后 满足解锁条件
    self._IsNew = nil    --解锁后 是否没点击过
    self._audioID = nil
end

function UISeasonCollageData_Music:Index()
    return self._Index
end

function UISeasonCollageData_Music:ID()
    return self._ID
end

function UISeasonCollageData_Music:IsValid()
    return self._Valid
end

function UISeasonCollageData_Music:IsUnlock()
    return self._IsUnlock
end

function UISeasonCollageData_Music:IsNew()
    return self._IsNew
end

function UISeasonCollageData_Music:AudioID()
    if not self._audioID then
        self._audioID = Cfg.cfg_role_music[self._ID].AudioID
    end
    return self._audioID
end

--秒
function UISeasonCollageData_Music:Duration()
    if not self._duration then
        self._duration = Cfg.cfg_role_music[self._ID].Duration
    end
    return self._duration
end
