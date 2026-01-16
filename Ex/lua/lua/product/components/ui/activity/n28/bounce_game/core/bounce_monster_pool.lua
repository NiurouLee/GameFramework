--对局怪物对象池
---@class BounceMonsterPool : Object
_class("BounceMonsterPool", Object)
BounceMonsterPool = BounceMonsterPool

function BounceMonsterPool:Constructor()
end

--提前准备资源
function BounceMonsterPool:PrepareInit()
    
end

--得到一个新的怪物
function BounceMonsterPool:Get(monsterId)
    return MonsterFactory.Acquire(monsterId)
end

--回收对象
---@param monster Monster 
function BounceMonsterPool:Recyle(monster)
   MonsterFactory.Recycle(monster)
end

--清理对象池
function BounceMonsterPool:ClearPool()
    MonsterFactory.Destroy()
end