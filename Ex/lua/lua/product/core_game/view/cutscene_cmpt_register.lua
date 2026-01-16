--[[------------------------------------------------------------------------------------------
    剧情使用的表现组件
]] --------------------------------------------------------------------------------------------

require("enum_lookup")
CutsceneComponentsRegister =
    ComponentsLookup:New(
    {
        "RenderStartIndex",
        --局内逻辑表现共享组件
        "EntityType",
        --
        -----------------------------CutscenePackInstaller
        "CutscenePlayer",
        "CutsceneMonster",
        -----------------------------

        "Asset",
        "View",
        "Location",
        "GridMove",
        "BodyArea",
        "Hitback",
        "RenderBoard",
        --anima
        "AnimatorController",
        "LegacyAnimation",
        "MaterialAnimation",
        "TrailEffectEx",
        --effect
        "ArchivedEffect",
        "EffectController",
        "EffectHolder",
        "GridEffect",
        --Count
        "TotalRenderComponents"
    }
)

CutsceneUniqueComponentsRegister =
    ComponentsLookup:New(
    {
        "RenderUniqueStartIndex",
        -----
        "LocalPlayer",
        --Count
        "TotalRenderUniqueComponents"
    }
)
