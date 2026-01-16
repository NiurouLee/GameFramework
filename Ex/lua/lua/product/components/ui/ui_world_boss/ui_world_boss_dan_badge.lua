---@class UIWorldBossDanBadge : UICustomWidget
_class("UIWorldBossDanBadge", UICustomWidget)
UIWorldBossDanBadge = UIWorldBossDanBadge
function UIWorldBossDanBadge:OnShow(uiParams)
    self:InitWidget()
end
function UIWorldBossDanBadge:InitWidget()
    --generated--
    self._rect = self:GetUIComponent("RectTransform","Info")
    ---@type RawImageLoader
    self._myDanIconBase = self:GetUIComponent("RawImageLoader", "MyDanIconBase")
    self._myDanIconBaseGo = self:GetGameObject("MyDanIconBase")
    self._myDanPlusIconGo = self:GetGameObject("PlusIcon")
    ---@type UnityEngine.GameObject
    self._myDanIconFrontGo = self:GetGameObject("MyDanIconFrontBg")
    self._myDanIconFrontText = self:GetUIComponent("UILocalizationText","MyDanIconFrontText")
    self._myDanIconFrontTextBack = self:GetUIComponent("UILocalizationText","MyDanIconFrontTextBack")
    --generated end--
end
function UIWorldBossDanBadge:SetData(badgeStyle,danId,rankLevel,tarSizeX,tarSizeY)

    local sizeX = self._rect.sizeDelta.x
    local sizeY = self._rect.sizeDelta.y
    if not tarSizeX then
        tarSizeX = sizeX
    end
    if not tarSizeY then
        tarSizeY = sizeY
    end
    local scaleX = tarSizeX/sizeX
    local scaleY = tarSizeY/sizeY
    self._rect.localScale = Vector3(scaleX,scaleY,1)
    if UIWorldBossHelper.IsNoDan(danId,rankLevel) then--无段位
        self._myDanIconBase:LoadImage("1601191_logo")
        self._myDanIconBaseGo:SetActive(false)
        self._myDanIconFrontGo:SetActive(false)
        return
    end
    local badgeBase
    if badgeStyle == UIWroldBossBadgeStype.WBBS_NORMAL then
        badgeBase = UIWorldBossHelper.GetDanBadgeBase(danId,rankLevel)
    elseif badgeStyle == UIWroldBossBadgeStype.WBBS_SIMPLE then
        badgeBase = UIWorldBossHelper.GetDanBadgeBaseSimple(danId,rankLevel)
    end
    if badgeBase then
        self._myDanIconBaseGo:SetActive(true)
        self._myDanIconBase:LoadImage(badgeBase)
        if rankLevel > 0 then
            self._myDanIconFrontGo:SetActive(true)
            self._myDanIconFrontText:SetText(tostring(rankLevel))
            if self._myDanIconFrontTextBack then
                self._myDanIconFrontTextBack:SetText(tostring(rankLevel))
            end
        else
            self._myDanIconFrontGo:SetActive(false)
        end
        local bPlus = UIWorldBossHelper.IsPlusDan(danId,rankLevel)
        --加号
        self._myDanPlusIconGo:SetActive(bPlus)
    end
end

function UIWorldBossDanBadge:EnableRankLevel(isEnable)
    self._myDanIconFrontGo:SetActive(isEnable)
end

function UIWorldBossDanBadge:RankLevelTransform(position, scale)
    local transform = self._myDanIconFrontGo.transform
    transform.localScale = Vector3(scale, scale, 1)
    transform.anchoredPosition = position
end
