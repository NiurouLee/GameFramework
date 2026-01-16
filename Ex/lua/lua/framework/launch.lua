local function Launch()
    --游戏启动时加载资源和必要的代码等
    _G.CLIENT = true
    print("lua launch start,", debug.traceback())

    dofile "start"
end

local HotUpdateVersionCheckResult = HotUpdate.HotUpdateVersionCheckResult
local UpdateResCallbackType = HotUpdate.UpdateResCallbackType

local versionCheckRes = HotUpdateLuaProxy.GetVersionCheckRes()
if versionCheckRes == HotUpdateVersionCheckResult.CloseHotUpdate then
    Launch()
    return
end
if HotUpdateLuaProxy.IsHotUpdateFinish() then --没有普通资源更新,直接launch
    print("没有普通资源更新,直接launch,", debug.traceback())
    Launch()
    return
end
--热更文本国际化
local _, t_str_hot_update = dofile("str_hotupdate")

local HotUpdateStringTable = {}
for id, tb in pairs(t_str_hot_update) do
    HotUpdateStringTable[id] = tb
end

--多语言key
local TitleKey = "str_hotupdate_title"
local QuitKey = "str_hotupdate_quit"
local RetryKey = "str_hotupdate_retry"
local CheckUpdateKey = "str_hotupdate_check"
local UpdatePatchCompleteKey = "str_hotupdate_patch_complete"
local NetErrorKey = "str_hotupdate_net_err"

--进度条提示信息
local progressInfoConfig = {
    {progress = 20, info = "str_hotupdate_progress_info_20"},
    {progress = 40, info = "str_hotupdate_progress_info_40"},
    {progress = 60, info = "str_hotupdate_progress_info_60"},
    {progress = 80, info = "str_hotupdate_progress_info_80"},
    {progress = 100, info = "str_hotupdate_progress_info_100"}
}

--UI变量
local launchRoot = nil
local updateInfoPanel = nil
--进度条相关
local progressPanel = nil
local progressBar = nil
local percentLabel = nil
local launchLabel = nil
local downloadedSizeLabel = nil
local totalSizeLabel = nil
local progressInfoLabel = nil
local speedLabel = nil
local checkTipsLabel = nil
local leftBrackets = nil
local rightBrackets = nil
local SpliteBrackets = nil
--弹窗界面相关
local messageBoxPanel = nil
local leftButtonGo = nil
local leftButtonNameLabel = nil
local rightButtonGo = nil
local rightButtonNameLabel = nil
local mesTitleLabel = nil
local mesContentLabel = nil

local showTips = nil

-- 上一次上报UA事件的进度
local nLastUAReportProgress = nil

local function InitUIComponent()
    launchRoot = UnityEngine.GameObject.Find("LaunchUI").transform
    updateInfoPanel = launchRoot:Find("UI").gameObject
    progressPanel = launchRoot:Find("UI/Progress").gameObject
    progressBar = launchRoot:Find("UI/Progress/Bar"):GetComponent("Image")
    percentLabel = launchRoot:Find("UI/txtProgress"):GetComponent("UILocalizationText")
    launchLabel = launchRoot:Find("UI/InfoPanel/txtLaunch"):GetComponent("UILocalizationText")
    downloadedSizeLabel = launchRoot:Find("UI/InfoPanel/DownloadSize"):GetComponent("UILocalizationText")
    totalSizeLabel = launchRoot:Find("UI/InfoPanel/TotalSize"):GetComponent("UILocalizationText")
    checkTipsLabel = launchRoot:Find("UI/CheckTips"):GetComponent("UILocalizationText")
    --progressInfoLabel = launchRoot:Find("UI/InfoPanel/ProgressInfo"):GetComponent("UILocalizationText")
    speedLabel = launchRoot:Find("UI/InfoPanel/Speed"):GetComponent("UILocalizationText")
    leftBrackets = launchRoot:Find("UI/InfoPanel/LeftBrackets").gameObject
    rightBrackets = launchRoot:Find("UI/InfoPanel/RightBrackets").gameObject
    SpliteBrackets = launchRoot:Find("UI/InfoPanel/Splite").gameObject

    messageBoxPanel = launchRoot:Find("MessageBox").gameObject
    mesTitleLabel = launchRoot:Find("MessageBox/Title"):GetComponent("UILocalizationText")
    mesContentLabel = launchRoot:Find("MessageBox/Content"):GetComponent("UILocalizationText")
    leftButtonGo = launchRoot:Find("MessageBox/ButtonGroup/LeftButton").gameObject
    rightButtonGo = launchRoot:Find("MessageBox/ButtonGroup/RightButton").gameObject
    leftButtonNameLabel =
        launchRoot:Find("MessageBox/ButtonGroup/LeftButton/ButtonName"):GetComponent("UILocalizationText")
    rightButtonNameLabel =
        launchRoot:Find("MessageBox/ButtonGroup/RightButton/ButtonName"):GetComponent("UILocalizationText")
    nLastUAReportProgress = nil
