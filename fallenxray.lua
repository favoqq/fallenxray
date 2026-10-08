-- // Matcha Rust Storage & Objects ESP (UI Freeze Fix)
local WS = game:GetService("Workspace")
local Camera = WS.CurrentCamera

local MAX_RENDER_DIST = 150
local POOL_SIZE = 15

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
        
        espSection:Toggle(toggleId, obj.name, obj.default)
        local r, g, b = obj.color.R, obj.color.G, obj.color.B
        espSection:ColorPicker(colorId, r, g, b, 1, function(c)
            currentColors[obj.id] = c
        end)
    end
    
    espSection:Toggle("esp_text", "Show Name", true)
    espSection:Toggle("esp_dist", "Show Distance", true)
end)

local renderPool = {}
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
    
    renderPool[i] = { Lines = lines, Text = text }
end

local function hideSlot(e)
    if not e then return end
    for _, l in ipairs(e.Lines) do l.Visible = false end
    e.Text.Visible = false
end

local cachedParts = {}

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

task.spawn(function()
    while true do
        task.wait(10)
        local success, err = pcall(function()
            local objMap = {}
            for _, obj in ipairs(ESP_OBJECTS) do
                objMap[obj.name] = obj
            end
            
            local newCache = {}
            for _, obj in ipairs(WS:GetDescendants()) do
                if obj:IsA("Model") or obj:IsA("Folder") then
                    local cfg = objMap[obj.Name]
                    if cfg then
                        local part = getVisualPart(obj)
                        if part and part.Parent then
                            table.insert(newCache, {part = part, cfg = cfg})
                        end
                    end
                end
            end
            cachedParts = newCache
        end)
        if not success then print("Scan error: " .. tostring(err)) end
    end
end)

local edges = { 1, 2,  1, 3,  2, 4,  3, 4, 5, 6,  5, 7,  6, 8,  7, 8, 1, 5,  2, 6,  3, 7,  4, 8 }

-- Кэш UI (читается раз в 3 секунды)
local uiCache = {
    isOn = true,
    showText = true,
    showDist = true,
    enabledTypes = {}
}

local function updateUICache()
    local success, err = pcall(function()
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
    end)
    if not success then print("UI Cache error: " .. tostring(err)) end
end

updateUICache()

task.spawn(function()
    while true do
        task.wait(3) -- Обновляем кэш UI раз в 3 секунды, чтобы не вешать GUI
        pcall(updateUICache)
    end
end)

local validParts = {}
for i = 1, 100 do
    validParts[i] = {part = nil, cfg = nil, dist = 0}
end

local corners2D = {}
for i = 1, 8 do
    corners2D[i] = Vector2.new(0,0)
end

local ptsX, ptsY, ptsZ = {}, {}, {}

