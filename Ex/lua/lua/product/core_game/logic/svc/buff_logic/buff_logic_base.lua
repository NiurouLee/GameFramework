--buff逻辑基类

_class("BuffLogicBase", Object)
---@class BuffLogicBase:Object
BuffLogicBase = BuffLogicBase

---@param buffInstance BuffInstance
function BuffLogicBase:Constructor(buffInstance, logicParam)
    ---@type  BuffInstance
    self._buffInstance = buffInstance
    self._entity = buffInstance:Entity()
    ---@type MainWorld
    self._world = buffInstance:World()
    ---@type BuffLogicService
    self._buffLogicService = self._world:GetService("BuffLogic")
    self._buffComponent = self._entity:BuffComponent()
    self._logicParam = logicParam
end

function BuffLogicBase:SetLogicIndex(index)
    self._logicIndex = index
end

function BuffLogicBase:GetLogicIndex()
    return self._logicIndex
end

function BuffLogicBase:NeedCheckGameTurn()
    return false
end

function BuffLogicBase:DoLogic(notify, triggers, index)
end

function BuffLogicBase:DoOverlap(logicParam, context)
    Log.exception(self:GetLogicName(),' DoOverlap() not implemented!')
end

--获取所有逻辑名
function BuffLogicBase:GetLogicName()
    return self._logicParam.logic
end

---@return number Buff唯一码
function BuffLogicBase:GetBuffSeq()
    return self._buffInstance._buffSeq
end

function BuffLogicBase:GetWorld()
    return self._world
end

---@return Entity
function BuffLogicBase:GetEntity()
    return self._entity
end

function BuffLogicBase:GetBuffComponent()
    return self._buffComponent
end

function BuffLogicBase:GetLogicParam()
    return self._logicParam
end

---@return BuffLogicService
function BuffLogicBase:GetBuffLogicService()
    return self._buffLogicService
end


function BuffLogicBase:UpdateTeamDefenceLogic(teamEntity)
    ---@type BattleService
    local battleService = self._world:GetService("Battle")
    battleService:UpdateTeamDefenceLogic(teamEntity)
end

function BuffLogicBase:GetBuffSourceEntity()
	local buffComponent = self._entity:BuffComponent()
	if buffComponent then
		local buffSource = buffComponent:GetBuffSourceByBuffID(self._buffInstance:BuffID())
		---@type BuffLogicService
		local buffLogicService = self._world:GetService("BuffLogic")
		return buffLogicService:GetBuffSourceEntity(buffSource)
	end
	return nil
end

function BuffLogicBase:PrintBuffLogicLog(...)
    if self._world and self._world:IsDevelopEnv() then 
        Log.debug(...)

    end
end