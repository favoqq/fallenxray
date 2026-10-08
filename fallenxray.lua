-- // Matcha Rust Storage & Objects ESP (Doors Disabled by Default)
local WS = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = WS.CurrentCamera

local MAX_RENDER_DIST = 150

local ESP_OBJECTS = {
    {id = "Cabinet", name = "Base Cabinet", color = Color3.fromRGB(166, 144, 130), default = true},
    {id = "StorageCabinet", name = "Storage Cabinet", color = Color3.fromRGB(44, 65, 128), default = true},
    {id = "Small", name = "Small Storage Box", color = Color3.fromRGB(148, 136, 127), default = true},
    {id = "Large", name = "Large Storage Box", color = Color3.fromRGB(104, 91, 81), default = true},
    {id = "WoodenDoor", name = "Wooden Door", color = Color3.fromRGB(139, 69, 19), default = false},
    {id = "WoodenDouble", name = "Wooden Double Door", color = Color3.fromRGB(160, 82, 45), default = false},
    {id = "MetalDoor", name = "Metal Door", color = Color3.fromRGB(100, 149, 237), default = false},
    {id = "MetalDouble", name = "Metal Double Door", color = Color3.fromRGB(70, 130, 180), default = false},
    {id = "SteelDoor", name = "Steel Door", color = Color3.fromRGB(192, 192, 192), default = false},
    {id = "SteelDouble", name = "Steel Double Door", color = Color3.fromRGB(169, 169, 169), default = false},
    {id = "GarageDoor", name = "Garage Door", color = Color3.fromRGB(128, 38, 38), default = false},
    {id = "SalvagedMetalDoor", name = "Salvaged Metal Door", color = Color3.fromRGB(101, 67, 33), default = false},
    {id = "ShotgunTurret", name = "Shotgun Turret", color = Color3.fromRGB(255, 255, 0), default = true},
    {id = "AutoTurret", name = "Auto Turret", color = Color3.fromRGB(255, 105, 180), default = true},
    {id = "LargeBattery", name = "Large Battery", color = Color3.fromRGB(255, 165, 0), default = true},
    {id = "MediumBattery", name = "Medium Battery", color = Color3.fromRGB(0, 191, 255), default = true},
    {id = "Bed", name = "Bed", color = Color3.fromRGB(255, 255, 255), default = true}
}

local currentColors = {}
for _, obj in ipairs(ESP_OBJECTS) do
    currentColors[obj.id] = obj.color
end

UI.AddTab("Storage & Objects ESP", function(tab)
    local espSection = tab:Section("ESP Settings", "Left")
    espSection:Toggle("esp_on", "Enabled", true)
    
    for _, obj in ipairs(ESP_OBJECTS) do
        local toggleId = "esp_" .. obj.id
        local colorId = "esp_" .. obj.id .. "_col"
        
        -- Передаем default значение в UI
        espSection:Toggle(toggleId, obj.name, obj.default)
        local r, g, b = obj.color.R, obj.color.G, obj.color.B
        espSection:ColorPicker(colorId, r, g, b, 1, function(c)
            currentColors[obj.id] = c
        end)
    end
    
    espSection:Toggle("esp_text", "Show Name", true)
    espSection:Toggle("esp_dist", "Show Distance", true)
end)

local POOL_SIZE = 10
local pools = {}

for _, obj in ipairs(ESP_OBJECTS) do
    pools[obj.id] = {}
    for i = 1, POOL_SIZE do
        local lines = {}
        for j = 1, 12 do
            local l = Drawing.new("Line")
            l.Thickness = 1.5
            l.Visible = false
            table.insert(lines, l)
        end
        local text = Drawing.new("Text")
        text.Size = 14
        text.Font = 2
        text.Center = true
        text.Outline = true
        text.Visible = false
        
        pools[obj.id][i] = { Lines = lines, Text = text }
    end
end

local function hideSlot(e)
    if not e then return end
    for _, l in ipairs(e.Lines) do l.Visible = false end
    e.Text.Visible = false
end

local cachedBoxes = {}
for _, obj in ipairs(ESP_OBJECTS) do
    cachedBoxes[obj.id] = {}
end

local function getVisualPart(obj)
    local bestPart = nil
    local maxVol = 0
    
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("BasePart") and child.Position and child.Size then
            local nameLower = string.lower(child.Name)
            if not string.find(nameLower, "collision") and not string.find(nameLower, "hitbox") and not string.find(nameLower, "trigger") then
                local s = child.Size
                local v = s.X * s.Y * s.Z
                if v > maxVol then
                    maxVol = v
                    bestPart = child
                end
            end
        end
    end
    
    if not bestPart then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("BasePart") then return child end
        end
    end
    return bestPart
end

local isScanning = false
local function scanBoxes()
    if isScanning then return end
    isScanning = true
    
    local newCache = {}
    for _, obj in ipairs(ESP_OBJECTS) do
        newCache[obj.id] = {}
    end
    
    local objMap = {}
    for _, espObj in ipairs(ESP_OBJECTS) do
        objMap[espObj.name] = espObj
    end
    
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local cfg = objMap[obj.Name]
            if cfg then
                local part = getVisualPart(obj)
                if part and part.Parent then
                    table.insert(newCache[cfg.id], part)
                end
            end
        end
    end
    cachedBoxes = newCache
    isScanning = false
