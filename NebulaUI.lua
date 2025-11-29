-- NebulaUI.lua
-- Cała biblioteka w jednym pliku

-- 🔸 Theme (style)
local Theme = {}
Theme.Background = Color3.fromRGB(25,25,35)
Theme.Panel      = Color3.fromRGB(35,35,45)
Theme.Button     = Color3.fromRGB(55,55,65)
Theme.Text       = Color3.fromRGB(255,255,255)
Theme.Accent     = Color3.fromRGB(155,92,246)

function Theme.StyleButton(btn)
    btn.BackgroundColor3 = Theme.Button
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
end

function Theme.StyleLabel(lbl)
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.BackgroundTransparency = 1
end

-- 🔸 Helpers (narzędzia)
local Helpers = {}

function Helpers.Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

function Helpers.SafeCallback(fn, ...)
    if typeof(fn) == "function" then
        local ok, err = pcall(fn, ...)
        if not ok then warn("[NebulaUI] Error:", err) end
    end
end

function Helpers.MakeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
end

-- 🔸 Core start (Window)
local NebulaUI = {}

function NebulaUI:CreateWindow(options)
    local screen = Instance.new("ScreenGui")
    screen.Name = options.Name or "NebulaWindow"
    screen.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = screen

    return {screen = screen, frame = frame}
end
function NebulaUI:CreateTab(window, name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 120, 0, 30)
    tabBtn.Text = icon and (icon .. " " .. name) or name
    Theme.StyleButton(tabBtn)
    tabBtn.Parent = window.frame

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -40)
    tabContent.Position = UDim2.new(0, 0, 0, 40)
    tabContent.Visible = false
    Theme.StyleLabel(tabContent)
    tabContent.Parent = window.frame

    local tab = { name = name, button = tabBtn, content = tabContent }
    window.tabs = window.tabs or {}
    table.insert(window.tabs, tab)

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(window.tabs) do
            t.content.Visible = false
        end
        tabContent.Visible = true
    end)

    if #window.tabs == 1 then
        tabContent.Visible = true
    end

    return tab
end
function NebulaUI:CreateButton(tab, config)
    config = config or {}
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 36)
    button.Text = config.Name or "Button"
    Theme.StyleButton(button)
    button.Parent = tab.content

    button.MouseButton1Click:Connect(function()
        Helpers.SafeCallback(config.Callback)
    end)

    return button
end
function NebulaUI:CreateToggle(tab, config)
    config = config or {}
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 36)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = config.Name or "Toggle"
    Theme.StyleLabel(label)
    label.Parent = frame

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0.3, 0, 1, 0)
    switch.Position = UDim2.new(0.7, 0, 0, 0)
    switch.Text = ""
    Theme.StyleButton(switch)
    Helpers.MakeCorner(switch, 10)
    switch.Parent = frame

    local state = config.Default == true

    local function render()
        switch.BackgroundColor3 = state and Theme.Accent or Theme.Button
    end
    render()

    switch.MouseButton1Click:Connect(function()
        state = not state
        render()
        Helpers.SafeCallback(config.Callback, state)
    end)

    return { Get = function() return state end }
end
function NebulaUI:CreateSlider(tab, config)
    config = config or {}
    local min, max = (config.Range and config.Range[1]) or 0, (config.Range and config.Range[2]) or 100
    local value = config.Default or min

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 50)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
    Theme.StyleLabel(label)
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Theme.Button
    Helpers.MakeCorner(bar, 4)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    Helpers.MakeCorner(fill, 4)
    fill.Parent = bar

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local abs = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
            value = math.clamp(math.floor(min + abs * (max - min)), min, max)
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            label.Text = (config.Name or "Slider") .. ": " .. tostring(value)
            Helpers.SafeCallback(config.Callback, value)
        end
    end)

    return { Get = function() return value end }
