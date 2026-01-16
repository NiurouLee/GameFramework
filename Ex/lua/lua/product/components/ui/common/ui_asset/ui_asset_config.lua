---普通的物品栏样式 组件与prefab对应关系
local normal = nil
---家园物品栏样式 组件与prefab对应关系 仅做举例
-- local homeland = nil
UIAssetConfig = {}
--通过组件类型获取该类型对应的prefab 如果normal列表里没有则默认prefab名字对应类名
--加此方法的目的是方便替换物品栏样式
---@return string prefab名称
function UIAssetConfig.GetComponentPrefab(type)
    if not normal then --首次使用时设置
        normal = {
            UIAssetComponentNew = "UIAssetComponentNew.prefab",
        }
    end
    local prefab = normal[type]
    if prefab then
        return prefab
    else
        return type._className .. ".prefab"
    end
end

-- function UIAssetConfig.GetHomelandComponentPrefab(type)
--     if not homeland then --首次使用时设置
--         homeland = {
--             UIAssetComponentNew = "UIAssetComponentNew_home.prefab",
--         }
--     end
--     local prefab = homeland[type]
--     if prefab then
--         return prefab
--     else
--         return type._className .. ".prefab"
--     end
-- end
