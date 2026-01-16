--数值判定方式
CompareNumType = {
    LessThan = 1, --<
    LessEquals = 2, --<=
    Equals = 3, --==
    MoreThan = 4, -->
    MoreEquals = 5 -->=
}

--判定函数
CompareNumber = function(c, x, y)
    if c == CompareNumType.LessThan then
        return x < y
    elseif c == CompareNumType.LessEquals then
        return x <= y
    elseif c == CompareNumType.Equals then
        return x == y
    elseif c == CompareNumType.MoreThan then
        return x > y
    elseif c == CompareNumType.MoreEquals then
        return x >= y
    end
end
