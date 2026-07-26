local Library = {}
Library.__index = Library

-- ── Services ──────────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local Mouse            = Players.LocalPlayer:GetMouse()

-- ── Theme ──────────────────────────────────────────────────────────────────────
local Theme = {
    BG          = Color3.fromRGB(10,  10,  16),
    Surface     = Color3.fromRGB(16,  16,  26),
    Raised      = Color3.fromRGB(22,  22,  36),
    Hover       = Color3.fromRGB(30,  30,  48),
    Accent      = Color3.fromRGB(108, 80, 245),
    AccentHover = Color3.fromRGB(130, 100, 255),
    TrackBG     = Color3.fromRGB(30,  30,  48),
    ToggleOn    = Color3.fromRGB(108, 80, 245),
    ToggleOff   = Color3.fromRGB(40,  40,  60),
    Text        = Color3.fromRGB(228, 228, 242),
    TextDim     = Color3.fromRGB(130, 130, 160),
    TextMuted   = Color3.fromRGB(75,  75,  105),
    Stroke      = Color3.fromRGB(35,  35,  55),
    Separator   = Color3.fromRGB(28,  28,  44),
    Notif = {
        info    = Color3.fromRGB(72,  162, 255),
        success = Color3.fromRGB(72,  199, 116),
        warn    = Color3.fromRGB(255, 178,  55),
        err     = Color3.fromRGB(255,  75,  75),
    },
    CornerR = UDim.new(0, 7),
    SmallR  = UDim.new(0, 4),
    MiniR   = UDim.new(0, 3),
}

-- ── Utility ────────────────────────────────────────────────────────────────────
local function New(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function Tween(obj, props, t, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(t or 0.14, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

local function Corner(parent, r)
    New("UICorner", { CornerRadius = r or Theme.CornerR, Parent = parent })
end

local function Stroke(parent, color, thickness)
    -- Remove existing stroke first to avoid stacking
    for _, c in pairs(parent:GetChildren()) do
        if c:IsA("UIStroke") then c:Destroy() end
    end
    New("UIStroke", { Color = color or Theme.Stroke, Thickness = thickness or 1, Parent = parent })
end

local function Pad(parent, top, right, bottom, left)
    New("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingRight  = UDim.new(0, right  or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 8),
        Parent        = parent,
    })
end

local function ListLayout(parent, spacing, dir, align)
    return New("UIListLayout", {
        FillDirection       = dir   or Enum.FillDirection.Vertical,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, spacing or 6),
        HorizontalAlignment = align or Enum.HorizontalAlignment.Center,
        Parent              = parent,
    })
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, startMouse, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        dragging   = true
        startMouse = input.Position
        startPos   = frame.Position
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement or not dragging then return end
        local d = input.Position - startMouse
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)
end

local function SafeGui(name)
    local sg = New("ScreenGui", {
        Name           = name or "ScriptBrosUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn   = false,
        IgnoreGuiInset = true,
    })
    local ok = pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(sg) end
        sg.Parent = CoreGui
    end)
    if not ok then
        sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    return sg
end

-- ── Notification System ────────────────────────────────────────────────────────
local NotifHolder
local NotifCount = 0

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = SafeGui("ScriptBros_Notifs")
    NotifHolder = New("Frame", {
        Name                 = "NotifHolder",
        BackgroundTransparency = 1,
        AnchorPoint          = Vector2.new(1, 1),
        Position             = UDim2.new(1, -16, 1, -16),
        Size                 = UDim2.new(0, 280, 1, -32),
        Parent               = sg,
    })
    local layout = ListLayout(NotifHolder, 8, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

function Library:Notify(opts)
    opts = opts or {}
    local title    = opts.title    or "Script Bros"
    local message  = opts.message  or ""
    local duration = opts.duration or 3
    local ntype    = opts.type     or "info"

    EnsureNotifHolder()
    local accentCol = Theme.Notif[ntype] or Theme.Notif.info

    local card = New("Frame", {
        Name             = "Notif_" .. tostring(NotifCount),
        BackgroundColor3 = Theme.Surface,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Parent           = NotifHolder,
    })
    Corner(card, Theme.SmallR)
    Stroke(card, Theme.Stroke)

    local bar = New("Frame", {
        BackgroundColor3 = accentCol,
        Size             = UDim2.new(0, 3, 1, 0),
        BorderSizePixel  = 0,
        Parent           = card,
    })
    Corner(bar, Theme.MiniR)

    local content = New("Frame", {
        BackgroundTransparency = 1,
        Position  = UDim2.new(0, 11, 0, 0),
        Size      = UDim2.new(1, -11, 1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent    = card,
    })
    Pad(content, 10, 10, 10, 0)
    ListLayout(content, 3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Size       = UDim2.new(1, 0, 0, 16),
        Font       = Enum.Font.GothamBold,
        Text       = title,
        TextColor3 = Theme.Text,
        TextSize   = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent     = content,
    })
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Font          = Enum.Font.Gotham,
        Text          = message,
        TextColor3    = Theme.TextDim,
        TextSize      = 12,
        TextWrapped   = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent        = content,
    })

    -- Slide in from right
    card.Position = UDim2.new(1.1, 0, 0, 0)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)

    task.delay(duration, function()
        Tween(card, { BackgroundTransparency = 1 }, 0.25)
        task.wait(0.3)
        card:Destroy()
    end)

    NotifCount = NotifCount + 1
