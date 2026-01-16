--[[
    活动辅助类
]]
---@class UIActivityHelper:Object
_class("UIActivityHelper", Object)
UIActivityHelper = UIActivityHelper

function UIActivityHelper.LoadCampaign(TT, res, campaignType, campaignId)
    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    if campaignId then -- 指定活动Id
        campaign:LoadCampaignInfo_Id(TT, res, campaignId)
    else
        campaign:LoadCampaignInfo(TT, res, campaignType)
    end
    return campaign
end

function UIActivityHelper.LoadCampaign_Local(campaignType, campaignId)
    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    if campaignId then -- 指定活动Id
        campaign:LoadCampaignInfo_Id_Local(campaignId)
    else
        campaign:LoadCampaignInfo_Local(campaignType)
    end
    return campaign
end

-- 加载组件的通用流程
-- 1.通过 活动类型 获取活动ID
-- 2.检查活动是否开启
-- 3.检查传入的组件是否开启
function UIActivityHelper.LoadDataOnEnter(TT, res, campaignType, componentIds)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    local campaign = UIActivityCampaign:New()
    campaign:LoadCampaignInfo(TT, res, campaignType, table.unpack(componentIds))

    -- 活动已开启，检查组件是否开启
    if res and res:GetSucc() then
        if not campaign:CheckComponentOpen(table.unpack(componentIds)) then
            res.m_result = campaign:CheckComponentOpenClientError(table.unpack(componentIds))
        end
    end

    -- 错误处理
    if res and not res:GetSucc() then
        campaign:CheckErrorCode(res.m_result, nil, nil)
    end

    return campaign
end

--region SetTimer
-- function UIActivityHelper.StartOnceTimerEvent(timerEvent, callback, tick)
--     local t = tick or 1000
--     UIActivityHelper.CancelTimerEvent(timerEvent)

--     timerEvent = GameGlobal.Timer():AddEventTimes(t, TimerTriggerCount.Once, callback)

--     return timerEvent
-- end

function UIActivityHelper.StartTimerEvent(timerEvent, timerCallback, tick)
    local t = tick or 1000

    -- 设置计时器的时候，进行首次回调
    local stopSign = timerCallback()

    timerEvent = UIActivityHelper.CancelTimerEvent(timerEvent)
    if not stopSign then -- 返回 stopSign 在首次回调时停止继续创建计时器
        timerEvent = GameGlobal.Timer():AddEventTimes(t, TimerTriggerCount.Infinite, timerCallback)
    end

    return timerEvent -- 返回新的 timerEvent
end

function UIActivityHelper.CancelTimerEvent(timerEvent)
    if timerEvent then
        GameGlobal.Timer():CancelEvent(timerEvent)
    end
    return nil
end

function UIActivityHelper.GetFormatTimerStr(time, id)
    -- 通用倒计时显示逻辑：
    -- 1天以上显示N天X小时；1小时以上显示N小时X分钟；1分钟以上显示N分钟；1分钟以内显示＜1分钟。
    -- N天0小时显示整数N天，N小时0分钟显示整数N小时。

    local default_id = {
        ["day"] = "str_activity_common_day",
        ["hour"] = "str_activity_common_hour",
        ["min"] = "str_activity_common_minute",
        ["zero"] = "str_activity_common_less_minute",
        ["over"] = "str_activity_error_107"
    }
    id = id or default_id

    local timeStr = StringTable.Get(id.over)
    if time < 0 then
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        timeStr = day .. StringTable.Get(id.day)
        if hour ~= 0 then
            timeStr = timeStr .. hour .. StringTable.Get(id.hour)
        end
    elseif hour > 0 then
        timeStr = hour .. StringTable.Get(id.hour)
        if min ~= 0 then
            timeStr = timeStr .. min .. StringTable.Get(id.min)
        end
    elseif min > 0 then
        timeStr = min .. StringTable.Get(id.min)
    else
        timeStr = StringTable.Get(id.zero)
    end
    return timeStr
