require "homelandpet_behavior_base"

---@class HomelandPetBehaviorFishingMatch:HomelandPetBehaviorBase
_class("HomelandPetBehaviorFishingMatch", HomelandPetBehaviorBase)
HomelandPetBehaviorFishingMatch = HomelandPetBehaviorFishingMatch

-- 钓鱼比赛交互行为的阶段
--- @enum HomelandPetFishingMatchStage
local HomelandPetFishingMatchStage = {
    Ready = 1, --准备
    Play = 2, --比赛
    PlayEnd = 3, --动作全部播放完
    Finish = 4, --播放比赛结果
    Exiting = 5 --退出
}
_enum("HomelandPetFishingMatchStage", HomelandPetFishingMatchStage)

-- 钓鱼动作
--- @class HomelandPetFishingAnimType
local HomelandPetFishingAnimType = {
    StartThrow = 1, --甩杆
    Waiting = 2, --等待
    Bite = 3, --咬勾
    Collect = 4, --起杆
    MAX = 5 --MAX
}
_enum("HomelandPetFishingAnimType", HomelandPetFishingAnimType)

-- 钓鱼动作 配置ID cfg_homeland_pet_extra_animation
--- @class HomelandPetFishingAnimID
local HomelandPetFishingAnimID = {
    Stand = 1, -- 站立
    StartThrow = 2, --甩杆
    Waiting = 3, --等待
    Bite = 4, --咬勾
    Collect = 5, --起杆
    Boost = 6, --效果
    Win = 7, --胜利
    Lose = 8, --失败
}
_enum("HomelandPetFishingAnimType", HomelandPetFishingAnimType)

function HomelandPetBehaviorFishingMatch:Constructor(behaviorType, pet)
    HomelandPetBehaviorFishingMatch.super.Constructor(self, behaviorType, pet)

    ---@type HomelandPetComponentExtraAnimation
    self._animationComponent = self:GetComponent(HomelandPetComponentType.ExtraAnimation)

    -- self._cfg = nil  --比赛配置
    -- self._chatCfg = nil  --对话配置
    self._abilityCfg = nil  --能力配置
    self._stage = HomelandPetFishingMatchStage.Ready
end

function HomelandPetBehaviorFishingMatch:Dispose()

end

function HomelandPetBehaviorFishingMatch:Enter()
    HomelandPetBehaviorFishingMatch.super.Enter(self)
    
    if self._cbFishMatchStart == nil then
        self._cbFishMatchStart = GameHelper:GetInstance():CreateCallback(self.FishMatchStart, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.FishMatchStart, self._cbFishMatchStart)
    end
    if self._cbFishMatchEnd == nil then
        self._cbFishMatchEnd = GameHelper:GetInstance():CreateCallback(self.FishMatchEnd, self)
        GameGlobal.EventDispatcher():AddCallbackListener(GameEventType.FishMatchEnd, self._cbFishMatchEnd)
    end

    self._animationComponent:PlayAnimation(HomelandPetFishingAnimID.Stand)

    if not self._params then
        return
    end
end

function HomelandPetBehaviorFishingMatch:Update(dms)
    HomelandPetBehaviorFishingMatch.super.Update(self, dms)

    if self._stage == HomelandPetFishingMatchStage.Play then
        local curTime = GameGlobal:GetInstance():GetCurrentTime()
        self._startTime = self._startTime or curTime

        local tick = curTime - self._startTime
        if not self:_CheckSectionEnd(tick) then
            self:_PlaySection(tick)
        else
            self:SwitchStage(HomelandPetFishingMatchStage.PlayEnd)
            self:_DebugBubble(5)
        end
    end
end

