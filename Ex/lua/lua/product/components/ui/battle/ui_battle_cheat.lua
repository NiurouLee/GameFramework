---@class UIBattleCheatHideUIArea
local UIBattleCheatHideUIArea = {
    LeftUp = 1,
    LeftDown = 2,
    AutoArea = 3,
    StateArea = 4,
    DebugInfo = 5,
    CheatBtn = 6,
    DamageDisplay = 7,
}
_enum("UIBattleCheatHideUIArea", UIBattleCheatHideUIArea)
--------------------------
---@class UIBattleCheat : UIController
_class("UIBattleCheat", UIController)
UIBattleCheat = UIBattleCheat

function UIBattleCheat:OnShow(uiparam)
    self._infoPanelGo = self:GetGameObject("InfoPanel")
    self._infoContent = self:GetGameObject("Content")
    self._infoLabel = self:GetGameObject("InfoLabel")
    self._infoPanelGo:SetActive(false)
    local input = self:GetUIComponent("InputField", "InputAttack")
    input.text = uiparam[1]
    self._infoLabels = {self._infoLabel}
    self._logIndex = 1

    local idx = BattleConst.AutoFightMoveEnhanced and 2 or 1
    local inputComplex = self:GetUIComponent("InputField","InputComplex")
    inputComplex.text = tostring(BattleConst.AutoFightPathComplexity[idx])
    local inputCnt = self:GetUIComponent("InputField","InputConnectCnt")
    inputCnt.text = tostring(BattleConst.AutoFightPathLengthCutPosNum)
    local inputRate = self:GetUIComponent("InputField","InputConnectRate")
    inputRate.text = tostring(BattleConst.AutoFightPathLengthCutConnectRate[idx])

    self._cheatHideUIRecord = uiparam[2] or {}
    self:_RefreshHideUIToggle()
end

function UIBattleCheat:BlackBGOnClick(go)
    ---取出TimeScale，并设置
    local input = self:GetUIComponent("InputField", "ModifyTimeScale")
    local scale = tonumber(input.text)
    if scale then
        BattleConst.TimeSpeedList[2] = scale
    end

    GameGlobal.GameRecorder():RecordAction(
        GameRecordAction.UIInput,
        {ui = "UIBattleCheat", input = "BlackBGOnClick", args = {}}
    )
    self:CloseDialog()
end

--热更
function UIBattleCheat:ReloadConfigOnClick(go)
    CfgClear("cfg_skill_view")
    CfgClear("cfg_battle_skill")
    CfgClear("cfg_pet_battle_skill")
    ConfigServiceHelper.ClearSkillConfigData()
end

--满血
function UIBattleCheat:HeroFullHPOnClick(go)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatHeroMaxHP")
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)
end

--满cd
function UIBattleCheat:FullPowerOnClick(go)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatTeamPowerFull")
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)
end
--怪无敌
function UIBattleCheat:MonsterInvincibleOnClick(go)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatMonsterInvincible")
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

--人攻击Max
function UIBattleCheat:AttackMaxOnClick(go)
    local input = self:GetUIComponent("InputField", "InputAttack")
    local attack = tonumber(input.text)
    self:_HeroAttack(attack)
end

function UIBattleCheat:_HeroAttack(attack)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatAttackMax")
    cmd:SetFuncParam(attack)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end
--局内加光灵 临时
function UIBattleCheat:AddPetButtonOnClick(go)
    local input = self:GetUIComponent("InputField", "InputAddPetInfo")
    local infoStr = input.text
    if not infoStr then
        return
    end
    local params = string.split(infoStr, ",")
    if params and #params > 0 then
        local createInfo = {}
        createInfo.petID = tonumber(params[1])
        createInfo.level = tonumber(params[2])
        createInfo.grade = tonumber(params[3])--游戏里的觉醒
        createInfo.awake = tonumber(params[4])--游戏里的突破
        createInfo.equip = tonumber(params[5])
        createInfo.atk = tonumber(params[6])
        createInfo.def = tonumber(params[7])
        createInfo.hp = tonumber(params[8])

        self:_AddPet(createInfo)
    else
        return
    end
