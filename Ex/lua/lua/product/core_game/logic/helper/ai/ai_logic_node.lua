--[[-------------------------------------------
    基于CustomLogic的AILogic实现
    使用行为树的形式
    如果有多个根节点 会根据顺序器逻辑执行节点
--]] -------------------------------------------
--require "ai_node_new"
-- require "ai_config"
--require "ai_node_active_tree"

----------------------------------------------------------------
---@class EnumAIGenInfo
local EnumAIGenInfo = {
    Base = 0, ---基类
    Monster = 1, ---怪物
    AiConfig = 2 ---使用cfg_ai表来解释
}
_enum("EnumAIGenInfo", EnumAIGenInfo)

_class("AIGenInfoBase", Object)
---@class AIGenInfoBase:Object
AIGenInfoBase = AIGenInfoBase

---@param aiLogicType AILogicPeriodType
function AIGenInfoBase:Constructor(world, ownerEntity)
    self.m_world = world
    self.OwnerEntity = ownerEntity
    ---@type ConfigService
    self._configService = self.m_world:GetService("Config")
    self.CustomLogicConfigTable = AILogicConfig
    self.CustomLogicConfigID = 0
    self.m_listAiSkill = {}
end

function AIGenInfoBase:GetSkillList()
    return self.m_listAiSkill
end
function AIGenInfoBase:SetSkillList(skillList)
    self.m_listAiSkill = skillList
end
function AIGenInfoBase:GetLogicType()
    return self.m_nAiLogicType
end
function AIGenInfoBase:GetGenInfoType()
    return EnumAIGenInfo.Base
end

--region AIGenInfo
_class("AIGenInfo", AIGenInfoBase)
---@class AIGenInfo:AIGenInfoBase
AIGenInfo = AIGenInfo

---@param aiLogicType AILogicPeriodType
function AIGenInfo:Constructor(world, ownerEntity, configID, monsterID, aiLogicType)
    self.CustomLogicConfigID = configID
    self.m_listAiSkill = self:_InitSkillList(monsterID)
    self.m_nAiLogicType = aiLogicType
end

function AIGenInfo:GetGenInfoType()
    return EnumAIGenInfo.Monster
end

function AIGenInfo:_InitSkillList(nWorkID)
    local monsterID = nWorkID
    if not monsterID then
        monsterID = self.OwnerEntity:MonsterID():GetMonsterID()
    end
    local listReturn = {}
    if monsterID > 0 then
        ---@type MonsterConfigData
        local monsterConfig = self._configService:GetMonsterConfigData()
        listReturn = monsterConfig:GetMonsterSkillIDs(monsterID)
    end
    return listReturn
end
--endregion

--region AIGenInfoByConfig
_class("AIGenInfoByConfig", AIGenInfoBase)
---@class AIGenInfoByConfig : AIGenInfoBase
AIGenInfoByConfig = AIGenInfoByConfig

---@param aiLogicType AILogicPeriodType
function AIGenInfoByConfig:Constructor(world, ownerEntity, nConfigAiKey)
    ---@type AiConfigData_Single
    local aiConfigData = self._configService:GetAiConfigData():GetAiObject(nConfigAiKey)
    self.CustomLogicConfigID = aiConfigData.m_nLogicID
    ---@type AiConfigData_Single
    self._configAiData = aiConfigData
    self.m_listAiSkill = self._configAiData.m_listSkillID
end

function AIGenInfoByConfig:GetGenInfoType()
    return EnumAIGenInfo.AiConfig
end

function AIGenInfoByConfig:GetLogicID()
    return self._configAiData.m_nLogicID
end
function AIGenInfoByConfig:GetLogicType()
    return self._configAiData.m_nLogicType
end
function AIGenInfoByConfig:GetLogicOrder()
    return self._configAiData.m_nLogicOrder
end
function AIGenInfoByConfig:IsPreview()
    return self._configAiData.m_bPreview
end
function AIGenInfoByConfig:GetSkillList()
    return self._configAiData.m_listSkillID
end
function AIGenInfoByConfig:GetExtParam()
    return self._configAiData.m_extParam
end
--endregion

require("ai_node_new")

_class("AILogicNode", AINewNode)
---@class AILogicNode:AINewNode
AILogicNode = AILogicNode

