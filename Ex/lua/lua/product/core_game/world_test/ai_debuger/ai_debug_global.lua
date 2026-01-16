if not EDITOR then
    return
end

function GetAIDebugInfo()
    ---@type AIDebugModule
    local module = GameGlobal.GetModule(AIDebugModule)
    return module:GetAIDebugInfo()
end

function GetAIDebugInfo1()
    return {{{{1,1,2,2,3,3,3,3,3,3,3,3,3},1,2,2,3,3,3,3,3,3,3,3,3},1,2,2,3,3,3,3,3,3,3,3,3},1,1,2,2,3,3,3,3,3,3,3,3,3}
end
