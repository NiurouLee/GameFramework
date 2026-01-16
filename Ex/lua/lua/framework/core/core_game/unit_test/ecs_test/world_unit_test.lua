require "framework/core/core_game/unit_test/coregame_unit_test"
require "world"

--------------------------------------------------------------
--LocationComponent
_class( "PositionComponent", Object )
PositionComponent = PositionComponent
function PositionComponent:Constructor(pos)
    self.Position = pos
end
ComponentsLookup_Test = {}
ComponentsLookup_Test.Position = 2



local creationContext = WorldCreationContext:New()
creationContext.totalComponents = 5

local world = World:New(creationContext)
local e = world:CreateEntity()
e.name = "haha"


local matcher = Matcher:New({ComponentsLookup_Test.Position}, {}, {})

local group = world:GetGroup(matcher)
for k,v in pairs(group._entities) do
    print(k.name)
end


local cmpt = PositionComponent:New(Vector3(0,0,0))
e:AddComponent(ComponentsLookup_Test.Position, cmpt)

local c = e:GetComponent(ComponentsLookup_Test.Position)
c.Position = Vector3(1,2,3)
e:ReplaceComponent(ComponentsLookup_Test.Position, c)

print("after AddComponent")
for k,v in pairs(group._entities) do
    print(k.name)
end

e:RemoveComponent(ComponentsLookup_Test.Position)

print("after RemoveComponent")
for k,v in pairs(group._entities) do
    print(k.name)
end

world:DestroyEntity(e)

ff = io.read()