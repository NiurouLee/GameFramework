---@class UIDrawCardConfirmController : UIController
_class("UIDrawCardConfirmController", UIController)
UIDrawCardConfirmController = UIDrawCardConfirmController
function UIDrawCardConfirmController:OnShow(uiParams)
    self:InitWidget()
    self.itemId = uiParams[1]
    self.itemCount = uiParams[2]
    self.poolId = uiParams[3]
    self.drawType = uiParams[4]
    self.free = uiParams[5] or false
    self.isSingleFree = uiParams[6] or false

    local cfg = Cfg.cfg_item[self.itemId]
    local ss
    if self.free then
        if self.isSingleFree then
            ss = StringTable.Get("str_draw_card_cost_free")
        else
            ss = StringTable.Get("str_draw_card_cost_freeten")
        end
    else
        ss = StringTable.Get("str_draw_card_cost_to_draw", self.itemCount, StringTable.Get(cfg.Name))
    end
    self.title:SetText(ss)

    self.iconRoot:SetActive(not self.free)
    local otherRootPosX = 0
    --白嫖
    if self.free then
        otherRootPosX = -75
        local freeCount = self.itemCount
        self.itemCount = 0
        --一次抽一次
        local lessCount = freeCount - 1
        self.have:SetText(freeCount)
        self.rest:SetText(lessCount)
    else
        local had = self:GetModule(RoleModule):GetAssetCount(self.itemId)
        local rest = had - self.itemCount
        if had > 99999 then
            had = "99999+"
        end
        if rest > 99999 then
            rest = "99999+"
        end
        self.have:SetText(had)
        self.rest:SetText(rest)
        self.icon:LoadImage(cfg.Icon)
    end
    self.otherRoot.anchoredPosition = Vector2(otherRootPosX, 0)
end
function UIDrawCardConfirmController:InitWidget()
    self.title = self:GetUIComponent("UILocalizationText", "title")
    self.icon = self:GetUIComponent("RawImageLoader", "icon")
    self.have = self:GetUIComponent("UILocalizationText", "have")
    self.rest = self:GetUIComponent("UILocalizationText", "rest")
    self.iconRoot = self:GetGameObject("iconRoot")
    self.otherRoot = self:GetUIComponent("RectTransform", "otherRoot")
end
function UIDrawCardConfirmController:ConfirmButtonOnClick(go)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.WaitForRecuitSceneLoadFinish, function()
        self:Lock(self:GetName())
        self:GetModule(PetModule):GetAllPetsSnapshoot() --抽卡前临时保存所有当前星灵id列表快照
        self:GetModule(GambleModule):Context():SetHaveMaxStarPet(self:GetModule(PetModule):GetMaxStarResult())
        --锁住成就弹窗先
        ---@type UIFunctionLockModule
        local funcModule = self:GetModule(RoleModule).uiModule
        funcModule:LockAchievementFinishPanel(true)
    
        self:StartTask(self.DrawCard, self)
    end)
end

function UIDrawCardConfirmController:DrawCard(TT)
    if self._free then
        Log.debug("###[UIDrawCardConfirmController] costid-->", self.itemId, "|costcount-->", self.itemCount)
    end
    ---@type GambleModule
    local module = self:GetModule(GambleModule)
    local ack, cards, duplicateTags = module:Shake(TT, self.drawType, self.poolId, self.itemId, self.itemCount)
    if ack:GetSucc() then
        self:UnLock(self:GetName())
        if cards == nil or #cards == 0 then
            Log.fatal("[DrawCard] cards result is empty!")
            return
        end

        Log.notice("[DrawCard] draw card success, count: ", #cards)
        local viewData = UIDrawCardViewData:New(cards, duplicateTags, self.drawType, self.poolId)
        module:Context():SetStateDrawCard(true)

        --卡池计数log
        if module:GetShowPoolCountCalc() then
            self:_PoolCountTestLog(viewData)
        end

        --self:SwitchState(UIStateType.UIDrawCardAnim, viewData)
        self:ShowDialog("UIDrawCardAnimController", viewData)
        self:CloseDialog()
    else
        --锁住成就弹窗先
        ---@type UIFunctionLockModule
        local funcModule = self:GetModule(RoleModule).uiModule
        funcModule:LockAchievementFinishPanel(false)

        self:UnLock(self:GetName())
        self:CloseDialog()
        ToastManager.ShowToast(module:GetReasonByErrorCode(ack:GetResult()))
        Log.error("抽卡失败:", ack:GetResult())
    end
    --刷新卡池数据
    local res = AsyncRequestRes:New()
    ---@type GambleModule
    local module = self:GetModule(GambleModule)
    local ack = module:ApplyAllPoolInfo(TT)
    if ack:GetSucc() then
        res:SetSucc(true)
        Log.notice("[DrawCard] get draw card data success, open ui")
    else
        res:SetSucc(false)
        Log.notice("[DrawCard] promotion time up, refresh pools failed")
        ToastManager.ShowToast(module:GetReasonByErrorCode(ack:GetResult()))
    end

    --更新一次光珀商店数据
    local shopModule = self:GetModule(ShopModule)
    shopModule:RequestGlowMarket(TT)
end

function UIDrawCardConfirmController:CancelButtonOnClick(go)
    self:CloseDialog()
end

function UIDrawCardConfirmController:_PoolCountTestLog(viewData)
    if EDITOR then
        Log.debug("###[PoolCountTestLog] EDITOR模式,开始写入log!")

        local path = UnityEngine.Application.dataPath .. "/card_pool_count_calc_log.lua"

        ---@type UIDrawCardViewData
        local data = viewData

        local file = io.open(path, "a")
        io.output(file)

        local poolid = data._poolID
        local module = GameGlobal.GetModule(GambleModule)

        local timeStr = os.date("%Y-%m-%d %H:%M %S", os.time())
        if data._cards and table.count(data._cards) > 0 then
            for i = 1, #data._cards do
                local itemStr = ""
                ---@type RoleAsset
                local item = data._cards[i]
                local itemid = item.assetid
                local itemcount = item.count
                itemStr = itemStr .. tostring(itemid) .. "*" .. tostring(itemcount)
                local writeStr = "日志:卡池ID[" .. poolid .. "],时间[" .. timeStr .. "],获得星灵[" .. itemStr .. "].\n"
                io.write("###[PoolCountTestLog] " .. writeStr)
            end
        end

        io.close(file)

        Log.debug("###[PoolCountTestLog] EDITOR模式,结束写入log!")
    else
        Log.debug("###[PoolCountTestLog] 不是EDITOR模式,写入log失败!")
    end
end
