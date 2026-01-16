--region UIHomelandLevelData
---@class UIHomelandLevelData:Object
---@field pstid number 玩家id
---@field liveable number 家园宜居值
---@field LiveableExps HomelandLevelLiveableExpItemData[] 宜居值-签到经验表
---@field expSources HomelandLevelExpSourceItemData[] 经验来源表
---@field level number 当前家园等级
---@field exp number 当前经验值
---@field expSign number 签到可获得的经验
---@field awardSign RoleAsset 签到奖励
---@field signedToday boolean 今天是否已经签到过了
---@field levels HomelandLevelItemData[] 等级信息表
_class("UIHomelandLevelData", Object)
UIHomelandLevelData = UIHomelandLevelData

function UIHomelandLevelData:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
end

function UIHomelandLevelData:Init()
    self.liveable = self.mHomeland:GetAmbientValue()
    self.LiveableExps = {}
    for liveable, cfgv in pairs(Cfg.cfg_homeland_sign()) do
        local item = HomelandLevelLiveableExpItemData:New(liveable)
        table.insert(self.LiveableExps, item)
    end
    self.expSources = {}
    for id, cfgv in pairs(Cfg.cfg_homeland_exp_source()) do
        local item = HomelandLevelExpSourceItemData:New(id)
        table.insert(self.expSources, item)
    end
    self:InitLevelData()
end
---初始化等级信息
function UIHomelandLevelData:InitLevelData()
    ---@type ClientHomelandInfo
    local clientHomelandInfo = self.mHomeland.m_homeland_info
    self.level = clientHomelandInfo.level
    self.exp = clientHomelandInfo.exp
    local sign_info = clientHomelandInfo.sign_info
    -- self.expSign = sign_info.sign_exp --废弃
    -- if sign_info.gift_num > 0 then --废弃
    --     self.awardSign = RoleAsset:New()
    --     local cfgv = Cfg.cfg_homeland_global["SignGiftId"]
    --     self.awardSign.assetid = cfgv.IntValue
    --     self.awardSign.count = sign_info.gift_num
    -- else
    --     self.awardSign = nil
    -- end
    self.awardSign = sign_info.cumulative_rewards --签到奖励改为家园币
    self.signedToday = self.awardSign == nil or #self.awardSign == 0  --累计0天可领说明今天已经领过了

    self.levels = {}
    for level, cfgv in ipairs(Cfg.cfg_homeland_level()) do
        local levelData = HomelandLevelItemData:New(level)
        table.insert(self.levels, levelData)
        local cfgvNext = Cfg.cfg_homeland_level[level + 1]
        if cfgvNext then --有下一等级
            levelData.expLow = cfgv.UpgradeCondition
            levelData.expHigh = cfgvNext.UpgradeCondition
        else --满级
            local cfgvPrev = Cfg.cfg_homeland_level[level - 1]
            levelData.expLow = cfgvPrev.UpgradeCondition
            levelData.expHigh = cfgv.UpgradeCondition
        end

        --region State
        local exist = false
        for _, levelGot in ipairs(sign_info.level_reward_list) do
            if level == levelGot then
                exist = true
                break
            end
        end
        if exist then
            levelData.state = HomelandLevelItemDataState.HasGot
        else
            if self.level >= level then --已达到
                levelData.state = HomelandLevelItemDataState.CanGet
            else
                levelData.state = nil
            end
        end
        --endregion

        levelData.dormitoryLimit = cfgv.ForgeDormitoryLimit
        levelData.landLimit = cfgv.ForgeLandLimit
        levelData.signReward = cfgv.SignRewardList[1][2] --后端支持多个奖励，前端只处理第1个
        levelData.furnitureReward = cfgv.SignRewardList[2][2] --后端支持多个奖励，前端只处理第1个
        levelData.livableValueMax = cfgv.LivableValueMax
        levelData.forgeSequenceCount = cfgv.QueueNum

        --region Award
        levelData.awards = {}
        if cfgv.RewardList then
            for index, award in ipairs(cfgv.RewardList) do
                local ra = RoleAsset:New()
                ra.assetid = award[1]
                ra.count = award[2]
                table.insert(levelData.awards, ra)

                if Cfg.cfg_item_architecture_skin[ra.assetid] then
                    table.insert(levelData.unlockSkins, ra.assetid)
                end
            end
        end

        table.sort(
            levelData.awards,
            function(a, b)
                local colora = Cfg.cfg_item[a.assetid].Color
                local colorb = Cfg.cfg_item[b.assetid].Color
                if colora ~= colorb then
                    return colora > colorb
                end
                return a.assetid < b.assetid
            end
        )
        --endregion
    end
end

function UIHomelandLevelData.CheckCode(result)
    if result == HomeLandErrorType.E_HOME_LAND_TYPE_SUCCESS then
        return true
    end
    local msg = StringTable.Get("str_homeland_error_code_" .. result)
    ToastManager.ShowHomeToast(msg)
    return false
end

---@return table<int, string>
function UIHomelandLevelData:GetLevelDescs(level)
    local res = {}

    local levelData = self:GetHomelandLevelItemDataByLevel(level)
    table.insert(res, StringTable.Get("str_homeland_level_desc_queue_num", levelData.forgeSequenceCount))
    table.insert(res, StringTable.Get("str_homeland_level_desc_dorm_limit", levelData.dormitoryLimit))
    table.insert(res, StringTable.Get("str_homeland_level_desc_land_limit", levelData.landLimit))

    for i = 1, #levelData.unlockSkins do
        local skinCfg = Cfg.cfg_item_architecture_skin[levelData.unlockSkins[i]]
        local skinNameKey = skinCfg.SkinName
        local archNameKey = Cfg.cfg_item_architecture[skinCfg.architecture_id].Name

        table.insert(
            res,
            StringTable.Get(
                "str_homeland_level_desc_arch_skin",
                StringTable.Get(archNameKey),
                StringTable.Get(skinNameKey)
            )
        )
    end

    return res
