---@class UICommonLoading:UIController
_class("UICommonLoading", UIController)
UICommonLoading = UICommonLoading

local MIN_TIME = 3000
local ATLAS_NAME = "UILoading.spriteatlas"
local RATE = 3
function UICommonLoading:Constructor()
    self._processValue = 0
    self._loadingType = LoadingType.STATICPIC
end

---@protected
function UICommonLoading:OnShow(uiParams)
    self:InitComponents()
    self:AddListener()
    self._loadingType = uiParams and uiParams[1] or LoadingType.STATICPIC
    local loadingId = uiParams[2]
    self._loadLevelEnd = false
    self._goSTATICPIC:SetActive(self._loadingType == LoadingType.STATICPIC)
    self._goBOTTOM:SetActive(self._loadingType == LoadingType.BOTTOM)
    if self._loadingType == LoadingType.BOTTOM then
        self._blurMaskObject:SetActive(false)
    elseif self._loadingType == LoadingType.STATICPIC then
        self:FlushStaticPic(loadingId)
    else
        Log.warn("### LoadingType=", self._loadingType)
    end

    GameGlobal.TaskManager():StartTask(self.DelayExcute, self)
end
--
function UICommonLoading:FlushStaticPic(loadingId)
    if not loadingId then
        local match = self:GetModule(MatchModule)
        local enterData = match:GetMatchEnterData()
        local levelId = enterData and enterData._level_id or nil
        local cfg_level = levelId and Cfg.cfg_level[levelId]
        if cfg_level then
            local loadingIds = cfg_level.LoadingId
            if loadingIds then
                if #loadingIds == 1 then
                    loadingId = loadingIds[1]
                else
                    local idx = math.random(1, #loadingIds)
                    loadingId = loadingIds[idx]
                end
            end
        end
    end
    local cfg = self:GetLoadingCfg(loadingId)
    -- 如果右边一个配置都没有隐藏右侧根
    -- TODO优化 可加一个字段控制整体隐藏
    if cfg and not cfg.Icon and not cfg.CName and not cfg.EName and not cfg.Desc then
        self._locationMiddle:SetActive(false)
    else
        self._locationMiddle:SetActive(true)
    end
    if cfg then
        -- 检查中文名
        if cfg.CName then
            self._cName:SetText(StringTable.Get(cfg.CName))
        else
            self._cName:SetText("")
        end
        -- 检查英文名
        if cfg.EName then
            self._eName:SetText(StringTable.Get(cfg.EName))
        else
            self._eName:SetText("")
        end
        --检查描述
        if cfg.Desc then
            self._desc:SetText(StringTable.Get(cfg.Desc))
        else
            self._desc:SetText("")
        end
        --检查新配置里的时间段
        --符合用配置的cg，不然用以前的loading图
        local newCg = self:CheakNewCG()
        if newCg then
            self._rawImageLoader:LoadImage(newCg)
        else
            if cfg.Cg then
                self._rawImageLoader:LoadImage(cfg.Cg)
            end
        end
    end
    self._blurMaskObject:SetActive(false)
end
--
function UICommonLoading:CheakNewCG()
    --获取utc0的当前时间
    local nowTime = math.ceil(GameGlobal.GetModule(SvrTimeModule):GetServerTime()*0.001)
    local cfgs = Cfg.cfg_loading_cg{}
    if cfgs and table.count(cfgs)>0 then
        for i = 1, #cfgs do
            local cfg = cfgs[i]
            local startTime = cfg.StartTime
            local endTime = cfg.EndTime

            if cfg.Active and startTime and endTime then
                local inner = self:CheckInner(nowTime,startTime,endTime)
                
                if inner then
                    return cfg.Cg
                end
            end
        end
    end
end
--
function UICommonLoading:CheckInner(nowTime,startTime,endTime)
    local inner = false
    local open = GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(startTime,Enum_DateTimeZoneType.E_ZoneType_GMT)
    local close = GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(endTime,Enum_DateTimeZoneType.E_ZoneType_GMT)
    if nowTime >= open and nowTime < close then
        inner = true
    end
    return inner
end

function UICommonLoading:DelayExcute(TT)
    if self._loadingType == LoadingType.PROGRESS then
        YIELD(TT, MIN_TIME) --PROGRESS类型需要至少等N秒
    end
    while not self._loadLevelEnd do
        YIELD(TT) --加载没结束会卡住流程
    end
    if self._loadingType == LoadingType.PROGRESS then
        while self._processValue < 100 do
            YIELD(TT) --PROGRESS类型，进度不到100会卡住主流程
        end
    end
    local lm = GameGlobal.LoadingManager()
    if lm then
        lm:Excute()
    else
        Log.fatal("### LoadingManager is nil.")
    end
end

---@protected
function UICommonLoading:OnHide()
    self:RemoveListener()
end

---@private
function UICommonLoading:HandleLoadingUpdate(value)
    if self._loadingType == LoadingType.PROGRESS then
        self._processValue = value
    end
end

function UICommonLoading:HandleLoadLevelEnd(loaded)
    self._loadLevelEnd = loaded
end

---@private
function UICommonLoading:GetLoadingCfg(loadingId)
    local cfg_loading = Cfg.cfg_loading {}
    if not cfg_loading then
        Log.fatal("cfg_loading is nil !")
        return
    end
    local idx
    if loadingId then
        return cfg_loading[loadingId]
    else
        idx = math.random(1, table.count(cfg_loading))
        return cfg_loading[idx]
    end
end

function UICommonLoading:InitComponents()
    self._blurMask = self:GetUIComponent("H3DUIBlurHelper", "BlurMask")
    self._blurMaskObject = self:GetGameObject("BlurMask")
    self._rawImageLoader = self:GetUIComponent("RawImageLoader", "RawImage")
    self._icon = self:GetUIComponent("Image", "Icon")
    self._cName = self:GetUIComponent("UILocalizationText", "ChinaName")
    self._eName = self:GetUIComponent("UILocalizationText", "EngLishName")
    self._desc = self:GetUIComponent("UILocalizationText", "Desc")
    self._descRect = self:GetUIComponent("RectTransform", "Desc")
    self._locationMiddle = self:GetGameObject("LocationMiddle")
    self._goSTATICPIC = self:GetGameObject("STATICPIC")
    self._goSTATICPIC:SetActive(false)
    self._goBOTTOM = self:GetGameObject("BOTTOM")
    self._goBOTTOM:SetActive(false)
end

function UICommonLoading:AddListener()
    self:AttachEvent(GameEventType.LoadingProgressChanged, self.HandleLoadingUpdate)
    self:AttachEvent(GameEventType.LoadLevelEnd, self.HandleLoadLevelEnd)
end

function UICommonLoading:RemoveListener()
    self:DetachEvent(GameEventType.LoadingProgressChanged, self.HandleLoadingUpdate)
    self:DetachEvent(GameEventType.LoadLevelEnd, self.HandleLoadLevelEnd)
end
