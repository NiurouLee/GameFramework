--
---@class UIN26CookMakeController : UIController
_class("UIN26CookMakeController", UIController)
UIN26CookMakeController = UIN26CookMakeController

---@param res AsyncRequestRes
function UIN26CookMakeController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
    self._cookData = UIN26CookData.New()
    self._cookData:LoadData(TT,res)
    local state = self._cookData:GetCookState()
    if state == UISummerOneEnterBtnState.NotOpen then
        return
    elseif state == UISummerOneEnterBtnState.Closed then
        return
    end
end
--初始化
function UIN26CookMakeController:OnShow(uiParams)
    self:InitWidget()
    self._dataId = uiParams[1]
    self:InitData()
    self:InitTips()
    self._spine:LoadSpine("n26_g_spine_idle")
    self._spine:SetAnimation(0, "idle", true)
    -- self:InitHead()
    self:Refresh(true)
    self:RefreshTips()
    self._eventMakeSucc = GameHelper:GetInstance():CreateCallback(self.OnMakeSucc, self)
    GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.OnN26CookMakeSucc, self._eventMakeSucc)
    self:CheckPreStory()
    self:PlayEnterAni()
    self._spine.AnimationState.Data.DefaultMix = 0
end

function UIN26CookMakeController:OnHide()
    if self._eventMakeSucc then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.OnN26CookMakeSucc, self._eventMakeSucc)
        self._eventMakeSucc = nil
    end
    self._isHide = true
end

function UIN26CookMakeController:PlayEnterAni()
    self:StartTask(function (TT)
        local lockName = "UIN26CookMainController:PlayEnterAni"
        self:Lock(lockName)
        local delay = 20
        for i, v in ipairs(self.matItems) do
            YIELD(TT,delay)
            v:PlayEnterAni()
            delay = delay + 20
        end
        self:UnLock(lockName)
    end)
end

function UIN26CookMakeController:OnMakeSucc()
    self:CloseDialog()
end

--获取ui组件
function UIN26CookMakeController:InitWidget()
    ---@type UICustomWidgetPool
    self.list = self:GetUIComponent("UISelectObjectPath", "list")
    ---@type UICustomWidgetPool
    self.detail = self:GetUIComponent("UISelectObjectPath", "detail")
    ---@type UnityEngine.GameObject
    self.left = self:GetGameObject("left")
    ---@type UnityEngine.GameObject
    self.right = self:GetGameObject("right")
    self.listGo = self:GetGameObject("list")
    self.txtMatHave = self:GetUIComponent("UILocalizationText", "txtMatHave")
    self.txtMatUse = self:GetUIComponent("UILocalizationText", "txtMatUse")
    self.head = self:GetUIComponent("RawImageLoader", "head")
    self.frame = self:GetUIComponent("RawImageLoader", "frame")
    self._headBgIcon = self:GetUIComponent("UICircleMaskLoader", "headBg")

    self.leftBtn = self:GetGameObject("LeftBtn")
    self.rightBtn = self:GetGameObject("RightBtn")
    self.pointPool = self:GetUIComponent("UISelectObjectPath", "pointPool")
    self.tips = self:GetUIComponent("UILocalizationText", "tips")
    self.name1 = self:GetUIComponent("UILocalizationText", "name1")
    self.cookPos = self:GetUIComponent("RectTransform", "cookPos")
    self.switchAni = self:GetUIComponent("Animation","switchAni")
    self.rightBtnAni = self:GetUIComponent("Animation","rightBtnAni")
    self.leftBtnAni = self:GetUIComponent("Animation","leftBtnAni")

    ---@type SpineLoader
    self._spine = self:GetUIComponent("SpineLoader", "Spine")

    local btns = self:GetUIComponent("UISelectObjectPath", "topBtn")
    ---@type UICommonTopButton
    local backBtn = btns:SpawnObject("UICommonTopButton")
    backBtn:SetData(
        function()
            self:CloseDialog()
            --self:SwitchState(UIStateType.UIN26CookBookController)
        end,
        nil,
        nil
    )
end

-- function UIN26CookMakeController:InitHead()
--     --head and frame
--    self._roleModule = self:GetModule(RoleModule)
--    self._roleHeadFrameID = self._roleModule:GetHeadFrameID()
--    local headId = self._roleModule.m_char_info.m_nHeadImageID
--    local cfg_head_frame = Cfg.cfg_role_head_frame[self._roleHeadFrameID]
--    if cfg_head_frame then
--        self.frame:LoadImage(cfg_head_frame.Icon)
--    end
   
--    local cfg_head = Cfg.cfg_role_head_image[headId]
--    if cfg_head then
--        self.head:LoadImage(cfg_head.Icon)
--    end

