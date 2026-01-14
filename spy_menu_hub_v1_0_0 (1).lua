--[[
    ╔══════════════════════════════════════════════════════════╗
    ║           SPY MENU HUB - UNIVERSAL EDITION               ║
    ║              Créé par : tomitom66800                     ║
    ║                                                          ║
    ║  Touche INSERT pour ouvrir/fermer le menu               ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Variables globales
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- États du menu
local SpyMenu = {
    GUI = nil,
    IsOpen = false,
    CurrentTab = "Players",
    SpectatingPlayer = nil,
    TrackingPlayer = nil,
    TrackingConnection = nil,
    OriginalCameraSubject = Camera.CameraSubject,
    OriginalPosition = nil,
    SpyWindows = {},
    ChatConnections = {},
    SearchTerm = "",
    FilterMode = "All", -- "All", "Friends"
    ActiveToggles = {}, -- Pour suivre l'état des boutons toggle
    WatchedPlayers = {}, -- Joueurs surveillés
    DebugMode = false -- Mode debug désactivé
}

-- Configuration des couleurs (thème moderne noir/rouge)
local Colors = {
    Background = Color3.fromRGB(15, 15, 15),
    Secondary = Color3.fromRGB(25, 25, 25),
    Tertiary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(220, 38, 38),
    AccentHover = Color3.fromRGB(255, 60, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(160, 160, 160),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(251, 146, 60),
    Border = Color3.fromRGB(45, 45, 45),
    Online = Color3.fromRGB(34, 197, 94),
    Offline = Color3.fromRGB(239, 68, 68)
}

-- ═══════════════════════════════════════════════════════════
--                    UTILITAIRES
-- ═══════════════════════════════════════════════════════════

-- Message de bienvenue
local function ShowWelcomeMessage()
    print("╔══════════════════════════════════════════════════════════╗")
    print("║                                                          ║")
    print("║       Bienvenue dans le SPY Launcher                    ║")
    print("║          Créé par : tomitom66800                        ║")
    print("║                                                          ║")
    print("║       Appuyez sur INSERT pour ouvrir le menu            ║")
    print("║                                                          ║")
    print("╚══════════════════════════════════════════════════════════╝")
end

-- Notification système
local function Notify(message, duration, color)
    duration = duration or 3
    color = color or Colors.Accent
    
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "SpyNotification"
    notifGui.ResetOnSpawn = false
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        notifGui.Parent = CoreGui
    end)
    
    if not notifGui.Parent then
        notifGui.Parent = LocalPlayer.PlayerGui
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 70)
    frame.Position = UDim2.new(1, -370, 0, 20)
    frame.BackgroundColor3 = Colors.Secondary
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 50, 1, 0)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🔔"
    icon.TextSize = 24
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, -20)
    text.Position = UDim2.new(0, 55, 0, 10)
    text.BackgroundTransparency = 1
    text.Text = message
    text.TextColor3 = Colors.Text
    text.TextSize = 14
    text.Font = Enum.Font.Gotham
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Top
    text.Parent = frame
    
    -- Animation d'entrée
    frame.Position = UDim2.new(1, 0, 0, 20)
    TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -370, 0, 20)
    }):Play()
    
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Position = UDim2.new(1, 0, 0, 20)
        }):Play()
        task.wait(0.3)
        notifGui:Destroy()
    end)
end

-- Obtenir les attributs du joueur
local function GetPlayerAttributes(player)
    local attrs = {}
    
    -- Liste des attributs génériques
    local knownAttrs = {
        "MicEnabled",
        "VoiceChatEnabled",
        "VREnabled",
        "Country",
        "Language",
        "DataLoaded",
        "Loaded"
    }
    
    for _, attrName in pairs(knownAttrs) do
        pcall(function()
            local value = player:GetAttribute(attrName)
            if value ~= nil then
                attrs[attrName] = value
            end
        end)
    end
    
    -- Debug: afficher tous les attributs du joueur
    if SpyMenu.DebugMode then
        print("=== Attributs de " .. player.Name .. " ===")
        for k, v in pairs(attrs) do
            print(k .. " = " .. tostring(v))
        end
        print("===========================")
    end
    
    return attrs
end

-- Obtenir les informations complètes du joueur
local function GetPlayerInfo(player)
    local info = {
        Username = player.Name,
        DisplayName = player.DisplayName,
        UserId = player.UserId,
        AccountAge = player.AccountAge .. " jours",
        Team = "N/A",
        Character = nil,
        Humanoid = nil,
        Health = "N/A",
        MaxHealth = "N/A",
        Position = "N/A",
        WalkSpeed = "N/A",
        JumpPower = "N/A",
        IsFriend = false,
        Attributes = {},
        Backpack = {},
        Equipment = {},
        LeaderstatsMinutes = "N/A",
        VoiceChatEnabled = "N/A",
        MicEnabled = "N/A",
        Country = "N/A",
        Language = "N/A"
    }
    
    -- Attributs génériques
    local attrs = GetPlayerAttributes(player)
    info.Attributes = attrs
    
    if attrs.VoiceChatEnabled ~= nil then
        info.VoiceChatEnabled = tostring(attrs.VoiceChatEnabled)
    end
    if attrs.MicEnabled ~= nil then
        info.MicEnabled = tostring(attrs.MicEnabled)
    end
    if attrs.Country then
        info.Country = attrs.Country
    end
    if attrs.Language then
        info.Language = attrs.Language
    end
    
    -- Informations du personnage
    if player.Character then
        info.Character = player.Character
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            info.Humanoid = humanoid
            info.Health = string.format("%.0f", humanoid.Health)
            info.MaxHealth = string.format("%.0f", humanoid.MaxHealth)
            info.WalkSpeed = string.format("%.1f", humanoid.WalkSpeed)
            info.JumpPower = string.format("%.1f", humanoid.JumpPower)
        end
        
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local pos = rootPart.Position
            info.Position = string.format("X: %.1f, Y: %.1f, Z: %.1f", pos.X, pos.Y, pos.Z)
        end
        
        -- Équipement
        for _, child in pairs(player.Character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Tool") then
                table.insert(info.Equipment, child.Name)
            end
        end
    end
    
    -- Équipe
    if player.Team then
        info.Team = player.Team.Name
    end
    
    -- Ami
    pcall(function()
        info.IsFriend = LocalPlayer:IsFriendsWith(player.UserId)
    end)
    
    -- Leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local minutes = leaderstats:FindFirstChild("Minutes")
        if minutes then
            info.LeaderstatsMinutes = tostring(minutes.Value) .. " min"
        end
    end
    
    -- Backpack
    if player:FindFirstChild("Backpack") then
        for _, tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                table.insert(info.Backpack, tool.Name)
            end
        end
    end
    
    return info
end


-- Créer un tooltip
local activeTooltip = nil

local function ShowTooltip(text, position)
    if activeTooltip then
        activeTooltip:Destroy()
    end
    
    local tooltipGui = Instance.new("ScreenGui")
    tooltipGui.Name = "Tooltip"
    tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    tooltipGui.DisplayOrder = 999
    
    pcall(function()
        tooltipGui.Parent = CoreGui
    end)
    
    if not tooltipGui.Parent then
        tooltipGui.Parent = LocalPlayer.PlayerGui
    end
    
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Size = UDim2.new(0, 250, 0, 60)
    tooltipFrame.Position = UDim2.new(0, position.X + 10, 0, position.Y + 10)
    tooltipFrame.BackgroundColor3 = Colors.Background
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Parent = tooltipGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = tooltipFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = tooltipFrame
    
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Size = UDim2.new(1, -20, 1, -20)
    tooltipText.Position = UDim2.new(0, 10, 0, 10)
    tooltipText.BackgroundTransparency = 1
    tooltipText.Text = text
    tooltipText.TextColor3 = Colors.Text
    tooltipText.TextSize = 12
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.TextWrapped = true
    tooltipText.TextXAlignment = Enum.TextXAlignment.Left
    tooltipText.TextYAlignment = Enum.TextYAlignment.Top
    tooltipText.Parent = tooltipFrame
    
    activeTooltip = tooltipGui
    return tooltipGui
end

local function HideTooltip()
    if activeTooltip then
        activeTooltip:Destroy()
        activeTooltip = nil
    end
end

-- Créer un bouton stylisé
local function CreateButton(text, size, callback, tooltip)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(0, 100, 0, 32)
    button.BackgroundColor3 = Colors.Secondary
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Colors.Text
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Border
    stroke.Thickness = 1
    stroke.Parent = button
    
    -- Animations
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Accent
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = Colors.AccentHover
        }):Play()
        
        -- Afficher le tooltip si fourni
        if tooltip then
            ShowTooltip(tooltip, Mouse)
        end
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Secondary
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.2), {
            Color = Colors.Border
        }):Play()
        
        -- Cacher le tooltip
        HideTooltip()
    end)
    
    if callback then
        button.MouseButton1Click:Connect(callback)
    end
    
    return button
end

