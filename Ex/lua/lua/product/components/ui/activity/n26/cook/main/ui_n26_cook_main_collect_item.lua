--
---@class UIN26CookMainCollectItem : UICustomWidget
_class("UIN26CookMainCollectItem", UICustomWidget)
UIN26CookMainCollectItem = UIN26CookMainCollectItem

--初始化
function UIN26CookMainCollectItem:OnShow(uiParams)
    self._atlas = self:GetAsset("UIN26Cook.spriteatlas", LoadType.SpriteAtlas)
    self:InitWidget()
end

--获取ui组件
function UIN26CookMainCollectItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.collectNumText = self:GetUIComponent("UILocalizationText", "collectNumText")
    ---@type UICustomWidgetPool
    self.rewardPool = self:GetUIComponent("UISelectObjectPath", "rewardPool")
    ---@type UnityEngine.GameObject
    self.canReceive = self:GetGameObject("canReceive")
    ---@type UnityEngine.GameObject
    self.hasReceive = self:GetGameObject("hasReceive")
    ---@type UnityEngine.GameObject
    self.unReach = self:GetGameObject("unReach")
    ---@type UnityEngine.UI.Image
    self.imgBg = self:GetUIComponent("Image","imgBg")
    self.animation = self:GetUIComponent("Animation","animation")
    --generated end--
end

--设置数据
function UIN26CookMainCollectItem:SetData(collectData, callback, itemClickCall)
    self.callback = callback
    self.itemClickCall = itemClickCall
    if not  collectData then
        Log.error("UIN26CookMainCollectItem collectDara is nil")
        return
    end
    local cfg = collectData.cfg
    self.collectId = cfg.CollectID
    ---@type NewYearDinner_Status
    local status = collectData.status
    self.canReceive:SetActive(status == NewYearDinner_Status.E_NewYearDinner_Status_CAN_RECV)
    self.hasReceive:SetActive(status == NewYearDinner_Status.E_NewYearDinner_Status_RECVED)
    local isUnReach = status == NewYearDinner_Status.E_NewYearDinner_Status_LOCK or 
            status == NewYearDinner_Status.E_NewYearDinner_Status_UN_FINISH
    self.unReach:SetActive(isUnReach)

    self:InitReward(cfg.Reward)
    if isUnReach then
        self.imgBg.sprite = self._atlas:GetSprite("n26_xyx_di02")
        self.collectNumText:SetText("<color=#ffdf80>"..cfg.Count.."</color>")
    else
        self.imgBg.sprite = self._atlas:GetSprite("n26_xyx_di03")
        self.collectNumText:SetText(cfg.Count)
    end
end

function UIN26CookMainCollectItem:InitReward(rewards)
    local len = #rewards
    local items = self.rewardPool:SpawnObjects("UIN26CookRewardItem",len)
    for k, v in ipairs(items) do
        local rewardData = rewards[k]
        local tplId = rewardData[1]
        local num = rewardData[2]
        v:SetData(tplId, num, function(tplId, pos)
            if self.itemClickCall then
                self.itemClickCall(tplId, pos)
            end
        end)
    end
end

--按钮点击
function UIN26CookMainCollectItem:ReceiveBtnOnClick(go)
    if self.callback then
        self.callback(self.collectId)
    end
end

function UIN26CookMainCollectItem:PlayEnterAni()
   self.animation:Play() 
end

function UIN26CookMainCollectItem:SetVisible(visible)
    self:GetGameObject():SetActive(visible)
end