end

function UIActivityHelper.Time2Str(time)
    local second = time % 60
    local min = math.floor(time / 60) % 60
    local hour = math.floor(time / 60 / 60) % 24
    local day = math.floor(time / 60 / 60 / 24)
    return day, hour, min, second
end

--endregion

--region Lock
function UIActivityHelper.StartLockEvent(lockName, timerEvent, callback, tick)
    if string.isnullorempty(lockName) then
        return nil
    end

    local t = tick or 1000
    UIActivityHelper.CancelLockEvent(lockName, timerEvent)

    timerEvent =
        GameGlobal.Timer():AddEventTimes(
        t,
        TimerTriggerCount.Once,
        function()
            UIActivityHelper.CancelLockEvent(lockName, timerEvent)
            if callback then
                callback()
            end
        end
    )

    GameGlobal.UIStateManager():Lock(lockName)
    return timerEvent
end

function UIActivityHelper.CancelLockEvent(lockName, timerEvent)
    if string.isnullorempty(lockName) then
        return nil
    end

    GameGlobal.UIStateManager():UnLock(lockName)
    if timerEvent then
        GameGlobal.Timer():CancelEvent(timerEvent)
    end
    return nil
end

--endregion

--region UI Helper

-- 得到 cfg_campaign 配置中的活动背景
function UIActivityHelper.GetCampaignMainBg(campaign, idx)
    local cfg_campaign = Cfg.cfg_campaign[campaign._id]
    if cfg_campaign then
        local url = cfg_campaign.BGImage
        return url and url[idx]
    end
end

-- 获取活动配置 cfg_campaign 中的首次进入剧情 id
function UIActivityHelper.GetCampaignFirstEnterStoryID(campaign, idx)
    local cfg_campaign = Cfg.cfg_campaign[campaign._id]
    if cfg_campaign then
        local id = cfg_campaign.FirstEnterStoryID
        return id and id[idx]
    end
end

function UIActivityHelper.PlayFirstPlot_Campaign(campaign, callback, autoCloseStoryUI)
    if not campaign:CheckCampaignOpen() then
        if callback then
            callback()
        end
        return
    end

    local storyId = UIActivityHelper.GetCampaignFirstEnterStoryID(campaign, 1)
    UIActivityHelper._PlayFirstPlot("PlayFirstPlot_Campaign_" .. campaign._id, storyId, callback, autoCloseStoryUI)
end

function UIActivityHelper.PlayFirstPlot_Component(campaign, componentId, callback, autoCloseStoryUI)
    if not campaign:CheckComponentOpen(componentId) then
        if callback then
            callback()
        end
        return
    end

    local component = campaign:GetComponent(componentId)
    local storyId = component:GetComponentInfo().m_first_story_id
    UIActivityHelper._PlayFirstPlot(
        "PlayFirstPlot_Component_" .. campaign._id .. "_" .. componentId,
        storyId,
        callback,
        autoCloseStoryUI
    )
end

function UIActivityHelper._PlayFirstPlot(keyStr, storyId, callback, autoCloseStoryUI)
    -- keyStr 为空 或 storyId 为空，跳过播剧情，直接回调
    if not keyStr or not storyId or storyId == 0 then
        Log.info("UIActivityHelper._PlayFirstPlot() keyStr == ", keyStr, ", storyId == ", storyId)
        if callback then
            callback()
        end
        return
    end

    keyStr = UIActivityHelper.GetLocalDBKeyWithPstId(keyStr .. "_")

    if LocalDB.HasKey(keyStr) then
        Log.info("UIActivityHelper._PlayFirstPlot() HasKey! keyStr == ", keyStr)
        if callback then
            callback()
        end
        return
    else
        Log.info("UIActivityHelper._PlayFirstPlot() SetKey! keyStr == ", keyStr)
        LocalDB.SetInt(keyStr, 1)

        GameGlobal.UIStateManager():ShowDialog("UIStoryController", storyId, callback, autoCloseStoryUI)
    end
