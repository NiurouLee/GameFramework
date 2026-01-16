PetObtainHelper = {}

function PetObtainHelper.Init()
end

-- 判断utf8字符byte长度
local function chsize(char)
    if not char then
        return 0
    elseif char > 240 then
        return 4
    elseif char > 225 then
        return 3
    elseif char > 192 then
        return 2
    else
        return 1
    end
end

function PetObtainHelper.InsertChar(str, char)
    if str == nil then
        return
    end
    local text = ""
    local currentIndex = 1
    while currentIndex <= #str do
        local byte = string.byte(str, currentIndex)
        local len = chsize(byte)
        local s = string.sub(str, currentIndex, currentIndex + len - 1)
        text = text .. s .. char
        currentIndex = currentIndex + len
    end
    return text
end
