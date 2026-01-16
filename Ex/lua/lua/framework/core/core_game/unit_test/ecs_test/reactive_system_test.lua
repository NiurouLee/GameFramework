require "framework/core/core_game/unit_test/coregame_unit_test"
require "world"
require "reactive_system"

--------------------------------------------------------------
--NameComponent
_class( "NameComponent", Object )
NameComponent = NameComponent
function NameComponent:Constructor(name)
    self.name = name
end
ComponentsLookup_Test = {}
ComponentsLookup_Test.Name = 2

local name_location = Matcher:New({ComponentsLookup_Test.Name}, {}, {})


--------------------------------------------------------------
--NameChangeLogSystem
_class( "NameChangeLogSystem", ReactiveSystem )
NameChangeLogSystem = NameChangeLogSystem

function NameChangeLogSystem:Constructor(world)
    print("NameChangeLogSystem:Constructor")
end

function NameChangeLogSystem:GetTrigger(world)
    local group = world:GetGroup(name_location)
    local c = Collector:New({ group }, {"AddedOrRemoved"})
    return c
end

function NameChangeLogSystem:Filter(entity)
    return entity._components:Find(ComponentsLookup_Test.Name) ~= nil
end

function NameChangeLogSystem:ExecuteEntities(entities)
    for i = 1, #entities do
        print("NameChangeLogSystem.ExecuteEntities : "..entities[i]:GetComponent(ComponentsLookup_Test.Name).name)
    end
end

--------------------------------------------------------------
--Test Begin
local creationContext = WorldCreationContext:New()
creationContext.totalComponents = 3

local world = World:New(creationContext)

---@type Entity
local e1 = world:CreateEntity()
print("e1._retainCount = "..e1._retainCount)
e1:AddComponent(ComponentsLookup_Test.Name, NameComponent:New("entity1"))


print("world:GetGroup name_location")
---@type Group
local group = world:GetGroup(name_location)
for k,v in pairs(group._entities) do
    print(k:GetComponent(ComponentsLookup_Test.Name).name)
end
print("e1._retainCount = "..e1._retainCount)


local sys = NameChangeLogSystem:New(world)
sys:Activate()

for i = 1, 10 do
    print("----- update_"..i)

    if i == 1 then
        local c = NameComponent:New("entity1_levelA")
        e1:ReplaceComponent(ComponentsLookup_Test.Name, c)
        print("e1._retainCount = "..e1._retainCount)
    end

    if i == 2 then
        local c = NameComponent:New("entity1_levelB")
        e1:ReplaceComponent(ComponentsLookup_Test.Name, c)
    end

    sys:Execute()

end

print("sys:Deactivate()")
sys:Deactivate()

print("e1._retainCount = "..e1._retainCount)

print("world:DestroyEntity(e1)")
world:DestroyEntity(e1)
print("e1._retainCount = "..e1._retainCount)

ff = io.read()