_G.PLATFORM = UnityEngine.Application.platform
local RuntimePlatform = UnityEngine.RuntimePlatform
_G.PUBLIC = PLATFORM ~= RuntimePlatform.OSXEditor and PLATFORM ~= RuntimePlatform.WindowsEditor
_G.EDITOR = PLATFORM == RuntimePlatform.OSXEditor or PLATFORM == RuntimePlatform.WindowsEditor
_G.NOGUIDE = false
_G.NoCache = false
--显示fps和内存

App.ShowFps = false
--公告功能关闭(海外)
_G.NoNoticeOut = false
--不弹公告
_G.NoPopNotice = false

_G.EXCEPTION_REPORT_WORKWX = false

---打开性能调试日志开关
_G.EnalbeProfLog = false

--lua分析
App.Profiler = false
--加载速度统计
App.SpeedStatistics = false
--自动战斗调试开关
_G.DEBUG_AUTO_FIGHT = false

-- 启用CriWare Adx2 音效引擎加载资源 播放
_G.USEADX2AUDIO = true
App.LodLevel = LodLevel.normal

--强制同步表现血量开关
_G.ForceSyncHP = true
--同步日志开关
_G.ENABLE_SYNC_LOG = true
--技能数值日志开关
_G.ENABLE_MATCH_LOG = true

---检查表现层直接访问逻辑层
_G.CHECK_RENDER_ACCESS_LOGIC = true

function IsNewApp()
    local appVersion = EngineGameHelper.CurrentAppVersion()
    if not appVersion or (appVersion ~= "1.0.2" and appVersion ~= "1.1.0") then
        return true
    end
    return false
end

---Game App Version Define
local curVer
if EDITOR then
    curVer = System.Version:New("99.99.99")
else
    curVer = System.Version:New(EngineGameHelper.CurrentAppVersion())
end
---打开网络统计和参数下发功能
_G.OPEN_NETSTAT = false
--_G.APPVER102 = curVer:CompareTo(System.Version:New("1.0.2")) > -1
--_G.APPVER110 = curVer:CompareTo(System.Version:New("1.1.0")) > -1
--_G.APPVER120 = curVer:CompareTo(System.Version:New("1.2.0")) > -1
---1.2.5:dmm版本
_G.APPVER125 = curVer:CompareTo(System.Version:New("1.2.5")) > -1
_G.APPVER130 = curVer:CompareTo(System.Version:New("1.3.0")) > -1
_G.APPVER170 = curVer:CompareTo(System.Version:New("1.7.0")) > -1
_G.APPVER184 = curVer:CompareTo(System.Version:New("1.8.4")) > -1
_G.APPVER1100 = curVer:CompareTo(System.Version:New("1.10.0")) > -1
_G.APPVERNETSTAT = curVer:CompareTo(System.Version:New("1.11.0")) > -1 and _G.OPEN_NETSTAT
_G.APPVER1110 = curVer:CompareTo(System.Version:New("1.11.2")) > -1
_G.APPVER1140 = curVer:CompareTo(System.Version:New("1.14.0")) > -1
_G.APPVER1142 = curVer:CompareTo(System.Version:New("1.14.2")) > -1
_G.APPVER1150 = curVer:CompareTo(System.Version:New("1.15.0")) > -1
_G.APPVER1170 = curVer:CompareTo(System.Version:New("1.17.0")) > -1
_G.APPVER1190 = curVer:CompareTo(System.Version:New("1.19.0")) > -1
_G.APPVER1210 = curVer:CompareTo(System.Version:New("1.21.0")) > -1
_G.APPVER1220 = curVer:CompareTo(System.Version:New("1.22.0")) > -1