-- ═══════════════════════════════════════════════════════════
--                FONCTIONS D'ACTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction SCAN : Afficher toutes les infos du joueur
local function OpenScanWindow(player)
    local info = GetPlayerInfo(player)
    
    -- Fermer la fenêtre si elle existe déjà
    local existing = CoreGui:FindFirstChild("ScanWindow_" .. player.Name) or LocalPlayer.PlayerGui:FindFirstChild("ScanWindow_" .. player.Name)
    if existing then
        existing:Destroy()
    end
    
    local scanGui = Instance.new("ScreenGui")
    scanGui.Name = "ScanWindow_" .. player.Name
    scanGui.ResetOnSpawn = false
    scanGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        scanGui.Parent = CoreGui
    end)
    
    if not scanGui.Parent then
        scanGui.Parent = LocalPlayer.PlayerGui
    end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 500, 0, 700)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -350)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = scanGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Barre de titre
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Colors.Tertiary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔍 SCAN - " .. player.DisplayName .. " (@" .. player.Name .. ")"
    title.TextColor3 = Colors.Accent
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Bouton fermer
    local closeBtn = CreateButton("✖", UDim2.new(0, 40, 0, 35), function()
        scanGui:Destroy()
    end)
    closeBtn.Position = UDim2.new(1, -50, 0, 7.5)
    closeBtn.Parent = titleBar
    
    -- ScrollFrame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -20, 1, -70)
    scrollFrame.Position = UDim2.new(0, 10, 0, 60)
    scrollFrame.BackgroundColor3 = Colors.Secondary
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Colors.Accent
    scrollFrame.Parent = mainFrame
    
    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 8)
    scrollCorner.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = scrollFrame
    
    -- Fonction pour ajouter une ligne d'info
    local function AddInfoLine(label, value, layoutOrder)
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -10, 0, 30)
        line.BackgroundColor3 = Colors.Tertiary
        line.BorderSizePixel = 0
        line.LayoutOrder = layoutOrder or 0
        line.Parent = scrollFrame
        
        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(0, 6)
        lineCorner.Parent = line
        
        local labelText = Instance.new("TextLabel")
        labelText.Size = UDim2.new(0.4, -10, 1, 0)
        labelText.Position = UDim2.new(0, 10, 0, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label .. ":"
        labelText.TextColor3 = Colors.TextSecondary
        labelText.TextSize = 12
        labelText.Font = Enum.Font.GothamBold
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.Parent = line
        
        local valueText = Instance.new("TextLabel")
        valueText.Size = UDim2.new(0.6, -10, 1, 0)
        valueText.Position = UDim2.new(0.4, 0, 0, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = tostring(value)
        valueText.TextColor3 = Colors.Text
        valueText.TextSize = 12
        valueText.Font = Enum.Font.Gotham
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.TextTruncate = Enum.TextTruncate.AtEnd
        valueText.Parent = line
        
        return line
    end
    
    -- Fonction pour ajouter une section
    local function AddSection(title, layoutOrder)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, -10, 0, 25)
        section.BackgroundTransparency = 1
        section.Text = title
        section.TextColor3 = Colors.Accent
        section.TextSize = 14
        section.Font = Enum.Font.GothamBold
        section.TextXAlignment = Enum.TextXAlignment.Left
        section.LayoutOrder = layoutOrder or 0
        section.Parent = scrollFrame
        
        return section
    end
    
    -- Ajouter les informations
    local order = 0
    
    AddSection("📊 INFORMATIONS DE BASE", order)
    order = order + 1
    AddInfoLine("Username", info.Username, order)
    order = order + 1
    AddInfoLine("Display Name", info.DisplayName, order)
    order = order + 1
    
    -- User ID avec bouton Copy
    local userIdLine = Instance.new("Frame")
    userIdLine.Size = UDim2.new(1, -10, 0, 25)
    userIdLine.BackgroundTransparency = 1
    userIdLine.LayoutOrder = order
    userIdLine.Parent = scrollFrame
    order = order + 1
    
    local userIdLabel = Instance.new("TextLabel")
    userIdLabel.Size = UDim2.new(0.4, 0, 1, 0)
    userIdLabel.BackgroundTransparency = 1
    userIdLabel.Text = "User ID"
    userIdLabel.TextColor3 = Colors.TextSecondary
    userIdLabel.TextSize = 12
    userIdLabel.Font = Enum.Font.GothamBold
    userIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    userIdLabel.Parent = userIdLine
    
    local userIdValue = Instance.new("TextLabel")
    userIdValue.Size = UDim2.new(0.4, -10, 1, 0)
    userIdValue.Position = UDim2.new(0.4, 0, 0, 0)
    userIdValue.BackgroundTransparency = 1
    userIdValue.Text = tostring(info.UserId)
    userIdValue.TextColor3 = Colors.Text
    userIdValue.TextSize = 12
    userIdValue.Font = Enum.Font.Gotham
    userIdValue.TextXAlignment = Enum.TextXAlignment.Right
    userIdValue.TextTruncate = Enum.TextTruncate.AtEnd
    userIdValue.Parent = userIdLine
    
    local btnCopyId = CreateButton("📋", UDim2.new(0.15, 0, 0, 20), function()
        setclipboard(tostring(info.UserId))
        Notify("ID copié: " .. tostring(info.UserId), 2, Colors.Success)
    end, "Copier l'User ID")
    btnCopyId.Position = UDim2.new(0.85, 0, 0, 2)
    btnCopyId.Parent = userIdLine
    
    AddInfoLine("Age du compte", info.AccountAge, order)
    order = order + 1
    AddInfoLine("Équipe", info.Team, order)
    order = order + 1
    AddInfoLine("Ami", info.IsFriend and "✓ Oui" or "✗ Non", order)
    order = order + 1
    
    AddSection("🌍 INFORMATIONS", order)
    order = order + 1
    AddInfoLine("Pays", info.Country, order)
    order = order + 1
    AddInfoLine("Langue", info.Language, order)
    order = order + 1
    
    AddSection("🎤 VOICE CHAT", order)
    order = order + 1
    AddInfoLine("Voice Chat", info.VoiceChatEnabled, order)
    order = order + 1
    AddInfoLine("Micro activé", info.MicEnabled, order)
    order = order + 1
    
    if info.Character then
        AddSection("💚 SANTÉ & MOUVEMENT", order)
        order = order + 1
        AddInfoLine("Santé", info.Health .. "/" .. info.MaxHealth, order)
        order = order + 1
        AddInfoLine("Vitesse", info.WalkSpeed, order)
        order = order + 1
        AddInfoLine("Jump Power", info.JumpPower, order)
        order = order + 1
    end
    
    if #info.Equipment > 0 then
        AddSection("👔 ÉQUIPEMENT", order)
        order = order + 1
        for _, item in ipairs(info.Equipment) do
            AddInfoLine("", item, order)
            order = order + 1
        end
    end
    
    if #info.Backpack > 0 then
        AddSection("🎒 INVENTAIRE", order)
        order = order + 1
        for _, tool in ipairs(info.Backpack) do
            AddInfoLine("", tool, order)
            order = order + 1
        end
    end
    
    -- Ajuster la taille du canvas
    task.wait(0.2)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 50)
    
    Notify("Scan de " .. player.DisplayName .. " terminé! Scroll pour voir SPY DIRECT.", 3, Colors.Success)
end

-- Fonction SPECTATE
local function SpectatePlayer(player)
    if not player.Character or not player.Character:FindFirstChild("Humanoid") then
        Notify("Le joueur n'a pas de personnage!", 2, Colors.Warning)
        return
    end
    
    SpyMenu.SpectatingPlayer = player
    Camera.CameraSubject = player.Character.Humanoid
    
    Notify("Mode spectateur activé sur " .. player.DisplayName, 2, Colors.Success)
end

-- Fonction STOP SPECTATE
local function StopSpectate()
    if SpyMenu.SpectatingPlayer then
        Camera.CameraSubject = SpyMenu.OriginalCameraSubject
        SpyMenu.SpectatingPlayer = nil
        Notify("Mode spectateur désactivé", 2, Colors.Success)
    end
end

