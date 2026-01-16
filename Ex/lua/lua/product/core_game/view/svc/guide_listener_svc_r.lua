require("guide_svc_r")

_class("GuideServiceListenerRender", GameEventListener)
GuideServiceListenerRender = GuideServiceListenerRender

function GuideServiceListenerRender:Constructor(guide_service)
    ---@type GuideServiceRender
    self._guide_service = guide_service
    self._eventDispatcher = guide_service._eventDispatcher
end

function GuideServiceListenerRender:RegEvents()
    self._eventDispatcher:AddListener(GameEventType.ShowGuideStep, self)
    self._eventDispatcher:AddListener(GameEventType.PauseGuideWeakLine, self)
    self._eventDispatcher:AddListener(GameEventType.FinishGuideWeakLine, self)
    self._eventDispatcher:AddListener(GameEventType.FinishGuideStep, self)
    self._eventDispatcher:AddListener(GameEventType.GuideYield, self)
    self._eventDispatcher:AddListener(GameEventType.GuideActiveSkill, self)
    self._eventDispatcher:AddListener(GameEventType.GuideChangeGhostLayer, self)
    self._eventDispatcher:AddListener(GameEventType.GuideYieldBreak, self)
end

function GuideServiceListenerRender:UnregEvents()
    self._eventDispatcher:RemoveListener(GameEventType.ShowGuideStep, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.PauseGuideWeakLine, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.FinishGuideWeakLine, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.FinishGuideStep, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.GuideYield, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.GuideActiveSkill, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.GuideChangeGhostLayer, self.listenerID)
    self._eventDispatcher:RemoveListener(GameEventType.GuideYieldBreak, self.listenerID)
end

function GuideServiceListenerRender:OnGameEvent(gameEventType, param)
    -- 显示触发引导步骤
    if gameEventType == GameEventType.ShowGuideStep then
        local guideStep = param
        local guideType = guideStep and guideStep.data.guideType
        local guideParam = guideStep and guideStep.guideParam
        if guideType == GuideType.Line then -- 强制连线
            self._guide_service:ShowGuideLine(guideParam)
        elseif guideType == GuideType.Piece then -- 格子引导
            self._guide_service:ShowGuidePiece(guideParam)
        elseif guideType == GuideType.StoryBanner then -- 剧情对话
        elseif guideType == GuideType.Warn then -- 对局左侧弹框
            GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowGuideWarn, guideParam)
        elseif guideType == GuideType.Pop then -- 弹出视频
        elseif guideType == GuideType.Circle then --圆形引导、格子遮罩高亮
            self._guide_service:ShowCircle(guideParam)
        elseif guideType == GuideType.Buff then -- 加buff
            self._guide_service:ShowBuff(guideParam)
        elseif guideType == GuideType.Entity then -- 加entity
            self._guide_service:ShowEntity(guideParam)
        elseif guideType == GuideType.PreviewLinkLine then -- 强制连线（主动技预览阶段）
            self._guide_service:ShowPLLGuideLine(guideParam)
        end
        self._guide_service:SetNeedYield(guideStep:NeedYield())
    elseif gameEventType == GameEventType.PauseGuideWeakLine then -- 暂停弱连线引导
        self._guide_service:PauseGuideWeakLine()
    elseif gameEventType == GameEventType.FinishGuideWeakLine then -- 结束弱连线引导
        self._guide_service:FinishGuideWeakLine()
    elseif gameEventType == GameEventType.FinishGuideStep then -- 结束步骤
        -- -- 焦点引导有创建模型的
        -- if guideType == GuideType.Circle then
        --     self._guide_service:FinishGuideShadowEntity()
        -- end
        local guideType = param
        if guideType == GuideType.Piece then
            self._guide_service:DestroyGuidePieceEntity()
        end
        if guideType == GuideType.Entity then
            self._guide_service:FinishGuideShadowEntity()
        end
    elseif gameEventType == GameEventType.GuideYield then -- 结束步骤
        local guideStep = param
        local yieldFlag = guideStep:Yield()
        if yieldFlag then
            self._guide_service:SetNeedYield(yieldFlag == 1)
        else
            self._guide_service:SetNeedYield(false)
        end
    elseif gameEventType == GameEventType.GuideYieldBreak then
        self._guide_service:SetNeedYield(false)
    elseif gameEventType == GameEventType.GuideActiveSkill then
        local petTempID = param.petTempID
        local guideStepID = param.guideStepID
        local playerEntity = self._guide_service._world:Player():GetLocalTeamEntity()
        local cmd = GuideCommand:New()
        cmd:SetPetPstId(self:GetPetPstIdByTempId(petTempID))
        cmd:SetGuideStepID(guideStepID)
        self._guide_service._world:Player():SendCommand(cmd)
    elseif gameEventType == GameEventType.GuideChangeGhostLayer then
        self._guide_service:ChangeGuideGhostLayer()
    end
end

function GuideServiceListenerRender:GetPetPstIdByTempId(petTempId)
    local pets = self._guide_service._world.BW_WorldInfo:GetLocalMatchPetList()
    for _, pet in ipairs(pets) do
        if pet:GetTemplateID() == petTempId then
            return pet:GetPstID()
        end
    end
    return nil
end