end

function UIBattleCheat:_AddPet(createInfo)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatAddPet")
    cmd:SetFuncParam(createInfo)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)
end
--恢复正常
function UIBattleCheat:GetRightOnClick(go)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatGetRight")
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

---自动无限召唤
function UIBattleCheat:AutoSummonOnClick(go)
    -- 这个是最早尝试在一个关卡里重复召唤不同怪物的实现，后面已经不再使用
    -- 996号机关没有用了，相关的AI和AI执行节点早就删掉了
end

--怪物全灭
function UIBattleCheat:KillMonstersOnClick()
    local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
    if coreGameStateID ~= GameStateID.WaitInput then
        Log.exception("请在玩家可以连线时使用此GM")
        return
    end

    ---@type MainWorld
    local world = GameGlobal:GetInstance():GetMainWorld()

    ---@type PreviewMonsterTrapService
    local prvwSvc = world:GetService("PreviewMonsterTrap")
    prvwSvc:ClearPreviewMonster()
    
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleKillMonsters")
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)
end

function UIBattleCheat:StartProfilerOnClick()
    GameGlobal.StartProfiler()
end
function UIBattleCheat:StopProfilerOnClick()
    GameGlobal.StopProfiler()
end
function UIBattleCheat:CancelFrameRateOnClick()
    UnityEngine.Application.targetFrameRate = 60
    -----@type MainWorld
    --local world = GameGlobal:GetInstance():GetMainWorld()
    -----@type RenderEntityService
    --local rsvcEntity = world:GetService("RenderEntity")
    --rsvcEntity:ClearTrapAreaOutlineEntity()
    --
    -----@type UtilScopeCalcServiceShare
    --local utilScopeSvc = world:GetService("UtilScopeCalc")
    -----@type SkillScopeCalculator
    --local calc = SkillScopeCalculator:New(utilScopeSvc)
    --
    -----@type Entity
    --local eLocalTeam = world:Player():GetLocalTeamEntity()
    -----@type Entity
    --local eFakeCaster = eLocalTeam:Team():GetTeamPetEntities()[1]
    --local scopeResult = calc:ComputeScopeRange(
    --        SkillScopeType.FullscreenExceptSafeZone,
    --        {
    --            safeAreaMode=1, safeAreaParam={14},
    --            safeAreaScopeType = 1,
    --            safeAreaScopeParam = {1, 1, 1},
    --        },
    --        eFakeCaster:GetGridPosition(),
    --        {Vector2.zero},
    --        eFakeCaster:GetGridDirection(),
    --        SkillTargetType.Monster,
    --        eFakeCaster:GetGridPosition(),
    --        eFakeCaster
    --)
    --
    --rsvcEntity:CreateTrapAreaOutlineEntity(scopeResult:GetAttackRange(), "eff_2902701_gezi_01.prefab")
end

--给队长挂buff
function UIBattleCheat:AddBuffHeroOnClick(go)
    local input = self:GetUIComponent("InputField", "InputBuffID")
    local buffID = tonumber(input.text)

    self:_HeroAddBuff(buffID)
end

function UIBattleCheat:_HeroAddBuff(buffID)

    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatAddBuffHero")
    cmd:SetFuncParam(buffID)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

--给队长删buff
function UIBattleCheat:RemoveBuffHeroOnClick(go)
    local input = self:GetUIComponent("InputField", "InputRemoveBuffID")
    local buffID = tonumber(input.text)

    self:_HeroRemoveBuff(buffID)
end

function UIBattleCheat:_HeroRemoveBuff(buffID)

    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatRemoveBuffHero")
    cmd:SetFuncParam(buffID)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

--给怪物挂buff
function UIBattleCheat:AddBuffAllMonstersOnClick(go)
    local input = self:GetUIComponent("InputField", "InputBuffID2")
    local buffID = tonumber(input.text)

    self:_MonsterAddBuff(buffID)
end

function UIBattleCheat:_MonsterAddBuff(buffID)

    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatAddBuffAllMonsters")
    cmd:SetFuncParam(buffID)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

