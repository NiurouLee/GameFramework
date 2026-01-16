--[[------------------------------------------------------------------------------------------
    RenderStateComponent : 这个记录的就是表现状态
    定义一个枚举，RenderStateType，列出来当前某个Entity处于某种表现状态，只有纯表现的会用，以后纯表现需要的状态都在这里扩展
]] --------------------------------------------------------------------------------------------

---表现状态类型枚举
---@class RenderStateType
RenderStateType = {
    None = 0, ---无
    PlayingSkill = 1, ---正在释放技能（技能蓄力）
    WaitPlayTask = 2 ---需要等待播放的任务
}
_enum("RenderStateType", RenderStateType)

_class("RenderStateComponent", Object)
---@class RenderStateComponent: Object
RenderStateComponent = RenderStateComponent

function RenderStateComponent:Constructor()
    self._renderState = RenderStateType.None
    self._param = nil
    self._previewIndex = 0

    self._skillTipsEntityID = -1
end

function RenderStateComponent:SetRenderState(renderState)
    self._renderState = renderState
end

function RenderStateComponent:SetRenderStateAndParam(renderState, param)
    self._renderState = renderState
    self._param = param
end

function RenderStateComponent:GetRenderStateType()
    return self._renderState
end

function RenderStateComponent:GetRenderStateParam()
    return self._param
end

--启动新的预览过程
function RenderStateComponent:NewPreviewRoutine()
    self._previewIndex = self._previewIndex + 1
end

--获取当前预览索引
function RenderStateComponent:GetPreviewRoutineIndex()
    return self._previewIndex
end

--结束预览过程
function RenderStateComponent:ResetPreviewRoutine()
    self._previewIndex = self._previewIndex + 1
end

function RenderStateComponent:SetSkillTipsEntityID(entityID)
    self._skillTipsEntityID = entityID
end

function RenderStateComponent:GetSkillTipsEntityID()
    return self._skillTipsEntityID
end
-- As IWorldEntityComponent:
--//////////////////////////////////////////////////////////

---@param owner Entity
function RenderStateComponent:WEC_PostInitialize(owner)
    --ToDo WEC_PostInitialize
end

function RenderStateComponent:WEC_PostRemoved()
    --Do WEC_PostRemoved
end ---@return RenderStateComponent
--------------------------------------------------------------------------------------------

-- This:
--//////////////////////////////////////////////////////////

--[[------------------------------------------------------------------------------------------
    Entity Extensions
]]
function Entity:RenderState()
    return self:GetComponent(self.WEComponentsEnum.RenderState)
end

function Entity:HasRenderState()
    return self:HasComponent(self.WEComponentsEnum.RenderState)
end

function Entity:AddRenderState()
    local index = self.WEComponentsEnum.RenderState
    local component = RenderStateComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceRenderState()
    local index = self.WEComponentsEnum.RenderState
    local component = RenderStateComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveRenderState()
	Log.fatal("1111 Trace:",Log.traceback())
    if self:HasRenderState() then
        self:RemoveComponent(self.WEComponentsEnum.RenderState)
    end
end