end

local function ClearUIRef()
    launchRoot = nil
    updateInfoPanel = nil
    progressPanel = nil
    progressBar = nil
    percentLabel = nil
    launchLabel = nil
    downloadedSizeLabel = nil
    totalSizeLabel = nil
    --progressInfoLabel = nil
    speedLabel = nil
    checkTipsLabel = nil
    leftBrackets = nil
    rightBrackets = nil
    SpliteBrackets = nil

    messageBoxPanel = nil
    leftButtonGo = nil
    leftButtonNameLabel = nil
    rightButtonGo = nil
    rightButtonNameLabel = nil
    mesTitleLabel = nil
    mesContentLabel = nil
    nLastUAReportProgress = nil
end

local function SetProgressInfoVisible(visible)
    downloadedSizeLabel.gameObject:SetActive(visible)
    totalSizeLabel.gameObject:SetActive(visible)
    leftBrackets:SetActive(visible)
    rightBrackets:SetActive(visible)
    SpliteBrackets:SetActive(visible)
end

local function _ReportCustomEvent(strEventName, strCustomEventName, paramsList, extraJson)
    local l_paramList = UAReportHelper.GetParamsList()
    l_paramList:Clear()
    if paramsList ~= nil then
        for index, value in ipairs(paramsList) do
            l_paramList:Add(value)
        end
    end
    UAReportHelper.ReportCustomEvent(strEventName, strCustomEventName, l_paramList, extraJson or "")
end

local function _UAReportEvent(uaEventName, paramsDic, extraJson, isRealTime)
    if isRealTime == nil then
        isRealTime = true
    end
    local l_paramDic = UAReportHelper.GetParamsDic()
    l_paramDic:Clear()
    if paramsDic ~= nil then
        for key, value in pairs(paramsDic) do
            l_paramDic:Add(key, value)
        end
    end
    UAReportHelper.UAReportEvent(uaEventName, l_paramDic, extraJson or "", isRealTime)
end

--更新下载进度
local function UpdateUIProgress(value, downloadSize, totalSize, progressInfo)
    if showTips then
        checkTipsLabel.gameObject:SetActive(false)
        progressPanel:SetActive(true)
        SetProgressInfoVisible(true)
        showTips = false
    end
    progressBar.fillAmount = value
    local l_strProgress = math.floor(value * 100) .. "%"
    percentLabel.text = l_strProgress
    downloadedSizeLabel.text = downloadSize
    totalSizeLabel.text = totalSize
    launchLabel.text = progressInfo
    -- 约定好每10%上报一次
    local l_nCurProgress = math.floor(value * 10)
    if l_nCurProgress ~= nLastUAReportProgress then
        nLastUAReportProgress = l_nCurProgress
        _ReportCustomEvent("HotUpdate", "HotUpdateProgress", {["Progress"] = l_strProgress})
    end
end

--显示检查更新面板
local function ShowCheckUpdateUI(info)
    showTips = true
    updateInfoPanel:SetActive(true)
    SetProgressInfoVisible(false)
    progressPanel:SetActive(false)
    checkTipsLabel.gameObject:SetActive(true)
    checkTipsLabel.text = info
    launchLabel.text = ""
    speedLabel.text = ""
