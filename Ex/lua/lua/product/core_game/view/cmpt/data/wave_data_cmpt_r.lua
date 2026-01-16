--[[------------------------------------------------------------------------------------------
    WaveDataComponent : 波次数据组件，存储逻辑通知的波次状态数据
]] --------------------------------------------------------------------------------------------

---@class WaveDataComponent: Object
_class("WaveDataComponent", Object)

function WaveDataComponent:Constructor()
    ---波次索引
    self._waveIndex = -1

    ---是否是逃脱关
    self._isCurWaveExit = false

    ---逃脱机关位置
    self._exitTrapPos = nil
end

function WaveDataComponent:SetWaveIndex(index)
    self._waveIndex = index
end

function WaveDataComponent:GetWaveIndex()
    return self._waveIndex
end

function WaveDataComponent:SetExitWave(isExit)
    self._isCurWaveExit = isExit
end

function WaveDataComponent:IsExitWave()
    return self._isCurWaveExit
end

function WaveDataComponent:SetExitWavePos(pos)
    self._exitTrapPos = pos
end

function WaveDataComponent:GetExitWavePos()
    return self._exitTrapPos
end

 ---@return WaveDataComponent
function Entity:WaveData()
    return self:GetComponent(self.WEComponentsEnum.WaveData)
end

function Entity:HasWaveData()
    return self:HasComponent(self.WEComponentsEnum.WaveData)
end

function Entity:AddWaveData()
    local index = self.WEComponentsEnum.WaveData
    local component = WaveDataComponent:New()
    self:AddComponent(index, component)
end

function Entity:ReplaceWaveData()
    local index = self.WEComponentsEnum.WaveData
    local component = WaveDataComponent:New()
    self:ReplaceComponent(index, component)
end

function Entity:RemoveWaveData()
    if self:HasWaveData() then
        self:RemoveComponent(self.WEComponentsEnum.WaveData)
    end
end