function AILogicNode:Constructor()
    self.InstanceID = -1
    ---@type AIGenInfo
    self.GenInfo = nil
    self.m_vecSonNodes = ArrayList:New()
    ---@type table
    self.m_mapActionList = {}
    ---@type AIActiveTree
    self.m_actionTree = AIActiveTree:New()
    ---@type AINewNode 及其派生类
    self.m_actionEnd = nil
    ---@type AILogicNode 及其派生类
    self.m_curAiNode = nil
    ---@type AINewNodeStatus
    self.m_curAiNodeStatus = AINewNodeStatus.Success
    ---ai_config.lua内配置的Logic节点信息
    self.CustomLogicID = 0
    self.CustomLogicType = ""
    self.m_bCancelLogic = false
    ---用来并行表现的标志
    self._parallelID = nil
end
---创建AI逻辑节点
---@return AILogicNode
function AILogicNode:_CreateLogicNode(nSonNodeID, context)
    local cfgSonNode = context.ConfigMng[nSonNodeID]
    ---@type AINewNode
    local sonNode = Classes[cfgSonNode.Type]:New()
    if sonNode._className == "AILogicNode" then
        sonNode:InitializeNode(cfgSonNode, context, self)
    else
        sonNode:InitializeNode(cfgSonNode, context, self, cfgSonNode.Data)
    end
    return sonNode
end
---创建AI动作节点s
---@return AILogicWorker
function AILogicNode:_CreateActionNode(cfgAction, context) --返回实际工作的AI逻辑
    local logicWorker = Classes[cfgAction.Type]:New()
    ---@type AINewNode
    logicWorker:InitializeNode(cfgAction, context, self, cfgAction.Data)
    return logicWorker
end
---@type AILogicNode    获取nSonNodeID对应的直接点
function AILogicNode:_FindSonNode(nSonNodeID)
    local vecSonNode = self.m_vecSonNodes
    for i = 1, vecSonNode:Size() do
        local sonNode = vecSonNode:GetAt(i)
        if sonNode.CustomLogicID == nSonNodeID then
            return sonNode
        end
    end
    return nil
end
--------------------------------
---@return AINewNode 的派生类
function AILogicNode:_FindSonNodeByClassName(stClassName)
    local mapSonNode = self.m_mapActionList
    for key, value in pairs(mapSonNode) do
        if key == stClassName then
            return value
        end
    end
    return nil
end
---@return AINewNode 的派生类
function AILogicNode:_FindSonNodeByID(nLogicID)
    local mapSonNode = self.m_mapActionList
    for key, value in pairs(mapSonNode) do
        if value.CustomLogicID == nLogicID then
            return value
        end
    end
    return nil
end
---创建AI逻辑节点
---@return AILogicNode
---@return AINewNode
function AILogicNode:_CreateNode_2(configNode, context)
    local newNode = nil
    local stClassName = configNode.Type
    if type(stClassName) == "number" then ---这是使用context.ConfigMng中的配置当子节点
        local nSonNodeID = stClassName
        local cfgSonNode = context.ConfigMng[nSonNodeID]
        -- 临时代码，不合回主干
        if not Classes[stClassName] then
            Log.exception("不存在的节点类型：", tostring(stClassName))
            return
        end
        -- 临时代码结束
        ---@type AILogicNode
        newNode = Classes[stClassName]:New()
        newNode:InitializeNode(cfgSonNode, context, self)
    else ---直接按照类名创建子节点
        -- 临时代码，不合回主干
        if not Classes[stClassName] then
            Log.exception("不存在的节点类型：", tostring(stClassName))
            return
        end
        -- 临时代码结束
        ---@type AINewNode
        newNode = Classes[stClassName]:New()
        newNode:InitializeNode(configNode, context, self, configNode.Data)
    end
    return newNode
end
---查找Action类，存在直接返回，不存在会创建
---@return AILogicNode
---@return AINewNode
function AILogicNode:_FindActionNode(cfgActionNode, context)
    local stClassName = cfgActionNode.Type
    local actionNode = self:_FindSonNodeByClassName(stClassName)
    if nil == actionNode then
        actionNode = self:_CreateNode_2(cfgActionNode, context)
        self.m_mapActionList[stClassName] = actionNode
    end
    return actionNode
