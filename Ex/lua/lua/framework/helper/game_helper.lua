---@class GameHelper:Singleton
---@field GetInstance GameHelper
_class("GameHelper", Singleton)
GameHelper = GameHelper

GameHelper.EMPTY_TABLE =
    setmetatable(
    {},
    {
        __newindex = function(t, k, v)
            error("readonly!")
        end
    }
)

function GameHelper:Constructor()
    self.callbackID = 0
end

---创建回调
---@param func 回调函数
---@param ... 任意参数
---@return Callback
function GameHelper:CreateCallback(func, ...)
    self.callbackID = self.callbackID + 1
    return Callback:New(self.callbackID, func, ...)
end
---创建Event回调
---@param gameEventType GameEventType
---@param func 回调函数
---@param ... 任意参数
---@return EventCallback
function GameHelper:CreateEventCallback(gameEventType, func, ...)
    self.callbackID = self.callbackID + 1
    local callBack = EventCallback:New(self.callbackID, func, ...)
    callBack:SetEventType(gameEventType)
    return callBack
end
---检查不定长参数
function GameHelper.IsNull(...)
    local len = select("#", ...)
    local t = {}
    for i = 1, len do
        local v = select(i, ...)
        if v then
            t[#t + 1] = v
        end
    end

    return #t == 0
end

function GameHelper.StringSplit(str, separatorPatten)
    local list = {}
    local s = 1

    repeat
        local i, j = string.find(str, separatorPatten, s)
        if i then
            list[#list + 1] = string.sub(str, s, i - 1)
            s = j + 1
        else
            list[#list + 1] = string.sub(str, s)
        end
    until not i

    return list
end

---2020-07-08 韩玉信添加
---计算A1项目的逻辑方向，最大值归化为1
function GameHelper.ComputeLogicDir(posDir)
    local nMax = math.max(math.abs(posDir.x), math.abs(posDir.y))
    if nMax ~= 0 then
        posDir.x = posDir.x / nMax
        posDir.y = posDir.y / nMax
    end
    return posDir
end
---计算两点之间距离的平方
function GameHelper.ComputeLogicDistance(posA, posB)
    local nX = posA.x - posB.x
    local nY = posA.y - posB.y
    return nX * nX + nY * nY
end
---计算两个点之间：通过4方向的行动总步长
function GameHelper.ComputeLogicStep(posA, posB)
    local nX = posA.x - posB.x
    local nY = posA.y - posB.y
    return math.abs(nX) + math.abs(nY)
end


---判断三点是否一线：方向是A=>B=>C
function GameHelper.IsPointOneLine(posA, posB, posC)
    local posDirAB = GameHelper.ComputeLogicDir( posA - posB )
    local posDirBC = GameHelper.ComputeLogicDir( posB - posC )
    
    return posDirAB == posDirBC
end
---@param posWork Vector2
function GameHelper.MakePosString(posWork)
    local stReturn = "(" .. posWork.x .. "," .. posWork.y .. ")"
    return stReturn
end

---提供一个调试方法，用于打印当前的帧
function GameHelper.GetFrameCount()
    local gameGlobal = GameGlobal:GetInstance()
    if gameGlobal.GetMainWorld then 
        return UnityEngine.Time.frameCount
    else
        return gameGlobal:GetFrameCount()
    end
end