using NFramework.Module.LogModule;

namespace NFramework.Module.EntityModule
{
    using Log = NFramework.Module.LogModule.Log;
    using Error = NFramework.Module.LogModule.Error;
    using Warning = NFramework.Module.LogModule.Warning;

    public partial class Entity
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