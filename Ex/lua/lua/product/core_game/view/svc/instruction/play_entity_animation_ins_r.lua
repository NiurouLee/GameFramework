require("base_ins_r")
---这条指令用于自己控制场上不在技能技能结果中的其他怪物或者机关。直接搜索活着的monsterID trapID
---@class PlayEntityAnimationInstruction: BaseInstruction
_class("PlayEntityAnimationInstruction", BaseInstruction)
PlayEntityAnimationInstruction = PlayEntityAnimationInstruction

function PlayEntityAnimationInstruction:Constructor(paramList)
    self._animName = paramList["animName"]

    self._monsterClassID = tonumber(paramList["monsterClassID"]) or 0
    self._trapID = tonumber(paramList["trapID"]) or 0
end

---@param casterEntity Entity
function PlayEntityAnimationInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    local entityList = {}

    if self._trapID and self._trapID > 0 then
        local trapGroup = world:GetGroup(world.BW_WEMatchers.Trap)
        for _, e in ipairs(trapGroup:GetEntities()) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            if trapRenderCmpt and not trapRenderCmpt:GetHadPlayDestroy() and self._trapID == trapRenderCmpt:GetTrapID() then
                table.insert(entityList, e)
            end
        end
    end

    if self._monsterClassID and self._monsterClassID > 0 then
        local monsterGroup = world:GetGroup(world.BW_WEMatchers.MonsterID)
        for _, e in ipairs(monsterGroup:GetEntities()) do
            if e:HasView() and not e:HasShowDeath() and self._monsterClassID == e:MonsterID():GetMonsterClassID() then
                table.insert(entityList, e)
            end
        end
    end

    for _, e in ipairs(entityList) do
        e:SetAnimatorControllerTriggers({self._animName})
    end
end
