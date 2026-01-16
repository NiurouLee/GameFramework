--
---@class UIHomelandDecompose : UIController
_class("UIHomelandDecompose", UIController)
UIHomelandDecompose = UIHomelandDecompose

function UIHomelandDecompose:Constructor()
    ---@type UIHomelandModule
    self._homelandModule = GameGlobal.GetUIModule(HomelandModule)
    ---@type ItemModule
    self._itemModule = GameGlobal.GetModule(ItemModule)
    ---@type HomelandClient
    self._homelandClient = self._homelandModule:GetClient()
    ---@type HomeBuildManager
    self._buildManager = self._homelandClient:BuildManager()
    self._maxCount = 100
    self._curCount = 0
    self._atlas = self:GetAsset("UIHomelandShop.spriteatlas", LoadType.SpriteAtlas)
end

--初始化
function UIHomelandDecompose:OnShow(uiParams)
    ---@type Item
    self._item = uiParams[1]
    self._cfg = self._item:GetTemplate()
    self:_GetComponents()
    self:_OnValue()
end

--获取ui组件
function UIHomelandDecompose:_GetComponents()
    ---@type UnityEngine.Animation
    self.uianim = self:GetUIComponent("Animation", "uianim")
    self._title = self:GetUIComponent("UILocalizationText", "Title")
    self._itemIcon = self:GetUIComponent("RawImageLoader", "ItemIcon")
    self._itemName = self:GetUIComponent("UILocalizationText", "ItemName")
    self._decomposeCount = self:GetUIComponent("UILocalizationText", "DecomposeCount")
    self._putCount = self:GetUIComponent("UILocalizationText", "PutCount")
    self._decompose = self:GetGameObject("Decompose")
    ---@type UnityEngine.Animation
    self.animDecompose = self:GetUIComponent("Animation", "Decompose")
    self._decomposeTitle = self:GetUIComponent("UILocalizationText", "DecomposeTitle")
    self._decomposeTips = self:GetUIComponent("UILocalizationText", "DecomposeTips")
    ---@type UISelectObjectPath
    self._content = self:GetUIComponent("UISelectObjectPath", "Content")
    ---@type UnityEngine.UI.Slider
    self._slider = self:GetUIComponent("Slider", "Slider")
    self._countValue = self:GetUIComponent("UILocalizationText", "CountValue")
    self._slider.onValueChanged:AddListener(
        function()
            self._curCount = math.min(self._maxCount, math.ceil(self._slider.value))
            self._countValue:SetText(self._curCount)
        end
    )
    self._btnConfirm = self:GetUIComponent("Image", "btnConfirm")
end

function UIHomelandDecompose:_OnValue()
    local totalCount = self._item:GetCount()
    local unPutCount = self._buildManager:GetBuildCount(self._cfg.ID)
    self._maxCount = unPutCount
    self._slider.maxValue = self._maxCount
    self._curCount = 0
    self._itemIcon:LoadImage(self._cfg.Icon)
    self._itemName:SetText(StringTable.Get(self._cfg.Name))
    self._decomposeCount:SetText(self._maxCount)
    --self._decomposeCount:SetText(StringTable.Get("str_homeland_decompose_count", self._maxCount))
    self._putCount:SetText(totalCount - unPutCount)
    --self._putCount:SetText(StringTable.Get("str_homeland_decompose_put_count", totalCount - unPutCount))
    self:_RefreshSlider()
    self._decompose:SetActive(false)
    if self._maxCount <= 0 then
        self._btnConfirm.sprite = self._atlas:GetSprite("n17_shop_btn06")
    else
        self._btnConfirm.sprite = self._atlas:GetSprite("n17_shop_btn09")
    end
end

--关闭
function UIHomelandDecompose:CloseBtnOnClick(go)
    self:PlayUIHomelandDecomposeOut(
        function()
            self:CloseDialog()
        end
    )
end
function UIHomelandDecompose:PlayUIHomelandDecomposeOut(callback)
    self:StartTask(
        function(TT)
            local key = "UIHomelandDecomposePlayUIHomelandDecomposeOut"
            self:Lock(key)
            self.uianim:Play("uieffanim_N17_UIHomelandDecompose_out")
            YIELD(TT, 200)
            self:UnLock(key)
            if callback then
                callback()
            end
        end,
        self
    )
end

