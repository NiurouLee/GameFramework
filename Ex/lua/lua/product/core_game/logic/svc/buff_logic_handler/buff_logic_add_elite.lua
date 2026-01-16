--[[
    添加精英词缀
]]

---@class BuffLogicAddElite : BuffLogicBase
_class("BuffLogicAddElite", BuffLogicBase)
BuffLogicAddElite = BuffLogicAddElite

function BuffLogicAddElite:Constructor(buffInstance, logicParam)
    self._eliteIDArray = logicParam.eliteIDArray
    if not self._eliteIDArray then
        Log.error("[AddElite] config error: elite id array is nil!")
    end
end

function BuffLogicAddElite:DoLogic(notify)
    ---@type Entity
    local ownerEntity = self._buffInstance:Entity()
    ---@type MonsterIDComponent
    local monsterIDCmpt = ownerEntity:MonsterID()
    if not monsterIDCmpt then
        return
    end

    ---查找需新增的精英词缀
    local addEliteIDArray = {}
    local ownerEliteIDArray = monsterIDCmpt:GetEliteIDArray()
    for _, id in ipairs(self._eliteIDArray) do
        if not table.icontains(ownerEliteIDArray, id) then
            table.insert(addEliteIDArray, id)
        end
    end

    if #addEliteIDArray == 0 then
        ---无需新增
        return
    end
    
    ---重新设置精英词缀
    table.appendArray(ownerEliteIDArray, addEliteIDArray)
    monsterIDCmpt:SetEliteIDArray(ownerEliteIDArray)

    ---@type BuffResultAddElite
    local result = BuffResultAddElite:New(addEliteIDArray)

    ---@type MainWorld
    local world = self._buffInstance:World()
    ---@type BuffLogicService
    local buffLogicSvc = world:GetService("BuffLogic")
    for _, eliteID in ipairs(addEliteIDArray) do
        local cfg = Cfg.cfg_monster_elite[eliteID]
        if not cfg then
            Log.error("[AddElite]", "invalid eliteID: ", eliteID)
            goto ADD_ELITE_BUFF_CONTINUE
        end

        if (not cfg.Buff) or (#(cfg.Buff) == 0) then
            goto ADD_ELITE_BUFF_CONTINUE
        end

        for _, buffID in ipairs(cfg.Buff) do
            Log.debug("[AddElite]", "entityID: ", ownerEntity:GetID(), "elite ID: ", eliteID, ", buffID: ", buffID)
            local buffIns = buffLogicSvc:AddBuff(buffID, ownerEntity, {})
            if buffIns then
                result:AddBuffSeq(buffIns:BuffSeq())
            end
        end

        ::ADD_ELITE_BUFF_CONTINUE::
    end

    return result
end
