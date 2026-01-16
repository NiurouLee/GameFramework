---@class UIAircraftResolve : UICustomWidget
_class("UIAircraftResolve", UICustomWidget)
UIAircraftResolve = UIAircraftResolve
function UIAircraftResolve:OnShow(uiParams)
    self._JXPressCfg = Cfg.cfg_item_smelt_long_press[0] --巨像长按配置
    -- self._pressTimeConst = self._JXPressCfg.PressTime
    self._pressTimeGape = 0 --长按间隔

    self:InitWidget()
    self:AddButtonEvent()
    self._airModule = self:GetModule(AircraftModule)
    self._roleModule = self:GetModule(RoleModule)
    self._petModule = self:GetModule(PetModule)
    self._itemModule = self:GetModule(ItemModule)

    self:RefreshData()

    self._itemColorFrame = {
        [ItemColor.ItemColor_White] = "spirit_shengji_se1",
        [ItemColor.ItemColor_Green] = "spirit_shengji_se2",
        [ItemColor.ItemColor_Blue] = "spirit_shengji_se3",
        [ItemColor.ItemColor_Purple] = "spirit_shengji_se4",
        [ItemColor.ItemColor_Yellow] = "spirit_shengji_se5",
        [ItemColor.ItemColor_Golden] = "spirit_shengji_se6"
    }

    self._tab2 = nil

    --当前选中，可为空table，巨像材料只能选择1个，光珀材料能选多个
    self._selections = {}

    ---@type UIAircraftGuangPoFilter
    self._xinpoFilter = self.filter:SpawnObject("UIAircraftGuangPoFilter")
    self._xinpoFilter:SetData(
        function(type, toggle)
            self:OnXinpoFilterChanged(type, toggle)
        end
    )

    self._onClickItem = function(idx)
        self:OnClickItem(idx)
    end

    self._onLongPressItem = function(idx, go)
        local id
        if self._tab2 == ResolveTab2.JuXiang then
            id = self._juxiangCfgs[idx].Input[1][1]
            self:ShowItemTips(id, go.transform.position)
        elseif self._tab2 == ResolveTab2.XinPo then
            id = self._xinpoCfgs[idx].Input[1][1]
        end
        self:ShowItemTips(id, go.transform.position)
    end

    self.scrollView:InitListView(
        0,
        function(scrollView, index)
            return self:_newRawItem(scrollView, index)
        end
    )
end

