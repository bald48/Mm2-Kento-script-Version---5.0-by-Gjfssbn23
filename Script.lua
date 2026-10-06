if _G.KentoHubMM2Loaded then return end
_G.KentoHubMM2Loaded = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local AUTHOR = "@Gjfssbn23"
local VERSION = "6.0"

local function Notify(text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Kento Hub MM2",
            Text = text,
            Duration = dur or 3,
        })
    end)
end

Notify("⏳ Загрузка WindUI...", 3)

local WindUI
local MIRRORS = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua",
}

for _, url in ipairs(MIRRORS) do
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if ok and res then
        WindUI = res
        break
    end
end

if not WindUI then
    Notify("❌ WindUI не загрузился", 6)
    return
end

Notify("✅ WindUI загружен", 2)

pcall(function()
    WindUI:AddTheme({
        Name = "Yellow",
        Accent = Color3.fromHex("#FFD700"),
        Dialog = Color3.fromHex("#1a1400"),
        Outline = Color3.fromHex("#FFD700"),
        Text = Color3.fromHex("#FFFFE0"),
        Placeholder = Color3.fromHex("#FFD700"),
        Background = Color3.fromHex("#2d2400"),
        Button = Color3.fromHex("#DAA520"),
        Icon = Color3.fromHex("#FFD700"),
    })
end)

local Window = WindUI:CreateWindow({
    Title = "🟨 Kento Hub MM2",
    Icon = "sparkles",
    Author = "by: " .. AUTHOR,
    Folder = "KentoHubMM2",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Yellow",
    OutlineColor = Color3.fromHex("#FFD700"),
    OutlineThickness = 2,
})

-- ==================== ЗОЛОТАЯ ОБВОДКА ====================
task.spawn(function()
    task.wait(0.8)
    local GOLD = Color3.fromHex("#FFD700")
    local ORANGE = Color3.fromHex("#FFA500")

    local function PaintStroke(obj)
        pcall(function()
            if obj:IsA("UIStroke") then
                obj.Color = GOLD
                obj.Thickness = math.max(obj.Thickness, 2)
                obj.Transparency = 0
            end
        end)
    end

    local function Walk(gui)
        if not gui then return end
        for _, d in ipairs(gui:GetDescendants()) do
            if d:IsA("UIStroke") then
                PaintStroke(d)
            end
            if d:IsA("ImageLabel") then
                local n = d.Name:lower()
                if n:find("border") or n:find("stroke") or n:find("outline") then
                    pcall(function() d.ImageColor3 = GOLD end)
                end
            end
            local grad = d:FindFirstChildOfClass("UIGradient")
            if grad then
                pcall(function()
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, GOLD),
                        ColorSequenceKeypoint.new(0.5, ORANGE),
                        ColorSequenceKeypoint.new(1, GOLD),
                    })
                end)
            end
        end
    end

    local function ScanAll()
        for _, gui in ipairs(CoreGui:GetChildren()) do
            pcall(function() Walk(gui) end)
        end
        local PG = LocalPlayer:FindFirstChild("PlayerGui")
        if PG then
            for _, gui in ipairs(PG:GetChildren()) do
                pcall(function() Walk(gui) end)
            end
        end
    end

    ScanAll()
    for i = 1, 5 do
        task.wait(1)
        ScanAll()
    end
end)

-- ==================== ПЕРЕМЕННЫЕ ====================
local WallCheck_Enabled = false
local AutoGrabGun_Enabled = false
local ESP_Enabled = false
local Hitbox_Enabled = false
local HitboxSize = 10
local HitboxTransparency = 0.7
local HitboxTarget = "Murderer"
local WalkSpeedValue = 16
local JumpPowerValue = 50
local Noclip_Enabled = false
local InfJump_Enabled = false
local Fly_Enabled = false
local FlySpeed = 60
local Fullbright_Enabled = false
local FOV_Enabled = false
local FOVValue = 70
local AntiAFK_Enabled = false
local SafeFarm_Enabled = false
local SelectedPlayer = nil
local SelectedTrollPlayer = nil
local espHighlights = {}
local hitboxOriginal = {}
local fps = 60

