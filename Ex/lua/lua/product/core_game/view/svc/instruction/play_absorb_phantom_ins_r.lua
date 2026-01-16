--[[
    吸收幻象的逻辑，逻辑与表现未分离，需要在表现过程中执行逻辑
]]
_class("PlayAbsorbPhantomInstruction", BaseInstruction)
---@class PlayAbsorbPhantomInstruction:BaseInstruction
PlayAbsorbPhantomInstruction = PlayAbsorbPhantomInstruction

function PlayAbsorbPhantomInstruction:Constructor(paramList)
    self.duration = tonumber(paramList["flyDuration"])
    self.eftID = tonumber(paramList["eftID"])
    self.phantomDeadAnim = paramList["phantomDeadAnim"]
    self.phantomDeadDuration = tonumber(paramList["phantomDeadDuration"])
    self.eftPosYa = tonumber(paramList["eftPosYa"])
    self.eftPosYb = tonumber(paramList["eftPosYb"])

    self.commonEft = tonumber(paramList["commonEft"])
end

function PlayAbsorbPhantomInstruction:GetCacheResource()
    local t = {}
    if self.eftID and self.eftID > 0 then
        table.insert(t, {Cfg.cfg_effect[self.eftID].ResPath, 1})
    end
    if self.commonEft and self.commonEft > 0 then
        table.insert(t, {Cfg.cfg_effect[self.commonEft].ResPath, 1})
    end
    return t
end

function PlayAbsorbPhantomInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.AbsorbPhantom)
    if resultArray == nil then
        Log.fatal("吸收幻象技能结果错误")
        return
    elseif #resultArray == 0 then
        Log.fatal("找不到吸收幻象技能结果")
        return
    elseif #resultArray ~= 1 then
        Log.fatal("只能吸收1个幻象")
    end

    ---@type SkillAbsorbPhantomEffectResult
    local result = resultArray[1]
    ---@type Entity
    local phantom = world:GetEntityByID(result:GetTargetEntityID())

    ---@type EffectService
    local effectService = world:GetService("Effect")

    phantom:SetAnimatorControllerTriggers({self.phantomDeadAnim})
    YIELD(TT, self.phantomDeadDuration)

    local _start = phantom:View():GetGameObject().transform.position:Clone()

    phantom:SetViewVisible(false)
    phantom:AddDeadFlag()

    ---隐藏血条
    local sliderEntityID = phantom:HP():GetHPSliderEntityID()
    local sliderEntity = world:GetEntityByID(sliderEntityID)
    sliderEntity:SetViewVisible(false)

    --执行一次通用死亡逻辑
    ---@type MonsterShowRenderService
    local sMonsterShowRender = world:GetService("MonsterShowRender")
    sMonsterShowRender:_DoOneMonsterDead(TT, phantom, 0)

    _start.y = self.eftPosYa
    local _end = casterEntity:View():GetGameObject().transform.position:Clone()
    _end.y = self.eftPosYb
    ---@type Entity
    local eftEntity = effectService:CreatePositionEffect(self.eftID, _start)
    if not eftEntity:HasView() then
        YIELD(TT)
    end
    local eftTansform = eftEntity:View():GetGameObject().transform
    local disx = math.abs(_end.x - _start.x)
    local disy = math.abs(_end.y - _start.y)
    local power = math.sqrt(disx + disy)
    eftTansform:DOJump(_end, power, 1, self.duration / 1000, false)
    YIELD(TT, self.duration + 10)
    world:DestroyEntity(eftEntity)

    effectService:CreateEffect(self.commonEft, casterEntity)

    --材质动画
    if casterEntity:MaterialAnimationComponent() then 
        casterEntity:MaterialAnimationComponent():PlayCure()
    end

    --加血飘字
    ---@type PlayDamageService
    local playDamageService = world:GetService("PlayDamage")
    local addHpDamageInfo = result:GetDamageInfo()
    playDamageService:AsyncUpdateHPAndDisplayDamage(casterEntity, addHpDamageInfo)
end
