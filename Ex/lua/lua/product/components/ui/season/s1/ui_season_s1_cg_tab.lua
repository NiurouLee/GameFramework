--
---@class UISeasonS1CGTab : UICustomWidget
_class("UISeasonS1CGTab", UICustomWidget)
UISeasonS1CGTab = UISeasonS1CGTab
--初始化
function UISeasonS1CGTab:OnShow(uiParams)
    self:InitWidget()
    self:AttachEvent(GameEventType.OnSeasonShareCgFinished, self._OnShareFinish)
end

--获取ui组件
function UISeasonS1CGTab:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.content = self:GetUIComponent("UISelectObjectPath", "Content")
    --generated end--

    self._anim = self:GetGameObject():GetComponent(typeof(UnityEngine.Animation))
end

--设置数据
---@param data UISeasonCollageData
---@param seasonObj UISeasonObj
function UISeasonS1CGTab:SetData(data, seasonObj)
    self._collageData = data
    self._cpt = seasonObj:GetComponent(ECCampaignSeasonComponentID.STORY)
    self._collageData:RefreshCgShareState(self._cpt) --用之前刷新一下分享状态
    self._seasonID = data:GetSeasonID()
    local count = self._collageData:GetCGCount()
    ---@type UISeasonS1CollageCGItem[]
    self._items = self.content:SpawnObjects("UISeasonS1CollageCGItem", count)

    local onSelect = function(data)
        self:_OnSelect(data)
    end
    -- self:SetShow(true)
    for i = 1, count do
        self._items[i]:SetData(self._collageData:GetCGByIndex(i), onSelect)
    end
end

function UISeasonS1CGTab:SetShow(show)
    self:GetGameObject():SetActive(show)
end

---@param data UISeasonCollageData_CG
function UISeasonS1CGTab:_OnSelect(data)
    if not data:IsUnlock() then
        return
    end
    if data:IsNew() then
        self._collageData:CGCancelNew(data)
        self._items[data:Index()]:SetNew(false)
        self:DispatchEvent(GameEventType.UISeasonS1OnSelectCollageItem)
    end
    self:ShowDialog("UISeasonCgDetailController",
        Cfg.cfg_cg_book[data:ID()],
        self._cpt
    )
end

function UISeasonS1CGTab:_OnShareFinish(id)
    self._collageData:RefreshCgShareState(self._cpt) --用之前刷新一下分享状态
    local count = self._collageData:GetCGCount()
    for i = 1, count do
        self._items[i]:ResetShareState()
    end
end

function UISeasonS1CGTab:PlayExitAnim()
    self._anim:Play("uieffanim_UISeasonS1CGTab_out")
    local count = self._collageData:GetCGCount()
    for i = 1, count do
        self._items[i]:PlayExitAnim()
    end
end
