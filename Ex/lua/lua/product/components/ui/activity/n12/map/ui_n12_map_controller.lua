---@class UIN12MapController : UIController
_class("UIN12MapController", UIController)
UIN12MapController = UIN12MapController

function UIN12MapController:OnShow(uiParams)
    self._nodeid = uiParams[1]
    self._stageid = uiParams[2]
    ---@type EntrustComponent
    self._component = uiParams[3]

    ---@type CampaignModule
    self._campaignModule = GameGlobal.GetModule(CampaignModule)

    self._rate = self:GetN12Rate()
    self._oldRate = self._rate

    if self["GetComponents"] then
        --self["GetComponents"]()
        self:GetComponents()
    end
    if self["OnValue"] then
        --self["OnValue"]()
        self:OnValue()
    end
end
function UIN12MapController:SetPass(btn)
    --检查剧情是否看过
    self._pass = self:CheckFinish()
    self._passGo:SetActive(self._pass)

    if btn then
        local alpha
        local sprite
        local inter
        if self._pass then
            alpha = 0.3
            sprite = "n12_ewai_btn_com2"
            inter = false
        else
            alpha = 1    
            sprite = "n12_ewai_btn_com"
            inter = true
        end
        
        self._alpha.alpha = alpha
        self._btnImg.raycastTarget = inter
        self._btnImg.sprite = self._atlas:GetSprite(sprite)
    end
end
function UIN12MapController:SetTextMat()
    local tex = self:GetUIComponent("UILocalizedTMP","btnTex")
    self:SetFontMat(tex,"uieff_n12_map_leave_tex.mat") 
end
function UIN12MapController:SetFontMat(lable,resname)
    self._res = ResourceManager:GetInstance():SyncLoadAsset(resname, LoadType.Mat)
    if not self._res  then return end 
    local obj  = self._res.Obj
    local mat = lable.fontMaterial
    lable.fontMaterial = obj
    lable.fontMaterial:SetTexture("_MainTex", mat:GetTexture("_MainTex"))
end
---@return EntrustLevelData
function UIN12MapController:GetEntrustData()
    local clientData = self._component.m_client_data
    local data = clientData.datas[self._stageid]
    return data
end
--设置当前界面的类型
---@param type EntrustEventType
function UIN12MapController:SetNodeType(type)
    ---@type EntrustEventType
    self._nodeType = type
end
function UIN12MapController:Cfg()
    local cfg = Cfg.cfg_campaign_entrust_event[self._nodeid]
    if not cfg then
        Log.error("###[UIN12MapController] cfg is nil ! id --> ",self._nodeid)
    end
    return cfg
end
--检查进度
function UIN12MapController:GetN12Rate()
    ---@type EntrustEventType
    local data = self:GetEntrustData()
    if not data then
        return 0
    end
    local all = data.total_events
    if all == 0 then
        return 0
    end
    local now = data.complete_events
    local rate = now/all
    return rate
end
--检查已完成
function UIN12MapController:CheckFinish()
    local data = self:GetEntrustData()
    if not data then
        return false
    end
    local nodePassList = data.rewarded_events
    if nodePassList and next(nodePassList) then
        return table.icontains(nodePassList,self._nodeid)
    end
end
--完成请求
function UIN12MapController:RequestFinishEvent()
    self:Lock("UIN12MapController:RequestFinishEvent")
    self:StartTask(function(TT)
        local AsyncRequestRes = AsyncRequestRes:New()
        local res,msg = self._component:HandleCompleteEvent(TT,AsyncRequestRes,self._stageid,self._nodeid)
        self:UnLock("UIN12MapController:RequestFinishEvent")
        if res:GetSucc() then
            local rewards = msg.rewards
            if self["OnFinishEvent"] then
                self:OnFinishEvent(rewards)
            end
            self._rate = self:GetN12Rate()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN12CloseMapWindow)
        else
            local result = res:GetResult()
            Log.error("###[UIN12MapController] HandleCompleteEvent fail ! stageid[",self._stageid,"] nodeid[",self._nodeid,"] result[",result,"]")

            self:CloseDialog()
        end
    end)
end
function UIN12MapController:ChangeTextWidth(tex)
    local width = tex.preferredWidth
    if width > 760 then
        self._contentSizeFitter.enabled = false
        tex.enableAutoSizing = true
        self._btnTexRect.sizeDelta = Vector2(760,60)
    end
end
function UIN12MapController:OnHide()
    if 1 ~= self._oldRate and self._rate == 1 then
        UIActivityN12Helper.N12_MapNode_Over(self._nodeid,self._stageid,self._component)
    end
    if self._res then
        self._res:Dispose()
        self._res = nil
    end
end
function UIN12MapController:closeBtnOnClick()
    self:CloseDialog()
end