function UIBattleCheat:changeAllMonstersHPPercentOnClick(go)
    local input = self:GetUIComponent("InputField", "InputHPPercent")
    local hppercent = tonumber(input.text)

    self:_ChangeMonsterHP(hppercent)
end

function UIBattleCheat:_ChangeMonsterHP(hppercent)

    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatChangeAllMonstersHPPercent")
    cmd:SetFuncParam(hppercent)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

function UIBattleCheat:CloseInfoPanelOnClick(go)
    self._infoPanelGo:SetActive(false)
end

function UIBattleCheat:OutPutOnClick(go)
    local world = GameGlobal:GetInstance():GetMainWorld()
    world:GetMatchLogger():SaveMatchLog(true)
end

function UIBattleCheat:GetCreateInfo()
    local InputFieldID = self:GetUIComponent("InputField", "InputCreateTrapID")
    local InputFieldPosX = self:GetUIComponent("InputField", "InputCreateTrapPosX")
    local InputFieldPosY = self:GetUIComponent("InputField", "InputCreateTrapPosY")
    local InputCreateDirX = self:GetUIComponent("InputField", "InputCreateDirX")
    local InputCreateDirY = self:GetUIComponent("InputField", "InputCreateDirY")

    local id = tonumber(InputFieldID.text)
    local pos = Vector2(tonumber(InputFieldPosX.text), tonumber(InputFieldPosY.text))
    local dir = Vector2(tonumber(InputCreateDirX.text),tonumber(InputCreateDirY.text))
    return id, pos, dir
end

function UIBattleCheat:CreateTrapButtonOnClick()
    local id, pos, dir = self:GetCreateInfo()


    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatCreateTrap")
    cmd:SetFuncParam(id, pos, dir)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

function UIBattleCheat:CreateMonsterButtonOnClick()
    local id, pos, dir = self:GetCreateInfo()


    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatCreateMonster")
    cmd:SetFuncParam(id, pos, dir)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

function UIBattleCheat:SkillLogOnClick()

    self._infoPanelGo:SetActive(true)
    self._logIndex = 1
    self:_ShowLog()
end

function UIBattleCheat:PrevLogOnClick()
    if self._logIndex > 1 then
        self._logIndex = self._logIndex - 1
    end
    self:_ShowLog()
end

function UIBattleCheat:NextLogOnClick()
    local world = GameGlobal:GetInstance():GetMainWorld()
    local logger = world:GetMatchLogger()
    local t = logger:GetLogs()
    local cnt = 0
    for i, v in ipairs(t) do
        if v.name == "FSMInfo" then
            cnt = cnt + 1
        end
    end
    if self._logIndex < cnt then
        self._logIndex = self._logIndex + 1
    end
    self:_ShowLog()
end

function UIBattleCheat:_ShowLog()
    for i, label in ipairs(self._infoLabels) do
        label:GetComponent("UILocalizationText"):SetText("")
    end
    ---@type MainWorld
    local world = GameGlobal:GetInstance():GetMainWorld()
    local logger = world:GetMatchLogger()
    local t = logger:GetLogs()
    local cnt = 0
    local index = 0
    for i, v in ipairs(t) do
        if v.name == "FSMInfo" then
            index = index + 1
        end
        if index == self._logIndex then
            cnt = cnt + 1
            if cnt <= #self._infoLabels then
                local label = self._infoLabels[cnt]
                label:GetComponent("UILocalizationText"):SetText(v.info)
            else
                local label = UnityEngine.GameObject.Instantiate(self._infoLabel, self._infoLabel.transform.parent)
                label:GetComponent("UILocalizationText"):SetText(v.info)
                self._infoLabels[#self._infoLabels + 1] = label
            end
        end
    end
end

function UIBattleCheat:SetBoardPieceOnClick()
    local InputColor = self:GetUIComponent("InputField", "InputColor")
    local pieceType = tonumber(InputColor.text)

    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatSetBoardPiece")
    cmd:SetFuncParam(pieceType)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end

function UIBattleCheat:AutoTestLogOnClick()
    self:ShowDialog("UIBattleAutoTest")
end

function UIBattleCheat:ShowLogicColorOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetEditorInfoShowType, UnityEngine.KeyCode.Z)
end

