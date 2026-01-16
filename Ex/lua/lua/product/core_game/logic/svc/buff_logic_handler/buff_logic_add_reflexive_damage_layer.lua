--[[
    增加反伤层数
]]
--增加反伤层数
_class("BuffLogicAddReflexiveDamageLayer", BuffLogicBase)
BuffLogicAddReflexiveDamageLayer = BuffLogicAddReflexiveDamageLayer

function BuffLogicAddReflexiveDamageLayer:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue
    self._maxLayer = logicParam.maxLayer
    self._notifyType = logicParam.notifyType
end

function BuffLogicAddReflexiveDamageLayer:DoLogic(notify)
    --检查是否是自己关心的通知类型
    local notifyType = notify:GetNotifyType()
    local isMatch = false
    if self._notifyType then
        for _, v in ipairs(self._notifyType) do
            if v == notifyType then
                isMatch = true
                break
            end
        end
    else
        isMatch = true
    end
    if not isMatch then
        return
    end

    local buffCom = self._entity:BuffComponent()
    --下面是真正的逻辑
    local layerKey = "ReflexiveDamageLayer"
    local layer = 0
    layer = buffCom:GetBuffValue(layerKey) or 0
    if layer >= self._maxLayer then
        return
    end
    layer = layer + 1
    buffCom:SetBuffValue(layerKey, layer)
    local res = BuffResultLayer:New(layer)
    return res
end
