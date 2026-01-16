--[[----------------------------------------------------------
    PlayerIdleStateSystem_Render 处理玩家进入闲置状态
]] ------------------------------------------------------------
---@class PlayerIdleStateSystem_Render:ReactiveSystem
_class("PlayerIdleStateSystem_Render", ReactiveSystem)
PlayerIdleStateSystem_Render = PlayerIdleStateSystem_Render

---@param world World
function PlayerIdleStateSystem_Render:Constructor(world)
    self._world = world
end

---@param world World
function PlayerIdleStateSystem_Render:GetTrigger(world)
    local c =
        Collector:New(
        {
            world:GetGroup(world.BW_WEMatchers.MoveFSM)
        },
        {
            "Added"
        }
    )
    return c
end

---@param entity Entity
function PlayerIdleStateSystem_Render:Filter(entity)
    if not entity:HasMoveFSM() then

        return false
    end

    local move_fsm_cmpt = entity:MoveFSM()
    local cur_state_id = move_fsm_cmpt:GetMoveFSMCurStateID()
    if cur_state_id == PlayerActionStateID.Idle then
        return true
    end

    return false
end

function PlayerIdleStateSystem_Render:ExecuteEntities(entities)
    for i = 1, #entities do
        local handle_res = self:HandleIdle(entities[i])
        if handle_res then
            break
        end
    end
end

function PlayerIdleStateSystem_Render:HandleIdle(entity)
    ---@type UtilDataServiceShare
    local utilDataSvc = self._world:GetService("UtilData")
    ---@type GameStateID
    local curMainStateID = utilDataSvc:GetCurMainStateID()

    if curMainStateID == GameStateID.ChainAttack or curMainStateID == GameStateID.RunTest then
        return self:_HandleChainSkillEnd(entity)
    end

    return false
end

function PlayerIdleStateSystem_Render:_HandleChainSkillEnd(entity)
    --检测链式技标签
    if entity:HasChainSkillFlag() then
        entity:RemoveChainSkillFlag()

        --Log.fatal("RemoveChainSkillFlag >>>>>>>>>>>>>>>>>>>>>>>>>>>>>",entity:GetID()," ",UnityEngine.Time.frameCount)

        --主角
        ---@type Entity
        local teamEntity = entity:Pet():GetOwnerTeamEntity()
        ---@type Entity
        local teamLeaderEntity = teamEntity:GetTeamLeaderPetEntity()
        local petEntities = teamEntity:Team():GetTeamPetEntities()
        local chain_skill_sequence_cmpt = teamEntity:ChainSkillSequence()
        local chain_skill_sequence_table = chain_skill_sequence_cmpt.ChainSkillSeqTable
        table.removev(chain_skill_sequence_table, entity:GetID())

        --Log.fatal("ChainSkillCount >>>>>>>>>>>>>>>>>>>>>>>>>>>>>",chain_skill_seq_count)

        if #chain_skill_sequence_table > 0 then
            --当释放完连锁技后，如果后续还有宝宝要释放连锁技，则隐藏上一个连锁技的caster
            if entity:HasViewExtension() then
                entity:SetViewVisible(false)
            end

            local pet_entity_id = self:GetFirstChainSkillActorID(chain_skill_sequence_table)
            TaskManager:GetInstance():CoreGameStartTask(
                self._StartNextPetChainAttack,
                self,
                teamEntity:GridLocation().Position,
                pet_entity_id
            )
        else
            --所有连锁技释放完后，显示队长，隐藏所有宝宝，这也是一块纯表现
            teamLeaderEntity:SetViewVisible(true)
            for i, e in ipairs(petEntities) do
                if e:HasViewExtension() and teamLeaderEntity:GetID() ~= e:GetID() then
                    e:SetViewVisible(false)
                end
            end
        end

        return true
    end
end

function PlayerIdleStateSystem_Render:GetFirstChainSkillActorID(chain_skill_sequence_table)
    local pet_entity_id = chain_skill_sequence_table[1]
    if not pet_entity_id then
        pet_entity_id = -1
    end
    return pet_entity_id
end

function PlayerIdleStateSystem_Render:_StartNextPetChainAttack(TT, castPos, nextPetEntityID)

    local pet_entity = self._world:GetEntityByID(nextPetEntityID)
    pet_entity:SetViewVisible(true)

    YIELD(TT, 100)

    pet_entity:AddChainSkillFlag()

    --Log.fatal("Start pet chain skill >>>>>>>>>>>>>>>>>>>>>>>>>>>>>",nextPetEntityID," ",UnityEngine.Time.frameCount)
    self._world:EventDispatcher():Dispatch(GameEventType.IdleEnd, 2, nextPetEntityID)
end
