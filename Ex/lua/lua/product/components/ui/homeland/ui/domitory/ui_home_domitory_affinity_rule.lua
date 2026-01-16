---@class UIHomeDomitoryAffinityRule : UIController
_class("UIHomeDomitoryAffinityRule", UIController)
UIHomeDomitoryAffinityRule = UIHomeDomitoryAffinityRule
--注释
function UIHomeDomitoryAffinityRule:OnShow(uiParams)
    self:InitWidget()
    ---@type UIHomeCommonCloseBtn
    local topBtns = self.topBtn:SpawnObject("UIHomeCommonCloseBtn")
    topBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        true
    )

    local tmp = Cfg.cfg_homeland_dormitory_favorability {}
    local cfgs = {}
    for _, value in pairs(tmp) do
        table.insert(cfgs, value)
    end
    table.sort(
        cfgs,
        function(a, b)
            return a.ID < b.ID
        end
    )

    local text1 = {}
    for i = 1, #cfgs do
        if i == 1 then
            text1[i] = "0" --默认0是第一档
        else
            text1[i] = cfgs[i - 1].AtmosphereValue + 1 .. "-" .. cfgs[i].AtmosphereValue
        end
    end

    self.chart.preferredHeight = (#cfgs + 1) * 64
    ---@type table<number,UIHomeDomitoryChartRow>
    local rows = self.rows:SpawnObjects("UIHomeDomitoryChartRow", #cfgs)
    for i = 1, #cfgs do
        rows[i]:SetData(i, text1[i], cfgs[i])
    end

    for i = 1, #cfgs do
        local line = UnityEngine.Object.Instantiate(self.line, self.line.transform.parent)
        local rect = line:GetComponent(typeof(UnityEngine.RectTransform))
        rect.anchoredPosition = Vector2(0, -i * 64)
        line:SetActive(true)
    end
end
--注释
function UIHomeDomitoryAffinityRule:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.topBtn = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UILocalizationText
    self.title1 = self:GetUIComponent("UILocalizationText", "title1")
    ---@type UILocalizationText
    self.title2 = self:GetUIComponent("UILocalizationText", "title2")
    --generated end--
    ---@type UICustomWidgetPool
    self.rows = self:GetUIComponent("UISelectObjectPath", "rows")
    self.line = self:GetGameObject("line")
    ---@type UnityEngine.UI.LayoutElement
    self.chart = self:GetUIComponent("LayoutElement", "chart")
end
