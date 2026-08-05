local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
	Window        = Color3.fromRGB(24, 24, 26),
	TopBar        = Color3.fromRGB(20, 20, 22),
	Sidebar       = Color3.fromRGB(20, 20, 22),
	SidebarActive = Color3.fromRGB(38, 38, 42),
	Content       = Color3.fromRGB(30, 30, 32),
	Card          = Color3.fromRGB(44, 44, 48),
	CardHover     = Color3.fromRGB(52, 52, 57),
	Stroke        = Color3.fromRGB(52, 52, 56),

	TextPrimary   = Color3.fromRGB(235, 235, 235),
	TextSecondary = Color3.fromRGB(150, 150, 155),
	TextMuted     = Color3.fromRGB(120, 120, 125),

	Accent        = Color3.fromRGB(59, 130, 246),  
	Warning       = Color3.fromRGB(232, 163, 61),   
	WarningBg     = Color3.fromRGB(50, 40, 22),
	WarningStroke = Color3.fromRGB(120, 90, 30),

	IconGray      = Color3.fromRGB(154, 154, 154),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_REG = Enum.Font.Gotham

local function new(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color or Theme.Stroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
	})
end

local function tween(inst, props, time, style, dir)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local ICONS = {
	home = "rbxassetid://10734943274",
	discord = "rbxassetid://10734955013",
	youtube = "rbxassetid://10734967205",
	warning = "rbxassetid://10747384394",
}

local Library = {}
Library.__index = Library

