--
---@class UISeasonCgDetailController : UIController
_class("UISeasonCgDetailController", UIController)
UISeasonCgDetailController = UISeasonCgDetailController

---@param res AsyncRequestRes
function UISeasonCgDetailController:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonCgDetailController:OnShow(uiParams)
    self:InitWidget()
    local cfg = uiParams[1]
    ---@type StoryComponent
    self._cpt = uiParams[2] --剧情组件 用于领分享奖励
    self._cfg = cfg
    if cfg then
        if cfg.Spine then
            self._staticPicGO:SetActive(false)
            self._spine1Go:SetActive(true)
            self._spine1Go.transform.localScale = Vector3(cfg.SpineScale, cfg.SpineScale, cfg.SpineScale)
            local spineName1 = cfg.Spine[1]
            self._spine1:LoadSpine(spineName1)

            local spineName2 = cfg.Spine[2]
            if spineName2 then
                self._spine2Go:SetActive(true)
                self._spine2:LoadSpine(spineName2)
                self._spine2Go.transform.localScale = Vector3(cfg.SpineScale, cfg.SpineScale, cfg.SpineScale)
            end
            --MSG59309	【Tapd_109208794】【必现】（测试_冯晓伟）档案顶部底部刚进去上下不是黑底，切到其他的再切回来才变成黑底 分辨率：2732*2048（视频）	4	新缺陷	靳策, jince	03/16/2023	
            self:_SetPicFullScreen(self._staticPicRect)
        else
            -- local scale = ResolutionManager.RealHeight() / 946
            -- self._staticPicGO.transform.localScale = Vector3(scale, scale, 1)
            self._spine1Go:SetActive(false)
            self._spine2Go:SetActive(false)
            self._staticPicGO:SetActive(true)
            self._staticPic:LoadImage(cfg.StaticPic)
            self:_SetPicFullScreen(self._staticPicRect)
        end
        self.txtTitle:SetText(StringTable.Get(cfg.name))
        self.txtDesc:SetText(StringTable.Get(cfg.info))
    end
    self.onlyShowCg = false

    local count = 0
    if self:GetModule(ShareModule):CanShare() and cfg.SeasonShareStoryID then
        if not self._cpt:IsStoryReceived(cfg.SeasonShareStoryID) then
            local storyCfg = Cfg.cfg_campaign_story[cfg.SeasonShareStoryID]
            count = storyCfg.RewardList[1][2]
        end
    end
    ---@type UISeasonShareBtn
    self._shareBtn = self.shareBtnPool:SpawnObject("UISeasonShareBtn")
    self._shareBtn:SetData(
        count,
        function()
            self:_OnShare()
        end
    )
    self._shareBtn:GetGameObject():SetActive(GameGlobal.GetModule(ShareModule):CanShare())
end

--获取ui组件
function UISeasonCgDetailController:InitWidget()
    ---@type UICustomWidgetPool
    local topBtns = self:GetUIComponent("UISelectObjectPath", "TopBtn")
    ---@type UICommonTopButton
    self._backBtns = topBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:CloseDialog()
        end,
        nil,
        nil,
        true
    )

    -- --黑边
    -- ---@type UnityEngine.GameObject
    -- self._topBlackSide = self:GetGameObject("Top")
    -- ---@type UnityEngine.GameObject
    -- self._bottomBlackSide = self:GetGameObject("Bottom")
    -- ---@type UnityEngine.GameObject
    -- self._leftBlackSide = self:GetGameObject("Left")
    -- ---@type UnityEngine.GameObject
    -- self._rightBlackSide = self:GetGameObject("Right")
    ---@type UnityEngine.RectTransform
    self._uiCanvasRect = self:GetUIComponent("RectTransform", "UICanvas")


    self._spine1 = self:GetUIComponent("SpineLoader", "spine1")
    self._spine1Go = self:GetGameObject("spine1")

    self._spine2 = self:GetUIComponent("SpineLoader", "spine2")
    self._spine2Go = self:GetGameObject("spine2")

    self._staticPic = self:GetUIComponent("RawImageLoader", "imgCg")
    self._staticPicRect = self:GetUIComponent("RectTransform", "imgCg")
    self._staticPicGO = self:GetGameObject("imgCg")

    ---@type UILocalizationText
    self.txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    ---@type UILocalizationText
    self.txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
    self.exclueCgGo = self:GetGameObject("exclueCgGo")
    self.exclueCgGo2 = self:GetGameObject("exclueCgGo2")
    self.shareBtnPool = self:GetUIComponent("UISelectObjectPath", "ShareBtn")
    self.root = self:GetGameObject("Root")
