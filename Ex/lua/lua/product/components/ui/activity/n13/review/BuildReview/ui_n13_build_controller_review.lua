--- @class UIN13BuildControllerReview:UIController
_class("UIN13BuildControllerReview", UIController)
UIN13BuildControllerReview = UIN13BuildControllerReview

--region help
function UIN13BuildControllerReview:_SpawnObject(widgetName, className)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local obj = pool:SpawnObject(className)
    return obj
end

function UIN13BuildControllerReview:_SpawnObjects(widgetName, className, count)
    ---@type UICustomWidgetPool
    local pool = self:GetUIComponent("UISelectObjectPath", widgetName)
    local objs = {}
    pool:SpawnObjects(className, count, objs)
    return objs
end

function UIN13BuildControllerReview:_SetRawImageBtn(widgetName, size, urlNormal, urlClick, callback)
    local obj = self:_SpawnObject(widgetName, "UIActivityCommonRawImageBtn")
    obj:SetData(size, urlNormal, urlClick, callback)
end

-- function UIN13BuildControllerReview:_SetRemainingTime(widgetName, descId, endTime, customTimeStr)
--     ---@type UIActivityCommonRemainingTime
--     local obj = self:_SpawnObject(widgetName, "UIActivityCommonRemainingTime")

--     if customTimeStr then
--         obj:SetCustomTimeStr_Common_1()
--     end
--     -- obj:SetExtraRollingText()
--     -- obj:SetExtraText("txtDesc", nil, extraId)
--     obj:SetAdvanceText(descId)

--     obj:SetData(endTime, nil, nil)
-- end

function UIN13BuildControllerReview:_PlayAnim(widgetName, animName, time, callback)
    local anim = self:GetUIComponent("Animation", widgetName)

    self:Lock(animName)
    anim:Play(animName)
    self:StartTask(
        function(TT)
            YIELD(TT, time)
            self:UnLock(animName)
            if callback then
                callback()
            end
        end,
        self
    )
end
--endregion

--region resident func
function UIN13BuildControllerReview:_SetCommonTopButton()
    local backBtns = self:GetUIComponent("UISelectObjectPath", "_backBtns")
    ---@type UICommonTopButton
    self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    self._backBtns:SetData(
        function()
            self:_Back()
        end,
        nil,
        nil,
        false,
        function()
            self:_HideUI()
        end
    )
end

function UIN13BuildControllerReview:_Back()
    self._campaign._campaign_module:CampaignSwitchState(
        true,
        UIStateType.UIN13MainControllerReview,
        UIStateType.UIMain,
        nil,
        self._campaign._id
    )
end

function UIN13BuildControllerReview:_HideUI()
    self:GetGameObject("_showBtn"):SetActive(true)

    self:_PlayAnim("_ani", "uieff_n13_build_main_hide", 333, nil)
    self:GetGameObject("BuildingNames"):SetActive(false)
    --self:GetGameObject("BuildingPicnic"):SetActive(false)
end

function UIN13BuildControllerReview:_ShowUI()
    self:GetGameObject("_showBtn"):SetActive(false)

    self:_PlayAnim("_ani", "uieff_n13_build_main_show", 333, nil)
    self:GetGameObject("BuildingNames"):SetActive(true)
    --self:GetGameObject("BuildingPicnic"):SetActive(true)
end
--endregion

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIN13BuildControllerReview:LoadDataOnEnter(TT, res, uiParams)
    self._campaignType = ECampaignType.CAMPAIGN_TYPE_REVIEW_N13
    self._componentId = ECampaignReviewN13ComponentID.ECAMPAIGN_REVIEW_ReviewN13_BUILD

    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(TT, res, self._campaignType, self._componentId)

    -- 错误处理
    if res and not res:GetSucc() then
        self._campaign:CheckErrorCode(res.m_result, nil, nil)
        return
    end

    -- 检查组件是否开启
    if not self._campaign:CheckComponentOpen(self._componentId) then
        res.m_result = self._campaign:CheckComponentOpenClientError(self._componentId)
        self._campaign._campaign_module:ShowErrorToast(res.m_result, true)
        return
    end

    ---@type CampaignBuildComponent
    self._component = self._campaign:GetComponent(self._componentId)
    ---@type BuildComponentInfo
    self._componentInfo = self._component:GetComponentInfo()
