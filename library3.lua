-- library.lua
-- Fully functional, no forward-reference errors

local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

-- Utility
local function Create(class, parent, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function MakeDraggable(frame, dragButton)
    local drag, startPos, startMouse
    dragButton = dragButton or frame
    dragButton.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            startPos = frame.Position
            startMouse = inp.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    dragButton.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and drag then
            local delta = inp.Position - startMouse
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- =====================================================================
-- 1. CONTROLS (base, toggle, slider, dropdown)
-- =====================================================================

local Control = {}
Control.__index = Control

function Control.new(parent, label)
    local self = setmetatable({}, Control)
    self.Label = label
    self.ParentSection = parent
    self.Callback = function() end

    self.Frame = Create("Frame", nil, {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
    })
    Create("TextLabel", self.Frame, {
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

function Control:SetCallback(fn)
    self.Callback = fn
end

-- Toggle
local Toggle = setmetatable({}, Control)
Toggle.__index = Toggle

function Toggle.new(parent, label, default)
    local self = Control.new(parent, label)
    setmetatable(self, Toggle)
    self.State = default or false

    self.Btn = Create("ImageButton", self.ValueContainer, {
        BackgroundColor3 = self.State and Theme.ToggleOn or Theme.ToggleOff,
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -45, 0.5, -10),
        Image = "", BorderSizePixel = 0,
    })
    self.Circle = Create("ImageLabel", self.Btn, {
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.State and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Image = "", BorderSizePixel = 0,
    })
    self.Btn.MouseButton1Click:Connect(function()
        self:SetState(not self.State)
    end)
    return self
end

function Toggle:SetState(state)
    self.State = state
    self.Btn.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
    self.Circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    self.Callback(state)
end

function Toggle:GetState() return self.State end

-- Slider
local Slider = setmetatable({}, Control)
Slider.__index = Slider

function Slider.new(parent, label, min, max, default, suffix)
    local self = Control.new(parent, label)
    setmetatable(self, Slider)
    self.Min, self.Max, self.Suffix = min or 0, max or 100, suffix or ""
    self.Value = default or min

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
    self.Bg = Create("Frame", self.ValueContainer, {
        BackgroundColor3 = Theme.SliderBg,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -50, 0, 6),
        Position = UDim2.new(0, 0, 0.5, -3),
        BorderSizePixel = 0,
    })
    self.Fill = Create("Frame", self.Bg, {
        BackgroundColor3 = Theme.SliderFill,
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BorderSizePixel = 0,
    })
    self.Dragging = false
    self.Bg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self:UpdateSlider(inp.Position.X)
        end
    end)
    self.Bg.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then self.Dragging = false end
    end)
    self.Bg.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and self.Dragging then
            self:UpdateSlider(inp.Position.X)
        end
    end)
    return self
end

function Slider:UpdateSlider(mouseX)
    local abs = self.Bg.AbsolutePosition
    local w = self.Bg.AbsoluteSize.X
    local rel = math.clamp((mouseX - abs.X) / w, 0, 1)
    local val = self.Min + (self.Max - self.Min) * rel
    self:SetValue(val)
end

function Slider:SetValue(val)
    val = math.clamp(val, self.Min, self.Max)
    self.Value = val
    self.ValueLabel.Text = tostring(math.round(val)) .. self.Suffix
    self.Fill.Size = UDim2.new((val - self.Min) / (self.Max - self.Min), 0, 1, 0)
    self.Callback(val)
end

function Slider:GetValue() return self.Value end

-- Dropdown
local Dropdown = setmetatable({}, Control)
Dropdown.__index = Dropdown