end
function NebulaUI:CreateDropdown(tab, config)
    config = config or {}
    local options = config.Options or {"Option A", "Option B"}
    local current = config.Default or options[1]

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 200, 0, 36)
    button.Text = (config.Name or "Dropdown") .. ": " .. current
    Theme.StyleButton(button)
    button.Parent = tab.content

    local menuOpen = false
    local menu

    button.MouseButton1Click:Connect(function()
        if menuOpen then
            if menu then menu:Destroy() end
            menuOpen = false
        else
            menuOpen = true
            menu = Instance.new("Frame")
            menu.Size = UDim2.new(0, 200, 0, #options * 28)
            menu.Position = UDim2.new(0, 0, 0, 40)
            menu.BackgroundColor3 = Theme.Panel
            Helpers.MakeCorner(menu, 10)
            menu.Parent = tab.content

            for _, opt in ipairs(options) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 28)
                item.Text = opt
                Theme.StyleButton(item)
                item.Parent = menu

                item.MouseButton1Click:Connect(function()
                    current = opt
                    button.Text = (config.Name or "Dropdown") .. ": " .. current
                    Helpers.SafeCallback(config.Callback, current)
                    menu:Destroy()
                    menuOpen = false
                end)
            end
        end
    end)

    return { Get = function() return current end }
end
function NebulaUI:Notify(config)
    config = config or {}
    local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 250, 0, 60)
    toast.Position = UDim2.new(1, -260, 1, -80)
    toast.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(toast, 10)
    toast.Parent = pg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 20)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.Text = config.Title or "NebulaUI"
    Theme.StyleLabel(title)
    title.Parent = toast

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -10, 0, 20)
    body.Position = UDim2.new(0, 5, 0, 30)
    body.Text = config.Content or "Notification"
    Theme.StyleLabel(body)
    body.Parent = toast

    local duration = config.Duration or 3
    task.delay(duration, function()
        if toast then toast:Destroy() end
    end)
end
NebulaUI._config = {
    Enabled = false,
    FolderName = "NebulaUI",
    FileName = "Config"
}

function NebulaUI:SetConfig(cfg)
    for k, v in pairs(cfg or {}) do
        NebulaUI._config[k] = v
    end
end

function NebulaUI:DestroyWindow(window)
    if window and window.screen then
        window.screen:Destroy()
        print("[NebulaUI] Window destroyed")
    end
end
function Helpers.MakeList(parent, padding)
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.Padding = UDim.new(0, padding or 8)
    list.Parent = parent
    return list
end

function NebulaUI:NotifyAdvanced(config)
    config = config or {}
    local pg = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 280, 0, 70)
    toast.Position = UDim2.new(1, -300, 1, -100)
    toast.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(toast, 10)
    toast.Parent = pg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -10, 0, 20)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.Text = config.Title or "NebulaUI"
    Theme.StyleLabel(title)
    title.Parent = toast

    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -10, 0, 20)
    body.Position = UDim2.new(0, 5, 0, 30)
    body.Text = config.Content or "Notification"
    Theme.StyleLabel(body)
    body.Parent = toast

    if config.Type == "success" then
        toast.BackgroundColor3 = Color3.fromRGB(40, 180, 99)
    elseif config.Type == "error" then
        toast.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    elseif config.Type == "warning" then
        toast.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    end

    local duration = config.Duration or 3
    task.delay(duration, function()
        if toast then toast:Destroy() end
    end)
end
function Theme.ApplyHover(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Theme.Accent
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Theme.Button
    end)
end

function Theme.ApplyClick(button)
    button.MouseButton1Click:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(200,200,200)
        task.delay(0.2, function()
            button.BackgroundColor3 = Theme.Button
        end)
    end)
end
function NebulaUI:CreateInput(tab, config)
    config = config or {}
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 200, 0, 36)
    box.Text = config.Placeholder or "Wpisz tekst..."
    Theme.StyleButton(box)
    box.Parent = tab.content

    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            Helpers.SafeCallback(config.Callback, box.Text)
        end
    end)

    return box
