-- 准备阶段切换按钮封装
---@class PrepareStageItem : UICustomWidget
_class("PrepareStageItem", UICustomWidget)
PrepareStageItem = PrepareStageItem


function PrepareStageItem:Constructor()
    self.prePareType  = nil
    self.clickCallback = nil
end

function PrepareStageItem:GetPrepareType()
    return self.prePareType
end

--初始化
function PrepareStageItem:OnShow(uiParams)
    self:InitWidget()
end

--获取ui组件
function PrepareStageItem:InitWidget()
    ---@type UILocalizationText
    self.name = self:GetUIComponent("UILocalizationText", "name")
    ---@type UILocalizationText
    self.unSelectName = self:GetUIComponent("UILocalizationText", "unSelectName")

    ---@type UnityEngine.GameObject
    self.select = self:GetGameObject("select")
    ---@type UnityEngine.GameObject
    self.unSelect = self:GetGameObject("unSelect")
end

--设置数据
function PrepareStageItem:SetData(name, prepareType, clickCallback)
    self.prePareType = prepareType
    self.clickCallback = clickCallback
    local txt = StringTable.Get(name)
    self.name:SetText(txt)
    self.unSelectName:SetText(txt)
end

function PrepareStageItem:SetSelect(bSelect)
    self.select:SetActive(bSelect)
    self.unSelect:SetActive(not bSelect)    
end


--按钮点击
function PrepareStageItem:ItemBtnOnClick(go)
    if self.clickCallback then
        self.clickCallback(self)
    end
end
