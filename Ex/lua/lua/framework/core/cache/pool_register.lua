---池子类型由项目自己定义扩展
---@class PoolType
local _PoolType = {
    Role = "Role",
    Effect = "Effect",
    SpriteAtlas = "SpriteAtlas",
}
_enum("PoolType", _PoolType)
PoolType = PoolType


_staticClass("PoolRegister")

---全局缓存池可以提前在这里编辑注册的池子
---@param poolManager PoolManager
function PoolRegister:RegisterPools(poolManager)
    poolManager:CreatePool(PoolType.Role,LoadType.GameObject, 3)
    poolManager:CreatePool(PoolType.Effect,LoadType.GameObject, 10)
    poolManager:CreatePool(PoolType.SpriteAtlas,LoadType.SpriteAtlas, 2)
end