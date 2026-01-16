---@class UIDiffResultRoot:UICustomWidget
_class("UIDiffResultRoot", UICustomWidget)
UIDiffResultRoot = UIDiffResultRoot
--困难关关卡
function UIDiffResultRoot:OnShow(uiParam)
end
function UIDiffResultRoot:GetComponents()
    self._layout = self:GetUIComponent("UISelectObjectPath", "layout")
    self._go = self:GetGameObject("go")
end
-- ---@param info DifficultyMissionResult
function UIDiffResultRoot:SetData(stageid, stageName, conds, nodeid)
    self:GetComponents()

    if nodeid then
        self._go:SetActive(true)
        ---@type DiffMissionNode
        local node

        local nodeCfg = Cfg.cfg_difficulty_parent_mission[nodeid]
        if nodeCfg.ComponentID then
            --关联了活动组件,视为活动高难关
            -- node = DiffMissionNode:New(nodeid, nil, nil, nil, nil)
        else
            ---@type UIDiffMissionModule
            -- local uiModule = GameGlobal.GetUIModule(DifficultyMissionModule)
            -- ---@type DiffMissionNode
            -- node = uiModule:GetNode(nodeid)
        end
        --已完成的词条们
        -- local a_conds = node:Cups()
        --本次完成的词条们
        local t_conds = conds

        local all = {}
        for index, value in ipairs(t_conds) do
            table.insert(all, value)
        end
        -- for index, value in ipairs(a_conds) do
        --     table.insert(all,value)
        -- end

        ---@type UIDiffMissionModule
        local uiModule = GameGlobal.GetUIModule(DifficultyMissionModule)
        uiModule:CreateEntiesDesc()
        self._layout:SpawnObjects("UIDiffResultItem", #all)
        local pools = self._layout:GetAllSpawnList()
        for i = 1, #pools do
            local item = pools[i]
            local condID = all[i]
            local cfg = Cfg.cfg_difficulty_mission_enties[condID]
            if not cfg then
                Log.error("###[UIDiffResultRoot] cfg is nil ! id --> ", condID)
            end
            local tex = uiModule:GetDiffMissionEnties(cfg.Desc)
            local finish = false
            if table.icontains(t_conds, condID) then
                finish = true
            end
            item:SetData(tex, finish)
        end
    else
        self._go:SetActive(false)
    end
end
