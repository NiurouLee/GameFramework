require("base_ins_r")
---播放Spine效果
---@class PlaySpineInstruction: BaseInstruction
_class("PlaySpineInstruction", BaseInstruction)
PlaySpineInstruction = PlaySpineInstruction

function PlaySpineInstruction:Constructor(paramList)
    self._spineName = paramList["spineName"]
    self._spineLength = tonumber(paramList["spineLength"])
    self._waitSpineTime = tonumber(paramList["waitSpineTime"])
    
    self._spineResRequest = nil
end

function PlaySpineInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type BattleRenderConfigComponent
    local battleRenderConfigCmpt = world:BattleRenderConfig()
    local canPlayCG = battleRenderConfigCmpt:GetCanPlaySkillSpineInBattle(self._spineName)

    if not canPlayCG then
        return
    end

    ---启动spine播放
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShowUltraSkillSpine, self._spineName)

    ---由于spine的长度和技能表现等待的spine播放时间不一致，所以这里使用计时器来关闭Spine
    ---使用wait来等待时长
    ---这个Timer会不会出现问题？
    ---如果有问题，应该把这个timer放到phaseContext里，在退出phase的时候，强制结束
    self._waitSpineTimerEvent =
        GameGlobal.Timer():AddEvent(
        self._spineLength,
        function()
            GameGlobal.EventDispatcher():Dispatch(GameEventType.StopUltraSkillSpine, self._spineName)
            self._waitSpineTimerEvent = nil
            --为解决局内内存峰值过大 主动技spine采用播放前动态加载/播放完立刻释放的方式来管理资源
            self._spineResRequest:Dispose()
            self._spineResRequest = nil
        end
    )

    YIELD(TT, self._waitSpineTime)
end

function PlaySpineInstruction:Prepare(TT, casterEntity)
    --为解决局内内存峰值过大 主动技spine采用播放前动态加载/播放完立刻释放的方式来管理资源
    self._spineResRequest = ResourceManager:GetInstance():AsyncLoadAsset(TT, self._spineName..".prefab", LoadType.GameObject)
end