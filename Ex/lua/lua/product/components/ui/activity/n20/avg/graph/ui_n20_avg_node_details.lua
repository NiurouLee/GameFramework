---@class UIN20AVGNodeDetails:UIController
_class("UIN20AVGNodeDetails", UIController)
UIN20AVGNodeDetails = UIN20AVGNodeDetails

function UIN20AVGNodeDetails:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
end

function UIN20AVGNodeDetails:OnShow(uiParams)
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    self.recordTime = self:GetGameObject("recordTime")
    ---@type UILocalizationText
    self.txtTime = self:GetUIComponent("UILocalizationText", "txtTime")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    ---@type UICustomWidgetPool
    local poolLeader = self:GetUIComponent("UISelectObjectPath", "leader")
    ---@type UIN20AVGActor
    self.leader = poolLeader:SpawnObject("UIN20AVGActor")
    ---@type UICustomWidgetPool
    self.poolPartners = self:GetUIComponent("UISelectObjectPath", "partners")

    self.nodeId = uiParams[1]

    self:Flush()
end

function UIN20AVGNodeDetails:OnHide()
    self.imgCG:DestoryLastImage()
end

function UIN20AVGNodeDetails:Flush()
    self.node = self.data:GetNodeById(self.nodeId)
    --节点达成后固定显示已达成的图；节点未达成时优先显示未达成的图，没配未达成的图就也显示已达成的图
    local state = self.node:State()
    if state == AVGStoryNodeState.Complete then
        self.imgCG:LoadImage(self.node.cg)
    else
        if string.isnullorempty(self.node.cgCanPlay) then
            self.imgCG:LoadImage(self.node.cg)
        else
            self.imgCG:LoadImage(self.node.cgCanPlay)
        end
    end
    self:FlushTime()
    self.txtName:SetText(self.node.title)
    self.txtDesc:SetText(self.node.desc)
    self:FlushActors()
end
function UIN20AVGNodeDetails:FlushTime()
    local ts = self.node:GetSaveTimestamp()
    if ts > 0 then
        self.recordTime:SetActive(true)
        local str = self.data:Timestamp2Str(ts)
        self.txtTime:SetText(str)
    else
        self.recordTime:SetActive(false)
    end
end
function UIN20AVGNodeDetails:FlushActors()
    local hp, strategies = self.node:StartData()
    self.leader:Flush(0, hp)
    local len = table.count(self.data.actorPartners)
    self.poolPartners:SpawnObjects("UIN20AVGActor", len)
    ---@type UIN20AVGActor[]
    local uis = self.poolPartners:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Flush(i, strategies[i] or 0)
    end
end

--region OnClick
function UIN20AVGNodeDetails:bgOnClick(go)
    self:CloseDialog()
end
function UIN20AVGNodeDetails:btnCloseOnClick(go)
    self:CloseDialog()
end
function UIN20AVGNodeDetails:btnStartOnClick(go)
    if GameGlobal.UIStateManager():IsShow("UIN20AVGStory") then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel, --1
            "", --2
            StringTable.Get("str_avg_n20_give_up_cur_node_progress_2_start_this_node"), --3
            function()
                self:CloseDialog()
                if GameGlobal.UIStateManager():IsShow("UIN20AVGGraph") then
                    GameGlobal.UIStateManager():CloseDialog("UIN20AVGGraph")
                end
                if GameGlobal.UIStateManager():IsShow("UIN20AVGEnding") then
                    GameGlobal.UIStateManager():CloseDialog("UIN20AVGEnding")
                end
                GameGlobal.UIStateManager():CallUIMethod("UIN20AVGStory", "PlayFromBegain", self.nodeId)
            end --4
        )
    else
        self:SwitchState(UIStateType.UIN20AVGStory, self.nodeId)
    end
end
--endregion