end

--endregion

--region Recharge
---@return boolean, number 是否充足，差额
function UIActivityHelper.IsYJEnough(cost) --耀晶
    local mShop = GameGlobal.GetModule(ShopModule)
    local count, countFree = mShop:GetDiamondCount()
    local total = count
    local isEnough = cost <= total
    local diff = cost - total
    return isEnough, diff
end

--endregion

--region new and RedPoint
-- 通过活动 sample 获取 New 信息
---@param campaign UIActivityCampaign
---@return boolean
function UIActivityHelper.CheckCampaignSampleNewPoint(campaign)
    local nonuse = UIActivityHelper.CheckCampaignSampleNewPoint_Nonuse(campaign._type)
    local customFunc = UIActivityHelper.CheckCampaignSampleNewPoint_CustomFunc(campaign._type)
    if nonuse then
        return false
    elseif customFunc then
        return customFunc(campaign)
    else
        return campaign:CheckCampaignNew()
    end
end

-- 需要使用定制方法检查【Sample New】的活动
function UIActivityHelper.CheckCampaignSampleNewPoint_CustomFunc(campaignType)
    local tb = {
        [ECampaignType.CAMPAIGN_TYPE_N19_COMMON] = UIN19Helper.GetNewPoint
    }
    return tb[campaignType]
end

-- 不检查【Sample New】的活动
function UIActivityHelper.CheckCampaignSampleNewPoint_Nonuse(campaignType)
    local tb = {
        [ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN] = true,
        [ECampaignType.CAMPAIGN_TYPE_SIGN_IN] = true,
        [ECampaignType.CAMPAIGN_TYPE_HAVESTTIME] = true,
        [ECampaignType.CAMPAIGN_TYPE_INLAND_FIRSTPET] = true,
        [ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN_COPY] = true
    }
    return tb[campaignType]
end

-- 通过活动 sample 获取红点信息
---@param campaign UIActivityCampaign
---@return boolean
function UIActivityHelper.CheckCampaignSampleRedPoint(campaign)
    local nonuse = UIActivityHelper.CheckCampaignSampleRedPoint_Nonuse(campaign._type)
    local customFunc = UIActivityHelper.CheckCampaignSampleRedPoint_CustomFunc(campaign._type)
    if nonuse then
        return false
    elseif customFunc then
        return customFunc(campaign)
    else
        return campaign:CheckCampaignRed()
    end
end

-- 需要使用定制方法检查【Sample Red】的活动
function UIActivityHelper.CheckCampaignSampleRedPoint_CustomFunc(campaignType)
    local tb = {
        [ECampaignType.CAMPAIGN_TYPE_BATTLEPASS] = UIActivityBattlePassHelper.CheckCampaignRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_BACK_PHASE_II] = UIActivityReturnSystemHelper.CheckCampaignRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN] = UIActivityHelper.CheckSeniorSkinRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_ANNIVERSARY] = UIActivityAnniversaryLoginHelper.CheckCampaignRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_N31_ANNIVERSARY] = UIN31SecondAnniversaryContent.CheckCampaignRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_SENIOR_SKIN_COPY] = UIActivityHelper.CheckSeniorSkinRedPoint,
        [ECampaignType.CAMPAIGN_TYPE_INLAND_FIRSTPET] = UIActivityPetTryHelper.CheckCampaignRedPoint
    }
    return tb[campaignType]
end

-- 不检查【Sample Red】的活动
function UIActivityHelper.CheckCampaignSampleRedPoint_Nonuse(campaignType)
    local tb = {
        [ECampaignType.CAMPAIGN_TYPE_HAVESTTIME] = true
    }
    return tb[campaignType]
end

