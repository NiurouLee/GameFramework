---@class HomelandBrickConnect:Object
_class("HomelandBrickConnect", Object)
HomelandBrickConnect = HomelandBrickConnect

function HomelandBrickConnect:Constructor(firstBrick, firstDirection, secondBrick, secondDirection)
    ---@type HomelandBrick
    self._firstBrick = firstBrick
    ---@type HomelandBrickDirection
    self._firstBrickDirection = firstDirection
    ---@type HomelandBrick
    self._secondBrick = secondBrick
    ---@type HomelandBrickDirection
    self._secondBrickDirection = secondDirection
    self:SetEdgeVisible(false)  
end

function HomelandBrickConnect:Destroy()
    self:SetEdgeVisible(true)
end

function HomelandBrickConnect:SetEdgeVisible(status)
    self._firstBrick:SetEdgeVisible(self._firstBrickDirection, status)
    self._secondBrick:SetEdgeVisible(self._secondBrickDirection, status)
end

function HomelandBrickConnect:Contain(brick)
    if self._firstBrick:Equal(brick) then
        return true
    end
    if self._secondBrick:Equal(brick) then
        return true
    end
    return false
end
