--[[
    P5 合击技相关buff
    纪录是否全部怪物（黑拳赛是敌方队伍）都weak，给合击技计算和表现用
]]
_class("BuffLogicRecordAllEnemyWeak", BuffLogicBase)
---@class BuffLogicRecordAllEnemyWeak:BuffLogicBase
BuffLogicRecordAllEnemyWeak = BuffLogicRecordAllEnemyWeak

function BuffLogicRecordAllEnemyWeak:Constructor(buffInstance, logicParam)
    self._weakBuffEffect = logicParam.weakBuffEffect or 0
end

function BuffLogicRecordAllEnemyWeak:DoLogic(notify)
    local allEnemyWeak = true
    local hasEnemy = false
    if self._world:MatchType() == MatchType.MT_BlackFist then
        local enemyTeam = self._world:Player():GetCurrentEnemyTeamEntity()
        if not enemyTeam:HasDeadMark() then
            ---@type BuffComponent
            local enemyBuffCmpt = enemyTeam:BuffComponent()
            if enemyBuffCmpt then
                hasEnemy = true
                if not enemyBuffCmpt:HasBuffEffect(self._weakBuffEffect) then
                    allEnemyWeak = false
                end
            end
        end
    else
        local monsterGroup = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
        for _, monsterEntity in ipairs(monsterGroup:GetEntities()) do
            if not monsterEntity:HasDeadMark() then
                ---@type BuffComponent
                local enemyBuffCmpt = monsterEntity:BuffComponent()
                if enemyBuffCmpt then
                    hasEnemy = true
                    if not enemyBuffCmpt:HasBuffEffect(self._weakBuffEffect) then
                        allEnemyWeak = false
                        break
                    end
                end
            end
        end
    end
    if not hasEnemy then
        allEnemyWeak = false
    end

    --重置数值
    local attributeCmpt = self._entity:Attributes()
    if attributeCmpt then
        attributeCmpt:SetSimpleAttribute("AllEnemyWeak", allEnemyWeak and 1 or 0)
    end
end
