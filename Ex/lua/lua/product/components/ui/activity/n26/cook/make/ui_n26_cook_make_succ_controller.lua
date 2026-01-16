--
---@class UIN26CookMakeSuccController : UIController
_class("UIN26CookMakeSuccController", UIController)
UIN26CookMakeSuccController = UIN26CookMakeSuccController

---@param res AsyncRequestRes
function UIN26CookMakeSuccController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UIN26CookMakeSuccController:OnShow(uiParams)
    self:InitWidget()

    self._dataId = uiParams[1]
    self._afterStoryId = uiParams[2]
    self._foodCfg = Cfg.cfg_component_newyear_dinner_food[self._dataId]
    if not self._foodCfg then
        Log.error("UIN26CookMakeSuccController error , cfg_component_newyear_dinner_food can not find id : " .. self._dataId)
        return
    end
    self._foodId = self._foodCfg.FoodID
    self.title:SetText(StringTable.Get(self._foodCfg.Name))
    self.icon:LoadImage(self._foodCfg.BigTu)
    self:InitReward(self._foodCfg.Reward)
end

function UIN26CookMakeSuccController:InitReward(rewards)
    local len = #rewards
    local items = self.list:SpawnObjects("UIN26CookRewardItem",len)
    for k, v in ipairs(items) do
        local rewardData = rewards[k]
        local tplId = rewardData[1]
        local num = rewardData[2]
        v:SetData(tplId, num, function (id, pos)
            self:OnItemClicked(id, pos)
        end)
    end
end


--获取ui组件
function UIN26CookMakeSuccController:InitWidget()
    --generated--
    ---@type UICustomWidgetPool
    self.list = self:GetUIComponent("UISelectObjectPath", "list")
    ---@type UILocalizationText
    self.title = self:GetUIComponent("UILocalizationText", "title")
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    --generated end--

    self._itemInfo = self:GetUIComponent("UISelectObjectPath", "itemInfo")
    self._selectInfo = self._itemInfo:SpawnObject("UISelectInfo")
end

function UIN26CookMakeSuccController:OnItemClicked(matid, pos)
    self._selectInfo:SetData(matid, pos)
end


function UIN26CookMakeSuccController:MaskOnClick(go)
    self:CloseDialog()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnN26CookMakeSucc)
    self:ChecAfterStory()
end

function UIN26CookMakeSuccController:ChecAfterStory()
    if not self._afterStoryId then
        return
    end

    local key = "N26CookAfterStory_"..self._foodId
    if UIN26CookData.HasKey(key) then
        return
    end
    UIN26CookData.SetKey(key)
    self:ShowDialog("UIStoryController", self._afterStoryId)
end
