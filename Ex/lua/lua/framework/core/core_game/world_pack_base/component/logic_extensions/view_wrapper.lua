--[[******************************************************************************************
    View Wrapper Extensions：

    职责：
    View Wrapper 是一个Entity完整 View 概念的封装
    对外隔离了渲染引擎的依赖，隔离了绘制实现细节的内部约定

    拿Unity举例来说他可以是一个gameObject（RPG的主角）， 也可以是一堆gameObject（SLG的一队兵）

    因为各种view可能会有很大的差距，所以其可支持的行为也可能不同，所以为了不让逻辑代码跟具体的View耦合，
    调用其行为的时候都通过下面的这种Signal， 目的就是让大家不同轻易的在逻辑代码中去添加跟具体View相关的代码

--******************************************************************************************]] --

---@class IViewWrapper:Object
_class("IViewWrapper", Object)
IViewWrapper = IViewWrapper

function IViewWrapper:Constructor()
    self.ViewType = "invalid"
end

function IViewWrapper:FindChild(name)
    return nil
end