end

function UIN13BuildControllerReview:_ReLoadDataAndRefresh()
    self:StartTask(
        function(TT)
            ---@type AsyncRequestRes
            local res = AsyncRequestRes:New()
            -- 强制刷新组件数据
            self._campaign:ReLoadCampaignInfo_Force(TT, res)

            self:_Refresh()
        end
    )
end

function UIN13BuildControllerReview:OnShow(uiParams)
    self:SetShowDebug(false, false) -- Debug

    self:_AttachEvents()

    self._isOpen = true
    UnityEngine.Input.multiTouchEnabled = true

    -- 首次清除 new
    local dbStr = N13ToolFunctions.GetSakuragariNew()
    local hadSave = not LocalDB.SetInt(dbStr, 1)

    self:_Init()
end

function UIN13BuildControllerReview:OnHide()
    self:_DetachEvents()
    self._isOpen = false
    UnityEngine.Input.multiTouchEnabled = false

    if self._cameraTweener then
        self._cameraTweener:Kill()
    end

    self._sr.OnContentPosChanged = nil
    self._sr.onContentScaleChanged = nil
end

function UIN13BuildControllerReview:_Init()
    self._content = self:GetUIComponent("RectTransform", "Content")
    self._redPoint = self:GetGameObject("RedPoint")
    self.playerID = GameGlobal.GameLogic():GetOpenId()
    self:_SetCommonTopButton()
    self:_SetBg()

    self:_InitBuildManager()
    self:_InitMap()
    self:_InitGotoManager()
    self:_InitScrollView()

    self:_SetPlotBtn()
    self:_SetRewardBtn()

    self:_Refresh()

    self:CheckStory()
    self:CheckRed()
end

function UIN13BuildControllerReview:CheckRed()
    local unlock, all = self._buildManager:CalcBuildUnlockProgress()
    local value = LocalDB.GetInt(self.playerID.."UIN13BuildPlotControllerReviewExtOnClickTrue")
    
    if  unlock == all and value ~= 1 then
        self._redPoint:SetActive(true)
    else
        self._redPoint:SetActive(false)
    end
end

function UIN13BuildControllerReview:_InitBuildManager()
    --if not self._buildManager then
        ---@type UIBuildComponentManager
        self._buildManager = UIBuildComponentManager:New(self._component)
    --end
end

