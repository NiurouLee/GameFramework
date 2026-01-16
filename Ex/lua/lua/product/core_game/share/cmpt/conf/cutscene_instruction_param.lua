--[[------------------------------------------------------------------------------------------
    CutsceneInstructionParam : 指令类型表现段
]] --------------------------------------------------------------------------------------------

---@class CutsceneInstructionParam: Object
_class("CutsceneInstructionParam", Object)
CutsceneInstructionParam = CutsceneInstructionParam

function CutsceneInstructionParam:Constructor(t)
    ---解析指令集
    self._instructionSet = self:_ParseInstructionSet(t)
end

function CutsceneInstructionParam:GetInstructionSet()
    return self._instructionSet
end

function CutsceneInstructionParam:GetCacheTable()
    ---提取每条指令的资源
    local t = {}
    for _,v in ipairs(self._instructionSet) do 
        ---@type CutsceneBaseInstruction
        local insObj = v
        local resourceTable = insObj:GetCacheResource()
        if resourceTable then 
            for _,res in pairs(resourceTable) do
                table.insert(t, res)
            end
        end
    end

    return t
end

function CutsceneInstructionParam:GetSoundCacheTable()
    local t = {}
    for _,v in ipairs(self._instructionSet) do 
        ---@type CutsceneBaseInstruction
        local insObj = v
        local resourceTable = insObj:GetCacheAudio()
        if resourceTable then 
            for _,res in pairs(resourceTable) do
                table.insert(t, res)
            end
        end
    end

    return t
end

function CutsceneInstructionParam:GetVoiceCacheTable()
    local t = {}
    for _,v in ipairs(self._instructionSet) do 
        ---@type CutsceneBaseInstruction
        local insObj = v
        local resourceTable = insObj:GetCacheVoice()
        if resourceTable then 
            for _,res in pairs(resourceTable) do
                table.insert(t, res)
            end
        end
    end

    return t
end

function CutsceneInstructionParam:_ParseInstructionSet(t)
    local instructionSet = {}
    local paramString = t[1]
    local phaseInsArray = string.split(paramString,";")
    for k,v in ipairs(phaseInsArray) do 
        if string.len(v) > 1 then 
            local instruction = string.split(v,",")
            if table.count(instruction) > 0 then 
                ---解析单条指令
                local instructionType,paramList = self:_ParseInstructionParam(instruction)
                ---@type CutsceneBaseInstruction
                local instructionObj = self:_CreateInstruction(instructionType,paramList)
                instructionSet[#instructionSet + 1] = instructionObj
            end
        end
    end

    return instructionSet
end

function CutsceneInstructionParam:_CreateInstruction(instructionType,paramList)
    ---@type CutsceneBaseInstruction
    local insObject = nil
    local insClassName = instructionType .. "Instruction"
    local insClass = Classes[insClassName]
    if insClass == nil then 
        Log.fatal("Can not create instruction:",insClassName)
    else
        insObject = insClass:New(paramList)
        ---todo 缓存资源
    end

    return insObject
end

---参数是单条指令字符串
---返回指令类型和参数列表
function CutsceneInstructionParam:_ParseInstructionParam(insArray)
    local instructionType = nil
    local paramList = {}

    for k,v in ipairs(insArray) do 
        if k == 1 then
            ---去掉空格
            instructionType = string.gsub(v, "^%s*(.-)%s*$", "%1")
            --Log.fatal("instructionType:",instructionType)
        else
            local paramArray = string.split(v,"=")
            if table.count(paramArray) >= 2 then    ---2020-10-15发现有空字符串出现，做保护
                local paramName = string.gsub(paramArray[1], "^%s*(.-)%s*$", "%1") 
                local paramValue = string.gsub(paramArray[2], "^%s*(.-)%s*$", "%1") 
                paramList[paramName] = paramValue
            end
            --Log.fatal("paramName:",paramName,";paramValue:",paramValue)
        end
    end

    return instructionType,paramList
end