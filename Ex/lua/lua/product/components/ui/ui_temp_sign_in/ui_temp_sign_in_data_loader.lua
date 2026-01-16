--[[
    活动数据加载类 
]]

---@class UITempSignInDataLoader:Object
_class("UITempSignInDataLoader", Object)
UITempSignInDataLoader = UITempSignInDataLoader


function UITempSignInDataLoader:SetData(params)
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UITempSignInDataLoader:LoadData(TT)
    local signInModule = GameGlobal.GetModule(SignInModule)
    local res = signInModule:RequestNewPlayerSignupStatus(TT)
end