function UIActivityHelper.SetWidgetNewAndRed(newObj, new, redObj, red)
    if not newObj and not redObj then
        return
    end

    if newObj and redObj then
        local same = (redObj == newObj)
        if same then
            -- 在 prefab 中，当 new 也连接到 red 的 Widget 的情况，红点逻辑特殊处理
            newObj:SetActive(new or red)
        else
            -- 当有 new 的时候，不显示 red 【策划：徐小庆】
            newObj:SetActive(new)
            redObj:SetActive(not new and red)
        end
    elseif newObj then
        -- 只有 new 的时候，显示 new
        newObj:SetActive(new)
    elseif redObj then
        -- 只有 red 的时候，显示 red
        redObj:SetActive(red)
    end
end

--endregion

--region ShowUIGetRewards
-- 通用奖励弹窗
-- 根据奖励类型分来，先显示 pet ，再显示 pet skin ，最后显示 item
function UIActivityHelper.ShowUIGetRewards(rewards, doNotSort)
    if not rewards then
        return
    end

    -- 分类
    local itemList = {}
    local petList = {}
    local petSkinList = {}

    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    for _, v in pairs(rewards) do
        if petModule:IsPetID(v.assetid) then
            table.insert(petList, v)
        elseif petModule:IsPetSkinID(v.assetid) then
            local roleAsset = RoleAsset:New()
            roleAsset.assetid = petModule:GetSkinIDFromItemID(v.assetid)
            roleAsset.count = v.count
            table.insert(petSkinList, roleAsset)
        else
            table.insert(itemList, v)
        end
    end

    UIActivityHelper.ShowUIGetRewards_Pet(petList, petSkinList, itemList, doNotSort)
end

function UIActivityHelper.ShowUIGetRewards_Pet(petList, petSkinList, itemList, doNotSort)
    if table.count(petList) <= 0 then
        UIActivityHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, doNotSort)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIPetObtain",
        petList,
        function()
            GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
            UIActivityHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, doNotSort)
        end
    )
    return
end

function UIActivityHelper.ShowUIGetRewards_PetSkin(petSkinList, itemList, doNotSort)
    if table.count(petSkinList) <= 0 then
        UIActivityHelper.ShowUIGetRewards_Item(itemList, doNotSort)
        return
    end

    local index = 0
    local showNextFunc = function()
        index = index + 1
        if index <= #petSkinList then
            return petSkinList[index]
        end
        return nil
    end
    local callBackFunc
    callBackFunc = function()
        GameGlobal.UIStateManager():CloseDialog("UIPetSkinObtainController")
        local nextAsset = showNextFunc()
        if nextAsset then
            UIActivityHelper.ShowUIGetRewards_PetSkin_Single(nextAsset, callBackFunc)
        else
            UIActivityHelper.ShowUIGetRewards_Item(itemList, doNotSort)
        end
    end

    UIActivityHelper.ShowUIGetRewards_PetSkin_Single(showNextFunc(), callBackFunc)
end

function UIActivityHelper.ShowUIGetRewards_PetSkin_Single(roleAsset, callBackFunc)
    if not roleAsset then
        if callBackFunc then
            callBackFunc()
        end
        return
    end
    GameGlobal.UIStateManager():ShowDialog("UIPetSkinObtainController", roleAsset, callBackFunc)
end

function UIActivityHelper.ShowUIGetRewards_Item(itemList, doNotSort)
    if table.count(itemList) <= 0 then
        GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        return
    end

    GameGlobal.UIStateManager():ShowDialog(
        "UIGetItemController",
        itemList,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnUIGetItemCloseInQuest, 0)
        end,
        doNotSort
    )
end

--endregion

--region LocalDB Help
function UIActivityHelper.GetLocalDBKeyWithPstId(keyStr)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return keyStr .. roleModule:GetPstId()
end

--endregion

--region DebugHelp
function UIActivityHelper.GetDebugOpenKey()
    return UIActivityHelper.GetLocalDBKeyWithPstId("UIActivityHelper_GetDebugOpenKey_")
end

function UIActivityHelper.CheckDebugOpen()
    local show =
        EngineGameHelper.IsDevelopmentBuild() or
        HelperProxy:GetInstance():GetConfig("EnableTestFunc", "false") == "true"
    return show and LocalDB.HasKey(UIActivityHelper.GetDebugOpenKey())