local AutoShoot_Enabled = false
local AutoShoot_FOV = 200
local SoftAim_Enabled = false
local SoftAim_FOV = 100
local SoftAim_Smooth = 0.25
local SoftAim_Head = false

-- ==================== HELPERS ====================
local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local roleCache = {}
local function GetPlayerRole(player)
    if not player then return "Innocent" end
    local cached = roleCache[player]
    if cached and (tick() - cached.time) < 1 then
        return cached.role
    end
    local bp, char = player:FindFirstChild("Backpack"), player.Character
    local role = "Innocent"
    if (bp and bp:FindFirstChild("Knife")) or (char and char:FindFirstChild("Knife")) then
        role = "Murderer"
    elseif (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Gun")) then
        role = "Sheriff"
    end
    roleCache[player] = { role = role, time = tick() }
    return role
end

local function HasGun()
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local char = LocalPlayer.Character
    if bp and bp:FindFirstChild("Gun") then return true end
    if char and char:FindFirstChild("Gun") then return true end
    return false
end

local function GetGun()
    local names = { "GunDrop", "Gun", "GunPickup", "GunModel", "GunSpawn" }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            if table.find(names, obj.Name) then
                return obj
            end
            if obj.Parent and obj.Parent:IsA("Model") then
                local pn = obj.Parent.Name
                if pn == "Gun" or pn == "GunDrop" or pn == "GunPickup" then
                    return obj
                end
            end
        end
    end
    return nil
end

local function CanSeeTarget(targetPos)
    local hrp = GetHRP()
    if not hrp then return false end
    local rayOrigin = hrp.Position
    local rayDirection = (targetPos - rayOrigin)
    local rayDistance = rayDirection.Magnitude
    if rayDistance == 0 then return true end
    local rayParams = RaycastParams.new()
    rayParams:AddToFilter(LocalPlayer.Character)
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local rayResult = Workspace:Raycast(rayOrigin, rayDirection.Unit * (rayDistance + 10), rayParams)
    if not rayResult then return true end
    local hitDistance = (rayResult.Position - rayOrigin).Magnitude
    return hitDistance >= rayDistance * 0.8
end

local function IsRoundActive()
    for _, p in ipairs(Players:GetPlayers()) do
        local r = GetPlayerRole(p)
        if r == "Murderer" or r == "Sheriff" then
            return true
        end
    end
    return false
end

local function FindBestTarget(maxPixels, headMode)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local best, bestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if GetPlayerRole(player) == "Murderer" then
                    local part
                    if headMode then
                        part = char:FindFirstChild("Head")
                    else
                        part = char:FindFirstChild("HumanoidRootPart")
                    end
                    if part then
                        local screenPos, onScreen = cam:WorldToScreenPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                            if dist < maxPixels and dist < bestDist then
                                if not WallCheck_Enabled or CanSeeTarget(part.Position) then
                                    best = part
                                    bestDist = dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function Shoot()
    pcall(function() VirtualUser:Button1Down(Vector2.new(0, 0)) end)
    pcall(function() VirtualUser:Button1Up(Vector2.new(0, 0)) end)
    pcall(function() VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
end

local function RestoreHitbox(char)
    pcall(function()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and hitboxOriginal[part] then
                part.Size = hitboxOriginal[part].size
                part.Transparency = hitboxOriginal[part].trans
                hitboxOriginal[part] = nil
            end
        end
    end)
end

local function ApplyHitbox(char, size, trans)
    pcall(function()
        if not char then return end
        local parts = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
        for _, partName in ipairs(parts) do
            local part = char:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                if not hitboxOriginal[part] then
                    hitboxOriginal[part] = { size = part.Size, trans = part.Transparency }
                end
                part.Size = Vector3.new(size, size, size)
                part.Transparency = trans
            end
        end
    end)
end

-- ==================== MAIN TAB ====================
local MainTab = Window:Tab({ Title = "👤 Main", Icon = "user" })
local InfoPara = MainTab:Paragraph({ Title = "📊 Player Info", Desc = "Loading..." })
local RolesPara = MainTab:Paragraph({ Title = "🎭 Roles", Desc = "Loading..." })

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local hum = GetHum()
            local ping = 0
            pcall(function()
                if Stats and Stats.Network and Stats.Network.ServerStatsItem then
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end
            end)
            pcall(function()
                InfoPara:SetDesc(string.format(
                    "Name: %s\nID: %d\nHealth: %s\nSpeed: %s\nPing: %d ms | FPS: %d\nPlayers: %d/%d",
                    LocalPlayer.Name, LocalPlayer.UserId,
                    hum and math.floor(hum.Health) or "—",
                    hum and math.floor(hum.WalkSpeed) or "—",
                    ping, fps, #Players:GetPlayers(), Players.MaxPlayers
                ))
            end)
            local murd, sher = "—", "—"
            for _, p in ipairs(Players:GetPlayers()) do
                local r = GetPlayerRole(p)
                if r == "Murderer" then murd = p.Name
                elseif r == "Sheriff" then sher = p.Name end
            end
            pcall(function()
                RolesPara:SetDesc("🔪 Murderer: " .. murd .. "\n🔫 Sheriff: " .. sher)
            end)
        end)
    end
end)