end
---@param actionTreeNode AIActiveTreeNode
---@param nAddType AIActiveAddType
---@param cfgAction ai_config.lua 内的[10084.Action]
---@param nLogicID number
function AILogicNode:_InitAction(actionTreeNode, nAddType, cfgAction, nLogicID, context)
    if nil == nLogicID or 0 == nLogicID or nil == cfgAction then
        return
    end
    local cfgActionNode = cfgAction[nLogicID]
    if nil == cfgActionNode then
        return
    end
    local nParentLogicID = 0
    if actionTreeNode then
        nParentLogicID = actionTreeNode:GetLogicID()
    end
    ---@type AINewNode
    local actionNode = self:_FindActionNode(cfgActionNode, context)
    actionNode:SetTreeID(nLogicID)
    -- Log.debug( "[AI_Action] _InitAction [" .. nParentLogicID .. "." .. nAddType ..
    --             "] Begin: nLogicID = " .. nLogicID .. ", ActionName = " .. actionNode._className)
    ---@type AIActiveTreeNode
    local newTreeNode = self.m_actionTree:AddNode(actionTreeNode, nAddType, actionNode, nLogicID, cfgActionNode.Data)
    if newTreeNode:IsHaveInit() then
        -- Log.debug(
        --     "[AI_Action] _InitAction [" ..
        --         nParentLogicID .. "." .. nAddType .. "] End : nLogicID = " .. nLogicID .. " HaveInit"
        -- )
        return
    end
    if cfgActionNode.success and cfgActionNode.success > 0 and cfgActionNode.success <2000000000 then
        self:_InitAction(newTreeNode, AIActiveAddType.Success, cfgAction, cfgActionNode.success, context)
    end
    if cfgActionNode.failed and cfgActionNode.failed > 0 and cfgActionNode.failed <2000000000 then
        self:_InitAction(newTreeNode, AIActiveAddType.Failure, cfgAction, cfgActionNode.failed, context)
    end
    if cfgActionNode.Other then
        local nOtherCount = table.count(cfgActionNode.Other)
        if nOtherCount > 0 then
            for key, value in pairs(cfgActionNode.Other) do
                self:_InitAction(newTreeNode, AIActiveAddType.Other + key, cfgAction, value, context)
            end
        end
    end
    newTreeNode:SetHaveInit(true)
    --Log.debug("[AI_Action] _InitAction [" .. nParentLogicID .. "." .. nAddType .. "] End: nLogicID = " .. nLogicID)
end
--------------------------------
---获取从配置文件内读取到的逻辑数据
function AILogicNode:GetNodesLogicData(nLogicID, nIndex, nDefault)
    local nodeData = nil
    for i = 1, #self.m_configData do
        if self.m_configData[i].ID == nLogicID then
            nodeData = self.m_configData[i]
            break
        end
    end
    if nil == nodeData then
        Log.warn(
            "[AI]，获取从配置文件内读取到的逻辑数据: LogicID = " ..
                self.CustomLogicID ..
                    ", Type = " .. self.CustomLogicType .. ", FindnLogicID" .. nLogicID .. ", FindIndex = " .. nIndex
        )
        return nDefault or 0
    end
    if nIndex < 0 or nIndex > #nodeData.NodesData then
        return nDefault or 0
    end
    return nodeData.NodesData[nIndex]
end
---设置节点工作时使用的逻辑数据
function AILogicNode:SetLogicData(logicData)
    AILogicNode.super.SetLogicData(self, logicData)
    self.m_actionMine:SetLogicData(logicData)
end
---@param cfg table
---@param context CustomNodeContext
function AILogicNode:InitializeNode(cfg, context, parentNode)
    AILogicNode.super.InitializeNode(self, cfg, context, parentNode, cfg.Nodes) --AILogicNode的m_configData是Nodes

    self.CustomLogicID = cfg.ID
    self.CustomLogicType = cfg.Type
    self.GenInfo = context.GenInfo
    if cfg.ActionEnd and "" ~= cfg.ActionEnd then
        self.m_actionEnd = self:_CreateActionNode(cfg.ActionEnd, context)
    end
    if cfg.Action then
        local nRootLogicID = cfg.Action.rootID or 1
        if not cfg.Action[nRootLogicID] then
            Log.exception("AI:",cfg.ID,"需要一个正确的Root,当前Root:",nRootLogicID,"不存在")
        end
        self:_InitAction(nil, AIActiveAddType.All, cfg.Action, nRootLogicID, context)
        if cfg.ActionSkill then
            self.m_actionTree.m_actionSkill = self:_CreateActionNode(cfg.ActionSkill, context)
        end
    end

    local vecSonNodes = self.m_vecSonNodes
    local cfgNodesData = cfg.Nodes
    if cfg.Nodes and #cfg.Nodes > 0 then
        for key, value in pairs(cfgNodesData) do
            local nSonNodeID = value.ID
            local sonNode = self:_CreateLogicNode(nSonNodeID, context)
            vecSonNodes:PushBack(sonNode)
        end
    end
