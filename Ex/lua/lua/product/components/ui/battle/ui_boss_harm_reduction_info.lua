---@class UIBossHarmReductionInfo : UICustomWidget
_class("UIBossHarmReductionInfo", UICustomWidget)
UIBossHarmReductionInfo = UIBossHarmReductionInfo

function UIBossHarmReductionInfo:Constructor()
end

function UIBossHarmReductionInfo:OnShow()
    self._root = self:GetGameObject("Root")

    self._imageRoot = self:GetGameObject("imageRoot")
    self._lineRoot = self:GetGameObject("lineRoot")
    self._harmReductionText = self:GetUIComponent("UILocalizationText", "harmReductionText")

    self._images = self._imageRoot:GetComponentsInChildren(typeof(UnityEngine.UI.Image), true)
    self._lines = self._lineRoot:GetComponentsInChildren(typeof(UnityEngine.UI.Image), true)

    self:AttachEvent(GameEventType.UpdateBossHarmReduction, self.OnRefresh)
    self:AttachEvent(GameEventType.UpdateCoffinMusumeUIDef, self.OnRefreshCoffinMusume)
    self:AttachEvent(GameEventType.UpdateCoffinMusumeUIAtkDef, self.OnRefreshCoffinMusumeAtkDef) --MSG51389
end

function UIBossHarmReductionInfo:OnHide()
    self:DetachEvent(GameEventType.UpdateBossHarmReduction, self.OnRefresh)
    self:DetachEvent(GameEventType.UpdateCoffinMusumeUIDef, self.OnRefreshCoffinMusume)
    self:DetachEvent(GameEventType.UpdateCoffinMusumeUIAtkDef, self.OnRefreshCoffinMusumeAtkDef) --MSG51389
end

---@param buffResult BuffResultHarmReduction
function UIBossHarmReductionInfo:OnRefresh(buffResult)
    self._root:SetActive(true)

    --参数1  有基层
    local layer = buffResult:GetLayer() - 1

    --参数2   白线位置
    local lineList = buffResult:GetLines()

    --参数3   减少伤害
    local harmReduction = buffResult:GetHarmReduction()

    local uiText = buffResult:GetUIText() --"str_battle_harm_reduction"

    for i = 0, self._images.Length - 1 do
        self._images[i].gameObject:SetActive(i <= layer)
    end

    for i = 0, self._lines.Length - 1 do
        local lineIndex = i + 1
        self._lines[i].gameObject:SetActive(lineIndex <= #lineList)
        if lineIndex <= #lineList then
            local siblingIndex = lineList[lineIndex] - 1
            self._lines[i].transform:SetParent(self._imageRoot.transform)
            self._lines[i].transform:SetSiblingIndex(siblingIndex)
        end
    end

    self._harmReductionText:SetText(StringTable.Get(uiText, harmReduction))
end

---@param buffResult BuffResultCoffinMusumeChangeDefenceByCandle|BuffResultCoffinMusumeHarmReduction
function UIBossHarmReductionInfo:OnRefreshCoffinMusume(buffResult)
    self._root:SetActive(true)

    --参数1  有基层
    local layer = buffResult:GetLightCandleCount() - 1

    --参数3   减少伤害
    local harmReduction = math.floor(buffResult:GetHarmReduction()--[[ * 100]]) --MSG51389

    local uiText = buffResult:GetUIText()

    for i = 0, self._images.Length - 1 do
        self._images[i].gameObject:SetActive(i <= layer)
    end

    --region MSG51389
    --for i = 0, self._lines.Length - 1 do
    --    self._lines[i].gameObject:SetActive(false)
    --end

    --参数2   白线位置
    local lineList = buffResult:GetLines()

    for i = 0, self._lines.Length - 1 do
        local lineIndex = i + 1
        self._lines[i].gameObject:SetActive(lineIndex <= #lineList)
        if lineIndex <= #lineList then
            local siblingIndex = lineList[lineIndex] - 1
            self._lines[i].transform:SetParent(self._imageRoot.transform)
            self._lines[i].transform:SetSiblingIndex(siblingIndex)
        end
    end
    --endregion

    self._harmReductionText:SetText(StringTable.Get(uiText, harmReduction))
end

--MSG51389

---@param buffResult BuffResultCoffinMusumeHarmReductionAndAttack
function UIBossHarmReductionInfo:OnRefreshCoffinMusumeAtkDef(buffResult)
    self._root:SetActive(true)

    --参数1  有基层
    local layer = buffResult:GetLightCandleCount() - 1

    --参数3   减少伤害
    local harmReduction = math.floor(buffResult:GetHarmReduction())
    local attackVal = math.floor(buffResult:GetAttackVal())

    local uiText = buffResult:GetUIText()

    for i = 0, self._images.Length - 1 do
        self._images[i].gameObject:SetActive(i <= layer)
    end

    --参数2   白线位置
    local lineList = buffResult:GetLines()

    for i = 0, self._lines.Length - 1 do
        local lineIndex = i + 1
        self._lines[i].gameObject:SetActive(lineIndex <= #lineList)
        if lineIndex <= #lineList then
            local siblingIndex = lineList[lineIndex] - 1
            self._lines[i].transform:SetParent(self._imageRoot.transform)
            self._lines[i].transform:SetSiblingIndex(siblingIndex)
        end
    end
    self._harmReductionText:SetText(StringTable.Get(uiText, harmReduction, attackVal))
end