function UIN13BuildControllerReview:_InitMap()
    local nodeData = UIUndirectedGraphData:New(Cfg.cfg_n13_map_node {}, Cfg.cfg_n13_map_line {})
    self:_SetMapNode(nodeData)
    self:_SetMapLine(nodeData)

    if not self._petManager then
        ---@type UICustomWidgetPool
        local pool = self:GetUIComponent("UISelectObjectPath", "Nodes")
        local objs = pool:GetAllSpawnList()
        ---@type UIN13BuildMapPetManager
        self._petManager =
            UIN13BuildMapPetManager:New(
            Cfg.cfg_n13_map_pet {},
            nodeData,
            objs,
            function(count)
                -- [ctrl + shift + f] UIN13BuildMapPetManager:_InitPetObjMap
                return self:_SpawnObjects("Pets", "UIN13BuildMapPet", count)
            end,
            function()
                -- [ctrl + shift + f] UIN13BuildMapPetManager:_GetFixedPetIdList
                local seq = self._buildManager:GetPicnicCurSeq()
                local picnicList = self._buildManager:GetBuildItemIdList_Picnic()
                local list = self._buildManager:GetPicnicFixedPetIdList(seq, #picnicList + 1) -- 多取一个以保证调用时 seq 未更新
                return list
            end,
            function()
                -- [ctrl + shift + f] UIN13BuildMapPetManager:_InitNode
                local cfgs = Cfg.cfg_n13_map_node_picnic {}
                local tb = {}
                for _, v in pairs(cfgs) do
                    tb[v.MapNodeId] = true
                end
                return tb
            end,
            function(petId)
                -- [ctrl + shift + f] UIN13BuildMapPet:BtnOnClick
                local seq = self._buildManager:GetPicnicCurSeq()
                local storyType = 2 -- hack:
                local storyId = self._buildManager:GetPicnicStory(seq)
                if storyId and storyId > 0 then
                    local storyInfo = {storyType, storyId, 0, 0}
                    UIActivityN13Helper.PlayStory_Picnic(
                        self._component,
                        storyInfo,
                        function(res)
                            if res:GetSucc() then
                                -- ToastManager.ShowToast("PicnicStory Succ")
                                Log.info("UIN13BuildMapPet:BtnOnClick() PicnicStory Succ")
                            else
                                -- ToastManager.ShowToast("PicnicStory Failed")
                                Log.error("UIN13BuildMapPet:BtnOnClick() PicnicStory Failed")
                            end
                            self:_ReLoadDataAndRefresh()
                        end
                    )
                end
            end
        )
        self._petManager:Start()
    end
end

function UIN13BuildControllerReview:_InitGotoManager()
    if not self._gotoManager then
        ---@type UIN13BuildGotoManager
        self._gotoManager =
            UIN13BuildGotoManager:New(
            self._buildManager,
            self._petManager,
            self:GetGameObject("GotoRoot"),
            self:_SpawnObjects("GotoRoot", "UIN13BuildGotoBtn", 2),
            self:_InitGotoPoints(),
            self._content,
            function(target)
                -- [ctrl + shift + f] UIN13BuildGotoManager._btnCallback
                local duration = 0.5
                local targetScale = self._defaultScale
                self:CameraMoveTo(target, duration, targetScale)
            end
        )

        self._gotoManager:Refresh(EnumN13Review.B)
    end
end

function UIN13BuildControllerReview:_InitGotoPoints()
    local pointName = {
        "_point_top_left",
        "_point_top_right",
        "_point_bottom_left",
        "_point_bottom_right",
        "_point_left_top",
        "_point_left_bottom",
        "_point_right_top",
        "_point_right_bottom"
    }
    local tb = {}
    for _, v in ipairs(pointName) do
        table.insert(tb, self:GetGameObject(v).transform.localPosition)
    end
    return tb
end

--region refresh
function UIN13BuildControllerReview:_Refresh()
    self:_SetProgress()
    self:_SetScore()
    --self:_SetTime()

    self:_RefreshBuild()
    self:_RefreshMapPet()
    self:_MovePetToBuild()
end

function UIN13BuildControllerReview:_RefreshBuild()
    local buildItemIdList = self._buildManager:GetBuildItemIdList()
    self:_SetMapBuildings(buildItemIdList)
    self:_SetMapBuildingNames(buildItemIdList)
    --local picnicItemIdList = self._buildManager:GetBuildItemIdList_Picnic()
    --self:_SetMapBuildingPicnic(picnicItemIdList)
    self:_SetEffect()
end

function UIN13BuildControllerReview:_RefreshMapPet()
    local haveStory = self._buildManager:CheckPicnicHaveStory()
    local seq = self._buildManager:GetPicnicCurSeq()
    local petId = self._buildManager:GetPicnicPet(seq)
    self._petManager:SetPetBtnShow(haveStory and petId or 0)
end

-- 将 Pet 节点移动到 Building 下
function UIN13BuildControllerReview:_MovePetToBuild()
    local cfg = Cfg.cfg_n13_map_pet_setting[1]
    local petLayer = cfg.PetLayer or 0

    local idx = 0
    local buildItemIdList = self._buildManager:GetBuildItemIdList()
    for i, v in ipairs(buildItemIdList) do
        if self._buildManager:GetLayer(v) > petLayer then
            idx = i
            break
        end
    end

    local parent = self:GetUIComponent("Transform", "Buildings")
    local petTrans = self:GetUIComponent("Transform", "Pets")
    petTrans.parent = parent
    petTrans:SetSiblingIndex(idx)
end
--endregion

function UIN13BuildControllerReview:_SetBg()
    local obj = self:GetUIComponent("RawImageLoader", "bg")

    local url = "xueluoyuan_map_kong"
    if url then
        obj:LoadImage(url)
    end
end

function UIN13BuildControllerReview:_SetProgress()
    local unlock, all = self._buildManager:CalcBuildUnlockProgress()
    local txt = math.floor(unlock * 100 / all) .. "%"

    ---@type UILocalizationText
    local obj = self:GetUIComponent("UILocalizationText", "_txtProgress")
    obj:SetText(txt)
end

function UIN13BuildControllerReview:_SetScore()
    local obj = self:_SpawnObject("_score", "UIN13BuildScore")
    obj:SetData(EnumN13Review.B)
end

-- function UIN13BuildControllerReview:_SetTime()
--     local endTime = self._componentInfo.m_close_time
--     self:_SetRemainingTime("_remainingTime", "str_n13_line_mission_remaining_time", endTime, nil)
-- end

function UIN13BuildControllerReview:_SetPlotBtn()
    self:_SetRawImageBtn(
        "PlotReviewBtn",
        Vector2(415, 213),
        "n13_xly_btn03",
        "n13_xly_btn04",
        function()
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SakuraCommonClick)
            self:ShowDialog("UIN13BuildPlotControllerReview", self._buildManager,
            function ()
                self:CheckRed()
            end)
        end
    )
