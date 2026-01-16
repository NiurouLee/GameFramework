---@class UIActivityBattlePassExpInfo:UICustomWidget
_class("UIActivityBattlePassExpInfo", UICustomWidget)
UIActivityBattlePassExpInfo = UIActivityBattlePassExpInfo

function UIActivityBattlePassExpInfo:_GetComponents()
    ---@type UILocalizationText
    self._txtTitle1 = self:GetUIComponent("UILocalizationText", "txtTitle1")
    ---@type UILocalizationText
    self._txtTitle2 = self:GetUIComponent("UILocalizationText", "txtTitle2")
    ---@type UILocalizationText
    self._txtTitle3 = self:GetUIComponent("UILocalizationText", "txtTitle3")
    ---@type UILocalizationText
    self._txtTitle4 = self:GetUIComponent("UILocalizationText", "txtTitle4")

    self._imgProgressBg = self:GetUIComponent("Image", "imgProgressBg")
    self._imgProgressValue = self:GetUIComponent("Image", "imgProgressValue")

    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self._txtProgress = self:GetUIComponent("UILocalizationText", "txtProgress")

    self._maxObj = self:GetGameObject("max")
end

function UIActivityBattlePassExpInfo:OnShow()
    self._isOpen = true
    self:_GetComponents()

    ---@type DG.Tweening.Sequence
    self._seq = DG.Tweening.DOTween.Sequence()
end

function UIActivityBattlePassExpInfo:OnHide()
    self._isOpen = false
end

---@param type EActivityEveSinsaLevelBtnType
function UIActivityBattlePassExpInfo:SetData(componentInfo, upgrade)
    --- @type LVRewardComponentInfo
    self._componentInfo = componentInfo

    self:_SetIcon(self._componentInfo.m_item_id)
    if not upgrade then
        self:_SetExpNormal()
    else
        self:_SetExpUpgrade()
    end
end

function UIActivityBattlePassExpInfo:_SetTitle(lv)
    self._txtTitle1:SetText("Lv.")
    self._txtTitle2:SetText(lv)
    self._txtTitle3:SetText(StringTable.Get("str_activity_battlepass_main_title"))
    self._txtTitle4:SetText(StringTable.Get("str_activity_battlepass_main_title_2"))

    local eng = HelperProxy:GetInstance():IsInEnglish()
    if eng then
        self:GetGameObject("txtTitle4"):SetActive(false)
    end
end

function UIActivityBattlePassExpInfo:_SetExp(lv, progress)
    self:_SetTitle(lv)

    local maxProgress = self._componentInfo.m_level_max_progress
    local maxLv = self._componentInfo.m_max_level

    local formatStr = "%s/%s"
    self._txtProgress:SetText(string.format(formatStr, progress, maxProgress))

    local rate = progress / maxProgress
    if rate ~= nil and rate >= 0 and rate <= 1 then
        self._imgProgressValue.fillAmount = rate
    end

    self._maxObj:SetActive(lv == maxLv and progress == maxProgress)
end

function UIActivityBattlePassExpInfo:_SetIcon(itemId)
    self._cfg_item = Cfg.cfg_item[itemId]
    if self._cfg_item == nil then
        Log.fatal("[quest] error --> cfg_item is nil ! id --> " .. itemId)
        return
    end

    local icon = self._cfg_item.Icon
    self._imgIcon:LoadImage(icon)
end

function UIActivityBattlePassExpInfo:_SetExpNormal()
    self._curLv = self._componentInfo.m_current_level
    self._curProgress = self._componentInfo.m_current_progress

    self:_SetExp(self._curLv, self._curProgress)
end

function UIActivityBattlePassExpInfo:_SetExpUpgrade()
    self._expIncreaseAnimTime = 1

    local curLv = self._curLv
    local curProgress = self._curProgress
    local targetLv = self._componentInfo.m_current_level
    local targetProgress = self._componentInfo.m_current_progress

    local maxProgress = self._componentInfo.m_level_max_progress

    if curLv < targetLv then
        -- 第一阶段，先播放 curProgress -> 100% 的动画
        self:_PlayFillAmount(
            curLv,
            maxProgress,
            function()
                -- 第一阶段完成时，设置到升级后的等级，进度设置为 0%
                self:_SetExp(targetLv, 0)

                -- 播放第二阶段， 0% -> targetProgress
                self:_PlayFillAmount(targetLv, targetProgress)
            end
        )
    else
        -- 不涉及升级，直接播放
        self:_PlayFillAmount(targetLv, targetProgress)
    end

    self._curLv = targetLv
    self._curProgress = targetProgress
end

function UIActivityBattlePassExpInfo:_PlayFillAmount(lv, progress, callback)
    local maxProgress = self._componentInfo.m_level_max_progress

    local rate = progress / maxProgress
    local tweener =
        self._imgProgressValue:DOFillAmount(rate, self._expIncreaseAnimTime):OnUpdate(
        function()
            local value = math.floor(self._imgProgressValue.fillAmount * maxProgress)
            self:_SetExp(lv, value)
        end
    ):OnComplete(
        function()
            self:_SetExp(lv, progress) -- 防止浮点计算误差，设置最终结果
            if callback then
                callback()
            end
        end
    )

    self._seq:Append(tweener)
end
