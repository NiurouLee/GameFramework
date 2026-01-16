_class("BuffLogicAddTrapExist", BuffLogicBase)
---@class BuffLogicAddTrapExist:BuffLogicBase
BuffLogicAddTrapExist = BuffLogicAddTrapExist

function BuffLogicAddTrapExist:Constructor(buffInstance, logicParam)
    self._addValue = logicParam.addValue or 0
    self._forceFull = logicParam.forceFull and true or false
    self._ignoreNextEffectUpdate = logicParam.ignoreNextEffectUpdate and true or false
    self._additionalOnZeroCurrentRound = logicParam.additionalOnZeroCurrentRound or false
end

function BuffLogicAddTrapExist:DoLogic(notify)
    local e = self._buffInstance:Entity()
    ---@type TrapComponent
    local trapCmpt = e:Trap()
    ---@type TrapDestroyType
    local trapDestroyType = trapCmpt:GetTrapDestroyType()
    ---@type TrapSelfDestroyParam
    local trapDestroyParam = trapCmpt:GetTrapDestroyParam()
    if not trapDestroyParam then
        return
    end
    local addValue = self._addValue
    local totalRound = e:Attributes():GetAttribute("TotalRound")
    local currentRound = e:Attributes():GetAttribute("CurrentRound")
    if self._additionalOnZeroCurrentRound and currentRound == 0 then
        if self._addValue < 0 then
            addValue = addValue - 1
        end
    end
    if currentRound-addValue <0 then
        addValue = currentRound
    end
    -- if self._forceFull then
    --     addValue = currentRound
    --     addValue = 2
    -- else
    --     if currentRound-addValue <0 then
    --         addValue = currentRound
    --     end
    -- end
    
    local changeValue= currentRound-addValue
    e:Attributes():Modify("CurrentRound",changeValue)
    trapDestroyParam:AddNum(addValue)

    --MSG64530 修改后currentRound >= totalRound时直接销毁
    --MSG66026 从>=改成>，因最后一回合仍然是正常状态
    local isDestroy = false
    if e:Attributes():GetAttribute("CurrentRound") > totalRound then
        e:Attributes():Modify("HP", 0)

        ---@type TrapServiceLogic
        local trapServiceLogic = self._world:GetService("TrapLogic")
        trapServiceLogic:AddTrapDeadMark(e)

        isDestroy = true
    end

    local result = BuffResultAddTrapExist:New(changeValue,self._forceFull,self._ignoreNextEffectUpdate, isDestroy)
    local res = DataAttributeResult:New(e:GetID(), "CurrentRound", changeValue)
    self._world:EventDispatcher():Dispatch(GameEventType.DataLogicResult, 0, res)
    return result
end
