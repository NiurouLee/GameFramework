---@class UIN28AVGNodeDetails:UIController
_class("UIN28AVGNodeDetails", UIController)
UIN28AVGNodeDetails = UIN28AVGNodeDetails

function UIN28AVGNodeDetails:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

function UIN28AVGNodeDetails:OnShow(uiParams)
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    self.recordTime = self:GetGameObject("recordTime")
    ---@type UILocalizationText
    self.txtTime = self:GetUIComponent("UILocalizationText", "txtTime")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self.txtName1 = self:GetUIComponent("UILocalizationText", "txtName1")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    ---@type UICustomWidgetPool
    local poolLeader = self:GetUIComponent("UISelectObjectPath", "leader")
    ---@type UIN28AVGActor
    self.leader = poolLeader:SpawnObject("UIN28AVGActor")
    ---@type UICustomWidgetPool
    self.poolPartners = self:GetUIComponent("UISelectObjectPath", "partners")
    self.anim = self:GetUIComponent("Animation", "anim")
    self.nodeId = uiParams[1]

    self:Flush()
end

function UIN28AVGNodeDetails:OnHide()
    self.imgCG:DestoryLastImage()
end

function UIN28AVGNodeDetails:Flush()
    self.node = self.data:GetNodeById(self.nodeId)
    --节点达成后固定显示已达成的图；节点未达成时优先显示未达成的图，没配未达成的图就也显示已达成的图
    local state = self.node:State()
    if state == N28AVGStoryNodeState.Complete then
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
    self.txtName1:SetText(self.node.title)
    self.txtDesc:SetText(self.node.desc)
    self:FlushActors()
end
function UIN28AVGNodeDetails:FlushTime()
    local ts = self.node:GetSaveTimestamp()
    if ts > 0 then
        self.recordTime:SetActive(true)
        local str = self.data:Timestamp2Str(ts)
        self.txtTime:SetText(str)
    else
        self.recordTime:SetActive(false)
    end
end
function UIN28AVGNodeDetails:FlushActors()
    local hp, strategies = self.node:StartData()
    self.leader:Flush(0, hp)
    local len = table.count(self.data.actorPartners)
    self.poolPartners:SpawnObjects("UIN28AVGActor", len)
    ---@type UIN28AVGActor[]
    local uis = self.poolPartners:GetAllSpawnList()
    for i, ui in ipairs(uis) do
        ui:Flush(i, strategies[i] or 0)
    end
end

--region OnClick
function UIN28AVGNodeDetails:BgOnClick(go)
    self:CloseDialog()
end
function UIN28AVGNodeDetails:BtnCloseOnClick(go)
    self.anim:Play("uieff_UIN28AVGNodeDetails_out")
    self:Lock("UIN28AVGNodeDetails_Close")
    GameGlobal.TaskManager():StartTask(
        function(TT)
            YIELD(TT, 233)
            self:UnLock("UIN28AVGNodeDetails_Close")
            self:CloseDialog()
        end,
        self
    )
end
function UIN28AVGNodeDetails:BtnStartOnClick(go)
    if GameGlobal.UIStateManager():IsShow("UIN28AVGStory") then
        PopupManager.Alert(
            "UICommonMessageBox",
            PopupPriority.Normal,
            PopupMsgBoxType.OkCancel, --1
            "", --2
            StringTable.Get("str_avg_n28_give_up_cur_node_progress_2_start_this_node"), --3
            function()
                self:CloseDialog()
                if GameGlobal.UIStateManager():IsShow("UIN28AVGGraph") then
                    GameGlobal.UIStateManager():CloseDialog("UIN28AVGGraph")
                end
                if GameGlobal.UIStateManager():IsShow("UIN28AVGEnding") then
                    GameGlobal.UIStateManager():CloseDialog("UIN28AVGEnding")
                end
                GameGlobal.UIStateManager():CallUIMethod("UIN28AVGStory", "PlayFromBegain", self.nodeId)
            end --4
        )
    else
        self:SwitchState(UIStateType.UIN28AVGStory, self.nodeId)
    end
end
--endregion