-- Fonction GOTO
local function GotoPlayer(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        Notify("Le joueur n'a pas de personnage!", 2, Colors.Warning)
        return
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
        return
    end
    
    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    Notify("Téléporté vers " .. player.DisplayName, 2, Colors.Success)
end

-- Fonction TRACK (suivi simple sans invisibilité)
local function TrackPlayer(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        Notify("Le joueur n'a pas de personnage!", 2, Colors.Warning)
        return false
    end
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
        return false
    end
    
    -- Sauvegarder la position originale
    if not SpyMenu.TrackingPlayer then
        SpyMenu.OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
    
    SpyMenu.TrackingPlayer = player
    
    -- Boucle de suivi
    if SpyMenu.TrackingConnection then
        SpyMenu.TrackingConnection:Disconnect()
    end
    
    SpyMenu.TrackingConnection = RunService.Heartbeat:Connect(function()
        if player and player.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = player.Character.HumanoidRootPart.CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPos * CFrame.new(0, 0, 3)
        end
    end)
    
    Notify("Mode Track activé sur " .. player.DisplayName, 3, Colors.Success)
    return true
end

-- Fonction STOP TRACK
local function StopTrack()
    if SpyMenu.TrackingConnection then
        SpyMenu.TrackingConnection:Disconnect()
        SpyMenu.TrackingConnection = nil
    end
    
    -- Téléporter à la position originale
    if SpyMenu.OriginalPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        task.wait(0.1)
        LocalPlayer.Character.HumanoidRootPart.CFrame = SpyMenu.OriginalPosition
    end
    
    SpyMenu.TrackingPlayer = nil
    Notify("Mode Track désactivé", 2, Colors.Success)
end

-- Fonction pour obtenir sur qui le joueur est tombé dans sa maison

-- Fonction pour détecter si un joueur utilise VR
local function IsPlayerUsingVR(player)
    -- Méthode 1 : Vérifier l'attribut VR dans le character
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local rigType = humanoid.RigType
            -- Les joueurs VR ont souvent un rig R15
            if rigType == Enum.HumanoidRigType.R15 then
                -- Vérifier si il y a une caméra VR
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local vrCamera = head:FindFirstChild("VRCamera")
                    if vrCamera then
                        return true
                    end
                end
            end
        end
        
        -- Vérifier les objets VR spécifiques
        for _, child in pairs(player.Character:GetDescendants()) do
            if child.Name:lower():find("vr") or child.Name:lower():find("headset") then
                return true
            end
        end
    end
    
    -- Méthode 2 : Vérifier les attributes VR
    local disableVRRagdoll = player:GetAttribute("DisableVRRagdoll")
    if disableVRRagdoll ~= nil then
        -- Si cet attribut existe et est configuré, le joueur a probablement VR
        return true
    end
    
    -- Méthode 3 : Vérifier le UserInputService (pour LocalPlayer uniquement)
    if player == LocalPlayer then
        local UserInputService = game:GetService("UserInputService")
        if UserInputService.VREnabled then
            return true
        end
    end
    
    return false
end

-- Fonction pour obtenir les informations VR
local function GetVRInfo(player)
    local isVR = IsPlayerUsingVR(player)
    if isVR then
        return "✅ Oui (VR Actif)"
    else
        return "❌ Non"
    end
end

-- Fonction SPY (Fenêtre de surveillance complète)
local function OpenSpyWindow(player)
    -- Fermer la fenêtre si elle existe déjà
    local existing = CoreGui:FindFirstChild("SpyWindow_" .. player.Name) or LocalPlayer.PlayerGui:FindFirstChild("SpyWindow_" .. player.Name)
    if existing then
        existing:Destroy()
    end
    
    local spyGui = Instance.new("ScreenGui")
    spyGui.Name = "SpyWindow_" .. player.Name
    spyGui.ResetOnSpawn = false
    spyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        spyGui.Parent = CoreGui
    end)
    
    if not spyGui.Parent then
        spyGui.Parent = LocalPlayer.PlayerGui
    end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -300)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = spyGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Accent
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Barre de titre
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Colors.Tertiary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🕵️ SPY - " .. player.DisplayName .. " (@" .. player.Name .. ")"
    title.TextColor3 = Colors.Accent
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    -- Bouton fermer
    local closeBtn = CreateButton("✖", UDim2.new(0, 40, 0, 35), function()
        spyGui:Destroy()
        if SpyMenu.ChatConnections[player.UserId] then
            SpyMenu.ChatConnections[player.UserId]:Disconnect()
            SpyMenu.ChatConnections[player.UserId] = nil
        end
    end)
    closeBtn.Position = UDim2.new(1, -50, 0, 7.5)
    closeBtn.Parent = titleBar
    
    -- Informations en temps réel
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -20, 0, 140)
    infoFrame.Position = UDim2.new(0, 10, 0, 60)
    infoFrame.BackgroundColor3 = Colors.Secondary
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = mainFrame
    
    local infoCorner = Instance.new("UICorner")
    infoCorner.CornerRadius = UDim.new(0, 8)
    infoCorner.Parent = infoFrame
    
    local infoTitle = Instance.new("TextLabel")
    infoTitle.Size = UDim2.new(1, -20, 0, 25)
    infoTitle.Position = UDim2.new(0, 10, 0, 5)
    infoTitle.BackgroundTransparency = 1
    infoTitle.Text = "📊 INFORMATIONS EN TEMPS RÉEL"
    infoTitle.TextColor3 = Colors.Accent
    infoTitle.TextSize = 13
    infoTitle.Font = Enum.Font.GothamBold
    infoTitle.TextXAlignment = Enum.TextXAlignment.Left
    infoTitle.Parent = infoFrame
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, -20, 0, 20)
    healthLabel.Position = UDim2.new(0, 10, 0, 35)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "💚 Santé: Chargement..."
    healthLabel.TextColor3 = Colors.Text
    healthLabel.TextSize = 12
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthLabel.Parent = infoFrame
    
    local posLabel = Instance.new("TextLabel")
    posLabel.Size = UDim2.new(1, -20, 0, 20)
    posLabel.Position = UDim2.new(0, 10, 0, 60)
    posLabel.BackgroundTransparency = 1
    posLabel.Text = "📍 Position: Chargement..."
    posLabel.TextColor3 = Colors.Text
    posLabel.TextSize = 12
    posLabel.Font = Enum.Font.Gotham
    posLabel.TextXAlignment = Enum.TextXAlignment.Left
    posLabel.Parent = infoFrame
    
    local micLabel = Instance.new("TextLabel")
    micLabel.Size = UDim2.new(1, -20, 0, 20)
    micLabel.Position = UDim2.new(0, 10, 0, 85)
    micLabel.BackgroundTransparency = 1
    micLabel.Text = "🎤 Micro: Chargement..."
    micLabel.TextColor3 = Colors.Text
    micLabel.TextSize = 12
    micLabel.Font = Enum.Font.Gotham
    micLabel.TextXAlignment = Enum.TextXAlignment.Left
    micLabel.Parent = infoFrame
    
    
    local toolLabel = Instance.new("TextLabel")
    toolLabel.Size = UDim2.new(1, -20, 0, 20)
    toolLabel.Position = UDim2.new(0, 10, 0, 110)
    toolLabel.BackgroundTransparency = 1
    toolLabel.Text = "🔧 Outil équipé: Aucun"
    toolLabel.TextColor3 = Colors.Text
    toolLabel.TextSize = 12
    toolLabel.Font = Enum.Font.Gotham
    toolLabel.TextXAlignment = Enum.TextXAlignment.Left
    toolLabel.Parent = infoFrame
    
    -- SPY DIRECT (réservé pour usage futur)
    local spyDirectFrame = Instance.new("Frame")
    spyDirectFrame.Size = UDim2.new(1, -20, 0, 100)
    spyDirectFrame.Position = UDim2.new(0, 10, 0, 210)
    spyDirectFrame.BackgroundColor3 = Colors.Secondary
    spyDirectFrame.BorderSizePixel = 0
    spyDirectFrame.Parent = mainFrame
    
    local spyDirectCorner = Instance.new("UICorner")
    spyDirectCorner.CornerRadius = UDim.new(0, 8)
    spyDirectCorner.Parent = spyDirectFrame
    
    local spyDirectTitle = Instance.new("TextLabel")
    spyDirectTitle.Size = UDim2.new(1, -20, 1, -10)
    spyDirectTitle.Position = UDim2.new(0, 10, 0, 5)
    spyDirectTitle.BackgroundTransparency = 1
    spyDirectTitle.Text = "🔍 SPY DIRECT\n\nFonctionnalités à venir..."
    spyDirectTitle.TextColor3 = Colors.TextSecondary
    spyDirectTitle.TextSize = 13
    spyDirectTitle.Font = Enum.Font.Gotham
    spyDirectTitle.TextXAlignment = Enum.TextXAlignment.Center
    spyDirectTitle.TextYAlignment = Enum.TextYAlignment.Center
    spyDirectTitle.Parent = spyDirectFrame
    
    -- Chat en direct
    local chatFrame = Instance.new("Frame")
    chatFrame.Size = UDim2.new(1, -20, 0, 220)
    chatFrame.Position = UDim2.new(0, 10, 0, 320)
    chatFrame.BackgroundColor3 = Colors.Secondary
    chatFrame.BorderSizePixel = 0
    chatFrame.Parent = mainFrame
    
    local chatCorner = Instance.new("UICorner")
    chatCorner.CornerRadius = UDim.new(0, 8)
    chatCorner.Parent = chatFrame
    
    local chatTitle = Instance.new("TextLabel")
    chatTitle.Size = UDim2.new(1, -20, 0, 25)
    chatTitle.Position = UDim2.new(0, 10, 0, 5)
    chatTitle.BackgroundTransparency = 1
    chatTitle.Text = "💬 CHAT EN DIRECT"
    chatTitle.TextColor3 = Colors.Accent
    chatTitle.TextSize = 13
    chatTitle.Font = Enum.Font.GothamBold
    chatTitle.TextXAlignment = Enum.TextXAlignment.Left
    chatTitle.Parent = chatFrame
    
    local chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Size = UDim2.new(1, -20, 1, -40)
    chatScroll.Position = UDim2.new(0, 10, 0, 35)
    chatScroll.BackgroundColor3 = Colors.Tertiary
    chatScroll.BorderSizePixel = 0
    chatScroll.ScrollBarThickness = 6
    chatScroll.ScrollBarImageColor3 = Colors.Accent
    chatScroll.Parent = chatFrame
    
    local chatScrollCorner = Instance.new("UICorner")
    chatScrollCorner.CornerRadius = UDim.new(0, 6)
    chatScrollCorner.Parent = chatScroll
    
    local chatLayout = Instance.new("UIListLayout")
    chatLayout.Padding = UDim.new(0, 5)
    chatLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chatLayout.Parent = chatScroll
    
    local chatPadding = Instance.new("UIPadding")
    chatPadding.PaddingLeft = UDim.new(0, 8)
    chatPadding.PaddingRight = UDim.new(0, 8)
    chatPadding.PaddingTop = UDim.new(0, 8)
    chatPadding.PaddingBottom = UDim.new(0, 8)
    chatPadding.Parent = chatScroll
    
    -- Fonction pour ajouter un message au chat
    local function AddChatMessage(message, timestamp)
        local msgFrame = Instance.new("Frame")
        msgFrame.Size = UDim2.new(1, -10, 0, 40)
        msgFrame.BackgroundColor3 = Colors.Background
        msgFrame.BorderSizePixel = 0
        msgFrame.Parent = chatScroll
        
        local msgCorner = Instance.new("UICorner")
        msgCorner.CornerRadius = UDim.new(0, 5)
        msgCorner.Parent = msgFrame
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0, 60, 0, 15)
        timeLabel.Position = UDim2.new(0, 5, 0, 3)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = timestamp
        timeLabel.TextColor3 = Colors.TextSecondary
        timeLabel.TextSize = 10
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Parent = msgFrame
        
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -70, 1, -5)
        msgLabel.Position = UDim2.new(0, 65, 0, 3)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = message
        msgLabel.TextColor3 = Colors.Text
        msgLabel.TextSize = 11
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.TextYAlignment = Enum.TextYAlignment.Top
        msgLabel.TextWrapped = true
        msgLabel.Parent = msgFrame
        
        -- Ajuster la hauteur du message
        local textSize = game:GetService("TextService"):GetTextSize(
            message,
            11,
            Enum.Font.Gotham,
            Vector2.new(msgLabel.AbsoluteSize.X, 1000)
        )
        msgFrame.Size = UDim2.new(1, -10, 0, math.max(40, textSize.Y + 10))
        
        chatScroll.CanvasSize = UDim2.new(0, 0, 0, chatLayout.AbsoluteContentSize.Y + 16)
        chatScroll.CanvasPosition = Vector2.new(0, chatScroll.CanvasSize.Y.Offset)
    end
    
    -- Boutons d'action rapide
    
    -- Mise à jour en temps réel des informations
    local updateConnection
    updateConnection = RunService.Heartbeat:Connect(function()
        if not spyGui.Parent then
            updateConnection:Disconnect()
            return
        end
        
        if player and player.Parent then
            local info = GetPlayerInfo(player)
            
            -- Santé
            if info.Character and info.Humanoid then
                healthLabel.Text = string.format("💚 Santé: %s/%s", info.Health, info.MaxHealth)
            else
                healthLabel.Text = "💚 Santé: N/A"
            end
            
            -- Position
            posLabel.Text = "📍 Position: " .. info.Position
            
            -- Micro
            local micStatus = info.MicEnabled == "true" and "🟢 Activé" or "🔴 Désactivé"
            micLabel.Text = "🎤 Micro: " .. micStatus
            
            -- Outil équipé
            if info.Character then
                local tool = info.Character:FindFirstChildOfClass("Tool")
                if tool then
                    toolLabel.Text = "🔧 Outil équipé: " .. tool.Name
                else
                    toolLabel.Text = "🔧 Outil équipé: Aucun"
                end
            end
        else
            healthLabel.Text = "💚 Joueur déconnecté"
            posLabel.Text = "📍 Position: N/A"
            micLabel.Text = "🎤 Micro: N/A"
            toolLabel.Text = "🔧 Outil équipé: N/A"
        end
    end)
    
    -- Surveiller le chat (utilise TextChatService si disponible)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        local chatChannel = TextChatService:FindFirstChild("TextChannels"):FindFirstChild("RBXGeneral")
        
        if chatChannel then
            SpyMenu.ChatConnections[player.UserId] = chatChannel.MessageReceived:Connect(function(message)
                if message.TextSource and message.TextSource.UserId == player.UserId then
                    local timestamp = os.date("%H:%M:%S")
                    AddChatMessage(message.Text, timestamp)
                end
            end)
        end
    end)
    
    -- Fallback: surveiller le chat legacy
    pcall(function()
        local function onChatted(msg)
            local timestamp = os.date("%H:%M:%S")
            AddChatMessage(msg, timestamp)
        end
        
        if not SpyMenu.ChatConnections[player.UserId] then
            player.Chatted:Connect(onChatted)
        end
    end)
    
    AddChatMessage("Surveillance du chat démarrée...", os.date("%H:%M:%S"))
    
    Notify("Fenêtre SPY ouverte pour " .. player.DisplayName, 2, Colors.Success)
