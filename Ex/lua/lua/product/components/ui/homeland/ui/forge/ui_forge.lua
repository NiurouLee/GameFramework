---@class UIForge:UIController
_class("UIForge", UIController)
UIForge = UIForge

function UIForge:Constructor()
    self.mHomeland = GameGlobal.GetModule(HomelandModule)
    self.data = self.mHomeland:GetForgeData()
    self.data:ResetSort() --每次打开都重置排序
    self.data.filter = 0
    self.data:Init(self.mHomeland:GetHomelandInfo())
    self.data:FilterList()
    self._firstItem = nil
    self._firstSquenceItem = nil
    self._fourthTagItem = nil
end

function UIForge:OnShow(uiParams)
    ---@type UnityEngine.RectTransform
    self.cTypeRect = self:GetUIComponent("RectTransform", "cType")
    ---@type UICustomWidgetPool
    self.cType = self:GetUIComponent("UISelectObjectPath", "cType")
    ---@type UILocalizationText
    self.txtSequence = self:GetUIComponent("UILocalizationText", "txtSequence")
    self.imgClock = self:GetGameObject("imgClock")
    self.redSequence = self:GetGameObject("redSequence")
    self.redSequence:SetActive(false)
    self.goSort = self:GetGameObject("sort")
    ---@type UICustomWidgetPool
    self.sort = self:GetUIComponent("UISelectObjectPath", "sort")
    self.goEconomy = self:GetGameObject("economy")
    ---@type UICustomWidgetPool
    self.economy = self:GetUIComponent("UISelectObjectPath", "economy")
    self.list = self:GetGameObject("list")
    self.sequence = self:GetGameObject("sequence")
    ---@type UICustomWidgetPool
    self.cList = self:GetUIComponent("UISelectObjectPath", "cList")
    ---@type UICustomWidgetPool
    self.cSequence = self:GetUIComponent("UISelectObjectPath", "cSequence")

    self.oneKeyUnlockBtn = self:GetGameObject("OneKeyUnlock")

    self:AttachEvent(GameEventType.ShowHideListSequence, self.ShowHideListSequence)
    self:AttachEvent(GameEventType.HomelandForgeUpdateList, self.FlushList)
    self:AttachEvent(GameEventType.HomelandForgeUpdateSequence, self.FlushSequence)
    self:AttachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self.HomelandLevelOnLevelInfoChange)

    self:Init()
    self:ShowHideListSequence(true)
    self:Flush()
    self:_CheckGuide()
end
function UIForge:OnHide()
    self:DetachEvent(GameEventType.ShowHideListSequence, self.ShowHideListSequence)
    self:DetachEvent(GameEventType.HomelandForgeUpdateList, self.FlushList)
    self:DetachEvent(GameEventType.HomelandForgeUpdateSequence, self.FlushSequence)
    self:DetachEvent(GameEventType.HomelandLevelOnLevelInfoChange, self.HomelandLevelOnLevelInfoChange)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIHomelandMain)
    if self._moveTask then
        GameGlobal.TaskManager():KillTask(self._moveTask)
        self._moveTask = nil
    end
end

--region Init
function UIForge:Init()
    self:InitTypeTree()
    self:InitSort()
    self:InitEconomy()
end
function UIForge:InitTypeTree()
    local len = table.count(self.data.filters)
    self.cType:SpawnObjects("UIForgeTypeTreeItem", len)
    ---@type UIForgeTypeTreeItem[]
    local uis = self.cType:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        local id = self.data.filters[i].id
        ui:Init(id)
        if id == 0 then
            ui:FoldFilter(0)
        end
        if id == 4 then
            self._fourthTagItem = ui
        end
    end
end
function UIForge:InitSort()
    local len = table.count(ForgeSortType)
    self.sort:SpawnObjects("UIForgeSort", len)
    ---@type UIForgeSort[]
    local uis = self.sort:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Init(i)
    end
end
function UIForge:InitEconomy()
    self.economy:SpawnObject("UIForgeEconomy")
end
--endregion

function UIForge:Flush()
    self:FlushSequence()
    self:GuideSort()
    self:FlushList()
end

function UIForge:GuideSort()
    if self:GetModule(GuideModule):IsGuideProcessKey("guide_dormitory_build") then
        local cfg = Cfg.cfg_guide_const["guide_dormitory_build"]
        local temp = nil
        for i = 1, #self.data.list do
            if self.data.list[i].id == cfg.ArrayValue[1] then
                temp = self.data.list[i]
                table.remove(self.data.list, i)
                break
            end
        end
        if temp then
            table.insert(self.data.list, 1, temp)
        end
    end
end

function UIForge:FlushList(needFlushData)
    local len = table.count(self.data.list)
    self.cList:SpawnObjects("UIForgeItem", len)
    ---@type UIForgeItem[]
    local uis = self.cList:GetAllSpawnList()
    self._firstItem = nil
    for i, ui in ipairs(uis) do
        local item = self.data.list[i]
        if item then
            ui:Flush(item.id)
        end
        if not self._firstItem then
            self._firstItem = ui
        end
    end
    self.oneKeyUnlockBtn:SetActive(self.data:HasCanUnlockItem() and self._isShowList)
    self:FlushSort()
end
function UIForge:FlushSort()
    ---@type UIForgeSort[]
    local uis = self.sort:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Flush()
    end
end

