--
---@class UIWidgetBattleAffix : UICustomWidget
_class("UIWidgetBattleAffix", UICustomWidget)
UIWidgetBattleAffix = UIWidgetBattleAffix
--初始化
function UIWidgetBattleAffix:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIWidgetBattleAffix:InitWidget()
    --generated--
    --词缀提取到通用
    self._mazeAffix = self:GetGameObject("mazeAffix")
    self._mazeAffixPoolGo = self:GetGameObject("mazeAffixPool")
    self._mazeAffixRollAreaGo = self:GetGameObject("mazeAffixRollArea") --多词缀时 用于滚动显示
    ---装饰性文字
    self._txtAffix = self:GetGameObject("txt_affix")
    self._mazeAffixDescOpen = false
    --generated end--
end
--设置数据
function UIWidgetBattleAffix:SetData(matchEnterData)
    local wordbuffids = matchEnterData:GetWordBuffIds()
    wordbuffids = self:_ProcessWordIds(wordbuffids)
    local wordsCount = #wordbuffids
    local matchType = matchEnterData:GetMatchType()
    if matchType ~= MatchType.MT_BlackFist and wordbuffids ~= nil and wordsCount > 0 then
        self:_InitWordsUi(wordbuffids)
    else
        self._mazeAffix:SetActive(false)
        self._mazeAffixRollAreaGo:SetActive(false)
        self._txtAffix:SetActive(false)
    end
end
function UIWidgetBattleAffix:_OnUpdate(deltaTimeMS)
    self:_UpdateMultiMazeAffix(deltaTimeMS)
end
function UIWidgetBattleAffix:_ProcessWordIds(wordIds)
    local firstId
    local sortedIds = {}
    local findDic = {}
    for _, wordId in ipairs(wordIds) do
        if wordId == BattleConst.WordBuffForMission then --熟练的指挥 放最前
            firstId = BattleConst.WordBuffForMission
        else
            if not findDic[wordId] then --去重
                findDic[wordId] = 1
                table.insert(sortedIds, wordId)
            end
        end
    end
    table.sort(sortedIds)
    --排序
    if firstId then
        table.insert(sortedIds, 1, firstId)
    end
    return sortedIds
end

function UIWidgetBattleAffix:_InitWordsUi(wordbuffids)
    self.affixUiData = {}
    for _, wordId in ipairs(wordbuffids) do
        local cfg_word = Cfg.cfg_word_buff[wordId]
        if cfg_word then
            if cfg_word.HideUIType and (cfg_word.HideUIType == AffixHideUIType.HideInGame) then
                --局内隐藏该词缀显示
            else
                local desc = cfg_word.Desc
                local name = cfg_word.Word[1]
                local uiInfo = {}
                uiInfo.nameStr = "【" .. StringTable.Get(name) .. "】"
                uiInfo.descStr = StringTable.Get(desc)
                table.insert(self.affixUiData, uiInfo)
            end
        else
            Log.fatal("###inner game -- maze - cfg_word is nil ! key --> ", wordId)
        end
    end
    local affixUiCount = #self.affixUiData
    if affixUiCount > 0 then
        self._mazeAffix:SetActive(true)
        self._txtAffix:SetActive(true)
        ---@type UICustomWidgetPool
        self._affixPool = self:GetUIComponent("UISelectObjectPath", "mazeAffixPool")
        self._affixPool:SpawnObjects("UIBattleWordAffixCell", affixUiCount)
        ---@type UIBattleWordAffixCell[]
        local affixCells = self._affixPool:GetAllSpawnList()
        self._affixCells = affixCells
        local clickCb = function()
            self:_MazeAffixShowBtnOnClick()
        end
        local firstPosX = 0
        local firstPosY = 0
        self._maxShowAffixCount = 1
        for index, affixUiInfo in ipairs(self.affixUiData) do
            local widget = self._affixCells[index]
            local bShowArrow = (affixUiCount > 1) and (index == affixUiCount)
            widget:SetData(index, clickCb, affixUiInfo.nameStr, affixUiInfo.descStr, false, bShowArrow)
            local posX = firstPosX
            local posY = firstPosY
            local itemGo = widget:GetGameObject()
            itemGo.transform.anchoredPosition = Vector2(posX, posY)
            itemGo.transform:SetSiblingIndex(affixUiCount - index)
            if index > self._maxShowAffixCount then
                itemGo:SetActive(false)
            end
        end
        --单独一个区域用于显示滚动
        if affixUiCount > 1 then
            self:_InitMazeAffixRoll()
            self._mazeAffixPoolGo:SetActive(false)
        else
            self._mazeAffixRollAreaGo:SetActive(false)
            self._mazeAffixPoolGo:SetActive(true)
        end
    else
        self._mazeAffix:SetActive(false)
        self._mazeAffixRollAreaGo:SetActive(false)
        self._txtAffix:SetActive(false)
    end