end

function UISeasonCgDetailController:ImgCgOnClick(go)
    self.onlyShowCg = not self.onlyShowCg
    self.exclueCgGo:SetActive(not self.onlyShowCg)
    self.exclueCgGo2:SetActive(not self.onlyShowCg)
end

function UISeasonCgDetailController:_OnShare()
    self.exclueCgGo:SetActive(false)
    self.exclueCgGo2:SetActive(false)
    self:AttachEvent(GameEventType.OnFocusAfterShareBack, self._OnShareFinish)
    self:Lock("UISeasonShareCG")
    self:StartTask(
        function(TT)
            YIELD(TT)
            YIELD(TT)
            self:ShowDialog("UIShare",
                self:GetName(),
                ShareAnchorType.BottomRight,
                function()
                    self.exclueCgGo:SetActive(true)
                    self.exclueCgGo2:SetActive(true)
                end,
                nil,
                nil,
                nil,
                ShareSceneType.Common,
                nil,
                nil
            )
            self:UnLock("UISeasonShareCG")
        end,
        self
    )
end

--分享成功 领奖
function UISeasonCgDetailController:_OnShareFinish()
    self:DetachEvent(GameEventType.OnFocusAfterShareBack, self._OnShareFinish)
    --分享
    if not self._cpt:IsStoryReceived(self._cfg.SeasonShareStoryID) then
        self:StartTask(self._ReqCompleteStory, self)
    else
        Log.error("cg分享奖励已经领过了")
    end
end

function UISeasonCgDetailController:_ReqCompleteStory(TT)
    local res = AsyncRequestRes:New()
    self:Lock("RequestCollectShareCgAward")
    local assets = self._cpt:HandleStoryTake(TT, res, self._cfg.SeasonShareStoryID)
    self:UnLock("RequestCollectShareCgAward")
    if res:GetSucc() then
        UISeasonHelper.ShowUIGetRewards(assets) --服务器发什么展示什么
        self._shareBtn:GetGameObject():SetActive(false)
        self:DispatchEvent(GameEventType.OnSeasonShareCgFinished, self._cfg.ID)
    else
        Log.error("cg分享奖励领取错误:", res:GetResult())
    end
end

---@param rectTrans UnityEngine.RectTransform
function UISeasonCgDetailController:_SetPicFullScreen(rectTrans)
    -- 全屏图片资源固定长宽为2532/1170
    local fullPicWidth = 2048
    local fullPicHeight = 946

    local screenWidth, screenHeight = self:GetCanvasSize()

    local picAspect = fullPicWidth / fullPicHeight
    local screenAspect = screenWidth / screenHeight

    local blackSideHeight = 0
    local blackSideWidth = 0


    local picHeight = fullPicHeight * screenWidth / fullPicWidth
    rectTrans.sizeDelta = Vector2(screenWidth, picHeight)
    blackSideHeight = math.abs(screenHeight - picHeight) / 2

    -- if screenAspect < picAspect  then
    --     local picHeight = fullPicHeight * screenWidth / fullPicWidth
    --     rectTrans.sizeDelta = Vector2(screenWidth, picHeight)
    --     blackSideHeight = math.abs(screenHeight - picHeight) / 2
    -- elseif screenAspect > picAspect then
    --     local picWidth = fullPicWidth * screenHeight / fullPicHeight
    --     rectTrans.sizeDelta = Vector2(picWidth, screenHeight)
    --     blackSideWidth = math.abs(screenWidth - picWidth) / 2
    -- else
    --     rectTrans.sizeDelta = Vector2(screenWidth, screenHeight)
    -- end

    -- self:SetBlackSideSize(blackSideWidth, blackSideHeight)
end

-- function UISeasonCgDetailController:SetBlackSideSize(width, height)
--     self._topBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
--     self._bottomBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(0, height)
--     self._topBlackSide:SetActive(height > 0)
--     self._bottomBlackSide:SetActive(height > 0)
--     self._leftBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
--     self._rightBlackSide:GetComponent("RectTransform").sizeDelta = Vector2(width, 0)
--     self._leftBlackSide:SetActive(width > 0)
--     self._rightBlackSide:SetActive(width > 0)
-- end

function UISeasonCgDetailController:GetCanvasSize()
    return self._uiCanvasRect.sizeDelta.x, self._uiCanvasRect.sizeDelta.y
end
