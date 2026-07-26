--// MavisDMA UI Library
--// https://github.com/PapaDusty/MavisDMA

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local ICON_DEFAULT = "rbxassetid://75466683081922"
local ICON_SEARCH = "rbxassetid://75976789185161"
local ICON_CHECK = "rbxassetid://99816002883608"
local ICON_MINIMIZE = "rbxassetid://80855609202946"
local ICON_CHEVRON = "rbxassetid://133013503900747"

local function PoppinsFont(weight)
	local ok, font = pcall(function()
		return Font.new("rbxasset://fonts/families/Poppins.json", weight, Enum.FontStyle.Normal)
	end)
	if ok then
		return font
	end
	return Font.fromEnum(Enum.Font.GothamMedium)
end

local Theme = {
	Background = Color3.fromRGB(17, 17, 20),
	Sidebar = Color3.fromRGB(24, 24, 27),
	Card = Color3.fromRGB(24, 24, 27),
	Element = Color3.fromRGB(30, 30, 45),
	ElementHover = Color3.fromRGB(38, 38, 55),
	Accent = Color3.fromRGB(124, 109, 242),
	AccentDark = Color3.fromRGB(101, 88, 214),
	Stroke = Color3.fromRGB(38, 38, 54),
	Text = Color3.fromRGB(235, 235, 245),
	SubText = Color3.fromRGB(148, 148, 165),
	MutedText = Color3.fromRGB(85, 85, 100),
	Font = PoppinsFont(Enum.FontWeight.Medium),
	FontMedium = PoppinsFont(Enum.FontWeight.Medium),
	FontSemibold = PoppinsFont(Enum.FontWeight.SemiBold),
	FontBold = PoppinsFont(Enum.FontWeight.Bold),
}

local function New(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			inst[k] = v
		end
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Round(parent, radius, full)
	local corner = full and UDim.new(1, 0) or UDim.new(0, radius or 0)
	return New("UICorner", { CornerRadius = corner, Parent = parent })
end

local function Stroke(parent, color, thickness)
	return New("UIStroke", { Color = color or Theme.Stroke, Thickness = thickness or 1, Parent = parent })
end

local function Pad(parent, l, r, t, b)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or t or 0),
		Parent = parent,
	})
end

local function Tween(inst, props, duration, style)
	local tw = TweenService:Create(inst, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad), props)
	tw:Play()
	return tw
end

local function IconPlaceholder(parent, size, image, color)
	local icon = New("ImageLabel", {
		Size = UDim2.new(0, size, 0, size),
		BackgroundTransparency = 1,
		Image = image or ICON_DEFAULT,
		ImageColor3 = color or Theme.SubText,
		ScaleType = Enum.ScaleType.Fit,
		Parent = parent,
	})
	return icon
end

local Library = {}
Library.__index = Library
Library.Flags = {}
Library._registry = {}

function Library:GetPlayerName()
	local ok, name = pcall(function()
		return LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name
	end)
	return ok and name or "Player"
end

function Library:GetAvatar(imageLabel)
	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok then
			imageLabel.Image = content
		end
	end)
end

