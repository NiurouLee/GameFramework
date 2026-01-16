--
---@class UIN25CampaignShopItemSmall : UICampaignShopItemSmall
_class("UIN25CampaignShopItemSmall", UICampaignShopItemSmall)
UIN25CampaignShopItemSmall = UIN25CampaignShopItemSmall


function UIN25CampaignShopItemSmall:_FillRemainArea()
    local showRemain = self._data:ShowRemain()
    local remainCount = self._data:GetRemainCount()
    if showRemain == false then
        self._itemRestAreaGO:SetActive(false)
    else
        if self._data:IsUnLimit() then
            self._itemRestAreaGO:SetActive(false)
        else
            if remainCount <= 0 then
                self._itemRestAreaGO:SetActive(false)
            else
                self._itemRestAreaGO:SetActive(true)
                -- 限购10
                --self._itemRestText:SetText(StringTable.Get("str_activity_evesinsa_shop_remain",remainCount))
                self._itemRestText:SetText(remainCount)
            end
        end
    end
    if self._data:IsUnLimit() then
        self._selledAreaGO:SetActive(false)
        self._infoCanvasGroup.blocksRaycasts = true
    else
        if remainCount <= 0 then
            self._selledAreaGO:SetActive(true)
            --self._infoCanvasGroup.alpha = 0.5
            self._infoCanvasGroup.blocksRaycasts = false
        else
            self._selledAreaGO:SetActive(false)
            --self._infoCanvasGroup.alpha = 1
            self._infoCanvasGroup.blocksRaycasts = true
        end
    end
end

function UIN25CampaignShopItemSmall:PlaySellOutAni()
    if not self.sellOutAni then
        self.sellOutAni = self:GetUIComponent("Animation", "sellOutAni")
    end
    self.sellOutAni:Play()
end