function Dropdown.new(parent, label, options, default)
    local self = Control.new(parent, label)
    setmetatable(self, Dropdown)
    self.Options = options or {}
    self.Selected = default or (options and options[1]) or ""

    self.Btn = Create("TextButton", self.ValueContainer, {
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
    Create("TextLabel", self.Btn, {
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Theme.DimText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -25, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
    })
    self.List = Create("Frame", self.ValueContainer, {
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
        local btn = Create("TextButton", self.List, {
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
    self.List.Size = UDim2.new(1, -45, 0, #options * 25)

    self.Btn.MouseButton1Click:Connect(function()
        self.List.Visible = not self.List.Visible
    end)
    UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 and self.List.Visible then
            local pos = inp.Position
            local abs = self.List.AbsolutePosition
            local sz = self.List.AbsoluteSize
            if not (pos.X >= abs.X and pos.X <= abs.X + sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y + sz.Y) then
                self.List.Visible = false
            end
        end
    end)
    return self
end

function Dropdown:Select(opt)
    self.Selected = opt
    self.Btn.Text = opt
    self.List.Visible = false
    self.Callback(opt)
end

function Dropdown:GetValue() return self.Selected end

-- =====================================================================
-- 2. SECTION
-- =====================================================================

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
    })
    Create("TextLabel", self.Frame, {
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

function Section:AddControl(ctrl)
    table.insert(self.Controls, ctrl)
    ctrl.Frame.Parent = self.ControlContainer
    self:UpdateLayout()
end

function Section:UpdateLayout()
    local y = 0
    for _, c in ipairs(self.Controls) do
        c.Frame.Position = UDim2.new(0, 0, 0, y)
        y = y + c.Frame.Size.Y.Offset + 5
    end
    self.Frame.Size = UDim2.new(1, -20, 0, y + 10)
    self.ParentTab:UpdateSections()
end

function Section:Toggle(label, callback, default)
    local c = Toggle.new(self, label, default)
    c:SetCallback(callback)
    self:AddControl(c)
    return c
end

function Section:Slider(label, min, max, default, suffix, callback)
    local c = Slider.new(self, label, min, max, default, suffix)
    c:SetCallback(callback)
    self:AddControl(c)
    return c
end

function Section:Dropdown(label, options, default, callback)
    local c = Dropdown.new(self, label, options, default)
    c:SetCallback(callback)
    self:AddControl(c)
    return c
end

-- =====================================================================
-- 3. TAB
-- =====================================================================

local Tab = {}
Tab.__index = Tab

function Tab.new(window, name)
    local self = setmetatable({}, Tab)
    self.Window = window
    self.Name = name
    self.Sections = {}

    self.Content = Create("ScrollingFrame", window.ContentContainer, {
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
    return self
end

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

-- =====================================================================
-- 4. WINDOW
-- =====================================================================

local Window = {}
Window.__index = Window

function Window.new(title, parent)
    local self = setmetatable({}, Window)
    self.Title = title
    self.Parent = parent or game:GetService("CoreGui")
    self.Tabs = {}
    self.TabButtons = {}
    self.ActiveTab = nil

    self.Main = Create("Frame", self.Parent, {
        BackgroundColor3 = Theme.Background,
        BorderColor3 = Theme.Border,
        BorderSizePixel = 1,
        Position = UDim2.new(0.5, -300, 0.5, -200),
        Size = UDim2.new(0, 600, 0, 400),
        ClipsDescendants = true,
        BackgroundTransparency = 0.05,
    })
    Create("ImageLabel", self.Main, {
        BackgroundTransparency = 1,
        Image = "rbxassetid://1316045048",
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10,10,10,10),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = 0,
    })

    -- Top bar
    self.TopBar = Create("Frame", self.Main, {
        BackgroundColor3 = Theme.Frame,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 45),
        BorderSizePixel = 0,
    })
    Create("TextLabel", self.TopBar, {
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0.02, 0, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    -- Player avatar + name
    local player = Players.LocalPlayer
    if player then
        Create("ImageLabel", self.TopBar, {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0.85, 0, 0.5, -15),
            Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420),
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
    local tab = Tab.new(self, name)
    table.insert(self.Tabs, tab)

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
        if not tab.Content.Visible then btn.BackgroundTransparency = 0 end
    end)
    btn.MouseLeave:Connect(function()
        if not tab.Content.Visible then btn.BackgroundTransparency = 0.2 end
    end)
    btn.MouseButton1Click:Connect(function()
        self:SelectTab(name)
    end)
    self.TabButtons[name] = btn

    -- reposition all buttons
    for i, t in ipairs(self.Tabs) do
        local b = self.TabButtons[t.Name]
        b.Size = UDim2.new(0, 100, 1, 0)
        b.Position = UDim2.new(0, (i-1)*100, 0, 0)
    end

    if #self.Tabs == 1 then self:SelectTab(name) end
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

-- =====================================================================
-- EXPOSE
-- =====================================================================

function Library.CreateWindow(title, parent)
    return Window.new(title, parent)
end

function Library.SetTheme(newTheme)
    for k, v in pairs(newTheme) do Theme[k] = v end
end

return Library
