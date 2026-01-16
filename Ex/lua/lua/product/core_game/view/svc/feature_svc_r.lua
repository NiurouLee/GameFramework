--[[------------------------------------------------------------------------------------------
    FeatureServiceRender: 模块 表现
]] --------------------------------------------------------------------------------------------

_class("FeatureServiceRender", BaseService)
---@class FeatureServiceRender:BaseService
FeatureServiceRender = FeatureServiceRender

function FeatureServiceRender:Dispose()
    self:_ResetDayNightShaderParam()
end
function FeatureServiceRender:OnBattleEnter(TT)
    self:_ResetDayNightShaderParam()
    self:_InitUIFeatureList(TT)
end
---通知ui初始化列表
function FeatureServiceRender:_InitUIFeatureList(TT)
    --临时
    local featureInitList = {}
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    featureInitList = utilData:GetFeatureUiInitData()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FeatureListInit,featureInitList)
end
---roundEnter
function FeatureServiceRender:DoFeatureOnRoundEnter(TT)
    ---@type Entity
    local renderBoardEntity = self._world:GetRenderBoardEntity()
    ---@type RenderFeatureComponent
    local renderFeature = renderBoardEntity:RenderFeature()
    if renderFeature then
        local info = renderFeature:GetCurRoundDecreaseSanValue(1)
        if info then
            self:NotifySanValueChange(info.cur,info.old,info.modify)
            ---@type PlayBuffService
            local svcPlayBuff = self._world:GetService("PlayBuff")
            svcPlayBuff:PlayBuffView(TT, NTSanValueChange:New(info.cur,info.old,info.debt,info._modifyTimes))
        end
        local dayNightInfo = renderFeature:GetCurRoundDayNightRouncChangeValue(1)
        if dayNightInfo then
            self:NotifyDayNightDataChange(dayNightInfo._curState,dayNightInfo._restRound)
            ---@type PlayBuffService
            local svcPlayBuff = self._world:GetService("PlayBuff")
            if dayNightInfo._curState ~= dayNightInfo._oldState then
                --场景效果
                self:_DoSceneSwitchDayNight(TT,dayNightInfo._curState)
                svcPlayBuff:PlayBuffView(TT, NTDayNightStateChange:New(dayNightInfo._curState,dayNightInfo._oldState))
            end
        end
    end
end
---场景 昼夜切换
function FeatureServiceRender:_DoSceneSwitchDayNight(TT,toState)
    local goRenderSetting = UnityEngine.GameObject.Find("[H3DRenderSetting]")
    if goRenderSetting then
        ---@type UnityEngine.Animation
        local anim = goRenderSetting:GetComponent("Animation")
        local animName = "anim_jdzz_daylight"
        local duration = 1
        local oldVal = 0
        local newVal = 1
        local effId
        if toState == FeatureDayNightState.Day then
            animName = "anim_jdzz_daylight"
            oldVal = 0
            newVal = 1
            effId = BattleConst.DayNightToDayDefaultEffID
        else
            animName = "anim_jdzz_nightlight"
            oldVal = 1
            newVal = 0
            effId = BattleConst.DayNightToNightDefaultEffID
        end
        ---@type UtilDataServiceShare
        local utilDataSvc = self._world:GetService("UtilData")
        local posCenter = utilDataSvc:GetBoardCenterPos()
        ---@type EffectService
        local serEffect = self._world:GetService("Effect")
        serEffect:CreateWorldPositionEffect(effId,posCenter,true)
        YIELD(TT,500)
        if anim then
            anim:Play(animName)
        end
        DoTweenHelper.DoUpdateFloat(oldVal,newVal,duration,
        function(percent)
            UnityEngine.Shader.SetGlobalFloat("_LightmapSwitch",percent)
        end
        )
    end
end
--buff用 修改昼夜
function FeatureServiceRender:ModifyDayNightData(TT,oldState,newState,restRound)
    Log.debug("Feature render,buff modify dayNight, oldState:",oldState," newState:",newState," restRound:",restRound)
    self:NotifyDayNightDataChange(newState,restRound)
    ---@type PlayBuffService
    local svcPlayBuff = self._world:GetService("PlayBuff")
    if newState ~= oldState then
        --场景效果
        self:_DoSceneSwitchDayNight(TT,newState)
        svcPlayBuff:PlayBuffView(TT, NTDayNightStateChange:New(newState,oldState))
    end