end

scanBoxes()
notify("Objects ESP scanned!", "Matcha", 3)

task.spawn(function()
    while true do
        task.wait(5)
        pcall(scanBoxes)
    end
end)

local edges = {
    {1, 2}, {1, 3}, {2, 4}, {3, 4}, 
    {5, 6}, {5, 7}, {6, 8}, {7, 8}, 
    {1, 5}, {2, 6}, {3, 7}, {4, 8}  
}

local size_offsets = {
    Vector3.new(0.5, 0.5, 0.5), Vector3.new(-0.5, 0.5, 0.5),
    Vector3.new(0.5, -0.5, 0.5), Vector3.new(-0.5, -0.5, 0.5),
    Vector3.new(0.5, 0.5, -0.5), Vector3.new(-0.5, 0.5, -0.5),
    Vector3.new(0.5, -0.5, -0.5), Vector3.new(-0.5, -0.5, -0.5)
}

local uiCache = {
    isOn = true,
    showText = true,
    showDist = true,
    enabledTypes = {}
}

local function updateUICache()
    uiCache.isOn = UI.GetValue("esp_on") == true or UI.GetValue("esp_on") == nil
    uiCache.showText = UI.GetValue("esp_text") == true or UI.GetValue("esp_text") == nil
    uiCache.showDist = UI.GetValue("esp_dist") == true or UI.GetValue("esp_dist") == nil
    
    for _, obj in ipairs(ESP_OBJECTS) do
        local tid = "esp_" .. obj.id
        local val = UI.GetValue(tid)
        if val == nil then
            uiCache.enabledTypes[obj.id] = obj.default
        else
            uiCache.enabledTypes[obj.id] = val
        end
    end
end

updateUICache()

task.spawn(function()
    while true do
        task.wait(2)
        pcall(updateUICache)
    end
end)

local visibleTargets = {}
local pts = {}

local function processPool(pool, targets, name, color, showBox, showText, showDist, n, campos, camLook)
    table.clear(visibleTargets)
    
    for i = 1, #targets do
        local root = targets[i]
        if root and root.Parent and root:IsA("BasePart") then
            local dist = (root.Position - campos).Magnitude
            if dist > 5 and dist <= MAX_RENDER_DIST then
                table.insert(visibleTargets, {part = root, dist = dist})
            end
        end
    end
    
    table.sort(visibleTargets, function(a, b) return a.dist < b.dist end)
    
    for i = 1, math.min(#visibleTargets, POOL_SIZE) do
        if n >= POOL_SIZE then break end
        local root = visibleTargets[i].part
        local dist = visibleTargets[i].dist
        
        local cf = root.CFrame
        local size = root.Size
        local sx, sy, sz = size.X, size.Y, size.Z
        
        table.clear(pts)
        local valid = true
        
        for j = 1, 8 do
            local off = size_offsets[j]
            local worldPos = cf * Vector3.new(off.X * sx, off.Y * sy, off.Z * sz)
            
            local dirToCorner = (worldPos - campos)
            if dirToCorner:Dot(camLook) > 0 then
                local sp = WorldToScreen(worldPos)
                if sp.X == 0 and sp.Y == 0 then
                    valid = false
                    break
                end
                pts[j] = Vector2.new(sp.X, sp.Y)
            else
                valid = false
                break
            end
        end
        
        if valid then
            n = n + 1
            local e = pool[n]
            
            if showBox then
                for j = 1, 12 do
                    local edge = edges[j]
                    local line = e.Lines[j]
                    line.From = pts[edge[1]]
                    line.To = pts[edge[2]]
                    line.Color = color
                    line.Visible = true
                end
            else
                for _, l in ipairs(e.Lines) do l.Visible = false end
            end
            
            if showText then
                local txt = name
                if showDist then
                    txt = txt .. " [" .. math.floor(dist) .. "m]"
                end
                e.Text.Text = txt
                local topY = math.min(pts[1].Y, pts[2].Y, pts[5].Y, pts[6].Y)
                local centerX = (pts[1].X + pts[2].X + pts[5].X + pts[6].X) / 4
                e.Text.Position = Vector2.new(centerX, topY - 15)
                e.Text.Color = color
                e.Text.Visible = true
            else
                e.Text.Visible = false
            end
        end
    end
    return n
end

RunService.RenderStepped:Connect(function()
    local success, err = pcall(function()
        if not uiCache.isOn then
            for _, pool in pairs(pools) do
                for i = 1, POOL_SIZE do hideSlot(pool[i]) end
            end
            return
        end

        local camCFrame = Camera.CFrame
        local campos = camCFrame.Position
        local camLook = camCFrame.LookVector
        
        for _, espObj in ipairs(ESP_OBJECTS) do
            local showType = uiCache.enabledTypes[espObj.id]
            local n = 0
            
            if showType then
                n = processPool(
                    pools[espObj.id],
                    cachedBoxes[espObj.id],
                    espObj.name,
                    currentColors[espObj.id],
                    showType, uiCache.showText, uiCache.showDist,
                    0, campos, camLook
                )
            end
            
            for i = n + 1, POOL_SIZE do
                hideSlot(pools[espObj.id][i])
            end
        end
    end)
    
    if not success then
        print("ESP Error handled: " .. tostring(err))
    end
end)