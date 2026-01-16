_class("HPComponent", Object)
---@class HPComponent:Object
HPComponent = HPComponent

function HPComponent:Constructor(redhp, whitehp, maxhp, offset)
    self._redhp = redhp
    self._whitehp = whitehp
    self._maxhp = maxhp
    self._slider_entity_id = -1
    self._hp_offset = offset

    self._shield = 0
    self._curseHp = 0
    self._isShowCurseHp = false


    self._initSep = false
    ---@type number
    self._hpLockSepList = {}
    self._hpLockUnlockedIndexList = {}

    self._sepPoolWidget = nil

    self._posDirty = true
    self._isShowHPSlider = true
    --- TODO临时：血条被创建得太早，会导致玩家的血条显示得非常早
    --- 单独拿出变量来，是希望【启用/禁用】状态与【表现/隐藏】状态分离
    --- 本质上还是血条创建时机相关的东西
    self._isHPBarTempHide = false

    self._uiHpBuffInfoWidget = nil
    self._uiTrapSkillInfoWidget = nil

    ---UI上的控件缓存，避免每次去C#侧取
    self._whiteImageCmpt = nil
    self._redImageCmpt = nil
    self._shieldImageCmpt = nil
    self._curseHpImageCmpt = nil

    ---最近一次改的Percent
    self._lastRedPercent = 0
    self._lastWhitePercent = 0
    ---WorldBoss
    self._isWorldBoss = false
    self._initWorldBossStageHPData = {}
    self._worldBossHPImage = {}
    self._curStage = 1
    self._curStageHP = 0
    self._totalStage = 1
    self._isChessMarked = false
    self._isChessRecoverMarked = false
    self._isWorldBossInit = false
    ---队员预览时切换血条高度使用
    self._useTeamView= true

    --机关次数血条
    self._initTrapSep = false

    self._chessBuffOffset = 74

    self._greyHP = 0
    self._lockPos = false
end

function HPComponent:Dispose()
    self:WidgetPoolCleanup()

    self._whiteImageCmpt = nil
    self._redImageCmpt = nil
    self._shieldImageCmpt = nil
    self._curseHpImageCmpt = nil
    self._sepImageCmpt = nil

    self._ui_csgoChessHP = nil
    self._ui_csTextChessHP = nil
    self._ui_csgoChessAttackTarget = nil
    self._ui_csgoChessRecoverTarget = nil

    if self._ui_widgetPoolChessHPScaleRuler1 then
        self._ui_widgetPoolChessHPScaleRuler1:Dispose()
    end
    if self._ui_widgetPoolChessHPScaleRuler2 then
        self._ui_widgetPoolChessHPScaleRuler2:Dispose()
    end

    self._lockPos = false
end

function HPComponent:WidgetPoolCleanup()
    if (self._sepPoolWidget ~= nil) then
        self._sepPoolWidget:Dispose()
        self._sepPoolWidget = nil
    end
    if self._uiHpBuffInfoWidget then
        self._uiHpBuffInfoWidget:Dispose()
        self._uiHpBuffInfoWidget = nil
    end
    if self._uiTrapSkillInfoWidget then
        self._uiTrapSkillInfoWidget:Dispose()
        self._uiTrapSkillInfoWidget = nil
    end
end

function HPComponent:IsShowHPSlider()
    return self._isShowHPSlider and (not self._isHPBarTempHide)
end

function HPComponent:SetHPBarTempHide(hide)
    self._isHPBarTempHide = hide
end

function HPComponent:IsHPBarTempHide()
    return self._isHPBarTempHide
end

function HPComponent:SetShowHPSliderState(state)
    self._isShowHPSlider = state

    -- 自上次停止更新之后可能位置已经变过了
    if state and self._slider_entity_id > 0 then
        self:SetHPPosDirty(true)
    end
end

function HPComponent:SetSepPoolWidget(sepPool)
    self._sepPoolWidget = sepPool
end

function HPComponent:GetSepPoolWidget()
    return self._sepPoolWidget
end

function HPComponent:IsInitSep()
    return self._initSep
end

function HPComponent:SetInitSepState(state)
    self._initSep = state
end

function HPComponent:SetHPLockSepList(hpLockSepList)
    self._hpLockSepList = hpLockSepList
end

function HPComponent:GetHPLockSepList()
    return self._hpLockSepList
end

function HPComponent:InitHPLockSepList(hpSepList)
    if hpSepList then
        self._hpLockSepList = {}
        for i, v in ipairs(hpSepList) do
            table.insert(self._hpLockSepList, v.hpPercent)
        end
        table.sort(self._hpLockSepList, table.ACS)
    end
