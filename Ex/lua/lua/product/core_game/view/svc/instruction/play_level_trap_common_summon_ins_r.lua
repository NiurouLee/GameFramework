--- 法官 召唤/升级机关 通用技能表现
require("base_ins_r")

---@class PlayLevelTrapCommonSummonInstruction: BaseInstruction
_class("PlayLevelTrapCommonSummonInstruction", BaseInstruction)
PlayLevelTrapCommonSummonInstruction = PlayLevelTrapCommonSummonInstruction

function PlayLevelTrapCommonSummonInstruction:Constructor(paramList)
    self._paramList = paramList

    self._destroyEffectID = tonumber(paramList.destroyEffectID)
    self._lvUpEffectID = tonumber(paramList.lvUpEffectID)
    self._maxLevelCamEffectID = tonumber(paramList.maxLevelCamEffectID)
    self._maxLevelAudioID = tonumber(paramList.maxLevelAudioID)
    self._summonDelay = tonumber(paramList.summonDelay) or 0
    self._destroyDelay = tonumber(paramList.destroyDelay) or 0
    self._destroyInterval = tonumber(paramList.destroyInterval) or 0
    self._forceMeanTime = 1
end

---@param casterEntity Entity
---@param phaseContext SkillPhaseContext
function PlayLevelTrapCommonSummonInstruction:DoInstruction(TT, casterEntity, phaseContext)
    ---@type MainWorld
    local world = casterEntity:GetOwnerWorld()

    ---@type SkillEffectResultContainer
    local routineCmpt = casterEntity:SkillRoutine():GetResultContainer()

    if not routineCmpt then
        return
    end

    ---@type SkillEffectDestroyTrapResult[]
    local resultArray = nil
    resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.LevelTrapAbsortSummon)
    if not resultArray then
        resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.LevelTrapUpLevel)
    end
    if not resultArray then
        resultArray = routineCmpt:GetEffectResultsAsArray(SkillEffectType.LevelTrapSummonOrUpLevel)
    end
    if not resultArray then
        return
    end
    ---@type EffectService
    local effectService = world:GetService("Effect")
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    local hasMaxLevel = false
    if self._lvUpEffectID and self._lvUpEffectID > 0 then
        for _,result in ipairs(resultArray) do
            ---@type SkillEffectDestroyTrapResult[]
            local destroyList = result:GetDestroyList()
            if destroyList then
                for index,destroyResult in ipairs(destroyList) do
                    local eID = destroyResult:GetEntityID()
                    local eTrap = world:GetEntityByID(eID)
                    if eTrap then
                        effectService:CreateWorldPositionEffect(self._lvUpEffectID, eTrap:GetGridPosition())
                    end
                end
            end
        end
    end
    if self._destroyDelay > 0 then
        YIELD(TT, self._destroyDelay)
    end
    for _,result in ipairs(resultArray) do
        ---@type SkillEffectDestroyTrapResult[]
        local destroyList = result:GetDestroyList()
        
        if destroyList then
            for index,destroyResult in ipairs(destroyList) do
                local eID = destroyResult:GetEntityID()
                local eTrap = world:GetEntityByID(eID)
                if eTrap then
                    trapServiceRender:PlayTrapDieSkill(TT, {eTrap},true)
                    if self._destroyEffectID and self._destroyEffectID > 0 then
                        effectService:CreateWorldPositionEffect(self._destroyEffectID, eTrap:GetGridPosition())
                    end
                    if self._destroyInterval > 0 and (index < #destroyList) then
                        YIELD(TT, self._destroyInterval)
                    end
                end
            end
        end
    end
    if self._summonDelay > 0 then
        YIELD(TT, self._summonDelay)
    end
    for _,result in ipairs(resultArray) do
        ---@type SkillSummonTrapEffectResult[]
        local summonList = result:GetSummonList()
        if result:HasMaxLevel() then
            hasMaxLevel = true
        end
        if summonList then
            for __, summonResult in ipairs(summonList) do
                local trapIDList = summonResult:GetTrapIDList()
                for i = 1, #trapIDList do
                    local trapEntity = world:GetEntityByID(trapIDList[i])
                    local summonPos = Vector2(summonResult:GetPos().x, summonResult:GetPos().y)
                    if self._forceMeanTime and self._forceMeanTime == 1 then
                        GameGlobal.TaskManager():CoreGameStartTask(
                            function()
                                self:_ShowTrap(TT, world, trapEntity, summonPos)
                            end
                        )
                    else
                        self:_ShowTrap(TT, world, trapEntity, summonPos)
                    end
                end
            end
        end
    end
    if hasMaxLevel then
        effectService:CreateScreenEffPointEffect(self._maxLevelCamEffectID)
        AudioHelperController.PlayInnerGameSfx(self._maxLevelAudioID)
    end
end
---@param trapEntity Entity
function PlayLevelTrapCommonSummonInstruction:_ShowTrap(TT, world, trapEntity,pos)
    ---@type TrapServiceRender
    local trapServiceRender = world:GetService("TrapRender")
    trapServiceRender:CreateSingleTrapRender(TT, trapEntity, true)
    trapEntity:SetPosition(pos)
end

function PlayLevelTrapCommonSummonInstruction:GetCacheResource()
    local t = {}
    if self._destroyEffectID and self._destroyEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._destroyEffectID].ResPath, 1})
    end
    if self._lvUpEffectID and self._lvUpEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._lvUpEffectID].ResPath, 1})
    end
    if self._maxLevelCamEffectID and self._maxLevelCamEffectID > 0 then
        table.insert(t, {Cfg.cfg_effect[self._maxLevelCamEffectID].ResPath, 1})
    end
    return t
end
function PlayLevelTrapCommonSummonInstruction:GetCacheAudio()
    if self._maxLevelAudioID and self._maxLevelAudioID > 0 then
        return {self._maxLevelAudioID}
    end
end