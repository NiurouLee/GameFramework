require "framework/core/core_game/unit_test/coregame_unit_test"

package_path = package_path ..';framework/core/core_game/world_pack_rpg/helper/multi_modify_value/?.lua'
require "multi_modify_value"
require "multi_modify_value_ex"


local v_last = MultModifyValue_Last:New(1)
print(v_last:Value())

v_last:AddModify(2, 101)
v_last:AddModify(3, 102)
print(v_last:Value())

v_last:RemoveModify(102)
print(v_last:Value())


local b_and = MultModifyBool_AND:New()
b_and:AddModify(true, "change1")
print(b_and:Value())
b_and:AddModify(false, "change1")
print(b_and:Value())

b_and = MultModifyBool_AND:New(false)
print(b_and:Value())
b_and:AddModify(true, "change1")
print(b_and:Value())

ff = io.read()

