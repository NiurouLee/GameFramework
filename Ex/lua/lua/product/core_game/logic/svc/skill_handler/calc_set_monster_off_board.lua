--[[
    SetMonsterOffBoard = 188, --设置怪物离场状态 （符文刺客）
]]
---@class SkillEffectCalc_SetMonsterOffBoard: Object
_class("SkillEffectCalc_SetMonsterOffBoard", Object)
SkillEffectCalc_SetMonsterOffBoard = SkillEffectCalc_SetMonsterOffBoard

function SkillEffectCalc_SetMonsterOffBoard:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SetMonsterOffBoard:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamSetMonsterOffBoard
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    ---@type Entity
    local teamEntity = self._world:Player():GetCurrentTeamEntity()

    ---@type BattleStatComponent
    local battleCmpt = self._world:BattleStat()

    

    ---@type Entity
    local boardEntity = self._world:GetBoardEntity()
    ---@type BoardComponent
    local boardComponent = boardEntity:Board()

    local results = {}
    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type UtilDataServiceShare
    local utilData = self._world:GetService("UtilData")
    local bSetOff = skillEffectParam:GetIsSetOff()
    for _, targetID in ipairs(targets) do
        ---@type Entity
        local e = self._world:GetEntityByID(targetID)
        if e then
            ---@type OffBoardMonsterComponent
            local offBoardMonsterCmpt = e:OffBoardMonster()
            ---@type BuffComponent
            local buffComponent = e:BuffComponent()
            if not bSetOff then--返场
                if offBoardMonsterCmpt then
                    local monsterID = offBoardMonsterCmpt:GetMonsterID()
                    if monsterID then
                        e:ReplaceComponent(e:GetMonsterIDComponentEnum(), monsterID)
                    end
                    e:RemoveOffBoardMonster()
                    buffComponent:SetBuffValue("Freeze", nil)
                    ---@type SkillEffectResultSetMonsterOffBoard
                    local result = SkillEffectResultSetMonsterOffBoard:New()
                    result:SetIsSetOff(bSetOff)
                    result:SetTargetEntityID(e:GetID())
                    table.insert(results,result)
                end
            else--离场
                if e:HasMonsterID() then
                    --local monsterID = e:MonsterID():GetMonsterID()
                    local monsterID = e:MonsterID()
                    if not offBoardMonsterCmpt then
                        e:AddOffBoardMonster(monsterID)
                        offBoardMonsterCmpt = e:OffBoardMonster()
                    end
                    --e:RemoveMonsterID() --waitInputSystem中执行
                    --冻结buff组件
                    buffComponent:SetBuffValue("Freeze", 1)
                    ---@type SkillEffectResultSetMonsterOffBoard
                    local result = SkillEffectResultSetMonsterOffBoard:New()
                    result:SetIsSetOff(bSetOff)
                    result:SetTargetEntityID(e:GetID())
                    table.insert(results,result)
                end
            end
        end
    end
    return results
end
