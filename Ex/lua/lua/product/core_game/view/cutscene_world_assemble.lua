require("component_filter")
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    CutsceneWorldAssembler:  根据 静态配置 组装World的UniqueComponents
]] _staticClass(
    "CutsceneWorldAssembler"
)

function CutsceneWorldAssembler.AssembleCutsceneWorldComponentsBase(world)
	-- local game_mode = GameModeType.CommonBaseMode
	-- local running_position = world:GetRunningPosition()
	-- local gamemode_config = GameModeConfig[game_mode]
	-- if not gamemode_config then
	-- 	Log.debug("WorldAssembler.AssembleWorldComponents wrong game mode :", game_mode)
	-- 	return
	-- end

	-- for k, v in pairs(gamemode_config.UniqueComponents) do
	-- 	-- k是unique_component名称， v是可能会用到的用于初始化的配置数据
	-- 	--在服务器运行时过滤掉render component
	-- 	if not WorldAssembler["Init" .. k] then
	-- 		Log.fatal("AssembleWorldComponents " .. k .. " missing Init" .. k .. " func")
	-- 	elseif ComponentFilter:CheckComponent(k, running_position) then
	-- 		WorldAssembler["Init" .. k](world)
	-- 	end
	-- end
end

---@param entity_context EntityCreationContext
function CutsceneWorldAssembler.AssembleCutsceneWorldComponents(world)
    -- local game_mode = world.BW_WorldInfo.game_mode
    -- local running_position = world:GetRunningPosition()
    -- local gamemode_config = GameModeConfig[game_mode]
    -- if not gamemode_config then
    --     Log.debug("WorldAssembler.AssembleWorldComponents wrong game mode :", game_mode)
    --     return
    -- end

    -- for k, v in pairs(gamemode_config.UniqueComponents) do
    --     -- k是unique_component名称， v是可能会用到的用于初始化的配置数据
    --     --在服务器运行时过滤掉render component
    --     if not WorldAssembler["Init" .. k] then
    --         Log.fatal("AssembleWorldComponents " .. k .. " missing Init" .. k .. " func")
    --     elseif ComponentFilter:CheckComponent(k, running_position) then
    --         WorldAssembler["Init" .. k](world)
    --     end
    -- end
end
