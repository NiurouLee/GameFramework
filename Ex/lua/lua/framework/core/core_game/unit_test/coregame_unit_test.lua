--[[-------------------------------------------
不在Unity中启动，直接做CoreGame单元测试的头文件
]]---------------------------------------------

local package_path = package.path
--base
package_path = package_path ..';tolua/?.lua'
package_path = package_path ..';tolua/misc/?.lua;tolua/System/?.lua;tolua/UnityEngine/?.lua'
package_path = package_path ..';lua_api/?.lua'
package_path = package_path ..';framework/base/?.lua'
package_path = package_path ..';framework/helper/?.lua'
package_path = package_path ..';framework/helper/containers/?.lua'
package_path = package_path ..';framework/core/core_game/?.lua'
package_path = package_path ..';framework/core/core_game/standard/?.lua'
package_path = package_path ..';framework/core/core_game/helper/?.lua'


--ecs core
package_path = package_path ..';framework/core/core_game/world_ecs/?.lua'
package_path = package_path ..';framework/core/core_game/world_ecs/world/?.lua'
package_path = package_path ..';framework/core/core_game/world_ecs/entity/?.lua'
package_path = package_path ..';framework/core/core_game/world_ecs/index/?.lua'
package_path = package_path ..';framework/core/core_game/world_ecs/group/?.lua'
package_path = package_path ..';framework/core/core_game/world_ecs/systems/?.lua'


--pack
package_path = package_path ..';framework/core/core_game/world_pack_rpg/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/helper/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/components/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/components/logic_extensions/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/services/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/services/network/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/services/resource/?.lua'
package_path = package_path ..';framework/core/core_game/world_pack_rpg/systems/?.lua'

package.path = package_path
--[[
--base
package_path = package_path ..';tolua/?.lua;tolua/misc/?.lua;tolua/System/?.lua;tolua/UnityEngine/?.lua;lua_api/?.lua;framework/lib/?.lua;framework/base/?.lua;framework/helper/?.lua;framework/helper/containers/?.lua;framework/core/core_game/?.lua;framework/core/core_game/standard/?.lua'

--ecs core
package_path = package_path ..';framework/core/core_game/world_ecs/?.lua;framework/core/core_game/world_ecs/world/?.lua;framework/core/core_game/world_ecs/entity/?.lua;framework/core/core_game/world_ecs/index/?.lua;framework/core/core_game/world_ecs/group/?.lua;framework/core/core_game/world_ecs/systems/?.lua'

--pack
package_path = package_path ..';framework/core/core_game/world_pack_rpg/?.lua;framework/core/core_game/world_pack_rpg/helper/?.lua;framework/core/core_game/world_pack_rpg/components/?.lua;framework/core/core_game/world_pack_rpg/components/logic_extensions/?.lua;framework/core/core_game/world_pack_rpg/services/?.lua;framework/core/core_game/world_pack_rpg/services/network/?.lua;framework/core/core_game/world_pack_rpg/services/resource/?.lua;framework/core/core_game/world_pack_rpg/systems/?.lua'
]]--

function table.append(ta,tb)
    for key, value in pairs(tb) do
        ta[key] = value
    end
end

-- Log = {}
-- Log.debug = print
-- Log.fatal = print
-- Log.sys = print
-- Log.warn = print

require "conf"
require "object"
require "singleton"

--各种容器
require "algorithm"
require "array_list"
require "sorted_array"
require "sorted_dictionary"

require "delegate_event"

--common_type
require "lua_math_ext"



