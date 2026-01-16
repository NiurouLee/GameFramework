require("base_ins_r")

---@class PlayMonster2802301CentralEffectInstruction: BaseInstruction
_class("PlayMonster2802301CentralEffectInstruction", BaseInstruction)
PlayMonster2802301CentralEffectInstruction = PlayMonster2802301CentralEffectInstruction

function PlayMonster2802301CentralEffectInstruction:Constructor(paramList)
    self._effectID = tonumber(paramList["effectID"])
    self._posY = tonumber(paramList["posY"])
    local strOffset = paramList["offset"] --特效偏移
    if strOffset then
        local arr = string.split(strOffset, "|")
        self._offset = Vector2(tonumber(arr[1]), tonumber(arr[2]))
    else
        self._offset = Vector2.zero
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMonster2802301CentralEffectInstruction:DoInstruction(TT, casterEntity, phaseContext)
    local world = casterEntity:GetOwnerWorld()

    local targetPos = Vector2.zero
    targetPos.y = self._posY

    --获取玩家位置，取X
    --[[
        2023/5/26 修改为”回合开始时的玩家位置“

        王伟 5-26 11:07:46
        [苦涩]那个新表现的需求我没说清楚，X读的应该是光灵回合开始时的X坐标，而不是当前X坐标

        王伟 5-26 11:08:13
        大哥你能不能再改下
    ]]
    targetPos.x = world:GetService("UtilData"):GetRoundBeginPlayerPos().x

    local offsetPos = targetPos + self._offset
    --播放特效

    ---@type EffectService
    local effectService = world:GetService("Effect")
    effectService:CreateWorldPositionEffect(self._effectID, offsetPos)
end

function PlayMonster2802301CentralEffectInstruction:GetCacheResource()
    local t = {}
    if self._effectID and self._effectID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._effectID].ResPath, 1 })
    end
    return t
end