end

-- ═══════════════════════════════════════════════════════════
--                INTERFACE PRINCIPALE
-- ═══════════════════════════════════════════════════════════

local function CreateMainGUI()
    -- Créer le ScreenGui
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "SpyMenuMain"
    mainGui.ResetOnSpawn = false
    mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        mainGui.Parent = CoreGui
    end)
    
    if not mainGui.Parent then
        mainGui.Parent = LocalPlayer.PlayerGui
    end
    
    SpyMenu.GUI = mainGui
    
    -- Frame principale
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 800, 0, 600)
    mainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false
    mainFrame.Parent = mainGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Colors.Accent
    stroke.Thickness = 3
    stroke.Parent = mainFrame
    
    -- Barre de titre
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Colors.Tertiary
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 15)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, -20, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🕵️ SPY MENU HUB"
    title.TextColor3 = Colors.Accent
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0.3, -80, 1, 0)
    subtitle.Position = UDim2.new(0.7, 0, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "by tomitom66800"
    subtitle.TextColor3 = Colors.TextSecondary
    subtitle.TextSize = 12
    title.Font = Enum.Font.GothamBold
    subtitle.TextXAlignment = Enum.TextXAlignment.Right
    subtitle.Parent = titleBar
    
    -- Bouton fermer
    local closeBtn = CreateButton("✖", UDim2.new(0, 50, 0, 45), function()
        mainFrame.Visible = false
        SpyMenu.IsOpen = false
    end)
    closeBtn.Position = UDim2.new(1, -60, 0, 7.5)
    closeBtn.Parent = titleBar
    
    -- Onglets
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(0, 150, 1, -70)
    tabsFrame.Position = UDim2.new(0, 10, 0, 70)
    tabsFrame.BackgroundColor3 = Colors.Secondary
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = mainFrame
    
    local tabsCorner = Instance.new("UICorner")
    tabsCorner.CornerRadius = UDim.new(0, 10)
    tabsCorner.Parent = tabsFrame
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 5)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = tabsFrame
    
    local tabsPadding = Instance.new("UIPadding")
    tabsPadding.PaddingLeft = UDim.new(0, 5)
    tabsPadding.PaddingRight = UDim.new(0, 5)
    tabsPadding.PaddingTop = UDim.new(0, 10)
    tabsPadding.PaddingBottom = UDim.new(0, 10)
    tabsPadding.Parent = tabsFrame
    
    -- Contenu
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, -180, 1, -70)
    contentFrame.Position = UDim2.new(0, 170, 0, 70)
    contentFrame.BackgroundColor3 = Colors.Secondary
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = contentFrame
    
    -- Fonction pour créer un onglet
    local function CreateTab(name, icon, layoutOrder)
        local tabBtn = CreateButton(icon .. " " .. name, UDim2.new(1, -10, 0, 45), function()
            SpyMenu.CurrentTab = name
            -- Mettre à jour l'apparence des onglets
            for _, child in pairs(tabsFrame:GetChildren()) do
                if child:IsA("TextButton") then
                    if child.Text:find(name) then
                        child.BackgroundColor3 = Colors.Accent
                    else
                        child.BackgroundColor3 = Colors.Secondary
                    end
                end
            end
            -- Mettre à jour le contenu
            for _, child in pairs(contentFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name:find("Page") then
                    child.Visible = (child.Name == name .. "Page")
                end
            end
        end)
        tabBtn.LayoutOrder = layoutOrder
        tabBtn.TextXAlignment = Enum.TextXAlignment.Left
        tabBtn.Parent = tabsFrame
        
        return tabBtn
    end
    
    -- Créer les onglets
    CreateTab("Players", "👥", 1)
    CreateTab("Misc", "🧩", 2)
    
    -- ═══════════════════════════════════════════════════════════
    --                    PAGE PLAYERS
    -- ═══════════════════════════════════════════════════════════
    
    local playersPage = Instance.new("Frame")
    playersPage.Name = "PlayersPage"
    playersPage.Size = UDim2.new(1, 0, 1, 0)
    playersPage.BackgroundTransparency = 1
    playersPage.Visible = true
    playersPage.Parent = contentFrame
    
    -- Barre de recherche et filtres
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -20, 0, 45)
    searchFrame.Position = UDim2.new(0, 10, 0, 10)
    searchFrame.BackgroundColor3 = Colors.Tertiary
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = playersPage
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 35, 1, 0)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 18
    searchIcon.Font = Enum.Font.GothamBold
    searchIcon.Parent = searchFrame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.5, -45, 1, -10)
    searchBox.Position = UDim2.new(0, 40, 0, 5)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Rechercher par pseudo ou DisplayName..."
    searchBox.PlaceholderColor3 = Colors.TextSecondary
    searchBox.Text = ""
    searchBox.TextColor3 = Colors.Text
    searchBox.TextSize = 13
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame
    
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        SpyMenu.SearchTerm = searchBox.Text:lower()
        -- Rafraîchir la liste
        task.spawn(function()
            -- Logique de recherche implémentée dans la mise à jour de la liste
        end)
    end)
    
    -- Filtres
    local filterAll = CreateButton("Tous", UDim2.new(0, 90, 1, -10), function()
        SpyMenu.FilterMode = "All"
        filterAll.BackgroundColor3 = Colors.Accent
        filterFriends.BackgroundColor3 = Colors.Secondary
        filterStalked.BackgroundColor3 = Colors.Secondary
        RefreshPlayerList()
    end)
    filterAll.Position = UDim2.new(0.52, 5, 0, 5)
    filterAll.BackgroundColor3 = Colors.Accent
    filterAll.Parent = searchFrame
    
    local filterFriends = CreateButton("Amis", UDim2.new(0, 90, 1, -10), function()
        SpyMenu.FilterMode = "Friends"
        filterAll.BackgroundColor3 = Colors.Secondary
        filterFriends.BackgroundColor3 = Colors.Accent
        filterStalked.BackgroundColor3 = Colors.Secondary
        RefreshPlayerList()
    end)
    filterFriends.Position = UDim2.new(0.68, 5, 0, 5)
    filterFriends.Parent = searchFrame
    
    local filterStalked = CreateButton("👁️ Surveillés", UDim2.new(0, 90, 1, -10), function()
        SpyMenu.FilterMode = "Stalked"
        filterAll.BackgroundColor3 = Colors.Secondary
        filterFriends.BackgroundColor3 = Colors.Secondary
        filterStalked.BackgroundColor3 = Colors.Warning
        RefreshPlayerList()
    end)
    filterStalked.Position = UDim2.new(0.84, 5, 0, 5)
    filterStalked.Parent = searchFrame
    
    -- Liste des joueurs
    local playersScroll = Instance.new("ScrollingFrame")
    playersScroll.Name = "PlayersScroll"
    playersScroll.Size = UDim2.new(1, -20, 1, -75)
    playersScroll.Position = UDim2.new(0, 10, 0, 65)
    playersScroll.BackgroundColor3 = Colors.Tertiary
    playersScroll.BorderSizePixel = 0
    playersScroll.ScrollBarThickness = 8
    playersScroll.ScrollBarImageColor3 = Colors.Accent
    playersScroll.Parent = playersPage
    
    local playersScrollCorner = Instance.new("UICorner")
    playersScrollCorner.CornerRadius = UDim.new(0, 8)
    playersScrollCorner.Parent = playersScroll
    
    local playersLayout = Instance.new("UIListLayout")
    playersLayout.Padding = UDim.new(0, 8)
    playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playersLayout.Parent = playersScroll
    
    local playersPadding = Instance.new("UIPadding")
    playersPadding.PaddingLeft = UDim.new(0, 10)
    playersPadding.PaddingRight = UDim.new(0, 10)
    playersPadding.PaddingTop = UDim.new(0, 10)
    playersPadding.PaddingBottom = UDim.new(0, 10)
    playersPadding.Parent = playersScroll
    
    -- Fonction pour créer une carte de joueur
    local function CreatePlayerCard(player)
        local info = GetPlayerInfo(player)
        
        -- Vérifier les filtres
        if SpyMenu.FilterMode == "Friends" then
            if not info.IsFriend then
                return nil
            end
        elseif SpyMenu.FilterMode == "Party" then
            if not IsInParty(player) then
                return nil
            end
        end
        
        -- Vérifier la recherche
        if SpyMenu.SearchTerm ~= "" then
            local searchLower = SpyMenu.SearchTerm
            if not (player.Name:lower():find(searchLower) or player.DisplayName:lower():find(searchLower)) then
                return nil
            end
        end
        
        local card = Instance.new("Frame")
        card.Name = "PlayerCard_" .. player.Name
        card.Size = UDim2.new(1, -10, 0, 120)
        card.BackgroundColor3 = Colors.Background
        card.BorderSizePixel = 0
        card.Parent = playersScroll
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 8)
        cardCorner.Parent = card
        
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Colors.Border
        cardStroke.Thickness = 1
        cardStroke.Parent = card
        
        -- Avatar (placeholder)
        local avatarFrame = Instance.new("Frame")
        avatarFrame.Size = UDim2.new(0, 60, 0, 60)
        avatarFrame.Position = UDim2.new(0, 10, 0, 10)
        avatarFrame.BackgroundColor3 = Colors.Tertiary
        avatarFrame.BorderSizePixel = 0
        avatarFrame.Parent = card
        
        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(0, 8)
        avatarCorner.Parent = avatarFrame
        
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.new(1, 0, 1, 0)
        avatarImg.BackgroundTransparency = 1
        avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
        avatarImg.Parent = avatarFrame
        
        local avatarImgCorner = Instance.new("UICorner")
        avatarImgCorner.CornerRadius = UDim.new(0, 8)
        avatarImgCorner.Parent = avatarImg
        
        -- Informations
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 200, 0, 20)
        nameLabel.Position = UDim2.new(0, 80, 0, 10)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.DisplayName
        nameLabel.TextColor3 = Colors.Text
        nameLabel.TextSize = 15
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = card
        
        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Size = UDim2.new(0, 200, 0, 18)
        usernameLabel.Position = UDim2.new(0, 80, 0, 30)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text = "@" .. player.Name
        usernameLabel.TextColor3 = Colors.TextSecondary
        usernameLabel.TextSize = 12
        usernameLabel.Font = Enum.Font.Gotham
        usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
        usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        usernameLabel.Parent = card
        
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Size = UDim2.new(0, 200, 0, 18)
        healthLabel.Position = UDim2.new(0, 80, 0, 50)
        healthLabel.BackgroundTransparency = 1
        healthLabel.Text = "💚 " .. info.Health .. "/" .. info.MaxHealth
        healthLabel.TextColor3 = Colors.Success
        healthLabel.TextSize = 11
        healthLabel.Font = Enum.Font.Gotham
        healthLabel.TextXAlignment = Enum.TextXAlignment.Left
        healthLabel.Parent = card
        
        -- Boutons d'action
        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Size = UDim2.new(1, -20, 0, 40)
        buttonsFrame.Position = UDim2.new(0, 10, 0, 75)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.Parent = card
        
        local btnScan = CreateButton("🔍", UDim2.new(0, 45, 1, 0), function()
            OpenScanWindow(player)
        end, "Affiche toutes les informations détaillées du joueur")
        btnScan.Position = UDim2.new(0, 0, 0, 0)
        btnScan.Parent = buttonsFrame
        
        -- Bouton Spectate avec toggle
        local btnSpectate = Instance.new("TextButton")
        btnSpectate.Size = UDim2.new(0, 45, 1, 0)
        btnSpectate.Position = UDim2.new(0, 53, 0, 0)
        btnSpectate.BackgroundColor3 = Colors.Secondary
        btnSpectate.BorderSizePixel = 0
        btnSpectate.Text = "👁️"
        btnSpectate.TextColor3 = Colors.Text
        btnSpectate.TextSize = 13
        btnSpectate.Font = Enum.Font.GothamBold
        btnSpectate.AutoButtonColor = false
        btnSpectate.Parent = buttonsFrame
        
        local spectateCorner = Instance.new("UICorner")
        spectateCorner.CornerRadius = UDim.new(0, 6)
        spectateCorner.Parent = btnSpectate
        
        local spectateStroke = Instance.new("UIStroke")
        spectateStroke.Color = Colors.Border
        spectateStroke.Thickness = 1
        spectateStroke.Parent = btnSpectate
        
        local spectateKey = "spectate_" .. player.UserId
        SpyMenu.ActiveToggles[spectateKey] = false
        
        btnSpectate.MouseEnter:Connect(function()
            if not SpyMenu.ActiveToggles[spectateKey] then
                TweenService:Create(btnSpectate, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Accent
                }):Play()
                TweenService:Create(spectateStroke, TweenInfo.new(0.2), {
                    Color = Colors.AccentHover
                }):Play()
            end
            ShowTooltip("Met la caméra en mode spectateur sur le joueur", Mouse)
        end)
        
        btnSpectate.MouseLeave:Connect(function()
            if not SpyMenu.ActiveToggles[spectateKey] then
                TweenService:Create(btnSpectate, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Secondary
                }):Play()
                TweenService:Create(spectateStroke, TweenInfo.new(0.2), {
                    Color = Colors.Border
                }):Play()
            end
            HideTooltip()
        end)
        
        btnSpectate.MouseButton1Click:Connect(function()
            if not SpyMenu.ActiveToggles[spectateKey] then
                -- Désactiver tous les autres toggles du joueur
                local trackKey = "track_" .. player.UserId
                if SpyMenu.ActiveToggles[trackKey] then
                    StopTrack()
                    SpyMenu.ActiveToggles[trackKey] = false
                end
                
                SpectatePlayer(player)
                btnSpectate.Text = "✅"
                btnSpectate.BackgroundColor3 = Colors.Success
                spectateStroke.Color = Colors.Success
                SpyMenu.ActiveToggles[spectateKey] = true
            else
                StopSpectate()
                btnSpectate.Text = "👁️"
                btnSpectate.BackgroundColor3 = Colors.Secondary
                spectateStroke.Color = Colors.Border
                SpyMenu.ActiveToggles[spectateKey] = false
            end
        end)
        
        local btnGoto = CreateButton("🚀", UDim2.new(0, 45, 1, 0), function()
            GotoPlayer(player)
        end, "Téléporte votre personnage vers le joueur")
        btnGoto.Position = UDim2.new(0, 106, 0, 0)
        btnGoto.Parent = buttonsFrame
        
        -- Bouton Track avec toggle
        local btnTrack = Instance.new("TextButton")
        btnTrack.Size = UDim2.new(0, 45, 1, 0)
        btnTrack.Position = UDim2.new(0, 159, 0, 0)
        btnTrack.BackgroundColor3 = Colors.Secondary
        btnTrack.BorderSizePixel = 0
        btnTrack.Text = "📍"
        btnTrack.TextColor3 = Colors.Text
        btnTrack.TextSize = 13
        btnTrack.Font = Enum.Font.GothamBold
        btnTrack.AutoButtonColor = false
        btnTrack.Parent = buttonsFrame
        
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 6)
        trackCorner.Parent = btnTrack
        
        local trackStroke = Instance.new("UIStroke")
        trackStroke.Color = Colors.Border
        trackStroke.Thickness = 1
        trackStroke.Parent = btnTrack
        
        local trackKey = "track_" .. player.UserId
        SpyMenu.ActiveToggles[trackKey] = false
        
        btnTrack.MouseEnter:Connect(function()
            if not SpyMenu.ActiveToggles[trackKey] then
                TweenService:Create(btnTrack, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Accent
                }):Play()
                TweenService:Create(trackStroke, TweenInfo.new(0.2), {
                    Color = Colors.AccentHover
                }):Play()
            end
            ShowTooltip("Suit automatiquement le joueur (3m derrière)", Mouse)
        end)
        
        btnTrack.MouseLeave:Connect(function()
            if not SpyMenu.ActiveToggles[trackKey] then
                TweenService:Create(btnTrack, TweenInfo.new(0.2), {
                    BackgroundColor3 = Colors.Secondary
                }):Play()
                TweenService:Create(trackStroke, TweenInfo.new(0.2), {
                    Color = Colors.Border
                }):Play()
            end
            HideTooltip()
        end)
        
        btnTrack.MouseButton1Click:Connect(function()
            if not SpyMenu.ActiveToggles[trackKey] then
                -- Désactiver tous les autres toggles du joueur
                local spectateKey = "spectate_" .. player.UserId
                if SpyMenu.ActiveToggles[spectateKey] then
                    StopSpectate()
                    SpyMenu.ActiveToggles[spectateKey] = false
                end
                
                local success = TrackPlayer(player)
                if success then
                    btnTrack.Text = "✅"
                    btnTrack.BackgroundColor3 = Colors.Success
                    trackStroke.Color = Colors.Success
                    SpyMenu.ActiveToggles[trackKey] = true
                end
            else
                StopTrack()
                btnTrack.Text = "📍"
                btnTrack.BackgroundColor3 = Colors.Secondary
                trackStroke.Color = Colors.Border
                SpyMenu.ActiveToggles[trackKey] = false
            end
        end)
        
        local btnSpy = CreateButton("🧠 SPY", UDim2.new(0, 100, 1, 0), function()
            OpenSpyWindow(player)
        end, "Ouvre une fenêtre de surveillance complète avec chat en direct")
        btnSpy.Position = UDim2.new(1, -210, 0, 0)
        btnSpy.Parent = buttonsFrame
        
        local btnWatch = CreateButton("👁️", UDim2.new(0, 100, 1, 0), function()
            if SpyMenu.WatchedPlayers[player.Name] then
                SpyMenu.WatchedPlayers[player.Name] = nil
                Notify("Surveillance arrêtée pour " .. player.DisplayName, 2, Colors.Success)
            else
                SpyMenu.WatchedPlayers[player.Name] = {
                    UserId = player.UserId,
                    LastSeen = os.time(),
                    LastState = "N/A",
                    LastHouse = "N/A",
                    LastParty = "N/A"
                }
                Notify("👁️ " .. player.DisplayName .. " ajouté à la surveillance!", 2, Colors.Warning)
            end
        end, "Ajouter/Retirer de la liste de surveillance")
        btnWatch.Position = UDim2.new(1, -100, 0, 0)
        btnWatch.Parent = buttonsFrame
        
        return card
    end
    
    -- Fonction pour rafraîchir la liste des joueurs
    local function RefreshPlayerList()
        -- Effacer les anciennes cartes
        for _, child in pairs(playersScroll:GetChildren()) do
            if child:IsA("Frame") and child.Name:find("PlayerCard") then
                child:Destroy()
            end
        end
        
        -- Créer les nouvelles cartes selon le filtre
        if SpyMenu.FilterMode == "Stalked" then
            -- Mode Stalked : afficher uniquement les joueurs surveillés
            for username, data in pairs(SpyMenu.WatchedPlayers) do
                local player = Players:FindFirstChild(username)
                if player and player ~= LocalPlayer then
                    -- Joueur en ligne
                    CreatePlayerCard(player)
                else
                    -- Joueur déconnecté mais surveillé - créer une carte spéciale
                    local card = Instance.new("Frame")
                    card.Name = "PlayerCard_" .. username
                    card.Size = UDim2.new(1, -10, 0, 80)
                    card.BackgroundColor3 = Colors.Secondary
                    card.BorderSizePixel = 0
                    card.LayoutOrder = 999 -- Mettre à la fin
                    card.Parent = playersScroll
                    
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = card
                    
                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Colors.Offline
                    stroke.Thickness = 2
                    stroke.Parent = card
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, -20, 0, 25)
                    nameLabel.Position = UDim2.new(0, 10, 0, 10)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = "❌ " .. username
                    nameLabel.TextColor3 = Colors.Offline
                    nameLabel.TextSize = 16
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.Parent = card
                    
                    local statusLabel = Instance.new("TextLabel")
                    statusLabel.Size = UDim2.new(1, -20, 0, 20)
                    statusLabel.Position = UDim2.new(0, 10, 0, 38)
                    statusLabel.BackgroundTransparency = 1
                    statusLabel.Text = "HORS LIGNE"
                    statusLabel.TextColor3 = Colors.Offline
                    statusLabel.TextSize = 12
                    statusLabel.Font = Enum.Font.Gotham
                    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
                    statusLabel.Parent = card
                    
                    local btnRemove = CreateButton("🗑️ Retirer", UDim2.new(0, 120, 0, 25), function()
                        SpyMenu.WatchedPlayers[username] = nil
                        RefreshPlayerList()
                        Notify("Surveillance arrêtée pour " .. username, 2, Colors.Success)
                    end, "Retirer de la surveillance")
                    btnRemove.Position = UDim2.new(1, -130, 0, 45)
                    btnRemove.Parent = card
                end
            end
        else
            -- Modes normaux (All, Friends)
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    -- Appliquer le filtre Friends
                    if SpyMenu.FilterMode == "All" or 
                       (SpyMenu.FilterMode == "Friends" and LocalPlayer:IsFriendsWith(player.UserId)) then
                        CreatePlayerCard(player)
                    end
                end
            end
        end
        
        -- Ajuster la taille du canvas
        task.wait(0.1)
        playersScroll.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Rafraîchir automatiquement toutes les 2 secondes
    task.spawn(function()
        while task.wait(2) do
            if SpyMenu.IsOpen and SpyMenu.CurrentTab == "Players" then
                RefreshPlayerList()
            end
        end
    end)
    
    -- Rafraîchir quand un joueur rejoint/quitte
    Players.PlayerAdded:Connect(function()
        if SpyMenu.IsOpen and SpyMenu.CurrentTab == "Players" then
            RefreshPlayerList()
        end
    end)
    
    Players.PlayerRemoving:Connect(function()
        if SpyMenu.IsOpen and SpyMenu.CurrentTab == "Players" then
            RefreshPlayerList()
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════
    --                    PAGE MISC
    -- ═══════════════════════════════════════════════════════════
    
    local miscPage = Instance.new("Frame")
    miscPage.Name = "MiscPage"
    miscPage.Size = UDim2.new(1, 0, 1, 0)
    miscPage.BackgroundTransparency = 1
    miscPage.Visible = false
    miscPage.Parent = contentFrame
    
    local miscScroll = Instance.new("ScrollingFrame")
    miscScroll.Size = UDim2.new(1, -20, 1, -20)
    miscScroll.Position = UDim2.new(0, 10, 0, 10)
    miscScroll.BackgroundColor3 = Colors.Tertiary
    miscScroll.BorderSizePixel = 0
    miscScroll.ScrollBarThickness = 8
    miscScroll.ScrollBarImageColor3 = Colors.Accent
    miscScroll.Parent = miscPage
    
    local miscScrollCorner = Instance.new("UICorner")
    miscScrollCorner.CornerRadius = UDim.new(0, 8)
    miscScrollCorner.Parent = miscScroll
    
    local miscLayout = Instance.new("UIListLayout")
    miscLayout.Padding = UDim.new(0, 15)
    miscLayout.SortOrder = Enum.SortOrder.LayoutOrder
    miscLayout.Parent = miscScroll
    
    local miscPadding = Instance.new("UIPadding")
    miscPadding.PaddingLeft = UDim.new(0, 15)
    miscPadding.PaddingRight = UDim.new(0, 15)
    miscPadding.PaddingTop = UDim.new(0, 15)
    miscPadding.PaddingBottom = UDim.new(0, 15)
    miscPadding.Parent = miscScroll
    
    -- Fonction pour créer une section
    local function CreateMiscSection(title, description)
        local section = Instance.new("Frame")
        section.Size = UDim2.new(1, -10, 0, 80)
        section.BackgroundColor3 = Colors.Background
        section.BorderSizePixel = 0
        section.Parent = miscScroll
        
        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 8)
        sectionCorner.Parent = section
        
        local sectionStroke = Instance.new("UIStroke")
        sectionStroke.Color = Colors.Border
        sectionStroke.Thickness = 1
        sectionStroke.Parent = section
        
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -20, 0, 25)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Colors.Accent
        titleLabel.TextSize = 15
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = section
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -20, 0, 40)
        descLabel.Position = UDim2.new(0, 10, 0, 30)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = description
        descLabel.TextColor3 = Colors.TextSecondary
        descLabel.TextSize = 12
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.TextYAlignment = Enum.TextYAlignment.Top
        descLabel.TextWrapped = true
        descLabel.Parent = section
        
        return section
    end
    
    -- Ajouter des sections MISC
    local miscSection0 = CreateMiscSection(
        "⚠️ RESET COMPLET",
        "Arrête TOUT (Spectate, Track, Speed, Jump, NoClip) et vous fait respawn"
    )
    
    local btnResetAll = CreateButton("🔴 STOP ALL + RESPAWN", UDim2.new(1, -20, 0, 35), function()
        -- Arrêter tous les modes de spectateur
        StopSpectate()
        StopTrack()
        
        -- Désactiver Speed Boost si actif
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(function()
                LocalPlayer.Character.Humanoid.WalkSpeed = 16
            end)
        end
        
        -- Désactiver Jump Boost si actif
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(function()
                LocalPlayer.Character.Humanoid.JumpPower = 50
            end)
        end
        
        -- Désactiver NoClip si actif
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    pcall(function()
                        part.CanCollide = true
                    end)
                end
            end
        end
        
        -- Respawn
        task.wait(0.2)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
        
        Notify("RESET COMPLET ! Respawn en cours...", 3, Colors.Warning)
    end, "Arrête tout et vous fait respawn pour reset complet")
    btnResetAll.Position = UDim2.new(0, 10, 0, 38)
    btnResetAll.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
    btnResetAll.Parent = miscSection0
    
    local miscSection1 = CreateMiscSection(
        "🚫 Stop All Spectate",
        "Arrête tous les modes de spectateur actifs (Spectate + Track)"
    )
    
    local btnStopAll = CreateButton("Arrêter tout", UDim2.new(0, 150, 0, 35), function()
        StopSpectate()
        StopTrack()
        Notify("Tous les modes spectateur ont été désactivés", 2, Colors.Success)
    end, "Désactive tous les modes de suivi actifs")
    btnStopAll.Position = UDim2.new(1, -160, 0, 38)
    btnStopAll.Parent = miscSection1
    
    local miscSection2 = CreateMiscSection(
        "🏃 Speed Boost",
        "Augmente temporairement votre vitesse de marche"
    )
    
    local speedEnabled = false
    local originalSpeed = 16
    
    -- Créer le bouton Speed manuellement pour un meilleur contrôle
    local btnSpeed = Instance.new("TextButton")
    btnSpeed.Size = UDim2.new(0, 150, 0, 35)
    btnSpeed.Position = UDim2.new(1, -160, 0, 38)
    btnSpeed.BackgroundColor3 = Colors.Secondary
    btnSpeed.BorderSizePixel = 0
    btnSpeed.Text = "Activer"
    btnSpeed.TextColor3 = Colors.Text
    btnSpeed.TextSize = 13
    btnSpeed.Font = Enum.Font.GothamBold
    btnSpeed.AutoButtonColor = false
    btnSpeed.Parent = miscSection2
    
    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = btnSpeed
    
    local speedStroke = Instance.new("UIStroke")
    speedStroke.Color = Colors.Border
    speedStroke.Thickness = 1
    speedStroke.Parent = btnSpeed
    
    btnSpeed.MouseEnter:Connect(function()
        if not speedEnabled then
            TweenService:Create(btnSpeed, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent}):Play()
            TweenService:Create(speedStroke, TweenInfo.new(0.2), {Color = Colors.AccentHover}):Play()
        end
        ShowTooltip("Active/Désactive l'augmentation de vitesse", Mouse)
    end)
    
    btnSpeed.MouseLeave:Connect(function()
        if not speedEnabled then
            TweenService:Create(btnSpeed, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary}):Play()
            TweenService:Create(speedStroke, TweenInfo.new(0.2), {Color = Colors.Border}):Play()
        end
        HideTooltip()
    end)
    
    btnSpeed.MouseButton1Click:Connect(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
            Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
            return
        end
        
        local humanoid = LocalPlayer.Character.Humanoid
        
        if not speedEnabled then
            originalSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = 50
            btnSpeed.Text = "🏃 ON"
            btnSpeed.BackgroundColor3 = Colors.Success
            speedStroke.Color = Colors.Success
            speedEnabled = true
            Notify("Speed Boost activé!", 2, Colors.Success)
        else
            humanoid.WalkSpeed = originalSpeed
            btnSpeed.Text = "Activer"
            btnSpeed.BackgroundColor3 = Colors.Secondary
            speedStroke.Color = Colors.Border
            speedEnabled = false
            Notify("Speed Boost désactivé", 2, Colors.Success)
        end
    end)
    
    local miscSection3 = CreateMiscSection(
        "🦘 Jump Boost",
        "Augmente temporairement votre puissance de saut"
    )
    
    local jumpEnabled = false
    local originalJump = 50
    
    -- Créer le bouton Jump manuellement
    local btnJump = Instance.new("TextButton")
    btnJump.Size = UDim2.new(0, 150, 0, 35)
    btnJump.Position = UDim2.new(1, -160, 0, 38)
    btnJump.BackgroundColor3 = Colors.Secondary
    btnJump.BorderSizePixel = 0
    btnJump.Text = "Activer"
    btnJump.TextColor3 = Colors.Text
    btnJump.TextSize = 13
    btnJump.Font = Enum.Font.GothamBold
    btnJump.AutoButtonColor = false
    btnJump.Parent = miscSection3
    
    local jumpCorner = Instance.new("UICorner")
    jumpCorner.CornerRadius = UDim.new(0, 6)
    jumpCorner.Parent = btnJump
    
    local jumpStroke = Instance.new("UIStroke")
    jumpStroke.Color = Colors.Border
    jumpStroke.Thickness = 1
    jumpStroke.Parent = btnJump
    
    btnJump.MouseEnter:Connect(function()
        if not jumpEnabled then
            TweenService:Create(btnJump, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent}):Play()
            TweenService:Create(jumpStroke, TweenInfo.new(0.2), {Color = Colors.AccentHover}):Play()
        end
        ShowTooltip("Active/Désactive l'augmentation de saut", Mouse)
    end)
    
    btnJump.MouseLeave:Connect(function()
        if not jumpEnabled then
            TweenService:Create(btnJump, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary}):Play()
            TweenService:Create(jumpStroke, TweenInfo.new(0.2), {Color = Colors.Border}):Play()
        end
        HideTooltip()
    end)
    
    btnJump.MouseButton1Click:Connect(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then
            Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
            return
        end
        
        local humanoid = LocalPlayer.Character.Humanoid
        
        if not jumpEnabled then
            originalJump = humanoid.JumpPower
            humanoid.JumpPower = 100
            btnJump.Text = "🦘 ON"
            btnJump.BackgroundColor3 = Colors.Success
            jumpStroke.Color = Colors.Success
            jumpEnabled = true
            Notify("Jump Boost activé!", 2, Colors.Success)
        else
            humanoid.JumpPower = originalJump
            btnJump.Text = "Activer"
            btnJump.BackgroundColor3 = Colors.Secondary
            jumpStroke.Color = Colors.Border
            jumpEnabled = false
            Notify("Jump Boost désactivé", 2, Colors.Success)
        end
    end)
    
    local miscSection4 = CreateMiscSection(
        "👻 No Clip",
        "Permet de traverser les murs (ATTENTION: peut être détecté)"
    )
    
    local noclipEnabled = false
    local noclipConnection
    
    -- Créer le bouton NoClip manuellement
    local btnNoclip = Instance.new("TextButton")
    btnNoclip.Size = UDim2.new(0, 150, 0, 35)
    btnNoclip.Position = UDim2.new(1, -160, 0, 38)
    btnNoclip.BackgroundColor3 = Colors.Secondary
    btnNoclip.BorderSizePixel = 0
    btnNoclip.Text = "Activer"
    btnNoclip.TextColor3 = Colors.Text
    btnNoclip.TextSize = 13
    btnNoclip.Font = Enum.Font.GothamBold
    btnNoclip.AutoButtonColor = false
    btnNoclip.Parent = miscSection4
    
    local noclipCorner = Instance.new("UICorner")
    noclipCorner.CornerRadius = UDim.new(0, 6)
    noclipCorner.Parent = btnNoclip
    
    local noclipStroke = Instance.new("UIStroke")
    noclipStroke.Color = Colors.Border
    noclipStroke.Thickness = 1
    noclipStroke.Parent = btnNoclip
    
    btnNoclip.MouseEnter:Connect(function()
        if not noclipEnabled then
            TweenService:Create(btnNoclip, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Accent}):Play()
            TweenService:Create(noclipStroke, TweenInfo.new(0.2), {Color = Colors.AccentHover}):Play()
        end
        ShowTooltip("Active/Désactive le mode no-clip", Mouse)
    end)
    
    btnNoclip.MouseLeave:Connect(function()
        if not noclipEnabled then
            TweenService:Create(btnNoclip, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Secondary}):Play()
            TweenService:Create(noclipStroke, TweenInfo.new(0.2), {Color = Colors.Border}):Play()
        end
        HideTooltip()
    end)
    
    btnNoclip.MouseButton1Click:Connect(function()
        if not LocalPlayer.Character then
            Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
            return
        end
        
        if not noclipEnabled then
            noclipEnabled = true
            btnNoclip.Text = "👻 ON"
            btnNoclip.BackgroundColor3 = Colors.Success
            noclipStroke.Color = Colors.Success
            
            noclipConnection = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            
            Notify("No Clip activé!", 2, Colors.Warning)
        else
            noclipEnabled = false
            btnNoclip.Text = "Activer"
            btnNoclip.BackgroundColor3 = Colors.Secondary
            noclipStroke.Color = Colors.Border
            
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = true
                    end
                end
            end
            
            Notify("No Clip désactivé", 2, Colors.Success)
        end
    end)
    
    local miscSection5 = CreateMiscSection(
        "📍 Waypoint Teleport",
        "Se téléporter à une position enregistrée"
    )
    
    local savedPosition = nil
    
    local btnSavePos = CreateButton("Sauvegarder", UDim2.new(0, 110, 0, 35), function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
            return
        end
        
        savedPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
        Notify("Position sauvegardée!", 2, Colors.Success)
    end, "Sauvegarde votre position actuelle")
    btnSavePos.Position = UDim2.new(1, -270, 0, 38)
    btnSavePos.Parent = miscSection5
    
    local btnTpPos = CreateButton("Téléporter", UDim2.new(0, 110, 0, 35), function()
        if not savedPosition then
            Notify("Aucune position sauvegardée!", 2, Colors.Warning)
            return
        end
        
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Notify("Vous n'avez pas de personnage!", 2, Colors.Warning)
            return
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = savedPosition
        Notify("Téléporté à la position sauvegardée!", 2, Colors.Success)
    end, "Téléporte à la position sauvegardée")
    btnTpPos.Position = UDim2.new(1, -150, 0, 38)
    btnTpPos.Parent = miscSection5
    
    local miscSection6 = CreateMiscSection(
        "🔄 Respawn",
        "Se faire réapparaître instantanément"
    )
    
    local btnRespawn = CreateButton("Respawn", UDim2.new(0, 150, 0, 35), function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
            Notify("Respawn en cours...", 2, Colors.Success)
        else
            Notify("Impossible de respawn!", 2, Colors.Warning)
        end
    end, "Se faire réapparaître instantanément")
    btnRespawn.Position = UDim2.new(1, -160, 0, 38)
    btnRespawn.Parent = miscSection6
    
    -- Ajuster la taille du canvas
    task.wait(0.1)
    miscScroll.CanvasSize = UDim2.new(0, 0, 0, miscLayout.AbsoluteContentSize.Y + 30)
    
    -- Initialiser avec la page Players
    RefreshPlayerList()
    
    return mainGui
