---@class UIN20AVGGraphNodeBase:UICustomWidget
_class("UIN20AVGGraphNodeBase", UICustomWidget)
UIN20AVGGraphNodeBase = UIN20AVGGraphNodeBase

function UIN20AVGGraphNodeBase:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
end

function UIN20AVGGraphNodeBase:OnShow()
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIAVG.spriteatlas", LoadType.SpriteAtlas)
    self.curPos = self:GetGameObject("curPos")
    self:InitComponent()
end
function UIN20AVGGraphNodeBase:OnHide()
end
function UIN20AVGGraphNodeBase:InitComponent()
    ---@type UnityEngine.UI.Image
    self.imgBG = self:GetUIComponent("Image", "imgBG")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
end

---@param id  number 结点id
function UIN20AVGGraphNodeBase:Flush(id)
    self.node = self.data:GetNodeById(id)
    self:FlushName()
    self:FlushState()
    self:FlushNew()
end
function UIN20AVGGraphNodeBase:FlushName()
end
function UIN20AVGGraphNodeBase:FlushCurPos(endId)
    if endId > 0 then
        if self.node:IsEnd() then
            if self.node.endId == endId then
                self.curPos:SetActive(true)
            else
                self.curPos:SetActive(false)
            end
        else
            self.curPos:SetActive(false)
        end
    else
        local curNodeId = self.data:CurNodeId()
        if curNodeId == self.node.id then
            self.curPos:SetActive(true)
        else
            self.curPos:SetActive(false)
        end
    end
end
function UIN20AVGGraphNodeBase:FlushState()
end
function UIN20AVGGraphNodeBase:FlushNew()
end
