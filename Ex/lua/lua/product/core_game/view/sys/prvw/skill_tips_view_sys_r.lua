--[[------------------------------------------------------------------------------------------
    SkillTipsViewSystem_Render : 技能tips
]]--------------------------------------------------------------------------------------------

---@class SkillTipsViewSystem_Render:ReactiveSystem
_class("SkillTipsViewSystem_Render", ReactiveSystem )
SkillTipsViewSystem_Render = SkillTipsViewSystem_Render

function SkillTipsViewSystem_Render:Constructor(world)
    self._world = world

    ---1代表左下，2代表左上，3代表右下，4代表右上
    ---以下是1920*1080分辨率基础上的偏移参考值
    local baseWidth = 1920
    local baseHeight = 1080
    self._offsetDic = {}
    self._offsetDic[1] = Vector3(400,80,0)
    self._offsetDic[2] = Vector3(400,-80,0)
    self._offsetDic[3] = Vector3(-400,80,0)
    self._offsetDic[4] = Vector3(-400,-80,0)

    ---根据当前的屏幕分辨率做一次适配
    for k,v in ipairs(self._offsetDic) do 
        ---@type Vector3
        local offset = v
        local adaptWidth = (UnityEngine.Screen.width * offset.x)/baseWidth
        local adaptHeight = (UnityEngine.Screen.height * offset.y)/baseHeight

        offset.x = adaptWidth
        offset.y = adaptHeight
        --Log.fatal("adpat res",offset)
    end

end

function SkillTipsViewSystem_Render:GetTrigger(world)
    local group = world:GetGroup(world.BW_WEMatchers.View)
    local skillTipsGroup = world:GetGroup(world.BW_WEMatchers.SkillTips)
    local c = Collector:New({ group,skillTipsGroup }, {"Added","Added"})
    return c
end

function SkillTipsViewSystem_Render:Filter(entity)
    if entity:HasSkillTips() then
        if entity:HasView() then 
            return true
        end
    end
    return false
end

function SkillTipsViewSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
	    if entities[i]:HasSkillTips() then
		    self:ShowSkillTips(entities[i])
	    end
    end
end

---
function SkillTipsViewSystem_Render:ShowSkillTips(skillTipsEntity)
    --Log.fatal("ShowSkillTips")
    ---@type SkillTipsComponent
    local skillTipsCmpt = skillTipsEntity:SkillTips()

    local reBoard = self._world:GetRenderBoardEntity()
	local touchPos
    ---@type PreviewMonsterActionComponent
    local previewCmpt = reBoard:PreviewMonsterAction()
	---@type PreviewTrapActionComponent
	local previewTrapCmpt=	reBoard:PreviewTrapAction()

    if previewCmpt and previewCmpt:IsShowMonsterAction() then
        touchPos = previewCmpt:GetTouchPosition()
    elseif previewTrapCmpt and previewTrapCmpt:IsShowTrapAction() then
        touchPos = previewTrapCmpt:GetTouchPosition()
    end
    ---这个函数的参数没吊用
    local hudWorldPos = self:_CalcGridHUDWorldPos(touchPos)
    if hudWorldPos == nil then 
        return 
    end
    local viewCmpt = skillTipsEntity:View()
    local viewWrapper = viewCmpt.ViewWrapper
    local skillTipsView = viewWrapper.GameObject
    skillTipsView.transform.position = hudWorldPos
    ---@type UIView
    local uiViewCmpt = skillTipsView:GetComponent("UIView")
    self:_FlushUI(uiViewCmpt, skillTipsCmpt)
end

---
function SkillTipsViewSystem_Render:_FlushUI(uiViewCmpt, skillTipsCmpt)
    local csTextSkillName = uiViewCmpt:GetUIComponent("UILocalizationText", "Name")
    local csTextSkillDesc = uiViewCmpt:GetUIComponent("UILocalizationText", "Desc")
    local trapGO = uiViewCmpt:GetGameObject("trap")
    local skillGO = uiViewCmpt:GetGameObject("skill")
    local chessGO = uiViewCmpt:GetGameObject("ChessPet")

    if skillTipsCmpt:IsTriggeredByChessPet() then
        trapGO:SetActive(false)
        skillGO:SetActive(false)
        chessGO:SetActive(true)
    elseif skillTipsCmpt:GetTrapDesc() then
        trapGO:SetActive(true)
        skillGO:SetActive(false)
        chessGO:SetActive(false)
    else
        trapGO:SetActive(false)
        skillGO:SetActive(true)
        chessGO:SetActive(false)
    end

    local skillNameID = skillTipsCmpt:GetSkillName()
    local skillDescID = skillTipsCmpt:GetSkillDesc()

    local skillName = StringTable.Get(skillNameID)
    local skillDesc = StringTable.Get(skillDescID)

    csTextSkillName:SetText(skillName)
    csTextSkillDesc:SetText(skillDesc)
end

function SkillTipsViewSystem_Render:_CalcGridHUDWorldPos(gridPos)
    local camera = self._world:MainCamera():Camera()

    ---换了机制，不使用gridPos作为基准来显示tips，而是使用鼠标点的那个位置作为基准
    ---之前的gridPos先保留
    ---@type InputComponent
    local inputCmpt = self._world:Input()
    local inputPos = inputCmpt:GetTouchBeginPosition()
    if self._world:MatchType() == MatchType.MT_Chess then
        ---@type ChessPickUpComponent
        local chessPickUpCmpt = self._world:ChessPickUp()
        inputPos = chessPickUpCmpt:GetChessClickPos()
    elseif self._world:MatchType() == MatchType.MT_PopStar then
        ---@type PopStarPickUpComponent
        local popStarPickUpCmpt = self._world:PopStarPickUp()
        inputPos = popStarPickUpCmpt:GetPopStarClickPos()
    end

    local screenPos = camera:WorldToScreenPoint(inputPos)    
    local areaIndex = self:_CalcAreaIndex(screenPos,camera)
    local areaOffset = self._offsetDic[areaIndex]
    local targetScreenPos = areaOffset + screenPos

    local hudCamera = self._world:MainCamera():HUDCamera()
    local hudWorldPos = hudCamera:ScreenToWorldPoint(targetScreenPos)

    return hudWorldPos
end

---1代表左下，2代表左上，3代表右下，4代表右上
function SkillTipsViewSystem_Render:_CalcAreaIndex(screenPos,camera)
    local halfPixelWidth = camera.pixelWidth / 2
    local halfPixelHeight = camera.pixelHeight / 2

    local areaIndex = 0
    if screenPos.x <= halfPixelWidth then 
        if screenPos.y <= halfPixelHeight then 
            areaIndex = 1
        else
            areaIndex = 2
        end
    else
        if screenPos.y <= halfPixelHeight then 
            areaIndex = 3
        else
            areaIndex = 4
        end       
    end

    return areaIndex
end