---@class HomelandFishRod:Object
_class("HomelandFishRod", Object)
HomelandFishRod = HomelandFishRod

function HomelandFishRod:Constructor()
    ---@type ItemModule
    local itemModule = GameGlobal.GetModule(ItemModule)
    local cfgs = Cfg.cfg_item_tool_upgrade{ToolType = 2}
    local t = {}
    for _, v in pairs(cfgs) do
        t[#t + 1] = v
    end
    table.sort(t, function(a, b)
        return a.Level > b.Level
    end)

    local fishRodId = 0
    for i = 1, #t do
        local count = itemModule:GetItemCount(t[i].ID)
        if count > 0 then
            fishRodId = t[i].ID
            break
        end
    end

    self._fishRodItemId = fishRodId --鱼竿的itemid
    local cfg = Cfg.cfg_item_tool_upgrade[fishRodId]
    self._fishingLength = cfg.param / 1000 --鱼被钓起来需要的总时长
    self._modelName = cfg.Res
    self._modelAttachPath = cfg.AttachPath
end

--获取鱼竿的物品Id
function HomelandFishRod:GetItemId()
    return self._fishRodItemId
end

--获取用该鱼竿钓鱼需要的总时长
function HomelandFishRod:GetFishingLength()
    return self._fishingLength
end

--获取模型名字
function HomelandFishRod:GetModelName()
    return self._modelName
end

--获取模型挂点路径
function HomelandFishRod:GetAttachPath()
    return self._modelAttachPath
end
