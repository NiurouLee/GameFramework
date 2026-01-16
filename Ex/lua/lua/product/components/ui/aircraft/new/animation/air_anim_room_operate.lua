--[[
    风船房间操作后的动画
]]
---@class AirAnimRoomOperate:Object
_class("AirAnimRoomOperate", Object)
AirAnimRoomOperate = AirAnimRoomOperate
function AirAnimRoomOperate:Constructor(main, operate, spaceID, onFinish)
    ---@type AircraftMain
    self._main = main
    ---@type AircraftDoorAnim
    self._operation = operate
    self._spaceID = spaceID
    self._onFinish = onFinish
    self._player = EZTL_Player:New()
end

function AirAnimRoomOperate:Play()
    --[[
        1.升级成功消息返回
        2.锁定屏幕，隐藏房间ui，相机聚焦到房间0.7s
        3.播放开门动画x秒
        4.显示ui，解锁屏幕
    ]]
    AirLog("开始房间门动画，spaceID:", self._spaceID, "，操作类型:", self._operation)
    self._main:ClearCurrentRoom()
    --多执行一次关闭房间UI，因为引导会绕过正常点击流程拉近房间
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)
    --锁ui
    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, true, "AirAnimRoomOperate")
    --隐藏房间ui
    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, nil)
    local room = self._main:GetRoomBySpaceID(self._spaceID)
    local door = self._main:GetDoorBySpaceID(self._spaceID)
    if not room then
        Log.exception("找不到房间，无法做动画：", self._spaceID, "，操作类型：", self._operation)
    end
    if not door then
        Log.exception("找不到门，无法做动画：", self._spaceID, "，操作类型：", self._operation)
    end
    --相机聚焦到房间，0.7s
    self._main:FocusRoomToAnimate(room, nil, 700)
    local tls = {}
    self._main:SetOneRoomUIActive(self._spaceID, false)

    tls[#tls + 1] = EZTL_Wait:New(700, "先等0.7s，相机聚焦到房间")

    if self._operation == AircraftDoorAnim.BuildRoom then
        --建造完开门
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Open()
                end,
                "建造，开门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(1750, "开门动画等1.5s")
    elseif self._operation == AircraftDoorAnim.TearDown then
        --拆除完关门
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Close()
                end,
                "拆除，关门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(1750, "关门动画等1.5s")
    elseif self._operation == AircraftDoorAnim.LevelUp then
        --升级完先关门再开门
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Close()
                end,
                "升级，关门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(2000, "关门动画之后等2s")
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Open()
                end,
                "开门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(1750, "开门动画等1.5s")
    elseif self._operation == AircraftDoorAnim.LevelDown then
        --降级完关门再开门，同升级
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Close()
                end,
                "降级，关门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(2000, "关门动画之后等2s")
        tls[#tls + 1] =
            EZTL_Callback:New(
                function()
                    door:Open()
                end,
                "开门动画"
            )
        tls[#tls + 1] = EZTL_Wait:New(1750, "开门动画等1.5s")
    end

    tls[#tls + 1] =
        EZTL_Callback:New(
            function()
                --触发建造完房间的引导
                if self._operation == AircraftDoorAnim.BuildRoom then
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.GuideBuildAirRoom, self._spaceID)
                end
                --拆除的房间不显示ui
                if self._operation ~= AircraftDoorAnim.TearDown then
                    GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftShowRoomUI, self._spaceID)
                    self._main:SelectSpace(self._spaceID, false)
                    door:AnimStop()
                end
                GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftUILock, false, "AirAnimRoomOperate")
                --刷新装修区域，这里暂时不刷新，因为暂时没有除4个休闲区房间外，其他房间升降级时刷新家具的需求
                -- GameGlobal.EventDispatcher():Dispatch(GameEventType.AircraftRefreshDecorateArea, self._spaceID)
                self._main:SetOneRoomUIActive(self._spaceID, true)
                if self._onFinish then
                    self._onFinish()
                end
                AirLog("房间门动画结束")
            end,
            "最后显示房间ui，解锁屏幕"
        )

    local tl = EZTL_Sequence:New(tls, "房间操作动画，串行")
    self._player:Play(tl)
end