end

function AILogicNode:Reset()
    AILogicNode.super.Reset(self)
    self.m_curAiNode = nil
    self.m_bCancelLogic = false
    self.m_curAiNodeStatus = AINewNodeStatus.Success
    local vecSonNodes = self.m_vecSonNodes
    for i = 1, vecSonNodes:Size() do
        vecSonNodes:GetAt(i):Reset()
    end
    if self.m_actionEnd then
        self.m_actionEnd:Reset()
    end
    self.m_actionTree:ClearScanNode()
end
---决策
function AILogicNode:OnBegin()
    self.m_curAiNode = nil
    self.m_curAiNodeStatus = AINewNodeStatus.Success
    self.m_actionTree:ResetWorkNode()
end
---执行
function AILogicNode:OnUpdate()
    ---一个动作执行完之前不允许打断
    repeat
        if self.m_curAiNode then
            if self.m_curAiNode:IsEnableStart() then
                self.m_curAiNode:Update()
            end
            if self.m_bCancelLogic then
                self.m_curAiNode:Reset()
                self.m_curAiNode = nil
                return AINewNodeStatus.Failure
            end
            if self.m_curAiNode:IsRunning() then
                return AINewNodeStatus.Running
            else
                self.m_curAiNodeStatus = self.m_curAiNode:GetStatues()
                self.m_actionTree:MoveWorkNode(self.m_curAiNodeStatus)
                self.m_curAiNode:Reset()
                self.m_curAiNode = nil
            end
        end
        if nil == self.m_curAiNode then
            self.m_curAiNode = self:_FindWorkSonNode()
        end
    until nil == self.m_curAiNode

    return self.m_curAiNodeStatus
end
function AILogicNode:OnEnd()
    if self.m_curAiNode then
        self.m_curAiNode:Reset()
        self.m_curAiNode = nil
    end
    if self.m_actionEnd then --有
        self.m_actionEnd:Update()
        if false == self.m_actionEnd:IsSuccess() then ---只有成功才不重启逻辑
            self:Reset()
        end
    end
end

function AILogicNode:UpdateSkillAction()
    if self.m_actionTree and self.m_actionTree.m_actionSkill then
        self.m_actionTree.m_actionSkill:Reset()
        self.m_actionTree.m_actionSkill:Update()
    end
end
function AILogicNode:GetActionSkillID(preview)
    local nSkillID = self.m_actionTree:GetActionSkillID(preview)
    if nSkillID and nSkillID > 0 then
        return nSkillID
    end
    if EDITOR then
        Log.exception("GetSkillID Failed ",Log.traceback())
    end
    Log.fatal("GetSkillID Failed ",Log.traceback())
    return 0
    --return AINewNode.super.GetActionSkillID(self, preview)
end
--------------------------------操作行为树子节点执行流程
function AILogicNode:GetLogicNodeParent()
    return self.m_logicOwn or self
end
function AILogicNode:ReSelectWorkSkill()
    self.m_actionTree:ReSelectWorkSkill()
end
--------------------------------
---获取一个可以运行的子节点
function AILogicNode:_FindWorkSonNode()
    if self.m_actionTree:IsTreeValid() then
        local treeNode = self.m_actionTree:GetWorkNode()
        if nil == treeNode then
            return nil
        end
        treeNode:StartWork(self.m_actionTree:GetActionSkillID())
        return treeNode:GetWorkAction()
    end
    return nil
end

--设置本节点有效
function AILogicNode:SetActive(bActive)
    if bActive then
        self:Activate()
    else
        self:Deactivate()
    end
end

--取消正在执行的AI逻辑
function AILogicNode:CancelLogic()
    self.m_bCancelLogic = true
    self:SetActive(false)
end