MainTab:Toggle({
    Title = "Anti-AFK",
    Value = false,
    Callback = function(v) AntiAFK_Enabled = v end
})

LocalPlayer.Idled:Connect(function()
    if AntiAFK_Enabled then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)

MainTab:Button({
    Title = "Rejoin",
    Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
})

MainTab:Button({
    Title = "Server Hop",
    Callback = function()
        pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            local data = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end)
    end
})

-- ==================== VISUALS ====================
local VisualsTab = Window:Tab({ Title = "💥 Visuals", Icon = "eye" })
local ESPStatus = VisualsTab:Paragraph({ Title = "📊 ESP Status", Desc = "Выключено" })

local function CreateESPHighlight(character, color)
    if not character or espHighlights[character] then return end
    pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "MM2HubESP"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.Parent = character
        espHighlights[character] = hl
    end)
end

VisualsTab:Toggle({
    Title = "ESP / Chams",
    Value = false,
    Callback = function(v)
        ESP_Enabled = v
        if not v then
            for char, hl in pairs(espHighlights) do
                pcall(function() if hl then hl:Destroy() end end)
                espHighlights[char] = nil
            end
            ESPStatus:SetDesc("Выключено")
        end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if ESP_Enabled then
            pcall(function()
                local cnt = 0
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local role = GetPlayerRole(p)
                        local color = Color3.fromRGB(0, 255, 0)
                        if role == "Murderer" then color = Color3.fromRGB(255, 0, 0)
                        elseif role == "Sheriff" then color = Color3.fromRGB(0, 0, 255) end
                        local hl = espHighlights[p.Character]
                        if hl and hl.Parent then
                            if hl.FillColor ~= color then hl.FillColor = color end
                            cnt = cnt + 1
                        else
                            CreateESPHighlight(p.Character, color)
                            cnt = cnt + 1
                        end
                    end
                end
                ESPStatus:SetDesc("✅ Активно: " .. cnt .. " целей")
            end)
        end
    end
end)

local origLight = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
}

VisualsTab:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v)
        Fullbright_Enabled = v
        if not v then
            pcall(function()
                for k, val in pairs(origLight) do Lighting[k] = val end
            end)
        end
    end
})

VisualsTab:Toggle({
    Title = "Custom FOV",
    Value = false,
    Callback = function(v)
        FOV_Enabled = v
        if not v then pcall(function() Workspace.CurrentCamera.FieldOfView = 70 end) end
    end
})

VisualsTab:Slider({
    Title = "FOV",
    Value = { Min = 30, Max = 120, Default = 70 },
    Step = 1,
    Callback = function(v) FOVValue = v end
})

-- ==================== COMBAT ====================
local CombatTab = Window:Tab({ Title = "⚔️ Combat", Icon = "swords" })

CombatTab:Paragraph({
    Title = "🎯 Аимы",
    Desc = "Можно включать оба сразу"
})

CombatTab:Toggle({
    Title = "🎯 Auto-Shoot",
    Value = false,
    Callback = function(v) AutoShoot_Enabled = v end
})

