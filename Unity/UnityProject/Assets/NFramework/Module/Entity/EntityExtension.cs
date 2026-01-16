namespace NFramework.Module.EntityModule
{
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