-- library.lua
-- Modern UI library – all classes defined in correct order

local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

-- Theme
local Theme = {
    Background = Color3.fromRGB(30, 30, 40),
    Frame = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(255, 255, 255),
    DimText = Color3.fromRGB(180, 180, 190),
    Border = Color3.fromRGB(60, 60, 70),
    ToggleOn = Color3.fromRGB(0, 200, 80),
    ToggleOff = Color3.fromRGB(80, 80, 90),
    SliderFill = Color3.fromRGB(0, 170, 255),
    SliderBg = Color3.fromRGB(70, 70, 80),
    DropdownBg = Color3.fromRGB(50, 50, 60),
}

-- Utilities
local function Create(className, parent, properties)
    local obj = Instance.new(className)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function MakeDraggable(frame, dragButton)
    local dragging, dragInput, startPos, startMousePos
    dragButton = dragButton or frame
    dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = frame.Position
            startMousePos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - startMousePos
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ====== TAB (defined first) ======
local Tab = {}
Tab.__index = Tab

function Tab:CreateSection(title)
    local section = Section.new(self, title)
    table.insert(self.Sections, section)
    self:UpdateSections()
    return section
end

function Tab:UpdateSections()
    local y = 0
    for _, s in ipairs(self.Sections) do
        s.Frame.Position = UDim2.new(0, 10, 0, y)
        y = y + s.Frame.Size.Y.Offset + 10
    end
    self.Content.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

-- ====== SECTION ======
local Section = {}
Section.__index = Section

function Section.new(parentTab, title)
    local self = setmetatable({}, Section)
    self.ParentTab = parentTab
    self.Title = title
    self.Controls = {}

    self.Frame = Create("Frame", parentTab.Content, {
        BackgroundColor3 = Theme.Frame,
        BackgroundTransparency = 0.4,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        ClipsDescendants = true,
        Visible = true,
    })
    self.TitleLabel = Create("TextLabel", self.Frame, {
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(1, -10, 0, 25),
        Position = UDim2.new(0.05, 0, 0, 5),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self.ControlContainer = Create("Frame", self.Frame, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -10, 1, -35),
        Position = UDim2.new(0.05, 0, 0, 30),
    })
    return self
end

function Section:AddControl(control)
    table.insert(self.Controls, control)
    control.Parent = self.ControlContainer
    self:UpdateLayout()
end

function Section:UpdateLayout()
    local y = 0
    for _, c in ipairs(self.Controls) do
        c.Position = UDim2.new(0, 0, 0, y)
        y = y + c.Size.Y.Offset + 5
    end
    self.Frame.Size = UDim2.new(1, -20, 0, y + 10)
    self.ParentTab:UpdateSections()
end

function Section:Toggle(label, callback, default)
    local toggle = Toggle.new(self, label, default)
    toggle:SetCallback(callback)
    self:AddControl(toggle)
    return toggle
end

function Section:Slider(label, min, max, default, suffix, callback)
    local slider = Slider.new(self, label, min, max, default, suffix)
    slider:SetCallback(callback)
    self:AddControl(slider)
    return slider
end

function Section:Dropdown(label, options, default, callback)
    local dropdown = Dropdown.new(self, label, options, default)
    dropdown:SetCallback(callback)
    self:AddControl(dropdown)
    return dropdown
end

-- ====== CONTROLS ======
local Control = {}
Control.__index = Control