function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "MAVISDMA"
	local subTitle = config.SubTitle or ""
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

	local ScreenGui = New("ScreenGui", {
		Name = "MavisDMA",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = (gethui and gethui()) or game:GetService("CoreGui"),
	})

	local Main = New("Frame", {
		Name = "Main",
		Size = UDim2.new(0, 900, 0, 600),
		Position = UDim2.new(0.5, -450, 0.5, -300),
		BackgroundColor3 = Theme.Background,
		Parent = ScreenGui,
	})
	Main.ClipsDescendants = true
	Round(Main, 12)

	local TopBar = New("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = Theme.Background,
		Parent = Main,
	})
	Round(TopBar, 12)
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Parent = TopBar,
	})

	local SearchBox = New("Frame", {
		Size = UDim2.new(0, 190, 0, 34),
		Position = UDim2.new(0, 10, 0.5, -17),
		BackgroundColor3 = Theme.Element,
		Parent = TopBar,
	})
	Round(SearchBox, nil, true)
	local searchIcon = IconPlaceholder(SearchBox, 14, ICON_SEARCH)
	searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
	local SearchInput = New("TextBox", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 34, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "Search elements",
		PlaceholderColor3 = Theme.MutedText,
		TextColor3 = Theme.Text,
		FontFace = Theme.Font,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = SearchBox,
	})

	local GearButton = New("TextButton", {
		Size = UDim2.new(0, 34, 0, 34),
		Position = UDim2.new(0, 214, 0.5, -17),
		BackgroundColor3 = Theme.Element,
		Text = "",
		AutoButtonColor = false,
		Parent = TopBar,
	})
	Round(GearButton, nil, true)
	local gearIcon = IconPlaceholder(GearButton, 16, ICON_MINIMIZE)
	gearIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	gearIcon.Position = UDim2.new(0.5, 0, 0.5, 0)

	local RightCluster = New("Frame", {
		Size = UDim2.new(0, 220, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = TopBar,
	})

	local Avatar = New("ImageLabel", {
		Size = UDim2.new(0, 34, 0, 34),
		Position = UDim2.new(1, 0, 0.5, -17),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Element,
		Image = "",
		Parent = RightCluster,
	})
	Round(Avatar, nil, true)
	Library:GetAvatar(Avatar)

	local NameLabel = New("TextLabel", {
		Size = UDim2.new(0, 140, 0, 34),
		Position = UDim2.new(1, -44, 0.5, -17),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Text = Library:GetPlayerName(),
		TextColor3 = Theme.Text,
		FontFace = Theme.FontSemibold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = RightCluster,
	})

	local Sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 190, 1, -66),
		Position = UDim2.new(0, 10, 0, 56),
		BackgroundColor3 = Theme.Sidebar,
		Parent = Main,
	})
	Round(Sidebar, 12)

	local LogoFrame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})
	local Logo1 = New("TextLabel", {
		Size = UDim2.new(0, 100, 1, 0),
		Position = UDim2.new(0, 20, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Theme.Text,
		FontFace = Theme.FontBold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = LogoFrame,
	})
	if subTitle ~= "" then
		New("TextLabel", {
			Size = UDim2.new(0, 120, 0, 12),
			Position = UDim2.new(0, 22, 1, -14),
			BackgroundTransparency = 1,
			Text = subTitle,
			TextColor3 = Theme.SubText,
			FontFace = Theme.Font,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = LogoFrame,
		})
	end

	local NavHolder = New("Frame", {
		Size = UDim2.new(1, -20, 1, -70),
		Position = UDim2.new(0, 10, 0, 60),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	})
	local NavList = New("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = NavHolder,
	})

	local Content = New("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -220, 1, -56),
		Position = UDim2.new(0, 220, 0, 56),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Main,
	})

	local Window = setmetatable({
		Gui = ScreenGui,
		Main = Main,
		Sidebar = Sidebar,
		NavHolder = NavHolder,
		Content = Content,
		Tabs = {},
		ActiveTab = nil,
		Order = 0,
	}, Library)

	-- dragging
	do
		local dragging, dragStart, startPos = false, nil, nil
		TopBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = Main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	-- minimize (gear button)
	local minimized = false
	local fullSize = Main.Size
	GearButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Sidebar.Visible = false
			Content.Visible = false
			Tween(Main, { Size = UDim2.new(0, fullSize.X.Offset, 0, 56) }, 0.2)
		else
			Tween(Main, { Size = fullSize }, 0.2)
			task.delay(0.2, function()
				Sidebar.Visible = true
				Content.Visible = true
			end)
		end
	end)
	GearButton.MouseEnter:Connect(function()
		Tween(GearButton, { BackgroundColor3 = Theme.ElementHover }, 0.15)
	end)
	GearButton.MouseLeave:Connect(function()
		Tween(GearButton, { BackgroundColor3 = Theme.Element }, 0.15)
	end)

	-- show/hide toggle key
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			ScreenGui.Enabled = not ScreenGui.Enabled
		end
	end)

	-- search filtering across active tab
	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = SearchInput.Text:lower()
		if not Window.ActiveTab then return end
		for _, section in ipairs(Window.ActiveTab.Sections) do
			for _, row in ipairs(section.Rows) do
				if query == "" then
					row.Container.Visible = true
				else
					row.Container.Visible = string.find(row.Name:lower(), query, 1, true) ~= nil
				end
			end
		end
	end)

	return Window
end

