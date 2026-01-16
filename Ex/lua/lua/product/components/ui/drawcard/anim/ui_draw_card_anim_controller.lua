---@class UIDrawCardAnimController : UIController
_class("UIDrawCardAnimController", UIController)
UIDrawCardAnimController = UIDrawCardAnimController
function UIDrawCardAnimController:OnShow(uiParams)
    self._curLayer = self:GetDepth() - 2
    for i = 0, self._curLayer do
        GameGlobal.UIStateManager().uiControllerManager:ShowLayer(i, false)
    end

    ---@type UIDrawCardViewData
    self.data = uiParams[1]
    self:InitWidget()
    self:InitConfig()

    Log.warn("开始抽卡动画，最高星等：", self.data:GetMaxStar())
    ---@type UIView
    self._finder = UnityEngine.GameObject.Find("LOGICROOT"):GetComponent(typeof(UIView))

    ---@type UIDrawCardAnimOperation
    self._opration = UIDrawCardAnimOperation:New(self._finder)

    --玩家操作状态
    self._operating = false

    self:InitSceneObjects()

    local audio_lights = {
        [ShakeType.SHAKE_ONCE] = CriAudioIDConst.Drawcard_light_one,
        [ShakeType.SHAKE_MULTIPLE] = CriAudioIDConst.Drawcard_light_more
    }

    local audio_light = audio_lights[self.data:GetShakeType()]
    self._opration:Init(
        self._camera,
        self.data:GetMaxStar(),
        function()
            self:SetBtnVisible(true)

            self._timeLinePlayer:Play(self._timeLine2)
            self._light_audio = AudioHelperController.PlayRequestedUISound(audio_light)
        end
    )
    --隐藏跳过按钮
    self:SetBtnVisible(false)

    self:InitTimeLines()

    --直接开始第一段动画
    self._timeLinePlayer:Play(self._timeLine1)
    --切bgm
    UIBgmHelper.PlayDrawcardBgm()
end

function UIDrawCardAnimController:OnHide()
    --锁住成就弹窗先
    ---@type UIFunctionLockModule
    local funcModule = self:GetModule(RoleModule).uiModule
    funcModule:LockAchievementFinishPanel(false)
    for i = 0, self._curLayer do
        GameGlobal.UIStateManager().uiControllerManager:ShowLayer(i, true)
    end
    self._opration:Dispose()

    if self._lightReqs and #self._lightReqs > 0 then
        for _, req in ipairs(self._lightReqs) do
            req:Dispose()
        end
    end

    if self._timeLinePlayer and self._timeLinePlayer:IsPlaying() then
        self._timeLinePlayer:Stop()
        self._timeLinePlayer = nil
    end
end

function UIDrawCardAnimController:OnUpdate(deltaTimeMS)
    self._opration:Update(deltaTimeMS)

    --玩家操作过程中，更新拉杆特效动画
    if self._operating then
        local x = self._handle.eulerAngles.x
        if x > 180 then
            x = x - 360
        end
        local percent = (self._handleStartRot - x) / self._handleAngle
        self._animState.enabled = true
        self._animState.normalizedTime = percent
        self._animState.weight = 1
        self._handleEftAnim:Sample()
        self._animState.enabled = false
    end
end

function UIDrawCardAnimController:InitWidget()
    --generate--
    self._skipBtn = self:GetGameObject("ButtonSkip")
    self._fader = self:GetUIComponent("Animation", "fader")
    self._faderImage = self:GetUIComponent("Image", "fader")
    --generate end--
end

