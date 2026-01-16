--
---@class UISeasonTestBtn : UICustomWidget
_class("UISeasonTestBtn", UICustomWidget)
UISeasonTestBtn = UISeasonTestBtn
--初始化
function UISeasonTestBtn:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function UISeasonTestBtn:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.txt = self:GetUIComponent("UILocalizationText", "txt")
    --generated end--
end

--设置数据
function UISeasonTestBtn:SetData(title, cb)
    self.txt:SetText(title)
    self._cb = cb
end

--按钮点击
function UISeasonTestBtn:UISeasonTestBtnOnClick(go)
    if self._cb then
        self._cb()
    end
end