end
function NebulaUI:CreateMultiDropdown(tab, config)
    config = config or {}
    local options = config.Options or {"Option A", "Option B"}
    local selected = {}

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 36)
    button.Text = (config.Name or "MultiDropdown") .. ": 0 selected"
    Theme.StyleButton(button)
    button.Parent = tab.content

    local menuOpen = false
    local menu

    button.MouseButton1Click:Connect(function()
        if menuOpen then
            if menu then menu:Destroy() end
            menuOpen = false
        else
            menuOpen = true
            menu = Instance.new("Frame")
            menu.Size = UDim2.new(0, 220, 0, #options * 28)
            menu.Position = UDim2.new(0, 0, 0, 40)
            menu.BackgroundColor3 = Theme.Panel
            Helpers.MakeCorner(menu, 10)
            menu.Parent = tab.content

            for _, opt in ipairs(options) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, 28)
                item.Text = opt
                Theme.StyleButton(item)
                item.Parent = menu

                item.MouseButton1Click:Connect(function()
                    if table.find(selected, opt) then
                        table.remove(selected, table.find(selected, opt))
                    else
                        table.insert(selected, opt)
                    end
                    button.Text = (config.Name or "MultiDropdown") .. ": " .. tostring(#selected) .. " selected"
                    Helpers.SafeCallback(config.Callback, selected)
                end)
            end
        end
    end)

    return { Get = function() return selected end }
end
function NebulaUI:CreateProgressBar(tab, config)
    config = config or {}
    local value = config.Default or 0

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 30)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(value/100, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    Helpers.MakeCorner(fill, 10)
    fill.Parent = frame

    local function setProgress(v)
        value = math.clamp(v, 0, 100)
        fill.Size = UDim2.new(value/100, 0, 1, 0)
        Helpers.SafeCallback(config.Callback, value)
    end

    return { Set = setProgress, Get = function() return value end }
end
NebulaUI._logs = {}

function NebulaUI:Log(message)
    table.insert(NebulaUI._logs, os.date("%X") .. " | " .. tostring(message))
    print("[NebulaUI] " .. message)
end

function NebulaUI:GetLogs()
    return NebulaUI._logs
end
function NebulaUI:CreateCheckbox(tab, config)
    config = config or {}
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 30)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 8)
    frame.Parent = tab.content

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 24, 0, 24)
    box.Position = UDim2.new(0, 4, 0.5, -12)
    box.Text = ""
    Theme.StyleButton(box)
    Helpers.MakeCorner(box, 6)
    box.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -34, 1, 0)
    label.Position = UDim2.new(0, 34, 0, 0)
    label.Text = config.Name or "Checkbox"
    Theme.StyleLabel(label)
    label.Parent = frame

    local checked = config.Default == true

    local function render()
        box.BackgroundColor3 = checked and Theme.Accent or Theme.Button
    end
    render()

    box.MouseButton1Click:Connect(function()
        checked = not checked
        render()
        Helpers.SafeCallback(config.Callback, checked)
    end)

    return { Get = function() return checked end }
end
function NebulaUI:CreateRadioGroup(tab, config)
    config = config or {}
    local options = config.Options or {"Option A", "Option B"}
    local selected = config.Default or options[1]

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, #options * 30)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    for _, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 28)
        item.Text = opt
        Theme.StyleButton(item)
        item.Parent = frame

        item.MouseButton1Click:Connect(function()
            selected = opt
            Helpers.SafeCallback(config.Callback, selected)
        end)
    end

    return { Get = function() return selected end }
end
NebulaUI._events = {}

function NebulaUI:On(eventName, callback)
    NebulaUI._events[eventName] = NebulaUI._events[eventName] or {}
    table.insert(NebulaUI._events[eventName], callback)
end

function NebulaUI:Emit(eventName, ...)
    if NebulaUI._events[eventName] then
        for _, cb in ipairs(NebulaUI._events[eventName]) do
            Helpers.SafeCallback(cb, ...)
        end
    end
end
function NebulaUI:CreateRangeSlider(tab, config)
    config = config or {}
    local min, max = (config.Range and config.Range[1]) or 0, (config.Range and config.Range[2]) or 100
    local low, high = config.DefaultLow or min, config.DefaultHigh or max

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 60)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = (config.Name or "RangeSlider") .. ": " .. low .. " - " .. high
    Theme.StyleLabel(label)
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Theme.Button
    Helpers.MakeCorner(bar, 4)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((high - low) / (max - min), 0, 1, 0)
    fill.Position = UDim2.new((low - min) / (max - min), 0, 0, 0)
    fill.BackgroundColor3 = Theme.Accent
    Helpers.MakeCorner(fill, 4)
    fill.Parent = bar

    local function update()
        label.Text = (config.Name or "RangeSlider") .. ": " .. low .. " - " .. high
        fill.Size = UDim2.new((high - low) / (max - min), 0, 1, 0)
        fill.Position = UDim2.new((low - min) / (max - min), 0, 0, 0)
        Helpers.SafeCallback(config.Callback, low, high)
    end

    update()
    return { Get = function() return {low, high} end, Set = function(l,h) low, high = l,h update() end }
