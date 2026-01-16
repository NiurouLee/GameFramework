---@class UIN20AVGEnding:UIController
_class("UIN20AVGEnding", UIController)
UIN20AVGEnding = UIN20AVGEnding

function UIN20AVGEnding:Constructor()
    self.mCampaign = GameGlobal.GetModule(CampaignModule)
    self.data = self.mCampaign:GetN20AVGData()
end

--region Request
---@param res AsyncRequestRes
function UIN20AVGEnding:LoadDataOnEnter(TT, res, uiParams)
    self.endId = uiParams[1]
    local key = "UIN20AVGEndingHandleComplateEnding"
    self:Lock(key)
    local com = self.data:GetComponentAVG()
    local res = AsyncRequestRes:New()
    local ret = com:HandleComplateEnding(TT, res, self.endId) --【请求】达成结局/BE
    if N20AVGData.CheckCode(res) then
        Log.info("### reach ending", self.endId)
    end
    self:UnLock(key)
end
--endregion

function UIN20AVGEnding:OnShow(uiParams)
    self.ne = self:GetGameObject("ne")
    self.be = self:GetGameObject("be")
    ---@type RawImageLoader
    self.imgCG = self:GetUIComponent("RawImageLoader", "imgCG")
    ---@type UILocalizationText
    self.txtName = self:GetUIComponent("UILocalizationText", "txtName")
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

function UIN20AVGEnding:OnHide()
    self.imgCG:DestoryLastImage()
    self.imgBigCG:DestoryLastImage()
end

function UIN20AVGEnding:Flush()
    local ending = self.data:GetEndingById(self.endId)
    if ending.isBE then
        self.ne:SetActive(false)
        self.be:SetActive(true)
        self.txtTitleBE:SetText(ending.title)
        self.txtBE:SetText(ending.desc)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20ShowBadendUI)
        UIWidgetHelper.PlayAnimation(self, "anim", "uieff_UIN20AVGEnding_be_in", 1133)
    else
        self.ne:SetActive(true)
        self.be:SetActive(false)
        self.imgCG:LoadImage(ending.cgEnding)
        self.imgBigCG:LoadImage(ending.cg)
        self.txtName:SetText(ending.title)
        self.txtNE:SetText(ending.desc)
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N20ShowNormalResult)
        UIWidgetHelper.PlayAnimation(self, "anim", "uieff_UIN20AVGEnding_ne_in", 1000)
    end
end

--region OnClick
function UIN20AVGEnding:btnShowCGOnClick(go)
    self.goBigCG:SetActive(true)
end
function UIN20AVGEnding:imgBigCGOnClick(go)
    self.goBigCG:SetActive(false)
end

function UIN20AVGEnding:btnExitNEOnClick(go)
    self:ShowUIN20AVGMain()
end
function UIN20AVGEnding:btnExitBEOnClick(go)
    self:ShowUIN20AVGMain()
end
function UIN20AVGEnding:ShowUIN20AVGMain()
    self:StartTask(
        function(TT)
            local key = "UIN20AVGEndingShowUIN20AVGMain"
            self:Lock(key)
            local com = self.data:GetComponentAVG()
            local res = AsyncRequestRes:New()
            local nodeId = self.data:FirstNodeId() --结局完后将当前位置设置到开头结点，以使AVG主界面显示【新游戏】
            local ret = com:HandleSetCurrentLocation(TT, res, nodeId) ---【请求】存储位置
            if N20AVGData.CheckCode(res) then
                self:SwitchState(UIStateType.UIN20AVGMain)
            end
            self:UnLock(key)
        end,
        self
    )
end
function UIN20AVGEnding:btnTreeNEOnClick(go)
    self:ShowUIN20AVGGraph()
end
function UIN20AVGEnding:btnTreeBEOnClick(go)
    self:ShowUIN20AVGGraph()
end
function UIN20AVGEnding:ShowUIN20AVGGraph()
    local ending = self.data:GetEndingById(self.endId)
    if ending.isBE then
        self:ShowDialog("UIN20AVGGraph")
    else
        self:ShowDialog("UIN20AVGGraph", true, self.endId)
    end
end

--endregion
