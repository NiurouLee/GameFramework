---@class DncRes
_enum(
    "DncRes",
    {
        Success = 0,
        RepeatFailed = 1
    }
)

---@class DnsProcess:DnsProcess
_class("DnsProcess", Object)
DnsProcess = DnsProcess

function DnsProcess:Constructor()
    self.cacheMap = {} --缓存解析过的域名，比如在高铁上跨地域(华南到华北)造成的动态ip变化有问题。。
    self.ipString = ""
    self.paring = false --辅助协程解析
    self.timeNum = 0
    self.sdkTime = 2000 --sdk超时时间
    self.timeMax = 25 --超时时间的次数
    self.timeOut = 100 --每次超时yield时间
    
    --（self.timeMax*self.timeOut） 一定要大于 self.sdkTime，否则c#回调luaFunc会无效
    if self.timeMax * self.timeOut <= self.sdkTime then
        Log.error("DnsProcess timeout error")
    end
end

--如果是域名直接解析
--如果是ipv4或者ipv6不需要解析，直接返回（减少一次线程开销）
function DnsProcess:AnalysisIP(TT, ipStr)

    Log.debug("[dns] ", "Analysis ip:{", ipStr, "}")
    if (self.cacheMap[ipStr] ~= nil) then
        return self.cacheMap[ipStr]
    end

    if (self:IsIP(ipStr) == true) then
        return ipStr
    end

    self.paring = true
    self.ipString = ""

    Log.debug("[dns] ", "Analysis start ip:{", ipStr, "}")
    --c#子线程异步调用
    CustomHttpDnsService.GetAddrByName(
        ipStr,
        function(str, eCode)
            
            Log.debug("[dns] ", "Analysis result ip:{", str, "}")
            if eCode == DncRes.RepeatFailed then
                Log.debug("[dns] ", "Analysis repeat ip")
                return --重入，直接弹出
            end

            self.ipString = str

            self.paring = false
        end
    )

    while (self.paring) do
        --超时处理
        self.timeNum = self.timeNum + 1
        if (self.timeNum >= self.timeMax) then
            self.paring = false
        end

        YIELD(TT, self.timeOut)
    end

    -- c#解析失败，LoginProcess 会轮询处理，这里不考虑
    --[[
    if self.ipString ~= "" then
        --解析成功一定是可用的ip地址（腾讯接口）
        self.ipString = self:ParseResult(self.ipString)
    end
    --]]

    if self.ipString == "" then
        self.ipString = CustomHttpDnsService.AgainAnalysis(ipStr)
    end

    --[[不做缓存了，有些情况缓存就错了
    if self.ipString ~= "" then
        self.cacheMap[ipStr] = self.ipString
    end
    --]]
    
    Log.debug("[dns] ", "Analysis end ip:{", self.ipString, "}")

    return self.ipString
end

--判断是否为ip
function DnsProcess:IsIP(ipStr)
    --使用c#的方法

    return CustomHttpDnsService.Ip4or6IsValid(ipStr)

    --[[ 这里只有ipv4
    if type(ipStr) ~= "string" then
        return false
    end

    --判断长度
    local len = string.len(ipStr)
    if len < 7 or len > 15 then --长度不对
        return false
    end

    --判断出现的非数字字符
    local point = string.find(ipStr, "%p", 1) --字符"."出现的位置
    if (point == nil) then
        return false
    end

    local pointNum = 0 --字符"."出现的次数 正常ip有3个"."
    local gapstart = 1
    while point ~= nil do
        if string.sub(ipStr, point, point) ~= "." then --得到非数字符号不是字符"."
            return false
        end

        pointNum = pointNum + 1
        if pointNum > 3 then
            return false
        end

        local gapstr = string.sub(ipStr, gapstart, point - 1)
        local gapdig = tonumber(gapstr) --这里也可以使用正则，就是太麻烦
        if (gapdig == nil) then
            return false
        end

        if gapdig < 0 or gapdig > 255 then --数字不对,小数的点会在上面处理，这里不用担心一定是整形
            return false
        end

        gapstart = point + 1
        point = string.find(ipStr, "%p", gapstart)
    end

    if (pointNum ~= 3) then
        return false
    end

    --最后一个点后面的字符判定（重复代码）
    local gapstr = string.sub(ipStr, gapstart, len)
    local gapdig = tonumber(gapstr)
    if (gapdig == nil) then
        return false
    end

    if gapdig < 0 or gapdig > 255 then
        return false
    end

    return true
    --]]
end

--腾讯返回的结果为"xx;xx";c#里面会返回""
function DnsProcess:ParseResult(ipStr)
    if (self:IsIP(ipStr) == true) then
        return ipStr
    end

    local point = string.find(ipStr, ";", 1) --字符"；"出现的位置
    if (point == nil) then
        return ""
    end

    local len = string.len(ipStr)
    local gapstr = string.sub(ipStr, 1, point - 1)
    if (gapstr == "0") then
        gapstr = string.sub(ipStr, point + 1, len)
        if (gapstr == "0") then
            return ""
        end
    end

    return gapstr
end
