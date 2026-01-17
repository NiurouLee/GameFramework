using NFramework.Module.LogModule;

namespace NFramework.Core
{
    using Log = NFramework.Module.LogModule.Log;
    using Error = NFramework.Module.LogModule.Error;
    using Warning = NFramework.Module.LogModule.Warning;
    public abstract class NObject
    {
        public FM GetFM<FM>() where FM : IFrameWorkModule
        {
            return Framework.I.G<FM>();
        }

        public Log? Log
        {
            get
            {
                return GetFM<LoggerM>().Log;
            }
        }
        public Error? Error
        {
            get
            {
                return GetFM<LoggerM>().Error;
            }
        }

        public Warning? Warning
        {
            get
            {
                return GetFM<LoggerM>().Warning;
            }
        }

    }
}