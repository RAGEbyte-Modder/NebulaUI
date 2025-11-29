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

function Helpers.MakeList(parent, padding)
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Left
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.Padding = UDim.new(0, padding or 8)
    list.Parent = parent
    return list
end

return Helpers
