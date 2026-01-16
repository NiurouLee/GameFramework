--[[
    风船帮助类
]]
--风船运行日志
function AirLog(...)
    -- if true then
    Log.debug("[AircraftLog] ", ...)
    -- end
end

--风船错误日志，编辑器里弹窗，手机上写日志
function AirError(...)
    if EDITOR then
        Log.exception(...)
    else
        Log.fatal("[AircraftError] ", ...)
    end
end

--风船严重错误，开启日志环境均需弹窗
function AirException(...)
    Log.exception("[AircraftError] ", ...)
end

function PopMsgBox(title, onOK)
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        title,
        onOK,
        nil,
        function(param)
            --取消
        end,
        nil
    )
end

--获取当前服务器时间（秒）
function GetSvrTimeNow()
    return math.floor(GameGlobal.GetModule(SvrTimeModule):GetServerTime() * 0.001)
end

-- function DeletePet(id)
--     local main = GameGlobal.GetModule(AircraftModule):GetClientMain()
--     local pet = main:GetPetByTmpID(id)
--     main:DestroyPet(pet)
-- end