CombatTab:Slider({
    Title = "Auto-Shoot FOV (px)",
    Value = { Min = 30, Max = 500, Default = 200 },
    Step = 10,
    Callback = function(v) AutoShoot_FOV = v end
})

CombatTab:Toggle({
    Title = "🎯 Soft Aim (плавно)",
    Value = false,
    Callback = function(v) SoftAim_Enabled = v end
})

CombatTab:Slider({
    Title = "Soft Aim FOV (px)",
    Value = { Min = 20, Max = 250, Default = 100 },
    Step = 5,
    Callback = function(v) SoftAim_FOV = v end
})

CombatTab:Slider({
    Title = "Soft Aim Smoothness",
    Value = { Min = 0.05, Max = 0.5, Default = 0.25 },
    Step = 0.05,
    Callback = function(v) SoftAim_Smooth = v end
})

CombatTab:Toggle({
    Title = "Soft Aim — в голову",
    Value = false,
    Callback = function(v) SoftAim_Head = v end
})

CombatTab:Toggle({
    Title = "Wall Check",
    Value = false,
    Callback = function(v) WallCheck_Enabled = v end
})

CombatTab:Toggle({
    Title = "Hitbox",
    Value = false,
    Callback = function(v)
        Hitbox_Enabled = v
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then RestoreHitbox(p.Character) end
            end
        end
    end
})

CombatTab:Slider({
    Title = "Hitbox Size",
    Value = { Min = 2, Max = 50, Default = 10 },
    Step = 0.5,
    Callback = function(v) HitboxSize = v end
})

CombatTab:Slider({
    Title = "Hitbox Transparency",
    Value = { Min = 0, Max = 1, Default = 0.7 },
    Step = 0.1,
    Callback = function(v) HitboxTransparency = v end
})

CombatTab:Dropdown({
    Title = "Hitbox Target",
    Values = { "Murderer", "Sheriff", "All" },
    Value = "Murderer",
    Callback = function(option) HitboxTarget = option end
})

local HitboxStatus = CombatTab:Paragraph({ Title = "📊 Hitbox Status", Desc = "Выключено" })
local AimStatus = CombatTab:Paragraph({ Title = "📊 Aim Status", Desc = "Выключено" })
local AimTarget = CombatTab:Paragraph({ Title = "🎯 Цель", Desc = "—" })
local AimDiag = CombatTab:Paragraph({ Title = "🔧 Диагностика", Desc = "Жду..." })

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local parts = {}
            if AutoShoot_Enabled then table.insert(parts, "Auto-Shoot") end
            if SoftAim_Enabled then table.insert(parts, "Soft Aim") end
            local text = #parts > 0 and table.concat(parts, " + ") or "Выключено"
            AimStatus:SetDesc("🎯 " .. text)

            if AutoShoot_Enabled or SoftAim_Enabled then
                local tgt = FindBestTarget(AutoShoot_Enabled and AutoShoot_FOV or SoftAim_FOV, SoftAim_Head)
                if tgt then
                    local nm = "?"
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl.Character and tgt:IsDescendantOf(pl.Character) then
                            nm = pl.Name
                            break
                        end
                    end
                    AimTarget:SetDesc("✅ Вижу: " .. nm)
                    local c = Workspace.CurrentCamera
                    local sp = c:WorldToScreenPoint(tgt.Position)
                    local center = Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2)
                    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    AimDiag:SetDesc(string.format("✅ Цель в %d px от центра", math.floor(dist)))
                else
                    AimTarget:SetDesc("❌ Убийца не в прицеле")
                    local has = false
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl ~= LocalPlayer and GetPlayerRole(pl) == "Murderer" then
                            has = true
                            break
                        end
                    end
                    if not has then
                        AimDiag:SetDesc("⚠️ Убийцы нет в раунде")
                    else
                        AimDiag:SetDesc("⚠️ Убийца вне радиуса FOV")
                    end
                end
            else
                AimTarget:SetDesc("—")
                AimDiag:SetDesc("Жду включения")
            end
        end)
    end
end)

