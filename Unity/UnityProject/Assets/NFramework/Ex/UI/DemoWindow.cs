using NFramework.Module.UIModule;

[View("DemoWindow")]
public class DemoWindow : Window, IViewSetData<DemoWindowData>
{
    private NButton m_button;
    protected override void OnBindFacade()
    {
        base.OnBindFacade();
        this.BindInput<IUIClickComponent>(m_button, this.OnClick);
    }

    private void OnClick(IUIClickComponent inComponent)
    {

    }

    protected override void OnAwake()
    {
        base.OnAwake();
    }
    public DemoWindow()
    {

    }


    public void SetData(DemoWindowData inData)
    {
    }
}

public class DemoWindowData
{
    public string Name;
}
