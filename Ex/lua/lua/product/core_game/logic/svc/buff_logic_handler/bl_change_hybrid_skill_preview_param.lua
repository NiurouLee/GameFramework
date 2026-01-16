--[[
    更改轮播技能预览的混合技能预览参数
]]
require("buff_logic_base")

_class("BuffLogicChangeHybridSkillPreviewParam", BuffLogicBase)
---@class BuffLogicChangeHybridSkillPreviewParam : BuffLogicBase
BuffLogicChangeHybridSkillPreviewParam = BuffLogicChangeHybridSkillPreviewParam

function BuffLogicChangeHybridSkillPreviewParam:Constructor(buffInstance, logicParam)
    --同cfg_monster_class.HybridSkillPreviewParam
    self._param = logicParam["param"]
end

function BuffLogicChangeHybridSkillPreviewParam:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        buffCmpt:SetBuffValue("HybridSkillPreviewParam", self._param)
        self._world:EventDispatcher():Dispatch(GameEventType.DataBuffValue, e:GetID(), "HybridSkillPreviewParam",
            self._param)
    end
end

_class("BuffLogicUndoChangeHybridSkillPreviewParam", BuffLogicBase)
---@class BuffLogicUndoChangeHybridSkillPreviewParam : BuffLogicBase
BuffLogicUndoChangeHybridSkillPreviewParam = BuffLogicUndoChangeHybridSkillPreviewParam

function BuffLogicUndoChangeHybridSkillPreviewParam:DoLogic()
    ---@type Entity
    local e = self._buffInstance:Entity()
    ---@type BuffComponent
    local buffCmpt = e:BuffComponent()
    if buffCmpt then
        buffCmpt:SetBuffValue("HybridSkillPreviewParam", nil)
        self._world:EventDispatcher():Dispatch(GameEventType.DataBuffValue, e:GetID(), "HybridSkillPreviewParam", nil)
    end
end
