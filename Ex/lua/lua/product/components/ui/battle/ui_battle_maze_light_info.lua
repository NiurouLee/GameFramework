---@class UIBattleMazeLightInfo : UICustomWidget
_class("UIBattleMazeLightInfo", UICustomWidget)
UIBattleMazeLightInfo = UIBattleMazeLightInfo

function UIBattleMazeLightInfo:OnShow()
    ---@type UnityEngine.GameObject
    self._leftTurnNormalGO = self:GetGameObject("Normal")
    ---@type UILocalizationText
    self._leftTurnNum = self:GetUIComponent("UILocalizationText", "txtTurnCount")
    ---@type UILocalizationText
    self._leftTurnLittleNum = self:GetUIComponent("UILocalizationText", "txtLittleTurnCount")
    self._text = self:GetUIComponent("UILocalizationText", "text")
    self._text.text = StringTable.Get("str_battle_light_count")
    --warn
    ---@type UnityEngine.GameObject
    self._leftTurnWarningGO = self:GetGameObject("Warning")
    ---@type UILocalizationText
    self._leftTurnWarningNum = self:GetUIComponent("UILocalizationText", "warningtxtTurnCount")
    ---@type UILocalizationText
    self._leftTurnWarningNumBG = self:GetUIComponent("UILocalizationText", "warningtxtTurnCountBG")
    ---@type UILocalizationText
    self._leftTurnWarningLittleNum = self:GetUIComponent("UILocalizationText", "warningtxtLittleTurnCount")
    ---@type UnityEngine.UI.Outline
    self._leftTurnWarningOutLineNum = self:GetUIComponent("Outline", "warningtxtTurnCount")
    ---进入警告状态回合数阈值
    ---@type number
    self._warningRoundCount = Cfg.cfg_global["inner_game_warning_round_count_maze"].IntValue
    ---@type boolean
    self._warningRoundState = false
    ---@type DG.Tweening.Sequence
    self._doTweenSequence = nil
    ---@type number
    self._roundWarningTaskID = nil
    --剩余能量特效
    local tranUpEff = self:GetGameObject("UP_Eff").transform
    ---@type UnityEngine.Animation[]
    self._arrAnimEffUp = {}
    self._arrTextEffUp = {}
    self._effArrLen = 5
    for i = 1, self._effArrLen do --预加载几个
        local goAnimEffUp = UIHelper.GetGameObject("UIEff_TurnInfo_tiaodong.prefab")
        goAnimEffUp.transform:SetParent(tranUpEff, false)
        goAnimEffUp:SetActive(false)
        local anim = goAnimEffUp:GetComponent("Animation")
        local txt = goAnimEffUp.transform:Find("number"):GetComponent("UILocalizationText")
        table.insert(self._arrAnimEffUp, anim)
        table.insert(self._arrTextEffUp, txt)
    end
    --
    self:Init()
    --event
    self:AttachEvent(GameEventType.InitRoundCount, self.InitRoundCount)
    self:AttachEvent(GameEventType.UpdateRoundCount, self.UpdateLeftTurnNum)
    -- self:AttachEvent(GameEventType.RemainRoundCount2Power, self.PlayRemainRoundCount2Power)
end

function UIBattleMazeLightInfo:OnHide()
    self._arrAnimEffUp = nil
    self._arrTextEffUp = nil
    self:DetachEvent(GameEventType.InitRoundCount, self.InitRoundCount)
    self:DetachEvent(GameEventType.UpdateRoundCount, self.UpdateLeftTurnNum)
    -- self:DetachEvent(GameEventType.RemainRoundCount2Power, self.PlayRemainRoundCount2Power)
end

function UIBattleMazeLightInfo:Init()
    self._leftTurnWarningGO:SetActive(false)
end

---初始化起始回合数
---@param turnCount number
function UIBattleMazeLightInfo:InitRoundCount(turnCount)
    self:CancelRoundWarningState()
    self:SetRoundCount(turnCount)
    self:UpdateLeftTurnNum(turnCount)
end

---设置回合数
---@param turnCount number
function UIBattleMazeLightInfo:SetRoundCount(turnCount)
    if turnCount > 999 then
        turnCount = "999+"
    end
    self._leftTurnNum:SetText(turnCount)
    self._leftTurnLittleNum:SetText(turnCount)
    self._leftTurnWarningNum:SetText(turnCount)
    self._leftTurnWarningLittleNum:SetText(turnCount)
    self._leftTurnWarningNumBG:SetText(turnCount)
end

---@param leftTurnNum number
function UIBattleMazeLightInfo:UpdateLeftTurnNum(leftTurnNum)
    if leftTurnNum > self._warningRoundCount and self._warningRoundState then
        self:CancelRoundWarningState()
    elseif leftTurnNum <= self._warningRoundCount and not self._warningRoundState then
        self:_DoRoundWarning()
    end
    self:SetRoundCount(leftTurnNum)
end

---取消回合数警告
function UIBattleMazeLightInfo:CancelRoundWarningState()
    self._warningRoundState = false
    self._leftTurnNormalGO:SetActive(true)
    self._leftTurnWarningGO:SetActive(false)
end
---进入回合数警告
function UIBattleMazeLightInfo:_DoRoundWarning()
    self._warningRoundState = true
    self._leftTurnNormalGO:SetActive(false)
    self._leftTurnWarningGO:SetActive(true)
    self._roundWarningTaskID = GameGlobal.TaskManager():CoreGameStartTask(self._DoLeftTurnWarningAnimation, self)
end

---进行回合数警告动效
function UIBattleMazeLightInfo:_DoLeftTurnWarningAnimation(TT)
    self._DoTweenSequence = DG.Tweening.DOTween.Sequence()
    ---@type UnityEngine.GameObject
    local sss = self:GetGameObject("warningtxtTurnCountBG")
    while self._warningRoundState do
        sss.transform:DOScale(Vector3(1.3, 1.3, 1), 0.2)
        --YIELD(TT,200)
        self._leftTurnWarningNumBG:DOFade(0, 0.1)
        if not self._warningRoundState then
            return
        end
        YIELD(TT, 200)
        local coreGameStateID = GameGlobal:GetInstance():CoreGameStateID()
        if coreGameStateID == GameStateID.Invalid then
            Log.notice("quit game already")
            break
        end
        if not self._warningRoundState then
            return
        end
        self._leftTurnWarningNumBG:DOFade(255, 0)
        sss.transform.localScale = Vector3(1, 1, 1)
    end
end

---剩余回合转能量表现
---@param energyNum number 回合转化的能量
---@param curRemainRound number 剩余回合数
function UIBattleMazeLightInfo:PlayRemainRoundCount2Power(energyNum, curRemainRound)
    if curRemainRound <= 0 then
        return
    end
    self:StartTask(
        function(TT)
            local perEnergy = energyNum / curRemainRound
            for i = curRemainRound, 1, -1 do
                local idx = i % self._effArrLen + 1
                self._arrAnimEffUp[idx].gameObject:SetActive(true)
                self._arrAnimEffUp[idx]:Play()
                self._arrTextEffUp[idx].text = tostring(i)
                self:SetRoundCount(i - 1)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.RemainRoundCount2PowerPet, perEnergy)
                YIELD(TT, 100)
                if not self._arrAnimEffUp then
                    return
                end
                self._arrAnimEffUp[idx].gameObject:SetActive(false)
            end
        end,
        self
    )
end