function UIDrawCardAnimController:InitConfig()
    --拉杆两侧动效
    self._handleAnimNames = {
        [3] = "eff_chouka_lagan_charge_1",
        [4] = "eff_chouka_lagan_charge_2",
        [5] = "eff_chouka_lagan_charge_3",
        [6] = "eff_chouka_lagan_charge_4"
    }

    --拉杆下落特效动画
    self._handleFallDownAnim = {
        [3] = "eff_chouka_laganwan_finished_1",
        [4] = "eff_chouka_laganwan_finished_2",
        [5] = "eff_chouka_laganwan_finished_3",
        [6] = "eff_chouka_laganwan_finished_4"
    }

    --光柱配置
    self._lightCfg = {
        [3] = {
            prefab = "eff_chouka_blue.prefab",
            color = Color(0.155, 0.521, 1, 1),
            Y = 2.5,
            W = 20,
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_lanse)
        },
        [4] = {
            prefab = "eff_chouka_purple.prefab",
            color = Color(0.5196, 0.2401, 0.7169, 1),
            Y = 2.5,
            W = 40,
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_zise)
        },
        [5] = {
            prefab = "eff_chouka_gold.prefab",
            color = Color(1, 0.592, 0.231, 1),
            Y = 2.5,
            W = 50,
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_zise)
        },
        [6] = {
            prefab = "eff_chouka_orange.prefab",
            color = Color(1, 0.252, 0.108, 1),
            Y = 2.5,
            W = 60,
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_chengse)
        }
    }

    self._newLightCfg = {
        [3] = {
            prefab = "eff_chouka_blue_new.prefab",
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_lanse)
        },
        [4] = {
            prefab = "eff_chouka_purple_new.prefab",
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_zise)
        },
        [5] = {
            prefab = "eff_chouka_gold_new.prefab",
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_zise)
        },
        [6] = {
            prefab = "eff_chouka_orange_new.prefab",
            audio = AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_chengse)
        }
    }
end

--初始化场景
function UIDrawCardAnimController:InitSceneObjects()
    ---@type UnityEngine.Animation
    self._animation = self:GetSceneGameObject("anim"):GetComponent(typeof(UnityEngine.Animation))
    self._animation.gameObject:SetActive(true)
    ---@type UnityEngine.Camera
    self._camera = self:GetSceneGameObject("Camera"):GetComponent(typeof(UnityEngine.Camera))
    ---@type UnityEngine.Camera
    self._chouKaCam = self:GetSceneGameObject("ChoukaCamera")
    self._chouKaCam:SetActive(true)

    --抽卡远景物体
    self._farSceneGO = self:GetSceneGameObject("choukaPrefab")
    self._farSceneGO:SetActive(false)

    --拉杆
    self._handle = self:GetSceneGameObject("Ckt_Yg").transform
    self._handle.gameObject:SetActive(true)

    --拉杆参数
    self._handleStartRot = Cfg.cfg_drawcard_value[2].Value
    local handleFinishRot = Cfg.cfg_drawcard_value[4].Value
    self._handleAngle = self._handleStartRot - handleFinishRot

    --拉杆特效动画
    ---@type UnityEngine.Animation
    self._handleEftAnim = self._finder:GetUIComponent("Animation", "Chouka_lagan_charge_prefab")

    ---@type UnityEngine.AnimationState
    self._animState = self._handleEftAnim:get_Item(self._handleAnimNames[self.data:GetMaxStar()])
    self._animState.enabled = true
    self._animState.weight = 1
    self._animState.normalizedTime = 0
    self._handleEftAnim:Sample()
    self._animState.enabled = false

    --拉杆下落后的特效
    ---@type UnityEngine.Animation
    self._fallDownAnim = self._finder:GetUIComponent("Animation", "chouka_lagan_prefab")
    self._fallDownAnim.gameObject:SetActive(false)

    self._powerEft = self:GetSceneGameObject("chouka_wunei_prefab")
    self._powerEft:SetActive(false)

    --只有多抽才播光柱动画
    if self.data:GetShakeType() == ShakeType.SHAKE_MULTIPLE then
        self:InitMultipleLight()
    elseif self.data:GetShakeType() == ShakeType.SHAKE_ONCE then
        self:InitSingleLight()
    end
end

--初始化动画时间线
function UIDrawCardAnimController:InitTimeLines()
    ---@type EZTL_Player 时间线播放器
    self._timeLinePlayer = EZTL_Player:New()
    --第一段
    ---@type EZTL_Sequence
    self._timeLine1 =
        EZTL_Sequence:New(
        {
            EZTL_Callback:New(
                function()
                    self._animation:Play("drawcard1")
                end,
                "回调，摄像机动画1，拉近拉杆"
            ),
            EZTL_PlayAudioOnce:New(AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_tuijingtou), "运镜音频"),
            EZTL_Callback:New(
                function()
                    GameGlobal.UAReportForceGuideEvent("UIDrawCardEvent", {"open_camera"}, true)
                    self._camera.gameObject:SetActive(true)
                    self._farSceneGO:SetActive(false)
                end,
                "打开摄像机"
            ),
            -- EZTL_PlayAnimation:New(self._animation, "drawcard1", "摄像机动画1，拉近拉杆"),
            EZTL_Wait:New(2000, "等相机动画播完"),
            EZTL_Callback:New(
                function()
                    self._opration:SetEnable(true)
                    self._operating = true
                end,
                "回调，玩家可操作"
            )
        },
        "抽卡时间线1，串行"
    )

    --第二段
    ---@type EZTL_Sequence
    self._timeLine2 = EZTL_Sequence:New(self:_InitTimeline2(), "抽卡时间线2，串行")
