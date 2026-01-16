--
---@class UIN5ReviewProgressAward : UICustomWidget
_class("UIN5ReviewProgressAward", UICustomWidget)
UIN5ReviewProgressAward = UIN5ReviewProgressAward
--初始化
function UIN5ReviewProgressAward:OnShow(uiParams)
    self:InitWidget()
end
--获取ui组件
function UIN5ReviewProgressAward:InitWidget()
    ---@type UnityEngine.UI.Image
    self.icon = self:GetUIComponent("Image", "icon")
    ---@type UnityEngine.RectTransform
    self.root = self:GetUIComponent("RectTransform", "root")
    ---@type UnityEngine.Animation
    self.animation = self:GetUIComponent("Animation","animation")
end
--设置数据
---@param idx number
---@param curIndex number
---@param progress number
function UIN5ReviewProgressAward:SetData(idx, curIndex, progress, curProgress, status)
    ---@type UnityEngine.RectTransform
    local parent = self.root.parent:GetComponent(typeof(UnityEngine.RectTransform))
    local width = parent.rect.width
    self.root.anchoredPosition = Vector2(width * progress / 100, 0)
    local atlas = self:GetAsset("UIN5.spriteatlas", LoadType.SpriteAtlas)
    if curIndex == -1 then
        --全部领取完了
        self.root.anchoredPosition = Vector2(width * progress / 100, 0)
        self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon02")
    -- elseif idx > curIndex then
    --     self.root.anchoredPosition = Vector2(width * progress / 100, 0)
    --     self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon01")
    -- elseif idx < curIndex then
    --     self.root.anchoredPosition = Vector2(width * progress / 100, 0)
    --     self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon02")
    else
        if status == 1 then --1:已领取
            self.root.anchoredPosition = Vector2(width * progress / 100, 0)
            self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon02")
        elseif status == 2 then --2:最近的可领取
            self.root.anchoredPosition = Vector2(width * progress / 100, 2)
            self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon03") 
        elseif status == 3 then --3:可领取或未完成
            self.root.anchoredPosition = Vector2(width * progress / 100, 0)
            self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon01")
        end

        -- if curProgress >= progress then
        --     if idx < curIndex then
        --         self.root.anchoredPosition = Vector2(width * progress / 100, 0)
        --         self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon02") 
        --     else  
        --         self.root.anchoredPosition = Vector2(width * progress / 100, 2)
        --         self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon03")
        --     end 
        -- else
        --     self.root.anchoredPosition = Vector2(width * progress / 100, 0)
        --     self.icon.sprite = atlas:GetSprite("hdhg_n5zjm_icon01")
        -- end
    end
    self.icon:SetNativeSize()
end
function UIN5ReviewProgressAward:PlayEnterAni(delay)
    self:StartTask(function (TT)
            YIELD(TT, delay)
            self.animation:Play("uieff_N24_Main_Review_icon01")
    end, self)
end