task.spawn(function()
    local lastShot = 0
    while task.wait(0.05) do
        if AutoShoot_Enabled then
            pcall(function()
                if not HasGun() then return end
                local target = FindBestTarget(AutoShoot_FOV, false)
                if target and (tick() - lastShot) > 0.1 then
                    Shoot()
                    lastShot = tick()
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if Hitbox_Enabled then
                local cnt = 0
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local isTarget = (HitboxTarget == "All") or (GetPlayerRole(p) == HitboxTarget)
                        if isTarget then
                            ApplyHitbox(p.Character, HitboxSize, HitboxTransparency)
                            cnt = cnt + 1
                        else
                            RestoreHitbox(p.Character)
                        end
                    end
                end
                HitboxStatus:SetDesc("✅ Активно: " .. cnt .. " целей")
            else
                HitboxStatus:SetDesc("Выключено")
            end
        end)
    end
end)

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        pl.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if Hitbox_Enabled and char and char.Parent then
                if (HitboxTarget == "All") or (GetPlayerRole(pl) == HitboxTarget) then
                    ApplyHitbox(char, HitboxSize, HitboxTransparency)
                end
            end
        end)
    end
end

Players.PlayerAdded:Connect(function(pl)
    pl.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if Hitbox_Enabled and char and char.Parent then
            if (HitboxTarget == "All") or (GetPlayerRole(pl) == HitboxTarget) then
                ApplyHitbox(char, HitboxSize, HitboxTransparency)
            end
        end
    end)
end)

-- ==================== AUTOMATION ====================
local AutoTab = Window:Tab({ Title = "🤖 Automation", Icon = "bot" })
local AutoGunStatus = AutoTab:Paragraph({ Title = "📊 Auto Gun", Desc = "Выключено" })

AutoTab:Toggle({
    Title = "Auto Grab Gun",
    Value = false,
    Callback = function(v) AutoGrabGun_Enabled = v end
})

task.spawn(function()
    local lastGrabTime = 0
    while task.wait(0.5) do
        if AutoGrabGun_Enabled then
            pcall(function()
                if HasGun() then
                    AutoGunStatus:SetDesc("✅ Пушка уже в руках")
                    return
                end
                local gun = GetGun()
                local hrp = GetHRP()
                local hum = GetHum()
                if not gun then
                    AutoGunStatus:SetDesc("❌ Пушка не найдена на карте")
                    return
                end
                if not hrp or not hum or hum.Health <= 0 then
                    AutoGunStatus:SetDesc("⚠️ Персонаж мёртв")
                    return
                end
                local dist = (hrp.Position - gun.Position).Magnitude
                AutoGunStatus:SetDesc(string.format("🎯 Дистанция: %d", math.floor(dist)))

                if dist < 250 and (os.clock() - lastGrabTime) > 1.5 then
                    local murdererClose = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and GetPlayerRole(p) == "Murderer" then
                            local phrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                            if phrp and (phrp.Position - gun.Position).Magnitude < 12 then
                                murdererClose = true
                                break
                            end
                        end
                    end
                    if murdererClose then
                        AutoGunStatus:SetDesc("⚠️ Убийца рядом — не рискую")
                    else
                        local oldCFrame = hrp.CFrame
                        local oldCollide = {}
                        for _, pt in ipairs(LocalPlayer.Character:GetDescendants()) do
                            if pt:IsA("BasePart") then
                                oldCollide[pt] = pt.CanCollide
                                pt.CanCollide = false
                            end
                        end
                        hrp.CFrame = gun.CFrame * CFrame.new(0, 2, 0)
                        task.wait(0.1)
                        hrp.CFrame = oldCFrame
                        for pt, val in pairs(oldCollide) do
                            pcall(function() pt.CanCollide = val end)
                        end
                        lastGrabTime = os.clock()
                        AutoGunStatus:SetDesc("✅ Забрал пушку!")
                    end
                end
            end)
        end
    end
end)

AutoTab:Toggle({
    Title = "Safe Farm Coins",
    Value = false,
    Callback = function(v) SafeFarm_Enabled = v end
})

