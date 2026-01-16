require("base_ins_r")
---@class PlayMonsterVisibleInstruction: BaseInstruction
_class("PlayMonsterVisibleInstruction", BaseInstruction)
PlayMonsterVisibleInstruction = PlayMonsterVisibleInstruction

function PlayMonsterVisibleInstruction:Constructor(paramList)
    local param = tonumber(paramList["visible"])
    if param == 1 then
        self._visible = true
    else
        self._visible = false
    end
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMonsterVisibleInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---这个字符串现在是一个常量，跟EntityConfig里配的一致，未来应该统一收到一个地方
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    local offsetY = self._visible and 0 or 1000
    ---先把所有怪物的本体隐藏
    local group = world:GetGroup(world.BW_WEMatchers.EntityType)
    for _, e in ipairs(group:GetEntities()) do
        if e:EntityType().Value == EntityType.Monster and not e:HasShowDeath() then
            -- e:SetViewVisible(self._visible)
            --关闭view会影响一些animation的状态机，所以改成了移动坐标
            self:SetMonsterPos(e,offsetY)
            if e:MonsterID() and e:MonsterID():GetSnakeBodyEffectID() then
                local bodyEffectList =self:GetBodyEffect(e)
                for index, id in ipairs(bodyEffectList) do
                    ---@type Entity
                    local bodyEffectEntity = world:GetEntityByID(id)
                    self:SetMonsterPos(bodyEffectEntity,offsetY)
                end
            end
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
---@param monsterEntity Entity
function PlayMonsterVisibleInstruction:SetMonsterPos(monsterEntity,offsetY)
    ---@type LocationComponent
    local location = monsterEntity:Location()
    if location then
        ---@type UnityEngine.Vector3
        local gridWorldPos = monsterEntity:GetPosition()
        local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
        monsterEntity:SetPosition(gridWorldNew)
    end
end

---@param casterEntity Entity
function PlayMonsterVisibleInstruction:GetBodyEffect(casterEntity)
    local bodyEffectList ={}
    local effectID = casterEntity:MonsterID():GetSnakeBodyEffectID()
    if casterEntity:HasEffectHolder() then
        ---@type EffectHolderComponent
        local effectHolderCmpt = casterEntity:EffectHolder()
        ---@type table<number,number>
        local effectDictList = effectHolderCmpt:GetEffectIDEntityDic()
        for effectID, entityIDList in pairs(effectDictList) do
            if effectID == effectID then
                for i, id in ipairs(entityIDList) do
                    table.insert(bodyEffectList,id)
                end
                break
            end
        end
    end
    return bodyEffectList
end

