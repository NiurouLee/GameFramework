---@class INTL.INTLAPI : object
---@field IsDebug bool
local m = {}
function m.InitSDK() end
function m.UpdateSDK() end
function m.ShutdownSDK() end
---@param dir string
function m.SetSDKDefaultUserStorage(dir) end
---@param dir string
function m.SetSDKDefaultSharedStorage(dir) end
function m.AutoLogin() end
---@param channel string
---@param permissions string
---@param extraJson string
function m.Login(channel, permissions, extraJson) end
---@param channel string
---@param channelOnly bool
function m.Logout(channel, channelOnly) end
---@return INTL.INTLAuthResult
function m.GetAuthResult() end
function m.QueryDataProtectionAcceptance() end
---@param tos_ver string
---@param pp_ver string
function m.ModifyDataProtectionAcceptance(tos_ver, pp_ver) end
function m.QueryUserInfo() end
function m.QueryBindInfo() end
function m.QueryAccountProfile() end
function m.ResetGuest() end
---@param channel string
---@param permissions string
---@param extraJson string
function m.Bind(channel, permissions, extraJson) end
---@param channelId int
---@param uid string
---@param extraJson string
function m.Unbind(channelId, uid, extraJson) end
---@param channelId int
---@param accountPlatType int
---@param account string
---@param phoneAreaCode string
---@param extraJson string
function m.QueryCanBind(channelId, accountPlatType, account, phoneAreaCode, extraJson) end
---@param channel string
---@param channelId int
---@param langType string
---@param accountPlatType int
---@param extraJson string
function m.SetAccountInfo(channel, channelId, langType, accountPlatType, extraJson) end
---@param account string
---@param password string
---@param verifyCode string
---@param phoneAreaCode string
---@param userProfile INTL.AccountProfile
---@param extraJson string
function m.Register(account, password, verifyCode, phoneAreaCode, userProfile, extraJson) end
---@param channel string
---@param account string
---@param password string
---@param phoneAreaCode string
---@param permissionList string
function m.LoginWithPassword(channel, account, password, phoneAreaCode, permissionList) end
---@param channel string
---@param account string
---@param password string
---@param verifyCode string
---@param phoneAreaCode string
---@param permissionList string
---@param onlyLoginType int
function m.LoginWithVerifyCode(channel, account, password, verifyCode, phoneAreaCode, permissionList, onlyLoginType) end
---@param account string
---@param codeType INTL.VerifyCodeType
---@param phoneAreaCode string
---@param extraJson string
function m.RequestVerifyCode(account, codeType, phoneAreaCode, extraJson) end
function m.QueryAccountRegistrationInfo() end
---@param account string
---@param verifyCode string
---@param phoneAreaCode string
---@param newPassword string
---@param extraJson string
function m.ResetPasswordWithVerifyCode(account, verifyCode, phoneAreaCode, newPassword, extraJson) end
---@param account string
---@param oldPassword string
---@param phoneAreaCode string
---@param newPassword string
---@param extraJson string
function m.ResetPasswordWithOldPassword(account, oldPassword, phoneAreaCode, newPassword, extraJson) end
---@param oldAccount string
---@param oldAccountVerifyCode string
---@param oldPhoneAreaCode string
---@param newAccount string
---@param newAccountVerifyCode string
---@param newPhoneAreaCode string
---@param extraJson string
function m.ModifyAccountWithVerifyCode(oldAccount, oldAccountVerifyCode, oldPhoneAreaCode, newAccount, newAccountVerifyCode, newPhoneAreaCode, extraJson) end
---@param oldAccount string
---@param oldPhoneAreaCode string
---@param password string
---@param newAccount string
---@param newAccountVerifyCode string
---@param newPhoneAreaCode string
---@param extraJson string
function m.ModifyAccountWithPassword(oldAccount, oldPhoneAreaCode, password, newAccount, newAccountVerifyCode, newPhoneAreaCode, extraJson) end
---@param oldPhoneAreaCode string
---@param newAccount string
---@param newAccountVerifyCode string
---@param newPhoneAreaCode string
---@param extraJson string
function m.ModifyAccountWithLoginState(oldPhoneAreaCode, newAccount, newAccountVerifyCode, newPhoneAreaCode, extraJson) end
---@param account string
---@param phoneAreaCode string
---@param extraJson string
function m.QueryRegisterStatus(account, phoneAreaCode, extraJson) end
---@param account string
---@param verifyCode string
---@param codeType INTL.VerifyCodeType
---@param phoneAreaCode string
---@param extraJson string
function m.QueryVerifyCodeStatus(account, verifyCode, codeType, phoneAreaCode, extraJson) end
---@param account string
---@param phoneAreaCode string
---@param extraJson string
function m.QueryIsReceiveEmail(account, phoneAreaCode, extraJson) end
---@param userProfile INTL.AccountProfile
function m.ModifyProfile(userProfile) end
function m.QueryIDToken() end
function m.RevokeChannelToken() end
function m.CancelAccountDeletion() end
function m.CancelLIAccountDeletion() end
---@param password string
function m.GenerateTransferCode(password) end
function m.QueryTransferCode() end
---@param transferCode string
---@param password string
function m.TransferAccount(transferCode, password) end
---@return INTL.INTLIDTokenResult
function m.GetIDTokenResult() end
---@param userName string
function m.QueryUserNameStatus(userName) end
---@param type int
---@param extraJson string
function m.LaunchAccountUI(type, extraJson) end
---@param channel string
---@param permission string
---@param extraJson string
function m.LoginWithMappedChannel(channel, permission, extraJson) end
---@param actionType int
function m.LoginWithConfirmCode(actionType) end
function m.BuildMapWithLoggedinChannel() end
function m.QueryLegalDocumentsAcceptedVersion() end
---@param version string
function m.ModifyLegalDocumentsAcceptedVersion(version) end
---@return string
function m.GetAuthEncryptData() end
---@param encryptData string
---@param overwrite bool
---@return bool
function m.SetAuthEncryptData(encryptData, overwrite) end
---@param channel string
---@param extra_josn string
function m.CancelLogin(channel, extra_josn) end
---@param extraJson string
function m.RequestAccountInfo(extraJson) end
---@param uid string
---@param token string
---@param extraJson string
function m.RequestBindDataForAccount(uid, token, extraJson) end
---@param recentDay string
---@param extraJson string
function m.RequestGetRecentLoginDays(recentDay, extraJson) end
---@param actionType int
---@param confirmCode string
---@param extraJson string
function m.RequestLoginWithConfirmCode(actionType, confirmCode, extraJson) end
---@param channelId string
---@param confirmCode string
---@param extraJson string
function m.RequestLoginWithConfirmCodeForMail(channelId, confirmCode, extraJson) end
function m.QueryLoginRecord() end
---@param recvEmail int
function m.ChangeIsReceiveEmail(recvEmail) end
function m.UpgradeSaccToLI() end
function m.LoginUsingPluginCache() end
function m.BindUsingPluginCache() end
function m.GetLIUidAndTokenForAdultCert() end
function m.QueryNeedUpgradeAndProvisionInfo() end
---@param user_agreed_game_tos string
---@param user_agreed_game_pp string
---@param user_agreed_li_pp string
---@param user_agreed_li_dt string
---@param user_agreed_li_tos string
---@param is_recv_email int
function m.SetProvision(user_agreed_game_tos, user_agreed_game_pp, user_agreed_li_pp, user_agreed_li_dt, user_agreed_li_tos, is_recv_email) end
function m.EnterGame() end
---@param ret INTL.INTLAuthResult
function m.EnterGameFailed(ret) end
function m.AutoLoginForLI() end
---@param channel string
---@param permissions string
---@param extraJson string
function m.LoginForLI(channel, permissions, extraJson) end
---@param info INTL.INTLFriendReqInfo
---@param channel string
function m.SendMessage(info, channel) end
---@param info INTL.INTLFriendReqInfo
---@param channel string
function m.Share(info, channel) end
---@param page int
---@param count int
---@param isInGame bool
---@param channel string
---@param extraJson string
function m.QueryFriends(page, count, isInGame, channel, extraJson) end
---@param region string
---@param langType string
---@param extraJson string
---@return string
function m.RequestNoticeData(region, langType, extraJson) end
---@param channel string
---@param account string
function m.RegisterPush(channel, account) end
---@param channel string
function m.UnregisterPush(channel) end
---@param channel string
---@param tag string
function m.SetTag(channel, tag) end
---@param channel string
---@param tag string
function m.DeleteTag(channel, tag) end
---@param channel string
---@param localNotification INTL.INTLLocalNotification
function m.AddLocalNotification(channel, localNotification) end
---@param channel string
function m.ClearLocalNotifications(channel) end
---@param url string
---@param screenOrientation INTL.INTLWebViewOrientation
---@param fullScreenEnable bool
---@param encryptEnable bool
---@param systemBrowserEnable bool
---@param extraJson string
function m.OpenUrl(url, screenOrientation, fullScreenEnable, encryptEnable, systemBrowserEnable, extraJson) end
---@param url string
---@param left int
---@param top int
---@param width int
---@param height int
---@param callback System.IntPtr
---@param encryptEnable bool
---@param extraJson string
function m.OpenUrlInsideGame(url, left, top, width, height, callback, encryptEnable, extraJson) end
---@param url string
---@return string
function m.GetEncryptUrl(url) end
---@param jsonJsParam string
function m.CallJS(jsonJsParam) end
function m.InitAnalytics() end
function m.InitFirebaseSDK() end
---@param eventName string
---@param paramsDic table
---@param specificChannel string
---@param extraJson string
function m.ReportEvent(eventName, paramsDic, specificChannel, extraJson) end
---@param eventName string
---@param paramsDic table
---@param currency string
---@param revenueValue string
---@param specificChannel string
---@param extraJson string
function m.ReportRevenue(eventName, paramsDic, currency, revenueValue, specificChannel, extraJson) end
function m.RestartAnalytics() end
function m.StopAnalytics() end
---@param eventName string
---@param data string
---@param length int
---@param specificChannel string
function m.ReportBinary(eventName, data, length, specificChannel) end
function m.FlushINTLEvents() end
function m.InitCrash() end
---@param channel string
---@return string
function m.GetInstanceID(channel) end
---@param id string
function m.StartTraceRoute(id) end
---@return string
function m.StopTraceRoute() end
---@param level INTL.INTLCrashLevel
---@param tag string
---@param log string
function m.LogCrashInfo(level, tag, log) end
---@param key string
---@param value string
function m.SetCrashUserValue(key, value) end
---@param userId string
function m.SetCrashUserId(userId) end
function m.SetCrashCallback() end
---@param version string
function m.SetCrashSightAppVersion(version) end
---@param type int
---@param exceptionName string
---@param exceptionMsg string
---@param exceptionStack string
---@param extInfo table
function m.ReportException(type, exceptionName, exceptionMsg, exceptionStack, extInfo) end
---@param sessionName string
---@param extra_json string
function m.MarkSessionLoad(sessionName, extra_json) end
---@param extra_json string
function m.SetSessionExtraParam(extra_json) end
function m.MarkSessionClosed() end
---@param latencyMs int
function m.PostNetworkLatencyInSession(latencyMs) end
---@param eventName string
---@param step uint
---@param stepName string
---@param result bool
---@param errorCode int
---@param paramsJson string
function m.ReportCustomEventStep(eventName, step, stepName, result, errorCode, paramsJson) end
---@param step uint
---@param stepName string
---@param result bool
---@param errorCode int
---@param paramsJson string
function m.ReportLoginStep(step, stepName, result, errorCode, paramsJson) end
---@param step uint
---@param stepName string
---@param result bool
---@param errorCode int
---@param paramsJson string
function m.ReportPayStep(step, stepName, result, errorCode, paramsJson) end
---@return int
function m.GetDeviceLevel() end
---@param parseJson string
---@return int
function m.TestJudgeCustomDeviceLevel(parseJson) end
function m.QueryDeviceLevel() end
---@param level int
function m.SetDeviceLevel(level) end
function m.RequestTrackingAuthorization() end
function m.CollectionStop() end
function m.CollectionResume() end
---@param kstep_name INTL.FINTLFunnelStep
---@param error_code int
function m.ReportFunnel(kstep_name, error_code) end
---@param l1_event_name string
---@param l2_event_name string
---@param error_code int
function m.ReportFunnelCustomEvent(l1_event_name, l2_event_name, error_code) end
---@param extra_josn string
---@return string
function m.GetDeviceInfo(extra_josn) end
---@param guid string
---@param sceneid string
---@param isautopoll bool
---@param isautoreport bool
function m.TABInit(guid, sceneid, isautopoll, isautoreport) end
function m.TABStart() end
function m.TABRefresh() end
---@param guid string
function m.TABSwitchGuid(guid) end
---@param layerCode string
---@param isreport bool
---@return string
function m.TABGetExpInfoByLayerCode(layerCode, isreport) end
---@param name string
---@param isReport bool
---@return string
function m.TABGetExpInfoByName(name, isReport) end
---@param kstatus INTL.ComplianceAgeStatus
function m.ComplianceSetAdulthood(kstatus) end
---@param kstatus INTL.ComplianceAgreeStatus
function m.ComplianceSetEUAgreeStatus(kstatus) end
---@param email string
---@param userName string
function m.ComplianceSendEmail(email, userName) end
---@param status INTL.ComplianceParentCertificateStatus
function m.ComplianceSetParentCertificateStatus(status) end
---@param region string
function m.QueryIsEEA(region) end
function m.ComplianceVerifyCreditCard() end
---@return bool
function m.ComplianceInit() end
---@param gameID string
---@param openID string
---@param token string
---@param channelID int
---@return bool
function m.ComplianceInitWithParams(gameID, openID, token, channelID) end
function m.ComplianceQueryUserInfo() end
---@param region string
function m.ComplianceQueryStrategy(region) end
---@param region string
---@param status INTL.ComplianceAgeStatus
function m.ComplianceSetUserInfoWithAgeStatus(region, status) end
---@param region string
---@param birthday string
function m.ComplianceSetUserInfoWithBirthday(region, birthday) end
function m.ComplianceVerifyRealName() end
function m.ComplianceVerifyParentAndCertificate() end
---@param openid string
---@param isOpenId bool
---@param channelId int
function m.QueryUserInfoWithOpenId(openid, isOpenId, channelId) end
---@param userProfile INTL.INTLCustomerUserProfile
function m.InitCustomer(userProfile) end
function m.ShowAllFAQSections() end
---@param sectionId string
function m.ShowFAQSection(sectionId) end
---@param faqId string
function m.ShowSingleFAQ(faqId) end
---@param userProfile INTL.INTLCustomerUserProfile
function m.UpdateUserInfo(userProfile) end
---@param logPath string
function m.SetLogPath(logPath) end
---@param uid string
---@param pushToken string
function m.OpenUnreadMessage(uid, pushToken) end
---@param lan string
function m.UpdateLanguage(lan) end
---@overload fun(configsDic:table, project:string):bool
---@param configsDic table
---@return bool
function m.UpdateConfigs(configsDic) end
---@param channel string
---@param extraJson string
---@return bool
function m.IsAppInstalled(channel, extraJson) end
---@param id string
function m.StartDetectNetwork(id) end
---@param id string
---@param count uint
---@param extraJson string
function m.StartUdpSocket(id, count, extraJson) end
---@param link string
function m.OpenDeepLink(link) end
---@param url string
---@param typeMark string
---@return bool
function m.ConvertShortUrl(url, typeMark) end
---@param host string
---@return string
function m.GetIpByHost(host) end
---@param host string
function m.QueryIpByHost(host) end
---@param host string
function m.RemoveHostCache(host) end
---@param region string
function m.SetDNSRegion(region) end
---@return string
function m.GetSDKVersion() end
---@return int
function m.GetStoreChannel() end
---@param event_id string
function m.QueryBindRewardStatus(event_id) end
---@param event_id_lis string
---@param extraJson string
function m.QueryBindRewardListStatus(event_id_lis, extraJson) end
---@param event_id string
---@param extraJson string
function m.SendBindReward(event_id, extraJson) end
---@param extraJson string
function m.SetRewardExtraJson(extraJson) end
---@return string
function m.GetRewardExtraJson() end
---@param tree_id int
function m.QueryDirTree(tree_id) end
---@param tree_id int
---@param node_id int
function m.QueryDirNode(tree_id, node_id) end
function m.RequestIPInfo() end
---@param permissionTypeArray table
function m.RequestPermission(permissionTypeArray) end
---@param permissionTypeArray table
function m.CheckPermissionStatus(permissionTypeArray) end
---@param permissionTypeArray table
function m.GotoSystemSetting(permissionTypeArray) end
function m.RequestTracking() end
function m.CheckTracking() end
---@param deviceInfoName string
---@return bool
function m.IsDeviceInfoCollectEnable(deviceInfoName) end
---@param channel string
function m.ShowGroupAgreementWindow(channel) end
---@param info INTL.INTLGroupReqInfo
---@param channel string
function m.ShowGroupChatRoom(info, channel) end
---@param callback INTL.OnINTLResultHandler
function m.AddAuthBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveAuthBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddIDTokenResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveIDTokenResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddAuthResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveAuthResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddAccountResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveAccountResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddFriendBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveFriendBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddFriendResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveFriendResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddNoticeResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveNoticeResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddWebViewResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveWebViewResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddComplianceResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveComplianceResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddPushBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemovePushBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddPushResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemovePushResultObserver(callback) end
---@param callback INTL.OnINTLStringRetEventHandler
function m.AddCrashBaseResultObserver(callback) end
---@param callback INTL.OnINTLStringRetEventHandler
function m.RemoveCrashBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddDeviceLevelResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveDeviceLevelResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddToolsResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveToolsResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.SetDeepLinkObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveDeepLinkObserver(callback) end
---@return string
function m.Fetch() end
---@param callback INTL.OnINTLResultHandler
function m.AddDNSResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveDNSResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddCustomerResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveCustomerResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddDirTreeResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveDirTreeResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddLBSIPInfoResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveLBSIPInfoResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddPermissionResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemovePermissionResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddExtendResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveExtendResultObserver(callback) end
---@return bool
function m.ShowRatingAlert() end
---@param callback INTL.OnINTLResultHandler
function m.AddDetectNetworkResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddStartUdpSocketResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveStartUdpSocketResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveDetectNetworkResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddGroupBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveGroupBaseResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddBindRewardResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveBindRewardResultObserver(callback) end
---@param channel string
---@param extendMethodName string
---@param paramsJson string
---@return string
function m.ExtendInvoke(channel, extendMethodName, paramsJson) end
---@param callback INTL.OnINTLResultHandler
function m.AddAccelerateNetworkResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveAccelerateNetworkResultObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.AddAccelerateTestLogObserver(callback) end
---@param callback INTL.OnINTLResultHandler
function m.RemoveAccelerateTestLogObserver(callback) end
INTL = {}
INTL.INTLAPI = m
return m