end
---昼夜场景 shader 参数 重置
function FeatureServiceRender:_ResetDayNightShaderParam()
    UnityEngine.Shader.SetGlobalFloat("_LightmapSwitch",1)--昼夜场景
end
---通知UI san值变化
function FeatureServiceRender:NotifySanValueChange(curValue,oldValue,modifyValue)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FeatureSanValueChange,curValue,oldValue,modifyValue)
    --屏幕特效
    self:_SanScreenEffOnValueChange(curValue,oldValue,modifyValue)
end
---San系统 屏幕特效处理
function FeatureServiceRender:_SanScreenEffOnValueChange(curValue,oldValue,modifyValue)
    --屏幕特效
    local effStartSan = self:_GetSanViewEffStartVal()
    if self._sanScreenEffEntity then
        if curValue > effStartSan then --取消特效
            if self._sanScreenEffGo then
                self._sanScreenEffGo:SetActive(false)
            end
        else
            --设置强度
            self:_UpdateSanScreenEff(curValue)
        end
    else
        if curValue <= effStartSan then
            self:_CreateSanScreenEff()
            --设置强度
            self:_UpdateSanScreenEff(curValue)
        end
    end
end
---San 屏幕特效
function FeatureServiceRender:_CreateSanScreenEff()
    if self._sanScreenEffEntity then
        return
    end
    ---@type EffectService
    local serEffect = self._world:GetService("Effect")
    self._sanScreenEffEntity = serEffect:CreateScreenEffPointEffect(BattleConst.SanCameraEffID)
    if self._sanScreenEffEntity then
        self._sanScreenEffGo = self._sanScreenEffEntity:View():GetGameObject()
        self._sanEffAnim = self._sanScreenEffGo:GetComponent("Animation")
        if self._sanEffAnim then
            self._sanEffAnimState = self._sanEffAnim:get_Item("uieffanim_FeatureSan_Camera")
        end
    end
end
---San 屏幕特效
function FeatureServiceRender:_UpdateSanScreenEff(curVal)
    local topVal = self:_GetSanViewEffStartVal()
    local bottomVal = 0
    local rangeVal = topVal - bottomVal
    if rangeVal < 0 then
        return
    end
    if self._sanScreenEffGo then
        self._sanScreenEffGo:SetActive(true)
    end
    if self._sanEffAnim and self._sanEffAnimState then
        --设置强度
        local percent = curVal / rangeVal
        local animPercent = 1 - percent
        self._sanEffAnimState.enabled = true
        self._sanEffAnimState.normalizedTime = animPercent
        self._sanEffAnimState.weight = 1
        self._sanEffAnim:Sample()
        self._sanEffAnimState.enabled = false
    end
end
---San系统 屏幕特效开始出现的值
function FeatureServiceRender:_GetSanViewEffStartVal()
    if not self._sanViewEffStartVal then
        ---@type FeatureEffectParamSan
        local sanData = FeatureServiceHelper.GetFeatureData(FeatureType.Sanity)
        if sanData then
            local sanityParam = sanData:GetSanityParam()
            if sanityParam then
                local viewStartVal = sanityParam.viewEffStartVal
                if not viewStartVal then
                    viewStartVal = BattleConst.SanViewEffDefaultStartVal
                end
                self._sanViewEffStartVal = viewStartVal
            end
        end
    end
    return self._sanViewEffStartVal
end
---通知UI 昼夜状态、回合数变化
function FeatureServiceRender:NotifyDayNightDataChange(state,restRound)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FeatureDayNightRefresh,state,restRound)
end
---通知UI 昼夜ui样式变化（夜王）
function FeatureServiceRender:NotifyDayNightUIStyleChange(uiStyle)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FeatureDayNightChangeUIStyle,uiStyle)
end
---Check if player can cast one active skill by previewing-level data
---@param casterEntity Entity caster entity
---@param skillID number ID of an active skill which is SkillTriggerType.San
---@param previewContext SkillPreviewContext current preview context
---@return boolean
function FeatureServiceRender:IsActiveSkillCanCastInPreview(casterEntity, skillID, previewContext)
    ---@type FeatureSanActiveSkillCanCastContext
    local context = {}
    local previewAttackGridList = previewContext:GetScopeResult() or {}
    context.scopeGridCount = #previewAttackGridList

    return FeatureServiceHelper.IsActiveSkillCanCast(casterEntity, skillID, context)
end
function FeatureServiceRender:NotifyFeatureSkillPowerChange(featureType,curPower,curReady)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.PersonaPowerChange,featureType, curPower, curReady)
end