end

---@return HomelandLevelLiveableExpItemData
function UIHomelandLevelData:GetHomelandLevelLiveableExpItemDataByLiveable(liveable)
    for _, le in ipairs(self.LiveableExps) do
        if le.liveable == liveable then
            return le
        end
    end
end
---@return HomelandLevelExpSourceItemData
function UIHomelandLevelData:GetHomelandLevelExpSourceItemDataById(id)
    for _, source in ipairs(self.expSources) do
        if source.id == id then
            return source
        end
    end
end
---@return HomelandLevelItemData
function UIHomelandLevelData:GetHomelandLevelItemDataByLevel(level)
    for _, levelData in ipairs(self.levels) do
        if levelData.level == level then
            return levelData
        end
    end
end

---是否满级
function UIHomelandLevelData:IsLevelMax()
    if Cfg.cfg_homeland_level[self.level + 1] then
        return false
    end
    return true
end

---有可领取的奖励，等级奖励或签到奖励
function UIHomelandLevelData:HasAward2Get()
    return self:HasLevelAward() or self:HasSignAward()
end

--等级奖励
function UIHomelandLevelData:HasLevelAward()
    for _, levelData in ipairs(self.levels) do
        if levelData.state == HomelandLevelItemDataState.CanGet then
            return true
        end
    end
    return false
end

--签到奖励
function UIHomelandLevelData:HasSignAward()
    local hasAwards = false 
    for i = 1, #self.awardSign do
        if  self.awardSign[i].count > 0 then 
            hasAwards = true 
        end 
    end
    return not self.signedToday and hasAwards
end

---今天是否已签到
function UIHomelandLevelData:HasSignedToday()
    return self.signedToday
end
function UIHomelandLevelData:CheckSignedToday()
    if self.signedToday then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_level_has_signed_today"))
    end
    return self.signedToday
end
---服务器推送CEventPushLevelInfo消息时调用
---@param levelChanged boolean
function UIHomelandLevelData:OnLevelInfoChange(deltaLevel)
    self:InitLevelData()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.HomelandLevelOnLevelInfoChange, deltaLevel,self.level)
end

---获取下次刷新时间戳
function UIHomelandLevelData:GetNextSignTime()
    ---@type ClientHomelandInfo
    local clientHomelandInfo = self.mHomeland.m_homeland_info
    local sign_info = clientHomelandInfo.sign_info
    local stampNextSign = sign_info.next_refresh_time
    return stampNextSign
end
--endregion

--region HomelandLevelLiveableExpItemData
---@class HomelandLevelLiveableExpItemData : Object
---@field liveable number 宜居值
---@field exp number 签到经验
_class("HomelandLevelLiveableExpItemData", Object)
HomelandLevelLiveableExpItemData = HomelandLevelLiveableExpItemData

function HomelandLevelLiveableExpItemData:Constructor(liveable)
    self.liveable = liveable
    local cfgv = Cfg.cfg_homeland_sign[liveable]
    self.exp = cfgv.Exp
end
--endregion

--region HomelandLevelExpSourceItemData 经验来源Item信息
---@class HomelandLevelExpSourceItemData : Object
---@field id number cfg_homeland_exp_source 主键
---@field name string 经验来源item名
---@field details string[] 经验来源item具体表
_class("HomelandLevelExpSourceItemData", Object)
HomelandLevelExpSourceItemData = HomelandLevelExpSourceItemData

function HomelandLevelExpSourceItemData:Constructor(id)
    self.id = id
    local cfgv = Cfg.cfg_homeland_exp_source[id]
    self.name = StringTable.Get(cfgv.Name)
    self.details = {}
    if cfgv.Params then
        for _, param in ipairs(cfgv.Params) do
            local str = StringTable.Get(param[1], param[2])
            table.insert(self.details, str)
        end
    end
end
--endregion

--region HomelandLevelItemData
---@class HomelandLevelItemData : Object 等级item信息
---@field level number 等级
---@field expLow number 该等级最小经验值
---@field expHigh number 该等级最大经验值
---@field state HomelandLevelItemDataState 状态
---@field forgeSequenceCount number 解锁的打造队列数
---@field dormitoryLimit number 宿舍限制数
---@field landLimit number 地块限制数
---@field signReward number 签到奖励(家园币数量)
---@field furnitureReward number 签到奖励(家具币数量)
---@field livableValueMax number 宜居值上限
---@field unlockSkins number[] 解锁皮肤ID列表
---@field awards RoleAsset[] 奖励
_class("HomelandLevelItemData", Object)
HomelandLevelItemData = HomelandLevelItemData

function HomelandLevelItemData:Constructor(level)
    self.level = level
    self.expLow = 0
    self.expHigh = 0
    self.state = nil
    self.dormitoryLimit = 0
    self.landLimit = 0
    self.signReward = 0
    self.furnitureReward = 0
    self.livableValueMax = 0
    self.forgeSequenceCount = 0
    self.unlockSkins = {}
    self.awards = {}

    local mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = mHomeland:GetHomelandLevelData()
end

---@class HomelandLevelItemDataState
---@field HasGot number 已领取
---@field CanGet number 可领取
_enum(
    "HomelandLevelItemDataState",
    {
        HasGot = 1,
        CanGet = 2
    }
)
HomelandLevelItemDataState = HomelandLevelItemDataState
--endregion
