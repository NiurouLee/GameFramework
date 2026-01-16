--[[------------------------------------------------------------------------------------------
    SkillPreviewParamParser : 技能预览解析器
]] --------------------------------------------------------------------------------------------

_class("SkillPreviewParamParser", Object)
---@class SkillPreviewParamParser: Object
SkillPreviewParamParser = SkillPreviewParamParser

function SkillPreviewParamParser:Constructor()
	---注册所有解析类型
	self._previewParamClassDict = {}
	self._previewParamClassDict[SkillPreviewType.Instruction] = SkillPreviewParamInstruction --1
end

---解析技能效果参数
function SkillPreviewParamParser:ParseSkillPreviewList(previewList)
	local _previewList ={}
	for i, v in ipairs(previewList) do
		local previewType = v.PreviewType
		local param = v.Param
		local classType = self._previewParamClassDict[previewType]
		if  classType == nil  then
			Log.fatal("ParsePreviewList Failed PreviewType:",previewType)
		end
		local paramObj = classType:New(v)
		table.insert(_previewList,paramObj)
	end
	return _previewList
end
