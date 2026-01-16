require("base_ins_r")
---@class PlayMoveTrapInstruction: BaseInstruction
_class("PlayMoveTrapInstruction", BaseInstruction)
PlayMoveTrapInstruction = PlayMoveTrapInstruction

function PlayMoveTrapInstruction:Constructor(paramList)
    self._visible = true

    ---扩展参数
    local str = paramList["disappearLegacyAnimNames"]
    self._disappearLegacyAnimNames = string.split(str, "|")
    self._disappearEffID = tonumber(paramList["disappearEffID"])
    self._moveDelayTime = tonumber(paramList["moveDelayTime"]) or 0
    str = paramList["appearLegacyAnimNames"]
    self._appearLegacyAnimNames = string.split(str, "|")
    self._appearEffID = tonumber(paramList["appearEffID"])
end

function PlayMoveTrapInstruction:GetCacheResource()
    local t = {}
    if self._disappearEffID and self._disappearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._disappearEffID].ResPath, 1 })
    end

    if self._appearEffID and self._appearEffID > 0 then
        table.insert(t, { Cfg.cfg_effect[self._appearEffID].ResPath, 1 })
    end
    return t
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayMoveTrapInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()

    ---@type SkillEffectResultMoveTrap[]
    local resultArray = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.MoveTrap)

    if not resultArray or table.count(resultArray) == 0 then
        return
    end
    ---@type PlayBuffService
    local playBuffSvc = world:GetService("PlayBuff")
    for _, result in ipairs(resultArray) do
        local entity = world:GetEntityByID(result:GetEntityID())
        if entity then
            ---消失表现
            self:_DoTrapDisappear(entity)

            ---等待消失表现完毕
            if self._moveDelayTime > 0 then
                YIELD(TT, self._moveDelayTime)
            end

            ---@type UnityEngine.Vector3
            -- local gridWorldPos = entity:GetPosition()
            local gridWorldPos = result:GetPosNew()

            -- local offsetY = self._visible and 0 or 1000
            -- local gridWorldNew = UnityEngine.Vector3.New(gridWorldPos.x, offsetY, gridWorldPos.z)
            entity:SetPosition(gridWorldPos)
            if self._visible then
                entity:SetViewVisible(self._visible)
            end

            ---出现表现
            self:_DoTrapAppear(entity)
        end

        local replaceTrap = world:GetEntityByID(result:GetReplaceTrapEntityID())
        if replaceTrap then
            ---@type TrapServiceRender
            local trapServiceRender = world:GetService("TrapRender")
            trapServiceRender:PlayTrapDieSkill(TT, { replaceTrap })
        end
        ---@type NTMoveTrap
        local NTMoveTrap = NTMoveTrap:New()
        playBuffSvc:PlayBuffView(TT, NTMoveTrap)
    end
end

---@param entity Entity
function PlayMoveTrapInstruction:_DoTrapDisappear(entity)
    if self._disappearEffID then
        ---@type MainWorld
        local world = entity:GetOwnerWorld()
        ---@type BoardServiceRender
        local boardSvc = world:GetService("BoardRender")
        local pos = boardSvc:GetRealEntityGridPos(entity)
        ---@type EffectService
        local effectSvc = world:GetService("Effect")
        effectSvc:CreateWorldPositionEffect(self._disappearEffID, pos)
    end

    if self._disappearLegacyAnimNames == nil then
        Log.fatal("Legacy animation params is nil!")
        return
    end
    if not entity:HasView() then
        return
    end
    local go = entity:View():GetGameObject()
    ---@type UnityEngine.Animation
    local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
    if anim == nil then
        Log.fatal("Cant play legacy animation, animation not found in ", go.name)
        return
    end
    if table.count(self._disappearLegacyAnimNames) > 1 then
        anim:Stop()
        for i = 1, #self._disappearLegacyAnimNames do
            anim:PlayQueued(self._disappearLegacyAnimNames[i])
        end
    else
        anim:Play(self._disappearLegacyAnimNames[1])
    end
end

---@param entity Entity
function PlayMoveTrapInstruction:_DoTrapAppear(entity)
    if self._appearLegacyAnimNames then
        if not entity:HasView() then
            return
        end
        local go = entity:View():GetGameObject()
        ---@type UnityEngine.Animation
        local anim = go:GetComponentInChildren(typeof(UnityEngine.Animation))
        if anim == nil then
            Log.fatal("Cant play legacy animation, animation not found in ", go.name)
            return
        end
        if table.count(self._appearLegacyAnimNames) > 1 then
            anim:Stop()
            for i = 1, #self._appearLegacyAnimNames do
                anim:PlayQueued(self._appearLegacyAnimNames[i])
            end
        else
            anim:Play(self._appearLegacyAnimNames[1])
        end
    end

    if self._appearEffID then
        ---@type MainWorld
        local world = entity:GetOwnerWorld()
        ---@type BoardServiceRender
        local boardSvc = world:GetService("BoardRender")
        local pos = boardSvc:GetRealEntityGridPos(entity)
        ---@type EffectService
        local effectSvc = world:GetService("Effect")
        effectSvc:CreateWorldPositionEffect(self._appearEffID, pos)
    end
end
