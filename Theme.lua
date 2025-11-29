
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

return Theme