end
function NebulaUI:CreateIconTab(window, name, icon)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 140, 0, 32)
    tabBtn.Text = (icon or "⭐") .. " " .. name
    Theme.StyleButton(tabBtn)
    tabBtn.Parent = window.frame

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -40)
    tabContent.Position = UDim2.new(0, 0, 0, 40)
    tabContent.Visible = false
    Theme.StyleLabel(tabContent)
    tabContent.Parent = window.frame

    local tab = { name = name, button = tabBtn, content = tabContent }
    window.tabs = window.tabs or {}
    table.insert(window.tabs, tab)

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(window.tabs) do
            t.content.Visible = false
        end
        tabContent.Visible = true
    end)

    if #window.tabs == 1 then
        tabContent.Visible = true
    end

    return tab
end
function NebulaUI:AddTooltip(element, text)
    local tooltip

    element.MouseEnter:Connect(function()
        tooltip = Instance.new("TextLabel")
        tooltip.Size = UDim2.new(0, 150, 0, 24)
        tooltip.Position = UDim2.new(0, element.AbsolutePosition.X, 0, element.AbsolutePosition.Y - 28)
        tooltip.Text = text
        Theme.StyleLabel(tooltip)
        tooltip.BackgroundColor3 = Theme.Panel
        Helpers.MakeCorner(tooltip, 6)
        tooltip.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end)

    element.MouseLeave:Connect(function()
        if tooltip then tooltip:Destroy() end
    end)
end
function NebulaUI:CreateContextMenu(tab, config)
    config = config or {}
    local options = config.Options or {"Opcja A", "Opcja B"}

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 160, 0, #options * 28)
    menu.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(menu, 8)
    menu.Visible = false
    menu.Parent = tab.content

    for _, opt in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, 28)
        item.Text = opt
        Theme.StyleButton(item)
        item.Parent = menu

        item.MouseButton1Click:Connect(function()
            Helpers.SafeCallback(config.Callback, opt)
            menu.Visible = false
        end)
    end

    return {
        Show = function(x, y)
            menu.Position = UDim2.new(0, x, 0, y)
            menu.Visible = true
        end,
        Hide = function()
            menu.Visible = false
        end
    }
end
function NebulaUI:CreateHorizontalTabs(window, names)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 36)
    bar.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(bar, 8)
    bar.Parent = window.frame

    window.htabs = {}

    for _, name in ipairs(names) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.Text = name
        Theme.StyleButton(btn)
        btn.Parent = bar

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 1, -40)
        content.Position = UDim2.new(0, 0, 0, 40)
        content.Visible = false
        Theme.StyleLabel(content)
        content.Parent = window.frame

        local tab = {name=name, button=btn, content=content}
        table.insert(window.htabs, tab)

        btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(window.htabs) do
                t.content.Visible = false
            end
            content.Visible = true
        end)
    end

    if #window.htabs > 0 then
        window.htabs[1].content.Visible = true
    end

    return window.htabs
end
function NebulaUI:CreateLoader(tab, config)
    config = config or {}
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.BackgroundTransparency = 1
    frame.Parent = tab.content

    local spinner = Instance.new("ImageLabel")
    spinner.Size = UDim2.new(1, 0, 1, 0)
    spinner.Image = "rbxassetid://6034986495" 
    spinner.BackgroundTransparency = 1
    spinner.Parent = frame

    local running = true
    task.spawn(function()
        while running do
            spinner.Rotation = spinner.Rotation + 10
            task.wait(0.05)
        end
    end)

    return {
        Stop = function() running = false end,
        Frame = frame
    }
end
function NebulaUI:CreateSubTab(tab, name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 28)
    btn.Text = name
    Theme.StyleButton(btn)
    btn.Parent = tab.content

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -40)
    content.Position = UDim2.new(0, 0, 0, 40)
    content.Visible = false
    Theme.StyleLabel(content)
    content.Parent = tab.content

    local subtab = {name=name, button=btn, content=content}
    tab.subtabs = tab.subtabs or {}
    table.insert(tab.subtabs, subtab)

    btn.MouseButton1Click:Connect(function()
        for _, st in ipairs(tab.subtabs) do
            st.content.Visible = false
        end
        content.Visible = true
    end)

    if #tab.subtabs == 1 then
        content.Visible = true
    end

    return subtab
