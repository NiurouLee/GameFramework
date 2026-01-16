--怪物数据
---@class MonsterData : Object
_class("MonsterData", Object)
MonsterData = MonsterData

function MonsterData:Constructor(monsterId)
    self.camp = BounceCamp.Monster
    local cfg = Cfg.cfg_bounce_monster[monsterId]
    self.initHp = cfg.InitHp --初始hp
    self.hp = self.initHp --当前hp
    self.durationMS = 0 --怪物加入对局后累积世间（只计算战斗状态）
    self.cfg = cfg
end


function MonsterData:ChgCamp()
    if self.camp == BounceCamp.Player then
        self.camp = BounceCamp.Monster
    elseif self.camp == BounceCamp.Monster then
        self.camp = BounceCamp.Player
    end
end

function MonsterData:Reset()
    self.camp = BounceCamp.Monster
    self.durationMS = 0
    self.underPlayer = false --怪物在玩家正下方
end

function MonsterData:GetMaxHp()
    return self.initHp
end