end
function HPComponent:AddHPLockUnlockedIndex(hpLockUnlockedIndex)
    table.insert(self._hpLockUnlockedIndexList,hpLockUnlockedIndex)
end
function HPComponent:SetHPLockUnlockedIndexList(hpLockUnlockedIndexList)
    self._hpLockUnlockedIndexList = hpLockUnlockedIndexList
end

function HPComponent:GetHPLockUnlockedIndexList()
    return self._hpLockUnlockedIndexList
end
--region 机关次数血条
function HPComponent:GetShowTrapSep()
    return self._showTrapSep
end

function HPComponent:SetShowTrapSep(state)
    self._showTrapSep = state
end

function HPComponent:IsInitTrapSep()
    return self._initTrapSep
end

function HPComponent:SetInitTrapSepState(state)
    self._initTrapSep = state
end
--endregion 机关次数血条

function HPComponent:InitHP(maxHP)
    self._redhp = maxHP
    self._whitehp = maxHP
    self._maxhp = maxHP
end

function HPComponent:GetRedHP()
    return self._redhp
end

function HPComponent:SetRedHP(new_red_hp)
    self._redhp = math.floor(new_red_hp)
end

function HPComponent:GetWhiteHP()
    return self._whitehp
end

function HPComponent:SetGreyHP(val)
    self._greyHP = val
end

function HPComponent:GetGreyHP()
    return self._greyHP
end

function HPComponent:GetMaxHP()
    return self._maxhp
end

function HPComponent:SetMaxHP(maxhp)
    self._maxhp = maxhp
end

function HPComponent:GetHPOffset()
    return self._hp_offset
end

function HPComponent:SetHPOffset(heightOffset)
    self._hp_offset = Vector3(0, heightOffset, 0)
end

function HPComponent:GetHPSliderEntityID()
    return self._slider_entity_id
end

function HPComponent:SetHPSliderEntityID(slider_entity_id)
    self._slider_entity_id = slider_entity_id
end

function HPComponent:SetShieldValue(shieldVal)
    self._shield = shieldVal
end

function HPComponent:GetShieldValue()
    return self._shield
end
function HPComponent:SetShowCurseHp(set)
    self._isShowCurseHp = set
end
function HPComponent:GetShowCurseHp()
    return self._isShowCurseHp
end
function HPComponent:SetCurseHpValue(shieldVal)
    self._curseHp = shieldVal
end

function HPComponent:GetCurseHpValue()
    return self._curseHp
end
function HPComponent:SetHPPosDirty(dirty,useTeamView)
    self._posDirty = dirty
    if useTeamView ~= nil then
        self._useTeamView  = useTeamView
    end
end

function HPComponent:ResetUseTeamViewState()
    self._useTeamView = true
end

function HPComponent:IsUseTeamView()
    return self._useTeamView
end

function HPComponent:IsHPPosDirty()
    return self._posDirty
end

function HPComponent:ResetHP(curHP, maxHP)
    self._maxhp = maxHP
    self._redhp = math.floor(curHP)
    self._whitehp = self._redhp
end

function HPComponent:SetUIHpBuffInfoWidget(ui)
    self._uiHpBuffInfoWidget = ui
end

function HPComponent:GetUIHpBuffInfoWidget()
    return self._uiHpBuffInfoWidget
end

function HPComponent:SetUITrapSkillInfoWidget(ui)
    self._uiTrapSkillInfoWidget = ui
end

function HPComponent:SetHPImageComponent(white, red, shield, sep, grey,curseHp)
    self._whiteImageCmpt = white
    self._redImageCmpt = red
    self._shieldImageCmpt = shield
    self._sepImageCmpt = sep
    self._greyImageCmpt = grey
    self._curseHpImageCmpt = curseHp
end

---
function HPComponent:SetChessUIComponent(csgoChessHP, csTextChessHP, csgoChessAttackTarget, csgoChessRecoverTarget)
    self._ui_csgoChessHP = csgoChessHP
    self._ui_csTextChessHP = csTextChessHP
    self._ui_csgoChessAttackTarget = csgoChessAttackTarget
    self._ui_csgoChessRecoverTarget = csgoChessRecoverTarget
end

---
function HPComponent:SetChessHPBarGroup(v)
    self._ui_csgoChessHPBarGroup = v
end

---
function HPComponent:SetChessHPWhite1(v)
    self._ui_csImageChessHPWhite1 = v