end

--显示信息提示框
local function ShowMessageBox(
    titleInfo,
    contentInfo,
    leftButtonCallback,
    leftButtonName,
    rightButtonCallback,
    rightButtonName)
    messageBoxPanel:SetActive(true)
    mesTitleLabel.text = titleInfo
    mesContentLabel.text = contentInfo
    if leftButtonCallback then
        leftButtonGo:SetActive(true)
        leftButtonNameLabel.text = leftButtonName
        UIEventTriggerListener.Get(leftButtonGo).onClick = function()
            leftButtonCallback()
            messageBoxPanel:SetActive(false)
        end
    else
        leftButtonGo:SetActive(false)
    end
    if rightButtonCallback then
        rightButtonGo:SetActive(true)
        rightButtonNameLabel.text = rightButtonName
        UIEventTriggerListener.Get(rightButtonGo).onClick = function()
            rightButtonCallback()
            messageBoxPanel:SetActive(false)
        end
    else
        rightButtonGo:SetActive(false)
    end
end

--根据进度获取提示信息
local function GetProgressInfo(progress)
    if #progressInfoConfig < 0 then
        return ""
    end
    local index = #progressInfoConfig
    for i = 1, #progressInfoConfig do
        local info = progressInfoConfig[i]
        if progress * 100 < info.progress then
            if i == 1 then
                index = 1
            else
                index = i - 1
            end
            break
        end
    end

    return HotUpdateStringTable[progressInfoConfig[index].info]
end

--检查更新
InitUIComponent()
ShowCheckUpdateUI(HotUpdateStringTable[CheckUpdateKey])
if versionCheckRes == HotUpdateVersionCheckResult.UpdatePatch then --有新补丁，更新完成，提示重启
    ShowMessageBox(
        HotUpdateStringTable[TitleKey],
        HotUpdateStringTable[UpdatePatchCompleteKey],
        function()
            UnityEngine.Application.Quit()
        end,
        HotUpdateStringTable[QuitKey]
    )
elseif versionCheckRes == HotUpdateVersionCheckResult.UpdateRes then --热更资源
    local hotUpdateType = false
    local function OnHotUpdateCallback(type, ...)
        hotUpdateType = type
        print("OnHotUpdateCallback ", tostring(type))
        if type == UpdateResCallbackType.Finish then
            local totalSize = HotUpdateLuaProxy.GetTotalSize()
            local progress = HotUpdateLuaProxy.GetProgress()
            local downloadSize = HotUpdateLuaProxy.GetDownloadedSize()
            UpdateUIProgress(progress, downloadSize, totalSize, GetProgressInfo(progress))
            ClearUIRef()
            Launch()
        elseif type == UpdateResCallbackType.Downloading then
            launchLabel.text = GetProgressInfo(HotUpdateLuaProxy.GetProgress())
            if checkTipsLabel then
                checkTipsLabel.gameObject:SetActive(false)
            end
        --[[
        elseif type == UpdateResCallbackType.DownloadError then
            ShowMessageBox(HotUpdateStringTable[TitleKey], HotUpdateStringTable[NetErrorKey],
                function()
                    UnityEngine.Application.Quit()
                end,
                HotUpdateStringTable[QuitKey],
                function()
                    HotUpdateLuaProxy.RetryDownload()
                end,
                HotUpdateStringTable[RetryKey]
            )]]
        end
    end
    AppLuaProxy.OnUpdate(
        function(e, unscaled, curTimeMS)
            if hotUpdateType == UpdateResCallbackType.Downloading then
                local totalSize = HotUpdateLuaProxy.GetTotalSize()
                local progress = HotUpdateLuaProxy.GetProgress()
                local downloadSize = HotUpdateLuaProxy.GetDownloadedSize()
                UpdateUIProgress(progress, downloadSize, totalSize, GetProgressInfo(progress))
            end
        end
    )
    HotUpdateLuaProxy.AddListener(OnHotUpdateCallback)
end