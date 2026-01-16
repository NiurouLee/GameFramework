---@class UIChooseMainCgController:UIController
_class("UIChooseMainCgController", UIController)
UIChooseMainCgController = UIChooseMainCgController

local currentEvent
function UIChooseMainCgController:Constructor()
    self._changePosValue = 0
    self._changePosValue2 = 0
    --速递
    self._speed = 50
    --位置偏移，为了能在拐角处自然一点，不要改
    self._up_offset = -1
    self._down_offset = 5
    self._right_offset = -20
end

function UIChooseMainCgController:OnShow(uiParams)
    currentEvent = UnityEngine.EventSystems.EventSystem.current

    self._type = uiParams[1]
    self:GetComponents()
    self:OnValue()
end

function UIChooseMainCgController:GetComponents()
    self._minValueTex = self:GetUIComponent("UILocalizationText","minValue")
    self._maxValueTex = self:GetUIComponent("UILocalizationText","maxValue")
    self._currentValueTex = self:GetUIComponent("UILocalizationText","currentValue")

    ---@type UnityEngine.UI.Slider
    self._sliderView = self:GetUIComponent("Slider","sliderView")

    self._line_down = self:GetUIComponent("RectTransform","line_down")
    self._line_up = self:GetUIComponent("RectTransform","line_up")
    self._line_left = self:GetUIComponent("RectTransform","line_left")
    self._line_right = self:GetUIComponent("RectTransform","line_right")
end

function UIChooseMainCgController:OnValue()
    self:Init()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnShowChangeMainCg,true)
end

function UIChooseMainCgController:GetPosAndScale()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local petid = roleModule:GetResId()

    self._defaultPetID = 0
    local grade
    local skin
    local asid
    if petid and petid ~= 0 then
        self._defaultPetID = petid
        grade = roleModule.m_choose_painting.pet_grade
        skin = roleModule.m_choose_painting.skin_id
        asid = roleModule.m_choose_painting.board_pet
    else
        --获取spine设置
        self._defaultPetID = Cfg.cfg_global["main_default_spine_pet_id"].IntValue
        grade = 0
        skin = 0
        asid = 0
    end

    local petModule = GameGlobal.GetModule(PetModule)
    local cfg_pet
    if grade > 0 then
        cfg_pet = Cfg.cfg_pet_grade {PetID = self._defaultPetID, Grade = grade}[1]
    else
        cfg_pet = Cfg.cfg_pet[self._defaultPetID]
    end

    ---@type MatchPet
    if cfg_pet then
        --看板娘qa
        if asid and asid ~= 0 then
            local cfg_as = Cfg.cfg_only_assistant[asid]
            if not cfg_as then
                Log.error("###[UIChooseMainCgController] cfg_as is nil ! id --> ",asid)
            end
            self._staticSpineSettings = cfg_as.CG
        else
            --时装还没应用
            self._staticSpineSettings =
            HelperProxy:GetInstance():GetPetStaticBody(self._defaultPetID, grade, skin, PetSkinEffectPath.NO_EFFECT)
        end
    else
        self._staticSpineSettings = self._defaultPetID .. "_cg"
    end

    -----------------------------------
    self._startPos = Vector2(0,0)
    self._startScale = 1

    local open_id = GameGlobal.GameLogic():GetOpenId()
    local title = "MAIN_OFFSET_"
    local key = title .. open_id .. "_" .. self._staticSpineSettings

    local pos_offset_str = LocalDB.GetString(key,"null")
    if pos_offset_str == "null" then
    else
        local strs = string.split(pos_offset_str,"|")
        local _x = tonumber(strs[1])
        local _y = tonumber(strs[2])

        self._startPos = Vector2(_x,_y)
        self._startScale = tonumber(strs[3])
    end

    self._defaultPos = self._startPos
    self._defaultScale = self._startScale
end

function UIChooseMainCgController:Init()
    self:GetPosAndScale()

    self._minValue = 100
    self._maxValue = 300

    --缩放系数
    self._scaleK = 0.2
    self._touchScaleK = 0.001

    --缩放限制
    self._scaleMax = 1.5
    self._scaleMin = 0.5

    --移动系数
    self._moveK = 1
    --移动限制
    self._moveMaxX = 1000
    self._moveMinX = -1000
    self._moveMaxY = 500
    self._moveMinY = -500

    --计算鼠标移动位置
    self._mousePos2 = 0
    self._mousePos = 0

    --动作
    self._scaling = false
    self._draging = false

    --手指移动位置
    self._touch0Pos = 0
    self._touch0Pos2 = 0

    --算移动
    local pixels = Cfg.cfg_aircraft_camera["clickAndDragPixelLength"].Value
    self._startMove = pixels * pixels

    self:OnInit()
end

function UIChooseMainCgController:OnInit()
    self._mousePresent = GameGlobal.EngineInput().mousePresent
    UnityEngine.Input.multiTouchEnabled = true
end

function UIChooseMainCgController:OnHide()
    self._mousePresent = nil
    UnityEngine.Input.multiTouchEnabled = false
    currentEvent = nil
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnShowChangeMainCg,false)
end

