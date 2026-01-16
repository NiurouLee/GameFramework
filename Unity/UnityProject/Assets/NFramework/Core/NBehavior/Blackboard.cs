
namespace NFramework.NBehavior
{
    public class Blackboard
    {

        public enum Type
        {
            ADD,
            REMOVE,
            CHANGE
        }

        private struct Notification
        {
            public string key;
            public Type type;
            public object value;

            public Notification(string inKey, Type inType, object Value = null)
            {
                key = inKey;
                type = inType;
                value = Value;
            }
        }

    }
}