end

function UIDrawCardAnimController:InitSingleLight()
    local renderers =
        self._farSceneGO.transform:Find("global_eff/stage").gameObject:GetComponentsInChildren(
        typeof(UnityEngine.MeshRenderer)
    )
    ---@type table<number,UnityEngine.Material>
    local mats = {}
    for i = 0, renderers.Length - 1 do
        mats[#mats + 1] = renderers[i].sharedMaterial
    end

    for i = 1, 10 do
        local seq = string.format("%02d", i)
        for _, mat in ipairs(mats) do
            mat:SetColor("_PointLightColor" .. seq, Color(0, 0, 0, 0))
        end
    end
end

function UIDrawCardAnimController:InitMultipleLight()
    -- local poolID = self.data:GetPoolID()
    -- local poolCfg = Cfg.cfg_drawcard_pool_view[poolID]
    -- if not poolCfg.MultiplePosition or #poolCfg.MultiplePosition == 0 then
    --     Log.exception("找不到多抽奖池光柱位置，奖池ID：", poolID)
    --     return
    -- end
    -- local random = math.random(#poolCfg.MultiplePosition)
    -- local posCfg = Cfg.cfg_drawcard_position[random].Pos
    -- local cardCount = #self.data:GetCards()
    -- if #posCfg ~= cardCount then
    --     Log.exception("光柱配置数量与卡牌数量不一致，光柱：", #posCfg, "，卡牌：", cardCount)
    --     return
    -- end
    -- local posParent = self._finder:GetUIComponent("Transform", "ChoukaPoint")
    -- if cardCount ~= posParent.childCount then
    --     Log.exception("光柱数量与卡牌数量不一致，光柱：", posParent.childCount, "，卡牌：", cardCount)
    -- end
    -- --加载光柱
    -- local reqs = {}
    -- local lights = {}
    -- local cards = self.data:GetCards()
    -- local qCfgs = {}
    -- for i = 1, cardCount do
    --     ---@type RoleAsset
    --     local card = cards[i]
    --     local pos = posCfg[i]
    --     local star = Cfg.cfg_pet[card.assetid].Star
    --     local qCfg = self._lightCfg[star]
    --     qCfgs[i] = qCfg
    --     local req = ResourceManager:GetInstance():SyncLoadAsset(qCfg.prefab, LoadType.GameObject)
    --     local lightGo = req.Obj
    --     lightGo.transform.position = Vector3(pos[1], 0, pos[2])
    --     lights[i] = lightGo
    --     reqs[i] = req
    -- end
    -- self._lights = lights
    -- self._lightReqs = reqs
    -- --设置点光shader
    -- local shaderColorName = "_PointLightColor"
    -- local shaderPosName = "_PointLight"
    -- local renderers =
    --     self._farSceneGO.transform:Find("global_eff/stage").gameObject:GetComponentsInChildren(
    --     typeof(UnityEngine.MeshRenderer)
    -- )
    -- ---@type table<number,UnityEngine.Material>
    -- local mats = {}
    -- for i = 0, renderers.Length - 1 do
    --     mats[#mats + 1] = renderers[i].sharedMaterial
    -- end
    -- local matParams = {}
    -- for i = 1, 10 do
    --     local seq = string.format("%02d", i)
    --     for _, mat in ipairs(mats) do
    --         if i <= cardCount then
    --             local qCfg = self._lightCfg[Cfg.cfg_pet[cards[i].assetid].Star]
    --             local pos = posCfg[i]
    --             mat:SetColor(shaderColorName .. seq, Color(0, 0, 0, 0))
    --             mat:SetVector(shaderPosName .. seq, Vector4(pos[1], qCfg.Y, pos[2], qCfg.W))
    --             --记录动画需要的数据
    --             matParams[i] = {propertyName = shaderColorName .. seq, targetColor = qCfg.color, audio = qCfg.audio}
    --         else
    --             mat:SetColor(shaderColorName .. seq, Color(0, 0, 0, 0))
    --         end
    --     end
    -- end
    -- self._mats = mats
    -- self._matParams = matParams
end

--初始化第二段动画，单抽多抽不同
function UIDrawCardAnimController:_InitTimeline2()
    local _handleFinishRot = Cfg.cfg_drawcard_value[4].Value
    local _handleFallDuaration = Cfg.cfg_drawcard_value[5].Value

    --前半段一样
    local timeline = {
        EZTL_DOTweenRotate:New(
            self._handle,
            Vector3(_handleFinishRot, 0, 0),
            _handleFallDuaration,
            DG.Tweening.Ease.InCubic,
            "拉杆下落"
        ),
        EZTL_Callback:New(
            function()
                self._operating = false
                AudioHelperController.PlayRequestedUISound(CriAudioIDConst.DrawCard_preshilian)
                AudioHelperController.PlayRequestedUISound(CriAudioIDConst.DrawCard_daodi)

                --下落特效
                self._fallDownAnim.gameObject:SetActive(true)
                self._fallDownAnim:Play(self._handleFallDownAnim[self.data:GetMaxStar()])

                self._animState.enabled = true
                self._animState.normalizedTime = 1
                self._animState.weight = 1
                self._handleEftAnim:Sample()
                self._animState.enabled = false
            end,
            "拉杆下落，运动完成"
        ),
        EZTL_Parallel:New(
            {
                EZTL_PlayAnimation:New(self._animation, "drawcard2", "摄像机动画2，远离拉杆"),
                EZTL_Sequence:New(
                    {
                        EZTL_Wait:New(1600, "光球音效前等待"),
                        EZTL_Callback:New(
                            function()
                                GameGlobal.UAReportForceGuideEvent("UIDrawCardEvent", {"guangqiu"}, true)
                            end,
                            "上报事件"
                        )
                        -- EZTL_PlayAudioOnce:New(
                        --     AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_guangqiu),
                        --     "光球音效"
                        -- )
                    }
                ),
                EZTL_Wait:New(2750, "切视角前等3.7秒")
            },
            EZTL_EndTag.SomeOne,
            3,
            "并行时间线，切换视角并等待"
        ),
        EZTL_Callback:New(
            function()
                self._camera.gameObject:SetActive(false)
                self._farSceneGO:SetActive(true)
            end,
            "切换摄像机"
        )
    }
    timeline[#timeline + 1] = EZTL_Wait:New(200, "大光柱音效延迟")
    -- timeline[#timeline + 1] =
    --     EZTL_PlayAudioOnce:New(AudioHelperController.GetConfigName(CriAudioIDConst.DrawCard_chendi), "大光柱音效")

    if self.data:GetShakeType() == ShakeType.SHAKE_MULTIPLE then
        -- timeline[#timeline + 1] = EZTL_Wait:New(100, "光柱延迟等待")
        timeline[#timeline + 1] =
            EZTL_Callback:New(
            function()
                self._lightReqs = {}
                local cards = self.data:GetCards()
                local posParent = self._finder:GetUIComponent("Transform", "ChoukaPoint")
                for i = 1, #cards do
                    local card = cards[i]
                    local star = Cfg.cfg_pet[card.assetid].Star
                    local qCfg = self._newLightCfg[star]
                    local req = ResourceManager:GetInstance():SyncLoadAsset(qCfg.prefab, LoadType.GameObject)
                    local light = req.Obj.transform
                    local parent = posParent:GetChild(i - 1)
                    light:SetParent(parent)
                    light.localPosition = Vector3.zero
                    light.localRotation = Quaternion.identity
                    light.localScale = Vector3.one
                    light.gameObject:SetActive(true)
                    table.insert(self._lightReqs, req)
                end
            end,
            "同时展示10个光柱"
        )
        timeline[#timeline + 1] = EZTL_Wait:New(370, "显示光柱后等待播音频")
        local max = self.data:GetMaxStar()
        -- timeline[#timeline + 1] = EZTL_PlayAudioOnce:New(self._newLightCfg[max].audio, "播最高星音频")

        -- for i = 1, #self.data:GetCards() do
        --     local light = self._lights[i]
        --     timeline[#timeline + 1] = EZTL_Wait:New(35, "光柱间隔0.035秒" .. i)
        --     timeline[#timeline + 1] =
        --         EZTL_Callback:New(
        --         function()
        --             light:SetActive(true)
        --         end,
        --         "显示光柱" .. i
        --     )

        --     local matParam = self._matParams[i]
        --     local parallel = {}
        --     for idx, mat in ipairs(self._mats) do
        --         local tl = EZTL_MatColor:New(mat, matParam.propertyName, Color(0, 0, 0, 0), matParam.targetColor, 0.5)
        --         parallel[#parallel + 1] = tl
        --     end
        --     parallel[#parallel + 1] = EZTL_PlayAudioOnce:New(matParam.audio)
        --     timeline[#timeline + 1] = EZTL_Parallel:New(parallel, EZTL_EndTag.All, nil, "点光颜色" .. i .. ", 并行")
        -- end
        timeline[#timeline + 1] = EZTL_Wait:New(1500, "最后等1.5秒")
        timeline[#timeline + 1] =
            EZTL_Callback:New(
            function()
                GameGlobal.UAReportForceGuideEvent("UIDrawCardEvent", {"qianzhi"}, true)
            end,
            "上报事件"
        )
        timeline[#timeline + 1] = EZTL_PlayAnimation:New(self._fader, "UIDrawCardAnim_black", "黑屏转场")
    elseif self.data:GetShakeType() == ShakeType.SHAKE_ONCE then
        timeline[#timeline + 1] = EZTL_Wait:New(970, "单抽等待")
        timeline[#timeline + 1] =
            EZTL_Callback:New(
            function()
                GameGlobal.UAReportForceGuideEvent("UIDrawCardEvent", {"qianzhi"}, true)
            end,
            "上报事件"
        )
        timeline[#timeline + 1] = EZTL_PlayAnimation:New(self._fader, "UIDrawCardAnim_white", "白屏转场")
    end
    timeline[#timeline + 1] =
        EZTL_Callback:New(
        function()
            self:AnimFinish(false)
        end,
        "动画结束，跳转界面"
    )
    return timeline
end

function UIDrawCardAnimController:AnimFinish(skip)
    AudioHelperController.StopUISound(self._light_audio)
    local pets = nil
    self:SetBtnVisible(false)
    self._faderImage.color = Color.black
    if skip then
        self._camera.gameObject:SetActive(false)
        pets = self.data:GetUnskipCards()
    else
        pets = self.data:GetCards()
    end
    if #pets == 0 then
        if self.data:GetShakeType() == ShakeType.SHAKE_MULTIPLE then
            --多抽而没有可展示的卡牌
            self:ShowDialog("UIDrawCardMultipleShowController", self.data)
        else
            --单抽跳过卡牌动画，直接展示
            self:ShowDialog(
                "UIPetObtain",
                self.data:GetCards(),
                function()
                    self:Manager():CloseAllDialogOverLayerWithName("UIDrawCardController")
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshRecuitUIView)
                    UIBgmHelper.PlayMainBgm()
                end,
                true
            )
        end
    else
        local afterShow = nil
        if self.data:GetShakeType() == ShakeType.SHAKE_MULTIPLE then
            afterShow = function()
                self:ShowDialog("UIDrawCardMultipleShowController", self.data)
                self:Manager():CloseDialog("UIPetObtain")
            end
        else
            afterShow = function()
                self:Manager():CloseAllDialogOverLayerWithName("UIDrawCardController")
                GameGlobal.EventDispatcher():Dispatch(GameEventType.RefreshRecuitUIView)
                UIBgmHelper.PlayMainBgm()
            end
        end
        self:ShowDialog("UIPetObtain", pets, afterShow)
        self._chouKaCam:SetActive(false)
    end
end

function UIDrawCardAnimController:ButtonSkipOnClick(go)
    self._timeLinePlayer:Stop()
    self:AnimFinish(true)
end

function UIDrawCardAnimController:SetBtnVisible(_show)
    self._skipBtn:SetActive(_show)
end

function UIDrawCardAnimController:GetSceneGameObject(name)
    return self._finder:GetGameObject(name)
end

-------------------------------------------------------------------------------------