end

--endregion

--region HelpFunc

-- 获取多语言文字表格中 Id 连续的所有字符串，从 1 开始
-- 如：["str_xx_"]
-- 返回 ["str_xx_1,", "str_xx_2", "str_xx_3"]
function UIActivityHelper.GetStringTableArray(key)
    local tb = {}
    local n = 0
    while true do
        n = n + 1
        local b = StringTable.Has(key .. n)
        if b then
            table.insert(tb, key .. n)
        else
            n = n - 1
            break
        end
    end
    if n <= 0 then
        Log.fatal("UIActivityHelper.GetStringTableArray() no [", key, n, "] in str_xxx.xlsx")
    end
    return tb
end

-- 获得设置颜色的文字
-- 例如：["#000000"] ["abcd"] ["#ffffff"] ["1234"] -->
-- ["<color=#000000>abcd</color><color=#ffffff>1234</color>"]
function UIActivityHelper.GetColorText(...)
    local str = ""
    local tb = {...}
    for i = 1, #tb, 2 do
        str = string.format("%s<color=%s>%s</color>", str, tb[i], tb[i + 1])
    end
    return str
end

-- 获得设置 Rich 标签的文字
-- 以 2 个参数为一组，参数 1 为标签 table， 参数 2 为文字
-- 例如：[{color = "#000000", size = 20}] ["abcd"] [{color = "#FFFFFF", size = 40}] ["1234"] -->
-- ["<color=#000000><size=20>abcd</size></color><color=#FFFFFF><size=40>1234</size></color>"]
function UIActivityHelper.GetRichText(...)
    local str = ""
    local tb = {...}
    for i = 1, #tb, 2 do
        local p = tb[i]
        local t = tb[i + 1]
        for k, v in pairs(p) do
            t = string.format("<%s=%s>%s</%s>", k, v, t, k)
        end
        str = str .. t
    end
    return str
end

function UIActivityHelper._GetRichText(param, text)
    return string.format("<%s=%s>%s</%s>")
end

-- 计算数字位数
function UIActivityHelper._DightNum(inNum)
    local num = tonumber(inNum)
    if not num then
        return -1
    end
    if math.floor(num) ~= num or num < 0 then
        return -1
    elseif 0 == num then
        return 1
    else
        local tmp_dight = 0
        while num > 0 do
            num = math.floor(num / 10)
            tmp_dight = tmp_dight + 1
        end
        return tmp_dight
    end
end

-- 返回数字前需要填充的0
-- 例如：[dest_dight = 8] [num = 1234] --> [00001234] --> [0000]
function UIActivityHelper.GetZeroStrFrontNum(dest_dight, num)
    local num_dight = UIActivityHelper._DightNum(num)
    if -1 == num_dight then
        return ""
    elseif num_dight >= dest_dight then
        return ""
    else
        local str_e = ""
        for var = 1, dest_dight - num_dight do
            str_e = str_e .. "0"
        end
        return str_e
    end
end