function Control.new(parent, label, type)
    local self = setmetatable({}, Control)
    self.Type = type
    self.Label = label
    self.ParentSection = parent
    self.Callback = function() end

    self.Frame = Create("Frame", nil, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
    self.LabelObj = Create("TextLabel", self.Frame, {
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0.5, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self.ValueContainer = Create("Frame", self.Frame, {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -10, 1, 0),
        Position = UDim2.new(0.5, 10, 0, 0),
    })
    return self
end

function Control:SetCallback(func)
    self.Callback = func
end

function Control:Destroy()
    self.Frame:Destroy()
end

-- Toggle
local Toggle = setmetatable({}, Control)
Toggle.__index = Toggle

function Toggle.new(parent, label, default)
    local self = Control.new(parent, label, "Toggle")
    setmetatable(self, Toggle)
    self.State = default or false

    self.ToggleBtn = Create("ImageButton", self.ValueContainer, {
        BackgroundColor3 = self.State and Theme.ToggleOn or Theme.ToggleOff,
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        Image = "",
        ImageTransparency = 1,
        BorderSizePixel = 0,
    })
    self.Circle = Create("ImageLabel", self.ToggleBtn, {
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Image = "",
        ImageTransparency = 1,
        BorderSizePixel = 0,
    })
    self.ToggleBtn.MouseButton1Click:Connect(function()
        self:SetState(not self.State)
    end)
    return self
end

function Toggle:SetState(state)
    self.State = state
    self.ToggleBtn.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    self.Circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    self.Callback(state)
end

function Toggle:GetState()
    return self.State
end

-- Slider
local Slider = setmetatable({}, Control)
Slider.__index = Slider

function Slider.new(parent, label, min, max, default, suffix)
    local self = Control.new(parent, label, "Slider")
    setmetatable(self, Slider)
    self.Min = min or 0
    self.Max = max or 100
    self.Value = default or min
    self.Suffix = suffix or ""

    self.ValueLabel = Create("TextLabel", self.ValueContainer, {
        BackgroundTransparency = 1,
        Text = tostring(self.Value) .. self.Suffix,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(1, -45, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    self.SliderBg = Create("Frame", self.ValueContainer, {
        BackgroundColor3 = Theme.SliderBg,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -50, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3),
        BorderSizePixel = 0,
    })
    self.SliderFill = Create("Frame", self.SliderBg, {
        BackgroundColor3 = Theme.SliderFill,
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BorderSizePixel = 0,
    })
    self.Dragging = false
    self.SliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self:UpdateSlider(input.Position.X)
        end
    end)
    self.SliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)
    self.SliderBg.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.Dragging then
            self:UpdateSlider(input.Position.X)
        end
    end)
    return self
end

function Slider:UpdateSlider(mouseX)
    local absPos = self.SliderBg.AbsolutePosition
    local width = self.SliderBg.AbsoluteSize.X
    local relX = math.clamp((mouseX - absPos.X) / width, 0, 1)
    local val = self.Min + (self.Max - self.Min) * relX
    self:SetValue(val)
end

function Slider:SetValue(val)
    val = math.clamp(val, self.Min, self.Max)
    self.Value = val
    self.ValueLabel.Text = tostring(math.round(val)) .. self.Suffix
    self.SliderFill.Size = UDim2.new((val - self.Min) / (self.Max - self.Min), 0, 1, 0)
    self.Callback(val)
end

function Slider:GetValue()
    return self.Value
end

-- Dropdown
local Dropdown = setmetatable({}, Control)
Dropdown.__index = Dropdown

function Dropdown.new(parent, label, options, default)
    local self = Control.new(parent, label, "Dropdown")
    setmetatable(self, Dropdown)
    self.Options = options or {}
    self.Selected = default or (options and options[1]) or ""

    self.DropBtn = Create("TextButton", self.ValueContainer, {
        BackgroundColor3 = Theme.DropdownBg,
        Text = self.Selected,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(1, -45, 1, -4),
        Position = UDim2.new(0, 0, 0, 2),
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    self.Arrow = Create("TextLabel", self.DropBtn, {
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Theme.DimText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    self.ListFrame = Create("Frame", self.ValueContainer, {
        BackgroundColor3 = Theme.DropdownBg,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Size = UDim2.new(1, -45, 0, 0),
        Position = UDim2.new(0, 0, 0, 30),
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 2,
    })
    self.OptionButtons = {}
    for i, opt in ipairs(options) do
        local btn = Create("TextButton", self.ListFrame, {
            BackgroundTransparency = 1,
            Text = opt,
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, (i-1)*25),
            BorderSizePixel = 0,
        })
        btn.MouseButton1Click:Connect(function()
            self:Select(opt)
        end)
        table.insert(self.OptionButtons, btn)
    end
    self.ListFrame.Size = UDim2.new(1, -45, 0, #options * 25)

    self.DropBtn.MouseButton1Click:Connect(function()
        self.ListFrame.Visible = not self.ListFrame.Visible
    end)
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.ListFrame.Visible then
                local mousePos = input.Position
                local absPos = self.ListFrame.AbsolutePosition
                local size = self.ListFrame.AbsoluteSize
                if not (mousePos.X >= absPos.X and mousePos.X <= absPos.X + size.X and
                        mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + size.Y) then
                    self.ListFrame.Visible = false
                end
            end
        end
    end)
    return self
end

function Dropdown:Select(opt)
    self.Selected = opt
    self.DropBtn.Text = opt
    self.ListFrame.Visible = false
    self.Callback(opt)
end

function Dropdown:GetValue()
    return self.Selected
end

-- ====== WINDOW ======
local Window = {}
Window.__index = Window

function Window.new(title, parent)
    local self = setmetatable({}, Window)
    self.Title = title
    self.Parent = parent or game:GetService("CoreGui")
    self.Tabs = {}
    self.TabButtons = {}
    self.ActiveTab = nil

    -- Main Frame
    self.Main = Create("Frame", self.Parent, {
        BackgroundColor3 = Theme.Background,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = true,
        Active = true,
        Visible = true,
        BackgroundTransparency = 0.05,
        Style = Enum.FrameStyle.Custom,
    })
    Create("ImageLabel", self.Main, {
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045048",
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 10, 10),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = 0,
    })

    -- Top bar
    self.TopBar = Create("Frame", self.Main, {
        BackgroundColor3 = Theme.Frame,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 0.1,
    })
    self.TitleLabel = Create("TextLabel", self.TopBar, {
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.02, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    -- Player info
    local player = Players.LocalPlayer
    if player then
        Create("ImageLabel", self.TopBar, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.85, 0, 0.5, -15),
            Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420),
            ImageTransparency = 0.1,
        })
        Create("TextLabel", self.TopBar, {
            BackgroundTransparency = 1,
            Text = player.Name,
            TextColor3 = Theme.Text,
            TextSize = 16,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(0, 150, 0, 30),
            Position = UDim2.new(0.88, 0, 0.5, -15),
            TextXAlignment = Enum.TextXAlignment.Left,
        })
    end

    self.CloseBtn = Create("TextButton", self.TopBar, {
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = Theme.Text,
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0, 35, 1, 0),
        Position = UDim2.new(1, -35, 0, 0),
    })
    self.CloseBtn.MouseButton1Click:Connect(function()
        self.Main:Destroy()
    end)

    self.TabContainer = Create("Frame", self.Main, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 35),
        Position = UDim2.new(0, 0, 0, 45),
    })
    self.ContentContainer = Create("Frame", self.Main, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -80),
        Position = UDim2.new(0, 0, 0, 80),
    })

    MakeDraggable(self.Main, self.TopBar)
    return self