function UIForge:FlushSequence()
    local len = table.count(self.data.sequnces)
    self.cSequence:SpawnObjects("UIForgeSequenceItem", len)
    ---@type UIForgeSequenceItem[]
    local uis = self.cSequence:GetAllSpawnList()
    self._firstSquenceItem = nil
    for i, ui in ipairs(uis) do
        ui:Flush(self.data.sequnces[i].index)
        if not self._firstSquenceItem then
            self._firstSquenceItem = ui
        end
    end
    self:FlushSequenceButton()
    self.oneKeyUnlockBtn:SetActive(false)
end
function UIForge:FlushSequenceButton()
    local mapStateCount = self.data:GetSequenceStateCountMap()
    local countForging = mapStateCount[ForgeSequenceState.Forging]
    local countGetable = mapStateCount[ForgeSequenceState.Getable]
    local countIdle = mapStateCount[ForgeSequenceState.Idle]
    local countLocked = mapStateCount[ForgeSequenceState.Locked]

    --先显示红点，红点领完了，显示打造中的沙漏。——徐小庆2022-5-24
    self.redSequence:SetActive(false)
    self.imgClock:SetActive(false)
    if countGetable > 0 then
        self.redSequence:SetActive(true)
    else
        if countForging > 0 then
            self.imgClock:SetActive(true)
        end
    end

    if countForging > 0 then
        self.txtSequence:SetText(
            StringTable.Get(
                "str_homeland_forge_sequence_produce_ing",
                countForging,
                countForging + countGetable + countIdle
            )
        ) --生产中M/N
    else
        self.txtSequence:SetText(StringTable.Get("str_homeland_forge_sequence_produce_list")) --生产队列
    end

    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshInteractUI)
end

function UIForge:HomelandLevelOnLevelInfoChange()
    self.data:Init(self.mHomeland:GetHomelandInfo())
    self:FlushSequence()
end

function UIForge:ShowHideListSequence(isShowList)
    if isShowList then
        self.goSort:SetActive(true)
        self.goEconomy:SetActive(false)
        self.list:SetActive(true)
        self.sequence:SetActive(false)
    else
        self.goSort:SetActive(false)
        self.goEconomy:SetActive(true)
        self.list:SetActive(false)
        self.sequence:SetActive(true)
    end
    self._isShowList = isShowList
end

---@param uiText UILocalizationText | RollingText
---@param time number 时间戳
function UIForge.FlushCDText(uiText, time, strs, isUILocalizationText)
    local leftSeconds = UICommonHelper.CalcLeftSeconds(time)
    local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
    local SetText = function(str)
        if isUILocalizationText then
            uiText:SetText(str)
        else
            uiText:RefreshText(str)
        end
    end
    if d >= 1 then
        if h >= 1 then
            SetText(StringTable.Get(strs[1], math.floor(d), math.floor(h)))
        else
            SetText(StringTable.Get(strs[2], math.floor(d)))
        end
    else
        if h >= 1 then
            if m >= 1 then
                SetText(StringTable.Get(strs[3], math.floor(h), math.floor(m))) --不能用ceil，避免出现1小时60分
            else
                SetText(StringTable.Get(strs[4], math.floor(h)))
            end
        else
            if m >= 1 then
                SetText(StringTable.Get(strs[5], math.floor(m)))
            else
                SetText(StringTable.Get(strs[5], "<1"))
            end
        end
    end
end

function UIForge.GetTimestampStr(timeDelta, strs)
    local d, h, m, s = UICommonHelper.S2DHMS(timeDelta)
    local str = ""
    if d >= 1 then
        if h >= 1 then
            str = StringTable.Get(strs[1], math.ceil(d), math.ceil(h))
        else
            str = StringTable.Get(strs[2], math.ceil(d))
        end
    else
        if h >= 1 then
            if m >= 1 then
                str = StringTable.Get(strs[3], math.ceil(h), math.ceil(m))
            else
                str = StringTable.Get(strs[4], math.ceil(h))
            end
        else
            if m >= 1 then
                str = StringTable.Get(strs[5], math.ceil(m))
            else
                str = StringTable.Get(strs[5], "<1")
            end
        end
    end
    return str
end

function UIForge:btnBackOnClick()
    self:CloseDialog()
end

function UIForge:btnInfoOnClick()
    self:ShowDialog("UIHomeHelpController", "UIForge")
end

function UIForge:btnSequenceOnClick()
    self:ShowHideListSequence(false)
    self:FlushSequence()
end

function UIForge:OneKeyUnlockOnClick()
    self:ShowDialog("UIForgeOneKeyUnlock")
end

function UIForge:GeForgeItem()
    return self._firstItem:GetGameObject("bg")
end

function UIForge:GeForgeFirstSquenceItemBg()
    return self._firstSquenceItem:GetGameObject("bg")
end

function UIForge:GeForgeFirstSquenceItemSpeedBtn()
    return self._firstSquenceItem:GetGameObject("btnSpeed")
end

function UIForge:GeForgeFirstSquenceBtnGet()
    return self._firstSquenceItem:GetGameObject("BtnGet")
end

function UIForge:GetSpecialTagItem()
    return self._fourthTagItem:GetGameObject("bg")
end

function UIForge:GetLandTagItem()
    self._moveTask = self:StartTask(
        function (TT)
            YIELD(TT, 100)
            if self.cTypeRect then
                self.cTypeRect.anchoredPosition = Vector2(self.cTypeRect.anchoredPosition.x, 120)
            end
        end
    )
    return self._fourthTagItem:GetLandBtn()
end

function UIForge:_CheckGuide()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideOpenUI, GuideOpenUI.UIForge)
end
