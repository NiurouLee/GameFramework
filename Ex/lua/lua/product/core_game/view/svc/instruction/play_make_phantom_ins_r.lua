--[[
    制造幻象的逻辑，逻辑与表现未分离，需要在表现过程中执行逻辑
]]
---@class PlayMakePhantomInstruction:BaseInstruction
_class("PlayMakePhantomInstruction", BaseInstruction)
PlayMakePhantomInstruction = PlayMakePhantomInstruction

function PlayMakePhantomInstruction:Constructor(paramList)
    self.duration = tonumber(paramList["flyDuration"])
    self.eftID = tonumber(paramList["eftID"])
    self.eftPosYa = tonumber(paramList["eftPosYa"])
    self.eftPosYb = tonumber(paramList["eftPosYb"])
end

function PlayMakePhantomInstruction:GetCacheResource()
    local t = {}
    if self.eftID and self.eftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.eftID].ResPath, 1})
    end
    return t
end

function PlayMakePhantomInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MakePhantom)
    if resultArray == nil then
        Log.fatal("制造幻象技能结果错误")
        return
    elseif #resultArray == 0 then
        Log.fatal("找不到制造幻象技能结果")
        return
    elseif #resultArray ~= 1 then
        Log.fatal("只能制造1个幻象")
    end

    ---@type BoardServiceRender
    local boardServiceRender = world:GetService("BoardRender")
    ---@type EffectService
    local effectService = world:GetService("Effect")
    local _start = casterEntity:View():GetGameObject().transform.position:Clone()
    _start.y = self.eftPosYa
    local _end = nil

    ---@type SkillMakePhantomEffectResult
    local result = resultArray[1]

    ---@type Entity
    local eftEntity = effectService:CreatePositionEffect(self.eftID, _start)

    if not eftEntity:HasView() then
        YIELD(TT)
    end

    local eftTansform = eftEntity:View():GetGameObject().transform
    _end = boardServiceRender:GridPos2RenderPos(result:GetBornPos())
    _end.y = self.eftPosYb

    local disx = math.abs(_end.x - _start.x)
    local disy = math.abs(_end.y - _start.y)
    local power = math.sqrt(disx + disy)
    eftTansform:DOJump(_end, power, 1, self.duration / 1000, false)

    YIELD(TT, self.duration + 10)

    world:DestroyEntity(eftEntity)
    ---@type MonsterShowRenderService
    local monsterShowRenderService = world:GetService("MonsterShowRender")
    local entity = world:GetEntityByID(result:GetTargetEntityID())

    monsterShowRenderService:CreateMonsterHPEntity(entity)

    --表现
    ---@type MonsterShowRenderService
    local sMonsterShowRender = world:GetService("MonsterShowRender")
    sMonsterShowRender:ShowMonsters(TT, {entity}, {result:GetBornPos()})

    entity:SetViewVisible(true)
end
