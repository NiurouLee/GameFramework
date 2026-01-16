--[[
    风船娱乐区房间解锁动画
]]
---@class AirAnimRoomUnlock:Object
_class("AirAnimRoomUnlock", Object)
AirAnimRoomUnlock = AirAnimRoomUnlock

local index = 3

function AirAnimRoomUnlock:Constructor(main, spaceID, onFinish, test)
    ---@type AircraftMain
    self._main = main
    -- if test then
    --     spaceID = index
    --     index = index + 1
    --     if index > 5 then
    --         index = 2
    --     end
    -- end
    self._spaceID = spaceID
    self._onFinish = onFinish
    self._test = test or false
    self._player = EZTL_Player:New()
end
function AirAnimRoomUnlock:Play()
    --[[
        1.相机聚焦到房间
        2.播放解锁特效
        3.显示房间ui
    ]]
    AirLog("开始休息区房间解锁动画：", self._spaceID)
    --锁定屏幕
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AirAnimRoomUnlock")
    --隐藏ui
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)

    ---@type UnityEngine.Camera
    local camera = self._main:GetMainCamera()
    local oldMask = camera.cullingMask
    self._main:SetHudCameraActive(false)
    --摄像机过滤星灵
    camera.cullingMask = oldMask & ~(1 << AircraftLayer.Pet)
    --这里获取的room实际上是旧的，但不影响相机位置
    local room = self._main:GetRoomBySpaceID(self._spaceID)
    if self._test then
        room:LoadLastGameObject()
    end
    --相机聚焦到房间
    self._main:FocusRoomToAnimate(room, nil, 700)
    ---
    local reqs = {}
    local loadEff = function(name)
        local req = ResourceManager:GetInstance():SyncLoadAsset(name .. ".prefab", LoadType.GameObject)
        if not req then
            Log.exception("加载不到特效：", name)
        end
        reqs[#reqs + 1] = req
        local go = req.Obj
        return go
    end
    --后处理
    local postEff = loadEff("eff_aircraft_PostProcess_Plane")
    --光虫
    local fireflys = {}
    local fireflyTrans = room:GetFirflys(self._test)
    if fireflyTrans then
        for i, fireT in ipairs(fireflyTrans) do
            --只加载不播放
            local firefly = loadEff("eff_aircraft_guangchong1")
            firefly.transform.position = fireT.position
            firefly.transform.rotation = fireT.rotation
            firefly.transform.localScale = Vector3.one
            fireflys[i] = firefly
        end
    end
    --关窗动画
    local closeWindow = loadEff("eff_aircraft_window")
    local windowT = closeWindow.transform
    local wind = room:GetWindow(self._test)
    -- windowT:SetParent(wind)
    windowT.position = wind.position + Vector3(1.86, 0.09, 6.11)
    windowT.rotation = wind.rotation
    windowT.localScale = wind.localScale

    local req = ResourceManager:GetInstance():SyncLoadAsset("eff_aircraft_BrightObject.mat", LoadType.Mat)
    reqs[#reqs + 1] = req
    --家具材质
    local furMat = req.Obj
    --家具新材质参数
    furMat:SetFloat("_Dissolve", 2)
    furMat:SetFloat("_Alpha", 1)

    --所有家具的材质
    local renderMats = {}
    local blur = nil

    local enTips = {
        [AirRestAreaType.RestRoom] = "str_aircraft_unlock_restroom",
        [AirRestAreaType.EntertainmentRoom] = "str_aircraft_unlock_gameroom",
        [AirRestAreaType.Bar] = "str_aircraft_unlock_bar",
        [AirRestAreaType.CoffeeHouse] = "str_aircraft_unlock_coffeehouse"
    }
    local enTip = enTips[room:Area()]

    local tls = {}
    tls[#tls + 1] = EZTL_Wait:New(700, "相机聚焦，先等0.7s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            postEff.transform:SetParent(camera.transform)
            postEff.transform.localPosition = Vector3(0, 0, 13.6)
            postEff.transform.localRotation = Quaternion.Euler(-90, 0, 0)
            postEff.transform.localScale = Vector3.one
            postEff:SetActive(true)

            closeWindow:SetActive(true)

            local anim = postEff:GetComponent(typeof(UnityEngine.Animation))
            anim:Play("eff_aircraft_PostProcess")
        end,
        "打开相机遮罩，播放关窗动画"
    )
    tls[#tls + 1] = EZTL_Wait:New(1000, "关窗等1s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            GameObjectHelper.SetGameObjectLayer(postEff, AircraftLayer.Pet)

            ---@type H3DUIBlurHelper
            blur = camera.gameObject:AddComponent(typeof(H3DUIBlurHelper))
            blur.OwnerCamera = camera
            blur.UseAllCamerasCapture = true
            local rt = blur:BlurTexture(UnityEngine.Screen.width, UnityEngine.Screen.height, 0)
            local meshRender = postEff:GetComponent(typeof(UnityEngine.MeshRenderer))
            meshRender.sharedMaterial:SetTexture("_CutTex", rt)

            GameObjectHelper.SetGameObjectLayer(postEff, AircraftLayer.Default)
        end,
        "截屏"
    )
    tls[#tls + 1] = EZTL_Wait:New(200, "截屏后等0.2s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            --替换房间模型
            if self._test then
                room:SwitchToNow()
            else
                self._main:RefreshRestRoom(self._spaceID)
            end
            --逻辑，刷新区域家具
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRefreshDecorateArea, self._spaceID)

            -- local newRoom = self._main:GetRoomBySpaceID(self._spaceID)
            -- local furs = newRoom:GetAllFurniture()
            local furs = self._main:GetFurnituresBySpace(self._spaceID)
            for _, fur in ipairs(furs) do
                --隐藏所有特效
                fur:SetEffectActive(false)
            end

            for _, firefly in ipairs(fireflys) do
                --播放光虫动画
                firefly:SetActive(true)
            end

            for _, fur in ipairs(furs) do
                local meshRenders = fur:Transform().gameObject:GetComponentsInChildren(typeof(UnityEngine.Renderer))
                if meshRenders and meshRenders.Length > 0 then
                    for i = 0, meshRenders.Length - 1 do
                        local render = meshRenders[i]
                        local mats = render.materials
                        --按顺序暂存所有家具材质
                        local oldMats = {}
                        for j = 0, mats.Length - 1 do
                            oldMats[j + 1] = mats[j]
                            mats[j] = furMat
                        end
                        render.materials = mats
                        renderMats[render] = oldMats
                    end
                end
            end
        end,
        "替换房间、家具换材质"
    )
    tls[#tls + 1] = EZTL_Wait:New(2800, "等2.8s")
    tls[#tls + 1] = EZTL_MatFloat:New(furMat, "_Dissolve", 0, 2000, "材质Dissolve参数到0，时长2s")
    tls[#tls + 1] = EZTL_Wait:New(1700, "材质Dissolve动画后等1.7s")
    tls[#tls + 1] = EZTL_MatFloat:New(furMat, "_Alpha", 0, 500, "材质Alpha动画，0.5s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            --家具恢复材质
            AirLog("恢复家具材质")
            for render, mats in pairs(renderMats) do
                AirLog("恢复的家具render:", render.name)
                local ms = render.materials
                for i = 0, ms.Length - 1 do
                    ms[i] = mats[i + 1]
                end
                -- for i = 1, #mats do
                --     ms[i - 1] = mats[i]
                -- end
                render.materials = ms
            end
            --相机恢复mask
            camera.cullingMask = oldMask
            self._main:SetHudCameraActive(true)

            -- local room = self._main:GetRoomBySpaceID(self._spaceID)
            -- local furs = room:GetAllFurniture()
            local furs = self._main:GetFurnituresBySpace(self._spaceID)
            for _, fur in ipairs(furs) do
                --显示所有特效
                fur:SetEffectActive(true)
            end

            closeWindow:SetActive(false)
        end,
        "切换回正常房间"
    )
    tls[#tls + 1] = EZTL_Wait:New(2000, "析构前最后等2s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            GameGlobal.UIStateManager():ShowDialog(
                "UIAircraftUnlockFileController",
                StringTable.Get("str_aircraft_unlock_room", room:RoomName()),
                StringTable.Get(enTip)
            )
        end,
        "显示修复ui动画"
    )
    tls[#tls + 1] = EZTL_Wait:New(3000, "动画等3s")
    tls[#tls + 1] =
        EZTL_Callback:New(
        function()
            --析构req
            for _, req in ipairs(reqs) do
                req:Dispose()
            end
            GameGlobal.UIStateManager():CloseDialog("UIAircraftUnlockFileController")

            UnityEngine.Object.Destroy(blur)

            if self._onFinish then
                self._onFinish()
            end

            --触发引导
            if not self._test then
                GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideEntertainmentRoomUnlock, self._spaceID)
            end
            -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, self._spaceID)
            self._main:SelectSpace(self._spaceID, false)
            --刷新氛围值
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftOnAmbientChanged)
            --解锁屏幕
            GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AirAnimRoomUnlock")
            AirLog("休息区房间解锁动画完成")
        end,
        "析构，结束回调"
    )

    local tl = EZTL_Sequence:New(tls, "解锁房间总时间线，串行")
    self._player:Play(tl)
end
