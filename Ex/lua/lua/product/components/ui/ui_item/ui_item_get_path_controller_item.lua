---@class UIItemGetPathControllerItem : UICustomWidget
_class("UIItemGetPathControllerItem", UICustomWidget)
UIItemGetPathControllerItem = UIItemGetPathControllerItem

function UIItemGetPathControllerItem:OnShow(uiParams)
    self._itemModule = GameGlobal.GetModule(ItemModule)

    self._txtGetWay = self:GetUIComponent("UILocalizationText", "txt_getway")
    self._txtRandom = self:GetUIComponent("UILocalizationText", "txt_random")
    self._txtpar = self:GetUIComponent("RevolvingTextWithDynamicScroll", "txt_getwayobj")

    self._bg1 = self:GetGameObject("bg1")
    self._bg2 = self:GetGameObject("bg2")

    self._index = -1

    self._jumpGo = self:GetGameObject("btn_goto")
    self._jumpImg = self:GetUIComponent("Image","btn_goto")
    self._gotoText = self:GetUIComponent("UILocalizationText","gotoText")
    self._gotoNewText = self:GetUIComponent("UILocalizationText","gotoNewText")
    -- self._closeGo = self:GetGameObject("btn_close")
    self._lockGo = self:GetGameObject("btn_lock")
    
    self._ecBtnTex = self:GetUIComponent("UILocalizationText","btn_ec")
    self._ecBtnTexRect = self:GetUIComponent("RectTransform","btn_ec")

    self._ecBtnGo = self:GetGameObject("Button_ec")
    self._ecImg = self:GetUIComponent("Image","Button_ec")
    self._useBtnGo = self:GetGameObject("Button_use")

    self._maskRect = self:GetUIComponent("RectTransform", "txt_getwayobj")

    self._maskWidth = {[1] = Vector2(768, 64), [2] = Vector2(568, 64), [3] = Vector2(360, 64)}

    self._atlas = self:GetAsset("UIItemMain.spriteatlas", LoadType.SpriteAtlas)
    local sprite1 = self._atlas:GetSprite("items_kuang1_btn")
    local sprite2 = self._atlas:GetSprite("items_kuang2_btn")

    self._getIntro = self:GetGameObject("Button_getIntro")
    self._enough2sprite = {
        [1] = sprite1,
        [2] = sprite2,
    }
end

--{way = v.type, useItemId = _useItemId, desc = tmp_desc, enabled = _enable, jumpId = v.jumpid, randomText = randomText}
---@param itemDataInfo table 物品信息
---@param index number 下标
function UIItemGetPathControllerItem:SetData(itemDataInfo, index, itemid,needNum,needNumRawData)
    self._index = index
    self._itemid = itemid
    self._needNum = needNum
    self._needNumRawData = needNumRawData --可能是nil,未经处理的数据
    self._itemDataInfo = itemDataInfo
    self._jumpId = itemDataInfo.jumpId
    self._useItemId = itemDataInfo.useItemId

    self:SetType(itemDataInfo.way, itemDataInfo.enabled, itemDataInfo.randomText)

    self._txtGetWay:SetText(itemDataInfo.desc)
    self._txtRandom:SetText(itemDataInfo.randomText)

    self._txtpar:OnRefreshRevolving()
end

