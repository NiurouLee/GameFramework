--[[
    6星卡牌获得展示
]]
require "pet_obtain_anim_base"

---@class PetObtainAnim6Star:PetObtainAnimBase
_class("PetObtainAnim6Star", PetObtainAnimBase)
PetObtainAnim6Star = PetObtainAnim6Star

function PetObtainAnim6Star:Constructor(pet, anim, atlas, uiStars, uiDepth, matAnim)
    ---@type ObtainPet
    self._pet = pet
    self._petID = self._pet:PetID()
    ---@type UnityEngine.Animation
    self._anim = anim
    self._atlas = atlas
    self._uiStars = uiStars
    self._depth = uiDepth
    self._matAnim = matAnim

    ---@type PetAudioModule
    self._petAudioModule = GameGlobal.GetModule(PetAudioModule)

    self._audios = {
        {CriAudioIDConst.Drawcard_pet_obtain_6, -1},
        {1213, 100},
        {1216, 2650},
        {1205, 3400},
        {1204, 6400},
        {1214, 7400}
    }
    self._audioPlayers = {}
    self._disposed = false
end

function PetObtainAnim6Star:Prepare()
    if self._state ~= ObtainAnimState.Wait then
        return
    end

    local cfg = Cfg.cfg_pet[self._petID]
    local tag = cfg.Tags[1] --阵营
    local bgMat = {
        [PetFilterType.BaiYeCheng] = "JQ_BGShangcheng",
        [PetFilterType.BaiYeXiaCheng] = "bg_baiyexiacheng", --
        [PetFilterType.QiGuang] = "JQ_BGEnlightment4",
        [PetFilterType.BeiJing] = "bg_beijing", --
        [PetFilterType.HongYouBanShou] = "JQ_BGRediesel2",
        [PetFilterType.TaiYangJiaoTuan] = "bg_zhenlijieshe", --
        [PetFilterType.YouMin] = "zjm_BG02"
    }

    self._assetName = {}
    self._assetName.Root = "uieff_Chouka_6_P1"
    self._assetName.PetLogo = cfg.Logo
    self._assetName.Logo1 = "1001_force_logo"
    self._assetName.Logo2 = "1003_force_logo"
    self._assetName.Logo3 = "1002_force_logo"
    self._assetName.Logo4 = "1004_force_logo"
    self._assetName.Logo5 = "1006_force_logo"
    self._assetName.Logo6 = "1005_force_logo"
    self._assetName.P3 = "chouka_6star_" .. self._petID
    local bgCfg = Cfg.cfg_drawcard_6_star_bg[self._petID]
    if bgCfg then
        self._assetName.ZhenYingBG = bgCfg.BG
    else
        self._assetName.ZhenYingBG = bgMat[tag]
    end

    for index, value in ipairs(self._audios) do
        AudioHelperController.RequestUISoundSync(value[1]) --同步缓存所有音频
    end
    self._cacheAudioReady = true

    if self._isFirst then
        self._state = ObtainAnimState.Prepare
        self:LoadAsset(self._assetName.Root, LoadType.GameObject)
        self:LoadAsset(self._assetName.PetLogo, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo1, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo2, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo3, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo4, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo5, LoadType.Mat)
        self:LoadAsset(self._assetName.Logo6, LoadType.Mat)
        self:LoadAsset(self._assetName.P3, LoadType.GameObject)
        self:LoadAsset(self._assetName.ZhenYingBG, LoadType.Mat)
        self._state = ObtainAnimState.Ready
    else
        GameGlobal:TaskManager():StartTask(self._load, self)
    end
end

function PetObtainAnim6Star:_load(TT)
    self._state = ObtainAnimState.Prepare
    self:LoadAssetAsync(TT, self._assetName.Root, LoadType.GameObject)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.PetLogo, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo1, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo2, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo3, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo4, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo5, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.Logo6, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.P3, LoadType.GameObject)
    if self:CheckClosed() then
        return
    end
    self:LoadAssetAsync(TT, self._assetName.ZhenYingBG, LoadType.Mat)
    if self:CheckClosed() then
        return
    end
    self._state = ObtainAnimState.Ready
end

function PetObtainAnim6Star:Start()
    self._anim:Play("uieff_uipetobtain_hide")
    self:checkReady()
end

