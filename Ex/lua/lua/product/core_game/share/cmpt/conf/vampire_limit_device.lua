---吸血额度结算装置
---@class VampireLimitDevice: Object
_class("VampireLimitDevice", Object)
VampireLimitDevice = VampireLimitDevice
function VampireLimitDevice:Constructor()
    self._limitMaxHP = 0.01
    self._baseHP = 0
    self._switch = false
    self._fromSkill = true
end

function VampireLimitDevice:ConsumeLimit(consumeValue)
    --无吸血效果
    if not self._switch then
        return nil
    end

    --如果已经没有额度了只能吸极少的血（0.01）
    if self._limitMaxHP <= 0.01 then
        return 0.01
    end

    local ret = 0.01
    --如果额度比（请求消费值+基础吸血）大，返回请求值+基础吸血，额度减去响应值
    if self._limitMaxHP >= consumeValue + self._baseHP then
        ret = consumeValue + self._baseHP
        self._limitMaxHP = self._limitMaxHP - ret
    else --如果额度比请求值小，只能返回额度值
        ret = self._limitMaxHP
        self._limitMaxHP = 0.01
    end
    --基础吸血只结算一次，所以直接清空
    self._baseHP = 0
    return ret
end

--有吸血效果时必须设置上限，不设置代表该伤害无吸血效果
function VampireLimitDevice:SetLimit(baseVampireHP, maxVampireHP, fromSkill)
    if self._switch then
        Log.fatal("当真要重复设置吸血参数？")
    end

    self._switch = true
    self._baseHP = baseVampireHP
    if maxVampireHP <= 0 then --最大值设为0或小于零的数表示无上限
        self._limitMaxHP = 999999999
    else
        self._limitMaxHP = maxVampireHP
    end
    --当前吸血参数是否来源于技能
    self._fromSkill = fromSkill
end
function VampireLimitDevice:Status()
    return self._switch, self._fromSkill
end