end

---
function HPComponent:SetChessHPRed1(v)
    self._ui_csgoChessHPRed1 = v
end

---
function HPComponent:SetChessHPScaleRuler1(v)
    self._ui_widgetPoolChessHPScaleRuler1 = v
end

---
function HPComponent:SetChessHPWhite2(v)
    self._ui_csImageChessHPWhite2 = v
end

---
function HPComponent:SetChessHPRed2(v)
    self._ui_csgoChessHPRed2 = v
end

---
function HPComponent:SetChessHPScaleRuler2(v)
    self._ui_widgetPoolChessHPScaleRuler2 = v
end

---
function HPComponent:GetChessHPBarGroup()
    return self._ui_csgoChessHPBarGroup
end

---
function HPComponent:GetChessHPWhite1()
    return self._ui_csImageChessHPWhite1
end

---
function HPComponent:GetChessHPRed1()
    return self._ui_csgoChessHPRed1
end

---
function HPComponent:GetChessHPScaleRuler1()
    return self._ui_widgetPoolChessHPScaleRuler1
end

---
function HPComponent:GetChessHPWhite2()
    return self._ui_csImageChessHPWhite2
end

---
function HPComponent:GetChessHPRed2()
    return self._ui_csgoChessHPRed2
end

---
function HPComponent:GetChessHPScaleRuler2()
    return self._ui_widgetPoolChessHPScaleRuler2
end

---@return UnityEngine.GameObject|nil
function HPComponent:GetUICSGOChessHP()
    if (not self._ui_csgoChessHP) or (tostring(self._ui_csgoChessHP) == "null") then
        return
    end

    return self._ui_csgoChessHP
end

---@return UnityEngine.GameObject|nil
function HPComponent:GetUICSTextChessHP()
    if (not self._ui_csTextChessHP) or (tostring(self._ui_csTextChessHP) == "null") then
        return
    end

    return self._ui_csTextChessHP
end

---@return UnityEngine.GameObject|nil
function HPComponent:GetUICSGOChessAttackTarget()
    if (not self._ui_csgoChessAttackTarget) or (tostring(self._ui_csgoChessAttackTarget) == "null") then
        return
    end

    return self._ui_csgoChessAttackTarget
end

---@return UnityEngine.GameObject|nil
function HPComponent:GetUICSGOChessRecoverTarget()
    if (not self._ui_csgoChessRecoverTarget) or (tostring(self._ui_csgoChessRecoverTarget) == "null") then
        return
    end

    return self._ui_csgoChessRecoverTarget
end

function HPComponent:SetLastRedPercent(percent)
    self._lastRedPercent = percent
end

function HPComponent:SetLastWhitePercent(percent)
    self._lastWhitePercent = percent
end

function HPComponent:GetWhiteImageComponent()
    return self._whiteImageCmpt
end

function HPComponent:GetRedImageComponent()
    return self._redImageCmpt
end

function HPComponent:GetShieldImageComponent()
    return self._shieldImageCmpt
end
function HPComponent:GetCurseHpImageComponent()
    return self._curseHpImageCmpt
end
function HPComponent:GetSepImageComponent()
    return self._sepImageCmpt
end

---@return UnityEngine.UI.Image
function HPComponent:GetGreyImageComponent()
    return self._greyImageCmpt
end

function HPComponent:GetLastRedPercent()
    return self._lastRedPercent
end

function HPComponent:GetLastWhitePercent()
    return self._lastWhitePercent
end

function HPComponent:SetWorldBossState(state)
    self._isWorldBoss = state
end

function HPComponent:IsWorldBoss()
    return self._isWorldBoss
end

function HPComponent:IsInitWorldBoss()
    return self._isWorldBossInit
end

function HPComponent:InitWorldBossHPData(stageData, imageData)
    if self._isWorldBossInit then
        return
    end
    for stageIndex, v in ipairs(stageData) do
        self._initWorldBossStageHPData[stageIndex] = v.hp
    end
    self._worldBossHPImage = imageData
    self._curStage = 1
    self._curStageHP = self._initWorldBossStageHPData[self._curStage]
    self._isWorldBossInit = true
end

function HPComponent:GetCurStageImage()
    local count = table.count(self._worldBossHPImage)
    local index = (self._totalStage - 1) % count + 1
    local id = self._worldBossHPImage[index]
    --Log.fatal("GetCurImageID:", id, " Index:", index)
    return self._worldBossHPImage[index]
end

