--[[------------------------------------------------------------------------------------------
    RandomServiceLogic : 提供逻辑随机数
]] --------------------------------------------------------------------------------------------
require("random")
_class("RandomServiceLogic", BaseService)
---@class RandomServiceLogic: BaseService
RandomServiceLogic = RandomServiceLogic

---@param world MainWorld
function RandomServiceLogic:Constructor(world)
    self._logicRandor = lcg(world.BW_WorldInfo.world_seed)
    self._logicRandCount = 0

    self._boardLogicRandor = lcg(world.BW_WorldInfo.boardSeed)
    self._boardLogicRandCount = 0
    self._world = world
    self._useBoardSeed = false
end

function RandomServiceLogic:Initialize()
    if self:GetMatchType() == MatchType.MT_WorldBoss then
        self._useBoardSeed = true
    end
    if self._world.BW_WorldInfo.world_seed ~= self._world.BW_WorldInfo.boardSeed then
        self._useBoardSeed = true
    end
end

---洗板的时候 世界Boss用棋盘的的随机数其余都用统一的
function RandomServiceLogic:BoardLogicRandSelectByMatchType(m, n)
    if self._useBoardSeed then
        return self:BoardLogicRand(m, n)
    else
        return self:LogicRand(m,n)
    end
end

function RandomServiceLogic:BoardLogicRand(m, n)
    
    -- if EDITOR then 
    --     ---@type GameFSMComponent
    --     local gameFsmCmpt = self._world:GameFSM()
    --     local gameFsmStateID = gameFsmCmpt:CurStateID()
    --     if gameFsmStateID == GameStateID.WaitInput or 
    --         gameFsmStateID == GameStateID.PreviewActiveSkill or 
    --         gameFsmStateID == GameStateID.WaitInputChain then 
    --             Log.exception("不能在预览状态下计算逻辑随机数")
    --     end
    -- end
    if EDITOR and CHECK_RENDER_ACCESS_LOGIC then 
        local debugInfo = debug.getinfo(2,'S')
        local filePath = debugInfo.short_src
        local renderIndex = string.find(filePath,"_r.lua")
        if renderIndex ~= nil then 
            Log.exception("render file :",filePath," call BoardLogicRand() ",Log.traceback())
            return nil
        end
    end    

    local randomNum = -1
    if m == nil and n == nil then
        randomNum = self._boardLogicRandor:random()
    else
        randomNum = self:Rounding(self._boardLogicRandor:random(m, n))
    end
    self._boardLogicRandCount = self._boardLogicRandCount + 1


    self._world:GetSyncLogger():Trace(
            {
                key = "BoardLogicRand",
                randCount = self._boardLogicRandCount,
                randValue = randomNum,
                --caller = debug.getinfo(2, "n").name
            }
    )
    return randomNum
end

function RandomServiceLogic:LogicRand(m, n)
    -- if EDITOR then 
    --     ---@type GameFSMComponent
    --     local gameFsmCmpt = self._world:GameFSM()
    --     local gameFsmStateID = gameFsmCmpt:CurStateID()
    --     if gameFsmStateID == GameStateID.WaitInput or 
    --         gameFsmStateID == GameStateID.PreviewActiveSkill or 
    --         gameFsmStateID == GameStateID.WaitInputChain then 
    --             Log.exception("不能在预览状态下计算逻辑随机数")
    --     end
    -- end
    if EDITOR and CHECK_RENDER_ACCESS_LOGIC then 
        local debugInfo = debug.getinfo(2,'S')
        local filePath = debugInfo.short_src
        local renderIndex = string.find(filePath,"_r.lua")
        if renderIndex ~= nil then 
            Log.exception("render file :",filePath," call LogicRand() ",Log.traceback())
            return nil
        end
    end    

    local randomNum = -1
    if m == nil and n == nil then
        randomNum = self._logicRandor:random()
    else
        randomNum = self:Rounding(self._logicRandor:random(m, n))
    end
    self._logicRandCount = self._logicRandCount + 1

    --self:LogRandom(randomNum)
    self._world:GetSyncLogger():Trace(
        {
            key = "LogicRand",
            randCount = self._logicRandCount,
            randValue = randomNum,
            --caller = debug.getinfo(2, "n").name
        }
    )
    return randomNum
end

---四舍五入取整
function RandomServiceLogic:Rounding(value)
    local f = math.floor(value)
    if f == value then
        return f
    else
        return math.floor(value + 0.5)
    end
end


function RandomServiceLogic:Shuffle(t)
    for i = 1, #t do
        local n = self:LogicRand(1, #t)
        t[i], t[n] = t[n], t[i]
    end
    return t
end

function RandomServiceLogic:ShuffleUseBoardRand(t)
    for i = 1, #t do
        local n = self:BoardLogicRand(1, #t)
        t[i], t[n] = t[n], t[i]
    end
    return t
end