--分解
function UIHomelandDecompose:DecomposeBtnOnClick(go)
    if self._maxCount == 0 then
        ToastManager.ShowHomeToast(StringTable.Get("str_homeland_tree_decompose_notice3"))
        return
    end
    if self._curCount <= 0 then
        return
    end
    self:StartTask(
        function(TT)
            self._decompose:SetActive(true)
            self:_SetDecomposeUIInfo()
            local key = "UIHomelandDecomposeDecomposeBtnOnClick"
            self:Lock(key)
            self.animDecompose:Play("uieffanim_N17_UIHomelandDecompose_in2")
            YIELD(TT, 367)
            self:UnLock(key)
        end,
        self
    )
end

-- -1
function UIHomelandDecompose:ReduceBtnOnClick(go)
    self._curCount = math.max(0, self._curCount - 1)
    self:_RefreshSlider()
end

-- +1
function UIHomelandDecompose:AddBtnOnClick(go)
    self._curCount = math.min(self._curCount + 1, self._maxCount)
    self:_RefreshSlider()
end

function UIHomelandDecompose:_RefreshSlider()
    self._slider.value = self._curCount
    self._countValue:SetText(self._curCount)
end

function UIHomelandDecompose:_SetDecomposeUIInfo()
    local str = StringTable.Get(self._cfg.Name)
    str = str .. "*" .. self._curCount
    local tipsStr = StringTable.Get("str_homeland_decompose_tips", str)
    self._decomposeTips:SetText(tipsStr)
    local cfgDecompose = Cfg.cfg_item_decompose[self._cfg.ID]
    if not cfgDecompose then
        Log.error("UIHomelandDecompose cfg_item_decompose error! " .. self._cfg.ID)
    end
    self._decomposeResult = {}
    local count = #cfgDecompose.Output

    self._maxGotItemCellCount = 10
    ---@type table<number, UIHomelandDecomposeItem>
    self._items = self._content:SpawnObjects("UIHomelandDecomposeItem", self._maxGotItemCellCount)
    ---@type table<number, RoleAsset>
    self._showItemData = {}
    for i = 1, count do
        if i <= count then
            ---@type RoleAsset
            local roleAsset = {}
            roleAsset.assetid = cfgDecompose.Output[i][1]
            roleAsset.count = cfgDecompose.Output[i][2] * self._curCount
            self._showItemData[i] = roleAsset
            table.insert(self._decomposeResult, roleAsset)
        else
        end
    end
    local onSelect = function(idx)
    end
    for i = 1, self._maxGotItemCellCount do
        self._items[i]:SetData(i, self._showItemData[i], onSelect)
    end

    -- self._content:SpawnObjects("UIItemHomeland", count)
    -- ---@type table<number, UIItemHomeland>
    -- self._items = self._content:GetAllSpawnList()
    -- for i = 1, count do
    --     ---@type RoleAsset
    --     local roleAsset = {}
    --     roleAsset.assetid = cfgDecompose.Output[i][1]
    --     roleAsset.count = cfgDecompose.Output[i][2] * self._curCount
    --     self._items[i]:Flush(roleAsset)
    --     table.insert(self._decomposeResult, roleAsset)
    -- end
end

---取消分解
function UIHomelandDecompose:CancleBtnOnClick(go)
    self:PlayUIHomelandDecomposeOut2(
        function()
            self._decompose:SetActive(false)
        end
    )
end
function UIHomelandDecompose:PlayUIHomelandDecomposeOut2(callback)
    self:StartTask(
        function(TT)
            local key = "UIHomelandDecomposeCancleBtnOnClick"
            self:Lock(key)
            self.animDecompose:Play("uieffanim_N17_UIHomelandDecompose_out2")
            YIELD(TT, 200)
            if callback then
                callback()
            end
            self:UnLock(key)
        end,
        self
    )
end

---确定分解
function UIHomelandDecompose:OnSureBtnOnClick(go)
    self:StartTask(
        function(TT)
            local key = "UIHomelandDecompose"
            self:Lock(key)
            local res = self._itemModule:ItemDecomposeByTemplate(TT, self._cfg.ID, self._curCount)
            self:UnLock(key)
            if res and res:GetSucc() then
                self:ShowDialog(
                    "UIHomeShowAwards",
                    self._decomposeResult,
                    function()
                        self:PlayUIHomelandDecomposeOut2(
                            function()
                                self:PlayUIHomelandDecomposeOut(
                                    function()
                                        self:CloseDialog()
                                    end
                                )
                            end
                        )
                    end
                )
            end
        end,
        self
    )
end
