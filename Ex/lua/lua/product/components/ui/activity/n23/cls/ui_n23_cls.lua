---@class N23Data:CampaignDataBase
---@field replays N23Replay[] 彩蛋列表
_class("N23Data", CampaignDataBase)
N23Data = N23Data

function N23Data:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)

    self:Init()
end

function N23Data:Init()
    self.replays = {}
    local cfg = Cfg.cfg_n23_replay()
    for key, cfgv in pairs(cfg) do
        local replay = N23Replay:New(cfgv.ID, self)
        table.insert(self.replays, replay)
    end
end
---@return N23Replay
function N23Data:GetReplayById(id)
    for key, replay in pairs(self.replays) do
        if replay.id == id then
            return replay
        end
    end
end
---@return N23Replay
function N23Data:GetReplayByExchangeId(exchangeId)
    for key, replay in pairs(self.replays) do
        if replay.exchangeId == exchangeId then
            return replay
        end
    end
end

--region 红点 new
function N23Data:CheckRedAward() --累计奖励
    local lp = self:GetLocalProcess()
    local red = self.mCampaign:CheckComponentRed(lp, ECampaignN23ComponentID.ECAMPAIGN_N23_CUMULATIVE_LOGIN)
    return red
end
function N23Data:CheckRedFilm() --拍电影
    local state = self:GetStateAdventure()
    if state == UISummerOneEnterBtnState.Normal then
    --TODO 填写拍电影红点逻辑
    end
    return false
end
function N23Data:CheckRedAdventure() --奇遇任务
    local state = self:GetStateAdventure()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local red = self.mCampaign:CheckComponentRed(lp, ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN)
        return red
    end
    return false
end
function N23Data:CheckRedNormal()
    local state = self:GetStateNormal()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local redFixTeam = self.mCampaign:CheckComponentRed(lp, ECampaignN23ComponentID.ECAMPAIGN_N23_LINE_MISSION)
        return redFixTeam
    end
    return false
end
function N23Data:CheckRedShop()
    local state = self:GetStateShop()
    if state == UISummerOneEnterBtnState.Normal then
        local lp = self:GetLocalProcess()
        local redFixTeam = self.mCampaign:CheckComponentRed(lp, ECampaignN23ComponentID.ECAMPAIGN_N23_SHOP)
        return redFixTeam
    end
    return false
end
--endregion

--region Component ComponentInfo
---@return HomelandTaskComponent 奇遇任务组件
function N23Data:GetComponentAdventure()
    local c = self.activityCampaign:GetComponent(ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN)
    return c
end
---@return HomlandTaskComponentInfo 奇遇任务组件信息
function N23Data:GetComponentInfoAdventure()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN23ComponentID.ECAMPAIGN_N23_PANGOLIN)
    return cInfo
end

---@return LineMissionComponent 线性关
function N23Data:GetComponentNormal()
    local c = self.activityCampaign:GetComponent(ECampaignN23ComponentID.ECAMPAIGN_N23_LINE_MISSION)
    return c
end
---@return LineMissionComponentInfo 线性关
function N23Data:GetComponentInfoNormal()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN23ComponentID.ECAMPAIGN_N23_LINE_MISSION)
    return cInfo
end

---@return ExchangeItemComponent 商店
function N23Data:GetComponentShop()
    local c = self.activityCampaign:GetComponent(ECampaignN23ComponentID.ECAMPAIGN_N23_SHOP)
    return c
end
---@return ExchangeItemComponentInfo 商店
function N23Data:GetComponentInfoShop()
    local cInfo = self.activityCampaign:GetComponentInfo(ECampaignN23ComponentID.ECAMPAIGN_N23_SHOP)
    return cInfo
end
--endregion

--region 显隐New
---@return UISummerOneEnterBtnState
function N23Data:GetState(cInfo)
    local nowTimestamp = UICommonHelper.GetNowTimestamp()
    if nowTimestamp < cInfo.m_unlock_time then --未开启
        return UISummerOneEnterBtnState.NotOpen
    elseif nowTimestamp > cInfo.m_close_time then --已关闭
        return UISummerOneEnterBtnState.Closed
    else --进行中
        if cInfo.m_b_unlock then --是否已解锁，可能有关卡条件
            return UISummerOneEnterBtnState.Normal
        else
            local cfgv = Cfg.cfg_campaign_mission[cInfo.m_need_mission_id]
            if cfgv then
                return UISummerOneEnterBtnState.Locked
            else
                return UISummerOneEnterBtnState.Normal
            end
        end
    end
end
---@return UISummerOneEnterBtnState
function N23Data:GetStateAdventure()
    local cInfo = self:GetComponentInfoAdventure()
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N23Data:GetStateNormal()
    local cInfo = self:GetComponentInfoNormal()
    return self:GetState(cInfo)
end
---@return UISummerOneEnterBtnState
function N23Data:GetStateShop()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN23ComponentID.ECAMPAIGN_N23_SHOP)
    if c then
        return self:GetState(c)
    end
end
---@return UISummerOneEnterBtnState
function N23Data:GetStateAward()
    local c = self.activityCampaign:GetComponentInfo(ECampaignN23ComponentID.ECAMPAIGN_N23_CUMULATIVE_LOGIN)
    if c then
        return self:GetState(c)
    end
