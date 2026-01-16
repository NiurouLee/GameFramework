---@class UIN28AVGEnding:UIController
_class("UIN28AVGEnding", UIController)
UIN28AVGEnding = UIN28AVGEnding

function UIN28AVGEnding:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN28AVGData()
end

--region Request
---@param res AsyncRequestRes
function UIN28AVGEnding:LoadDataOnEnter(TT, res, uiParams)
    self.endId = uiParams[1]
    self.nodeId = uiParams[2]
    local key = "UIN28AVGEndingHandleComplateEnding"
    self:Lock(key)
    local com = self.data:GetComponentAVG()
    local res = AsyncRequestRes:New()
    local ret = com:HandleComplateEnding(TT, res, self.endId) --【请求】达成结局/BE
    if N28AVGData.CheckCode(res) then
        Log.info("### reach ending", self.endId)
    end
    self:UnLock(key)
end
--endregion

function UIN28AVGEnding:OnShow(uiParams)
    self.ne = self:GetGameObject("ne")
    self.be = self:GetGameObject("be")
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self.txtName1 = self:GetUIComponent("UILocalizationText", "txtName1")
    ---@type UILocalizationText
    self.txtNE = self:GetUIComponent("UILocalizationText", "txtNE")
    ---@type RawImageLoader
    self.imgBigCG = self:GetUIComponent("RawImageLoader", "imgBigCG")
    self.goBigCG = self:GetGameObject("goBigCG")
    self.goBigCG:SetActive(false)
    ---@type UILocalizationText
    self.txtTitleBE = self:GetUIComponent("UILocalizationText", "txtTitleBE")
    ---@type UILocalizationText
    self.txtBE = self:GetUIComponent("UILocalizationText", "txtBE")

    self:Flush()
end

function UIN28AVGEnding:OnHide()
    self.imgCG:DestoryLastImage()
    self.imgBigCG:DestoryLastImage()
end

function UIN28AVGEnding:Flush()
    local ending = self.data:GetEndingById(self.endId)
    if ending.isBE then
        self.ne:SetActive(false)
        self.be:SetActive(true)
        self.txtTitleBE:SetText(ending.title)
        self.txtBE:SetText(ending.desc)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20ShowBadendUI)
        UIWidgetHelper.PlayAnimation(self, "anim", "uieff_UIN28AVGEnding_be_in", 1133)
    else
        self.ne:SetActive(true)
        self.be:SetActive(false)
        self.imgCG:LoadImage(ending.cgEnding)
        self.imgBigCG:LoadImage(ending.cg)
        self.txtName:SetText(ending.title)
        self.txtName1:SetText(ending.title)
        self.txtNE:SetText(ending.desc)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20ShowNormalResult)
        UIWidgetHelper.PlayAnimation(self, "anim", "uieff_UIN28AVGEnding_ne_in", 1000)
    end
end

--region OnClick
function UIN28AVGEnding:BtnShowCGOnClick(go)
    self.goBigCG:SetActive(true)
end
function UIN28AVGEnding:ImgBigCGOnClick(go)
    self.goBigCG:SetActive(false)
end

function UIN28AVGEnding:BtnExitNEOnClick(go)
    self:ShowUIN28AVGMain()
end
function UIN28AVGEnding:BtnExitBEOnClick(go)
    self:ShowUIN28AVGMain()
end
function UIN28AVGEnding:ShowUIN28AVGMain()
    self:StartTask(
        function(TT)
            local key = "UIN28AVGEndingShowUIN28AVGMain"
            self:Lock(key)
            local com = self.data:GetComponentAVG()
            local res = AsyncRequestRes:New()
            local nodeId = self.data:FirstNodeId() --结局完后将当前位置设置到开头结点，以使AVG主界面显示【新游戏】
            local ret = com:HandleSetCurrentLocation(TT, res, nodeId) ---【请求】存储位置
            if N28AVGData.CheckCode(res) then
                self:SwitchState(UIStateType.UIN28AVGMain)
            end
            self:UnLock(key)
        end,
        self
    )
end
function UIN28AVGEnding:BtnTreeNEOnClick(go)
    self:ShowUIN28AVGGraph()
end
function UIN28AVGEnding:BtnTreeBEOnClick(go)
    self:ShowUIN28AVGGraph()
end
function UIN28AVGEnding:ShowUIN28AVGGraph()
    local ending = self.data:GetEndingById(self.endId)
    if ending.isBE then
        self:ShowDialog("UIN28AVGGraph")
    else
        self:ShowDialog("UIN28AVGGraph", true, self.endId, self.nodeId)
    end
end

--endregion
