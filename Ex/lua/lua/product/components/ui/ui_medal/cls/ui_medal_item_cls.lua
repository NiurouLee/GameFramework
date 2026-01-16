--
---@class UIMedalItemData : Object
---@field _tplItem table cfg_item
_class("UIMedalItemData", Object)
UIMedalItemData = UIMedalItemData

function UIMedalItemData:Constructor()
    ---@type cfg_item_medal
    self._template = nil
    self._tplItem = nil
    ---@type client_medal
    self.data = nil
    ---@type ItemModule
    self.itemModule = GameGlobal.GetModule(ItemModule)
    self._itemPstId = nil
end
---@param medal client_medal
function UIMedalItemData:Init(medal)
    self.data = medal
    self._template = Cfg.cfg_item_medal [self.data.medal_id]
    self._tplItem = Cfg.cfg_item [self.data.medal_id]
    if not self._template then
        Log.error("[UIMedalItemData] can't find cfg_item_medal with id = " .. self.data.medal_id)
    end
    if self:IsReceive() then
        local items = self.itemModule:GetItemByTempId(self.data.medal_id)
        if items and table.count(items)>0 then
            for key, value in pairs(items) do
                self._itemPstId = key
                break
            end
        end
    else
        self._itemPstId = nil
    end
end

function UIMedalItemData:GetPstId()
    return self._itemPstId    
end

--获得勋章ID
function UIMedalItemData:GetID()
    if self.data then
        return self.data.medal_id
    end
end
--获得模板ID
function UIMedalItemData:GetTemplID()
    if self._template then
        return self._template.ID
    end

    return nil
end
--获得模板
function UIMedalItemData:GetTempl()
    return self._template
end

--region cfg_item 相关
---获取道具模板
function UIMedalItemData:GetTemplateItem()
    return self._tplItem
end
function UIMedalItemData:GetIconItem()
    local cfgv = self:GetTemplateItem()
    return cfgv.Icon
end
--endregion

function UIMedalItemData:IsNew()
    if not self:IsReceive() then
        return false
    end

    if not self._tplItem.ShowNew or self._tplItem.ShowNew ~= 1 then
        return false
    end

    local item = self.itemModule:FindItem(self._itemPstId)
    if not item then
        return false
    end
    
    return item:IsNew()
end

function UIMedalItemData:IsReceive()
    return self.data.status == RewardStatus.E_MEDAL_REWARD_RECVED
end

--功能未解锁
---@type boolean
function UIMedalItemData:IsFunctionLock()
    return self.data.status == RewardStatus.E_MEDAL_REWARD_FUNCTION_LOCK
end

---@return RewardStatus
function UIMedalItemData:GetStatus()
    return self.data.status
end

function UIMedalItemData:GetProgress()
    local progress = 0
    local curInfo = ""
    local totalInfo = ""

    local molecule = 0
    local denominator = 0
    -- if self.data.condition_type == ConditionType.CT_MissionID then
    --     local discoverData = GameGlobal.GetModule(MissionModule):GetDiscoveryData()
    --     local curNode = discoverData:GetNodeDataByStageId(self.data.cur_progress)
    --     if curNode then
    --         molecule = curNode.fullIdx
    --         curInfo = curNode.name
    --     end

    --     local totalNode = discoverData:GetNodeDataByStageId(self.data.total_progress)
    --     if totalNode then
    --         denominator = totalNode.fullIdx
    --         totalInfo = totalNode.name
    --     end
    -- --elseif self.data.condition_type == ConditionType.CT_ExMissionID then
    -- else
        molecule = self.data.cur_progress
        denominator = self.data.total_progress
        curInfo = self.data.cur_progress
        totalInfo = self.data.total_progress
    --end

    if denominator > 0 then
        progress = math.min(1, molecule / denominator)
    end
    return progress, curInfo, totalInfo
end
