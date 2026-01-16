---@class UIN29ShopItem : UICustomWidget
_class("UIN29ShopItem", UICustomWidget)
UIN29ShopItem = UIN29ShopItem

function UIN29ShopItem:Constructor()
    self.size = {
        big = Vector2(361, 344),
        small = Vector2(299, 324)
    }
end

function UIN29ShopItem:OnShow(uiParams)
    ---@type UnityEngine.U2D.SpriteAtlas
    self.atlas = self:GetAsset("UIN29Lottery.spriteatlas", LoadType.SpriteAtlas)

    self.go = self:GetGameObject()
    self.go:SetActive(false)
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "UIN29ShopItem")
    ---@type UnityEngine.UI.LayoutElement
    -- self.loe = self:GetUIComponent("LayoutElement", "UIN29ShopItem")
    self.big = self:GetGameObject("big")
    ---@type UnityEngine.UI.Image
    self.bgBig = self:GetUIComponent("Image", "bgBig")
    ---@type RawImageLoader
    self.imgIconBig = self:GetUIComponent("RawImageLoader", "imgIconBig")
    ---@type UILocalizationText
    self.txtCountItemBig = self:GetUIComponent("UILocalizationText", "txtCountItemBig")
    ---@type UILocalizationText
    self.txtCountAwardBig = self:GetUIComponent("UILocalizationText", "txtCountAwardBig")
    ---@type UnityEngine.UI.Image
    self.imgBigFlag = self:GetUIComponent("Image", "imgBigFlag")
    self.bigMaskGo = self:GetGameObject("bigMask")


    self.small = self:GetGameObject("small")
    ---@type UnityEngine.UI.Image
    self.bgSmall = self:GetUIComponent("Image", "bgSmall")
    ---@type RawImageLoader
    self.imgIconSmall = self:GetUIComponent("RawImageLoader", "imgIconSmall")
    ---@type UILocalizationText
    self.txtCountItemSmall = self:GetUIComponent("UILocalizationText", "txtCountItemSmall")
    ---@type UILocalizationText
    self.txtCountAwardSmall = self:GetUIComponent("UILocalizationText", "txtCountAwardSmall")
    self.smallMaskGo = self:GetGameObject("smallMask")

    ---@type RawImageLoader
    self.imgIconBigShadow = self:GetUIComponent("RawImageLoader", "imgIconBigShadow")
    ---@type RawImageLoader
    self.imgIconSmallShadow = self:GetUIComponent("RawImageLoader", "imgIconSmallShadow")


end
function UIN29ShopItem:OnHide()
    self.imgIconBig:DestoryLastImage()
    self.imgIconSmall:DestoryLastImage()
end

---@param data AwardInfo
function UIN29ShopItem:InitData(data, itemInfoCallback, unlock)
    self._data = data
    self._unlock = unlock
    self._itemId = self._data.m_item_id
    self._itemCount = self._data.m_lottery_limit_count
    self._itemRestCount = self._data.m_lottery_count
    self._itemInfoCallback = itemInfoCallback
    self:FillUi()
end
function UIN29ShopItem:FillUi()
    local itemCfg = Cfg.cfg_item[self._itemId]
    if itemCfg then
        local res = itemCfg.Icon
        local hasRest = self._itemRestCount > 0
        --上锁和抽完
        local itemCount = self._data.m_count
        -- local bgSprite
        -- local imgIconColor
        local showNumberTex = "x" .. itemCount
        local showTimesTex
        -- local starSprite
        local canGet = self._unlock and hasRest
        -- if canGet then
        --     -- imgIconColor = Color.white
        --     -- showNumberTex = "<color=#f0ede9>" .. showNumberTex .. "</color>"
        --     showTimesTex = "<color=#f7e2c4>" .. self._itemRestCount .. "/" .. self._itemCount .. "</color>"
        --     -- bgSprite = self._data.m_is_big_reward and "n29_lottery_di1" or "n29_lottery_di5"
        --     -- starSprite = "n29_lottery_di4"
        -- else
        --     -- imgIconColor = Color(1, 1, 1, 0.5)
        --     -- showNumberTex = "<color=#a1a1a1>" .. showNumberTex .. "</color>"
        --     if self._itemRestCount > 0 then
        --         showTimesTex = "<color=#606060>" .. self._itemRestCount .. "/" .. self._itemCount .. "</color>"
        --     else
        --         showTimesTex =
        --             "<color=#9a9a9a>" ..
        --             self._itemRestCount .. "</color><color=#606060>/" .. self._itemCount .. "</color>"
        --     end
        --     -- bgSprite = self._data.m_is_big_reward and "n24_shop_di3" or "n24_shop_di5"
        --     -- starSprite = "n24_shop_icon2"
        -- end

        if self._data.m_is_big_reward then
            showTimesTex = "<color=#fffae7>" .. self._itemRestCount  .. "</color>" .. "<color=#b9b2aa>/" .. self._itemCount .. "</color>"
            -- self.loe.preferredWidth = self.size.big.x
            -- self.loe.preferredHeight = self.size.big.y
            self.big:SetActive(true)
            self.small:SetActive(false)
            self.imgIconBig:LoadImage(res)
            self.imgIconBigShadow:LoadImage(res)
            self.txtCountItemBig:SetText(showNumberTex)
            self.txtCountAwardBig:SetText(showTimesTex)
            self.bigMaskGo:SetActive(not canGet)

            -- self.bgBig.sprite = self.atlas:GetSprite(bgSprite)
            -- self.imgBigFlag.sprite = self.atlas:GetSprite(starSprite)
            -- self.imgIconBig:SetColor(imgIconColor)
        else
            showTimesTex = "<color=#9a7c5f>" .. self._itemRestCount  .. "</color>" .. "<color=#292624>/" .. self._itemCount .. "</color>"
            -- self.loe.preferredWidth = self.size.small.x
            -- self.loe.preferredHeight = self.size.small.y
            self.big:SetActive(false)
            self.small:SetActive(true)
            self.imgIconSmall:LoadImage(res)
            self.imgIconSmallShadow:LoadImage(res)
            self.txtCountItemSmall:SetText(showNumberTex)
            self.txtCountAwardSmall:SetText(showTimesTex)
            self.smallMaskGo:SetActive(not canGet)

            -- self.bgSmall.sprite = self.atlas:GetSprite(bgSprite)
            -- self.imgIconSmall:SetColor(imgIconColor)
        end
    end
end

function UIN29ShopItem:ShowHide(isShow)
    self.go:SetActive(isShow)
end

function UIN29ShopItem:PlayAnim(idx)
    self:StartTask(
        function(TT)
            if idx > 1 then
                YIELD(TT, (idx - 1) * 60)
            end
            self.go:SetActive(true)
            local key = "UIN29ShopItemPlayAnim" .. self._itemId
            self:Lock(key)
            if self._data.m_is_big_reward then
                self.anim:Play("uieff_UIN29ShopItem_big")
            else
                self.anim:Play("uieff_UIN29ShopItem_small")
            end
            YIELD(TT, 867)
            self:UnLock(key)
        end,
        self
    )
end

function UIN29ShopItem:PlayOutAnim()
    self.anim:Play("uieff_UIN29ShopItem_out")
end

function UIN29ShopItem:BgOnClick(go)
    if self._itemInfoCallback then
        self._itemInfoCallback(self._data.m_item_id, go.transform.position)
    end
end
