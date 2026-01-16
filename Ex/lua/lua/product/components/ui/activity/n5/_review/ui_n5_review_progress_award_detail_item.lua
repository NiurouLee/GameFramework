--
---@class UIN5ReviewProgressAwardDetailItem : UICustomWidget
_class("UIN5ReviewProgressAwardDetailItem", UICustomWidget)
UIN5ReviewProgressAwardDetailItem = UIN5ReviewProgressAwardDetailItem
--初始化
function UIN5ReviewProgressAwardDetailItem:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIN5ReviewProgressAwardDetailItem:InitWidget()
    --generated--
    ---@type UILocalizationText
    self.progress = self:GetUIComponent("UILocalizationText", "progress")
    ---@type RawImageLoader
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    ---@type UnityEngine.GameObject
    self.collected = self:GetGameObject("collected")
    ---@type UnityEngine.GameObject
    self.canCollect = self:GetGameObject("canCollect")
    ---@type UnityEngine.GameObject
    self.cantCollect = self:GetGameObject("cantCollect")
    ---@type UnityEngine.Animation
    self.animation = self:GetUIComponent("Animation", "animation")
    --generated end--
end
--设置数据
function UIN5ReviewProgressAwardDetailItem:SetData(id, count, progress, collected, canCollect, onClick, collectCallback)
    self.icon:LoadImage(Cfg.cfg_item[id].Icon)
    self.progressData = progress
    self.count:SetText("×" .. count)
    self.progress:SetText(progress .. "%")
    if collected then
        self.collected:SetActive(true)
        self.canCollect:SetActive(false)
        self.cantCollect:SetActive(false)
    else
        self.collected:SetActive(false)
        if canCollect then
            self.canCollect:SetActive(true)
            self.cantCollect:SetActive(false)
        else
            self.canCollect:SetActive(false)
            self.cantCollect:SetActive(true)
        end
    end
    self._onClick = onClick
    self._itemID = id
    self._collectCallback = collectCallback
end

function UIN5ReviewProgressAwardDetailItem:PlayEnterAni(delay)
    self:StartTask(
        function ()
            YIELD(TT, delay)
            self.animation:Play("uieff_N24_Main_DetailItem01")
        end
    )
end

function UIN5ReviewProgressAwardDetailItem:IconOnClick(go)
    self._onClick(self._itemID, go)
end

function UIN5ReviewProgressAwardDetailItem:CanCollectOnClick(go)
   if self._collectCallback then
        self._collectCallback(self.progressData)
        self.collected:SetActive(true)
        self.canCollect:SetActive(false)
   end
end
