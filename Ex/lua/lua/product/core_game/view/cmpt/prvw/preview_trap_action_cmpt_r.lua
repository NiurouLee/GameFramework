--[[------------------------------------------------------------------------------------------
    PreviewTrapActionComponent : 预览机关行动
]] --------------------------------------------------------------------------------------------


_class("PreviewData", Object)
---@class PreviewData: Object
PreviewData = PreviewData

function PreviewData:Constructor(nTrapEntityID, touchPosition, offset)
    ---2020-08-03 韩玉信修改ID为列表，适应多机关重叠的预览逻辑
    self.m_nEntityID = nTrapEntityID
	self.m_posTouch = touchPosition or Vector2(0,0)
	self.m_posOffset = offset or Vector2(0,0)
end
----------------------------------------------------------------
_class("PreviewTrapActionComponent", Object)
---@class PreviewTrapActionComponent: Object
PreviewTrapActionComponent = PreviewTrapActionComponent

function PreviewTrapActionComponent:Constructor()
    self._showTrapAction = false
    ---2020-08-03 韩玉信修改ID为列表，适应多机关重叠的预览逻辑
    self._listTrapPreview = {}
end
function PreviewTrapActionComponent:SetTrapPreviewData(nTrapEntityID, touchPosition, offset)
    self._listTrapPreview[nTrapEntityID] = PreviewData:New(nTrapEntityID, touchPosition, offset)
    -- self._trapEntityID = trapEntityID
end
function PreviewTrapActionComponent:RemoveTrapEntityID(trapEntityID)
    self._listTrapPreview[trapEntityID] = nil
end

function PreviewTrapActionComponent:GetTrapEntityList()
    local listTrapID = {}
    for key, value in pairs(self._listTrapPreview) do
        table.insert(listTrapID, key)
    end
    return listTrapID
end

function PreviewTrapActionComponent:ShowTrapAction(show)
    self._showTrapAction = show
end

function PreviewTrapActionComponent:IsShowTrapAction()
    return self._showTrapAction
end

function PreviewTrapActionComponent:GetTouchPosition(trapEntityID)
    local pPreviewData = self._listTrapPreview[trapEntityID]
    if nil == pPreviewData then
        return Vector2(0,0)
    end
	return pPreviewData.m_posTouch
end

function PreviewTrapActionComponent:GetTouchPositionOffset(trapEntityID)
    local pPreviewData = self._listTrapPreview[trapEntityID]
    if nil == pPreviewData then
        return Vector2(0,0)
    end
	return pPreviewData.m_posOffset
end

--------------------------------------------------------------------------------------------
--[[------------------------------------------------------------------------------------------
    Entity Extensions
]] 
function Entity:PreviewTrapAction()
    return self:GetComponent(self.WEComponentsEnum.PreviewTrapAction)
end

function Entity:HasPreviewTrapAction()
    return self:HasComponent(self.WEComponentsEnum.PreviewTrapAction)
end

function Entity:AddPreviewTrapAction()
    local index = self.WEComponentsEnum.PreviewTrapAction
    local component = PreviewTrapActionComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplacePreviewTrapAction()
    local index = self.WEComponentsEnum.PreviewTrapAction
    local component = PreviewTrapActionComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemovePreviewTrapAction()
    if self:HasPreviewTrapAction() then
        self:RemoveComponent(self.WEComponentsEnum.PreviewTrapAction)
    end
end
