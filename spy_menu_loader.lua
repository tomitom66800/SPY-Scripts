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

-- Configuration des PlaceIds
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
local function DetectGame()
    local placeId = game.PlaceId
    
    if placeId == GAME_IDS.NEIGHBORS then
        return "NEIGHBORS"
    elseif placeId == GAME_IDS.THE_CORNER then
        return "THE_CORNER"
    else
        return "HUB"
    end
end

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
    subtitleLabel.Text = "Choisissez votre mode de chargement"
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
    
    -- Bouton AUTO
    CreateButton("🤖 AUTO - Détection automatique", UDim2.new(0, 20, 0, 120), function()
        local gameType = DetectGame()
        local gameName = gameType == "NEIGHBORS" and "Neighbors" or 
                        gameType == "THE_CORNER" and "The Corner" or 
                        "Generic HUB"
        
        -- Message de chargement
        subtitleLabel.Text = "Détection: " .. gameName .. " - Chargement..."
        subtitleLabel.TextColor3 = Colors.Success
        
        task.wait(0.5)
        
        LoadScript(gameType)
        
        -- Fermer le GUI après 1 seconde
        task.wait(1)
        screenGui:Destroy()
    end)
    
    -- Bouton MANUEL
    CreateButton("👆 MANUEL - Choisir le menu", UDim2.new(0, 20, 0, 180), function()
        -- Cacher les boutons principaux et afficher les options
        mainFrame:ClearAllChildren()
        
        -- Recréer les éléments de base
        local newCorner = Instance.new("UICorner")
        newCorner.CornerRadius = UDim.new(0, 12)
        newCorner.Parent = mainFrame
        
        local newStroke = Instance.new("UIStroke")
        newStroke.Color = Colors.Border
        newStroke.Thickness = 2
        newStroke.Parent = mainFrame
        
        -- Titre
        local newTitle = Instance.new("TextLabel")
        newTitle.Size = UDim2.new(1, -40, 0, 50)
        newTitle.Position = UDim2.new(0, 20, 0, 20)
        newTitle.BackgroundTransparency = 1
        newTitle.Text = "🕵️ SÉLECTION MANUELLE"
        newTitle.TextColor3 = Colors.Accent
        newTitle.TextSize = 22
        newTitle.Font = Enum.Font.GothamBold
        newTitle.TextXAlignment = Enum.TextXAlignment.Center
        newTitle.Parent = mainFrame
        
        -- Sous-titre
        local newSubtitle = Instance.new("TextLabel")
        newSubtitle.Size = UDim2.new(1, -40, 0, 30)
        newSubtitle.Position = UDim2.new(0, 20, 0, 60)
        newSubtitle.BackgroundTransparency = 1
        newSubtitle.Text = "Choisissez le menu à charger"
        newSubtitle.TextColor3 = Colors.TextSecondary
        newSubtitle.TextSize = 13
        newSubtitle.Font = Enum.Font.Gotham
        newSubtitle.TextXAlignment = Enum.TextXAlignment.Center
        newSubtitle.Parent = mainFrame
        
        -- Agrandir le frame
        mainFrame.Size = UDim2.new(0, 400, 0, 360)
        mainFrame.Position = UDim2.new(0.5, -200, 0.5, -180)
        
        -- Bouton Neighbors
        CreateButton("🏘️ SPY MENU - NEIGHBORS", UDim2.new(0, 20, 0, 110), function()
            newSubtitle.Text = "Chargement du menu Neighbors..."
            newSubtitle.TextColor3 = Colors.Success
            task.wait(0.5)
            LoadScript("NEIGHBORS")
            task.wait(1)
            screenGui:Destroy()
        end)
        
        -- Bouton The Corner
        CreateButton("🏙️ SPY MENU - THE CORNER", UDim2.new(0, 20, 0, 170), function()
            newSubtitle.Text = "Chargement du menu The Corner..."
            newSubtitle.TextColor3 = Colors.Success
            task.wait(0.5)
            LoadScript("THE_CORNER")
            task.wait(1)
            screenGui:Destroy()
        end)
        
        -- Bouton HUB
        CreateButton("🌐 SPY MENU - HUB (Generic)", UDim2.new(0, 20, 0, 230), function()
            newSubtitle.Text = "Chargement du menu HUB..."
            newSubtitle.TextColor3 = Colors.Success
            task.wait(0.5)
            LoadScript("HUB")
            task.wait(1)
            screenGui:Destroy()
        end)
        
        -- Bouton retour
        local backButton = Instance.new("TextButton")
        backButton.Size = UDim2.new(0, 100, 0, 35)
        backButton.Position = UDim2.new(0.5, -50, 1, -45)
        backButton.BackgroundColor3 = Colors.Secondary
        backButton.BorderSizePixel = 0
        backButton.Text = "← Retour"
        backButton.TextColor3 = Colors.TextSecondary
        backButton.TextSize = 14
        backButton.Font = Enum.Font.Gotham
        backButton.AutoButtonColor = false
        backButton.Parent = mainFrame
        
        local backCorner = Instance.new("UICorner")
        backCorner.CornerRadius = UDim.new(0, 8)
        backCorner.Parent = backButton
        
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
print("🎮 Jeu détecté: " .. (DetectGame() == "NEIGHBORS" and "Neighbors" or DetectGame() == "THE_CORNER" and "The Corner" or "Autre"))
print("📍 PlaceId: " .. game.PlaceId)
print("")

-- Créer le GUI
CreateLoaderGUI()
