---@class UIN28AVGGraphNodeNormal:UIN28AVGGraphNodeBase
_class("UIN28AVGGraphNodeNormal", UIN28AVGGraphNodeBase)
UIN28AVGGraphNodeNormal = UIN28AVGGraphNodeNormal

---@overload
function UIN28AVGGraphNodeNormal:FlushName()
    local state = self.node:State()
    if state == N28AVGStoryNodeState.CantPlay then
        self.txtName:SetText("???")
        self.txtName1:SetText("???")
        self.txtName1Outline.effectColor = Color(105 / 255, 105 / 255, 128 / 255, 1)
    else
        self.txtName:SetText(self.node.title)
        self.txtName1:SetText(self.node.title)
        self.txtName1Outline.effectColor = Color(62 / 255, 156 / 255, 199 / 255, 1)
    end
end
---@overload
function UIN28AVGGraphNodeNormal:FlushState()
    self.imgBG1 = self:GetUIComponent("Image", "imgBG1")
    local state = self.node:State()
    if state == N28AVGStoryNodeState.CantPlay then
        self.imgBG.sprite = self.atlas:GetSprite("N28_avg_jd_di03")
        self.imgBG1.sprite = self.atlas:GetSprite("N28_avg_jd_icon06")
    else
        self.imgBG.sprite = self.atlas:GetSprite("N28_avg_jd_di02")
        self.imgBG1.sprite = self.atlas:GetSprite("N28_avg_jd_icon05")
    end
end