function Library:CreateWindow(config)
	config = config or {}
	local title = config.Title or "Window"

	local existing = PlayerGui:FindFirstChild("CursorHubLib")
	if existing then existing:Destroy() end

	local ScreenGui = new("ScreenGui", {
		Name = "CursorHubLib",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	local Main = new("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(530, 410),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	}, {
		corner(8),
		stroke(Theme.Stroke, 1, 0.4),
	})

	new("UISizeConstraint", {
		MinSize = Vector2.new(380, 300),
		MaxSize = Vector2.new(700, 550),
		Parent = Main,
	})

	local TopBar = new("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.TopBar,
		BorderSizePixel = 0,
		Parent = Main,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TopBar })

	new("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Theme.TopBar,
		BorderSizePixel = 0,
		ZIndex = 0,
		Parent = TopBar,
	})

	new("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0, 250, 1, 0),
		Font = FONT_BOLD,
		Text = title,
		TextColor3 = Theme.TextPrimary,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TopBar,
	})

	local IconBar = new("Frame", {
		Name = "IconBar",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(140, 24),
		BackgroundTransparency = 1,
		Parent = TopBar,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 14),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function iconButton(name, imageId, order, onClick)
		local btn = new("ImageButton", {
			Name = name,
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = imageId,
			ImageColor3 = Theme.IconGray,
			LayoutOrder = order,
			Parent = IconBar,
		})
		btn.MouseEnter:Connect(function()
			tween(btn, { ImageColor3 = Theme.TextPrimary }, 0.1)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { ImageColor3 = Theme.IconGray }, 0.1)
		end)
		if onClick then
			btn.MouseButton1Click:Connect(onClick)
		end
		return btn
	end

	iconButton("Discord", ICONS.discord, 1)
	iconButton("YouTube", ICONS.youtube, 2)

	local Minimized = false
	local ContentHeightCache

	local minimizeBtn = new("TextButton", {
		Name = "Minimize",
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "—",
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = Theme.IconGray,
		LayoutOrder = 3,
		Parent = IconBar,
	})
	minimizeBtn.MouseEnter:Connect(function() tween(minimizeBtn, { TextColor3 = Theme.TextPrimary }, 0.1) end)
	minimizeBtn.MouseLeave:Connect(function() tween(minimizeBtn, { TextColor3 = Theme.IconGray }, 0.1) end)

	local closeBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		Text = "✕",
		Font = FONT_BOLD,
		TextSize = 14,
		TextColor3 = Theme.IconGray,
		LayoutOrder = 4,
		Parent = IconBar,
	})
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, { TextColor3 = Color3.fromRGB(230, 90, 90) }, 0.1) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, { TextColor3 = Theme.IconGray }, 0.1) end)
	closeBtn.MouseButton1Click:Connect(function()
		tween(Main, { Size = UDim2.fromOffset(0, 0) }, 0.18)
		task.delay(0.18, function() ScreenGui:Destroy() end)
	end)

	local Body = new("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		BackgroundTransparency = 1,
		Parent = Main,
	})

	minimizeBtn.MouseButton1Click:Connect(function()
		Minimized = not Minimized
		if Minimized then
			ContentHeightCache = Main.Size
			tween(Main, { Size = UDim2.fromOffset(Main.AbsoluteSize.X, 40) }, 0.18)
		else
			tween(Main, { Size = ContentHeightCache or UDim2.fromOffset(530, 410) }, 0.18)
		end
	end)

	do
		local dragging, dragStart, startPos
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
				Main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	local Sidebar = new("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 140, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = Body,
	})

	local SidebarList = new("Frame", {
		Name = "TabList",
		Position = UDim2.fromOffset(0, 8),
		Size = UDim2.new(1, 0, 1, -8),
		BackgroundTransparency = 1,
		Parent = Sidebar,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		new("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	})

	local Content = new("Frame", {
		Name = "Content",
		Position = UDim2.new(0, 140, 0, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Parent = Body,
	})

	local Window = setmetatable({
		ScreenGui = ScreenGui,
		Main = Main,
		Sidebar = SidebarList,
		Content = Content,
		Tabs = {},
		ActiveTab = nil,
	}, { __index = {} })

	function Window:CreateTab(tabConfig)
		tabConfig = tabConfig or {}
		local tabName = tabConfig.Name or "Tab"

		local NavButton = new("TextButton", {
			Name = tabName .. "NavButton",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.SidebarActive,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = #Window.Tabs + 1,
			Parent = SidebarList,
		}, { corner(6) })

		local NavIcon = new("ImageLabel", {
			Name = "Icon",
			Position = UDim2.fromOffset(10, 9),
			Size = UDim2.fromOffset(16, 16),
			BackgroundTransparency = 1,
			Image = ICONS.home,
			ImageColor3 = Theme.TextSecondary,
			Parent = NavButton,
		})

		local NavLabel = new("TextLabel", {
			Name = "Label",
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -40, 1, 0),
			BackgroundTransparency = 1,
			Font = FONT,
			Text = tabName,
			TextColor3 = Theme.TextSecondary,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = NavButton,
		})

		local Page = new("ScrollingFrame", {
			Name = tabName .. "Page",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Stroke,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Content,
		}, {
			new("UIListLayout", {
				Padding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			new("UIPadding", {
				PaddingTop = UDim.new(0, 16),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 16),
				PaddingBottom = UDim.new(0, 16),
			}),
		})

		local Tab = { Page = Page, NavButton = NavButton, NavIcon = NavIcon, NavLabel = NavLabel }
		table.insert(Window.Tabs, Tab)

		local function selectTab()
			for _, t in ipairs(Window.Tabs) do
				t.Page.Visible = false
				tween(t.NavButton, { BackgroundTransparency = 1 }, 0.12)
				tween(t.NavIcon, { ImageColor3 = Theme.TextSecondary }, 0.12)
				tween(t.NavLabel, { TextColor3 = Theme.TextSecondary }, 0.12)
			end
			Page.Visible = true
			tween(NavButton, { BackgroundTransparency = 0 }, 0.12)
			tween(NavIcon, { ImageColor3 = Theme.Accent }, 0.12)
			tween(NavLabel, { TextColor3 = Theme.TextPrimary }, 0.12)
			Window.ActiveTab = Tab
		end

		NavButton.MouseButton1Click:Connect(selectTab)
		NavButton.MouseEnter:Connect(function()
			if Window.ActiveTab ~= Tab then
				tween(NavButton, { BackgroundTransparency = 0.6 }, 0.1)
			end
		end)
		NavButton.MouseLeave:Connect(function()
			if Window.ActiveTab ~= Tab then
				tween(NavButton, { BackgroundTransparency = 1 }, 0.1)
			end
		end)

		if #Window.Tabs == 1 then
			selectTab()
		end

		local TabAPI = {}

		local function cardRow(height)
			return new("Frame", {
				Size = UDim2.new(1, 0, 0, height or 44),
				BackgroundColor3 = Theme.Card,
				BorderSizePixel = 0,
				Parent = Page,
			}, { corner(6) })
		end

		function TabAPI:AddLabel(text)
			local lbl = new("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Font = FONT_REG,
				Text = text,
				TextColor3 = Theme.TextSecondary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = Page,
			})
			return lbl
		end

		function TabAPI:AddParagraph(cfg)
			cfg = cfg or {}
			return TabAPI:AddLabel(cfg.Title or cfg.Content or "")
		end

		function TabAPI:AddWarning(text)
			local row = new("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundColor3 = Theme.WarningBg,
				BorderSizePixel = 0,
				Parent = Page,
			}, {
				corner(6),
				stroke(Theme.WarningStroke, 1, 0.3),
			})

			new("ImageLabel", {
				Position = UDim2.fromOffset(14, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(16, 16),
				Position2 = nil,
				BackgroundTransparency = 1,
				Image = ICONS.warning,
				ImageColor3 = Theme.Warning,
				Parent = row,
			}).Position = UDim2.new(0, 14, 0.5, 0)

			new("TextLabel", {
				Position = UDim2.fromOffset(38, 0),
				Size = UDim2.new(1, -50, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = text,
				TextColor3 = Theme.Warning,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			return row
		end

		function TabAPI:AddButton(cfg)
			cfg = cfg or {}
			local row = cardRow(44)
			local btn = new("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				AutoButtonColor = false,
				Font = FONT,
				Text = cfg.Name or "Button",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				Parent = row,
			})
			btn.MouseEnter:Connect(function() tween(row, { BackgroundColor3 = Theme.CardHover }, 0.1) end)
			btn.MouseLeave:Connect(function() tween(row, { BackgroundColor3 = Theme.Card }, 0.1) end)
			btn.MouseButton1Down:Connect(function() tween(row, { Size = UDim2.new(0.99, 0, 0, 43) }, 0.08) end)
			btn.MouseButton1Up:Connect(function() tween(row, { Size = UDim2.new(1, 0, 0, 44) }, 0.08) end)
			btn.MouseButton1Click:Connect(function()
				if cfg.Callback then task.spawn(cfg.Callback) end
			end)
			return row
		end

		function TabAPI:AddToggle(cfg)
			cfg = cfg or {}
			local state = cfg.Default or false
			local row = cardRow(44)

			new("TextLabel", {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -80, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = cfg.Name or "Toggle",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local Track = new("TextButton", {
				Name = "Track",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(38, 20),
				BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 60, 64),
				AutoButtonColor = false,
				Text = "",
				Parent = row,
			}, { corner(10) })

			local Knob = new("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = Track,
			}, { corner(8) })

			local function set(newState)
				state = newState
				tween(Track, { BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(60, 60, 64) }, 0.15)
				tween(Knob, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }, 0.15)
				if cfg.Callback then task.spawn(cfg.Callback, state) end
			end

			Track.MouseButton1Click:Connect(function() set(not state) end)

			return { Set = set, Get = function() return state end }
		end

		function TabAPI:AddValueLabel(cfg)
			cfg = cfg or {}
			local row = cardRow(44)
			new("TextLabel", {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -80, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = cfg.Name or "Value",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})
			local valueLbl = new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(60, 20),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = tostring(cfg.Default or 0),
				TextColor3 = Theme.Accent,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})
			return {
				Set = function(v) valueLbl.Text = tostring(v) end,
			}
		end

		function TabAPI:AddSlider(cfg)
			cfg = cfg or {}
			local min = cfg.Min or 0
			local max = cfg.Max or 100
			local value = cfg.Default or min

			local row = cardRow(56)

			new("TextLabel", {
				Position = UDim2.fromOffset(14, 8),
				Size = UDim2.new(1, -80, 0, 18),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = cfg.Name or "Slider",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local valueLbl = new("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -14, 0, 8),
				Size = UDim2.fromOffset(50, 18),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = tostring(value),
				TextColor3 = Theme.Accent,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = row,
			})

			local Bar = new("Frame", {
				Position = UDim2.new(0, 14, 0, 34),
				Size = UDim2.new(1, -28, 0, 4),
				BackgroundColor3 = Color3.fromRGB(60, 60, 64),
				BorderSizePixel = 0,
				Parent = row,
			}, { corner(2) })

			local Fill = new("Frame", {
				Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
				Parent = Bar,
			}, { corner(2) })

			local Knob = new("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = false,
				Text = "",
				ZIndex = 2,
				Parent = Bar,
			}, { corner(7) })

			local function setFromAlpha(alpha)
				alpha = math.clamp(alpha, 0, 1)
				value = math.floor(min + (max - min) * alpha + 0.5)
				local a = (value - min) / (max - min)
				Fill.Size = UDim2.new(a, 0, 1, 0)
				Knob.Position = UDim2.new(a, 0, 0.5, 0)
				valueLbl.Text = tostring(value)
				if cfg.Callback then task.spawn(cfg.Callback, value) end
			end

			local dragging = false
			Knob.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local rel = (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
					setFromAlpha(rel)
				end
			end)
			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local rel = (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X
					setFromAlpha(rel)
				end
			end)

			return { Set = function(v) setFromAlpha((v - min) / (max - min)) end, Get = function() return value end }
		end

		function TabAPI:AddTextbox(cfg)
			cfg = cfg or {}
			local row = cardRow(44)

			new("TextLabel", {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = cfg.Name or "Textbox",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local BoxHolder = new("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(120, 28),
				BackgroundColor3 = Theme.Window,
				BorderSizePixel = 0,
				Parent = row,
			}, { corner(5), stroke(Theme.Stroke, 1, 0.3) })

			local Box = new("TextBox", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.fromOffset(8, 0),
				BackgroundTransparency = 1,
				Font = FONT_REG,
				PlaceholderText = cfg.Placeholder or "type...",
				PlaceholderColor3 = Theme.TextMuted,
				Text = "",
				TextColor3 = Theme.TextPrimary,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				Parent = BoxHolder,
			})

			Box.FocusLost:Connect(function(enterPressed)
				if cfg.Callback then task.spawn(cfg.Callback, Box.Text, enterPressed) end
			end)

			return { Set = function(v) Box.Text = v end, Get = function() return Box.Text end }
		end

		function TabAPI:AddColorPicker(cfg)
			cfg = cfg or {}
			local color = cfg.Default or Color3.fromRGB(219, 40, 40)
			local row = cardRow(44)

			new("TextLabel", {
				Position = UDim2.fromOffset(14, 0),
				Size = UDim2.new(1, -80, 1, 0),
				BackgroundTransparency = 1,
				Font = FONT,
				Text = cfg.Name or "Color",
				TextColor3 = Theme.TextPrimary,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = row,
			})

			local Swatch = new("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -14, 0.5, 0),
				Size = UDim2.fromOffset(36, 18),
				BackgroundColor3 = color,
				AutoButtonColor = false,
				Text = "",
				Parent = row,
			}, { corner(4) })

			Swatch.MouseButton1Click:Connect(function()
				if cfg.Callback then task.spawn(cfg.Callback, color) end
			end)

			return {
				Set = function(c)
					color = c
					Swatch.BackgroundColor3 = c
					if cfg.Callback then task.spawn(cfg.Callback, c) end
				end,
				Get = function() return color end,
			}
		end

		return TabAPI
	end

	return Window
end

return Library