function UIBattleCheat:ShowEntityIDOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetEditorInfoShowType, UnityEngine.KeyCode.D)
end

function UIBattleCheat:ShowConfigIDOnClick()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.SetEditorInfoShowType, UnityEngine.KeyCode.S)
end


function UIBattleCheat:changePetHPPercentOnClick(go)
    local input = self:GetUIComponent("InputField", "InputPetHPPercent")
    local hppercent = tonumber(input.text)

    self:_ChangePetHP(hppercent)
end

function UIBattleCheat:_ChangePetHP(hppercent)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatChangePetHPPercent")
    cmd:SetFuncParam(hppercent)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)
end

function UIBattleCheat:AutoFightComplexOnClick()
    local input = self:GetUIComponent("InputField","InputComplex")
    local complex = tonumber(input.text)
    self:_ChangeAutoFightComplex(complex)
end

--拆成两个函数是为了给白盒测试复用
function UIBattleCheat:_ChangeAutoFightComplex(complex)
    local cmd = GMCommand:New()
    cmd:SetFuncName("BattleCheatSetAutoFightComplex")
    cmd:SetFuncParam(complex)
    GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.OnUIGMCheatCommand, cmd)

end


function UIBattleCheat:AutoFightConnectRateOnClick()
    local input = self:GetUIComponent("InputField","InputConnectRate")
    local rate = tonumber(input.text)
    local idx = BattleConst.AutoFightMoveEnhanced and 2 or 1
    BattleConst.AutoFightPathLengthCutConnectRate[idx] = rate
end

function UIBattleCheat:AutoFightConnectCntOnClick()
    local input = self:GetUIComponent("InputField","InputConnectCnt")
    local cnt = tonumber(input.text)
    BattleConst.AutoFightPathLengthCutPosNum = cnt
end
function UIBattleCheat:_RefreshHideUIToggle()
    if self._cheatHideUIRecord then
        for i = UIBattleCheatHideUIArea.LeftUp, UIBattleCheatHideUIArea.DamageDisplay do
            self:_InitHideUIToggle(i)
        end
    end
end
function UIBattleCheat:_InitHideUIToggle(index)
    ---@type UnityEngine.UI.Toggle
    local name = "HideUIToggle" .. tostring(index)
    local tgl = self:GetUIComponent("Toggle", name)
    if tgl then
        if self._cheatHideUIRecord[index] then
            tgl.isOn = true
        else
            tgl.isOn = false
        end
    end
end
function UIBattleCheat:_HideUIToggleOnClick(index)
    ---@type UnityEngine.UI.Toggle
    local name = "HideUIToggle" .. tostring(index)
    local tgl = self:GetUIComponent("Toggle", name)
    if tgl then
        local bHide = tgl.isOn
        GameGlobal:GetInstance():EventDispatcher():Dispatch(GameEventType.UICheatHideArea, index,bHide)
    end
end
function UIBattleCheat:HideUIToggle1OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.LeftUp)
end
function UIBattleCheat:HideUIToggle2OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.LeftDown)
end
function UIBattleCheat:HideUIToggle3OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.AutoArea)
end
function UIBattleCheat:HideUIToggle4OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.StateArea)
end
function UIBattleCheat:HideUIToggle5OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.DebugInfo)
end
function UIBattleCheat:HideUIToggle6OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.CheatBtn)
end
function UIBattleCheat:HideUIToggle7OnClick()
    self:_HideUIToggleOnClick(UIBattleCheatHideUIArea.DamageDisplay)
    ---@type UnityEngine.UI.Toggle
    local name = "HideUIToggle" .. tostring(7)
    local tgl = self:GetUIComponent("Toggle", name)
    if tgl then
        local bHide = tgl.isOn
        ---@type MainWorld
        local world = GameGlobal:GetInstance():GetMainWorld()
        ---@type PreviewMonsterTrapService
        local playDamageService = world:GetService("PlayDamage")
        playDamageService:CheatHideDamageDisplay(bHide)
    end
end