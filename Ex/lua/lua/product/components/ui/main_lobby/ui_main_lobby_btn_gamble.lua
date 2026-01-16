--[[
    主界面抽卡按钮相关逻辑
    按钮信息优先级：免费十连>免费单抽，new单独判断
    红点之前在有免费单抽的时候显示，现在被免费单抽图标代替
]]
---@class UIMainLobbyBtnGamble:Object
_class("UIMainLobbyBtnGamble", Object)
UIMainLobbyBtnGamble = UIMainLobbyBtnGamble

function UIMainLobbyBtnGamble:Constructor(icon, freeMulGo, freeSinGo, newGo)
    freeMulGo:SetActive(false)
    freeSinGo:SetActive(false)
    newGo:SetActive(false)
    --最新开放的卡池
    self._latestPoolId = 0
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    local pools = gambleModule:GetPrizePools()
    local temp = {}
    for i = 1, #pools do
        local pool = pools[i]
        if pool.prize_pool_type == 2 then
            table.insert(temp, pool)
        end
    end
    local openTime = 0
    if table.count(temp) > 0 then
        for i = 1, #temp do
            if temp[i].open_time > openTime then
                self._latestPoolId = temp[i].prize_pool_id
                openTime = temp[i].open_time
            end
        end
    end

    --先设置抽卡图标
    if self._latestPoolId ~= 0 then
        --显示活动icon
        local cfg_gamble = Cfg.cfg_gamble_icon[self._latestPoolId]
        if cfg_gamble then
            if cfg_gamble.Icon then
                icon.gameObject:SetActive(true)
                icon:LoadImage(cfg_gamble.Icon)
            else
                icon.gameObject:SetActive(false)
            end
        else
            icon.gameObject:SetActive(false)
        end
    else
        icon.gameObject:SetActive(false)
    end

    --其他图标
    local freeMul, freeSin, hasNew = false, false, false
    freeMul = self:_HasFreeDraw_Multi()
    if freeMul then
        --有免费十连
        freeMulGo:SetActive(true)
    else
        freeMulGo:SetActive(false)
        freeSin = self:_HasFreeDraw_Single()
        if freeSin then
            --有免费单抽
            freeSinGo:SetActive(true)
        else
            freeSinGo:SetActive(false)
        end
    end
    hasNew = self:_HasNew()
    if hasNew then
        --有new
        newGo:SetActive(true)
    else
        newGo:SetActive(false)
    end

    self._gambleNew = newGo
    self._hasGambleNew = hasNew
end

--是否有免费多抽
function UIMainLobbyBtnGamble:_HasFreeDraw_Multi()
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    ---@type PrizePoolInfo[]
    local pools = gambleModule:GetPrizePools()
    for _, pool in ipairs(pools) do
        if pool.mul_remain_free_count > 0 then
            return true
        end
    end
    return false
end

--是否有免费单抽
function UIMainLobbyBtnGamble:_HasFreeDraw_Single()
    ---@type GambleModule
    local gambleModule = GameGlobal.GetModule(GambleModule)
    ---@type PrizePoolInfo[]
    local pools = gambleModule:GetPrizePools()
    for _, pool in ipairs(pools) do
        if pool.remain_free_count > 0 then
            return true
        end
    end
    return false
end

function UIMainLobbyBtnGamble:_HasNew()
    if self._latestPoolId ~= 0 then
        --new
        --去本地poolid和这个poolid对比，一样的话。取消new
        --不一样的话，显示new，当点击时，把这个poolid存到本地
        local openId = GameGlobal.GameLogic():GetOpenId()
        local key = tostring(openId) .. "GambleNew"
        if UnityEngine.PlayerPrefs.HasKey(key) then
            local value = UnityEngine.PlayerPrefs.GetInt(key)
            if value == self._latestPoolId then
                return false
            else
                return true
            end
        else
            return true
        end
    else
        return false
    end
end

function UIMainLobbyBtnGamble:OnClicked()
    GameGlobal.UAReportForceGuideEvent("UIMainClick", {"Click_DrawCardController"}, true)
    --获取功能解锁的数�??
    local module = GameGlobal.GetModule(RoleModule)
    local isLock = not module:CheckModuleUnlock(GameModuleID.MD_Gamble)
    if isLock then
        ToastManager.ShowToast(StringTable.Get("str_function_lock_unlock"))
        return
    end
    TaskManager:GetInstance():StartTask(
        function(TT)
            GameGlobal.GetModule(RoleModule):OnHomePageEnter(TT, CLICKENTRANCE.CE_SUMMON)
        end
    )
    if self._hasGambleNew then
        if self._latestPoolId ~= 0 then
            local openId = GameGlobal.GameLogic():GetOpenId()
            local key = tostring(openId) .. "GambleNew"
            UnityEngine.PlayerPrefs.SetInt(key, self._latestPoolId)
        end
    end
    self._gambleNew:SetActive(false)

    --GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.DrawCard_Enter, "Ckt_01_new")
    --GameGlobal.UIStateManager():SwitchState(UIStateType.UIDrawCardController)
    GameGlobal.UIStateManager():ShowDialog("UIDrawCardController")
end
