require("base_ins_r")
---@class PlayRideOnInstruction : BaseInstruction
_class("PlayRideOnInstruction", BaseInstruction)
PlayRideOnInstruction = PlayRideOnInstruction

function PlayRideOnInstruction:Constructor(paramList)
    self._rideOnDelay = tonumber(paramList.rideOnDelay)
end

---@param casterEntity Entity
function PlayRideOnInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local resultContainer = casterEntity:SkillRoutine():GetResultContainer()
    ---@type SkillEffectRideOnResult
    local result = resultContainer:GetEffectResultByArray(SkillEffectType.RideOn)
    if not result then
        return
    end

    --显示召唤机关
    ---@type TrapServiceRender
    local trapSvc = world:GetService("TrapRender")
    local trapIDList = result:GetTrapIDList()
    local newTrapID = nil
    if trapIDList then
        local trapEntityList = {}
        for _, trapEntityID in ipairs(trapIDList) do
            local trapEntity = world:GetEntityByID(trapEntityID)
            if trapEntity then
                newTrapID = trapEntityID
                table.insert(trapEntityList, trapEntity)
            end
        end
        trapSvc:ShowTraps(TT, trapEntityList, true)
    end

    YIELD(TT, self._rideOnDelay)

    ---@type RideServiceRender
    local rideRenderSvc = world:GetService("RideRender")
    local monsterMountID = result:GetMonsterMountID()
    local trapMountID = result:GetTrapMountID()
    if newTrapID then
        rideRenderSvc:ReplaceRideRender(casterEntity:GetID(), newTrapID)
    elseif monsterMountID then
        rideRenderSvc:ReplaceRideRender(casterEntity:GetID(), monsterMountID)
    elseif trapMountID then
        rideRenderSvc:ReplaceRideRender(casterEntity:GetID(), trapMountID)
    end
end