--    local headbgid = self._roleModule.m_char_info.m_nHeadColorID
--     local cfg_head_bg = Cfg.cfg_player_head_bg[headbgid]
--     if cfg_head_bg then
--         self._headBgIcon:LoadImage(cfg_head_bg.Icon)
--    end
-- end

function UIN26CookMakeController:InitData()
    self._foodCfg = Cfg.cfg_component_newyear_dinner_food[self._dataId]
    if not self._foodCfg then
        Log.error("UIN26CookMakeController error , cfg_component_newyear_dinner_food can not find id : " .. self._dataId)
        return
    end
    local recipeCfg = self._foodCfg.Recipe
    self._foodId = self._foodCfg.FoodID
    self._matNumLimit = 0
    self._recipeData = {}
    for i, v in ipairs(recipeCfg) do
        local recipe = {}
        recipe.num = 0
        recipe.bestNum = v[2]
        recipe.id = v[1]

        self._matNumLimit = self._matNumLimit + recipe.bestNum
        self._recipeData[i] = recipe
    end

    local itemModule = GameGlobal.GetModule(ItemModule)
    local itemid = self._cookData:GetCostId()
    --通用材料数量
    self._itemCount  = itemModule:GetItemCount(itemid)
    
    self._AllTip = self._foodCfg.Tip

    self.name1:SetText(StringTable.Get(self._foodCfg.Name))
    self.head:LoadImage(self._foodCfg.PetIcon)

    --init storyID
    local storys = self._foodCfg.StoryId
    for k, v in pairs(storys) do
        local storyType = v[1]
        if storyType == 1 then
            self.preStoryId = v[2]
        elseif storyType ==2 then
            self.afterStoryId = v[2]
        end
    end
end

function UIN26CookMakeController:Refresh(hide)
    self.txtMatHave:SetText(StringTable.Get("str_n26_cook_has_mat",self._itemCount))
    self:RefreshUseNum()
    local len = #self._recipeData
    local items = self.list:SpawnObjects("UIN26CookMatSelectItem", 4)
    self.matItems = items
    for i, v in ipairs(items) do
        if hide then
            v:SetVisible(false)
        end
        if i <= len then
            local subData = self._recipeData[i]
            v:SetData(subData, self._matNumLimit,
            function ()
                return self:GetSelectedMatCount()
            end, 
            function ()
                return self:GetRemianMatCount()
            end,
            function (selNum)
                subData.num = selNum
                self:RefreshUseNum() 
            end)
            
        else
            v:SetAsEmpty()
        end
        
    end
end

function UIN26CookMakeController:RefreshUseNum()
    local str = "<color=#fdd53e>"..self:GetSelectedMatCount().."</color>"
    self.txtMatUse:SetText(StringTable.Get("str_n26_cook_use_mat",str,self._matNumLimit))
end

function UIN26CookMakeController:CheckPreStory()
    if not self.preStoryId then
        return
    end

    local key = "N26CookPreStory_"..self._foodId
    if UIN26CookData.HasKey(key) then
        return
    end
    UIN26CookData.SetKey(key)
    self:ShowDialog("UIStoryController", self.preStoryId)
end


--选择的材料数量 
function UIN26CookMakeController:GetSelectedMatCount()
    local num = 0
    for i, v in ipairs(self._recipeData) do
        num = num + v.num
    end
    return num
end

--剩余的材料数量
function UIN26CookMakeController:GetRemianMatCount()
    return self._itemCount - self:GetSelectedMatCount()
end


function UIN26CookMakeController:LeftBtnOnClick()
    if self.curTipsIndex > 1 then
        self.curTipsIndex = self.curTipsIndex - 1
        self:RefreshTips()
        self.leftBtnAni:Play()
        self.switchAni:Play("uieff_N26_CookMakeController_left_L")
    end
end

function UIN26CookMakeController:RightBtnOnClick()
    if self.curTipsIndex < self.tipsCount then
        self.curTipsIndex = self.curTipsIndex + 1
        self:RefreshTips()
        self.rightBtnAni:Play()
        self.switchAni:Play("uieff_N26_CookMakeController_left_R")
    end
end

