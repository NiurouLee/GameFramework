require "season_map_express_base"

---@class SeasonMapExpressAnimation:SeasonMapExpressBase
_class("SeasonMapExpressAnimation", SeasonMapExpressBase)
SeasonMapExpressAnimation = SeasonMapExpressAnimation

function SeasonMapExpressAnimation:Constructor(cfg, eventPoint)
    self._content = self._cfg.Animation
    ---@type SeasonManager
    self._seasonManager = GameGlobal.GetUIModule(SeasonModule):SeasonManager()
    self._time = 0
    ---@type table<string, ResRequest>
    self._effectReqs = {}
    ---@type SeasonPlayer
    self._player = self._seasonManager:SeasonPlayerManager():GetPlayer()
end

function SeasonMapExpressAnimation:Update(deltaTime)
    if self._state == SeasonExpressState.Playing then
        self._time = self._time - deltaTime
        if self._time <= 0 then
            self._state = SeasonExpressState.Over
            self._player:PlayAnimation(SeasonPlayerAnimation.Stand, 0)
            self:_Next(self._param)
        end
    end
end

function SeasonMapExpressAnimation:Dispose()
    for _, _req in pairs(self._effectReqs) do
        _req:Dispose()
    end
    table.clear(self._effectReqs)
end

function SeasonMapExpressAnimation:Play(param)
    SeasonMapExpressAnimation.super.Play(self, param)
    --播放动画
    local eventanim = self._content.eventanim --事件点动画
    local eventLoop = self._content.eventloop --事件点动画循环次数(算时间用)
    local playeranim = self._content.playeranim --主角动画
    local playerLoop = self._content.playerloop --主角动画循环次数(算时间用)
    local eventAnimationState = self._eventPoint:PlayAnimation(eventanim)
    if eventAnimationState then
        if not eventLoop then
            eventLoop = 1
        end
        self._time = eventAnimationState.length * eventLoop
    end
    local playerAnimationState = self._player:PlayAnimation(playeranim)
    if playerAnimationState then
        if not playerLoop then
            playerLoop = 1
        end
        local time = playerAnimationState.length * playerLoop
        if self._time < time then
            self._time = time
        end
    end
    self._time = self._time * 1000
    Log.debug("SeasonMapExpressAnimation time ", self._time)
    --播放特效
    local eventEffect = self._content.eventeffect --事件点特效
    local eventHolder = self._content.eventholder --事件点特效挂点
    local playerEffect = self._content.playereffect --主角特效
    local playerHolder = self._content.playerholder --主角特效挂点
    if eventEffect then
        local eventReq = ResourceManager:GetInstance():SyncLoadAsset(eventEffect .. ".prefab", LoadType.GameObject)
        if eventReq and eventReq.Obj then
            local bone = self._eventPoint:GetBoneNode(eventHolder)
            local effect = eventReq.Obj
            effect:SetActive(true)
            effect.transform:SetParent(bone)
            effect.transform.localPosition = Vector3.zero
            effect.transform.localRotation = Quaternion.Euler(0, 0, 0)
            self._effectReqs[eventReq] = eventReq
        end
    end
    if playerEffect then
        local playerReq = ResourceManager:GetInstance():SyncLoadAsset(playerEffect .. ".prefab", LoadType.GameObject)
        if playerReq and playerReq.Obj then
            local bone = self._player:GetBoneNode(playerHolder)
            local effect = playerReq.Obj
            effect:SetActive(true)
            effect.transform:SetParent(bone)
            effect.transform.localPosition = Vector3.zero
            effect.transform.localRotation = Quaternion.Euler(0, 0, 0)
            self._effectReqs[playerReq] = playerReq
        end
    end
    local audioID = self._content.audio --音效
    if audioID then
        AudioHelperController.PlayUISoundAutoRelease(tonumber(audioID))
    end
    self._state = SeasonExpressState.Playing
end