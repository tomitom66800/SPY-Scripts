--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              SPY MENU LOADER - HUB                       ║
    ║              Créé par : tomitom66800                     ║
    ║                                                          ║
    ║  Charge automatiquement le bon menu SPY                 ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Configuration des PlaceIds (pour info uniquement)
local GAME_IDS = {
    NEIGHBORS = 7346416636,
    THE_CORNER = 17255098561
}

-- URLs des scripts (GitHub)
local SCRIPT_URLS = {
    NEIGHBORS = "https://raw.githubusercontent.com/tomitom66800/SPY-Scripts/refs/heads/main/spy_menu_neighbors_v1_0_0_FINAL_FIXED.lua",
    THE_CORNER = "https://raw.githubusercontent.com/tomitom66800/SPY-Scripts/refs/heads/main/spy_menu_corner_v1_0_0%20(1).lua",
    HUB = "https://raw.githubusercontent.com/tomitom66800/SPY-Scripts/refs/heads/main/spy_menu_hub_v1_0_0%20(1).lua"
}

-- Couleurs
local Colors = {
    Background = Color3.fromRGB(20, 20, 25),
    Secondary = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentHover = Color3.fromRGB(108, 121, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(180, 180, 185),
    Success = Color3.fromRGB(67, 181, 129),
    Border = Color3.fromRGB(45, 45, 50)
}

-- Fonction pour charger un script
local function LoadScript(scriptType)
    print("🔄 Chargement du menu " .. scriptType .. "...")
    
    local url = SCRIPT_URLS[scriptType]
    
    -- Chargement via HTTP
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    
    if not success then
        warn("❌ Erreur lors du chargement : " .. tostring(result))
        warn("💡 URL utilisée : " .. url)
        warn("💡 Vérifie que ton executor supporte game:HttpGet()")
    else
        print("✅ Menu " .. scriptType .. " chargé avec succès!")
    end
end

-- Fonction pour détecter le jeu
-- Créer le GUI
local function CreateLoaderGUI()
    -- Supprimer l'ancien GUI s'il existe
    if CoreGui:FindFirstChild("SpyMenuLoader") then
        CoreGui:FindFirstChild("SpyMenuLoader"):Destroy()
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SpyMenuLoader"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui
    
    -- Frame principale
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Colors.Border
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    -- Shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    -- Titre
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -40, 0, 50)
    titleLabel.Position = UDim2.new(0, 20, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🕵️ SPY MENU LOADER"
    titleLabel.TextColor3 = Colors.Accent
    titleLabel.TextSize = 24
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.Parent = mainFrame
    
    -- Sous-titre
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -40, 0, 30)
    subtitleLabel.Position = UDim2.new(0, 20, 0, 70)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Sélectionnez le menu SPY"
    subtitleLabel.TextColor3 = Colors.TextSecondary
    subtitleLabel.TextSize = 13
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    subtitleLabel.Parent = mainFrame
    
    -- Fonction pour créer un bouton
    local function CreateButton(text, position, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -40, 0, 50)
        button.Position = position
        button.BackgroundColor3 = Colors.Secondary
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Colors.Text
        button.TextSize = 16
        button.Font = Enum.Font.GothamBold
        button.AutoButtonColor = false
        button.Parent = mainFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 10)
        buttonCorner.Parent = button
        
        local buttonStroke = Instance.new("UIStroke")
        buttonStroke.Color = Colors.Border
        buttonStroke.Thickness = 1
        buttonStroke.Parent = button
        
        -- Effet hover
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Colors.Accent
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Colors.Secondary
        end)
        
        button.MouseButton1Click:Connect(function()
            -- Animation click
            button.BackgroundColor3 = Colors.AccentHover
            task.wait(0.1)
            button.BackgroundColor3 = Colors.Accent
            
            callback()
        end)
        
        return button
    end
    
    -- Bouton Neighbors
    CreateButton("🏘️ SPY MENU - NEIGHBORS", UDim2.new(0, 20, 0, 120), function()
        subtitleLabel.Text = "Chargement du menu Neighbors..."
        subtitleLabel.TextColor3 = Colors.Success
        task.wait(0.5)
        LoadScript("NEIGHBORS")
        task.wait(1)
        screenGui:Destroy()
    end)
    
    -- Bouton The Corner
    CreateButton("🏙️ SPY MENU - THE CORNER", UDim2.new(0, 20, 0, 180), function()
        subtitleLabel.Text = "Chargement du menu The Corner..."
        subtitleLabel.TextColor3 = Colors.Success
        task.wait(0.5)
        LoadScript("THE_CORNER")
        task.wait(1)
        screenGui:Destroy()
    end)
    
    -- Bouton HUB
    CreateButton("🌐 SPY MENU - HUB (Generic)", UDim2.new(0, 20, 0, 240), function()
        subtitleLabel.Text = "Chargement du menu HUB..."
        subtitleLabel.TextColor3 = Colors.Success
        task.wait(0.5)
        LoadScript("HUB")
        task.wait(1)
        screenGui:Destroy()
    end)
    
    -- Agrandir la fenêtre pour le bouton À propos
    mainFrame.Size = UDim2.new(0, 400, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -180)
    
    -- Bouton À propos (plus petit, en bas)
    local aboutButton = Instance.new("TextButton")
    aboutButton.Size = UDim2.new(0, 150, 0, 35)
    aboutButton.Position = UDim2.new(0.5, -75, 1, -45)
    aboutButton.BackgroundColor3 = Colors.Secondary
    aboutButton.BorderSizePixel = 0
    aboutButton.Text = "ℹ️ À propos"
    aboutButton.TextColor3 = Colors.TextSecondary
    aboutButton.TextSize = 14
    aboutButton.Font = Enum.Font.GothamBold
    aboutButton.AutoButtonColor = false
    aboutButton.Parent = mainFrame
    
    local aboutCorner = Instance.new("UICorner")
    aboutCorner.CornerRadius = UDim.new(0, 8)
    aboutCorner.Parent = aboutButton
    
    aboutButton.MouseEnter:Connect(function()
        aboutButton.BackgroundColor3 = Colors.Accent
        aboutButton.TextColor3 = Colors.Text
    end)
    
    aboutButton.MouseLeave:Connect(function()
        aboutButton.BackgroundColor3 = Colors.Secondary
        aboutButton.TextColor3 = Colors.TextSecondary
    end)
    
    aboutButton.MouseButton1Click:Connect(function()
        -- Créer la page À propos
        mainFrame:ClearAllChildren()
        
        local newCorner = Instance.new("UICorner")
        newCorner.CornerRadius = UDim.new(0, 12)
        newCorner.Parent = mainFrame
        
        local newStroke = Instance.new("UIStroke")
        newStroke.Color = Colors.Border
        newStroke.Thickness = 2
        newStroke.Parent = mainFrame
        
        -- Agrandir pour le texte
        mainFrame.Size = UDim2.new(0, 450, 0, 420)
        mainFrame.Position = UDim2.new(0.5, -225, 0.5, -210)
        
        -- Titre
        local aboutTitle = Instance.new("TextLabel")
        aboutTitle.Size = UDim2.new(1, -40, 0, 50)
        aboutTitle.Position = UDim2.new(0, 20, 0, 20)
        aboutTitle.BackgroundTransparency = 1
        aboutTitle.Text = "ℹ️ À PROPOS"
        aboutTitle.TextColor3 = Colors.Accent
        aboutTitle.TextSize = 24
        aboutTitle.Font = Enum.Font.GothamBold
        aboutTitle.TextXAlignment = Enum.TextXAlignment.Center
        aboutTitle.Parent = mainFrame
        
        -- Ligne séparatrice
        local separator = Instance.new("Frame")
        separator.Size = UDim2.new(1, -40, 0, 2)
        separator.Position = UDim2.new(0, 20, 0, 75)
        separator.BackgroundColor3 = Colors.Border
        separator.BorderSizePixel = 0
        separator.Parent = mainFrame
        
        -- Créé par
        local creatorLabel = Instance.new("TextLabel")
        creatorLabel.Size = UDim2.new(1, -40, 0, 30)
        creatorLabel.Position = UDim2.new(0, 20, 0, 90)
        creatorLabel.BackgroundTransparency = 1
        creatorLabel.Text = "👤 Créé par : tomitom66800"
        creatorLabel.TextColor3 = Colors.Text
        creatorLabel.TextSize = 16
        creatorLabel.Font = Enum.Font.GothamBold
        creatorLabel.TextXAlignment = Enum.TextXAlignment.Left
        creatorLabel.Parent = mainFrame
        
        -- Discord (cliquable)
        local discordFrame = Instance.new("Frame")
        discordFrame.Size = UDim2.new(1, -40, 0, 50)
        discordFrame.Position = UDim2.new(0, 20, 0, 135)
        discordFrame.BackgroundColor3 = Colors.Secondary
        discordFrame.BorderSizePixel = 0
        discordFrame.Parent = mainFrame
        
        local discordCorner = Instance.new("UICorner")
        discordCorner.CornerRadius = UDim.new(0, 8)
        discordCorner.Parent = discordFrame
        
        local discordLabel = Instance.new("TextLabel")
        discordLabel.Size = UDim2.new(1, -20, 0, 25)
        discordLabel.Position = UDim2.new(0, 10, 0, 5)
        discordLabel.BackgroundTransparency = 1
        discordLabel.Text = "💬 Discord :"
        discordLabel.TextColor3 = Colors.TextSecondary
        discordLabel.TextSize = 14
        discordLabel.Font = Enum.Font.Gotham
        discordLabel.TextXAlignment = Enum.TextXAlignment.Left
        discordLabel.Parent = discordFrame
        
        local discordLink = Instance.new("TextButton")
        discordLink.Size = UDim2.new(1, -20, 0, 20)
        discordLink.Position = UDim2.new(0, 10, 0, 25)
        discordLink.BackgroundTransparency = 1
        discordLink.Text = "🔗 https://discord.gg/KTS8z2ZjQq (clik)"
        discordLink.TextColor3 = Colors.Accent
        discordLink.TextSize = 13
        discordLink.Font = Enum.Font.GothamBold
        discordLink.TextXAlignment = Enum.TextXAlignment.Left
        discordLink.AutoButtonColor = false
        discordLink.Parent = discordFrame
        
        discordLink.MouseEnter:Connect(function()
            discordLink.TextColor3 = Colors.AccentHover
        end)
        
        discordLink.MouseLeave:Connect(function()
            discordLink.TextColor3 = Colors.Accent
        end)
        
        discordLink.MouseButton1Click:Connect(function()
            setclipboard("https://discord.gg/KTS8z2ZjQq")
            discordLink.Text = "✅ Lien copié dans le presse-papier!"
            task.wait(2)
            discordLink.Text = "🔗 https://discord.gg/KTS8z2ZjQq (clik)"
        end)
        
        -- Warning
        local warningFrame = Instance.new("Frame")
        warningFrame.Size = UDim2.new(1, -40, 0, 120)
        warningFrame.Position = UDim2.new(0, 20, 0, 200)
        warningFrame.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
        warningFrame.BackgroundTransparency = 0.2
        warningFrame.BorderSizePixel = 0
        warningFrame.Parent = mainFrame
        
        local warningCorner = Instance.new("UICorner")
        warningCorner.CornerRadius = UDim.new(0, 8)
        warningCorner.Parent = warningFrame
        
        local warningStroke = Instance.new("UIStroke")
        warningStroke.Color = Color3.fromRGB(255, 50, 50)
        warningStroke.Thickness = 2
        warningStroke.Parent = warningFrame
        
        local warningTitle = Instance.new("TextLabel")
        warningTitle.Size = UDim2.new(1, -20, 0, 30)
        warningTitle.Position = UDim2.new(0, 10, 0, 10)
        warningTitle.BackgroundTransparency = 1
        warningTitle.Text = "⚠️ /!\\ WARNING /!\\"
        warningTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
        warningTitle.TextSize = 18
        warningTitle.Font = Enum.Font.GothamBold
        warningTitle.TextXAlignment = Enum.TextXAlignment.Center
        warningTitle.Parent = warningFrame
        
        local warningText = Instance.new("TextLabel")
        warningText.Size = UDim2.new(1, -20, 0, 70)
        warningText.Position = UDim2.new(0, 10, 0, 45)
        warningText.BackgroundTransparency = 1
        warningText.Text = "Cet outil est très dangereux !\n\nÀ utiliser avec PRÉCAUTION.\nVous êtes seul responsable de son utilisation."
        warningText.TextColor3 = Colors.Text
        warningText.TextSize = 14
        warningText.Font = Enum.Font.Gotham
        warningText.TextWrapped = true
        warningText.TextXAlignment = Enum.TextXAlignment.Center
        warningText.TextYAlignment = Enum.TextYAlignment.Top
        warningText.Parent = warningFrame
        
        -- Bouton retour
        local backButton = Instance.new("TextButton")
        backButton.Size = UDim2.new(0, 150, 0, 40)
        backButton.Position = UDim2.new(0.5, -75, 1, -50)
        backButton.BackgroundColor3 = Colors.Secondary
        backButton.BorderSizePixel = 0
        backButton.Text = "← Retour"
        backButton.TextColor3 = Colors.Text
        backButton.TextSize = 16
        backButton.Font = Enum.Font.GothamBold
        backButton.AutoButtonColor = false
        backButton.Parent = mainFrame
        
        local backCorner = Instance.new("UICorner")
        backCorner.CornerRadius = UDim.new(0, 8)
        backCorner.Parent = backButton
        
        backButton.MouseEnter:Connect(function()
            backButton.BackgroundColor3 = Colors.Accent
        end)
        
        backButton.MouseLeave:Connect(function()
            backButton.BackgroundColor3 = Colors.Secondary
        end)
        
        backButton.MouseButton1Click:Connect(function()
            screenGui:Destroy()
            CreateLoaderGUI()
        end)
    end)
    
    -- Info en bas
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, -40, 0, 25)
    infoLabel.Position = UDim2.new(0, 20, 1, -35)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "Made by tomitom66800 • v1.0.0"
    infoLabel.TextColor3 = Colors.TextSecondary
    infoLabel.TextSize = 11
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = mainFrame
end

-- Message de bienvenue
print("╔═══════════════════════════════════════════════════════════╗")
print("║                                                           ║")
print("║              SPY MENU LOADER v1.0.0                       ║")
print("║                by tomitom66800                            ║")
print("║                                                           ║")
print("╚═══════════════════════════════════════════════════════════╝")
print("")
print("✨ Sélectionnez le menu SPY de votre choix")
print("")

-- Créer le GUI
CreateLoaderGUI()
