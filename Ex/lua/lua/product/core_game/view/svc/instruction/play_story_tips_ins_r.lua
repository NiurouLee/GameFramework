require("base_ins_r")
---将施法星灵的头像拉出来
---@class PlayStoryTipsInstruction: BaseInstruction
_class("PlayStoryTipsInstruction", BaseInstruction)
PlayStoryTipsInstruction = PlayStoryTipsInstruction

function PlayStoryTipsInstruction:Constructor(paramList)
	self._prob = tonumber(paramList["prob"])
	self._tipsList = paramList["tipsList"]
	local tmp = string.split(self._tipsList,"|")
	self._tipsList= {}
	for _, v in ipairs(tmp) do
		table.insert(self._tipsList,tonumber(v))
	end
end

---@param casterEntity Entity
function PlayStoryTipsInstruction:DoInstruction(TT, casterEntity, phaseContext)
	---@type MainWorld
	local world = casterEntity:GetOwnerWorld()
	local rand = Mathf.Random(1,100)
	if rand<= self._prob then
		local index = Mathf.Random(1,#self._tipsList)
		---@type InnerStoryService
		local innerStoryService = world:GetService("InnerStory")
		if casterEntity:HasSuperEntity() then
			casterEntity = casterEntity:GetSuperEntity()
		end
		if casterEntity:MonsterID() then
			innerStoryService:DoMonsterStoryTips(casterEntity:MonsterID():GetMonsterID(),casterEntity:GetID(), tonumber(self._tipsList[index]))
		elseif casterEntity:PetPstID() then
			innerStoryService:DoPetStoryTips(casterEntity:PetPstID():GetPstID(),casterEntity, tonumber(self._tipsList[index]))
		elseif casterEntity:ChessPet() then
			innerStoryService:DoChessStoryTips(casterEntity:ChessPet():GetChessPetClassID(),casterEntity:GetID(), tonumber(self._tipsList[index]))
		end
	end
end
