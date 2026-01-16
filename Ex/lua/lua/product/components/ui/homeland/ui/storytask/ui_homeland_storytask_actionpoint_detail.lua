---@class UIHomelandStoryTaskActionPointDetail:UIController
_class("UIHomelandStoryTaskActionPointDetail", UIController)
UIHomelandStoryTaskActionPointDetail = UIHomelandStoryTaskActionPointDetail

function UIHomelandStoryTaskActionPointDetail:Constructor()
  
end

---@param res AsyncRequestRes
function UIHomelandStoryTaskActionPointDetail:LoadDataOnEnter(TT, res, uiParams)
    
end

function UIHomelandStoryTaskActionPointDetail:OnShow(uiParams)
    --self:AttachEvent(GameEventType.HomelandLevelClickLevelItem, self.HomelandLevelClickLevelItem)
    self:_GetComponents()
    self:Refresh()
end

function UIHomelandStoryTaskActionPointDetail:_GetComponents()
    
end

function UIHomelandStoryTaskActionPointDetail:OnHide()

end

function UIHomelandStoryTaskActionPointDetail:Refresh()

end

--region OnClick
function UIHomelandStoryTaskActionPointDetail:CloseBtnOnClick(go)
    self:CloseDialog()
end