function PetObtainAnim6Star:checkReady()
    if self._state == ObtainAnimState.Ready then
        self._state = ObtainAnimState.Playing

        Log.debug("6星卡牌展示开始:", self._petID)
        self._eff = self:GetAsset(self._assetName.Root)
        self._eff:SetActive(true)
        local cfg = Cfg.cfg_pet[self._petID]
        ---@type UIView
        local uiView = self._eff:GetComponent(typeof(UIView))

        --设置相机深度
        self:OnUIDepthChanged(self._depth)

        local en1 = uiView:GetUIComponent("UILocalizationText", "En1")
        local en2 = uiView:GetUIComponent("UILocalizationText", "En2")
        local en3 = uiView:GetUIComponent("UILocalizationText", "En3")
        local en4 = uiView:GetUIComponent("UILocalizationText", "En4")
        ---@type TypewriterText
        local cn1 = uiView:GetUIComponent("TypewriterText", "Cn1")
        local cn2 = uiView:GetUIComponent("UILocalizationText", "Cn2")
        local en6 = uiView:GetUIComponent("UILocalizationText", "En6")

        en1:SetText(StringTable.Get(cfg.EnglishName))
        en2:SetText(StringTable.Get(cfg.EnglishName))
        en3:SetText(StringTable.Get(cfg.NickName))
        en4:SetText(StringTable.Get(cfg.NickName))
        local lang = Localization.GetCurLanguage()
        if lang == LanguageType.jp then
            --日文1个空格
            cn2:SetText(PetObtainHelper.InsertChar(StringTable.Get(cfg.ChinaTag), " "))
        else
            --其他版本2个空格，英文不会显示
            cn2:SetText(PetObtainHelper.InsertChar(StringTable.Get(cfg.ChinaTag), "  "))
        end
        en6:SetText(StringTable.Get(cfg.NickName))

        local videos = {
            [PetFilterType.BaiYeCheng] = "chouka_byc.mp4",
            [PetFilterType.BaiYeXiaCheng] = "chouka_byxc.mp4",
            [PetFilterType.QiGuang] = "chouka_qg.mp4",
            [PetFilterType.BeiJing] = "chouka_bj.mp4",
            [PetFilterType.HongYouBanShou] = "chouka_hybs.mp4",
            [PetFilterType.TaiYangJiaoTuan] = "chouka_zljs.mp4",
            [PetFilterType.YouMin] = "chouka_wzy.mp4"
        }

        local bgMat = {
            [PetFilterType.BaiYeCheng] = "JQ_BGShangcheng.mat",
            [PetFilterType.BaiYeXiaCheng] = "bg_baiyexiacheng.mat", --
            [PetFilterType.QiGuang] = "JQ_BGEnlightment4.mat",
            [PetFilterType.BeiJing] = "bg_beijing.mat", --
            [PetFilterType.HongYouBanShou] = "JQ_BGRediesel2.mat",
            [PetFilterType.TaiYangJiaoTuan] = "bg_zhenlijieshe.mat", --
            [PetFilterType.YouMin] = "bg_wuzhenying.mat"
        }

        local logoMat = self:GetAsset(self._assetName.PetLogo)
        local tag = cfg.Tags[1] --阵营
        -- tag = PetFilterType.YouMin
        ---@type UnityEngine.Video.VideoPlayer
        local mov = nil
        local ym_logo_parent = uiView:GetGameObject("Logo_parent_ym")
        if tag == PetFilterType.YouMin then
            --无阵营
            mov = uiView:GetUIComponent("VideoPlayer", "Mov_ym")
            local ym_logo = uiView:GetUIComponent("MeshRenderer", "Logo_ym")
            ym_logo.sharedMaterial:SetTexture("_MainTex", logoMat:GetTexture("_MainTex"))
            ym_logo_parent:SetActive(true)
        else
            mov = uiView:GetUIComponent("VideoPlayer", "Mov")
            ym_logo_parent:SetActive(false)
        end

        local url = HelperProxy:GetInstance():GetVideoUrl(videos[tag])
        if url == nil then
            url = HelperProxy:GetInstance():GetVideoUrl(videos[PetFilterType.QiGuang])
            Log.fatal("暂时找不到阵营视频，用启光代替：", tag)
        end
        mov.url = url
        mov:Prepare()
        mov.gameObject:SetActive(true)

        ---@type UnityEngine.MeshRenderer
        local mr = uiView:GetUIComponent("MeshRenderer", "Logo")
        mr.sharedMaterial:SetTexture("_MainTex", logoMat:GetTexture("_MainTex"))

        uiView:GetUIComponent("MeshRenderer", "logo1").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo1):GetTexture("_MainTex")
        )
        uiView:GetUIComponent("MeshRenderer", "logo2").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo2):GetTexture("_MainTex")
        )
        uiView:GetUIComponent("MeshRenderer", "logo3").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo3):GetTexture("_MainTex")
        )
        uiView:GetUIComponent("MeshRenderer", "logo4").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo4):GetTexture("_MainTex")
        )
        uiView:GetUIComponent("MeshRenderer", "logo5").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo5):GetTexture("_MainTex")
        )
        uiView:GetUIComponent("MeshRenderer", "logo6").sharedMaterial:SetTexture(
            "_MainTex",
            self:GetAsset(self._assetName.Logo6):GetTexture("_MainTex")
        )

        --p3部分，每个星灵单独设置
        local p3 = self:GetAsset(self._assetName.P3)
        if p3 == nil then
            Log.fatal("找不到spine的timeline动画，使用樱龙使:", self._petID)
            --为了正常执行，同步加载1个
            p3 = self:LoadAsset("chouka_6star_1600021.prefab", LoadType.GameObject)
        end
        local t = p3.transform
        t:SetParent(uiView:GetUIComponent("Transform", "P3Root"))
        t.localPosition = Vector3(0, -100, 0)
        -- t.localRotation = Quaternion.identity
        -- t.localScale = Vector3.one
        p3:SetActive(true)
        ---@type UIView
        local p3View = p3:GetComponent(typeof(UIView))
        ---@type UnityEngine.AI.NavMesh
        local bgMr = p3View:GetUIComponent("MeshRenderer", "bg")
        local zhenyingBG = self:GetAsset(self._assetName.ZhenYingBG)
        bgMr.sharedMaterial:SetTexture("_MainTex", zhenyingBG:GetTexture("_MainTex"))

        --p3end

        ---@type UIView
        self._petObtain = uiView:GetUIComponent("UIView", "UIPetObtain")
        self:InitData()

        --适配相关
        --rt
        local width = UnityEngine.Screen.width
        local height = UnityEngine.Screen.height
        local rt = UnityEngine.RenderTexture:New(width, height, 16)
        local p3Cam = uiView:GetUIComponent("Camera", "P3Camera")
        p3Cam.targetTexture = rt
        local transPlaneMr = uiView:GetUIComponent("MeshRenderer", "TransPlane")
        transPlaneMr.sharedMaterial:SetTexture("_MainTex", rt)
        transPlaneMr.transform.localScale = Vector3(width / height * 10, 10, 1)
        local cgMid = self._petObtain:GetUIComponent("RawImage", "cgMid")
        cgMid.texture = rt
        self._renderTexture = rt

        local canvasT = uiView:GetUIComponent("Transform", "Canvas")
        local scale = width / height / 1.77777
        canvasT.localScale = Vector3(scale, scale, scale)

        --时间线
        local tls = {}
        tls[#tls + 1] = EZTL_Wait:New(2000, "先等2.0秒")
        tls[#tls + 1] =
            EZTL_Callback:New(
            function()
                cn1:RefreshText(StringTable.Get(cfg.Name))
            end,
            "打字机效果展示卡牌名称"
        )
        tls[#tls + 1] = EZTL_RandomText:New(en4, StringTable.Get(cfg.NickName), 850, "随机滚动文本")
        tls[#tls + 1] = EZTL_Wait:New(5700, "再等3.7秒")
        local tl1 = EZTL_Sequence:New(tls, "6星卡牌时间线1，串行")

        --6星
        local tl2_tls = {
            EZTL_Wait:New(8433, "等8.433s显示重复获得材料"),
            EZTL_Callback:New(
                function()
                    self._anim:Play("uieff_Card_PetObtain_6")
                    self._petAudioModule:PlayPetAudio("Obtain", self._petID)
                end,
                "ui动效"
            )
        }
        tl2_tls[#tl2_tls + 1] = EZTL_Wait:New(100, "出现星星前等0.1s")
        for i = 1, 6 do
            local star = self._uiStars:GetChild(i - 1).gameObject
            star:SetActive(false)
            tl2_tls[#tl2_tls + 1] =
                EZTL_Callback:New(
                function()
                    star:SetActive(true)
                end,
                "显示第" .. i .. "个星星"
            )
            tl2_tls[#tl2_tls + 1] = EZTL_Wait:New(33, "等33ms")
        end
        self._matAnim:SetActive(false)
        --重复获得
        if not self._pet:IsNew() then
            tl2_tls[#tl2_tls + 1] =
                EZTL_Callback:New(
                function()
                    self._matAnim:SetActive(true)
                end,
                "播放重复获得材料动画"
            )
        end
        tl2_tls[#tl2_tls + 1] = EZTL_Wait:New(1500, "再等1.5s")
        local tl2 = EZTL_Sequence:New(tl2_tls, "6星抽卡时间线2")

        -- local audioTl = {}
        -- audioTl[#audioTl + 1] = EZTL_PlayAudioByID:New(1213, 100)
        -- audioTl[#audioTl + 1] = EZTL_PlayAudioByID:New(1216, 2650)
        -- audioTl[#audioTl + 1] = EZTL_PlayAudioByID:New(1205, 3400)
        -- audioTl[#audioTl + 1] = EZTL_PlayAudioByID:New(1204, 6400)
        -- audioTl[#audioTl + 1] = EZTL_PlayAudioByID:New(1214, 7400)
        -- local tl3 = EZTL_Parallel:New(audioTl, EZTL_EndTag.All, nil, "6星抽卡音效时间线")

        GameGlobal:TaskManager():StartTask(self._audioTask, self)

        self._tl = EZTL_Parallel:New({tl1, tl2}, EZTL_EndTag.All, nil, "6星抽卡总时间线，并行")
        self._tl:Start()

        self._running = true
    end
end

function PetObtainAnim6Star:Update(dtMS)
    if self._state == ObtainAnimState.Playing then
        self._tl:Update(dtMS)
        if self._tl:Over() then
            self._state = ObtainAnimState.Finished
        end
    elseif self._state == ObtainAnimState.Prepare or self._state == ObtainAnimState.Ready then
        self:checkReady()
    end
end

function PetObtainAnim6Star:IsOver()
    return self._state == ObtainAnimState.Finished
end

function PetObtainAnim6Star:Dispose()
    if self._state == ObtainAnimState.Wait then
    elseif self._state == ObtainAnimState.Prepare then
        self._state = ObtainAnimState.Closed
        self:ReleaseAsset()
    elseif self._state == ObtainAnimState.Ready then
        self:ReleaseAsset()
    elseif self._state == ObtainAnimState.Playing then
        self._tl:Stop()
        self:ReleaseAsset()
        self._renderTexture:Release()
    elseif self._state == ObtainAnimState.Finished then
        self:ReleaseAsset()
        self._renderTexture:Release()
    elseif self._state == ObtainAnimState.Closed then
    end

    self._petAudioModule:StopAll()

    for index, value in ipairs(self._audioPlayers) do
        AudioHelperController.StopUISound(value)
    end
    self._audioPlayers = nil

    if self._cacheAudioReady then
        for index, value in ipairs(self._audios) do
            AudioHelperController.ReleaseUISoundById(value[1])
        end
    end

    self._disposed = true
end

function PetObtainAnim6Star:InitData()
    ---@type SpineLoader
    self._spine = self._petObtain:GetUIComponent("SpineLoader", "spine")
    self._spineRect = self._petObtain:GetUIComponent("RectTransform", "spine")

    ---@type PetModule
    local petModule = GameGlobal.GetModule(PetModule)
    local petId = self._petID
    --local cfgv = Cfg.cfg_pet[petId]
    local spine = self:_GetSpine(self._pet)
    self._spine:LoadSpine(spine)
    UICG.SetTransform(self._spineRect, "UIPetObtain", spine)
end
function PetObtainAnim6Star:_GetSpine(obtainPet)
    if obtainPet then
        if obtainPet:SkinID() > 0 then
            local cfgv = Cfg.cfg_pet_skin[obtainPet:SkinID()]
            if cfgv then
                return cfgv.Spine
            end
        else
            local spine = HelperProxy:GetInstance():GetPetSpine(obtainPet:PetID(), 0, 0, PetSkinEffectPath.NO_EFFECT)
            if spine then
                return spine
            end
        end
    end
    return ""
end

function PetObtainAnim6Star:OnUIDepthChanged(depth)
    depth = depth * 10
    ---@type UIView
    local uiView = self._eff:GetComponent(typeof(UIView))

    local cam = uiView:GetUIComponent("Camera", "Camera1")
    cam.depth = depth + 2
    cam = uiView:GetUIComponent("Camera", "Camera2")
    cam.depth = depth + 3
    cam = uiView:GetUIComponent("Camera", "Camera3")
    cam.depth = depth + 3
    cam = uiView:GetUIComponent("Camera", "Camera4")
    cam.depth = depth + 3
    cam = uiView:GetUIComponent("Camera", "Camera5")
    cam.depth = depth + 1

    local p3 = self:GetAsset(self._assetName.P3)
    local t = p3.transform
    local p3Cam1 = t:Find("Camera").gameObject:GetComponent("Camera")
    p3Cam1.depth = depth + 1
    local p3Cam2 = p3Cam1.transform:GetChild(0).gameObject:GetComponent("Camera")
    p3Cam2.depth = depth + 2
end

function PetObtainAnim6Star:_audioTask(TT)
    local timeModule = GameGlobal.GetModule(SvrTimeModule)
    local start = timeModule:GetServerTime()
    for index, value in ipairs(self._audios) do
        local id = value[1]
        local time = math.max(0, math.floor(value[2] - (timeModule:GetServerTime() - start)))
        YIELD(TT, time)
        if self._disposed then
            return
        end
        table.insert(self._audioPlayers, AudioHelperController.PlayRequestedUISound(id))
    end
end
