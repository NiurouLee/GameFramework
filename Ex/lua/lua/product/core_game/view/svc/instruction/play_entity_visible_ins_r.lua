require("base_ins_r")
---@class PlayEntityVisibleInstruction: BaseInstruction
_class("PlayEntityVisibleInstruction", BaseInstruction)
PlayEntityVisibleInstruction = PlayEntityVisibleInstruction

function PlayEntityVisibleInstruction:Constructor(paramList)
    local param = tonumber(paramList["visible"])
    if param == 1 then
        self._visible = true
    else
        self._visible = false
    end

    self._monsterClassID = tonumber(paramList["monsterClassID"]) or 0
    self._trapID = tonumber(paramList["trapID"]) or 0
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayEntityVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    if self._trapID and self._trapID > 0 then
        local group = world:GetGroup(world.BW_WEMatchers.Trap)
        for _, e in ipairs(group:GetEntities()) do
            ---@type TrapRenderComponent
            local trapRenderCmpt = e:TrapRender()
            if trapRenderCmpt and not trapRenderCmpt:GetHadPlayDestroy() and self._trapID == trapRenderCmpt:GetTrapID() then
                self:_OnSetEntityVisible(e)

                ---@type TrapRoundInfoRenderComponent
                local cTrapRoundInfo = e:TrapRoundInfoRender()
                if cTrapRoundInfo then
                    cTrapRoundInfo:SetIsShow(self._visible)
                end
            end
        end
    end

    if self._monsterClassID and self._monsterClassID > 0 then
        local group = world:GetGroup(world.BW_WEMatchers.EntityType)
        for _, e in ipairs(group:GetEntities()) do
            if
                e:EntityType().Value == EntityType.Monster and not e:HasShowDeath() and
                    self._monsterClassID == e:MonsterID():GetMonsterClassID()
             then
                self:_OnSetEntityVisible(e)
            end
        end

        ---再把所有怪物的血条隐藏
        local group = world:GetGroup(world.BW_WEMatchers.EntityType)
        for _, e in ipairs(group:GetEntities()) do
            if e:EntityType().Value == EntityType.HPSlider then
                e:SetViewVisible(self._visible)
            end
        end
    end
end

function PlayEntityVisibleInstruction:_OnSetEntityVisible(entity)
    ---@type LocationComponent
    local location = entity:Location()
    if location then
        ---@type UnityEngine.Vector3
        local gridWorldPos = entity:GetPosition()
        local offsetY = self._visible and 0 or 1000
        local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
        entity:SetPosition(gridWorldNew)
        if self._visible then
            entity:SetViewVisible(self._visible)
        end
    end
end
