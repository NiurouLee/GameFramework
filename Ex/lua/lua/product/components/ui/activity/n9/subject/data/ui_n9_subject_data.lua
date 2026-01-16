--题目数据
_class("UIN9SubjectData", Object)
---@class UIN9SubjectData:Object
UIN9SubjectData = UIN9SubjectData

function UIN9SubjectData:Constructor(cfg)
    self._id = cfg.ID
    self._grade = cfg.Grade
    self._des = StringTable.Get(cfg.Des)
    self._options = {}
    for i = 1, #cfg.Option do
        self._options[#self._options + 1] = StringTable.Get(cfg.Option[i])
    end
    self._answer = cfg.Answer
end

--获取题目Id
function UIN9SubjectData:GetId()
    return self._id
end

--获取题目等级
function UIN9SubjectData:GetGrade()
    return self._grade
end

--获取题目描述
function UIN9SubjectData:GetDes()
    return self._des
end

--获取题目选项
function UIN9SubjectData:GetOptions()
    return self._options
end

--获取题目正确答案
function UIN9SubjectData:GetAnswerIndex()
    return self._answer
end

--检查是否正确
function UIN9SubjectData:CheckIsRight(index)
    return index == self._answer
end
