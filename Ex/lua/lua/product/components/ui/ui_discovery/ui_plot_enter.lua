---@class UIPlotEnter:UIController
_class("UIPlotEnter", UIController)
UIPlotEnter = UIPlotEnter

function UIPlotEnter:OnShow(uiParam)
    ---@type DiscoveryNode
    local node = uiParam[1]
    ---@type DiscoveryStage
    self._stage = uiParam[2]
    local chapterid = uiParam[3]
    self._module = self:GetModule(MissionModule)
    ---@type DiscoveryData
    self._data = self._module:GetDiscoveryData()
    ---@type UILocalizationText
    local txtStageIdx = self:GetUIComponent("UILocalizationText", "txtStageIdx")
    ---@type RollingText
    local txtStageNameTex = self:GetUIComponent("UILocalizationText", "txtStageName")
    local txtStageName = self:GetUIComponent("RollingText", "txtStageName")
    txtStageIdx.text = node.name or ""
    txtStageName:RefreshText(self._stage.name or "")

    local img = self:GetUIComponent("Image","imgBG")
    self._atlas = self:GetAsset("UIDiscovery.spriteatlas", LoadType.SpriteAtlas)
    local sprite
    local texColor
    local descColor

    local discoverySection = self._data:GetDiscoverySectionByChapterId(chapterid)
    self._isBetween = discoverySection.isBetween

    if not self._isBetween then
        sprite = "map_juqing_di1"
        texColor = Color(44/255,44/255,44/255,1)
        descColor = Color(98/255,98/255,98/255,1)
    else
        sprite = "map_juqing_icon1"
        texColor = Color(156/255,115/255,185/255,1)
        descColor = Color(163/255,158/255,170/255,1)
    end
    txtStageIdx.color = texColor
    txtStageNameTex.color = descColor

    img.sprite = self._atlas:GetSprite(sprite)
end
function UIPlotEnter:OnHide()
end

function UIPlotEnter:EnterPlot()
    ---@type DiscoveryStory
    local story = self._data:GetStoryByStageIdStoryType(self._stage.id, StoryTriggerType.Node)
    if not story then
        Log.error("### [UIPlotEnter] no story in stage:", self._stage.id)
        return
    end
    self:ShowDialog(
        "UIStoryController",
        story.id,
        function()
            local isActive = self._module:IsPassMissionID(self._stage.id)
            if isActive then --已激活的就不再发激活消息
                -- Log.warn("### stage has pass.", self._stage.id)
                return
            end
            self:StartTask(
                function(TT)
                    self._module:SetMissionStoryActive(TT, self._stage.id, ActiveStoryType.ActiveStoryType_BeforeBattle)
                    local ret, award = self._module:CompleteStoryMission(TT, self._stage.id)
                    if ret == MISSION_RESULT_CODE.MISSION_SUCCEED then
                        GameGlobal.EventDispatcher():Dispatch(GameEventType.DiscoveryFlushLines)
                        self:ShowDialog(
                            "UIGetItemController",
                            award,
                            function()
                                local trigger = false
                                GameGlobal.EventDispatcher():Dispatch(
                                    GameEventType.GuidePlotEnterFinish,
                                    self._stage.id,
                                    function(_trigger)
                                        trigger = _trigger
                                    end
                                )
                                if not trigger then
                                --self:SwitchState(UIStateType.UIDiscovery)
                                end
                                -- Log.warn("### CompleteStoryMission success.", self._stage.id)
                                GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckPartUnlock)
                            end
                        )
                    else
                        --self:SwitchState(UIStateType.UIDiscovery)
                        -- Log.warn("### CompleteStoryMission fail.", self._stage.id)
                        ToastManager.ShowToast(self._module:GetErrorMsg(ret))
                    end
                end,
                self
            )
        end
    )
    self:CloseDialog()
end

function UIPlotEnter:imgBGOnClick(go)
    self:EnterPlot()
end
function UIPlotEnter:btnEnterOnClick(go)
    self:EnterPlot()
end

function UIPlotEnter:bgOnClick(go)
    self:CloseDialog()
end
