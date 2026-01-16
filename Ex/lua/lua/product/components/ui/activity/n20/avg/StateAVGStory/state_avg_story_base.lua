---@class StateAVGStoryBase : State
_class("StateAVGStoryBase", State)
StateAVGStoryBase = StateAVGStoryBase

function StateAVGStoryBase:Init()
    self.fsm = self:GetFsm()
    ---@type UIN20AVGStory
    self.ui = self.fsm:GetData()
    ---@type N20AVGData
    self.data = self.ui.data
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self.ui:GetAsset("UIAVG.spriteatlas", LoadType.SpriteAtlas)
end

function StateAVGStoryBase:Destroy()
    StateAVGStoryBase.super.Destroy(self)
    self.ui = nil
end

function StateAVGStoryBase:NodeId(nodeId)
    return self.ui:NodeId(nodeId)
end
function StateAVGStoryBase:NextNodeId(nextNodeId)
    return self.ui:NextNodeId(nextNodeId)
end

--region passSectionIds
function StateAVGStoryBase:PassSectionId(sectionSign)
    return self.ui:PassSectionId(sectionSign)
end
function StateAVGStoryBase:ClearPassSectionIds()
    self.ui:ClearPassSectionIds()
end
--endregion

function StateAVGStoryBase:CalcCurData()
    return self.ui:CalcCurData()
end

function StateAVGStoryBase:InitStoryManager()
    return self.ui:InitStoryManager()
end

function StateAVGStoryBase:ShowHideOption(isShow)
    self.ui:ShowHideOption(isShow)
end

function StateAVGStoryBase:UpdateDriveByState(deltaTimeMS)
    if self.ui then
        self.ui:UpdateDriveByState(deltaTimeMS)
    end
end

--region ShowHideButton
function StateAVGStoryBase:ShowHideButtonAuto(isShow)
    self.ui.goAuto:SetActive(isShow)
end
function StateAVGStoryBase:ShowHideButtonReview(isShow)
    self.ui.btnReview:SetActive(isShow)
end
function StateAVGStoryBase:ShowHideButtonShowHideUI(isShow)
    self.ui.goShowHideUI:SetActive(isShow)
end
function StateAVGStoryBase:ShowHideButtonNext(isShow)
    self.ui.btnNext:SetActive(isShow)
end
function StateAVGStoryBase:ShowHideButtonGraph(isShow)
    self.ui.btnGraph:SetActive(isShow)
end
function StateAVGStoryBase:ShowHideButtonExit(isShow)
    self.ui.btnExit:SetActive(isShow)
end
--endregion

function StateAVGStoryBase:HandleSetCurrentLocation(TT, nodeId, callback)
    local com = self.data:GetComponentAVG()
    local res = AsyncRequestRes:New()
    local ret = com:HandleSetCurrentLocation(TT, res, nodeId) ---【请求】存储位置
    if N20AVGData.CheckCode(res) then
        if callback then
            callback()
        end
    end
end