function HomelandPetBehaviorFishingMatch:Exit()
    HomelandPetBehaviorFishingMatch.super.Exit(self)

    if self._cbFishMatchStart then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.FishMatchStart, self._cbFishMatchStart)
        self._cbFishMatchStart = nil
    end
    if self._cbFishMatchEnd then
        GameGlobal.EventDispatcher():RemoveCallbackListener(GameEventType.FishMatchEnd, self._cbFishMatchEnd)
        self._cbFishMatchEnd = nil
    end

    self._animationComponent:PlayAnimation(HomelandPetFishingAnimID.Stand)
end

function HomelandPetBehaviorFishingMatch:Finish()
    return false
end

function HomelandPetBehaviorFishingMatch:CanInterrupt()
    -- 只有钓鱼比赛结束后才可切换状态，防止邀请后修改回旧状态
    if self._stage == HomelandPetFishingMatchStage.Exiting then
        return true
    end
    return false
end

--region 对外接口

--切换状态
---@param stage HomelandPetFishingMatchStage
function HomelandPetBehaviorFishingMatch:SwitchStage(stage)
    self._stage = stage
end

--比赛开始
function HomelandPetBehaviorFishingMatch:FishMatchStart(match_end_time, pet_ability_id)
    self._startTime = nil

    self:_SetCfg(pet_ability_id)
    self._data = self:_CalcSectionData(self._abilityCfg.Config)

    self:SwitchStage(HomelandPetFishingMatchStage.Play)
end

--比赛结束
---@param result FishMatchEndType
function HomelandPetBehaviorFishingMatch:FishMatchEnd(result, playerGoal, petGoal)
    self:SwitchStage(HomelandPetFishingMatchStage.Exiting)

    local cfgId = HomelandPetFishingAnimID.Win
    if result ~= FishMatchEndType.MATCHEND_CLOSE then
        cfgId = (playerGoal > petGoal) and HomelandPetFishingAnimID.Lose or HomelandPetFishingAnimID.Win
    end
    self._animationComponent:StopAllEffect()
    self._animationComponent:PlayAnimation(cfgId, HomelandPetFishingAnimID.Stand)

    self._animationComponent:StopFishTools()
end

--得分
function HomelandPetBehaviorFishingMatch:Goal()
    GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchPetScore)
end

--endregion

--region 内部逻辑

--初始化配置
function HomelandPetBehaviorFishingMatch:_SetCfg(id)
    -- cfg_homeland_fishmatch_pet_ability
    self._abilityCfg = Cfg.cfg_homeland_fishmatch_pet_ability[id]
    if not self._abilityCfg then
        Log.exception("HomelandPetBehaviorFishingMatch:_SetCfg() cfg_homeland_fishmatch_pet_ability[", id, "] == nil")
        return
    end
end

function HomelandPetBehaviorFishingMatch:_GetAnimationTime()
    -- hack: diaoyu_in_hli, diaoyu_out_hli 动画的长度
    return 1300, 1667
end

function HomelandPetBehaviorFishingMatch:_CalcSectionData(data)
    local tb_out = {}
    local animTime1, animTime2 = self:_GetAnimationTime()

    for i, v in ipairs(data) do
        local timeOnce = v[1]
        local biteTime = v[2]
        local effect = (v[3] == 1)
        local count = v[4]

        if biteTime < 0 then
            Log.exception("HomelandPetBehaviorFishingMatch:_CalcPlayData() cfg_homeland_fishmatch_pet_ability[", self._params, "] Error: biteTime < 0")
        end
        
        -- 计算甩杆收杆动作是否需要加快播放速度
        local playSpeed = 1
        if timeOnce < animTime1 + animTime2 then
            playSpeed = timeOnce / (animTime1 + animTime2)
        end

        -- t1 = 甩杆时间，t2 = 等待时间，t3 = 咬勾时间，t4 = 收杆时间
        local t1, t4 = animTime1 * playSpeed, animTime2 * playSpeed
        local t2t3 = timeOnce - t1 - t4
        local t2 = math.max(0, (t2t3 - biteTime))
        local t3 = t2t3 - t2

        for ii = 1, count do
            table.insert(tb_out, self:_CreateData(tb_out, t1, effect))
            table.insert(tb_out, self:_CreateData(tb_out, t2, effect))
            table.insert(tb_out, self:_CreateData(tb_out, t3, effect))
            table.insert(tb_out, self:_CreateData(tb_out, t4, effect))
        end
    end

    -- 最后一次甩杆假数据，用来等待比赛结束事件时保持垂钓姿势
    table.insert(tb_out, self:_CreateData(tb_out, animTime1, false))
    table.insert(tb_out, self:_CreateData(tb_out, 0, false))

    return tb_out