function UIAircraftResolve:RefreshData()
    --处理数据
    local juxiang_show = Cfg.cfg_item_smelt {Tab = ResolveTab2.JuXiang}
    if juxiang_show == nil then
        juxiang_show = {}
    end
    table.sort(
        juxiang_show,
        function(a, b)
            return a.Index < b.Index
        end
    )
    local xinPoCfgs = Cfg.cfg_item_smelt {Tab = ResolveTab2.XinPo}
    if xinPoCfgs == nil then
        xinPoCfgs = {}
    end

    --全部心珀
    local xinpo_show = {}
    --按星等区分的心珀
    local xinpo_star = {
        [XinPoFilter.All] = {},
        [XinPoFilter.Star4] = {},
        [XinPoFilter.Star5] = {},
        [XinPoFilter.Star6] = {}
    }
    for _, cfg in pairs(xinPoCfgs) do
        if cfg.Pet == nil then
            AirError("心珀材料没配星灵ID:", cfg.ID)
        end
        if #cfg.Input > 1 then
            AirError("心珀材料配了多个输入:", cfg.ID)
        end
        ---@type Pet
        local pet = self._petModule:GetPetByTemplateId(cfg.Pet)
        if pet and pet:IsBreakFull() then
            local id = cfg.Input[1][1]
            if self._roleModule:GetAssetCount(id) > 0 then
                xinpo_show[#xinpo_show + 1] = cfg
            end
        end
    end
    table.sort(
        xinpo_show,
        function(a, b)
            return a.Index < b.Index
        end
    )
    for idx, cfg in ipairs(xinpo_show) do
        ---@type Pet
        local pet = self._petModule:GetPetByTemplateId(cfg.Pet)
        --使用星灵的星等
        local star = pet:GetPetStar()
        if star <= 3 then
            AirError("三星星灵不应该有心珀:", cfg.ID)
        end
        table.insert(xinpo_star[star], idx)
        table.insert(xinpo_star[XinPoFilter.All], idx)
    end

    self._juxiangCfgs = juxiang_show
    self._xinpoCfgs = xinpo_show
    self._xinPo_Star = xinpo_star
end

function UIAircraftResolve:InitWidget()
    --generated--
    ---@type UIDynamicScrollView
    self.scrollView = self:GetUIComponent("UIDynamicScrollView", "ScrollView")
    ---@type UICustomWidgetPool
    self.filter = self:GetUIComponent("UISelectObjectPath", "Filter")
    ---@type UILocalizationText
    self.tip = self:GetUIComponent("UILocalizationText", "tip")
    ---@type UnityEngine.GameObject
    self.juxiang = self:GetGameObject("juxiang")
    ---@type RawImageLoader
    self.juxiang1_icon = self:GetUIComponent("RawImageLoader", "juxiang1_icon")
    ---@type UILocalizationText
    self.juxiang1_name = self:GetUIComponent("UILocalizationText", "juxiang1_name")
    ---@type RawImageLoader
    self.juxiang2_icon = self:GetUIComponent("RawImageLoader", "juxiang2_icon")
    ---@type UILocalizationText
    self.juxiang2_name = self:GetUIComponent("UILocalizationText", "juxiang2_name")
    ---@type UILocalizationText
    self.juxiang2_count = self:GetUIComponent("UILocalizationText", "juxiang2_count")
    ---@type UILocalizationText
    self.count = self:GetUIComponent("UILocalizationText", "count")
    ---@type UICustomWidgetPool
    self.xinpo = self:GetUIComponent("UISelectObjectPath", "xinpo")
    ---@type UIEventTriggerListener
    self.addButton = self:GetUIComponent("UIEventTriggerListener", "AddButton")
    ---@type UIEventTriggerListener
    self.removeButton = self:GetUIComponent("UIEventTriggerListener", "RemoveButton")
    ---@type UnityEngine.UI.Button
    self.juXiangBtn = self:GetUIComponent("Button", "JuXiangBtn")
    ---@type UnityEngine.UI.Button
    self.xinPoBtn = self:GetUIComponent("Button", "XinPoBtn")
    --generated end--

    self.xinPoGo = self:GetGameObject("xinpo")

    ---@type RollingText
    self.tip1 = self:GetUIComponent("RollingText", "tip1")

    self.juxiang1_color = self:GetUIComponent("Image", "juxiang1_color")
    self.juxiang2_color = self:GetUIComponent("Image", "juxiang2_color")
    self._itemAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end

--为按钮添加事件
function UIAircraftResolve:AddButtonEvent ()
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.addButton.gameObject),
        UIEvent.Click,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._timerEvent = nil
            end
            if self._longTrigger then
                return
            end
            self:OnJuxiangAdd()
        end
    )

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.addButton.gameObject),
        UIEvent.Press,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._timerEvent = nil
            end
            self:LongEvent(true)
        end
    )

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.addButton.gameObject),
        UIEvent.Release,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._pressTime = nil
                self._longTrigger = false
                self._timerEvent = nil
            end
        end
    )

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.removeButton.gameObject),
        UIEvent.Press,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._timerEvent = nil
            end
            self:LongEvent(false)
        end
    )

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.removeButton.gameObject),
        UIEvent.Release,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._pressTime = nil
                self._longTrigger = false
                self._timerEvent = nil
            end
        end
    )

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(self.removeButton.gameObject),
        UIEvent.Click,
        function(go)
            if self._timerEvent then
                GameGlobal.Timer():CancelEvent(self._timerEvent)
                self._timerEvent = nil
            end
            if self._longTrigger then
                return
            end
            self:OnJuxiangRemove()
        end
    )
end