local visited = {}
task.spawn(function()
    while task.wait(0.3) do
        if SafeFarm_Enabled then
            pcall(function()
                if not IsRoundActive() then return end
                local hrp, hum = GetHRP(), GetHum()
                if not hrp or not hrp.Parent or not hum or hum.Health <= 0 then return end

                local container = nil
                for _, v in ipairs(Workspace:GetChildren()) do
                    local c = v:FindFirstChild("CoinContainer")
                    if c then container = c; break end
                end
                if not container then return end

                local best, bestDist
                for _, coin in ipairs(container:GetChildren()) do
                    if coin:IsA("BasePart") and coin.Parent then
                        local t = visited[coin]
                        if not t or (os.clock() - t) > 8 then
                            local d = (hrp.Position - coin.Position).Magnitude
                            if not bestDist or d < bestDist then
                                best, bestDist = coin, d
                            end
                        end
                    end
                end
                if not best then return end

                visited[best] = os.clock()
                local duration = math.max(bestDist / 25, 0.1)
                local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = best.CFrame})
                tween:Play()
                local done = false
                local c = tween.Completed:Connect(function() done = true end)
                local start = os.clock()
                while not done and SafeFarm_Enabled and (os.clock() - start) < (duration + 1) do
                    task.wait(0.05)
                end
                c:Disconnect()
                if not SafeFarm_Enabled then tween:Cancel() end
                task.wait(0.3)
            end)
        end
    end
end)

-- ==================== MOVEMENT ====================
local MoveTab = Window:Tab({ Title = "🏃 Movement", Icon = "zap" })

MoveTab:Slider({
    Title = "WalkSpeed",
    Value = { Min = 16, Max = 100, Default = 16 },
    Step = 1,
    Callback = function(v) WalkSpeedValue = v end
})

MoveTab:Slider({
    Title = "JumpPower",
    Value = { Min = 50, Max = 200, Default = 50 },
    Step = 1,
    Callback = function(v) JumpPowerValue = v end
})

MoveTab:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(v) Noclip_Enabled = v end
})

MoveTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v) InfJump_Enabled = v end
})

UserInputService.JumpRequest:Connect(function()
    if InfJump_Enabled then
        pcall(function()
            local hum = GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)

local flyBV
local function StopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    pcall(function()
        local hum = GetHum()
        if hum then hum.PlatformStand = false end
    end)
end

MoveTab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(v)
        Fly_Enabled = v
        if not v then StopFly() end
    end
})

MoveTab:Slider({
    Title = "Fly Speed",
    Value = { Min = 20, Max = 200, Default = 60 },
    Step = 5,
    Callback = function(v) FlySpeed = v end
})

-- ==================== TELEPORT ====================
local TpTab = Window:Tab({ Title = "📍 Teleport", Icon = "map-pin" })

local function PlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then names = { "—" } end
    return names
end

local function GetFirstPlayerName()
    local names = PlayerNames()
    return names[1] or "—"
end

local PlayerDropdown = TpTab:Dropdown({
    Title = "Select Player",
    Values = PlayerNames(),
    Value = GetFirstPlayerName(),
    Callback = function(option)
        if option ~= "—" then
            SelectedPlayer = Players:FindFirstChild(option)
        else
            SelectedPlayer = nil
        end
    end
})

TpTab:Button({
    Title = "Refresh Players",
    Callback = function()
        pcall(function()
            if PlayerDropdown then
                if PlayerDropdown.Refresh then
                    PlayerDropdown:Refresh(PlayerNames())
                elseif PlayerDropdown.SetValues then
                    PlayerDropdown:SetValues(PlayerNames())
                end
            end
        end)
    end
})

TpTab:Button({
    Title = "TP to Player",
    Callback = function()
        pcall(function()
            local target = SelectedPlayer
            if not target or not target.Parent then return end
            local hrp = GetHRP()
            local thrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if hrp and thrp then
                hrp.CFrame = thrp.CFrame * CFrame.new(0, 0, 3)
            end
        end)
    end
})

