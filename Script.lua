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

local AUTHOR = "@Gjfssbn23"
local VERSION = "5.0"

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
        local CoreGui = game:GetService("CoreGui")
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

local AimAssist_Enabled = false
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
local AimSmoothness = 0.1
local SelectedPlayer = nil
local SelectedTrollPlayer = nil
local espHighlights = {}
local fps = 60

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
    for _, item in ipairs(Workspace:GetChildren()) do
        if item:IsA("BasePart") and item.Name == "GunDrop" then
            return item
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

local VisualsTab = Window:Tab({ Title = "💥 Visuals", Icon = "eye" })

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
        end
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if ESP_Enabled then
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local role = GetPlayerRole(p)
                        local color = Color3.fromRGB(0, 255, 0)
                        if role == "Murderer" then color = Color3.fromRGB(255, 0, 0)
                        elseif role == "Sheriff" then color = Color3.fromRGB(0, 0, 255) end
                        local hl = espHighlights[p.Character]
                        if hl and hl.Parent then
                            if hl.FillColor ~= color then hl.FillColor = color end
                        else
                            CreateESPHighlight(p.Character, color)
                        end
                    end
                end
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

local CombatTab = Window:Tab({ Title = "⚔️ Combat", Icon = "swords" })

CombatTab:Toggle({
    Title = "AimAssist Gun (Mobile)",
    Value = false,
    Callback = function(v) AimAssist_Enabled = v end
})

CombatTab:Slider({
    Title = "Smoothness",
    Value = { Min = 0.05, Max = 0.5, Default = 0.1 },
    Step = 0.05,
    Callback = function(v) AimSmoothness = v end
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
            pcall(function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.Transparency = 0
                        end
                    end
                end
            end)
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

local AutoTab = Window:Tab({ Title = "🤖 Automation", Icon = "bot" })

AutoTab:Toggle({
    Title = "Auto Grab Gun",
    Value = false,
    Callback = function(v) AutoGrabGun_Enabled = v end
})

task.spawn(function()
    local lastGrabTime = 0
    while task.wait(0.1) do
        if AutoGrabGun_Enabled then
            pcall(function()
                local gun = GetGun()
                local hrp = GetHRP()
                local hum = GetHum()
                if gun and hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - gun.Position).Magnitude
                    if dist < 150 and (os.clock() - lastGrabTime) > 2 then
                        local murdererClose = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and GetPlayerRole(p) == "Murderer" then
                                local phrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                                if phrp and (phrp.Position - gun.Position).Magnitude < 10 then
                                    murdererClose = true
                                    break
                                end
                            end
                        end
                        if not murdererClose then
                            local oldCFrame = hrp.CFrame
                            hrp.CFrame = gun.CFrame * CFrame.new(0, 3, 0)
                            task.wait(0.05)
                            hrp.CFrame = oldCFrame
                            lastGrabTime = os.clock()
                        end
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
                while not done and SafeFarm_Enabled and (os.clock() - start) < (duration + 1) do task.wait() end
                c:Disconnect()
                if not SafeFarm_Enabled then tween:Cancel() end
                task.wait(0.3)
            end)
        end
    end
end)

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
            if hrp then
                hrp.CFrame = CFrame.new(Vector3.new(0, 50, 0) + Vector3.new(0, 3, 0))
            end
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

local InfoTab = Window:Tab({ Title = "ℹ️ Info", Icon = "info" })

InfoTab:Paragraph({
    Title = "🟨 Kento Hub MM2",
    Desc = "Author: " .. AUTHOR .. "\nVersion: " .. VERSION .. "\n\n© All rights reserved.\nРаспространение без разрешения автора запрещено."
})

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

    if AimAssist_Enabled and HasGun() then
        pcall(function()
            local cam = Workspace.CurrentCamera
            local targetPlayer = nil
            local closestAngle = math.huge
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if hrp and humanoid and humanoid.Health > 0 then
                            local isKnife = character:FindFirstChild("Knife")
                            local bpc = player:FindFirstChild("Backpack")
                            local backpackKnife = bpc and bpc:FindFirstChild("Knife")
                            if isKnife or backpackKnife then
                                local skip = false
                                if WallCheck_Enabled and not CanSeeTarget(hrp.Position) then
                                    skip = true
                                end
                                if not skip then
                                    local targetScreenPos = cam:WorldToScreenPoint(hrp.Position)
                                    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
                                    local screenPos = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                                    local angle = (screenPos - screenCenter).Magnitude
                                    if angle < closestAngle and angle < 300 then
                                        closestAngle = angle
                                        targetPlayer = hrp
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if targetPlayer then
                local targetPos = targetPlayer.Position + Vector3.new(0, 0.8, 0)
                local currentCFrame = cam.CFrame
                local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
                cam.CFrame = currentCFrame:Lerp(newCFrame, AimSmoothness)
            end
        end)
    end
end)

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
    end)
end)

RunService.Stepped:Connect(function()
    if (Noclip_Enabled or SafeFarm_Enabled or Fly_Enabled) and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Hitbox_Enabled then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local isTarget = (HitboxTarget == "All") or (GetPlayerRole(p) == HitboxTarget)
                            if isTarget then
                                hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                                hrp.Transparency = HitboxTransparency
                            else
                                hrp.Size = Vector3.new(2, 2, 1)
                                hrp.Transparency = 0
                            end
                        end
                    end
                end
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    roleCache[p] = nil
    if espHighlights[p.Character] then
        pcall(function() espHighlights[p.Character]:Destroy() end)
        espHighlights[p.Character] = nil
    end
end)

Notify("✅ Kento Hub MM2 v" .. VERSION .. " | " .. AUTHOR, 4)
