--[[
    用来修改UI上的技能已就绪图标 光灵米洛斯
]]
_class("BuffLogicShowPowerfullRoundCountUI", BuffLogicBase)
---@class BuffLogicShowPowerfullRoundCountUI:BuffLogicBase
BuffLogicShowPowerfullRoundCountUI = BuffLogicShowPowerfullRoundCountUI

function BuffLogicShowPowerfullRoundCountUI:Constructor(buffInstance, logicParam)
	self._bShow = logicParam.show == 1
	self._resDic = logicParam.resDic
end

function BuffLogicShowPowerfullRoundCountUI:DoLogic()
	local buffResult = BuffResultShowPowerfullRoundCountUI:New(self._bShow,self._resDic)
	return buffResult
end