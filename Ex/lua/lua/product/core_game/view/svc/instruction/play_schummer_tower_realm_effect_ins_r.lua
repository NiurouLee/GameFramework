require("base_ins_r")

--[[
    白舒默尔专用指令：根据已激活的诅咒塔的方位，放置对应方位的特效
    需求过于特化，effectID和
]]

---@class PlaySchummerTowerRealmEffectInstruction: BaseInstruction
_class("PlaySchummerTowerRealmEffectInstruction", BaseInstruction)
PlaySchummerTowerRealmEffectInstruction = PlaySchummerTowerRealmEffectInstruction

local PositionalData = {
    LT = {
        v2GridPos = Vector2.New(2, 8),
        v2Dir = Vector2.up,
    },
    LB = {
        v2GridPos = Vector2.New(2, 2),
        v2Dir = Vector2.left,
    },
    RT = {
        v2GridPos = Vector2.New(8, 8),
        v2Dir = Vector2.right,
    },
    RB = {
        v2GridPos = Vector2.New(8, 2),
        v2Dir = Vector2.down,
    },
}

function PlaySchummerTowerRealmEffectInstruction:Constructor(paramList)
    self._effectID = 2771
end

---@param casterEntity Entity
function PlaySchummerTowerRealmEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type EffectService
    local fxsvc = world:GetService("Effect")
    local curseTowerGroupEntities = world:GetGroupEntities(world.BW_WEMatchers.CurseTower)
    if (not curseTowerGroupEntities) or (#curseTowerGroupEntities <= 0) then
        return
    end

    ---@type UtilDataServiceShare
    local utilDataSvc = world:GetService("UtilData")

    for _, eTower in ipairs(curseTowerGroupEntities) do
        if utilDataSvc:GetTrapCurseTowerState(eTower) == CurseTowerState.Deactive then
            goto PLAY_SCHUMMERTOWERREALMEFFECT_INSTRUCTION_DEACTIVE_CONTINUE
        end

        local v2GridPos = eTower:GetGridPosition()
        local v2Relative = v2GridPos - BattleConst.BoardCenterPos
        local tPosData
        if v2Relative.x < 0 and v2Relative.y > 0 then
            tPosData = PositionalData.LT
        elseif v2Relative.x > 0 and v2Relative.y > 0 then
            tPosData = PositionalData.RT
        elseif v2Relative.x < 0 and v2Relative.y < 0 then
            tPosData = PositionalData.LB
        elseif v2Relative.x > 0 and v2Relative.y < 0 then
            tPosData = PositionalData.RB
        end

        fxsvc:CreateWorldPositionDirectionEffect(self._effectID, tPosData.v2GridPos, tPosData.v2Dir)

        ::PLAY_SCHUMMERTOWERREALMEFFECT_INSTRUCTION_DEACTIVE_CONTINUE::
    end
end

function PlaySchummerTowerRealmEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._effectID].ResPath, 1})
    end
    return t
end
