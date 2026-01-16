--
---@class UISeasonFinalPlotShare : UIController
_class("UISeasonFinalPlotShare", UIController)
UISeasonFinalPlotShare = UISeasonFinalPlotShare

---@param res AsyncRequestRes
function UISeasonFinalPlotShare:LoadDataOnEnter(TT, res)
    res:SetSucc(true)
end

--初始化
function UISeasonFinalPlotShare:OnShow(uiParams)
    self:InitWidget()
    local seasonID = uiParams[1]
    ---@type StoryComponent
    self._cpt = uiParams[2] --用剧情组件标记奖励
    self._onFinish = uiParams[3]
    local cfg = Cfg.cfg_season_campaign_client[seasonID]
    self._storyID = cfg.FinalStoryShareStoryID
    local cg = cfg.FinalStoryCg
    local sourceCg = cfg.FinalStorySourceCg
    local cfg = Cfg.cfg_campaign_story[self._storyID]
    local asset = cfg.RewardList[1]
    self.cg:LoadImage(cg)
    self.sourceCg:LoadImage(sourceCg)
    ---@type UISeasonShareBtn
    local btn = self._shareBtn:SpawnObject("UISeasonShareBtn")
    btn:SetData(
        asset[2],
        function()
            self:_ShareBtnOnClick()
        end
    )
end

--获取ui组件
function UISeasonFinalPlotShare:InitWidget()
    --generated--
    ---@type RawImageLoader
    self.cg = self:GetUIComponent("RawImageLoader", "Cg")
    --generated end--
    self.sourceCg = self:GetUIComponent("RawImageLoader", "SourceCg")
    self._shareBtn = self:GetUIComponent("UISelectObjectPath", "ShareBtn")
    self._anim = self:GetGameObject():GetComponent("Animation")
    self._root = self:GetGameObject("root")
end

--按钮点击
function UISeasonFinalPlotShare:_ShareBtnOnClick()
    self:Lock("UISeasonFinalPlotShare")
    self:AttachEvent(GameEventType.OnFocusAfterShareBack, self._OnShareFinish)
    self.sourceCg.gameObject:SetActive(true)
    self._root:SetActive(false)
    self:StartTask(
        function(TT)
            YIELD(TT)
            YIELD(TT)
            self:ShowDialog("UIShare",
                self:GetName(),
                ShareAnchorType.BottomRight,
                function()
                    self.sourceCg.gameObject:SetActive(false)
                    self._root:SetActive(true)
                end,
                nil,
                nil,
                nil,
                ShareSceneType.Common,
                nil,
                nil
            )
            self:UnLock("UISeasonFinalPlotShare")
        end,
        self
    )
end

function UISeasonFinalPlotShare:_OnShareFinish()
    self:DetachEvent(GameEventType.OnFocusAfterShareBack, self._OnShareFinish)
    if not self._cpt:IsStoryReceived(self._storyID) then
        self:StartTask(self._ReqCompleteStory, self)
    else
        Log.error("分享奖励已经领过了")
    end
end

function UISeasonFinalPlotShare:_ReqCompleteStory(TT)
    local res = AsyncRequestRes:New()
    self:Lock("RequestCollectFinalPlotShareCgAward")
    local assets = self._cpt:HandleStoryTake(TT, res, self._storyID)
    self:UnLock("RequestCollectFinalPlotShareCgAward")
    if res:GetSucc() then
        self:_CloseDialogWithAnim(function()
            UISeasonHelper.ShowUIGetRewards(assets) --服务器发什么展示什么
            self._onFinish()
            self:DispatchEvent(GameEventType.OnSeasonShareCgFinished)
        end)
    else
        Log.error("分享奖励领取错误:", res:GetResult())
    end
end

--按钮点击
function UISeasonFinalPlotShare:CloseOnClick(go)
    self:_CloseDialogWithAnim(function()
        self._onFinish()
    end)
end

function UISeasonFinalPlotShare:_CloseDialogWithAnim(callback)
    if self._anim then
        self:Lock("UISeasonFinalPlotShare:CloseDialogWithAnim")
        if self._anim then
            self._anim:Play("uianim_UISeasonFinalPlotShare_out")
        end
        self:StartTask(
            function(TT)
                YIELD(TT, 500)
                self:UnLock("UISeasonFinalPlotShare:CloseDialogWithAnim")
                if not self.view then
                    return
                end
                self:CloseDialog()
                if callback then
                    callback()
                end
            end,
            self
        )
    end
end