-- 数字前填充 0 到指定位数，可设置颜色
-- 例如：[dest_dight = 8] [num = 1234] --> [00001234]
-- 例如：[dest_dight = 8] [num = 1234] ["#000000"] ["#ffffff"] -->
-- ["<color="#000000>0000</color><color=#ffffff>1234</color>"]
function UIActivityHelper.FormatNumber_PreZero(dest_dight, num, c1, c2)
    local preZero = UIActivityHelper.GetZeroStrFrontNum(dest_dight, num)
    if c1 and c2 then
        return UIActivityHelper.GetColorText(c1, preZero, c2, num)
    else
        return preZero .. num
    end
end

-- 数字前填充 0 到指定位数
-- 例如：[dest_dight = 8] [num = 1234] --> [00001234]
function UIActivityHelper.AddZeroFrontNum(dest_dight, num)
    local num_dight = UIActivityHelper._DightNum(num)
    if -1 == num_dight then
        return num
    elseif num_dight >= dest_dight then
        return tostring(num)
    else
        local str_e = ""
        for var = 1, dest_dight - num_dight do
            str_e = str_e .. "0"
        end
        return str_e .. tostring(num)
    end
end

--N5 军功榜 客户端计算排名
function UIActivityHelper.CalPlayerPersonProgressRank(cmptCfgId, progress)
    local rank = 1
    local cfgGroup = Cfg.cfg_activity_person_progress_extra_client {ComponentID = cmptCfgId}
    if cfgGroup and #cfgGroup > 0 then
        for index, value in ipairs(cfgGroup) do
            if value.NpcName and value.ItemCount > progress then --有NPC信息的才参与排名
                rank = rank + 1
            end
        end
    end
    return rank
end

--打开活动说明界面，关联配置Cfg.cfg_activityintro
function UIActivityHelper.ShowActivityIntro(activityIntroKey)
    local introCfg = Cfg.cfg_activityintro[activityIntroKey]
    if introCfg then
        local uiName = "UIActivityIntroController"
        if string.isnullorempty(introCfg.SpecialUi) then
        else --不能用通用的界面时的处理
            uiName = introCfg.SpecialUi
        end
        GameGlobal.UIStateManager():ShowDialog(uiName, activityIntroKey)
    end
end

--不显示红点
function UIActivityHelper.NoRed()
    return false
end

--卡莲高级时装红点，抽过1次之后取消红点
---@param campaign UIActivityCampaign
function UIActivityHelper.CheckSeniorSkinRedPoint(campaign)
    ---@type SeniorSkinComponentInfo
    local info = campaign:GetComponentInfo(ECampaignSeniorSkinComponentID.ECAMPAIGN_SENIOR_SKIN)
    if not info then
        return false
    end
    local componentId =
        info.m_campaign_id * CampaignConfigDefine.CONFIG_CAMPAIGN_ID_MOD +
        info.m_component_type * CampaignConfigDefine.CONFIG_COMPONENT_TYPE_MOD +
        info.m_component_id

    local nextShake = info.shake_num + 1
    local cost = Cfg.cfg_component_senior_skin_cost {ComponentID = componentId, SeqID = nextShake}
    if cost then
        return cost[1].CostItemCount == 0
    end
    return false
end

--endregion

---@param blurHelper H3DUIBlurHelper
---@param safeAreaSize Vector2 安全区宽高
---@param camera UnityEngine.Camera 截图相机
---@param callback function 回调
function UIActivityHelper.Snap(blurHelper, safeAreaSize, camera, callback)
    blurHelper.width = safeAreaSize.x
    blurHelper.height = safeAreaSize.y
    blurHelper.OwnerCamera = camera
    blurHelper:CleanRenderTexture()
    local rt = blurHelper:RefreshBlurTexture()
    local cache_rt = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT)
            UnityEngine.Graphics.Blit(rt, cache_rt)
            if callback then
                callback(cache_rt)
            end
        end
    )
end
--创建光灵修正区域widget
---@param uiStyle UIActivityPetEnhanceAreaUIStyle
function UIActivityHelper.SpawnPetEnhanceArea(uiView, widgetName,componentCfgId,uiStyle)
    ---@type UICustomWidgetPool
    local petEnhanceAreaGen = uiView:GetUIComponent("UISelectObjectPath", widgetName)
    if petEnhanceAreaGen then
        local cfgGroup = Cfg.cfg_campaign_mission_pet_correct{ComponentID=componentCfgId}
        --if cfgGroup and #cfgGroup > 0 then
            ---@type UIActivityPetEnhanceAreaWidget
            local petEnhanceArea = petEnhanceAreaGen:SpawnObject("UIActivityPetEnhanceAreaWidget")
            if petEnhanceArea then
                petEnhanceArea:SetData(componentCfgId,uiStyle)
            end
        --end
    end
end