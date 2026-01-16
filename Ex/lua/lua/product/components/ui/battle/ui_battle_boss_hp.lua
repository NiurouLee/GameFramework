---@class UIBattleBossHP : UICustomWidget
_class("UIBattleBossHP", UICustomWidget)
UIBattleBossHP = UIBattleBossHP

function UIBattleBossHP:Constructor()
end

function UIBattleBossHP:OnShow()
    self._goHP2 = self:GetGameObject("hp2") --1/2个血条
    ---@type UICustomWidgetPool
    self._hp2 = self:GetUIComponent("UISelectObjectPath", "hp2")
    ---@type UIBossHPInfo
    self._hpList = {}
    self._hp2:SpawnObjects("UIBossHPInfo", 2)
    self._hpList = self._hp2:GetAllSpawnList()
    self._hpInfo1 = self._hpList[1]
    self._hpInfo2 = self._hpList[2]
    for _, v in ipairs(self._hpList) do
        v:SetActive(false)
    end
    self._haveBoss = false --只有一个boss的时候有意义
    self._isCurrentBoss = false --只有一个boss的时候有意义
    self._isBossLive = false --只有一个boss的时候有意义
    self._bossEntityID = nil
    self._goHP4 = self:GetGameObject("hp4") --4个血条
    ---@type UICustomWidgetPool
    self._hp4 = self:GetUIComponent("UISelectObjectPath", "hp4")

    self._goName = self:GetGameObject("name")
    self._goName:SetActive(false)
    self._txtBossName = self:GetUIComponent("UILocalizationText", "txtBossName")
    self._rtRect = self:GetUIComponent("RectTransform", "txtBossName")
    self._revolvingText = self:GetUIComponent("RevolvingTextWithDynamicScroll", "RevolvingText")

    self:AttachEvent(GameEventType.ShowBossHp, self.ShowBossHp)
    self:AttachEvent(GameEventType.HideBossHp, self.HideBossHp)
    self:AttachEvent(GameEventType.PreviewMonsterReplaceHPBar, self.ShowPreviewMonsterReplaceHPBar)
    self:AttachEvent(GameEventType.RevokePreviewMonsterReplaceHPBar, self.RevokePreviewMonsterReplaceHPBar)
end

function UIBattleBossHP:OnHide()
    self:DetachEvent(GameEventType.ShowBossHp, self.ShowBossHp)
    self:DetachEvent(GameEventType.HideBossHp, self.HideBossHp)
    self:DetachEvent(GameEventType.PreviewMonsterReplaceHPBar, self.ShowPreviewMonsterReplaceHPBar)
    self:DetachEvent(GameEventType.RevokePreviewMonsterReplaceHPBar, self.RevokePreviewMonsterReplaceHPBar)
end

function UIBattleBossHP:FlushName(bossId)
    if self._txtBossName then
        local tplId = bossId.tplId
        ---@type MonsterConfigData
        local monsterConfigData = ConfigServiceHelper.GetMonsterConfigData()
        self._cfgMonsterClass = monsterConfigData:GetMonsterClass(tplId)
        local name = StringTable.Get(self._cfgMonsterClass.Name)
        -- self._txtBossName.text = StringTable.Get("str_battle_bracket", name)
        --超出文本宽度自动滚动，组件只计算了一个文本的宽度。修改为由Name的文本前方添加11个空格，来填充“BOSS”文本占的宽度，“BOSS”文本则缩进Name的范围内左对齐。

        local textOffset = ""
        self._txtBossName.text = StringTable.Get("str_battle_bracket", "")
        local width = self._txtBossName.preferredWidth

        --根据多语言 判断这个BOSS名字外框的长度是多少
        if width <= 20 then
            textOffset = "  "
        elseif width > 20 and width < 50 then
            textOffset = " "
        elseif width >= 50 then
            textOffset = ""
        end

        self._txtBossName.text = "           " .. textOffset .. StringTable.Get("str_battle_bracket", name)

        self._rtRect.sizeDelta = Vector2(self._txtBossName.preferredWidth, 45)
        if self._revolvingText then
            self._revolvingText:OnRefreshRevolving()
        end
    end
end

---@param bossIds SortedArray
function UIBattleBossHP:ShowBossHp(bossIds, isWorldBoss)
    local info = bossIds:GetAt(1)
    if self._bossEntityID == info.pstId then
        return
    end

    self._bossEntityID = info.pstId
    self._haveBoss = true
    self._hpInfo1:SetActive(true)
    self._isBossLive = true
    self._isCurrentBoss = true
    self._hpInfo1:Flush(bossIds:GetAt(1), isWorldBoss)
end
function UIBattleBossHP:HideBossHp(entityID)
    if entityID ~= self._bossEntityID then
        return
    end
    self:ShowHideBossHp2(false)
end

function UIBattleBossHP:ShowHideBossHp2(isShow)
    if self._haveBoss then
        self._isBossLive = false
        self._hpInfo1:SetActive(isShow)
    end
end

function UIBattleBossHP:ShowPreviewMonsterReplaceHPBar(info)
    ---@type UIBossHPInfo
    local hpInfo
    if self._haveBoss then
        if info.pstId == self._bossEntityID and self._isCurrentBoss then
            return
        end
        self._isCurrentBoss = false
        hpInfo = self._hpInfo2
        self._hpInfo1:SetActive(false)
        self._hpInfo2:SetActive(true)
    else
        hpInfo = self._hpInfo1
        self._hpInfo1:SetActive(true)
    end
    hpInfo:Flush(info)
    if info.isWorldBoss then
        hpInfo:InitWorldBossHP(info)
        hpInfo:PreviewSetWorldBossHP(info)
    else
        hpInfo:PreviewRevertWorldBossStyle()
    end
end

function UIBattleBossHP:RevokePreviewMonsterReplaceHPBar()
    if self._haveBoss then
        self._isCurrentBoss = true
        self._hpInfo1:SetActive(self._isBossLive)
        self._hpInfo2:SetActive(false)
    else
        self._hpInfo1:SetActive(false)
    end
end