end

--多词缀时 初始化滚动区域
function UIWidgetBattleAffix:_InitMazeAffixRoll()
    self._multiMazeAffix = true
    self._multiMazeAffixRollIndex = 1
    self._mazeAffixRollAreaGo:SetActive(true)
    local clickCb = function()
        self:_MazeAffixShowBtnOnClick()
    end
    ---@type UICustomWidgetPool
    self._affixRollPool = self:GetUIComponent("UISelectObjectPath", "mazeAffixRoll")
    self._affixRollPool:SpawnObjects("UIBattleWordAffixCell", 2)
    ---@type UIBattleWordAffixCell[]
    local affixRollCells = self._affixRollPool:GetAllSpawnList()
    self._affixRollCells = affixRollCells
    self._affixRollCells[1]:SetData(1, clickCb, self.affixUiData[1].nameStr, "", true, false)
    self._affixRollCells[2]:SetData(2, clickCb, "", "", true, false)
    self._affixRollCells[1]:GetGameObject().transform:SetSiblingIndex(1)
    self._affixRollCells[2]:GetGameObject().transform:SetSiblingIndex(0)
    ---@type UnityEngine.RectTransform
    local firstRect = self._affixRollCells[1]:GetGameObject().transform
    ---@type UnityEngine.RectTransform
    local secondRect = self._affixRollCells[2]:GetGameObject().transform
    secondRect.anchoredPosition = Vector2(secondRect.anchoredPosition.x, secondRect.anchoredPosition.y + 24)
    self._affixRollCellBasePos = Vector2(firstRect.anchoredPosition.x, firstRect.anchoredPosition.y)
    self._multiMazeAffixRolling = true
end

---多词缀 滚动区域重置
function UIWidgetBattleAffix:_ResetMultiMazeAffixRoolArea()
    if self._affixRollSeq then
        self._affixRollSeq:Kill(true)
        self._affixRollSeq = nil
    end
    local clickCb = function()
        self:_MazeAffixShowBtnOnClick()
    end
    self._affixRollCells[1]:SetData(1, clickCb, self.affixUiData[1].nameStr, "", true, false)
    self._affixRollCells[2]:SetData(2, clickCb, "", "", true, false)
    self._affixRollCells[1]:GetGameObject().transform:SetSiblingIndex(1)
    self._affixRollCells[2]:GetGameObject().transform:SetSiblingIndex(0)
    ---@type UnityEngine.RectTransform
    local firstRect = self._affixRollCells[1]:GetGameObject().transform
    ---@type UnityEngine.RectTransform
    local secondRect = self._affixRollCells[2]:GetGameObject().transform
    firstRect.anchoredPosition = Vector2(self._affixRollCellBasePos.x, self._affixRollCellBasePos.y)
    secondRect.anchoredPosition = Vector2(self._affixRollCellBasePos.x, self._affixRollCellBasePos.y + 24)
end

--多词缀时 滚动 --改成只切换文字和底板
function UIWidgetBattleAffix:_DoMazeAffixRoll()
    self:_AddMazeAffixRollIndex()
    local name = self:_GetMazeAffixRollNextName()
    local cellA = self._affixRollCells[1]
    cellA:SetDataForRoll(name,true)
end

--多词缀时 滚动时 设置当前index
function UIWidgetBattleAffix:_AddMazeAffixRollIndex()
    self._multiMazeAffixRollIndex = self._multiMazeAffixRollIndex + 1
    local dataCount = #self.affixUiData
    if self._multiMazeAffixRollIndex > dataCount then
        self._multiMazeAffixRollIndex = 1
    end