function Library:AddTab(config)
	config = config or {}
	local name = config.Name or "Tab"
	local flat = config.Flat or false
	local iconImage = config.Icon and ("rbxassetid://" .. tostring(config.Icon)) or ICON_DEFAULT
	self.Order = self.Order + 1

	local NavButton = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Sidebar,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = self.Order,
		Parent = self.NavHolder,
	})
	Round(NavButton, 8)

	local Indicator = New("Frame", {
		Size = UDim2.new(0, 3, 0, 16),
		Position = UDim2.new(0, 0, 0.5, -8),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		Parent = NavButton,
	})
	Round(Indicator, 2)

	local navIcon = IconPlaceholder(NavButton, 16, iconImage)
	navIcon.Position = UDim2.new(0, 12, 0.5, -8)

	local NavText = New("TextLabel", {
		Size = UDim2.new(1, flat and -40 or -60, 1, 0),
		Position = UDim2.new(0, 38, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.SubText,
		FontFace = Theme.FontSemibold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = NavButton,
	})

	if not flat then
		IconPlaceholder(NavButton, 12, ICON_CHEVRON).Position = UDim2.new(1, -22, 0.5, -6)
	end

	local Page = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Element,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = self.Content,
	})
	Pad(Page, 18, 18, 16, 16)

	local Columns = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Page,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Columns,
	})

	local ColumnFrames = {}
	for i = 1, 2 do
		local col = New("Frame", {
			Size = UDim2.new(0.5, -14, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			LayoutOrder = i,
			Parent = Columns,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 16),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = col,
		})
		ColumnFrames[i] = col
	end

	local Tab = setmetatable({
		Window = self,
		Name = name,
		Button = NavButton,
		Indicator = Indicator,
		Text = NavText,
		Page = Page,
		Columns = ColumnFrames,
		Sections = {},
		Order = 0,
	}, { __index = TabMethods })

	NavButton.MouseButton1Click:Connect(function()
		self:SelectTab(Tab)
	end)
	NavButton.MouseEnter:Connect(function()
		if self.ActiveTab ~= Tab then
			Tween(NavButton, { BackgroundColor3 = Theme.ElementHover }, 0.15)
		end
	end)
	NavButton.MouseLeave:Connect(function()
		if self.ActiveTab ~= Tab then
			Tween(NavButton, { BackgroundColor3 = Theme.Sidebar }, 0.15)
		end
	end)

	table.insert(self.Tabs, Tab)
	if not self.ActiveTab then
		self:SelectTab(Tab)
	end
	return Tab
end

function Library:SelectTab(tab)
	if self.ActiveTab then
		self.ActiveTab.Page.Visible = false
		Tween(self.ActiveTab.Button, { BackgroundColor3 = Theme.Sidebar }, 0.15)
		Tween(self.ActiveTab.Indicator, { BackgroundTransparency = 1 }, 0.15)
		Tween(self.ActiveTab.Text, { TextColor3 = Theme.SubText }, 0.15)
	end
	tab.Page.Visible = true
	Tween(tab.Button, { BackgroundColor3 = Theme.Element }, 0.15)
	Tween(tab.Indicator, { BackgroundTransparency = 0 }, 0.15)
	Tween(tab.Text, { TextColor3 = Theme.Text }, 0.15)
	self.ActiveTab = tab
end

TabMethods = {}
TabMethods.__index = TabMethods

function TabMethods:AddSection(config)
	config = config or {}
	local name = config.Name or "SECTION"
	local column = config.Column or 1
	local autoDivider = config.Dividers or false
	self.Order = self.Order + 1

	local Wrap = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self.Order,
		Parent = self.Columns[column],
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Wrap,
	})

	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = name:upper(),
		TextColor3 = Theme.SubText,
		FontFace = Theme.FontSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = Wrap,
	})

	local Card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Card,
		LayoutOrder = 1,
		Parent = Wrap,
	})
	Round(Card, 14)
	Pad(Card, 14, 14, 12, 12)

	local RowHolder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Card,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = RowHolder,
	})

	local Section = setmetatable({
		Card = Card,
		RowHolder = RowHolder,
		Rows = {},
		Order = 0,
		AutoDivider = autoDivider,
	}, { __index = SectionMethods })

	table.insert(self.Sections, Section)
	return Section
end

SectionMethods = {}
SectionMethods.__index = SectionMethods

local function InsertDividerLine(section)
	section.Order = section.Order + 1
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.6,
		LayoutOrder = section.Order,
		Parent = section.RowHolder,
	})
end

local function RowBase(section, height)
	if section.AutoDivider and #section.Rows > 0 then
		InsertDividerLine(section)
	end
	section.Order = section.Order + 1
	local Row = New("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		LayoutOrder = section.Order,
		Parent = section.RowHolder,
	})
	return Row
end

local function RegisterFlag(flag, obj)
	if flag then
		Library._registry[flag] = obj
	end