function UIChooseMainCgController:saveBtnOnClick(go)
    if self._draging or self._scaling then
        return
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeSave,self._type,UIChooseAssistantState.Save)
    self:CloseDialog()
end
function UIChooseMainCgController:cancelBtnOnClick(go)
    if self._draging or self._scaling then
        return
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeSave,self._type,UIChooseAssistantState.Cancel)
    self:CloseDialog()
end
function UIChooseMainCgController:defaultBtnOnClick(go)
    if self._draging or self._scaling then
        return
    end
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeSave,self._type,UIChooseAssistantState.Default)
    self._startPos = Vector2(0,0)
    self._startScale = 1
    self._defaultPos = self._startPos
    self._defaultScale = self._startScale
end
function UIChooseMainCgController:ChangeScale(scale_off)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangeScale,self._type,scale_off)
end
function UIChooseMainCgController:ChangePos(pos_off)
    local pos2v2 = Vector2(pos_off.x,pos_off.y)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.OnMainCgChangePos,self._type,pos2v2)
end
--防止触发点击bg事件，在ondown时候打开遮罩，up时候去掉
function UIChooseMainCgController:Update(deltaTimeMS)
    if self._mousePresent then
        self:EditorInput(deltaTimeMS*0.001)
    else
        self:TouchInput(deltaTimeMS*0.001)
    end

    self:Animation(deltaTimeMS)
end
function UIChooseMainCgController:Animation(deltaTimeMS)
    self._changePosValue = self._changePosValue + deltaTimeMS*0.001*self._speed
    self._changePosValue2 = self._changePosValue2 - deltaTimeMS*0.001*self._speed
    if self._changePosValue >= 54 then
        self._changePosValue = -54
    end
    if self._changePosValue2 <= -54 then
        self._changePosValue2 = 54
    end
    self._line_down.anchoredPosition = Vector2((self._changePosValue2-54+self._down_offset),0)
    self._line_up.anchoredPosition = Vector2((self._changePosValue-54+self._up_offset),0)
    self._line_left.anchoredPosition = Vector2(0,self._changePosValue-54)
    self._line_right.anchoredPosition = Vector2(0,self._changePosValue2-54+self._right_offset)
end

function UIChooseMainCgController:TouchInput()
    local touchCount = GameGlobal.EngineInput().touchCount
    local touch0 = nil
    if touchCount > 0 then
        touch0 = GameGlobal.EngineInput().GetTouch(0)
    end
    local touch1 = nil
    if touchCount > 1 then
        touch1 = GameGlobal.EngineInput().GetTouch(1)
    end

    if touch0 and touch0.phase == TouchPhase.Began then
        self._touch0DownPos = touch0.position
    end

    --移动
    if not touch1 then
        if touch0 and touch0.phase == TouchPhase.Moved then
            self._touch0Pos = touch0.position
            if self._touch0Pos2 and self._touch0Pos2 ~= 0 and self._touch0Pos2 ~= self._touch0Pos then
                if self._draging == false then
                    if (self._touch0Pos - self._touch0DownPos).sqrMagnitude > self._startMove then
                        self._draging = true
                    end
                end

                local offset = self._touch0Pos - self._touch0Pos2
                local _moveGap = offset * self._moveK
                self:ChangePos(_moveGap)
            end
            self._touch0Pos2 = self._touch0Pos
        end
    end

    if touchCount == 0 then
        self._draging = false
        self._scaling = false

        self._touch0Pos = 0
        self._touch0Pos2 = 0
    end

    --缩放
    if touch1 then
        self._scaling = true
        local lastLength =
            Vector2.Distance(touch0.position - touch0.deltaPosition, touch1.position - touch1.deltaPosition)
        local length = Vector2.Distance(touch0.position, touch1.position)
        local offset = length - lastLength
        local gap = offset * self._touchScaleK

        self:ChangeScale(gap)
    end
end

function UIChooseMainCgController:EditorInput()
    if GameGlobal.EngineInput().GetMouseButtonDown(0) then
        self._mousePos2 = 0
        self._mousePos = 0
        self._mouseDpwnPos = GameGlobal.EngineInput().mousePosition
    end

    --移动
    if GameGlobal.EngineInput().GetMouseButton(0) then
        self._mousePos = GameGlobal.EngineInput().mousePosition
        if self._mousePos2 and self._mousePos2 ~= 0 and self._mousePos2 ~= self._mousePos then
            if self._draging == false then
                if (self._mousePos - self._mouseDpwnPos).sqrMagnitude > self._startMove then
                    self._draging = true
                end
            end

            local offset = self._mousePos - self._mousePos2
            local _moveGap = offset * self._moveK
            self:ChangePos(_moveGap)
        end
        self._mousePos2 = self._mousePos
    end

    --缩放
    self._scaleLength = GameGlobal.EngineInput().GetAxis("Mouse ScrollWheel")
    if self._scaleLength > 0 or self._scaleLength < 0 then
        local gap = self._scaleLength * self._scaleK

        self:ChangeScale(gap)
    end

    if GameGlobal.EngineInput().GetMouseButtonUp(0) then
        self._mousePos2 = 0
        self._mousePos = 0
        if self._draging then
            self._draging = false
        end
    end
end