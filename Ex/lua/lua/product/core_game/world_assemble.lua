require("component_filter")
--------------------------------------------------------------------------------------------

--[[------------------------------------------------------------------------------------------
    WorldAssembler:  根据 静态配置 组装World的UniqueComponents
]] _staticClass(
    "WorldAssembler"
)

function WorldAssembler.AssembleWorldComponentsBase(world)
	local game_mode = GameModeType.CommonBaseMode
	local running_position = world:GetRunningPosition()
	local gamemode_config = GameModeConfig[game_mode]
	if not gamemode_config then
		Log.debug("WorldAssembler.AssembleWorldComponents wrong game mode :", game_mode)
		return
	end

	for k, v in pairs(gamemode_config.UniqueComponents) do
		-- k是unique_component名称， v是可能会用到的用于初始化的配置数据
		--在服务器运行时过滤掉render component
		if not WorldAssembler["Init" .. k] then
			Log.fatal("AssembleWorldComponents " .. k .. " missing Init" .. k .. " func")
		elseif ComponentFilter:CheckComponent(k, running_position) then
			WorldAssembler["Init" .. k](world)
		end
	end
end

---@param entity_context EntityCreationContext
function WorldAssembler.AssembleWorldComponents(world)
    local game_mode = world.BW_WorldInfo.game_mode
    local running_position = world:GetRunningPosition()
    local gamemode_config = GameModeConfig[game_mode]
    if not gamemode_config then
        Log.debug("WorldAssembler.AssembleWorldComponents wrong game mode :", game_mode)
        return
    end

    for k, v in pairs(gamemode_config.UniqueComponents) do
        -- k是unique_component名称， v是可能会用到的用于初始化的配置数据
        --在服务器运行时过滤掉render component
        if not WorldAssembler["Init" .. k] then
            Log.fatal("AssembleWorldComponents " .. k .. " missing Init" .. k .. " func")
        elseif ComponentFilter:CheckComponent(k, running_position) then
            WorldAssembler["Init" .. k](world)
        end
    end
end

function WorldAssembler.InitInputMngComponent(world)
    world:AddInputMng()
end

function WorldAssembler.InitGameFSMComponent(world)
    world:AddGameFSM(world)
end

function WorldAssembler.InitMainCameraComponent(world)
    world:AddMainCamera(world)
end

function WorldAssembler.InitPlayerComponent(world)
    world:AddPlayer()
end

function WorldAssembler.InitInputComponent(world)
    world:AddInput(world)
end

function WorldAssembler.InitGridTouchComponent(world)
    world:AddGridTouch(world)
end

function WorldAssembler.InitSpawnMngComponent(world)
    world:AddSpawnMng(world)
end

function WorldAssembler.InitPickUpComponent(world)
    world:AddPickUp(world)
end

function WorldAssembler.InitBattleStatComponent(world)
    world:AddBattleStat(world)
end

function WorldAssembler.InitBattleRenderConfigComponent(world)
    world:AddBattleRenderConfig(world)
end

function WorldAssembler.InitBattleFlagsComponent(world)
    world:AddBattleFlags(world)
end

function WorldAssembler.InitRenderBattleStatComponent(world)
    world:AddRenderBattleStat(world)
end

function WorldAssembler.InitChessPickUpComponent(world)
    world:AddChessPickUp(world)
end

function WorldAssembler.InitMiragePickUpComponent(world)
    world:AddMiragePickUp(world)
end

function WorldAssembler.InitPopStarPickUpComponent(world)
    world:AddPopStarPickUp(world)
end
