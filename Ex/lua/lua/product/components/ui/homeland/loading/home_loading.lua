--家园Loading
---@class HomeLoading:Object
_class("HomeLoading", Object)
HomeLoading = HomeLoading

--进入家园
function HomeLoading.Self()
    Log.debug("[HomelandProfile] (HomeLoading.Self) StartLoading")
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Homeland_Enter, "konggu02func")
end

--进入家园（美术场景）
function HomeLoading.Self_Art()
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Homeland_Enter, "konggu02")
end

--从主界面拜访好友家园
function HomeLoading.Visit(friendID)
    GameGlobal.TaskManager():StartTask(
        HomeLoading._CheckFriend,
        {},
        friendID,
        function()
            GameGlobal.LoadingManager():StartLoading("HomeVisitEnterLoadingHandler", "konggu02func", friendID)
        end
    )
end

--从好友家园返回自己家园
function HomeLoading.VisitToSelf()
    GameGlobal.LoadingManager():StartLoading("HomeVisitToSelfLoading", "konggu02func")
end

--从自己家园拜访好友家园
function HomeLoading.SelfToVisit(friendID)
    GameGlobal.TaskManager():StartTask(
        HomeLoading._CheckFriend,
        {},
        friendID,
        function()
            GameGlobal.LoadingManager():StartLoading("HomeSelfToVisitLoading", "konggu02func", friendID)
        end
    )
end

function HomeLoading.VisitToVisit(friendID)
    GameGlobal.TaskManager():StartTask(
        HomeLoading._CheckFriend,
        {},
        friendID,
        function()
            GameGlobal.LoadingManager():StartLoading("HomeVisitToVisitLoading", "konggu02func", friendID)
        end
    )
end

--从任意家园返回主界面
function HomeLoading.Exit(...)
    GameGlobal.LoadingManager():StartLoading(LoadingHandlerName.Homeland_Exit, "UI", ...)
end

--拜访之前先检查是否为双向好友
function HomeLoading._CheckFriend(_, TT, id, func)
    GameGlobal.UIStateManager():Lock("CheckFriendBeforeVisit")
    local res = GameGlobal.GetModule(SocialModule):HandleCEventBothwayFriend(TT, id)
    GameGlobal.UIStateManager():UnLock("CheckFriendBeforeVisit")
    if res:GetSucc() then
        func()
    else
        local m = ChatFriendManager:New()
        m:HandleErrorMsgCode(res:GetResult())
    end
end