end

-- ═══════════════════════════════════════════════════════════
--                    BANDEAU INFO + FENÊTRE RAPIDE
-- ═══════════════════════════════════════════════════════════

-- ScreenGui pour les éléments permanents
local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "SpyMenuOverlay"
overlayGui.ResetOnSpawn = false
overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
overlayGui.Parent = game:GetService("CoreGui")

-- Bandeau info en haut
local infoBanner = Instance.new("Frame")
infoBanner.Name = "InfoBanner"
infoBanner.Size = UDim2.new(0, 900, 0, 45)
infoBanner.Position = UDim2.new(0.5, -450, 0, 10)
infoBanner.BackgroundColor3 = Colors.Background
infoBanner.BorderSizePixel = 0
infoBanner.ZIndex = 10
infoBanner.Active = true
infoBanner.Parent = overlayGui

local infoBannerCorner = Instance.new("UICorner")
infoBannerCorner.CornerRadius = UDim.new(0, 12)
infoBannerCorner.Parent = infoBanner

local infoBannerStroke = Instance.new("UIStroke")
infoBannerStroke.Color = Colors.Accent
infoBannerStroke.Thickness = 2
infoBannerStroke.Parent = infoBanner

local infoBannerGradient = Instance.new("UIGradient")
infoBannerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}
infoBannerGradient.Rotation = 90
infoBannerGradient.Parent = infoBanner

