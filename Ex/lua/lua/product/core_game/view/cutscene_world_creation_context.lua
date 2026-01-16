require "base_world_creation_context"
require "cutscene_pack_installer"
---------------------------------------------

--[[-------------------------------------------
    创建剧情世界的上下文
]]
_class("CutsceneWorldCreationContext", BaseWorldCreationContext)
---@class CutsceneWorldCreationContext:BaseWorldCreationContext
CutsceneWorldCreationContext = CutsceneWorldCreationContext

function CutsceneWorldCreationContext:Constructor()
    self.WCC_StartCreationIndex = 1
    self.WCC_EntityCreationProto = Entity

    local wEComponents = ComponentsLookup:New({})
    local wUniqueComponents = ComponentsLookup:New({})
    local wEMatchers = {}

    CutscenePackInstaller:InstallEntityComponentsLookup(wEComponents)
    CutscenePackInstaller:InstallUniqueComponentsLookup(wUniqueComponents)

    --Matchers 初始化依赖于 wEComponents 要放在最后
    BasePackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)
    CombatPackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)
    CutscenePackInstaller:InstallEntityMatchers(wEMatchers, wEComponents)

    self.BWCC_EComponentsEnum = wEComponents
    self.BWCC_WUniqueComponentsEnum = wUniqueComponents
    self.BWCC_EMatchers = wEMatchers

    self.level_id = 0

    self.totalComponents = wEComponents.TotalComponents
end

function CutsceneWorldCreationContext:Destructor()
    self.players = nil
end