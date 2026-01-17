using NFramework.Module.LogModule;

namespace NFramework.Module
{
    using Log = NFramework.Module.LogModule.Log;
    using Error = NFramework.Module.LogModule.Error;
    using Warning = NFramework.Module.LogModule.Warning;

    public abstract class NObject
    {
        public TM GetM<TM>() where TM : FrameworkModule
        {
            return NFROOT.I.G<TM>();
        }

        public Log? Log
        {
            get { return GetM<LoggerM>().Log; }
        }

        public Error? Error
        {
            get { return GetM<LoggerM>().Error; }
        }

        public Warning? Warning
        {
            get { return GetM<LoggerM>().Warning; }
        }
    }
}