end

function UIN13BuildControllerReview:_SetRewardBtn()
    self:_SetRawImageBtn(
        "RewardBtn",
        Vector2(488, 242),
        "n13_xly_btn01",
        "n13_xly_btn02",
        function()
            AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDefaultClick)
            self:ShowDialog("UIN13BuildRewardController", self._buildManager)
        end
    )
end

--region ScrollView
function UIN13BuildControllerReview:_InitScrollView()
    ---@type DG.Tweening.Tweener
    self._cameraTweener = nil --相机移动Tweener

    self._scaleMin = Mathf.Max(0.5, self:_CalcMinScale())
    self._scaleMax = 1
    self._scaleStep = 0.1

    self._defaultScale = 1
    self._curScale = self._defaultScale

    self:_SetScrollView()

    -- 进入场景时定位地图位置
    local target = Vector2(-200, -200)
    local duration = 0
    local targetScale = self._defaultScale
    self:CameraMoveTo(target, duration, targetScale)
end

function UIN13BuildControllerReview:_CalcMinScale()
    self._srRT = self:GetUIComponent("RectTransform", "ScrollView")
    local rtBg = self:GetUIComponent("RectTransform", "bg")

    local scaleX = self._srRT.rect.width / rtBg.rect.width
    local scaleY = self._srRT.rect.height / rtBg.rect.height
    return Mathf.Max(scaleX, scaleY)
end

function UIN13BuildControllerReview:_SetScrollView()
    self._srRT = self:GetUIComponent("RectTransform", "ScrollView")

    --滚动缩放地图
    ---@type ScalableScrollRect
    self._sr = self:GetUIComponent("ScalableScrollRect", "ScrollView")
    self._sr:Init(Vector2(self._scaleMin, self._scaleMax), self._scaleStep)
    self._sr.OnContentPosChanged = function()
        self._gotoManager:Refresh()
    end
    self._sr.onContentScaleChanged = function(scale)
        Log.info("self._sr.onContentScaleChanged")
        self._curScale = scale
        self._sr:UpdateContentScale(scale)
        self._gotoManager:Refresh()
    end

    -- 注册滚轮事件
    if EDITOR or IsPc() then
        local contentScale = 1
        self:SetUIEventTrigger( --滚轮
            self._sr.gameObject,
            UIEventTriggerType.Scroll,
            function(ped)
                contentScale =
                    Mathf.Clamp(contentScale + ped.scrollDelta.y * self._scaleStep, self._scaleMin, self._scaleMax)
                self._sr:UpdateContentScale(contentScale)
            end
        )
    end
end

---是否正在操作地图（单指滑动，两指缩放等）
function UIN13BuildControllerReview:IsHandlingMap()
    if self._sr then
        return self._sr:IsDragging() or self._sr:IsScaling()
    end
end

