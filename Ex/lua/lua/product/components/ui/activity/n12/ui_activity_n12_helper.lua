--[[
    活动辅助类
]]
---@class UIActivityN12Helper
_class("UIActivityN12Helper", Object)
UIActivityN12Helper = UIActivityN12Helper

function UIActivityN12Helper:Constructor()
end

--region n12 Entrust New
function UIActivityN12Helper.GetEntrustNewKey()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return "UIActivityN12Helper_Entrust_New_" .. roleModule:GetPstId()
end

---@param component EntrustComponent
function UIActivityN12Helper.EntrustHasNew(component)
    local key = UIActivityN12Helper.GetEntrustNewKey()
    local historyTime = 0
    if LocalDB.HasKey(key) then
        historyTime = LocalDB.GetFloat(key)
    end

    ---@type SvrTimeModule
    local timeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = timeModule:GetServerTime()
    Log.info("UIActivityN12Helper.EntrustHasNew() key = ", key, " nowTime = ", nowTime, " historyTime = ", historyTime)

    local levels = component:GetAllLevelId()
    for _, levelId in ipairs(levels) do
        local openTime = component:GetStageOpenTime(levelId) * 1000
        if nowTime >= openTime and openTime > historyTime then
            Log.info("UIActivityN12Helper.EntrustHasNew() return true, levelId = ", levelId, " openTime = ", openTime)
            return true
        end
    end

    Log.info("UIActivityN12Helper.EntrustHasNew() return false")
    return false
end

function UIActivityN12Helper.EntrustClearNew()
    local key = UIActivityN12Helper.GetEntrustNewKey()

    ---@type SvrTimeModule
    local timeModule = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = timeModule:GetServerTime()
    Log.info("UIActivityN12Helper.EntrustClearNew() key = ", key, " nowTime = ", nowTime)

    LocalDB.SetFloat(key, nowTime)
end
--endregion

--region n12帮助函数
---@param component EntrustComponent
function UIActivityN12Helper.N12_MapNode_Click(nodeid, levelId, component)
    local cfg_map_node = Cfg.cfg_campaign_entrust_event[nodeid]
    if not cfg_map_node then
        Log.error("###[UIActivityN12Helper] cfg_map_node is nil ! id --> ", nodeid)
    end
    local nodeType = cfg_map_node.EventType

    if nodeType == EntrustEventType.EntrustEventType_Box then
        UIActivityN12Helper.N12_MapNode_Box(nodeid, levelId, component)
    elseif nodeType == EntrustEventType.EntrustEventType_Story then
        UIActivityN12Helper.N12_MapNode_Story(nodeid, levelId, component)
    elseif nodeType == EntrustEventType.EntrustEventType_Fight then
        UIActivityN12Helper.N12_MapNode_Stage(nodeid, levelId, component)
    elseif nodeType == EntrustEventType.EntrustEventType_End then
        -- 先检查有没有打开过终点 banner ，打开过的话直接弹离开弹窗，否则打开 banner
        if component:GetBannerState() then
            component:SetBannerState(1)
            UIActivityN12Helper.N12_MapNode_Banner(nodeid, levelId, component)
        -- else
        --     UIActivityN12Helper.N12_MapNode_Over(nodeid, levelId, component)
        end
    elseif
        nodeType == EntrustEventType.EntrustEventType_MissionOccupy or
            nodeType == EntrustEventType.EntrustEventType_MissionSubmit
     then
        UIActivityN12Helper.N12_MapNode_Quest(nodeid, levelId, component)
    else
        Log.debug("###[UIActivityN12Helper] nodeType else ! type --> ", nodeType)
    end
end

--任务
function UIActivityN12Helper.N12_MapNode_Quest(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapQuestController", nodeid, levelId, component)
end

--终点
function UIActivityN12Helper.N12_MapNode_Over(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapExitsController", nodeid, levelId, component)
end
function UIActivityN12Helper.N12_MapNode_Banner(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapBannerController", nodeid, levelId, component)
end

--关卡
function UIActivityN12Helper.N12_MapNode_Stage(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapStageController", nodeid, levelId, component)
end

--剧情
function UIActivityN12Helper.N12_MapNode_Story(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapStoryController", nodeid, levelId, component)
end

--宝箱
function UIActivityN12Helper.N12_MapNode_Box(nodeid, levelId, component)
    GameGlobal.UIStateManager():ShowDialog("UIN12MapBoxController", nodeid, levelId, component)
end
--endregion

--region Entrust Animation
function UIActivityN12Helper.GetMapNodeAnimationKey(nodeid)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    return "UIActivityN12Helper_MapNodeAnimation_" .. roleModule:GetPstId() .. "_" .. nodeid
end
--endregion
