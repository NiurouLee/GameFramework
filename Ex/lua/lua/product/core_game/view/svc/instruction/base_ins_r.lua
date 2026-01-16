_class("BaseInstruction", Object)
---@class BaseInstruction: Object
BaseInstruction = BaseInstruction

function BaseInstruction:Constructor(params)
    ---基类里解析label
    self._label = params["label"]
end

---目前还没用
function BaseInstruction:GetInstructionType()
end

---取出当前指令的label
function BaseInstruction:GetInstructionLabel()
    return self._label
end

---指令的具体执行
---@param casterEntity Entity 施法者
---@param phaseContext SkillPhaseContext 当前指令集合的上下文，用于存储数据
function BaseInstruction:DoInstruction(TT, casterEntity, phaseContext)
end

---提取指令需要缓存的资源
function BaseInstruction:GetCacheResource(skillConfig,skinId)
end

---提取指令需要缓存的音效资源
function BaseInstruction:GetCacheAudio()
end

---提取指令需要缓存的语音资源
function BaseInstruction:GetCacheVoice()
end


---@param casterEntity Entity
---@return number 技能ID
function BaseInstruction:GetSkillID(casterEntity)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillRoutine():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    return skillID
end

---@param casterEntity Entity
---@return PlaySkillInstructionService
function BaseInstruction:PlaySkillInstruction(casterEntity)
    local world = casterEntity:GetOwnerWorld()
    local sPlaySkillInstruction = world:GetService("PlaySkillInstruction")
    return sPlaySkillInstruction
end

function BaseInstruction:GetEffectResCacheInfo(effectID, count)
    count = count or 1

    if not effectID then
        return nil
    end

    if not Cfg.cfg_effect[effectID] then
        Log.exception(self._className, "effectID not found: ", tostring(effectID))
        return nil
    end

    local resPath = Cfg.cfg_effect[effectID].ResPath
    if not ResourceManager:GetInstance():HasResource(resPath) then
        Log.exception(self._className, "res not found: ", tostring(resPath))
        return nil
    end
    
    return {resPath, count}
end

---@param anyEntity Entity
function BaseInstruction:CreateInstructionEnv(anyEntity)
    if not anyEntity then
        return {}
    end

    local world = anyEntity:GetOwnerWorld()
    ---@type UtilDataServiceShare
    local utilData = world:GetService("UtilData")
    ---@type UtilCalcServiceShare
    local utilCalc = world:GetService("UtilCalc")
    ---@type EffectService
    local rsvcEffect = world:GetService("Effect")
    ---@type PlayBuffService
    local rsvcBuff = world:GetService("PlayBuff")
    ---@type PlayDamageService
    local rsvcDamage = world:GetService("PlayDamage")

    -- local _ENV不让提交，所以这么写没有任何意义
    --return setmetatable({
    --    world = world,
    --    rsvcEffect = rsvcEffect,
    --    rsvcBuff = rsvcBuff,
    --    rsvcDamage = rsvcDamage,
    --}, {__index = _G})

    return {
        world = world,
        utilData = utilData,
        utilCalc = utilCalc,
        effectService = rsvcEffect,
        playBuffService = rsvcBuff,
        playDamageService = rsvcDamage
    }
end