end
function NebulaUI:CreateColorPicker(tab, config)
    config = config or {}
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 60)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = config.Name or "Color Picker"
    Theme.StyleLabel(label)
    label.Parent = frame

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 40, 0, 40)
    box.Position = UDim2.new(0, 10, 0, 20)
    box.BackgroundColor3 = config.Default or Color3.new(1,1,1)
    Helpers.MakeCorner(box, 8)
    box.Parent = frame

    box.MouseButton1Click:Connect(function()
        local newColor = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        box.BackgroundColor3 = newColor
        Helpers.SafeCallback(config.Callback, newColor)
    end)

    return { Get = function() return box.BackgroundColor3 end }
end
function NebulaUI:CreateAnimatedSlider(tab, config)
    config = config or {}
    local min, max = (config.Range and config.Range[1]) or 0, (config.Range and config.Range[2]) or 100
    local value = config.Default or min

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 50)
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = (config.Name or "AnimatedSlider") .. ": " .. tostring(value)
    Theme.StyleLabel(label)
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0, 10, 0, 30)
    bar.BackgroundColor3 = Theme.Button
    Helpers.MakeCorner(bar, 4)
    bar.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    Helpers.MakeCorner(fill, 4)
    fill.Parent = bar

    local function animateTo(newValue)
        local steps = 20
        local diff = (newValue - value) / steps
        for i=1,steps do
            value = value + diff
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            label.Text = (config.Name or "AnimatedSlider") .. ": " .. tostring(math.floor(value))
            task.wait(0.02)
        end
        Helpers.SafeCallback(config.Callback, math.floor(value))
    end

    return { Set = animateTo, Get = function() return math.floor(value) end }
end
function NebulaUI:AddTab(window, name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 120, 0, 30)
    tabBtn.Text = name
    Theme.StyleButton(tabBtn)
    tabBtn.Parent = window.frame

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -40)
    tabContent.Position = UDim2.new(0, 0, 0, 40)
    tabContent.Visible = false
    Theme.StyleLabel(tabContent)
    tabContent.Parent = window.frame

    local tab = { name = name, button = tabBtn, content = tabContent }
    window.tabs = window.tabs or {}
    table.insert(window.tabs, tab)

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(window.tabs) do
            t.content.Visible = false
        end
        tabContent.Visible = true
    end)

    return tab
end

function NebulaUI:RemoveTab(window, tab)
    if tab and tab.button then tab.button:Destroy() end
    if tab and tab.content then tab.content:Destroy() end
end
function NebulaUI:CreateSettingsPanel(window, config)
    config = config or {}
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 300, 0, 200)
    panel.Position = UDim2.new(0.5, -150, 0.5, -100)
    panel.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(panel, 12)
    panel.Visible = false
    panel.Parent = window.frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = config.Title or "Settings"
    Theme.StyleLabel(title)
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -90, 0, 5)
    closeBtn.Text = "Close"
    Theme.StyleButton(closeBtn)
    closeBtn.Parent = panel

    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    return panel
end
function NebulaUI:CreateScrollableList(tab, config)
    config = config or {}
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(0, 220, 0, 150)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = 6
    frame.BackgroundColor3 = Theme.Panel
    Helpers.MakeCorner(frame, 10)
    frame.Parent = tab.content

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.Parent = frame

    function frame:AddItem(text)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1, -10, 0, 28)
        item.Text = text
        Theme.StyleLabel(item)
        item.Parent = frame
        frame.CanvasSize = UDim2.new(0, 0, 0, frame.CanvasSize.Y.Offset + 34)
    end

    return frame
end
function NebulaUI:CreateDescriptiveTab(window, name, description)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0, 140, 0, 32)
    tabBtn.Text = name
    Theme.StyleButton(tabBtn)
    tabBtn.Parent = window.frame

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -60)
    tabContent.Position = UDim2.new(0, 0, 0, 60)
    tabContent.Visible = false
    Theme.StyleLabel(tabContent)
    tabContent.Parent = window.frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, 0, 0, 28)
    desc.Position = UDim2.new(0, 0, 0, 32)
    desc.Text = description or ""
    Theme.StyleLabel(desc)
    desc.Parent = window.frame

    local tab = { name = name, button = tabBtn, content = tabContent }
    window.tabs = window.tabs or {}
    table.insert(window.tabs, tab)

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(window.tabs) do
            t.content.Visible = false
        end
        tabContent.Visible = true
    end)

    if #window.tabs == 1 then
        tabContent.Visible = true
    end

    return tab
end
