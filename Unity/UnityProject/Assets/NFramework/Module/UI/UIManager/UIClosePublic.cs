
namespace NFramework.Module.UIModule
{
    public partial class UIM
    {

        public void Close<T>() where T : View
        {
            this._Close(this.GetViewID<T>());
        }

        public void Close<T>(T inWindow) where T : Window
        {
            this._Close(this.GetViewID<T>());
        }

        public void Close(string inWindowID)
        {
            this._Close(inWindowID);
        }
    }
}