end

function SectionMethods:AddToggle(config)
	config = config or {}
	local name = config.Name or "Toggle"
	local default = config.Default or false
	local disabled = config.Disabled or false
	local flag = config.Flag
	local callback = config.Callback or function() end

	local Row = RowBase(self, 22)
	local Label = New("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = disabled and Theme.MutedText or Theme.Text,
		FontFace = Theme.Font,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})

	local Box = New("TextButton", {
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.new(1, -22, 0.5, -11),
		BackgroundColor3 = Theme.Element,
		Text = "",
		AutoButtonColor = false,
		Parent = Row,
	})
	Round(Box, 6)
	Stroke(Box, Theme.Stroke, 1)

	local state = default
	local Toggle = {}

	local function render()
		if disabled then
			Box.BackgroundColor3 = Theme.Element
			return
		end
		Tween(Box, { BackgroundColor3 = state and Theme.Accent or Theme.Element }, 0.15)
	end

	function Toggle:Set(value)
		if disabled then return end
		state = value
		render()
		callback(state)
		Library.Flags[flag or name] = state
	end

	function Toggle:Get()
		return state
	end

	if not disabled then
		Box.MouseButton1Click:Connect(function()
			Toggle:Set(not state)
		end)
	end

	render()
	Library.Flags[flag or name] = state
	RegisterFlag(flag, Toggle)
	table.insert(self.Rows, { Container = Row, Name = name })
	return Toggle
end