---@param target Vector2 目标位置坐标
---@param duration float 移动时长，0表示瞬移
---@param targetScale float 地图目标缩放值，为nil表示不进行缩放
---@param callback function 移动完成后的回调
---@param paramsTabel table 回调参数
function UIN13BuildControllerReview:CameraMoveTo(target, duration, targetScale, callback, paramsTabel, ignoreLimit, outBack)
    if self:IsHandlingMap() then --操作地图的时候不允许移动相机
        return
    end
    if self._cameraTweener and self._cameraTweener:IsPlaying() then --相机移动过程不会被打断
        return
    end
    local endPos = self:GetContentMoveVector(target)
    local beginScale = self._curScale
    if not ignoreLimit then
        if targetScale then
            targetScale = Mathf.Clamp(targetScale, self._scaleMin, self._scaleMax) --保证缩放值在范围之内
        end
    end
    if duration == -1 then
        --时间的为1的最远距离  小于则在0-1之间  大于则=1
        local moveMaximumDistance = 1000
        local currentDistance = (self._content.anchoredPosition - endPos).magnitude
        duration = Mathf.Lerp(0, 1, currentDistance / moveMaximumDistance)
    end
    --相机移动过程中开启UI锁
    if duration > 0 then
        local lockStr = "UIN13BuildControllerReview_CameraMoveTo"
        self:StartTask(
            function(TT)
                self:Lock(lockStr)
                YIELD(TT, duration * 1000) --ms
                self:UnLock(lockStr)
            end,
            self
        )
    end
    local tempScale = 0
    self._cameraTweener =
        self._content:DOAnchorPos(endPos, duration):OnUpdate(
        function()
            if targetScale then
                local value = 0
                if outBack then
                    -- Log.error("value:", value)
                    if self._cameraTweener:ElapsedDirectionalPercentage() < 0.5 then
                        value = beginScale + 0.5 * self._cameraTweener:ElapsedDirectionalPercentage()
                        tempScale = value
                    else
                        value =
                            tempScale + (targetScale - tempScale) * self._cameraTweener:ElapsedDirectionalPercentage()
                    end
                else
                    value = beginScale + (targetScale - beginScale) * self._cameraTweener:ElapsedDirectionalPercentage()
                end
                self._sr:UpdateContentScale(value)
            end
        end
    ):OnComplete(
        function()
            if callback then
                callback(paramsTabel)
            end
        end
    )
end

function UIN13BuildControllerReview:GetContentMoveVector(target)
    local endPos = Vector2.zero - target --既然是相机不动地图动，那么就该是地图沿着相机移动向量的反向量移动
    if self._content.sizeDelta.x ~= 0 then
        local limitX = self._content.sizeDelta.x * self._defaultScale / 2 - ResolutionManager.ScreenWidth() / 2
        local limitY = self._content.sizeDelta.y * self._defaultScale / 2 - ResolutionManager.ScreenHeight() / 2
        endPos.x = Mathf.Clamp(endPos.x, -limitX, limitX)
        endPos.y = Mathf.Clamp(endPos.y, -limitY, limitY)
    end
    return endPos
end
--endregion

--region Buildings
function UIN13BuildControllerReview:_SetMapBuildings(buildItemIdList)
    local buildingItems = self:_SpawnObjects("Buildings", "UIN13BuildItem", table.count(buildItemIdList))
    for i = 1, #buildingItems do
        ---@type UIN13BuildItem
        local item = buildingItems[i]
        item:SetData(self._buildManager, buildItemIdList[i],EnumN13Review.B)
    end
end

function UIN13BuildControllerReview:_SetMapBuildingNames(buildItemIdList)
    local buildingItems = self:_SpawnObjects("BuildingNames", "UIN13BuildItemName", table.count(buildItemIdList))
    local type = 1
    for i = 1, #buildingItems do
        ---@type UIN13BuildItemName
        local item = buildingItems[i]
        item:SetData(
            self._buildManager,
            buildItemIdList[i],
            function()
                -- [ctrl + shift + f] UIN13BuildItemName:BtnOnClick
                self:ShowDialog("UIN13BuildConfirmController", self._buildManager, buildItemIdList[i],EnumN13Review.B)
            end,
            EnumN13Review.B
        )
    end
end