end

function Window:CreateTab(name)
    local tab = setmetatable({}, {__index = Tab})  -- Tab is now defined
    tab.Name = name
    tab.Window = self
    tab.Sections = {}
    tab.Content = Create("ScrollingFrame", self.ContentContainer, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.5,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = false,
    })

    local btn = Create("TextButton", self.TabContainer, {
        BackgroundColor3 = Theme.Frame,
        BackgroundTransparency = 0.2,
        Text = name,
        TextColor3 = Theme.DimText,
        TextSize = 16,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 100, 1, 0),
        BorderSizePixel = 0,
    })
    btn.MouseEnter:Connect(function()
        if tab.Content.Visible ~= true then
            btn.BackgroundTransparency = 0
        end
    end)
    btn.MouseLeave:Connect(function()
        if tab.Content.Visible ~= true then
            btn.BackgroundTransparency = 0.2
        end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)

    table.insert(self.Tabs, tab)
    self.TabButtons[name] = btn

    for i, t in ipairs(self.Tabs) do
        local b = self.TabButtons[t.Name]
        b.Size = UDim2.new(0, 100, 1, 0)
        b.Position = UDim2.new(0, (i-1)*100, 0, 0)
    end

    if #self.Tabs == 1 then
        self:SelectTab(name)
    end
    return tab
end

function Window:SelectTab(name)
    for _, t in ipairs(self.Tabs) do
        local vis = (t.Name == name)
        t.Content.Visible = vis
        local btn = self.TabButtons[t.Name]
        if vis then
            btn.BackgroundTransparency = 0
            btn.TextColor3 = Theme.Text
            btn.BackgroundColor3 = Theme.Accent
        else
            btn.BackgroundTransparency = 0.2
            btn.TextColor3 = Theme.DimText
            btn.BackgroundColor3 = Theme.Frame
        end
    end
    self.ActiveTab = name
end

function Window:Destroy()
    self.Main:Destroy()
end

-- ====== EXPOSE LIBRARY ======
function Library.CreateWindow(title, parent)
    return Window.new(title, parent)
end

function Library.SetTheme(newTheme)
    for k, v in pairs(newTheme) do
        Theme[k] = v
    end
end

return Library