-- Rendre le bandeau draggable
local bannerDragging = false
local bannerDragStart = nil
local bannerStartPos = nil

infoBanner.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bannerDragging = true
        bannerDragStart = input.Position
        bannerStartPos = infoBanner.Position
    end
end)

infoBanner.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and bannerDragging then
        local delta = input.Position - bannerDragStart
        infoBanner.Position = UDim2.new(
            bannerStartPos.X.Scale,
            bannerStartPos.X.Offset + delta.X,
            bannerStartPos.Y.Scale,
            bannerStartPos.Y.Offset + delta.Y
        )
    end
end)

infoBanner.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bannerDragging = false
    end
end)

local infoText = Instance.new("TextLabel")
infoText.Size = UDim2.new(1, -20, 1, 0)
infoText.Position = UDim2.new(0, 10, 0, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "Spy Menu | Chargement..."
infoText.TextColor3 = Colors.Text
infoText.TextSize = 13
infoText.Font = Enum.Font.Gotham
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Center
infoText.TextScaled = false
infoText.Parent = infoBanner

-- Fonction pour mettre à jour le bandeau
local function UpdateInfoBanner()
    local now = os.date("*t")
    local dateStr = string.format("%02d/%02d/%04d", now.day, now.month, now.year)
    local timeStr = string.format("%02d:%02d:%02d", now.hour, now.min, now.sec)
    
    infoText.Text = string.format("🕵️ Spy Menu  |  📅 %s  |  🕐 %s", 
        dateStr, timeStr)
end

-- Mettre à jour toutes les secondes
task.spawn(function()
    while task.wait(1) do
        UpdateInfoBanner()
    end
end)
UpdateInfoBanner()

-- Variable pour le bandeau de surveillance
local WatchBanner = nil

local function CreateWatchBanner()
    if WatchBanner then return end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WatchBanner"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 10
    
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer.PlayerGui
    end
    
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 280, 0, 400)
    container.Position = UDim2.new(1, -290, 0, 100)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    local function UpdateBanner()
        -- Nettoyer
        for _, child in pairs(container:GetChildren()) do
            child:Destroy()
        end
        
        local yOffset = 0
        local count = 0
        
        for username, data in pairs(SpyMenu.WatchedPlayers) do
            count = count + 1
            local player = Players:FindFirstChild(username)
            local isOnline = player ~= nil
            
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 35)
            card.Position = UDim2.new(0, 0, 0, yOffset)
            card.BackgroundColor3 = Colors.Background
            card.BorderSizePixel = 0
            card.Parent = container
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = card
            
            local stroke = Instance.new("UIStroke")
            stroke.Color = isOnline and Colors.Online or Colors.Offline
            stroke.Thickness = 2
            stroke.Parent = card
            
            -- Dot de statut
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 8, 0, 8)
            dot.BackgroundColor3 = isOnline and Colors.Online or Colors.Offline
            dot.BorderSizePixel = 0
            dot.Parent = card
            
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0)
            dotCorner.Parent = dot
            
            -- Nom
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -25, 0, 20)
            nameLabel.Position = UDim2.new(0, 22, 0, 5)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = username
            nameLabel.TextColor3 = Colors.Text
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = card
            
            if isOnline then
                -- Joueur en ligne - pas d'informations supplémentaires
            else
                -- Hors ligne
                local offlineLabel = Instance.new("TextLabel")
                offlineLabel.Size = UDim2.new(1, -10, 0, 50)
                offlineLabel.Position = UDim2.new(0, 8, 0, 28)
                offlineLabel.BackgroundTransparency = 1
                offlineLabel.Text = "❌ Hors ligne"
                offlineLabel.TextColor3 = Colors.Offline
                offlineLabel.TextSize = 11
                offlineLabel.Font = Enum.Font.Gotham
                offlineLabel.TextXAlignment = Enum.TextXAlignment.Left
                offlineLabel.Parent = card
            end
            
            yOffset = yOffset + 40
        end
        
        if count == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 60)
            emptyLabel.BackgroundColor3 = Colors.Background
            emptyLabel.BorderSizePixel = 0
            emptyLabel.Text = "Aucun joueur\nsurveillé"
            emptyLabel.TextColor3 = Colors.TextSecondary
            emptyLabel.TextSize = 12
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextWrapped = true
            emptyLabel.Parent = container
            
            local emptyCorner = Instance.new("UICorner")
            emptyCorner.CornerRadius = UDim.new(0, 8)
            emptyCorner.Parent = emptyLabel
        end
    end
    
    UpdateBanner()
    
    -- Update toutes les 3 secondes
    local connection = RunService.Heartbeat:Connect(function()
        task.wait(3)
        UpdateBanner()
    end)
    
    screenGui.AncestryChanged:Connect(function(_, parent)
        if not parent then connection:Disconnect() end
    end)
    
    WatchBanner = screenGui