TpTab:Toggle({
    Title = "Spectate",
    Value = false,
    Callback = function(v)
        pcall(function()
            local cam = Workspace.CurrentCamera
            if v then
                if SelectedPlayer and SelectedPlayer.Parent then
                    local thum = SelectedPlayer.Character and SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if thum then cam.CameraSubject = thum end
                end
            else
                cam.CameraSubject = GetHum()
            end
        end)
    end
})

TpTab:Button({
    Title = "TP to Lobby",
    Callback = function()
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end
            local lobbyPos = nil
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") and obj.Parent then
                    lobbyPos = obj.Position + Vector3.new(0, 3, 0)
                    break
                end
            end
            if not lobbyPos then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local n = obj.Name:lower()
                        if n:find("lobby") or n:find("waiting") or n:find("spawn") then
                            lobbyPos = obj.Position + Vector3.new(0, 3, 0)
                            break
                        end
                    end
                end
            end
            if not lobbyPos then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if phrp then
                            lobbyPos = phrp.Position + Vector3.new(0, 3, 5)
                            break
                        end
                    end
                end
            end
            if not lobbyPos then lobbyPos = Vector3.new(0, 100, 0) end
            hrp.CFrame = CFrame.new(lobbyPos)
        end)
    end
})

TpTab:Button({
    Title = "TP to Map",
    Callback = function()
        pcall(function()
            local hrp = GetHRP()
            if not hrp then return end
            local spawnPos = Vector3.new(0, 50, 0)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local phrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if phrp then spawnPos = phrp.Position; break end
                end
            end
            hrp.CFrame = CFrame.new(spawnPos + Vector3.new(0, 5, 0))
        end)
    end
})

-- ==================== TROLLING ====================
local TrollTab = Window:Tab({ Title = "😈 Trolling", Icon = "zap" })

TrollTab:Paragraph({
    Title = "⚠️ Visible to All",
    Desc = "These functions affect all players"
})

local function SpinPlayer(player)
    pcall(function()
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for i = 1, 5 do
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(72), 0)
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function LaunchPlayer(player)
    pcall(function()
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.new(math.random(-50, 50), 100, math.random(-50, 50))
            end
        end
    end)
end

local function ExplodePlayer(player)
    pcall(function()
        if player and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and part ~= player.Character:FindFirstChild("HumanoidRootPart") then
                    part.AssemblyLinearVelocity = Vector3.new(
                        math.random(-100, 100),
                        math.random(-50, 100),
                        math.random(-100, 100)
                    )
                end
            end
        end
    end)
end

local function DancePlayer(player)
    pcall(function()
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for i = 1, 10 do
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(45), 0, 0)
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function TrollPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    if #names == 0 then names = { "—" } end
    return names
end

local function GetFirstTrollPlayerName()
    local names = TrollPlayerNames()
    return names[1] or "—"
end

local TrollPlayerDropdown = TrollTab:Dropdown({
    Title = "Select Player",
    Values = TrollPlayerNames(),
    Value = GetFirstTrollPlayerName(),
    Callback = function(option)
        if option ~= "—" then
            SelectedTrollPlayer = Players:FindFirstChild(option)
        else
            SelectedTrollPlayer = nil
        end
    end
})

TrollTab:Button({
    Title = "Refresh Players",
    Callback = function()
        pcall(function()
            if TrollPlayerDropdown then
                if TrollPlayerDropdown.Refresh then
                    TrollPlayerDropdown:Refresh(TrollPlayerNames())
                elseif TrollPlayerDropdown.SetValues then
                    TrollPlayerDropdown:SetValues(TrollPlayerNames())
                end
            end
        end)
    end
})

TrollTab:Button({
    Title = "🌀 Spin Player",
    Callback = function() if SelectedTrollPlayer then SpinPlayer(SelectedTrollPlayer) end end
})

TrollTab:Button({
    Title = "🚀 Launch Player",
    Callback = function() if SelectedTrollPlayer then LaunchPlayer(SelectedTrollPlayer) end end
})

TrollTab:Button({
    Title = "💥 Explode Player",
    Callback = function() if SelectedTrollPlayer then ExplodePlayer(SelectedTrollPlayer) end end
})

