---@class UIVideo:UIController
_class("UIVideo", UIController)
UIVideo = UIVideo

function UIVideo:OnShow(uiParams)
    self._onVideoComplete = uiParams[1] --视频播放完毕的回调

    --暂停bgm
    AudioHelperController.PauseBGM()
    local url = ResourceManager:GetInstance():GetAssetPath("pv.mp4", LoadType.VideoClip)

    if EDITOR then
        --[[
        local waitTime = 76 * 1000
        GameGlobal:GetInstance().RealTimer():AddEvent(
            waitTime,
            function()
                if self._onVideoComplete then
                    self._onVideoComplete()
                end
            end
        )

        ---@type UnityEngine.Video.VideoPlayer
        self._vp = self:GetUIComponent("VideoPlayer", "VideoPlayer")
        self._vp.gameObject:SetActive(true)
        Log.debug("[video] url ", url)
        self._vp.url = url
        self._vp.targetCamera = GameGlobal.UIStateManager():GetControllerCamera("UIVideo")
        self._vp:Play()
        ]]
        if self._onVideoComplete then
            self._onVideoComplete()
        end
    else
        --[[
        local resName = string.match(url, ".+/(.+)")
        ---参数3 FullScreenMovieControlMode.Hidden  参数4 FullScreenMovieScalingMode.AspectFit
        HelperProxy:GetInstance():PlayMovie(resName, Color.black, 3, 1)
        
        --Handheld.PlayFullScreenMovie接口不会在调用后立刻暂停unity 并且也没有回调 不知道实际的暂停继续时间 暂时用忙等固定时长来处理
        --这个时间不能过长 以避免安卓手机上立刻点返回跳过视频导致黑屏时间过长
        --这个时间也不能过短 在有些手机上等待时间过短会导致视频还没播放 就执行结束回调了
        local waitTime = 2 * 1000
        GameGlobal:GetInstance().RealTimer():AddEvent(
            waitTime,
            function()
                if self._onVideoComplete then
                    self._onVideoComplete()
                end
            end
        )
        ]]
        if self._onVideoComplete then
            self._onVideoComplete()
        end
    end
end

function UIVideo:OnHide()
    --继续bgm
    AudioHelperController.UnpauseBGM()
    self._onVideoComplete = nil
end
