---@class ChatData:Object
_class("ChatData", Object)
ChatData = ChatData

function ChatData:Constructor(id, messageType, message, emojiId, isSelf, date)
    self._id = id --消息Id
    self._messageType = messageType --消息类型
    self._message = message  --消息内容
    self._emojiId = emojiId --表情Id
    self._isSelf = isSelf --消息是否是自己发送的
    self._date = date  --消息发送的时间
    self._isShowTime = false
    self:DecodeMessage()
end

--获取消息Id
function ChatData:GetId()
    return self._id
end

--消息类型
function ChatData:GetMessageType()
    return self._messageType
end

--获取消息内容
function ChatData:GetMessage()
    return self._message
end

function ChatData:GetEmojiId()
    return self._emojiId
end

--获取消息发送时间
function ChatData:GetDate()
    return self._date
end

--获取消息发送时间字符串
function ChatData:GetDateStr()
    return TimeToDate(self._date, 'min')
end

--消息是否是自己发送的
function ChatData:IsSelf()
    return self._isSelf
end

--是否显示时间
function ChatData:IsShowTime()
    return self._isShowTime
end

--设置时间显示状态
function ChatData:SetShowTimeStatus(status)
    self._isShowTime = status
end

function ChatData:EncodeMessage()
    self._message = string.gsub(self._message, "]", "CUSTOM_RIGHT_BIG_BRACKET_BAIYEJIGUANG")
end

function ChatData:DecodeMessage()
    self._message = string.gsub(self._message, "CUSTOM_RIGHT_BIG_BRACKET_BAIYEJIGUANG", "]")
end
