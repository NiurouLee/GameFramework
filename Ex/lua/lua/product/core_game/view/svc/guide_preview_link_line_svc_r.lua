--[[------------------------------------------------------------------------------------------
    GuideServiceRender中关于预览阶段主动技连线的处理
]]
--------------------------------------------------------------------------------------------

require("guide_svc_r")

function GuideServiceRender:IsGuidePreviewLineLineInvokeType()
    return self:GetPLLInvokeType() == GuideInvokeType.GuidePreviewLinkLine
end

function GuideServiceRender:GetPLLInvokeType()
    ---@type Entity
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    return guidePLLCmpt and guidePLLCmpt:GetInvokeType() or GuideInvokeType.None
end

---在需要引导的时刻调用此方法
function GuideServiceRender:ShowPLLGuideLine(guideParam)
    self:_ShowPLLGuideLine(GuideRefreshType.StartGuidePath, guideParam)
end

function GuideServiceRender:_ShowPLLGuideLine(guideRefreshType, guideParam)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    local curGuideRefreshType = guidePLLCmpt:GetGuideRefreshType()
    if curGuideRefreshType ~= GuideRefreshType.StartGuidePath then
        if guideParam then
            local path = guideParam.LogicParams
            guidePLLCmpt:SetGuidePLLPath(path)
            guidePLLCmpt:SetInvokeType(guideParam.InvokeType)
        end
        guidePLLCmpt:SetGuideRefreshType(guideRefreshType)
        reBoard:ReplaceGuidePreviewLinkLine()
        self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, true)
    end
end

---处理相机回到正常点后的处理流程
function GuideServiceRender:HandlePLLCameraMoveToNormalTrigger()
    local invokeType = self:GetPLLInvokeType()
    if invokeType ~= GuideInvokeType.GuidePreviewLinkLine then
        return false
    end
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()

    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

    local finishGuide = self:CheckGuidePLLPathFinish(chainPath)
    if finishGuide == false then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        previewEntity:ReplacePreviewLinkLine({}, PieceType.None, PieceType.None)
        ---@type PreviewLinkLineService
        local linkLineSvc = self._world:GetService("PreviewLinkLine")
        linkLineSvc:NotifyPickUpTargetChange()

        --self._eventDispatcher:Dispatch(GameEventType.FlushPetChainSkillItem, true, 0, nil)

        self:_ReShowPLLGuideLine()
        return true
    end

    return false
end

---划线引导是否结束
---@param chainPath Array 当前的划线队列
function GuideServiceRender:CheckGuidePLLPathFinish(chainPath)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    local guidePath = guidePLLCmpt:GetGuidePLLPath()
    if chainPath == nil or guidePath == nil then
        return true
    end

    if #chainPath ~= #guidePath then
        return false
    end

    for index, pathPoint in ipairs(chainPath) do
        local curGuidePoint = guidePath[index]
        if curGuidePoint ~= pathPoint then
            return false
        end
    end

    return true
end

function GuideServiceRender:_ReShowPLLGuideLine()
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    guidePLLCmpt:SetGuideRefreshType(GuideRefreshType.RestartGuidePath)
    reBoard:ReplaceGuidePreviewLinkLine()
end

function GuideServiceRender:HandlePLLCameraMoveToFocusTrigger()
    local invokeType = self:GetPLLInvokeType()
    if invokeType ~= GuideInvokeType.GuidePreviewLinkLine then
        return
    end
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    local curGuideRefreshType = guidePLLCmpt:GetGuideRefreshType()
    if curGuideRefreshType ~= GuideRefreshType.ShowGuideLine then
        guidePLLCmpt:SetGuideRefreshType(GuideRefreshType.ShowGuideLine)
        reBoard:ReplaceGuidePreviewLinkLine()
    end
end

---返回值代表是否可以继续执行原有流程
function GuideServiceRender:HandlePLLBeginDragTrigger(newGridPos)
    self:PauseGuideWeakLine()
    local invokeType = self:GetPLLInvokeType()
    if invokeType == GuideInvokeType.GuidePreviewLinkLine then
        local reBoard = self._world:GetRenderBoardEntity()
        ---@type GuidePreviewLinkLineComponent
        local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
        guidePLLCmpt:SetGuideRefreshType(GuideRefreshType.ShowGuideLine)
        reBoard:ReplaceGuidePreviewLinkLine()
        return self:_CheckGuidePLLHasPos(newGridPos)
    end

    return true
end

function GuideServiceRender:_CheckGuidePLLHasPos(gridPos)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    local guidePath = guidePLLCmpt:GetGuidePLLPath()
    if guidePath == nil then
        return false
    end

    for _, v in ipairs(guidePath) do
        if v == gridPos then
            return true
        end
    end

    return false
end

function GuideServiceRender:HandlePLLEndDragTrigger()
    local invokeType = self:GetPLLInvokeType()
    if invokeType == GuideInvokeType.GuidePreviewLinkLine then
        ---@type Entity
        local previewEntity = self._world:GetPreviewEntity()
        ---@type PreviewLinkLineComponent
        local previewLinkLineCmpt = previewEntity:PreviewLinkLine()

        local chainPath = previewLinkLineCmpt:GetPreviewChainPath()

        local reBoard = self._world:GetRenderBoardEntity()
        ---@type GuidePreviewLinkLineComponent
        local guidePLLCmpt = reBoard:GuidePreviewLinkLine()

        local finishGuide = self:CheckGuidePLLPathFinish(chainPath)
        if finishGuide == true then
            ---引导结束
            guidePLLCmpt:SetInvokeType(GuideInvokeType.None)
            guidePLLCmpt:SetGuideRefreshType(GuideRefreshType.StopGuidePath)
            guidePLLCmpt:SetGuidePLLPath({})
            reBoard:ReplaceGuidePreviewLinkLine()
            self._eventDispatcher:Dispatch(GameEventType.ShowGuideMask, false)
            ---重置当前引导数据
            self._eventDispatcher:Dispatch(GameEventType.FinishGuideStep, GuideType.PreviewLinkLine)
        else
            ToastManager.ShowToast(StringTable.Get("str_guide_link_warn"))

            return false
        end
    end

    return true
end

---返回值代表是否可以继续执行原有流程
function GuideServiceRender:HandlePLLDragTrigger(newGridPos)
    local invokeType = self:GetPLLInvokeType()
    if invokeType ~= GuideInvokeType.GuidePreviewLinkLine then
        return true
    end
    ---@type Entity
    local previewEntity = self._world:GetPreviewEntity()
    ---@type PreviewLinkLineComponent
    local previewLinkLineCmpt = previewEntity:PreviewLinkLine()

    local chainPath = previewLinkLineCmpt:GetPreviewChainPath()
    local newPosIndex = #chainPath + 1
    return self:_CheckChainPosMatchGuidePLLPath(newPosIndex, newGridPos)
end

---检测当前连线的点是否和要引导的路径匹配
function GuideServiceRender:_CheckChainPosMatchGuidePLLPath(index, gridPos)
    local reBoard = self._world:GetRenderBoardEntity()
    ---@type GuidePreviewLinkLineComponent
    local guidePLLCmpt = reBoard:GuidePreviewLinkLine()
    local guidePath = guidePLLCmpt:GetGuidePLLPath()
    if guidePath == nil then
        return false
    end

    if #guidePath < index then
        return false
    end

    local guidePoint = guidePath[index]
    if guidePoint ~= gridPos then
        return false
    end

    return true
end
