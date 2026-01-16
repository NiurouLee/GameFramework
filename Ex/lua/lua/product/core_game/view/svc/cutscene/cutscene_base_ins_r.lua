--[[------------------------------------------------------------------------------------------
    CutsceneBaseInstruction：剧情指令基类
]] --------------------------------------------------------------------------------------------

---@class CutsceneBaseInstruction: Object
_class("CutsceneBaseInstruction", Object)
CutsceneBaseInstruction = CutsceneBaseInstruction

function CutsceneBaseInstruction:Constructor(params)
    ---基类里解析label
    self._label = params["label"]
end

---目前还没用
function CutsceneBaseInstruction:GetInstructionType()
end

---取出当前指令的label
function CutsceneBaseInstruction:GetInstructionLabel()
    return self._label
end

---指令的具体执行
---@param phaseContext CutscenePhaseContext 当前指令集合的上下文，用于存储数据
function CutsceneBaseInstruction:DoInstruction(TT,phaseContext)
end

---提取指令需要缓存的资源
function CutsceneBaseInstruction:GetCacheResource()
end

---提取指令需要缓存的音效资源
function CutsceneBaseInstruction:GetCacheAudio()
end

---提取指令需要缓存的语音资源
function CutsceneBaseInstruction:GetCacheVoice()
end

function CutsceneBaseInstruction:GetCutsceneID()
    return 0
end

---@return string
function CutsceneBaseInstruction:GetEffectResCacheInfo(effectID, count)
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
