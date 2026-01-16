---@class UIMapPathNextChapterItem:UICustomWidget
_class("UIMapPathNextChapterItem", UICustomWidget)
UIMapPathNextChapterItem = UIMapPathNextChapterItem

function UIMapPathNextChapterItem:Constructor()
    ---@type MissionModule
    self._module = self:GetModule(MissionModule)
    self._data = self._module:GetDiscoveryData()
end

function UIMapPathNextChapterItem:OnShow()
    self._go = self:GetGameObject()
    ---@type UnityEngine.RectTransform
    self._rect = self._go:GetComponent("RectTransform")
    local vec0_5 = Vector2(0.5, 0.5)
    self._rect.anchorMax = vec0_5
    self._rect.anchorMin = vec0_5
    ---@type UnityEngine.RectTransform
    self._rectRoot = self:GetGameObject("shape"):GetComponent("RectTransform")
    ---@type UnityEngine.GameObject
    self._line = self:GetGameObject("line")
    ---@type UnityEngine.GameObject
    self._shadow = self:GetGameObject("shadow")
    self:AttachEvent(GameEventType.DiscoveryNodeStateChange, self.FlushState)
end

function UIMapPathNextChapterItem:OnHide()
    self:DetachEvent(GameEventType.DiscoveryNodeStateChange, self.FlushState)
end

---@param sPos Vector2 起点
---@param ePos Vector2 终点
function UIMapPathNextChapterItem:Flush(sPos, ePos, nextChapterData, isShadow)
    self._nextChapter = nextChapterData
    local posS, posE = sPos:Clone(), ePos:Clone()
    if isShadow then
        local offsetY = 30
        posS.y = posS.y - offsetY
        posE.y = posE.y - offsetY
        self._shadow:SetActive(true)
    else
        self._line:SetActive(true)
    end

    local dis = Vector2.Distance(posS, posE)
    self._rectRoot.sizeDelta = Vector2(dis, self._rectRoot.sizeDelta.y)
    self._rect.anchoredPosition = posS
    local v = posE - posS
    self._rect.localRotation = Quaternion.FromToRotation(Vector3.right, Vector3(v.x, v.y, 0))

    self:FlushState()
    self:Animation()
end

function UIMapPathNextChapterItem:FlushState()
    local curChapter = self._data:GetCurPosChapter()
    local isComplete = curChapter:IsComplete()
    self._go:SetActive(isComplete)
end

function UIMapPathNextChapterItem:Animation()
    if self:IsFirstShow() then
        local targetWidth = self._rectRoot.sizeDelta.x
        self._rectRoot.sizeDelta = Vector2(0, self._rectRoot.sizeDelta.y)
        self._rectRoot:DOSizeDelta(Vector2(targetWidth, self._rectRoot.sizeDelta.y), 0.8)
    end
end

---@return boolean 是否是第一次显示
function UIMapPathNextChapterItem:IsFirstShow()
    local playerPrefsKey = self:GetPstId() .. "DiscoveryNextChapterIsFirstShow" .. self._nextChapter.chapterId
    local isFirst = UnityEngine.PlayerPrefs.GetInt(playerPrefsKey, 0)
    return isFirst == 0
end

---@private
function UIMapPathNextChapterItem:GetPstId()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return roleModule:GetPstId()
end
