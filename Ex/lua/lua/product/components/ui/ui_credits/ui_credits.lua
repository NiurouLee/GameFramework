---@class UICredits:UIController
_class("UICredits", UIController)
UICredits = UICredits

function UICredits:OnShow(uiParam)
    self.tran = self:GetGameObject().transform
    ---@type UILocalizationText
    self.txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")

    self.goBtns = self:GetGameObject("btns")
    self.goBtns:SetActive(false)
    ---@type UICustomWidgetPool
    local btns = self:GetUIComponent("UISelectObjectPath", "btns")
    ---@type UICommonTopButton
    self._backBtns = btns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil
    )
    local credits = Cfg.cfg_credits()
    local len = table.count(credits)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", "vlg")
    pool:SpawnObjects("UICreditsItem", len)
    ---@type UICreditsItem[]
    local items = pool:GetAllSpawnList()
    ---@type UILocalizationText[]
    local txts = {self.txtTitle} --存储Text的表
    for i, cfgv in ipairs(credits) do
        local title = StringTable.Get(cfgv.title)
        local strNames = StringTable.Get(cfgv.names)
        local tName = string.split(strNames, ";")

        --region UICreditsItem
        local uiCreditsItem = items[i]
        uiCreditsItem.txtTitle:SetText(title)
        local len = table.count(tName)
        if len >= 7 then
            uiCreditsItem.glg.constraintCount = 3
        else
            uiCreditsItem.glg.constraintCount = 1
        end
        uiCreditsItem.pool:SpawnObjects("UICreditsNameItem", len)
        ---@type UICreditsNameItem[]
        local itemsUICreditsNameItem = uiCreditsItem.pool:GetAllSpawnList()
        for j, uiCreditsNameItem in ipairs(itemsUICreditsNameItem) do
            --region UICreditsNameItem
            uiCreditsNameItem.txtName:SetText(tName[j])
            table.insert(txts, uiCreditsNameItem.txtName)
            --endregion
        end
        table.insert(txts, uiCreditsItem.txtTitle)
        --endregion
    end

    ---@type UnityEngine.RectTransform
    self.tranVlg = self:GetUIComponent("RectTransform", "vlg")
    ---@type UnityEngine.RectTransform
    self.tranC = self:GetUIComponent("RectTransform", "c")
    local beginY = -200
    local endY = 28400 + self.tranC.rect.height
    local duration = (endY - beginY) * 0.005
    self.tranVlg.anchoredPosition = Vector2(0, beginY)
    self.tweener =
        self.tranVlg:DOAnchorPosY(endY, duration):OnComplete(
        function()
            self:CloseDialog()
        end
    ):SetEase(DG.Tweening.Ease.Linear)

    ---@type UICustomWidgetPool
    local poolEffs = self:GetUIComponent("UISelectObjectPath", "effs")
    poolEffs:SpawnObjects("UICreditsEffItem", table.count(txts))
    ---@type UICreditsEffItem[]
    self.itemsEff = poolEffs:GetAllSpawnList()
    for i, uiitem in ipairs(self.itemsEff) do
        uiitem:Flush(txts[i])
    end

    ---@type UnityEngine.Camera
    self._cam = self:GetGameObject("Camera"):GetComponent("Camera")
    ---@type UnityEngine.Camera
    local uiCamera = GameGlobal.UIStateManager():GetControllerCamera("UICredits")
    self._cam.transform.parent = uiCamera.transform.parent
    self._cam.transform.localPosition = Vector3(0, 0, -10)
    self._cam.transform.localScale = Vector3.one
    self._cam.targetTexture = UnityEngine.RenderTexture:New(UnityEngine.Screen.width, UnityEngine.Screen.height, 16)
end
function UICredits:OnHide()
    if self.tweener then
        self.tweener:Kill()
        self.tweener = nil
    end
    self._cam.targetTexture:Release()
    self._cam.targetTexture = nil
    self._cam.transform.parent = self.tran
end

function UICredits:bgOnClick(go)
    self:ShowHideBtns()
end

function UICredits:ShowHideBtns()
    if self.goBtns.activeInHierarchy then
        self.goBtns:SetActive(false)
    else
        self.goBtns:SetActive(true)
    end
end

function UICredits:OnUpdate(dt)
    for i, uiitem in ipairs(self.itemsEff) do
        uiitem:OnUpdate()
        self._cam.targetTexture:SetGlobalShaderProperty("RTUICredits")
    end
end
