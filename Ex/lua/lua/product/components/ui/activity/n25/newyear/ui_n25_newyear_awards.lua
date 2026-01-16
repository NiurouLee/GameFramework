--
---@class UIN25NewYearAwards : UIController
_class("UIN25NewYearAwards", UIController)
UIN25NewYearAwards = UIN25NewYearAwards

---@param res AsyncRequestRes
function UIN25NewYearAwards:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UIN25NewYearAwards:OnShow(uiParams)
    local data = uiParams[1]
    self._awards = {}
    for _, TimeRewardInfo in pairs(data) do
        for _, reward in pairs(TimeRewardInfo.rewards) do
            table.insert(self._awards, reward)
        end
    end
    self:_GetComponents()
    self:_OnValue()
end

--获取ui组件
function UIN25NewYearAwards:_GetComponents()
    ---@type UICustomWidgetPool
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    self._itemTips = self:GetUIComponent("UISelectObjectPath", "ItemTips")
    ---@type UIN25NewYearItemTips
    self._tips = self._itemTips:SpawnObject("UIN25NewYearItemTips")
    ---@type UnityEngine.Animation
    self._animation = self.view.gameObject:GetComponent("Animation")
end

function UIN25NewYearAwards:_OnValue()
    local count = table.count(self._awards)
    self._content:SpawnObjects("UIN25NewYearAwardItem", count)
    ---@type UIN25NewYearAwardItem[]
    local widgets = self._content:GetAllSpawnList()
    for index, widget in ipairs(widgets) do
        widget:SetData(
            self._awards[index], 
            function (id, position)
                self:_ShowTips(id, position)
            end,
            true
        )
    end
end

--按钮点击
function UIN25NewYearAwards:BackgroundBtnOnClick(go)
    self:CloseDialog()
end

function UIN25NewYearAwards:_ShowTips(id, position)
    self._tips:SetData(id, position)
end