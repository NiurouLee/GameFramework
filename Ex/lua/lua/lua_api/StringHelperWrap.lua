---@class StringHelper : object
local m = {}
---@overload fun(md5UInt:MD5UInt, sb:System.Text.StringBuilder):bool
---@overload fun(bytes:table):string
---@param md5UInt MD5UInt
---@return string
function m.ToHexString(md5UInt) end
---@param bytes table
---@param length int
---@return string
function m.ToHexStringNew(bytes, length) end
---@overload fun(h:char, l:char):byte
---@param c char
---@return byte
function m.HexCharToByte(c) end
---@param hexString string
---@return table
function m.HexStringToBytes(hexString) end
---@overload fun(hexString:string, littleEndian:bool):MD5UInt
---@param hexString string
---@return MD5UInt
function m.HexStringToMD5UInt(hexString) end
StringHelper = m
return m