end

function N23Data:CheckNewFilm()
    if not N23Data.HasPrefsFilm() and self:GetStateAdventure() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
function N23Data:CheckNewAdventure()
    if not N23Data.HasPrefsAdventure() and self:GetStateAdventure() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
function N23Data:CheckNewLine()
    if not N23Data.HasPrefsLine() and self:GetStateNormal() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
function N23Data:CheckNewShop()
    if not N23Data.HasPrefsShop() and self:GetStateShop() == UISummerOneEnterBtnState.Normal then
        return true
    end
    return false
end
--endregion

---@return number, number
function N23Data:GetEggCount()
    local total = table.count(self.replays)
    local unLockCount = 0
    for index, replay in ipairs(self.replays) do
        if replay:IsUnlock() then
            unLockCount = unLockCount + 1
        end
    end
    return unLockCount, total
end

--region PrefsKey
---@private
function N23Data.GetPstId()
    local mRole = GameGlobal.GetModule(RoleModule)
    return mRole:GetPstId()
end
function N23Data.GetPrefsKey(str)
    local playerPrefsKey = N23Data.GetPstId() .. str
    return playerPrefsKey
end
function N23Data.GetPrefsKeyMain()
    return N23Data.GetPrefsKey("UIN23DataPrefsKeyMain")
end
function N23Data.GetPrefsKeyFilm()
    return N23Data.GetPrefsKey("UIN23DataPrefsKeyFilm")
end
function N23Data.GetPrefsKeyAdventure()
    return N23Data.GetPrefsKey("UIN23DataPrefsKeyAdventure")
end
function N23Data.GetPrefsKeyLine()
    return N23Data.GetPrefsKey("UIN23DataPrefsKeyLine")
end
function N23Data.GetPrefsKeyShop()
    return N23Data.GetPrefsKey("UIN23DataPrefsKeyShop")
end
---------------------------------------------------------------------------------
function N23Data.HasPrefsMain()
    return UnityEngine.PlayerPrefs.HasKey(N23Data.GetPrefsKeyMain())
end
function N23Data.SetPrefsMain()
    UnityEngine.PlayerPrefs.SetInt(N23Data.GetPrefsKeyMain(), 1)
end
function N23Data.HasPrefsFilm()
    return UnityEngine.PlayerPrefs.HasKey(N23Data.GetPrefsKeyFilm())
end
function N23Data.SetPrefsFilm()
    UnityEngine.PlayerPrefs.SetInt(N23Data.GetPrefsKeyFilm(), 1)
end
function N23Data.HasPrefsAdventure()
    return UnityEngine.PlayerPrefs.HasKey(N23Data.GetPrefsKeyAdventure())
end
function N23Data.SetPrefsAdventure()
    UnityEngine.PlayerPrefs.SetInt(N23Data.GetPrefsKeyAdventure(), 1)
end
function N23Data.HasPrefsLine()
    return UnityEngine.PlayerPrefs.HasKey(N23Data.GetPrefsKeyLine())
end
function N23Data.SetPrefsLine()
    UnityEngine.PlayerPrefs.SetInt(N23Data.GetPrefsKeyLine(), 1)
end
function N23Data.HasPrefsShop()
    return UnityEngine.PlayerPrefs.HasKey(N23Data.GetPrefsKeyShop())
end
function N23Data.SetPrefsShop()
    UnityEngine.PlayerPrefs.SetInt(N23Data.GetPrefsKeyShop(), 1)
end
--endregion

--region Replay
---@class N23Replay:Object
---@field id number 主键
---@field exchangeId number 商品id
---@field index string 索引文本
---@field icon number 主键
---@field view table 彩蛋表现参数
_class("N23Replay", Object)
N23Replay = N23Replay

function N23Replay:Constructor(id, data)
    self.id = id

    local cfgv = Cfg.cfg_n23_replay[id]
    self.exchangeId = cfgv.ExchangeId
    self.index = cfgv.Index
    self.icon = cfgv.Icon
    -- {spine="spine名",
    --     playSequence={
    --         [索引]={anim="动画名", time=表现时长ms}
    --     }
    -- }
    self.view = cfgv.View

    self.data = data
end
---@return string 获取彩蛋Spine名
function N23Replay:ViewSpine()
    if self.view then
        return self.view.spine
    end
end
---@return string 获取彩蛋spine播放序列
function N23Replay:ViewPlaySequence()
    if self.view then
        return self.view.playSequence
    end
end
---@return boolean 加载后是否隐藏spine
function N23Replay:ViewHideOnLoad()
    if self.view then
        return self.view.HideOnLoad and true or false
    end
end

---@return boolean 是否已解锁
function N23Replay:IsUnlock()
    local cInfo = self.data:GetComponentInfoShop()
    ---@type ExchangeItemComponentItemInfo[]
    local m_exchange_item_list = cInfo.m_exchange_item_list
    for _, exchangeItem in ipairs(m_exchange_item_list) do
        if
            exchangeItem.m_id == self.exchangeId and
                exchangeItem.m_can_exchange_count < exchangeItem.m_exchange_limit_count
         then
            return true
        end
    end
    return false
end
--endregion
