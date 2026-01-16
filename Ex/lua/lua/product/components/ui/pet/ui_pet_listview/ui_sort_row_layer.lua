---@class UiSortRowLayer : UICustomWidget
_class("UiSortRowLayer", UICustomWidget)
UiSortRowLayer = UiSortRowLayer
--注释
function UiSortRowLayer:Constructor()
    --按钮每行的容器，类似于空脚本
    self._rowSortBtnPos = 
    {
        [1] = 0,
        [2] = 210,
        [3] = 338,
        [4] = 466
    }
end
--注释
function UiSortRowLayer:OnShow()

end
--注释
function UiSortRowLayer:SetBtnPos(index)
    return self._rowSortBtnPos[index]
end