end

--多词缀时 滚动时 下一个要显示的词缀名
function UIWidgetBattleAffix:_GetMazeAffixRollNextName()
    local dataCount = #self.affixUiData
    if dataCount >= self._multiMazeAffixRollIndex then
        return self.affixUiData[self._multiMazeAffixRollIndex].nameStr
    end
end

--间隔触发多词条滚动
function UIWidgetBattleAffix:_UpdateMultiMazeAffix(deltaTimeMS)
    local intervalTime = 10000
    if self._multiMazeAffix then
        if self._multiMazeAffixRolling then
            if self._multiMazeAffixRollCd then
                self._multiMazeAffixRollCd = self._multiMazeAffixRollCd - deltaTimeMS
                if self._multiMazeAffixRollCd < 0 then
                    self._multiMazeAffixRollCd = intervalTime
                    self:_DoMazeAffixRoll()
                end
            else
                self._multiMazeAffixRollCd = intervalTime
            end
        end
    end
end
function UIWidgetBattleAffix:_MazeAffixShowBtnOnClick()
    self._mazeAffixDescOpen = not self._mazeAffixDescOpen
    if self._mazeAffixDescOpen then
        self:_MazeAffixExpand()
    else
        self:_MazeAffixUnExpand()
    end
end

---多词缀 展开
function UIWidgetBattleAffix:_MazeAffixExpand()
    if self._multiMazeAffix then
        self:_ResetMultiMazeAffixRoolArea()
        self._mazeAffixRollAreaGo:SetActive(false)
        self._multiMazeAffixRolling = false
        if self._multiMazeAffixRollCd then
            self._multiMazeAffixRollCd = nil
        end
    end
    self._mazeAffixPoolGo:SetActive(true)

    local cellOffX = 0
    local cellOffY = 0
    if self._affixExpandSeq then
        self._affixExpandSeq:Kill(true)
        self._affixExpandSeq = nil
    end
    ---@type DG.Tweening.Sequence
    self._affixExpandSeq = DG.Tweening.DOTween.Sequence()
    for index, cell in ipairs(self._affixCells) do
        cell:ShowDesc(self._mazeAffixDescOpen)
        local itemGo = cell:GetGameObject()
        itemGo:SetActive(true)
        ---@type UnityEngine.RectTransform
        local cellTrans = itemGo.transform
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(cellTrans)
        local tweener = cellTrans:DOAnchorPos(Vector2(cellOffX, cellOffY), 0.3)
        local cellY = cellTrans.rect.height
        cellOffY = cellOffY + cellY - 15 --调ui效果
        self._affixExpandSeq:Join(tweener)
    end

end

---多词缀 收起
function UIWidgetBattleAffix:_MazeAffixUnExpand()
    if self._affixExpandSeq then
        self._affixExpandSeq:Kill(true)
        self._affixExpandSeq = nil
    end
    ---@type DG.Tweening.Sequence
    self._affixExpandSeq = DG.Tweening.DOTween.Sequence()
    local firstPosX = 0
    local firstPosY = 0
    for index, cell in ipairs(self._affixCells) do
        cell:ShowDesc(self._mazeAffixDescOpen)
        local itemGo = cell:GetGameObject()
        ---@type UnityEngine.RectTransform
        local cellTrans = itemGo.transform
        local cellOffX = firstPosX
        local cellOffY = firstPosY
        if index > 1 then
            cellOffY = cellOffY + 24
        end
        local tweener =
        cellTrans:DOAnchorPos(Vector2(cellOffX, cellOffY), 0.3):OnComplete(
            function()
                itemGo:SetActive(index <= self._maxShowAffixCount)
            end
        )
        local cellY = cellTrans.sizeDelta.y
        cellOffY = cellOffY + cellY
        self._affixExpandSeq:Join(tweener)
    end
    self._affixExpandSeq:OnComplete(
        function()
            if self._multiMazeAffix then
                self._mazeAffixPoolGo:SetActive(false)
                self._mazeAffixRollAreaGo:SetActive(true)
                self._multiMazeAffixRolling = true
            end
        end
    )
end