task.spawn(function()
    while true do
        task.wait(0.033)
        
        local success, err = pcall(function()
            if not uiCache.isOn then
                for i = 1, POOL_SIZE do hideSlot(renderPool[i]) end
                return
            end

            local camCFrame = Camera.CFrame
            local campos = camCFrame.Position
            local camLook = camCFrame.LookVector
            
            local validCount = 0
            for i = 1, #cachedParts do
                local t = cachedParts[i]
                local root = t.part
                if root and root.Parent and root:IsA("BasePart") then
                    if uiCache.enabledTypes[t.cfg.id] then
                        local pos = root.Position
                        local dist = (pos - campos).Magnitude
                        if dist <= MAX_RENDER_DIST then
                            validCount = validCount + 1
                            if validCount <= 100 then
                                validParts[validCount].part = root
                                validParts[validCount].cfg = t.cfg
                                validParts[validCount].dist = dist
                            end
                        end
                    end
                end
            end
            
            for i = 1, math.min(validCount, POOL_SIZE) do
                for j = 1, math.min(validCount, POOL_SIZE) - i do
                    if validParts[j].dist > validParts[j+1].dist then
                        local temp = validParts[j]
                        validParts[j] = validParts[j+1]
                        validParts[j+1] = temp
                    end
                end
            end
            
            local n = 0
            for i = 1, math.min(validCount, POOL_SIZE) do
                local target = validParts[i]
                local root = target.part
                local dist = target.dist
                
                if dist > 5 then
                    local cf = root.CFrame
                    local size = root.Size
                    local sx, sy, sz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
                    
                    local pos = cf.Position
                    local right = cf.RightVector
                    local up = cf.UpVector
                    local back = cf.LookVector * -1
                    
                    local rX, rY, rZ = right.X * sx, right.Y * sx, right.Z * sx
                    local uX, uY, uZ = up.X * sy, up.Y * sy, up.Z * sy
                    local bX, bY, bZ = back.X * sz, back.Y * sz, back.Z * sz
                    
                    ptsX[1], ptsY[1], ptsZ[1] = pos.X + rX + uX + bX, pos.Y + rY + uY + bY, pos.Z + rZ + uZ + bZ
                    ptsX[2], ptsY[2], ptsZ[2] = pos.X - rX + uX + bX, pos.Y - rY + uY + bY, pos.Z - rZ + uZ + bZ
                    ptsX[3], ptsY[3], ptsZ[3] = pos.X + rX - uX + bX, pos.Y + rY - uY + bY, pos.Z + rZ - uZ + bZ
                    ptsX[4], ptsY[4], ptsZ[4] = pos.X - rX - uX + bX, pos.Y - rY - uY + bY, pos.Z - rZ - uZ + bZ
                    ptsX[5], ptsY[5], ptsZ[5] = pos.X + rX + uX - bX, pos.Y + rY + uY - bY, pos.Z + rZ + uZ - bZ
                    ptsX[6], ptsY[6], ptsZ[6] = pos.X - rX + uX - bX, pos.Y - rY + uY - bY, pos.Z - rZ + uZ - bZ
                    ptsX[7], ptsY[7], ptsZ[7] = pos.X + rX - uX - bX, pos.Y + rY - uY - bY, pos.Z + rZ - uZ - bZ
                    ptsX[8], ptsY[8], ptsZ[8] = pos.X - rX - uX - bX, pos.Y - rY - uY - bY, pos.Z - rZ - uZ - bZ
                    
                    local valid = true
                    for j = 1, 8 do
                        local dx = ptsX[j] - campos.X
                        local dy = ptsY[j] - campos.Y
                        local dz = ptsZ[j] - campos.Z
                        
                        local dot = dx * camLook.X + dy * camLook.Y + dz * camLook.Z
                        
                        if dot > 0 then
                            local sp = WorldToScreen(Vector3.new(ptsX[j], ptsY[j], ptsZ[j]))
                            if sp.X == 0 and sp.Y == 0 then
                                valid = false
                                break
                            end
                            corners2D[j] = Vector2.new(sp.X, sp.Y)
                        else
                            valid = false
                            break
                        end
                    end
                    
                    if valid then
                        n = n + 1
                        local e = renderPool[n]
                        local color = currentColors[target.cfg.id]
                        
                        for j = 1, 12 do
                            local edgeIdx = (j - 1) * 2 + 1
                            local p1 = edges[edgeIdx]
                            local p2 = edges[edgeIdx + 1]
                            local line = e.Lines[j]
                            line.From = corners2D[p1]
                            line.To = corners2D[p2]
                            line.Color = color
                            line.Visible = true
                        end
                        
                        if uiCache.showText then
                            local txt = target.cfg.name
                            if uiCache.showDist then
                                txt = txt .. " [" .. math.floor(dist) .. "m]"
                            end
                            e.Text.Text = txt
                            local topY = math.min(corners2D[1].Y, corners2D[2].Y, corners2D[5].Y, corners2D[6].Y)
                            local centerX = (corners2D[1].X + corners2D[2].X + corners2D[5].X + corners2D[6].X) * 0.25
                            e.Text.Position = Vector2.new(centerX, topY - 15)
                            e.Text.Color = color
                            e.Text.Visible = true
                        else
                            e.Text.Visible = false
                        end
                    end
                end
            end
            
            for i = n + 1, POOL_SIZE do
                hideSlot(renderPool[i])
            end
        end)
        
        if not success then
            print("ESP Error handled: " .. tostring(err))
        end
    end
end)