end

function HomelandPetBehaviorFishingMatch:_CreateData(tb_out, duration, effect)
    local last = tb_out[#tb_out]
    local type = last and last.type + 1 or HomelandPetFishingAnimType.MAX
    type = (type == HomelandPetFishingAnimType.MAX) and HomelandPetFishingAnimType.StartThrow or type
    local start = last and last.start + last.duration or 0
    return { type = type, start = start, duration = duration, effect = effect, play = false }
end

function HomelandPetBehaviorFishingMatch:_PlaySection(tick)
    if not self._data then
        return
    end

    local id = nil

    for i, v in ipairs(self._data) do
        if not v.play and tick > v.start then
            v.play = true
            local cfgId = HomelandPetFishingAnimType.Stand
            local effId = HomelandPetFishingAnimID.Boost

            local show = v.effect

            if v.type == HomelandPetFishingAnimType.StartThrow then
                id = 1
                cfgId = HomelandPetFishingAnimID.StartThrow
                GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchPetChangeFishingStatus, FishgingStatus.Throw)
                self._animationComponent:StartFishTools(cfgId, 800) -- hack: diaoyu_in_hli 做到一半时出现 鱼线和鱼漂
            elseif v.type == HomelandPetFishingAnimType.Waiting then
                id = 2
                cfgId = HomelandPetFishingAnimID.Waiting
                GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchPetChangeFishingStatus, FishgingStatus.Fishing)
            elseif v.type == HomelandPetFishingAnimType.Bite then
                id = 3
                cfgId = HomelandPetFishingAnimID.Bite
                GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchPetChangeFishingStatus, FishgingStatus.Bite)
            elseif v.type == HomelandPetFishingAnimType.Collect then
                id = 4
                cfgId = HomelandPetFishingAnimID.Collect
                GameGlobal.EventDispatcher():Dispatch(GameEventType.FishMatchPetChangeFishingStatus, FishgingStatus.FishSuccess)
                self._animationComponent:StopFishTools(500) -- hack: anim_5012001_success 鱼漂动画结束后消失
                self:Goal()
            end
            
            self._animationComponent:PlayAnimation(cfgId)
            self._animationComponent:PlayEffect(cfgId, true)
            self._animationComponent:PlayEffect(effId, show)
            break
        end
    end

    self:_DebugBubble(id)
end

function HomelandPetBehaviorFishingMatch:_CheckSectionEnd(tick)
    local last = self._data[#self._data]
    return not last or last.play
end

--endregion

--region Debug

function HomelandPetBehaviorFishingMatch:_DebugBubble(id)
    local show = UIActivityHelper.CheckDebugOpen()
    if not show then
        return
    end

    local tb = {
        [1] = 4030137, -- 嗨。
        [2] = 4030133, -- 你好。
        [3] = 4030103, -- 啦啦啦~
        [4] = 4030025, -- 看到你啦~
        [5] = 4030013, -- 精神不错呀。
        [6] = 4010082, -- 看来没委托了。
    }

    ---@type HomelandPetComponentBubble
    local bubbleCmp = self:GetComponent(HomelandPetComponentType.Bubble)
    local bubbleId = tb[id]
    if bubbleCmp and bubbleId then
        bubbleCmp:ShowBubble(bubbleId)
    end
end

--endregion
