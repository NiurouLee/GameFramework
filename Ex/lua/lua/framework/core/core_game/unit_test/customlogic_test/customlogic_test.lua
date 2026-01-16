require "coregame_unit_test"

package.path = package.path ..';framework/core/core_game/helper/custom_logic/?.lua'
package.path = package.path ..';framework/core/core_game/helper/custom_nodes_foundation/?.lua'


require "config_temp_customlogic"
require "config_temp_fsm"

require "logic_fsm"

local createInfo = { ["ConfigID"] = 100 }
local fsmImp = FSMFactory:GetInstance():CreateFSM(createInfo)


CustomLogic.Static_InitConfigMng(ConfigData_CustomLogicTest)
local geninfo = { ConfigID = 10001 } 
local logic = CustomLogic.Static_CreateLogic(geninfo)

while true do
    logic:Update(0.2)
    if logic:CanStop() then
        CustomLogic.Static_DestroyLogic(logic)
        break
    end
end




ff = io.read()