-- function UIN13BuildControllerReview:_SetMapBuildingPicnic(picnicItemIdList)
--     local buildingItems = self:_SpawnObjects("BuildingPicnic", "UIBuildBuildItemPicnic", table.count(picnicItemIdList))
--     for i = 1, #buildingItems do
--         ---@type UIBuildBuildItemPicnic
--         local item = buildingItems[i]
--         item:SetData(
--             self._buildManager,
--             picnicItemIdList[i],
--             function()
--                 -- [ctrl + shift + f] UIBuildBuildItemPicnic:BtnOnClick
--                 self._component:Start_HandlePicnicPutFood(
--                     picnicItemIdList[i],
--                     function(res, rewardList)
--                         if res:GetSucc() then
--                             -- ToastManager.ShowToast("Picnic Succ")
--                             Log.info("UIBuildBuildItemPicnic:BtnOnClick() Picnic Succ")

--                             self:_OnPicnic(
--                                 picnicItemIdList[i],
--                                 function()
--                                     -- [ctrl + shift + f] UIN13BuildMapPet:_ActEating
--                                     UIActivityHelper.ShowUIGetRewards(rewardList)
--                                     self:_ReLoadDataAndRefresh()
--                                     self._petManager:ChangeFixedPet()
--                                 end
--                             )
--                         else
--                             -- ToastManager.ShowToast("Picnic Failed")
--                             Log.error("UIBuildBuildItemPicnic:BtnOnClick() Picnic Failed")

--                             self:_ReLoadDataAndRefresh()
--                         end
--                     end
--                 )
--             end
--         )
--     end
-- end

function UIN13BuildControllerReview:_OnPicnic(buildItemId, callback)
    local seq = self._buildManager:GetPicnicCurSeq()
    local pet = self._buildManager:GetPicnicPet(seq)
    local story = self._buildManager:GetPicnicStory(seq)

    local cfg = Cfg.cfg_n13_map_node_picnic[buildItemId]
    if not cfg then
        Log.exception("UIN13BuildControllerReview:_OnPicnic() cfg_n13_map_node_picnic == nil, buildItemId = ", buildItemId)
    end
    local nodeId = cfg.MapNodeId

    self._petManager:SetPetPicnic(pet, nodeId, story, callback)
end
--endregion

--region Map
function UIN13BuildControllerReview:_SetMapNode(nodeData)
    local tb = nodeData:GetNodeIdList()

    local count = table.count(tb)
    local objs = self:_SpawnObjects("Nodes", "UIN13BuildMapNode", count)

    for i, v in ipairs(objs) do
        v:SetData(nodeData, tb[i], nil)
        v:SetDebugText(tb[i])
    end
end

function UIN13BuildControllerReview:_SetMapLine(nodeData)
    local tb = nodeData:GetLineIdList()

    local count = table.count(tb)
    local objs = self:_SpawnObjects("Lines", "UIN13BuildMapLine", count)

    for i, v in ipairs(objs) do
        v:SetData(nodeData:GetLinePos(tb[i]))
        v:SetDebugText(tb[i])
    end
end
--endregion

--region BuildingEffect
function UIN13BuildControllerReview:_SetEffect()
    self:GetGameObject("_fx"):SetActive(false)
    self:GetGameObject("_fx2"):SetActive(false)
end

function UIN13BuildControllerReview:_PlayEffect(buildItemId)
    -- [ctrl + shift + f] UIN13BuildControllerReview:_SetEffect

    local tbObj = {"_fx", "_fx2"}
    local tbTrans = {"_fxScale", "_fx2Scale"}

    -- 计算类型
    local curStatus = self._buildManager:GetBuildCurStatus(buildItemId)
    local type = (curStatus == UIBuildComponentBuildStatus.CleanUpComplete) and 1 or 2

    -- 设置位置
    local pos = self._buildManager:GetWidgetPos(buildItemId) + self._buildManager:GetEffectAreaPos(buildItemId)
    local objPos = self:GetGameObject(tbObj[type])
    objPos.transform.anchoredPosition = pos

    -- 设置大小w
    local scale = self._buildManager:GetEffectAreaScale(buildItemId)
    scale = scale * self._curScale / self._defaultScale -- 与场景 Scale 匹配
    local objScale = self:GetGameObject(tbTrans[type])
    objScale.transform.localScale = Vector3.one * scale

    -- 显示
    self:GetGameObject(tbObj[type]):SetActive(true)

    if type == 1 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N6RandomItemDisapper)
    elseif type == 2 then
        AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.N6ShowBuilding)
    end

    -- 关闭
    -- UIN13BuildConfirmController:_PlayOut() 会在一段时间后
    -- 发送 GameEventType.NPlusSixBuildingMainRefresh 事件
    -- 刷新全部建筑，此时会关闭特效 self:_SetEffect()
