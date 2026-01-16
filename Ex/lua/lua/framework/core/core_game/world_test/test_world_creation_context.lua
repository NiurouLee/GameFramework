require "base_world_creation_context"
require "components_lookup_test"

--[[-------------------------------------------
    创建一个世界的上下文
]]---------------------------------------------
---@class TestWorldCreationContext:BaseWorldCreationContext
_class( "TestWorldCreationContext", BaseWorldCreationContext )

function TestWorldCreationContext:Constructor()
    self.WCC_StartCreationIndex = 1
    self.WCC_EntityCreationProto = Entity

    self.BWCC_EComponentsEnum = WEComponents_Test
    self.BWCC_EMatchers = BW_WEMatchers_Test
    self.BWCC_WUniqueComponentsEnum = WUniqueComponentsEnum_Test

    --项目特化定制
    self.WorldName = "My_Unity_Test_World"
	self.LevelID = 0
    self.GameMode = 0 
end
