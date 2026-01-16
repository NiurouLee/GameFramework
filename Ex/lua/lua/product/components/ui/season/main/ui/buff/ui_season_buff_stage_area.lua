---@class UISeasonBuffStageArea:UICustomWidget
_class("UISeasonBuffStageArea", UICustomWidget)
UISeasonBuffStageArea = UISeasonBuffStageArea

function UISeasonBuffStageArea:OnShow(uiParams)
    ---@type UILocalizationText
    self.levelText = self:GetUIComponent("UILocalizationText", "Lv")
    
end

function UISeasonBuffStageArea:DetailBtnOnClick()
    GameGlobal.UIStateManager():ShowDialog(
        "UISeasonBuffMainInfo",self.componentID,self._curLevel,self._curProgress,self._isMaxLevel,self._curMaxProgress
    )
end
--设置数据
function UISeasonBuffStageArea:SetData(obj)
    ---@type UISeasonObj
    self._seasonObj = obj
    self.componentID = self._seasonObj:GetSeasonMissionComponentCfgID()
    self:RefreshInfo()
end
function UISeasonBuffStageArea:RefreshInfo()
    local curLevel,curProgress,maxLevel,isMaxLevel,curMaxProgress = UISeasonHelper.CalcBuffLevel(self.componentID)
    self._curLevel = curLevel
    self._curProgress = curProgress
    self._isMaxLevel = isMaxLevel
    self._curMaxProgress = curMaxProgress
    self.levelText:SetText(StringTable.Get("str_season_buff_level",tostring(curLevel)))
end