--获取途径的状态
---@param enable boolean 是否开启
function UIItemGetPathControllerItem:SetType(type, enable, randomTex)
    local maskWidthType = 1

    self._bg1:SetActive(false)
    self._bg2:SetActive(false)
    self._jumpGo:SetActive(false)
    self._lockGo:SetActive(false)
    self._useBtnGo:SetActive(false)
    self._ecBtnGo:SetActive(false)
    self._getIntro:SetActive(false)

    self._type = type
    if type == GetWayItemType.Jump then
        local module = GameGlobal.GetModule(RoleModule)
        local unLock = module:CheckModuleUnlock(GameModuleID.MD_Aircraft)
        if enable and unLock then
            self._jumpGo:SetActive(true)
            self._bg1:SetActive(true)

            -- 熔炼室特殊处理
            if self._itemDataInfo.smeltRoomInfo then
               local sp = "items_kuang1_btn"
               self._jumpImg.sprite = self._atlas:GetSprite(sp)
               if  self._itemDataInfo.smeltRoomInfo and not (self._itemDataInfo.smeltRoomInfo.conform) then
                --str_common_getway_goto
                 self._gotoText:SetText("")
                 self._gotoNewText:SetText(StringTable.Get("str_item_public_goto_aircraft"))
               end 
            end 
        else
            self._lockGo:SetActive(true)
            self._bg2:SetActive(true)
        end
        maskWidthType = 2
    elseif type == GetWayItemType.Text then
        self._bg2:SetActive(true)

        maskWidthType = 1
    elseif type == GetWayItemType.Use then
        self._useBtnGo:SetActive(true)
        self._bg1:SetActive(true)

        maskWidthType = 2
    elseif type == GetWayItemType.EC then
        self._ecBtnGo:SetActive(true)
        self._bg1:SetActive(true)

        --检查数量
        self._useItemEnough = false
        local item_a_count = self._itemDataInfo.useItemCount
        local item_a_id = self._useItemId
        local nowCount = self._itemModule:GetItemCount(item_a_id)
        if nowCount>=item_a_count then
            self._useItemEnough = true
        end
        local tex = ""
        local sprite
        local pos
        local width
        if self._useItemEnough then
            tex = StringTable.Get("str_item_public_use")
            sprite = self._enough2sprite[1]
            pos = -34
            width = 120
        else
            tex = StringTable.Get("str_item_public_get_path_not_enough")
            sprite = self._enough2sprite[2]
            pos = 0
            width = 200
        end
        self._ecBtnTexRect.anchoredPosition = Vector2(pos,0)
        self._ecBtnTexRect.sizeDelta = Vector2(width,56)
        self._ecBtnTex:SetText(tex)
        self._ecImg.sprite = sprite

        maskWidthType = 2
    elseif type == GetWayItemType.GetWayIntroduce then
        self._getIntro:SetActive(true)
        self._bg1:SetActive(true)
        maskWidthType = 2
    end

    if not string.isnullorempty(randomTex) then
        maskWidthType = 3
    end
    self._maskRect.sizeDelta = self._maskWidth[maskWidthType]
end

function UIItemGetPathControllerItem:btngotoOnClick(go)
    local aps = GameGlobal.GetModule(SerialAutoFightModule):GetApsData()
    aps:GotoWithItemGetPath(self._jumpId, self._itemid)

    -- 设置跳转返回数据
    local jumpData = GameGlobal.GetModule(SerialAutoFightModule):GetJumpData()
    jumpData:Track_Jump(self._jumpId)

    ---@type UIJumpModule
    local jumpModule = self:GetModule(QuestModule).uiModule

    local param = self._itemDataInfo.smeltRoomInfo
    
    if param then
        param.NeedNumRawData = self._needNumRawData
    end

    jumpModule:GotoWithItemGetPath(
        self._jumpId,
        self._itemid,
        FromUIType.NormalUI,
        "UIBackPackController",
        UIStateType.UIMain,
        param
    )
end
function UIItemGetPathControllerItem:BtnECOnClick(go)
    if self._type == GetWayItemType.EC then
        local item_b_id = self._itemid
        --默认兑换一个
        local item_b_count = 1
        local item_a_id = self._useItemId
        local item_a_count = self._itemDataInfo.useItemCount
        self:ShowDialog("UIItemExChangeController",item_a_id,item_a_count,item_b_id,item_b_count,self._useItemEnough)
    end
end
function UIItemGetPathControllerItem:BtnuseOnClick(go)
    if self._type == GetWayItemType.Use then
        local itemid = self._useItemId
        --打开自选礼包
        ---@type Item
        local item_data
        local item_datas = self._itemModule:GetItemByTempId(itemid)
        if item_datas and table.count(item_datas) > 0 then
            for key, value in pairs(item_datas) do
                item_data = value
                break
            end
        end
        local cfgItemGift = Cfg.cfg_item_gift[item_data:GetTemplateID()]
        if cfgItemGift and cfgItemGift.SpecialOpenType ~= nil then
            self:ShowDialog(
                "UIBackPackUseBox",
                item_data,
                {self._itemid,self._needNum}
            )
        else
            if item_data:GetCount() == 1 then
                self:ShowDialog("UIBackPackBox", item_data, 1)
            else
                self:ShowDialog(
                    "UIItemSaleAndUseWithCountController",
                    item_data,
                    EnumItemSaleAndUseState.Use,
                    function(item_data, count)
                        self:ShowDialog("UIBackPackBox", item_data, count)
                    end
                )
            end
        end 
    end
end

function UIItemGetPathControllerItem:BtnGetIntroOnClick(go)
    GameGlobal.UIStateManager():ShowDialog("UIDrawCardAwardConversionForOtherController")
end

function UIItemGetPathControllerItem:btncloseOnClick(go)
    --ToastManager.ShowToast(StringTable.Get("str_common_getway_no_open"))
end

function UIItemGetPathControllerItem:btnlockOnClick(go)
end

---@return number
function UIItemGetPathControllerItem:GetIndex()
    return self._index
end