function UIAircraftResolve:LongEvent(isAdd)
    if self._pressTime then
        local changeNum = nil
        for i, v in pairs(self._JXPressCfg.Value) do
            local tempLimitTime = v[1] * 1000
            if self._pressTime <= tempLimitTime then
                changeNum = v[2]
                break
            end
        end
        if not changeNum then
            changeNum = self._JXPressCfg.Value[#self._JXPressCfg.Value][2]
        end

        self._pressTimeGape = 1 / changeNum * 1000 --一秒钟增加changeNum个材料
        self._pressTime = self._pressTime + self._pressTimeGape
    else
        local time = self._JXPressCfg.Value[1][1]
        local num = self._JXPressCfg.Value[1][2]
        self._pressTimeGape = time / num * 1000
        self._pressTime = self._pressTimeGape
    end

    --计算数量
    -- local changeNum = 1
    -- for i, v in pairs(self._JXPressCfg.Value) do
    --     local tempLimitTime = v[1] * 1000
    --     if self._pressTime <= tempLimitTime then
    --         changeNum = v[2]
    --         break
    --     end
    -- end
    -- if not changeNum then
    --     changeNum = self._JXPressCfg.Value[#self._JXPressCfg.Value][2]
    -- end

    if isAdd then
        local select = self._selections[1]
        local cfg = self._juxiangCfgs[select]
        local from = cfg.Input[1][1]
        local fromCfg = Cfg.cfg_item[from]
        local maxNum = self._itemModule:GetItemCount(fromCfg.ID)

        if maxNum > self._juxiangCount then
            self._timerEvent = GameGlobal.Timer():AddEvent(
                self._pressTimeGape,
                function()
                    self._longTrigger = true
                    local tempNum = self._juxiangCount + 1--changeNum
                    if tempNum > maxNum then
                        self._juxiangCount = maxNum
                    else
                        self._juxiangCount = tempNum
                    end
                    self:RefreshExchangeInfo()
                    self:LongEvent(isAdd)
                end)
        end
    else
        if self._juxiangCount > 0 then
            self._timerEvent = GameGlobal.Timer():AddEvent(
                self._pressTimeGape,
                function()
                    self._longTrigger = true
                    local tempNum = self._juxiangCount - 1--changeNum
                    if tempNum >= 0 then
                        self._juxiangCount = tempNum
                    else
                        self._juxiangCount = 0
                    end
                    self:RefreshExchangeInfo()
                    self:LongEvent(isAdd)
                end)
        end
    end
end

function UIAircraftResolve:_newRawItem(scrollView, index)
    if index < 0 then
        return
    end

    index = index + 1
    local rowItem = scrollView:NewListViewItem("item")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", rowItem.gameObject)
    if rowItem.IsInitHandlerCalled == false then
        rowItem.IsInitHandlerCalled = true
        rowPool:SpawnObject("UIResolveItemRaw")
    end
    ---@type UIResolveItemRaw
    local item = rowPool:GetAllSpawnList()[1]
    if self._tab2 == ResolveTab2.JuXiang then
        item:SetData(
            ResolveTab2.JuXiang,
            self._juxiangCfgs,
            index,
            self._onClickItem,
            self._onLongPressItem,
            self._selections
        )
    elseif self._tab2 == ResolveTab2.XinPo then
        item:SetData(
            ResolveTab2.XinPo,
            self._xinpoCfgs,
            index,
            self._onClickItem,
            self._onLongPressItem,
            self._selections
        )
    end
    return rowItem
end
function UIAircraftResolve:OnTab2Changed(tab2)
    if self._tab2 == tab2 then
        return
    end
    self._tab2 = tab2

    if tab2 == ResolveTab2.JuXiang then
        self.tip:SetText(StringTable.Get("str_aircraft_resolve_tip1"))
        self.tip1:RefreshText(StringTable.Get("str_aircraft_smelt_juxiang_tip"))
        self._xinpoFilter:Active(false)
        self._juxiangCount = 0
        self:RefreshItems(#self._juxiangCfgs)
    elseif tab2 == ResolveTab2.XinPo then
        self.tip:SetText(StringTable.Get("str_aircraft_resolve_tip2"))
        self.tip1:RefreshText(StringTable.Get("str_aircraft_smelt_xinpo_tip"))

        self._xinpoFilter:Active(true)
        self:RefreshItems(#self._xinpoCfgs)
    else
    end
    self.juXiangBtn.interactable = tab2 ~= ResolveTab2.JuXiang
    self.xinPoBtn.interactable = tab2 ~= ResolveTab2.XinPo

    local selecetIdx = self._selections[1]
    self._selections = {}
    if self._tab2 == ResolveTab2.JuXiang then
        --巨像材料默认选中当前选中的，若没有则选中第一个
        if next(self._juxiangCfgs) then
            --用juxiang是否激活判断上个页面是不是巨像页面
            if not self.juxiang.activeSelf then
                self:OnClickItem(1)
            else
                if selecetIdx then
                    selecetIdx = (selecetIdx > 3) and 1 or selecetIdx
                    self:OnClickItem(selecetIdx)
                else
                    self:OnClickItem(1)
                end
            end
        else
            self:OnClickItem(1)
        end
    elseif self._tab2 == ResolveTab2.XinPo then
        --心珀材料默认不选中
        self:OnClickItem(nil)
    end
    -- self.xinPoGo:SetActive(tab2 == ResolveTab2.XinPo)
    self.juxiang:SetActive(tab2 == ResolveTab2.JuXiang)
end

function UIAircraftResolve:RefreshItems(count)
    count = math.ceil(count / 3)
    self.scrollView:SetListItemCount(count)
    self.scrollView:MovePanelToItemIndex(0, 0)
end

function UIAircraftResolve:OnXinpoFilterChanged(type, isOn)
    if self._tab2 ~= ResolveTab2.XinPo then
        return
    end

    if type == XinPoFilter.All then
        if isOn then
            self._selections = {}
            for _, idx in ipairs(self._xinPo_Star[XinPoFilter.All]) do
                table.insert(self._selections, idx)
            end
        else
            self._selections = {}
        end
    else
        for _, idx in ipairs(self._xinPo_Star[type]) do
            if table.icontains(self._selections, idx) then
                if not isOn then
                    table.removev(self._selections, idx)
                end
            else
                if isOn then
                    table.insert(self._selections, idx)
                end
            end
        end
    end

    self:RefreshExchangeInfo()
    GameGlobal:EventDispatcher():Dispatch(GameEventType.UIAircraftResolveItemOnclick, self._tab2, self._selections)
end

function UIAircraftResolve:OnJuxiangAdd()
    if self._tab2 == ResolveTab2.JuXiang then
        local select = self._selections[1]
        local cfg = self._juxiangCfgs[select]
        local input = cfg.Input[1][1]
        local own = self._itemModule:GetItemCount(input)
        if self._juxiangCount + 1 > own then
            return
        end
        self._juxiangCount = self._juxiangCount + 1
        self:RefreshExchangeInfo()
    end
end

function UIAircraftResolve:OnJuxiangRemove()
    if self._tab2 == ResolveTab2.JuXiang then
        if self._juxiangCount <= 0 then
            return
        end

        self._juxiangCount = self._juxiangCount - 1
        self:RefreshExchangeInfo()
    end
end

function UIAircraftResolve:OnClickItem(idx)
    if self._tab2 == ResolveTab2.JuXiang then
        if idx == nil then
            self._selections = {}
        else
            if table.icontains(self._selections, idx) then
                self._selections = {}
            else
                -- local input = self._juxiangCfgs[idx].Input[1][1]
                -- local own = self._itemModule:GetItemCount(input)
                -- if own > 0 then
                --     self._juxiangCount = 1
                -- else
                --     self._juxiangCount = 0
                -- end
                self._selections = {idx}
                self._juxiangCount = 0
            end
        end
    elseif self._tab2 == ResolveTab2.XinPo then
        if idx == nil then
            self._selections = {}
            self._xinpoFilter:Refresh(false, false, false)
        else
            if table.icontains(self._selections, idx) then
                table.removev(self._selections, idx)
            else
                table.insert(self._selections, idx)
            end

            local star4, star5, star6 = true, true, true
            if next(self._xinPo_Star[XinPoFilter.Star4]) then
                for _, idx in ipairs(self._xinPo_Star[XinPoFilter.Star4]) do
                    if not table.icontains(self._selections, idx) then
                        star4 = false
                        break
                    end
                end
            else
                star4 = false
            end

            if next(self._xinPo_Star[XinPoFilter.Star5]) then
                for _, idx in ipairs(self._xinPo_Star[XinPoFilter.Star5]) do
                    if not table.icontains(self._selections, idx) then
                        star5 = false
                        break
                    end
                end
            else
                star5 = false
            end
            if next(self._xinPo_Star[XinPoFilter.Star6]) then
                for _, idx in ipairs(self._xinPo_Star[XinPoFilter.Star6]) do
                    if not table.icontains(self._selections, idx) then
                        star6 = false
                        break
                    end
                end
            else
                star6 = false
            end

            self._xinpoFilter:Refresh(star4, star5, star6)
        end
    end
    self:RefreshExchangeInfo()
    GameGlobal:EventDispatcher():Dispatch(GameEventType.UIAircraftResolveItemOnclick, self._tab2, self._selections)
end

function UIAircraftResolve:SetData(tab1, onShowItemTip)
    self._tab1 = tab1
    self._onShowItemTip = onShowItemTip

    if tab1 == ResolveTab1.JuXiang then
        self:OnTab2Changed(ResolveTab2.JuXiang)
    elseif tab1 == ResolveTab1.XinPo then
        self:OnTab2Changed(ResolveTab2.XinPo)
    end
end

function UIAircraftResolve:SetShow(show)
    self:GetGameObject():SetActive(show)
    if not show then
        self._selections = {}
        self._tab1 = nil
        self._tab2 = nil
    end
end

function UIAircraftResolve:JumpTo(jumpID)
    local targetCfg = Cfg.cfg_item_smelt[jumpID]
    if targetCfg.Tab == ResolveTab2.JuXiang or targetCfg.Tab == ResolveTab2.XinPo then
        self:OnTab2Changed(targetCfg.Tab)
    else
        AirError("分解跳转二级页签错误:", targetCfg.Tab)
    end
end

--刷新右侧兑换信息
function UIAircraftResolve:RefreshExchangeInfo()
    if self._tab2 == ResolveTab2.JuXiang then
        local select = self._selections[1]
        if select then
            local cfg = self._juxiangCfgs[select]
            local from = cfg.Input[1][1]
            local fromStep = cfg.Input[1][2]
            local to = cfg.Output[1]
            local toStep = cfg.Output[2]
            local fromCfg = Cfg.cfg_item[from]
            local toCfg = Cfg.cfg_item[to]

            self.juxiang1_name:SetText(StringTable.Get(fromCfg.Name))
            self.juxiang1_icon:LoadImage(fromCfg.Icon)
            self.juxiang1_color.sprite = self._itemAtlas:GetSprite(UIEnum.ItemColorFrame(fromCfg.Color))
            self.count:SetText(self._juxiangCount * fromStep)
            self.juxiang2_icon:LoadImage(toCfg.Icon)
            self.juxiang2_name:SetText(StringTable.Get(toCfg.Name))
            self.juxiang2_count:SetText(self._juxiangCount * toStep)
            self.juxiang2_color.sprite = self._itemAtlas:GetSprite(UIEnum.ItemColorFrame(toCfg.Color))
            self.juxiang:SetActive(true)
        else
            self.juxiang:SetActive(false)
        end
        self.xinPoGo:SetActive(false)
    elseif self._tab2 == ResolveTab2.XinPo then
        local outPuts = {}
        for _, select in ipairs(self._selections) do
            local cfg = self._xinpoCfgs[select]
            local from = cfg.Input[1][1]
            if cfg.Input[1][2] ~= 1 then
                AirError("心珀材料的输入数量必须是1:", cfg.ID)
            end
            local count = self._itemModule:GetItemCount(from)

            local toID = cfg.Output[1]
            --策划口头保证，心珀材料的兑换比例一定是1:n，这里处理时直接乘数量 2021.7.5 靳策
            local toCount = cfg.Output[2] * count
            if not outPuts[toID] then
                outPuts[toID] = 0
            end
            outPuts[toID] = outPuts[toID] + toCount
        end

        local outPutCount = table.count(outPuts)
        if outPutCount > 0 then
            self.xinPoGo:SetActive(true)
            self.xinpo:SpawnObjects("UIItem", outPutCount)
            ---@type table<number,UIItem>
            local outPutItems = self.xinpo:GetAllSpawnList()

            local idx = 1
            for key, count in pairs(outPuts) do
                local item = outPutItems[idx]
                item:SetForm(UIItemForm.Base, 1)
                local cfg = Cfg.cfg_item[key]
                item:SetData(
                    {
                        icon = cfg.Icon,
                        quality = cfg.Color,
                        text1 = count,
                        text2 = StringTable.Get(cfg.Name),
                        itemId = key
                    }
                )

                item:SetClickCallBack(
                    function(go)
                        self:ShowItemTips(key, go.transform.position)
                    end
                )

                idx = idx + 1
            end
        else
            self.xinPoGo:SetActive(false)
        end
    else
    end
end

function UIAircraftResolve:JuXiangBtnOnClick(go)
    self:OnTab2Changed(ResolveTab2.JuXiang)
end
function UIAircraftResolve:XinPoBtnOnClick(go)
    self:OnTab2Changed(ResolveTab2.XinPo)
end
function UIAircraftResolve:SmeltButtonOnClick(go)
    if not next(self._selections) then
        return
    end

    local result = self:CheckResolve()
    if result > 0 then
        --分解后萤火超上限
        if result & AirItemErrorCode.FireflyOverflow > 0 then
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.OkCancel,
                "",
                StringTable.Get("str_aircraft_firefly_overflow"),
                function(param)
                    AirLog("萤火超上限，继续分解")
                    self:StartTask(self.Resolve, self)
                end,
                nil,
                function(param)
                    AirLog("取消分解材料")
                end,
                nil
            )
        else
            AirLog("分解材料错误:", result)
        end
        return
    end

    self:StartTask(self.Resolve, self)
end

function UIAircraftResolve:juxiang1_iconOnClick(go)
    if self._tab2 == ResolveTab2.JuXiang then
        if self._selections[1] then
            local id = self._juxiangCfgs[self._selections[1]].Input[1][1]
            self:ShowItemTips(id, go.transform.position)
        end
    end
end

function UIAircraftResolve:juxiang2_iconOnClick(go)
    if self._tab2 == ResolveTab2.JuXiang then
        if self._selections[1] then
            local id = self._juxiangCfgs[self._selections[1]].Output[1]
            self:ShowItemTips(id, go.transform.position)
        end
    end
end

function UIAircraftResolve:Resolve(TT)
    self:Lock(self:GetName())
    ---@type AsyncRequestRes
    local res, reply, assets
    if self._tab2 == ResolveTab2.JuXiang then
        local id = self._juxiangCfgs[self._selections[1]].ID
        res, reply = self._airModule:HandleItemSmelt(TT, id, self._juxiangCount)
        local asset = ItemAsset:New()
        asset.assetid = reply.id
        asset.count = reply.num
        assets = {asset}
    elseif self._tab2 == ResolveTab2.XinPo then
        local inputs = {}
        for _, idx in ipairs(self._selections) do
            local asset = RoleAsset:New()
            asset.assetid = self._xinpoCfgs[idx].ID
            local itemID = self._xinpoCfgs[idx].Input[1][1]
            --这里的数量其实应该除以兑换倍率，但是分解材料永远是1:n，所以就用物品数量
            asset.count = self._itemModule:GetItemCount(itemID)
            inputs[#inputs + 1] = asset
        end
        res, reply = self._airModule:HandleMultItemSmelt(TT, inputs)
        local obatins = {}
        --合并重复材料
        for _, obatin in ipairs(reply.item_list) do
            if not obatins[obatin.assetid] then
                obatins[obatin.assetid] = 0
            end
            obatins[obatin.assetid] = obatins[obatin.assetid] + obatin.count
        end
        assets = {}
        for id, count in pairs(obatins) do
            local asset = RoleAsset:New()
            asset.assetid = id
            asset.count = count
            assets[#assets + 1] = asset
        end
    end
    if res:GetSucc() then
        --ui表现
        -- if self._tab2 == ResolveTab2.JuXiang then
        --     local anim = self:GetUIComponent("Animation", "Center")
        --     anim:Play("uieff_AircraftSmelt_Resolve")
        --     YIELD(TT, 1000)
        -- elseif self._tab2 == ResolveTab2.XinPo then
        --     if not self._xinPoEffs then
        --         self._xinPoEffs = {}
        --     end
        --     local xinpoParent = self:GetUIComponent("Transform", "xinpo")
        --     for i = 1, xinpoParent.childCount do
        --         local item = xinpoParent:GetChild(i - 1)
        --         if item.gameObject.activeSelf then
        --             if not self._xinPoEffs[i] then
        --                 self._xinPoEffs[i] = self:GetAsset("uieff_Resolve_Fx.prefab", LoadType.GameObject)
        --                 self._xinPoEffs[i].transform:SetParent(item)
        --                 self._xinPoEffs[i].transform.localPosition = Vector3(0, 0, 0)
        --                 self._xinPoEffs[i].transform.localRotation = Quaternion.identity
        --                 self._xinPoEffs[i].transform.localScale = Vector3(1, 1, 1)
        --             end
        --             self._xinPoEffs[i]:SetActive(true)
        --         end
        --     end
        --     YIELD(TT, 1000)
        -- end

        self:ShowDialog("UIGetItemController", assets)
        --如果获得了萤盏，需要刷新风船ui，因为萤盏影响房间的解锁状态
        for _, value in ipairs(assets) do
            if value.assetid == RoleAssetID.RoleAssetFirefly then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRefreshMainUI)
                break
            end
        end
        self:RefreshAfterSmelt()
    else
        ToastManager.ShowToast(self._airModule:GetErrorMsg(res:GetResult()))
    end
    self:UnLock(self:GetName())
end

function UIAircraftResolve:CheckResolve()
    local result = AirItemErrorCode.None

    if self._tab2 == ResolveTab2.JuXiang then
        if self._juxiangCount == 0 then
            result = result | AirItemErrorCode.Zero
        end

        local cfg = self._juxiangCfgs[self._selections[1]]
        for idx, item in ipairs(cfg.Input) do
            local id = item[1]
            local need = item[2]
            if self._roleModule:GetAssetCount(id) < need * self._juxiangCount then
                result = result | AirItemErrorCode.NotEnough
            end
        end

        if cfg.Output[1] == RoleAssetID.RoleAssetFirefly then
            local _count = cfg.Output[2]
            if self._airModule:GetFirefly() + _count * self._juxiangCount > self._airModule:GetMaxFirefly() then
                result = result | AirItemErrorCode.FireflyOverflow
            end
        end
    elseif self._tab2 == ResolveTab2.XinPo then
    end

    return result
end

function UIAircraftResolve:RefreshAfterSmelt()
    self:RefreshData()
    local cur = self._tab2
    self._tab2 = nil
    self:OnTab2Changed(cur)
end

function UIAircraftResolve:ShowItemTips(id, pos)
    self._onShowItemTip(id, pos)
end

--------------------------------------------------------------
--巨像材料和心珀材料的二级页签ID分别是402和502,不允许策划改动
---@class ResolveTab2
local ResolveTab2 = {
    JuXiang = 402,
    XinPo = 502
}
_enum("ResolveTab2", ResolveTab2)
--------------------------------------------------------------
--熔炼一级页签，对应cfg_aircraft_smelt_tab1的ID
---@class ResolveTab1
local ResolveTab1 = {
    HeCheng = 1, --合成
    XinPo = 2, --心珀
    JuXiang = 3 --巨像
}
_enum("ResolveTab1", ResolveTab1)
--------------------------------------------------------------
--熔炼UI样式类型，对应cfg_aircraft_smelt_tab1.UIType
---@class SmeltRoomUIType
local SmeltRoomUIType = {
    Compond = 1, --合成
    Resolve = 2, --分解
    Camp = 3 --势力
}
_enum("SmeltRoomUIType", SmeltRoomUIType)
