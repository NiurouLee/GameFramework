--[[
    资源本客户端数据类
    author by lixing
]]
---@class ClientResInstance
_class("ClientResInstance", Object)
ClientResInstance = ClientResInstance

function ClientResInstance:Constructor()
    self.entryDatas = {}
    self:InitEntryConfig()
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstid = roleModule:GetPstId()
    self.resInstanceLocalDBKey = {
        [DungeonType.DungeonType_Coin] = pstid .. "DungeonType_Coin",
        [DungeonType.DungeonType_Experience] = {
            [DungeonSubType.DungeonSubType_Blue] = pstid .. "DungeonSubType_Blue",
            [DungeonSubType.DungeonSubType_Red] = pstid .. "DungeonSubType_Red",
            [DungeonSubType.DungeonSubType_Green] = pstid .. "DungeonSubType_Green",
            [DungeonSubType.DungeonSubType_Yellow] = pstid .. "DungeonSubType_Yellow"
        },
        [DungeonType.DungeonType_AircraftMaterial] = pstid .. "DungeonType_AircraftMaterial",
        [DungeonType.DungeonType_equip] = pstid .. "DungeonType_AircraftEquip"
    }
    self.resInstanceSubLocalDBKey = pstid .. "ResInstanceSubLocalDBKey" -- 记录经验本subtype
end

function ClientResInstance:InitEntryConfig()
    local entrys = Cfg.cfg_res_instance_entry {}
    for id, cfg in ipairs(entrys) do
        local e = UIResInstanceEntryData:New(cfg)
        self.entryDatas[e:GetMainType()] = e
    end
end

--- 获取入口数量
function ClientResInstance:GetEntryCount()
    return table.count(self.entryDatas)
end

function ClientResInstance:GetEntryDatas()
    return self.entryDatas
end

--- 获取入口数据
function ClientResInstance:GetEntryById(entryId)
    return self.entryDatas[entryId]
end

--- 获取副本数据
function ClientResInstance:GetInstanceById(entryId, instanceId)
    return self.entryDatas[entryId][instanceId]
end

--- 获取副本数据byid
function ClientResInstance:GetMainTypeByInstanceId(instanceId)
    for mainType, entry in pairs(self.entryDatas) do
        local instanceData = entry:GetInstanceById(instanceId)
        if instanceData then
            return mainType
        end
    end
    return nil
end
--- 获取经验本列表
---@param subType DungeonSubType
function ClientResInstance:GetExpInstanceList(subType)
    return self.entryDatas[DungeonType.DungeonType_Experience]:GetExpInstanceList(subType)
end

function ClientResInstance:GetExpInstanceListSort(subType)
    return self.entryDatas[DungeonType.DungeonType_Experience]:GetExpInstanceListSort(subType)
end

---@public
---@param mainType DungeonType
function ClientResInstance:GetNormalInstanceList(mainType)
    return self.entryDatas[mainType]:GetInstanceList(mainType)
end

function ClientResInstance:GetLocalDBKey(mainType, subType)
    if mainType == DungeonType.DungeonType_Experience then
        return self.resInstanceLocalDBKey[mainType][subType]
    else
        return self.resInstanceLocalDBKey[mainType]
    end
end
