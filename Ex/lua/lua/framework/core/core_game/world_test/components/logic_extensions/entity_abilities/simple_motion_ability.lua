
require "entity_ability"

---@class EntityAbilitysLookup_Test
_autoEnum("EntityAbilitysLookup_Test", {
    "GroundMotion",     --地面运动能力
})

for key, value in pairs(EntityAbilitysLookup_Test) do
    EntityAbilitysLookup[key] = value
end


--[[------------------------------------------------------------------------------------------
    SimpleMotionAbility
    简单示例： 
    SimpleMotionAbility 只管理Enity上的一个Component实现简单的 无碰撞地面匀速移动功能

    多想一些：
    如果是一个轮滑游戏，类似能力就可能会包含：加速、转向漂移、急停、减速、碰撞等复杂逻辑。
    更可能的是把上述内容分成多个能力： 
        转向能力： 没有这个就是火箭、弹珠...  除了修正速度朝向、还要配合管理身体倾斜的动画融合
        驱动能力（加、减速）：  还要控制不动速度下动画的样式和播放速率不同 
        急停能力： 刚学轮滑的人没有这能力只好撞墙...  处理急停惯性、特殊动画、脚下烟尘特效

]]--------------------------------------------------------------------------------------------

------@class SimpleMotionAbility:EntityAbility
_class( "SimpleMotionAbility", EntityAbility )

function SimpleMotionAbility:Constructor()
    self.m_abilityType = EntityAbilitysLookup.GroundMotion
end

function SimpleMotionAbility:OnDisable() 
    self.m_owner:RemoveMovement()
end

function SimpleMotionAbility:HandleCommand(cmd) 
    Log.debug("SimpleMotionAbility:HandleCommand.."..cmd.CommandType)
    if cmd.CommandType == "AxisOperation" then
        Log.debug("Operation x = "..cmd.AxleX.." ,  y = "..cmd.AxleY)
        local e = self.m_owner
        if cmd.AxleX == 0 and cmd.AxleY == 0  then
            e:RemoveMovement()
        else
            local velocityXZ = e:Attributes():GetAttribute("Speed")
            Log.debug("velocityXZ  = "..velocityXZ)
            e:ReplaceMovement(MovementByDirection:New(Vector3(cmd.AxleX, 0, cmd.AxleY), velocityXZ))
        end
    end

end