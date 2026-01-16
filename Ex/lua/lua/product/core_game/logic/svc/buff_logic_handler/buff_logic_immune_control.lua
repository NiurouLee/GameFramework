--[[
    添加和去除免控
]]

--添加免控
_class("BuffLogicSetImmuneControl", BuffLogicBase)
BuffLogicSetImmuneControl = BuffLogicSetImmuneControl

function BuffLogicSetImmuneControl:Constructor(buffInstance, logicParam)
    self._layerNum = logicParam.layerNum --层数
end

function BuffLogicSetImmuneControl:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():SetFlag(BuffFlags.ImmuneControl)
end

--去除免控
_class("BuffLogicResetImmuneControl", BuffLogicBase)
BuffLogicResetImmuneControl = BuffLogicResetImmuneControl

function BuffLogicResetImmuneControl:Constructor(buffInstance, logicParam)
    self._layerNum = logicParam.layerNum --层数
end

function BuffLogicResetImmuneControl:DoLogic()
    local e = self._buffInstance:Entity()
    e:BuffComponent():ResetFlag(BuffFlags.ImmuneControl)
end

