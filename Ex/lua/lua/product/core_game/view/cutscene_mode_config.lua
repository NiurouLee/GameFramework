--[[
    剧情需要的模块配置
--]]
CutsceneModeConfig = {
    Systems = {
        -- {Name = "EffectAttachSystem_Render", Type = "EffectAttachSystem_Render"},
        -- {Name = "EffectPlaySystem_Render", Type = "EffectPlaySystem_Render"},
        {Name = "HitbackSystem_Render", Type = "HitbackSystem_Render"},
        {Name = "GridMoveSystem_Render", Type = "GridMoveSystem_Render"},
        {Name = "AnimatorControllerSystem_Render", Type = "AnimatorControllerSystem_Render"}
    },
    UniqueComponents = {},
    Services = {
        --service begin
        {Name = "Config", Type = "ConfigService"},
        {Name = "BoardRender", Type = "BoardServiceRender"},
        {Name = "Piece", Type = "PieceServiceRender"},
        {Name = "TransformRenderer", Type = "TransformServiceRenderer"},
        {Name = "Cutscene", Type = "CutsceneServiceRender"},
        {Name = "Time", Type = "ClientTimeService"},
        {Name = "ResourcesPool", Type = "ResourcesPoolService"},
        {Name = "Resource", Type = "UnityResourceService"},
        {Name = "RenderEntity", Type = "RenderEntityService"},
        {Name = "Loading", Type = "LoadingServiceRender"},
        {Name = "Effect", Type = "EffectService"},
        {Name = "TrapRender", Type = "TrapServiceRender"}
        -- {Name = "UtilData", Type = "UtilDataServiceShare"}
        --service end
    }
}