end

-- ═══════════════════════════════════════════════════════════
--                    INITIALISATION
-- ═══════════════════════════════════════════════════════════

-- Afficher le message de bienvenue
ShowWelcomeMessage()

-- Créer le GUI
CreateMainGUI()

-- Gérer l'ouverture/fermeture avec INSERT
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        SpyMenu.IsOpen = not SpyMenu.IsOpen
        
        if SpyMenu.GUI and SpyMenu.GUI:FindFirstChild("MainFrame") then
            SpyMenu.GUI.MainFrame.Visible = SpyMenu.IsOpen
            
            if SpyMenu.IsOpen then
                Notify("Menu SPY ouvert", 1.5, Colors.Success)
                
                -- Rafraîchir la liste des joueurs
                task.spawn(function()
                    task.wait(0.1)
                    local playersScroll = SpyMenu.GUI.MainFrame.ContentFrame:FindFirstChild("PlayersPage"):FindFirstChild("PlayersScroll")
                    if playersScroll then
                        for _, child in pairs(playersScroll:GetChildren()) do
                            if child:IsA("Frame") and child.Name:find("PlayerCard") then
                                child:Destroy()
                            end
                        end
                        
                        for _, player in pairs(Players:GetPlayers()) do
                            if player ~= LocalPlayer then
                                -- Créer la carte (fonction définie plus haut)
                            end
                        end
                    end
                end)
            else
                Notify("Menu SPY fermé", 1.5, Colors.Warning)
            end
        end
    end
end)

-- Activer le bandeau de surveillance
task.spawn(function()
    task.wait(1)
    CreateWatchBanner()
end)

-- Message final
print("╔═══════════════════════════════════════════════════════════╗")
print("║                                                           ║")
print("║           SPY MENU HUB - VERSION 1.0.0                    ║")
print("║                    by tomitom66800                        ║")
print("║                                                           ║")
print("╚═══════════════════════════════════════════════════════════╝")
print("")
print("✅ Menu chargé avec succès!")
print("📌 Appuyez sur INSERT pour ouvrir/fermer")
print("")
print("📊 Fonctionnalités:")
print("  • Players: Liste complète avec filtres (Tous/Amis/Surveillés)")
print("  • Misc: Fonctions diverses")
print("")
print("🎯 Enjoy!")