function SectionMethods:AddSlider(config)
	config = config or {}
	local name = config.Name or "Slider"
	local min = config.Min or 0
	local max = config.Max or 100
	local default = math.clamp(config.Default or min, min, max)
	local suffix = config.Suffix or ""
	local decimals = config.Decimals or 0
	local flag = config.Flag
	local callback = config.Callback or function() end

	local Row = RowBase(self, 40)
	New("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 18),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		FontFace = Theme.Font,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})
	local ValueLabel = New("TextLabel", {
		Size = UDim2.new(0.4, 0, 0, 18),
		Position = UDim2.new(0.6, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(default) .. suffix,
		TextColor3 = Theme.SubText,
		FontFace = Theme.Font,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Row,
	})

	local Track = New("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 26),
		BackgroundColor3 = Theme.Element,
		Parent = Row,
	})
	Round(Track, 3)
	local Fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		Parent = Track,
	})
	Round(Fill, 3)
	local Handle = New("TextButton", {
		Size = UDim2.new(0, 14, 0, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Theme.Text,
		Text = "",
		AutoButtonColor = false,
		Parent = Track,
	})
	Round(Handle, 7)

	local value = default
	local Slider = {}

	local function setFromAlpha(alpha)
		alpha = math.clamp(alpha, 0, 1)
		local raw = min + (max - min) * alpha
		if decimals == 0 then
			raw = math.floor(raw + 0.5)
		else
			local mult = 10 ^ decimals
			raw = math.floor(raw * mult + 0.5) / mult
		end
		value = raw
		local pctX = (value - min) / (max - min)
		Fill.Size = UDim2.new(pctX, 0, 1, 0)
		Handle.Position = UDim2.new(pctX, 0, 0.5, 0)
		ValueLabel.Text = tostring(value) .. suffix
		callback(value)
		Library.Flags[flag or name] = value
	end

	function Slider:Set(v)
		setFromAlpha((math.clamp(v, min, max) - min) / (max - min))
	end
	function Slider:Get()
		return value
	end

	local dragging = false
	Handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
			setFromAlpha(alpha)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local alpha = (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
			setFromAlpha(alpha)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	Slider:Set(default)
	RegisterFlag(flag, Slider)
	table.insert(self.Rows, { Container = Row, Name = name })
	return Slider
end

function SectionMethods:AddDropdown(config)
	config = config or {}
	local name = config.Name or "Dropdown"
	local options = config.Options or {}
	local default = config.Default or options[1]
	local flag = config.Flag
	local callback = config.Callback or function() end

	local Row = RowBase(self, 44)
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Theme.Text,
		FontFace = Theme.Font,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})

	local Button = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 22),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = Theme.Element,
		Text = "",
		AutoButtonColor = false,
		Parent = Row,
	})
	Round(Button, 6)
	Stroke(Button, Theme.Stroke, 1)

	local SelectedLabel = New("TextLabel", {
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(default or ""),
		TextColor3 = Theme.SubText,
		FontFace = Theme.Font,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Button,
	})
	New("TextLabel", {
		Size = UDim2.new(0, 20, 1, 0),
		Position = UDim2.new(1, -22, 0, 0),
		BackgroundTransparency = 1,
		Text = "v",
		TextColor3 = Theme.MutedText,
		FontFace = Theme.Font,
		TextSize = 12,
		Parent = Button,
	})

	local Overlay = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 4),
		BackgroundColor3 = Theme.Element,
		Visible = false,
		ZIndex = 20,
		ClipsDescendants = true,
		Parent = Button,
	})
	Round(Overlay, 6)
	Stroke(Overlay, Theme.Stroke, 1)
	local OverlayList = New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = Overlay })

	local value = default
	local Dropdown = {}

	local function close()
		Overlay.Visible = false
		Overlay.Size = UDim2.new(1, 0, 0, 0)
	end

	function Dropdown:Set(v)
		value = v
		SelectedLabel.Text = tostring(v)
		callback(v)
		Library.Flags[flag or name] = v
	end
	function Dropdown:Get()
		return value
	end
	function Dropdown:Refresh(newOptions)
		options = newOptions
		for _, c in ipairs(Overlay:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, opt in ipairs(options) do
			local OptButton = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.Element,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 21,
				Parent = Overlay,
			})
			New("TextLabel", {
				Size = UDim2.new(1, -10, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(opt),
				TextColor3 = Theme.Text,
				FontFace = Theme.Font,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 21,
				Parent = OptButton,
			})
			OptButton.MouseEnter:Connect(function()
				OptButton.BackgroundColor3 = Theme.ElementHover
			end)
			OptButton.MouseLeave:Connect(function()
				OptButton.BackgroundColor3 = Theme.Element
			end)
			OptButton.MouseButton1Click:Connect(function()
				Dropdown:Set(opt)
				close()
			end)
		end
	end

	Button.MouseButton1Click:Connect(function()
		if Overlay.Visible then
			close()
		else
			Overlay.Visible = true
			Overlay.Size = UDim2.new(1, 0, 0, math.min(#options * 24, 120))
		end
	end)

	Dropdown:Refresh(options)
	if default then
		Dropdown:Set(default)
	end
	RegisterFlag(flag, Dropdown)
	table.insert(self.Rows, { Container = Row, Name = name })
	return Dropdown
end

function SectionMethods:AddButton(config)
	config = config or {}
	local name = config.Name or "Button"
	local callback = config.Callback or function() end

	local Row = RowBase(self, 30)
	local Btn = New("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Element,
		Text = name,
		TextColor3 = Theme.Text,
		FontFace = Theme.FontSemibold,
		TextSize = 13,
		AutoButtonColor = false,
		Parent = Row,
	})
	Round(Btn, 6)
	Stroke(Btn, Theme.Stroke, 1)

	Btn.MouseEnter:Connect(function()
		Tween(Btn, { BackgroundColor3 = Theme.ElementHover }, 0.15)
	end)
	Btn.MouseLeave:Connect(function()
		Tween(Btn, { BackgroundColor3 = Theme.Element }, 0.15)
	end)
	Btn.MouseButton1Click:Connect(function()
		callback()
	end)

	table.insert(self.Rows, { Container = Row, Name = name })
	return Btn
end

function SectionMethods:AddLabel(config)
	config = config or {}
	local text = config.Text or ""
	local Row = RowBase(self, 18)
	local Lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.SubText,
		FontFace = Theme.Font,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = Row,
	})
	table.insert(self.Rows, { Container = Row, Name = text })
	return Lbl
end

function SectionMethods:AddDivider()
	local Row = RowBase(self, 1)
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.6,
		Parent = Row,
	})
	table.insert(self.Rows, { Container = Row, Name = "" })
end

function Library:SaveConfig(fileName)
	if not writefile then
		warn("MavisDMA: writefile not supported by this executor")
		return false
	end
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(self.Flags)
	end)
	if ok then
		pcall(writefile, "MavisDMA_" .. fileName .. ".json", encoded)
		return true
	end
	return false
end

function Library:LoadConfig(fileName)
	if not readfile or not isfile then
		warn("MavisDMA: readfile not supported by this executor")
		return false
	end
	local path = "MavisDMA_" .. fileName .. ".json"
	if not isfile(path) then return false end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok then return false end
	for flag, value in pairs(data) do
		local obj = self._registry[flag]
		if obj and obj.Set then
			obj:Set(value)
		end
	end
	return true
end

return Library
