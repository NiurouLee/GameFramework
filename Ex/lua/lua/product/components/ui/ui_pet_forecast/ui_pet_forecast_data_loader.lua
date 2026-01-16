--[[
    活动数据加载类 通用活动
]]

---@class UIPetForecastDataLoader:Object
_class("UIPetForecastDataLoader", Object)
UIPetForecastDataLoader = UIPetForecastDataLoader


function UIPetForecastDataLoader:SetData(params)
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIPetForecastDataLoader:LoadData(TT, res)
    ---@type SignInModule
    local signInModule = GameGlobal.GetModule(SignInModule)
    local data = signInModule:GetPredictionData()

    local ret, replyEvent = signInModule:PredictionReq(TT)
    if PetForecastData.CheckCode(ret:GetResult(), false) then
        data:Init(replyEvent.info)
        return data
    else
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ActivityCloseEvent, -1)
        res:SetSucc(false)
        Log.warn("### PredictionReq failed.")
    end
end