function HPComponent:GetNextStageImage()
    local count = table.count(self._worldBossHPImage)
    local index = (self._totalStage) % count + 1
    local id = self._worldBossHPImage[index]
    --Log.fatal("GetNextImageID:", id, " Index:", index)
    return self._worldBossHPImage[index]
end
function HPComponent:GetPreStageImage()
    local count = table.count(self._worldBossHPImage)
    local index
    if self._totalStage == 1 then
        index = count
    else
        index = (self._totalStage - 2) % count + 1
    end
    local id = self._worldBossHPImage[index]
    --Log.fatal("GetPreImageID:", id, " Index:", index)
    return self._worldBossHPImage[index]
end

function HPComponent:SwitchStage()
    if self._curStage ~= table.count(self._initWorldBossStageHPData) then
        self._curStage = self._curStage + 1
    end
    self._totalStage = self._totalStage + 1
    --Log.fatal("RenderStage:",self._curStage)
    self._curStageHP = self._initWorldBossStageHPData[self._curStage]
end

function HPComponent:GetCurStageHPPercent()
    local initCurStageHP = self._initWorldBossStageHPData[self._curStage]
    local percent = self._curStageHP / initCurStageHP
    return percent
end

function HPComponent:GetCurStageHP()
    return self._curStageHP
end

function HPComponent:SetStageHP(hp)
    self._curStageHP = hp
end

function HPComponent:GetCurStage()
    return self._curStage
end

function HPComponent:SetChessTargetedMark(isMarked, isRecover)
    self._isChessMarked = isMarked
    self._isChessRecoverMarked = isRecover
end

function HPComponent:GetChessTargetedMark() return self._isChessMarked end

function HPComponent:GetChessRecoverMark()
    return self._isChessRecoverMarked
end

function HPComponent:SetLockPos(b)
    self._lockPos = b
end

function HPComponent:IsPosLocked()
    return self._lockPos
end

--------------------------------------------------------------
--------------------------------------------------------------
---@return HPComponent
function Entity:HP()
    return self:GetComponent(self.WEComponentsEnum.HP)
end

function Entity:HasHP()
    return self:HasComponent(self.WEComponentsEnum.HP)
end

function Entity:AddHP(redhp, whitehp, maxhp, offset)
    self:AddComponent(self.WEComponentsEnum.HP, HPComponent:New(redhp, whitehp, maxhp, offset))
end

---获取Entity的UI红血量
function Entity:GetRedHP()
    ---@type HPComponent
    local hp = self:HP()
    if nil == hp then
        return -1
    end
    return hp:GetRedHP()
end

---获取Entity的UI白血量
function Entity:GetWhiteHP()
    ---@type HPComponent
    local hp = self:HP()
    if nil == hp then
        return -1
    end
    return hp:GetWhiteHP()
end

---重置红血量
function Entity:ReplaceRedHP(redhp)
    ---@type HPComponent
    local hp = self:HP()
    hp:SetRedHP(redhp)

    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceRedHPAndWhitHP(redhp)
    ---@type HPComponent
    local hp = self:HP()
    hp:SetRedHP(redhp)
    hp._whitehp = redhp
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceRedAndMaxHP(curHP, maxHP)
    local hp = self:HP()
    hp:ResetHP(curHP, maxHP)
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceMaxHP(maxHp)
    ---@type HPComponent
    local hp = self:HP()
    hp:SetMaxHP(maxHp)
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceInitHPLockSepList(hpSepList)
    ---@type HPComponent
    local hp = self:HP()
    hp:InitHPLockSepList(hpSepList)

    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceHPComponent()
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceChessTargetedMark(isMarked, isRecover)
    local hp = self:HP()
    hp:SetChessTargetedMark(isMarked, isRecover)

    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:ReplaceGreyHP(v)
    v = v or 0
    self:HP():SetGreyHP(v)
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end

function Entity:TriggerHPUpdate()
    self:ReplaceComponent(self.WEComponentsEnum.HP, self:HP())
end


_class("HPLockSep", Object)
---@class HPLockSep:Object
HPLockSep = HPLockSep

function HPLockSep:Constructor()
    self._lockPercent = 0
end

---@class HPBarType
local HPBarType = {
    NormalMonster = 1, --普通怪物
    EliteMonster = 2, --精英怪物
    Trap = 3, --机关
    Boss = 4, --Boss
    EliteBoss = 5, --精英Boss
    BlackFist = 6, ---黑拳赛
    ChessPet = 7,
}
_enum("HPBarType", HPBarType)