end
--endregion

--region Story
function UIN13BuildControllerReview:CheckStory()
    local storyList = self._buildManager:GetUnPlayStoryList()
    if storyList == nil or #storyList <= 0 then
        return
    end
    self:PlayStoryList(storyList)
end

function UIN13BuildControllerReview:PlayStoryList(storyList)
    if table.count(storyList) <= 0 then
        return
    end
    local storyInfo = storyList[1]
    table.remove(storyList, 1)
    UIActivityN13Helper.PlayStory_Build(
        self._component,
        storyInfo,
        function()
            self:PlayStoryList(storyList)
        end
    )
end
--endregion

--region Event Callback
function UIN13BuildControllerReview:ShowBtnOnClick(go)
    self:_ShowUI()
end
--endregion

--region AttachEvent
function UIN13BuildControllerReview:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)

    self:AttachEvent(GameEventType.NPlusSixBuildingMainRefresh, self._RefreshBuild)
    self:AttachEvent(GameEventType.NPlusSixBuildingBuildingComplete, self._PlayEffect)
    self:AttachEvent(GameEventType.NPlusSixBuildingAllBuildingComplete, self._Refresh)
    -- self:AttachEvent(GameEventType.NPlusSixShowEventRewardTips, self.ShowTips)
    -- self:AttachEvent(GameEventType.NPlusSixEventRefresh, self.RefreshEvent)
    -- self:AttachEvent(GameEventType.NPlusSixEventComplete, self.EventCompleteHandle)

    self:AttachEvent(GameEventType.AfterUILayerChanged, self.OnUIOpenClose)
end

function UIN13BuildControllerReview:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)

    self:DetachEvent(GameEventType.NPlusSixBuildingMainRefresh, self._RefreshBuild)
    self:DetachEvent(GameEventType.NPlusSixBuildingBuildingComplete, self._PlayEffect)
    self:DetachEvent(GameEventType.NPlusSixBuildingAllBuildingComplete, self._Refresh)
    -- self:DetachEvent(GameEventType.NPlusSixShowEventRewardTips, self.ShowTips)
    -- self:DetachEvent(GameEventType.NPlusSixEventRefresh, self.RefreshEvent)
    -- self:DetachEvent(GameEventType.NPlusSixEventComplete, self.EventCompleteHandle)

    self:DetachEvent(GameEventType.AfterUILayerChanged, self.OnUIOpenClose)
end

function UIN13BuildControllerReview:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIN13BuildControllerReview:OnUIOpenClose()
    UnityEngine.Input.multiTouchEnabled = self:Manager():IsTopUI(self.name)
end
--endregion

--region debug
function UIN13BuildControllerReview:SetShowDebug(showMap, showPet)
    self._flagDebugShowMap = showMap
    self._flagDebugShowPet = showPet
    self:_SetDebug()
end

function UIN13BuildControllerReview:_SetDebug()
    local show = UIActivityHelper.CheckDebugOpen()

    local obj = self:GetGameObject("Test") -- 调试按钮
    obj:SetActive(show)

    local tb = {"Nodes", "Lines"} -- 调试信息
    for _, v in ipairs(tb) do
        local obj = self:GetGameObject(v)
        obj:SetActive(self._flagDebugShowMap and show)
    end

    if self._petManager then
        self._petManager:SetShowDebug(self._flagDebugShowPet and show)
    end
end

function UIN13BuildControllerReview:Test1BtnOnClick(go)
    -- 显示光灵调试信息
    self:SetShowDebug(not self._flagDebugShowMap, self._flagDebugShowPet)
end

function UIN13BuildControllerReview:Test2BtnOnClick(go)
    -- 显示路点调试信息
    self:SetShowDebug(self._flagDebugShowMap, not self._flagDebugShowPet)
end

function UIN13BuildControllerReview:Test3BtnOnClick(go)
    -- 测试交换固定光灵
    local newFixedPetIdList = self._petManager:DebugChangeFixedPet()

    local t = "{"
    for _, v in ipairs(newFixedPetIdList) do
        t = t .. v .. ", "
    end
    t = t .. "}"
    ToastManager.ShowToast("new fixed petid = " .. t)
end
--endregion