function UIN26CookMakeController:InitTips()
    local len = #self._AllTip;
    local isChg = false
    if not self.tipsContent or len ~= #self.tipsContent then
        self.tipsContent = {}
        local wrongTimes = self._cookData:GetWrongTimes(self._dataId)
        for k, v in pairs(self._AllTip) do
            local t = tonumber(v[1])
            if wrongTimes >= t then
                table.insert(self.tipsContent, v[2])
            end
        end
        isChg = true
    end
    self.tipsCount = #self.tipsContent
    self.curTipsIndex = 1

    local pointCount = 0
    if self.tipsCount > 1 then
        pointCount = self.tipsCount        
    end

    self.allPointCont = self.allPointCont or 0

    if self.allPointCont ~= pointCount  then
        self.allPointCont = pointCount
        self.allPointItem = self.pointPool:SpawnObjects("UIN26CookPoint", pointCount)
    end

    return isChg
end

function UIN26CookMakeController:RefreshTips()
    if self.tipsContent then
        local tipsStr = self.tipsContent[self.curTipsIndex]
        self.tips:SetText(StringTable.Get(tipsStr))
    end
    self.leftBtn:SetActive(self.curTipsIndex > 1)
    self.rightBtn:SetActive(self.curTipsIndex < self.tipsCount)
    if self.allPointCont > 1 then
        for i, v in ipairs(self.allPointItem) do
            v:SetSelect(self.curTipsIndex == i)
        end
    end
end

function UIN26CookMakeController:MakeBtnOnClick()
    if  self._matNumLimit  ~= self:GetSelectedMatCount() then
        ToastManager.ShowToast(StringTable.Get("str_n26_cook_make_mat_err"))
        return
    end

    local err
    local diff = 0
    local errRecipeId = 0
    for i, v in ipairs(self._recipeData) do
        if v.num ~= v.bestNum then
            local d = v.num - v.bestNum
            if d > diff then
                diff = d
                errRecipeId = v.id
            end
           err  = true
        end
    end

    self:StartTask(
        function(TT)
            --fly obj
            if self.matItems then
                local pos = self.cookPos.position
                for i, v in ipairs(self.matItems) do
                    local num = v:GetMatCount()
                    local template = v:GetIconTrans()
                    for k = 1, num, 1 do
                        self:CopyObjAndFly(template, pos, 0.4, 0.8)
                    end
                end
            end
            self.left:SetActive(false)
            self.right:SetActive(false)
            YIELD(TT, 1000)
            if self._isHide then
                return
            end
            self.listGo:SetActive(false)
            self._spine:SetAnimation(0,"splash",false)

            YIELD(TT, 1000)
            if self._isHide then
                return
            end
            self._spine:SetAnimation(0,"close",false)

            YIELD(TT, 1000)
            if self._isHide then
                return
            end
            self._spine:SetAnimation(0,"ripe",false)

            YIELD(TT, 2000)
            if self._isHide then
                return
            end
            self._spine:SetAnimation(0,"open",false)
     
            YIELD(TT, 1000)
            if self._isHide then
                return
            end
        
            if err then
                local t =  self._cookData:GetWrongTimes(self._dataId)
                self._cookData:SetWrongTimes(self._dataId, t + 1)
                if self:InitTips() then
                    self:RefreshTips()
                end
                local name = self._foodCfg.Name
                local tips = ""
                local cfg = Cfg.cfg_dinner_food_material[errRecipeId]
                if cfg then
                    tips = StringTable.Get(cfg.Name)
                else
                    Log.error("UIN26CookMakeController cfg_dinner_food_material can't find id " .. errRecipeId)
                end

                local petIcon = self._foodCfg.PetIcon
                self:ShowDialog("UIN26CookMakeFailedController",name, tips, petIcon)
                self.left:SetActive(true)
                self.right:SetActive(true)
                self.listGo:SetActive(true)
                self._spine:SetAnimation(0,"idle",true)
            return
            end

             --request
            local lockName = "UIN26CookMakeController_RequestMakeFood"
            self:Lock(lockName)
            local res = self._cookData:RequestMakeFood(TT, self._foodId)
            if res and res:GetSucc()  then
                local res = AsyncRequestRes:New()
                res:SetSucc(true)
                self._cookData:LoadData(TT,res)
                self:Refresh()
                self:ShowDialog("UIN26CookMakeSuccController", self._dataId, self.afterStoryId)
            end
            self:UnLock(lockName)
        end,
        self
    )
end

function UIN26CookMakeController:CopyObjAndFly(templateTrasnsform, pos, startDuration, duration)
    local obj = UnityEngine.Object.Instantiate(templateTrasnsform, templateTrasnsform.parent)
    local startPos = obj.position
    startPos.x = startPos.x + math.random() * 0.5
    startPos.y = startPos.y + math.random() * 0.5

    obj:DOMove(startPos, startDuration):OnComplete(
        function()
            obj:DOMove(pos, duration):OnComplete(
                function()
                    UnityEngine.Object.DestroyImmediate(obj.gameObject)
                end
            )
        end
    )
end