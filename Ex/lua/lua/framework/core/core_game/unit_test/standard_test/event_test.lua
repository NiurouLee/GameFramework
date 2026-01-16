require "framework/core/core_game/unit_test/coregame_unit_test"
require "delegate_event"


Window = {
    Name = "Test Window",    
}

function Window:Set2Event()
    Button.ClickEvent:AddEvent(self, self.Button_OnClick1)    
    Button.ClickEvent:AddEvent(self, self.Button_OnClick2)   
end

function Window:Remove1Event()
    Button.ClickEvent:RemoveEvent(self, self.Button_OnClick2)      
end

--sender是传来的Button对象
function Window:Button_OnClick1(sender)    
    print(sender.Name.." 1 Click On "..self.Name)
end
function Window:Button_OnClick2(sender)    
    print(sender.Name.." 2 Click On "..self.Name)
end

Button = {
    Name = "A Button",
    ClickEvent = DelegateEvent:New(),
}

function Button:Click()
    print('Click begin')
    self:ClickEvent()
    print('Click end')
end


Window:Set2Event()
Button:Click()

Window:Remove1Event()
Button:Click()

ff = io.read()