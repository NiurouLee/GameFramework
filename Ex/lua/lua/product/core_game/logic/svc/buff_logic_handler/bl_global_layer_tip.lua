require('buff_logic_base')

_class("BuffLogicGlobalLayerTipShow", BuffLogicBase)
---@class BuffLogicGlobalLayerTipShow:BuffLogicBase
BuffLogicGlobalLayerTipShow = BuffLogicGlobalLayerTipShow

function BuffLogicGlobalLayerTipShow:Constructor(buffInstance, logicParam)
    self._layerBuffID = logicParam.layerBuffID
    self._layerTipKey = logicParam.layerTipKey
end

function BuffLogicGlobalLayerTipShow:DoLogic(notify)
    local cfgBuff = Cfg.cfg_buff[self._layerBuffID]
    if not cfgBuff then
        Log.exception("GlobalLayerTipShow: 指定的layerBuffID不存在：", tostring(self._layerBuffID))
        return
    end

    local layerType = cfgBuff.BuffEffectType

    local buffsvc = self:GetBuffLogicService()
    local layer = buffsvc:GetBuffLayer(self:GetEntity(), layerType)
    local maxLayer = cfgBuff.LayerCount

    self:GetBuffComponent():SetBuffValue("GLOBAL_LAYER_TIP_BUFF_ID", self._layerBuffID)

    ---@class UIBattle_GlobalLayerTipInitData
    ---@field count number
    ---@field max number
    ---@field tipKey string
    local result = {
        count = layer,
        max = maxLayer,
        tipKey = self._layerTipKey
    }

    return result
end

_class("BuffLogicGlobalLayerTipHide", BuffLogicBase)
---@class BuffLogicGlobalLayerTipHide:BuffLogicBase
BuffLogicGlobalLayerTipHide = BuffLogicGlobalLayerTipHide

function BuffLogicGlobalLayerTipHide:DoLogic(notify)
    return true
end

_class("BuffLogicGlobalLayerTipUpdate", BuffLogicBase)
---@class BuffLogicGlobalLayerTipUpdate:BuffLogicBase
BuffLogicGlobalLayerTipUpdate = BuffLogicGlobalLayerTipUpdate

function BuffLogicGlobalLayerTipUpdate:DoLogic(notify)
    local cBuff = self:GetBuffComponent()
    local buffID = cBuff:GetBuffValue("GLOBAL_LAYER_TIP_BUFF_ID")
    if not buffID then
        return
    end

    local cfgBuff = Cfg.cfg_buff[buffID]
    if not cfgBuff then
        return
    end

    local layerType = cfgBuff.BuffEffectType
    local buffsvc = self:GetBuffLogicService()
    local layer = buffsvc:GetBuffLayer(self:GetEntity(), layerType)
    local maxLayer = cfgBuff.LayerCount

    ---@class UIBattle_GlobalLayerTipUpdateData
    ---@field count number
    ---@field max number
    local result = {
        count = layer,
        max = maxLayer,
    }

    return result
end
