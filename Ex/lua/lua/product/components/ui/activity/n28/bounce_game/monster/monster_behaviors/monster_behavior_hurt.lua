require "monster_behavior_base"

--怪物行为组件-受伤行为
---@class MonsterBeHaviorHurt : MonsterBeHaviorBase
_class("MonsterBeHaviorHurt", MonsterBeHaviorBase)
MonsterBeHaviorHurt = MonsterBeHaviorHurt

function MonsterBeHaviorHurt:Name()
    return "MonsterBeHaviorHurt"
end

--受伤行为
function MonsterBeHaviorHurt:Exec(ap)
    ---@type MonsterData
    local monsterData = self:GetMonsterData()
    local monsterOldHp = monsterData.hp
    local newHp = monsterData.hp - ap
    if newHp < 0 then
        newHp = 0
    end 

    monsterData.hp = newHp
    self:PlayAudioByLeftHp(newHp)

    --触发其它行为
    --进度条
    local beHaviorProgress = self:GetBehavior(MonsterBeHaviorShowHpProgress:Name())
    if beHaviorProgress then
        beHaviorProgress:SetProgress(newHp)
    end

    local behaviorAni = self:GetBehavior(MonsterBeHaviorAnimation:Name())
    --是否死亡
    if newHp == 0 then
        --得分
        ---@type BounceController
        local bounceController = self:GetCoreController()
        bounceController:MonsterDead(self.monster:GetMonsterId())
        

        local deadDuration = 0

        if self.monster.state == BounceObjState.Transformation  then
            --先更新资源
            local beHaviorTransmation = self:GetBehavior("MonsterBeHaviorTransformationWithHp")
            if beHaviorTransmation then
                beHaviorTransmation:ChgResImmediatelyBy(monsterOldHp)
                behaviorAni = self:GetBehavior(MonsterBeHaviorAnimation:Name())
            end
        end

         --死亡动画
         if behaviorAni then
            behaviorAni:PlayAnimation(BounceConst.MonsterDeadAniName)
        end
        
        local behaviorView = self:GetBehavior(MonsterBeHaviorView:Name())
        if behaviorView and behaviorView.resCfg then
            --死亡动画时间
            local duration = behaviorView.resCfg.DeadDuration
            deadDuration = duration or 0
        end

        self.monster:SetDeadWithDuration(deadDuration)
        return
    else
        --受到攻击动作
        if behaviorAni then
            behaviorAni:PlayAnimation(BounceConst.MonsterBeAttackedAniName)
         end
    end

    --是否改变形状
    ---@type MonsterBeHaviorTransformationWithHp
    local beHaviorTransmation = self:GetBehavior("MonsterBeHaviorTransformationWithHp")
    if beHaviorTransmation then
        beHaviorTransmation:CheckTransformation(monsterData.hp)
    end
end

function MonsterBeHaviorHurt:PlayAudioByLeftHp(hp)
    local cfg = self:GetCfg()
    if not cfg or not cfg.Audio then
        return
    end
    local audioId = nil
    if hp > 0 then
        audioId = cfg.Audio[BounceConst.MonsterAudioTypeBeAttacked]
    else
        audioId = cfg.Audio[BounceConst.MonsterAudioTypeDead]
    end
    if audioId then
        AudioHelperController.PlayUISoundAutoRelease(audioId)
    end
end

function MonsterBeHaviorHurt:OnInit(param)
end

function MonsterBeHaviorHurt:OnShow()
end

function MonsterBeHaviorHurt:OnReset()
end

function MonsterBeHaviorHurt:OnRelease()
end