TrollTab:Button({
    Title = "🕺 Dance Player",
    Callback = function() if SelectedTrollPlayer then DancePlayer(SelectedTrollPlayer) end end
})

TrollTab:Button({
    Title = "⚡ Launch All",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then LaunchPlayer(p) end
        end
    end
})

TrollTab:Button({
    Title = "🌪️ Spin All",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                task.spawn(function() SpinPlayer(p) end)
            end
        end
    end
})

-- ==================== MISC ====================
local MiscTab = Window:Tab({ Title = "🔧 Misc", Icon = "settings" })

MiscTab:Button({
    Title = "Lower Graphics",
    Callback = function()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.Brightness = 1
            local count = 0
            for _, v in ipairs(Workspace:GetChildren()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    count = count + 1
                elseif v:IsA("Model") then
                    for _, p in ipairs(v:GetChildren()) do
                        if p:IsA("BasePart") then
                            p.Material = Enum.Material.SmoothPlastic
                            count = count + 1
                        end
                    end
                end
                if count > 2000 then break end
            end
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        end)
    end
})

MiscTab:Button({
    Title = "Reset Character",
    Callback = function()
        pcall(function()
            local hum = GetHum()
            if hum then hum.Health = 0 end
        end)
    end
})

-- ==================== INFO ====================
local InfoTab = Window:Tab({ Title = "ℹ️ Info", Icon = "info" })

InfoTab:Paragraph({
    Title = "🟨 Kento Hub MM2",
    Desc = "Author: " .. AUTHOR .. "\nVersion: " .. VERSION .. "\n\n© All rights reserved."
})

-- ==================== RENDER LOOP ====================
RunService.RenderStepped:Connect(function(dt)
    fps = math.floor(1 / math.max(dt, 0.001))

    if Fullbright_Enabled then
        pcall(function()
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 1e6
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        end)
    end

    if FOV_Enabled then
        pcall(function() Workspace.CurrentCamera.FieldOfView = FOVValue end)
    end

    if SoftAim_Enabled and HasGun() then
        pcall(function()
            local cam = Workspace.CurrentCamera
            local target = FindBestTarget(SoftAim_FOV, SoftAim_Head)
            if target then
                local currentCFrame = cam.CFrame
                local newCFrame = CFrame.new(currentCFrame.Position, target.Position)
                cam.CFrame = currentCFrame:Lerp(newCFrame, SoftAim_Smooth)
            end
        end)
    end
end)

-- ==================== HEARTBEAT ====================
RunService.Heartbeat:Connect(function()
    pcall(function()
        local hum, hrp = GetHum(), GetHRP()
        if not (hum and hrp) then return end

        if WalkSpeedValue ~= 16 then hum.WalkSpeed = WalkSpeedValue end
        if JumpPowerValue ~= 50 then
            hum.UseJumpPower = true
            hum.JumpPower = JumpPowerValue
        end

        if Fly_Enabled then
            if not flyBV or not flyBV.Parent then
                flyBV = Instance.new("BodyVelocity")
                flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBV.Velocity = Vector3.zero
                flyBV.Parent = hrp
            end
            hum.PlatformStand = true
            local cam = Workspace.CurrentCamera
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                local look = cam.CFrame.LookVector
                local flat = Vector3.new(look.X, 0, look.Z)
                if flat.Magnitude > 0 then
                    local forward = moveDir:Dot(flat.Unit)
                    local verticalComponent = Vector3.new(0, look.Y * forward * FlySpeed, 0)
                    flyBV.Velocity = moveDir * FlySpeed + verticalComponent
                else
                    flyBV.Velocity = moveDir * FlySpeed
                end
            else
                flyBV.Velocity = Vector3.zero
            end
        end

        if Noclip_Enabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
end)

-- ==================== CLEANUP ====================
Players.PlayerRemoving:Connect(function(p)
    roleCache[p] = nil
    if espHighlights[p.Character] then
        pcall(function() espHighlights[p.Character]:Destroy() end)
        espHighlights[p.Character] = nil
    end
    if p.Character then RestoreHitbox(p.Character) end
end)

Notify("✅ Kento Hub MM2 v" .. VERSION .. " | " .. AUTHOR, 4)