end

-- ── SetTheme — call before CreateMain ─────────────────────────────────────────
function Library:SetTheme(overrides)
    for k, v in pairs(overrides or {}) do
        Theme[k] = v
    end
end

-- ── CreateMain ─────────────────────────────────────────────────────────────────
function Library:CreateMain(opts)
    opts = opts or {}
    local projName  = opts.projName or "Script Bros"
    local resizable = opts.Resizable
    local minSize   = opts.MinSize  or UDim2.new(0, 400, 0, 380)
    local maxSize   = opts.MaxSize  or UDim2.new(0, 750, 0, 550)

    local Main = {}

    -- Root
    Main.Screen = SafeGui(projName)

    -- Window
    Main.Window = New("Frame", {
        Name             = "Window",
        BackgroundColor3 = Theme.BG,
        Position         = UDim2.new(0.5, -300, 0.5, -230),
        Size             = UDim2.new(0, 600, 0, 460),
        ClipsDescendants = false,
        Parent           = Main.Screen,
    })
    Corner(Main.Window, Theme.CornerR)
    Stroke(Main.Window, Theme.Stroke)

    -- Shadow
    New("ImageLabel", {
        BackgroundTransparency = 1,
        Image            = "rbxassetid://5554236805",
        ImageColor3      = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.6,
        Position         = UDim2.new(0, -20, 0, -20),
        Size             = UDim2.new(1, 40, 1, 40),
        ZIndex           = 0,
        Parent           = Main.Window,
    })

    -- Titlebar
    local titlebar = New("Frame", {
        Name             = "Titlebar",
        BackgroundColor3 = Theme.Surface,
        Size             = UDim2.new(1, 0, 0, 38),
        ZIndex           = 3,
        Parent           = Main.Window,
    })
    Corner(titlebar, Theme.CornerR)
    -- Fill bottom half to square the bottom corners of the titlebar
    New("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        Parent           = titlebar,
    })

    -- Accent pip left of title
    local pip = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size             = UDim2.new(0, 3, 0, 18),
        Position         = UDim2.new(0, 12, 0.5, -9),
        Parent           = titlebar,
    })
    Corner(pip, Theme.MiniR)

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position       = UDim2.new(0, 22, 0, 0),
        Size           = UDim2.new(0.6, 0, 1, 0),
        Font           = Enum.Font.GothamBold,
        Text           = projName,
        TextColor3     = Theme.Text,
        TextSize       = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 4,
        Parent         = titlebar,
    })

    -- Close button
    local closeBtn = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(255, 70, 70),
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(1, -14, 0.5, -6),
        Text             = "",
        ZIndex           = 5,
        AutoButtonColor  = false,
        Parent           = titlebar,
    })
    Corner(closeBtn, UDim.new(1, 0))
    closeBtn.MouseButton1Click:Connect(function()
        Main.Window.Visible = false
    end)

    -- Minimize button
    local minBtn = New("TextButton", {
        BackgroundColor3 = Color3.fromRGB(255, 190, 50),
        Size             = UDim2.new(0, 12, 0, 12),
        Position         = UDim2.new(1, -30, 0.5, -6),
        Text             = "",
        ZIndex           = 5,
        AutoButtonColor  = false,
        Parent           = titlebar,
    })
    Corner(minBtn, UDim.new(1, 0))

    local minimized = false
    local storedSize
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            storedSize = Main.Window.Size
            Tween(Main.Window, { Size = UDim2.new(0, Main.Window.Size.X.Offset, 0, 38) }, 0.2)
        else
            Tween(Main.Window, { Size = storedSize }, 0.2)
        end
    end)

    MakeDraggable(Main.Window, titlebar)

    -- Body
    local body = New("Frame", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 38),
        Size             = UDim2.new(1, 0, 1, -38),
        ClipsDescendants = true,
        Parent           = Main.Window,
    })

    -- Sidebar
    local sidebar = New("ScrollingFrame", {
        Name             = "Sidebar",
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 140, 1, 0),
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        ClipsDescendants = true,
        Parent           = body,
    })
    -- Square the right edge of sidebar
    New("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -6, 0, 0),
        Size             = UDim2.new(0, 6, 1, 0),
        Parent           = sidebar,
    })
    Pad(sidebar, 10, 4, 10, 8)
    ListLayout(sidebar, 3, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Left)

    -- Divider
    New("Frame", {
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 140, 0, 0),
        Size             = UDim2.new(0, 1, 1, 0),
        Parent           = body,
    })

    -- Content area
    local contentHolder = New("Frame", {
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 141, 0, 0),
        Size             = UDim2.new(1, -141, 1, 0),
        ClipsDescendants = true,
        Parent           = body,
    })

    -- Resizable grip
    if resizable then
        local grip = New("TextButton", {
            BackgroundColor3     = Theme.TextMuted,
            BackgroundTransparency = 0.5,
            Size                 = UDim2.new(0, 14, 0, 14),
            Position             = UDim2.new(1, -14, 1, -14),
            Text                 = "",
            ZIndex               = 6,
            AutoButtonColor      = false,
            Parent               = Main.Window,
        })
        Corner(grip, UDim.new(0, 2))

        local resizing, rStart, rSize
        grip.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            resizing = true
            rStart   = input.Position
            rSize    = Main.Window.Size
        end)
        grip.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseMovement or not resizing then return end
            local d  = input.Position - rStart
            local nw = math.clamp(rSize.X.Offset + d.X, minSize.X.Offset, maxSize.X.Offset)
            local nh = math.clamp(rSize.Y.Offset + d.Y, minSize.Y.Offset, maxSize.Y.Offset)
            Main.Window.Size = UDim2.new(0, nw, 0, nh)
        end)
    end

    -- ── CreateCategory ─────────────────────────────────────────────────────────
    local firstCat  = true
    local activeCat = nil

    function Main:CreateCategory(name)
        local Cat = {}

        Cat.Button = New("TextButton", {
            BackgroundColor3     = Theme.Surface,
            BackgroundTransparency = 1,
            Size                 = UDim2.new(1, 0, 0, 30),
            Font                 = Enum.Font.GothamSemibold,
            Text                 = name,
            TextColor3           = Theme.TextDim,
            TextSize             = 13,
            TextXAlignment       = Enum.TextXAlignment.Left,
            AutoButtonColor      = false,
            ZIndex               = 3,
            Parent               = sidebar,
        })
        Pad(Cat.Button, 0, 6, 0, 10)
        Corner(Cat.Button, Theme.SmallR)

        local catPip = New("Frame", {
            BackgroundColor3 = Theme.Accent,
            Size             = UDim2.new(0, 3, 0, 14),
            Position         = UDim2.new(0, 2, 0.5, -7),
            Visible          = false,
            Parent           = Cat.Button,
        })
        Corner(catPip, Theme.MiniR)

        Cat.Page = New("ScrollingFrame", {
            BackgroundTransparency  = 1,
            Size                    = UDim2.new(1, 0, 1, 0),
            CanvasSize              = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize     = Enum.AutomaticSize.Y,
            ScrollBarThickness      = 3,
            ScrollBarImageColor3    = Theme.Accent,
            Visible                 = false,
            ClipsDescendants        = true,
            Parent                  = contentHolder,
        })
        Pad(Cat.Page, 12, 10, 12, 10)
        ListLayout(Cat.Page, 10, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

        local function Select()
            for _, child in pairs(sidebar:GetChildren()) do
                if child:IsA("TextButton") then
                    Tween(child, { TextColor3 = Theme.TextDim, BackgroundTransparency = 1 }, 0.12)
                    local p = child:FindFirstChildOfClass("Frame")
                    if p and p.Name ~= "UICorner" then p.Visible = false end
                end
            end
            for _, child in pairs(contentHolder:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            Tween(Cat.Button, { TextColor3 = Theme.Text, BackgroundTransparency = 0.85 }, 0.12)
            catPip.Visible  = true
            Cat.Page.Visible = true
            activeCat = Cat
        end

        Cat.Button.MouseButton1Click:Connect(Select)
        Cat.Button.MouseEnter:Connect(function()
            if activeCat ~= Cat then
                Tween(Cat.Button, { BackgroundTransparency = 0.9 }, 0.1)
            end
        end)
        Cat.Button.MouseLeave:Connect(function()
            if activeCat ~= Cat then
                Tween(Cat.Button, { BackgroundTransparency = 1 }, 0.1)
            end
        end)

        if firstCat then Select(); firstCat = false end

        -- ── CreateSection ───────────────────────────────────────────────────────
        function Cat:CreateSection(sectionName)
            local Sec = {}

            Sec.Frame = New("Frame", {
                Name             = sectionName .. "_Section",
                BackgroundColor3 = Theme.Surface,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                Parent           = Cat.Page,
            })
            Corner(Sec.Frame, Theme.CornerR)
            Stroke(Sec.Frame, Theme.Stroke)

            -- Header row
            local header = New("Frame", {
                BackgroundTransparency = 1,
                Size   = UDim2.new(1, 0, 0, 30),
                Parent = Sec.Frame,
            })
            New("TextLabel", {
                BackgroundTransparency = 1,
                Position       = UDim2.new(0, 12, 0, 0),
                Size           = UDim2.new(1, -12, 1, 0),
                Font           = Enum.Font.GothamBold,
                Text           = sectionName,
                TextColor3     = Theme.TextDim,
                TextSize       = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent         = header,
            })
            New("Frame", {
                BackgroundColor3 = Theme.Separator,
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 0, 1, -1),
                Size             = UDim2.new(1, 0, 0, 1),
                Parent           = header,
            })

            -- Items container
            Sec.List = New("Frame", {
                BackgroundTransparency = 1,
                Size          = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position      = UDim2.new(0, 0, 0, 30),
                Parent        = Sec.Frame,
            })
            Pad(Sec.List, 6, 12, 10, 12)
            ListLayout(Sec.List, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

            -- ── Create ──────────────────────────────────────────────────────────
            function Sec:Create(elemType, elemName, callback, options)
                options = options or {}
                local E = {}
                local t = elemType:lower()

                local function Row(h)
                    local f = New("Frame", {
                        BackgroundColor3 = Theme.Raised,
                        Size             = UDim2.new(1, 0, 0, h or 34),
                        Parent           = Sec.List,
                    })
                    Corner(f, Theme.SmallR)
                    return f
                end

                -- ── BUTTON ────────────────────────────────────────────────────
                if t == "button" then
                    local row = Row(34)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.65, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local btn = New("TextButton", {
                        BackgroundColor3 = Theme.Accent,
                        Size             = UDim2.new(0, 70, 0, 22),
                        Position         = UDim2.new(1, -82, 0.5, -11),
                        Font             = Enum.Font.GothamBold,
                        Text             = "Run",
                        TextColor3       = Color3.fromRGB(255, 255, 255),
                        TextSize         = 12,
                        AutoButtonColor  = false,
                        Parent           = row,
                    })
                    Corner(btn, Theme.SmallR)

                    btn.MouseEnter:Connect(function()
                        Tween(btn, { BackgroundColor3 = Theme.AccentHover }, 0.1)
                    end)
                    btn.MouseLeave:Connect(function()
                        Tween(btn, { BackgroundColor3 = Theme.Accent }, 0.1)
                    end)
                    btn.MouseButton1Click:Connect(function()
                        if options.animated then
                            Tween(btn, { Size = UDim2.new(0, 64, 0, 20) }, 0.07)
                            task.wait(0.08)
                            Tween(btn, { Size = UDim2.new(0, 70, 0, 22) }, 0.07)
                        end
                        if callback then callback() end
                    end)

                    function E:SetText(text) btn.Text = text end

                -- ── TOGGLE ───────────────────────────────────────────────────
                elseif t == "toggle" then
                    local state = options.default or false
                    local row   = Row(34)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.7, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local TW, TH = 36, 18
                    local track = New("Frame", {
                        BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff,
                        Size             = UDim2.new(0, TW, 0, TH),
                        Position         = UDim2.new(1, -(TW + 12), 0.5, -(TH / 2)),
                        Parent           = row,
                    })
                    Corner(track, UDim.new(1, 0))

                    local KS = TH - 6
                    local knob = New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size             = UDim2.new(0, KS, 0, KS),
                        Position         = state
                            and UDim2.new(0, TW - KS - 3, 0.5, -(KS / 2))
                            or  UDim2.new(0, 3, 0.5, -(KS / 2)),
                        Parent           = track,
                    })
                    Corner(knob, UDim.new(1, 0))

                    local hitbox = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size   = UDim2.new(1, 0, 1, 0),
                        Text   = "",
                        Parent = row,
                    })

                    local function SetState(val, fire)
                        state = val
                        Tween(track, { BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff }, 0.15)
                        Tween(knob, {
                            Position = state
                                and UDim2.new(0, TW - KS - 3, 0.5, -(KS / 2))
                                or  UDim2.new(0, 3, 0.5, -(KS / 2))
                        }, 0.15)
                        if fire and callback then callback(state) end
                    end

                    if options.default then SetState(true, true) end
                    hitbox.MouseButton1Click:Connect(function() SetState(not state, true) end)

                    function E:Set(val) SetState(val, false) end
                    function E:Get() return state end

                -- ── SLIDER ───────────────────────────────────────────────────
                elseif t == "slider" then
                    local sMin     = options.min     or 0
                    local sMax     = options.max     or 100
                    local precise  = options.precise or false
                    local cur      = options.default or sMin

                    local row = Row(50)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 6),
                        Size           = UDim2.new(0.65, 0, 0, 20),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local valLbl = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 0, 0, 6),
                        Size           = UDim2.new(1, -12, 0, 20),
                        Font           = Enum.Font.GothamBold,
                        Text           = tostring(cur),
                        TextColor3     = Theme.Accent,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        Parent         = row,
                    })

                    local trackBG = New("Frame", {
                        BackgroundColor3 = Theme.TrackBG,
                        Size             = UDim2.new(1, -24, 0, 5),
                        Position         = UDim2.new(0, 12, 0, 36),
                        Parent           = row,
                    })
                    Corner(trackBG, UDim.new(1, 0))

                    local initRatio = math.clamp((cur - sMin) / (sMax - sMin), 0, 1)
                    local fill = New("Frame", {
                        BackgroundColor3 = Theme.Accent,
                        Size             = UDim2.new(initRatio, 0, 1, 0),
                        Parent           = trackBG,
                    })
                    Corner(fill, UDim.new(1, 0))

                    local hitbox = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size     = UDim2.new(1, 0, 0, 22),
                        Position = UDim2.new(0, 0, 0, -8),
                        Text     = "",
                        ZIndex   = 3,
                        Parent   = trackBG,
                    })

                    local sliding = false

                    local function UpdateSlider()
                        local ratio = math.clamp(
                            (Mouse.X - trackBG.AbsolutePosition.X) / trackBG.AbsoluteSize.X,
                            0, 1
                        )
                        local raw = sMin + (sMax - sMin) * ratio
                        cur = precise and (math.floor(raw * 10) / 10) or math.floor(raw)
                        valLbl.Text = tostring(cur)
                        Tween(fill, { Size = UDim2.new(ratio, 0, 1, 0) }, 0.05)
                        if callback then callback(cur) end
                    end

                    hitbox.MouseButton1Down:Connect(function()
                        sliding = true
                        UpdateSlider()
                    end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            sliding = false
                        end
                    end)
                    RunService.Heartbeat:Connect(function()
                        if sliding then UpdateSlider() end
                    end)

                    function E:Set(val)
                        cur = math.clamp(val, sMin, sMax)
                        valLbl.Text = tostring(cur)
                        Tween(fill, { Size = UDim2.new((cur - sMin) / (sMax - sMin), 0, 1, 0) }, 0.1)
                    end
                    function E:Get() return cur end

                -- ── TEXTBOX ──────────────────────────────────────────────────
                elseif t == "textbox" then
                    local row = Row(34)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.45, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local boxBG = New("Frame", {
                        BackgroundColor3 = Theme.TrackBG,
                        Size             = UDim2.new(0, 140, 0, 22),
                        Position         = UDim2.new(1, -152, 0.5, -11),
                        Parent           = row,
                    })
                    Corner(boxBG, Theme.SmallR)
                    Stroke(boxBG, Theme.Stroke)

                    local tb = New("TextBox", {
                        BackgroundTransparency = 1,
                        Size              = UDim2.new(1, -8, 1, 0),
                        Position          = UDim2.new(0, 6, 0, 0),
                        Font              = Enum.Font.Gotham,
                        PlaceholderText   = options.text or "Type here...",
                        PlaceholderColor3 = Theme.TextMuted,
                        Text              = "",
                        TextColor3        = Theme.Text,
                        TextSize          = 12,
                        ClearTextOnFocus  = false,
                        TextXAlignment    = Enum.TextXAlignment.Left,
                        Parent            = boxBG,
                    })

                    tb.Focused:Connect(function()
                        Tween(boxBG, { BackgroundColor3 = Theme.Hover }, 0.12)
                        Stroke(boxBG, Theme.Accent)
                    end)
                    tb.FocusLost:Connect(function()
                        Tween(boxBG, { BackgroundColor3 = Theme.TrackBG }, 0.12)
                        Stroke(boxBG, Theme.Stroke)
                        if callback then callback(tb.Text) end
                    end)

                    function E:Set(text) tb.Text = text end
                    function E:Get() return tb.Text end

                -- ── KEYBIND ──────────────────────────────────────────────────
                elseif t == "keybind" then
                    local bind     = options.default
                    local listening = false
                    local bindConn

                    local row = Row(34)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.55, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local keyBG = New("TextButton", {
                        BackgroundColor3 = Theme.TrackBG,
                        Size             = UDim2.new(0, 90, 0, 22),
                        Position         = UDim2.new(1, -102, 0.5, -11),
                        Font             = Enum.Font.GothamBold,
                        Text             = bind and bind.Name or "None",
                        TextColor3       = Theme.TextDim,
                        TextSize         = 12,
                        AutoButtonColor  = false,
                        Parent           = row,
                    })
                    Corner(keyBG, Theme.SmallR)
                    Stroke(keyBG, Theme.Stroke)

                    keyBG.MouseButton1Click:Connect(function()
                        if listening then return end
                        listening = true
                        keyBG.Text      = "..."
                        keyBG.TextColor3 = Theme.Accent
                        if bindConn then bindConn:Disconnect() end
                        bindConn = UserInputService.InputBegan:Connect(function(input, gpe)
                            if gpe then return end
                            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                            if input.KeyCode == Enum.KeyCode.Backspace then
                                bind = nil
                                keyBG.Text = "None"
                            else
                                bind = input.KeyCode
                                keyBG.Text = bind.Name
                            end
                            keyBG.TextColor3 = Theme.TextDim
                            listening = false
                            bindConn:Disconnect()
                        end)
                    end)

                    UserInputService.InputBegan:Connect(function(input, gpe)
                        if gpe or listening or not bind then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard
                            and input.KeyCode == bind then
                            if callback then callback(bind) end
                        end
                    end)

                    function E:Set(key) bind = key; keyBG.Text = key and key.Name or "None" end
                    function E:Get() return bind end

                -- ── DROPDOWN ─────────────────────────────────────────────────
                elseif t == "dropdown" then
                    local optsList = options.options or {}
                    local selected = options.default or (optsList[1] or "")
                    local open     = false
                    local EXPAND   = 120

                    -- wrapper grows when open
                    local wrapper = New("Frame", {
                        BackgroundTransparency = 1,
                        Size             = UDim2.new(1, 0, 0, 34),
                        ClipsDescendants = false,
                        ZIndex           = 2,
                        Parent           = Sec.List,
                    })

                    local row = New("Frame", {
                        BackgroundColor3 = Theme.Raised,
                        Size             = UDim2.new(1, 0, 0, 34),
                        ClipsDescendants = false,
                        ZIndex           = 2,
                        Parent           = wrapper,
                    })
                    Corner(row, Theme.SmallR)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.55, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex         = 3,
                        Parent         = row,
                    })

                    local selLbl = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size           = UDim2.new(1, -40, 1, 0),
                        Font           = Enum.Font.Gotham,
                        Text           = tostring(selected),
                        TextColor3     = Theme.Accent,
                        TextSize       = 12,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex         = 3,
                        Parent         = row,
                    })

                    local arrow = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position  = UDim2.new(1, -26, 0.5, -8),
                        Size      = UDim2.new(0, 16, 0, 16),
                        Font      = Enum.Font.GothamBold,
                        Text      = "▾",
                        TextColor3 = Theme.TextDim,
                        TextSize  = 14,
                        ZIndex    = 3,
                        Parent    = row,
                    })

                    -- List panel
                    local listFrame = New("Frame", {
                        BackgroundColor3 = Theme.Surface,
                        Size             = UDim2.new(1, 0, 0, 0),
                        Position         = UDim2.new(0, 0, 0, 36),
                        ClipsDescendants = true,
                        ZIndex           = 10,
                        Parent           = row,
                    })
                    Corner(listFrame, Theme.SmallR)
                    Stroke(listFrame, Theme.Stroke)

                    local listScroll = New("ScrollingFrame", {
                        BackgroundTransparency  = 1,
                        Size                    = UDim2.new(1, 0, 1, 0),
                        CanvasSize              = UDim2.new(0, 0, 0, 0),
                        AutomaticCanvasSize     = Enum.AutomaticSize.Y,
                        ScrollBarThickness      = 3,
                        ScrollBarImageColor3    = Theme.Accent,
                        ZIndex                  = 10,
                        Parent                  = listFrame,
                    })
                    Pad(listScroll, 4, 4, 4, 4)
                    ListLayout(listScroll, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)

                    -- Optional search box
                    local searchBox
                    if options.search then
                        local sbg = New("Frame", {
                            BackgroundColor3 = Theme.Raised,
                            Size             = UDim2.new(1, -4, 0, 24),
                            ZIndex           = 11,
                            Parent           = listScroll,
                        })
                        Corner(sbg, Theme.MiniR)
                        searchBox = New("TextBox", {
                            BackgroundTransparency = 1,
                            Size              = UDim2.new(1, -8, 1, 0),
                            Position          = UDim2.new(0, 6, 0, 0),
                            Font              = Enum.Font.Gotham,
                            PlaceholderText   = "Search...",
                            PlaceholderColor3 = Theme.TextMuted,
                            Text              = "",
                            TextColor3        = Theme.Text,
                            TextSize          = 12,
                            ClearTextOnFocus  = false,
                            ZIndex            = 11,
                            Parent            = sbg,
                        })
                    end

                    local itemBtns = {}
                    local function BuildList(filter)
                        for _, b in pairs(itemBtns) do b:Destroy() end
                        itemBtns = {}
                        for _, opt in ipairs(optsList) do
                            local show = not filter
                                or string.find(string.lower(tostring(opt)), string.lower(filter), 1, true)
                            if show then
                                local btn = New("TextButton", {
                                    BackgroundColor3 = Theme.Raised,
                                    Size             = UDim2.new(1, 0, 0, 26),
                                    Font             = Enum.Font.Gotham,
                                    Text             = tostring(opt),
                                    TextColor3       = Theme.Text,
                                    TextSize         = 12,
                                    AutoButtonColor  = false,
                                    ZIndex           = 11,
                                    Parent           = listScroll,
                                })
                                Corner(btn, Theme.MiniR)
                                btn.MouseEnter:Connect(function()
                                    Tween(btn, { BackgroundColor3 = Theme.Hover }, 0.08)
                                end)
                                btn.MouseLeave:Connect(function()
                                    Tween(btn, { BackgroundColor3 = Theme.Raised }, 0.08)
                                end)
                                btn.MouseButton1Click:Connect(function()
                                    selected = opt
                                    selLbl.Text = tostring(opt)
                                    open = false
                                    Tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                                    Tween(wrapper, { Size = UDim2.new(1, 0, 0, 34) }, 0.15)
                                    Tween(arrow, { Rotation = 0 }, 0.15)
                                    if callback then callback(selected) end
                                end)
                                table.insert(itemBtns, btn)
                            end
                        end
                    end

                    BuildList()

                    if searchBox then
                        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                            BuildList(searchBox.Text ~= "" and searchBox.Text or nil)
                        end)
                    end

                    local toggleBtn = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size   = UDim2.new(1, 0, 1, 0),
                        Text   = "",
                        ZIndex = 5,
                        Parent = row,
                    })
                    toggleBtn.MouseButton1Click:Connect(function()
                        open = not open
                        if open then
                            BuildList(searchBox and searchBox.Text ~= "" and searchBox.Text or nil)
                            Tween(listFrame, { Size = UDim2.new(1, 0, 0, EXPAND) }, 0.18, Enum.EasingStyle.Quart)
                            Tween(wrapper, { Size = UDim2.new(1, 0, 0, 34 + EXPAND + 4) }, 0.18, Enum.EasingStyle.Quart)
                            Tween(arrow, { Rotation = 180 }, 0.15)
                        else
                            Tween(listFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                            Tween(wrapper, { Size = UDim2.new(1, 0, 0, 34) }, 0.15)
                            Tween(arrow, { Rotation = 0 }, 0.15)
                        end
                    end)

                    function E:Set(val) selected = val; selLbl.Text = tostring(val) end
                    function E:Get() return selected end
                    function E:SetOptions(newOpts) optsList = newOpts; BuildList() end

                -- ── COLORPICKER ──────────────────────────────────────────────
                elseif t == "colorpicker" then
                    local h_v, s_v, v_v = Color3.toHSV(options.default or Color3.fromRGB(255, 0, 0))
                    local currentColor   = options.default or Color3.fromRGB(255, 0, 0)
                    local cpOpen         = false

                    local row = Row(34)

                    New("TextLabel", {
                        BackgroundTransparency = 1,
                        Position       = UDim2.new(0, 12, 0, 0),
                        Size           = UDim2.new(0.6, 0, 1, 0),
                        Font           = Enum.Font.GothamSemibold,
                        Text           = elemName,
                        TextColor3     = Theme.Text,
                        TextSize       = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        Parent         = row,
                    })

                    local swatch = New("Frame", {
                        BackgroundColor3 = currentColor,
                        Size             = UDim2.new(0, 52, 0, 20),
                        Position         = UDim2.new(1, -64, 0.5, -10),
                        Parent           = row,
                    })
                    Corner(swatch, Theme.MiniR)
                    Stroke(swatch, Theme.Stroke)

                    local openBtn = New("TextButton", {
                        BackgroundTransparency = 1,
                        Size   = UDim2.new(1, 0, 1, 0),
                        Text   = "",
                        ZIndex = 3,
                        Parent = row,
                    })

                    -- Floating panel
                    local panel = New("Frame", {
                        BackgroundColor3 = Theme.Surface,
                        Size             = UDim2.new(0, 220, 0, 200),
                        Position         = UDim2.new(0, 150, 0, 80),
                        Visible          = false,
                        ZIndex           = 20,
                        Parent           = Main.Window,
                    })
                    Corner(panel, Theme.CornerR)
                    Stroke(panel, Theme.Stroke)
                    MakeDraggable(panel)

                    -- SV square
                    local svPicker = New("ImageButton", {
                        BackgroundColor3 = Color3.fromHSV(h_v, 1, 1),
                        Size             = UDim2.new(0, 150, 0, 120),
                        Position         = UDim2.new(0, 10, 0, 10),
                        Image            = "rbxassetid://5113592272",
                        AutoButtonColor  = false,
                        ZIndex           = 21,
                        Parent           = panel,
                    })
                    Corner(svPicker, Theme.SmallR)
                    New("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size  = UDim2.new(1, 0, 1, 0),
                        Image = "rbxassetid://5113600420",
                        ZIndex = 21,
                        Parent = svPicker,
                    })
                    local svKnob = New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        AnchorPoint      = Vector2.new(0.5, 0.5),
                        Size             = UDim2.new(0, 10, 0, 10),
                        Position         = UDim2.new(s_v, 0, 1 - v_v, 0),
                        ZIndex           = 22,
                        Parent           = svPicker,
                    })
                    Corner(svKnob, UDim.new(1, 0))
                    Stroke(svKnob, Color3.fromRGB(0, 0, 0))

                    -- Hue strip
                    local huePicker = New("ImageButton", {
                        Size            = UDim2.new(0, 14, 0, 120),
                        Position        = UDim2.new(0, 170, 0, 10),
                        Image           = "rbxassetid://5118428654",
                        AutoButtonColor = false,
                        ZIndex          = 21,
                        Parent          = panel,
                    })
                    Corner(huePicker, Theme.MiniR)
                    local hueKnob = New("Frame", {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        Size             = UDim2.new(1, 0, 0, 3),
                        AnchorPoint      = Vector2.new(0, 0.5),
                        Position         = UDim2.new(0, 0, h_v, 0),
                        ZIndex           = 22,
                        Parent           = huePicker,
                    })
                    Corner(hueKnob, UDim.new(1, 0))

                    -- Preview + Done
                    local preview = New("Frame", {
                        BackgroundColor3 = currentColor,
                        Size             = UDim2.new(0, 60, 0, 22),
                        Position         = UDim2.new(0, 10, 0, 144),
                        ZIndex           = 21,
                        Parent           = panel,
                    })
                    Corner(preview, Theme.MiniR)

                    local doneBtn = New("TextButton", {
                        BackgroundColor3 = Theme.Accent,
                        Size             = UDim2.new(0, 100, 0, 22),
                        Position         = UDim2.new(1, -110, 0, 144),
                        Font             = Enum.Font.GothamBold,
                        Text             = "Done",
                        TextColor3       = Color3.fromRGB(255, 255, 255),
                        TextSize         = 12,
                        AutoButtonColor  = false,
                        ZIndex           = 21,
                        Parent           = panel,
                    })
                    Corner(doneBtn, Theme.SmallR)

                    local function UpdateColor()
                        currentColor = Color3.fromHSV(h_v, s_v, v_v)
                        swatch.BackgroundColor3   = currentColor
                        preview.BackgroundColor3  = currentColor
                        svPicker.BackgroundColor3 = Color3.fromHSV(h_v, 1, 1)
                        svKnob.Position           = UDim2.new(s_v, 0, 1 - v_v, 0)
                        hueKnob.Position          = UDim2.new(0, 0, h_v, 0)
                        if callback then callback(currentColor) end
                    end

                    local hueDrag, svDrag = false, false
                    huePicker.MouseButton1Down:Connect(function() hueDrag = true end)
                    svPicker.MouseButton1Down:Connect(function()  svDrag  = true end)
                    UserInputService.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDrag = false
                            svDrag  = false
                        end
                    end)
                    RunService.Heartbeat:Connect(function()
                        if hueDrag then
                            h_v = math.clamp(
                                (Mouse.Y - huePicker.AbsolutePosition.Y) / huePicker.AbsoluteSize.Y, 0, 1
                            )
                            UpdateColor()
                        end
                        if svDrag then
                            s_v = math.clamp(
                                (Mouse.X - svPicker.AbsolutePosition.X) / svPicker.AbsoluteSize.X, 0, 1
                            )
                            v_v = 1 - math.clamp(
                                (Mouse.Y - svPicker.AbsolutePosition.Y) / svPicker.AbsoluteSize.Y, 0, 1
                            )
                            UpdateColor()
                        end
                    end)

                    openBtn.MouseButton1Click:Connect(function()
                        cpOpen = not cpOpen
                        panel.Visible = cpOpen
                        if cpOpen then
                            local abs = row.AbsolutePosition
                            local wp  = Main.Window.AbsolutePosition
                            panel.Position = UDim2.new(
                                0, abs.X - wp.X + row.AbsoluteSize.X + 8,
                                0, abs.Y - wp.Y
                            )
                        end
                    end)
                    doneBtn.MouseButton1Click:Connect(function()
                        cpOpen = false
                        panel.Visible = false
                    end)

                    UpdateColor()

                    function E:Set(col)
                        h_v, s_v, v_v = Color3.toHSV(col)
                        UpdateColor()
                    end
                    function E:Get() return currentColor end

                -- ── LABEL ────────────────────────────────────────────────────
                elseif t == "label" then
                    local lbl = New("TextLabel", {
                        BackgroundTransparency = 1,
                        Size           = UDim2.new(1, 0, 0, 0),
                        AutomaticSize  = Enum.AutomaticSize.Y,
                        Font           = Enum.Font.Gotham,
                        Text           = elemName,
                        TextColor3     = Theme.TextDim,
                        TextSize       = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextWrapped    = true,
                        Parent         = Sec.List,
                    })
                    Pad(lbl, 2, 0, 2, 4)
                    function E:Set(text) lbl.Text = text end
                    function E:Get() return lbl.Text end

                -- ── SEPARATOR ────────────────────────────────────────────────
                elseif t == "separator" then
                    New("Frame", {
                        BackgroundColor3 = Theme.Separator,
                        BorderSizePixel  = 0,
                        Size             = UDim2.new(1, 0, 0, 1),
                        Parent           = Sec.List,
                    })
                end

                return E
            end

            return Sec
        end

        return Cat
    end

    -- ── Utility methods ────────────────────────────────────────────────────────
    function Main:Destroy()
        Main.Screen:Destroy()
    end

    function Main:SetVisible(bool)
        Main.Window.Visible = bool
    end

    function Main:Toggle()
        Main.Window.Visible = not Main.Window.Visible
    end

    return Main
end

return Library
