--[[
    免疫位移
]]
---@field ImmuneHitBack number 击退 1
---@field ImmunePullAround number 拉取 2
---@field ImmuneTransportConveyor number 传送带传送 3
---@field ImmuneTransportEddy number 传送旋涡传送 4
BuffImmuneTranslateType = {
    "ImmuneHitBack",
    "ImmunePullAround",
    "ImmuneTransportConveyor",
    "ImmuneTransportEddy"
}

--添加免疫位移
---@class BuffLogicImmuneTranslate:BuffLogicBase
_class("BuffLogicImmuneTranslate", BuffLogicBase)
BuffLogicImmuneTranslate = BuffLogicImmuneTranslate

---@param logicParam number[] 免疫位移类型数组
function BuffLogicImmuneTranslate:Constructor(buffInstance, logicParam)
    self._translateTypeList = logicParam.translateType
end

function BuffLogicImmuneTranslate:DoLogic()
    local e = self._buffInstance:Entity()
    local cBuff = e:BuffComponent()
    if self._translateTypeList then
        for _, idx in ipairs(self._translateTypeList) do
            cBuff:SetBuffValue(BuffImmuneTranslateType[idx], true)
        end
    end
end

--去除免疫位移
---@class BuffLogicResetImmuneTranslate:BuffLogicBase
_class("BuffLogicResetImmuneTranslate", BuffLogicBase)
BuffLogicResetImmuneTranslate = BuffLogicResetImmuneTranslate

function BuffLogicResetImmuneTranslate:Constructor(buffInstance, logicParam)
    self._translateTypeList = logicParam.translateType
end

function BuffLogicResetImmuneTranslate:DoLogic()
    local e = self._buffInstance:Entity()
    local cBuff = e:BuffComponent()
    if self._translateTypeList then
        for _, idx in ipairs(self._translateTypeList) do
            cBuff:SetBuffValue(BuffImmuneTranslateType[idx], nil)
        end
    end
end
