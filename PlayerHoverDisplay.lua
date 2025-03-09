-- Debug message on load (before applying saved variables)
if PlayerHoverDisplaySettings and PlayerHoverDisplaySettings.debugMode then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFPHD Debug: Starting with default settings.|r")
end


-- Class colors
local classColors = {
    ["WARRIOR"] = "C79C6E",
    ["PALADIN"] = "F58CBA",
    ["HUNTER"] = "ABD473",
    ["ROGUE"] = "FFF569",
    ["PRIEST"] = "FFFFFF",
    ["SHAMAN"] = "0070DE",
    ["MAGE"] = "69CCF0",
    ["WARLOCK"] = "9482C9",
    ["DRUID"] = "FF7D0A"
}

-- NPC reaction colors
local reactionColors = {
    ["FRIENDLY"] = "00FF00",
    ["NEUTRAL"] = "FFFF00",
    ["HOSTILE"] = "FF0000"
}

-- Level difficulty colors
local levelColors = {
    ["GRAY"] = "808080",
    ["GREEN"] = "00FF00",
    ["YELLOW"] = "FFFF00",
    ["ORANGE"] = "FF7F00",
    ["RED"] = "FF0000",
    ["SKULL"] = "FFFFFF"
}

-- Default settings
local defaultSettings = {
    offsetX = 0,
    offsetY = 10,
    font_size = 14,
    showLevel = true,
    showToT = true,
    anchor = "BOTTOM",
    useClassColors = true,
    font = "Fonts\\FRIZQT__.TTF",
    debugMode = false,
    targetBelow = false,
}

-- Initialize PlayerHoverDisplaySettings globally without overwriting saved values.
if not PlayerHoverDisplaySettings then
    PlayerHoverDisplaySettings = {}
end
for k, v in pairs(defaultSettings) do
    if PlayerHoverDisplaySettings[k] == nil then
        PlayerHoverDisplaySettings[k] = v
    end
end

-- Main frame
local hoverFrame = CreateFrame("Frame", "PlayerHoverDisplayFrame", UIParent)

-- Font string to show hover text
text = hoverFrame:CreateFontString("PlayerHoverText", "OVERLAY")
text:SetFont(PlayerHoverDisplaySettings.font, PlayerHoverDisplaySettings.font_size or 12, "OUTLINE")
text:SetTextColor(1, 1, 1, 1)
text:Hide()

-- Helper: Get level color
local function GetLevelColor(targetLevel, isHostile)
    local playerLevel = UnitLevel("player") or 1
    if targetLevel == -1 and isHostile then
        return levelColors["SKULL"], "??"
    end

    local levelDiff = targetLevel - playerLevel
    if levelDiff >= 6 then
        return levelColors["RED"], targetLevel
    elseif levelDiff >= 3 then
        return levelColors["ORANGE"], targetLevel
    elseif levelDiff >= -2 then
        return levelColors["YELLOW"], targetLevel
    elseif levelDiff >= -7 then
        return levelColors["GREEN"], targetLevel
    else
        return levelColors["GRAY"], targetLevel
    end
end

-- Helper: Get color for Target of Target
local function GetTargetColor()
    if UnitExists("mouseovertarget") then
        if PlayerHoverDisplaySettings.useClassColors and UnitIsPlayer("mouseovertarget") then
            local class = UnitClass("mouseovertarget")
            local classKey = class and string.upper(class) or "UNKNOWN"
            return classColors[classKey] or "FFFFFF"
        else
            local reaction = UnitReaction("mouseovertarget", "player") or 4
            if reaction >= 5 then
                return reactionColors["FRIENDLY"]
            elseif reaction == 4 then
                return reactionColors["NEUTRAL"]
            else
                return reactionColors["HOSTILE"]
            end
        end
    end
    return "FFFFFF"
end

-- Centered position updater
local function UpdateTextPosition()
    local x, y = GetCursorPosition()

    -- Fix scale calculation to handle different UI scale properly in Vanilla 1.12.1
    local scale = UIParent:GetEffectiveScale() or 1
    x, y = x / scale, y / scale

    text:ClearAllPoints()
    local offsetX = PlayerHoverDisplaySettings.offsetX or 0
    local offsetY = PlayerHoverDisplaySettings.offsetY or 0
    local anchor = PlayerHoverDisplaySettings.anchor or "BOTTOM"
    -- Five arguments are required in Vanilla 1.12.1
    text:SetPoint(anchor, UIParent, "BOTTOMLEFT", x + offsetX, y + offsetY)
end

-- Hover update logic
local function UpdateHover()
    if not UnitExists("mouseover") then
        text:Hide()
        hoverFrame:SetScript("OnUpdate", nil)
        return
    end

    local name, level = UnitName("mouseover"), UnitLevel("mouseover")
    if not name then
        text:Hide()
        return
    end

    local levelColor, levelDisplay = "", ""
    if PlayerHoverDisplaySettings.showLevel and level then
        local isHostile = UnitCanAttack("player", "mouseover")
        levelColor, levelDisplay = GetLevelColor(level, isHostile)
        levelDisplay = "|cFF" .. levelColor .. "[" .. levelDisplay .. "]|r "
    end

    local targetText = ""
    if PlayerHoverDisplaySettings.showToT and UnitExists("mouseovertarget") then
        local targetColor = GetTargetColor()
        local targetName = UnitName("mouseovertarget") or "Unknown"
        if PlayerHoverDisplaySettings.targetBelow then
            -- Show target below the hovered unit's name
            targetText = "\n|cFF" .. targetColor .. targetName .. "|r"
        else
            -- Show target beside the hovered unit's name
            targetText = " |cFF808080>|r |cFF" .. targetColor .. targetName .. "|r"
        end
    end

    local colorHex = "FFFFFF"
    if PlayerHoverDisplaySettings.useClassColors and UnitIsPlayer("mouseover") then
        local class = UnitClass("mouseover")
        colorHex = classColors[class and string.upper(class) or "UNKNOWN"] or "FFFFFF"
    else
        local reaction = UnitReaction("mouseover", "player") or 4
        if reaction >= 5 then
            colorHex = reactionColors["FRIENDLY"]
        elseif reaction == 4 then
            colorHex = reactionColors["NEUTRAL"]
        else
            colorHex = reactionColors["HOSTILE"]
        end
    end

    -- Break apart each piece and ensure defaults to empty strings if nil
    local safeLevelDisplay = levelDisplay or ""
    local safeColorHex = colorHex or "FFFFFF"
    local safeName = name or "Unknown"
    local safeTargetText = targetText or ""

    -- Force font update
    text:SetFont(PlayerHoverDisplaySettings.font, PlayerHoverDisplaySettings.font_size, "OUTLINE")
    text:SetText(safeLevelDisplay .. "|cFF" .. safeColorHex .. safeName .. "|r" .. safeTargetText)
    UpdateTextPosition()
    text:Show()
end

-- Trigger frame for hover detection
local triggerFrame = CreateFrame("Frame")
triggerFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
triggerFrame:SetScript("OnEvent", function()
    if UnitExists("mouseover") then
        hoverFrame:SetScript("OnUpdate", UpdateHover)
    end
end)

--#########################################
--######## Configuration GUI Start ########
--#########################################

local settingsFrame = CreateFrame("Frame", "PHDSettingsFrame", UIParent)
if not settingsFrame then
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Error: settingsFrame could not be created!")
    end
    return
end

settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
settingsFrame:SetWidth(300)
settingsFrame:SetHeight(350) -- Increased height to accommodate new elements
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
settingsFrame:Hide()

-- Title
local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", settingsFrame, "TOP", 0, -16)
title:SetText("PlayerHoverDisplay Config")

-- Close Button
local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -10, -10)

-- Level Checkbox
local showLevelCheck = CreateFrame("CheckButton", "PHDShowLevelCheck", settingsFrame, "OptionsCheckButtonTemplate")
if not showLevelCheck then
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Error: Failed to create showLevelCheck!")
    end
else
    showLevelCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -65)
    showLevelCheck:SetChecked(PlayerHoverDisplaySettings.showLevel)
    showLevelCheck:SetScript("OnClick", function()
        PlayerHoverDisplaySettings.showLevel = showLevelCheck:GetChecked() and true or false
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Show Level toggled to: " .. tostring(PlayerHoverDisplaySettings.showLevel))
        end
    end)
end
local showLevelText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showLevelText:SetPoint("LEFT", showLevelCheck, "RIGHT", 5, 0)
showLevelText:SetText("Level")

-- Target of Target Checkbox
local showToTCheck = CreateFrame("CheckButton", "PHDShowToTCheck", settingsFrame, "OptionsCheckButtonTemplate")
if not showToTCheck then
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Error: Failed to create showToTCheck!")
    end
else
    showToTCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 160, -65)
    showToTCheck:SetChecked(PlayerHoverDisplaySettings.showToT)
    showToTCheck:SetScript("OnClick", function()
        PlayerHoverDisplaySettings.showToT = showToTCheck:GetChecked() and true or false
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Show Target of Target toggled to: " .. tostring(PlayerHoverDisplaySettings.showToT))
        end
    end)
end
local showToTText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showToTText:SetPoint("LEFT", showToTCheck, "RIGHT", 5, 0)
showToTText:SetText("Target (ToT)")

-- Debug Checkbox
local debugModeCheck = CreateFrame("CheckButton", "PHDDebugModeCheck", settingsFrame, "OptionsCheckButtonTemplate")
debugModeCheck:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 160, 13)
debugModeCheck:SetChecked(PlayerHoverDisplaySettings.debugMode)
debugModeCheck:SetScript("OnClick", function()
    PlayerHoverDisplaySettings.debugMode = debugModeCheck:GetChecked() and true or false
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Debug Mode ENABLED")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Debug Mode DISABLED")
    end
end)
local debugModeText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
debugModeText:SetPoint("LEFT", debugModeCheck, "RIGHT", 5, 2)
debugModeText:SetText("Debug")

-- Class Color Checkbox
local useClassColorsCheck = CreateFrame("CheckButton", "PHDUseClassColorsCheck", settingsFrame, "OptionsCheckButtonTemplate")
if not useClassColorsCheck then
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Error: Failed to create useClassColorsCheck!")
    end
else
    useClassColorsCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 20, -95)
    useClassColorsCheck:SetChecked(PlayerHoverDisplaySettings.useClassColors)
    useClassColorsCheck:SetScript("OnClick", function()
        PlayerHoverDisplaySettings.useClassColors = useClassColorsCheck:GetChecked() and true or false
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Use Class Colors toggled to: " .. tostring(PlayerHoverDisplaySettings.useClassColors))
        end
    end)
end
local useClassColorsText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
useClassColorsText:SetPoint("LEFT", useClassColorsCheck, "RIGHT", 5, 0)
useClassColorsText:SetText("Class Color")

-- Target Below Checkbox
local targetBelowCheck = CreateFrame("CheckButton", "PHDTargetBelowCheck", settingsFrame, "OptionsCheckButtonTemplate")
targetBelowCheck:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 160, -95)
targetBelowCheck:SetChecked(PlayerHoverDisplaySettings.targetBelow)
targetBelowCheck:SetScript("OnClick", function()
    PlayerHoverDisplaySettings.targetBelow = targetBelowCheck:GetChecked() and true or false
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Show Target Below toggled to: " .. tostring(PlayerHoverDisplaySettings.targetBelow))
    end
end)
local targetBelowText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
targetBelowText:SetPoint("LEFT", targetBelowCheck, "RIGHT", 5, 0)
targetBelowText:SetText("Target Below")


--###################################
--##### Font Select Menu Start ######
--###################################
local fontButton = CreateFrame("Button", "PHDFontButton", settingsFrame)
fontButton:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 25, -175)
fontButton:SetWidth(110)
fontButton:SetHeight(20)
fontButton:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
local fontButtonText = fontButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontButtonText:SetPoint("CENTER", fontButton, "CENTER", 0, 0)
PlayerHoverDisplaySettings.font = PlayerHoverDisplaySettings.font or "Fonts\\FRIZQT__.TTF"
fontButtonText:SetText(string.gsub(string.gsub(PlayerHoverDisplaySettings.font, "Fonts\\", ""), ".ttf", ""))

-- Dropdown menu for font selection
local fontMenu = CreateFrame("Frame", "PHDFontMenu", settingsFrame, "UIDropDownMenuTemplate")
fontMenu:SetPoint("TOPLEFT", fontButton, "BOTTOMLEFT", 0, -5)
fontMenu:Hide()

-- List of native fonts in WoW Vanilla 1.12.1
local nativeFonts = {
    "Fonts\\FRIZQT__.TTF",
    "Fonts\\ARIALN.TTF",
    "Fonts\\MORPHEUS.TTF",
    "Fonts\\SKURRI.TTF"
}

-- Function to initialize the font dropdown menu
local function InitializeFontMenu()
    for _, font in ipairs(nativeFonts) do
        local currentFont = font
        local displayName = string.gsub(string.gsub(font, "Fonts\\", ""), ".ttf", "")
        local info = {}
        info.text = displayName
        info.func = function()
            PlayerHoverDisplaySettings.font = currentFont
            fontButtonText:SetText(displayName)
            if text then
                text:SetFont(currentFont, PlayerHoverDisplaySettings.font_size, "OUTLINE")
            end
            CloseDropDownMenus()
        end
        UIDropDownMenu_AddButton(info)
    end
end

-- Set the dropdown menu's initialization function
UIDropDownMenu_Initialize(fontMenu, InitializeFontMenu)

-- Set the script to show/hide the dropdown menu
fontButton:SetScript("OnClick", function()
    ToggleDropDownMenu(1, nil, fontMenu, fontButton, 0, 0)
end)

-- Text label for the font button
local fontText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontText:SetPoint("BOTTOM", fontButton, "TOP", 0, 5)
fontText:SetText("Font Selection")
--###################################
--###### Font Select Menu End #######
--###################################

--###################################
--### Anchor Dropdown Menu Start ####
--###################################
local anchorButton = CreateFrame("Button", "PHDAnchorButton", settingsFrame)
anchorButton:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 165, -175)
anchorButton:SetWidth(110)
anchorButton:SetHeight(20)
anchorButton:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
local anchorButtonText = anchorButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorButtonText:SetPoint("CENTER", anchorButton, "CENTER", 0, 0)
anchorButtonText:SetText(PlayerHoverDisplaySettings.anchor or "BOTTOM")  -- Default to "BOTTOM"

local anchorMenu = CreateFrame("Frame", "PHDAnchorMenu", settingsFrame, "UIDropDownMenuTemplate")
anchorMenu:SetPoint("TOPLEFT", anchorButton, "BOTTOMLEFT", 0, -5)
anchorMenu:Hide()

local function InitializeAnchorMenu()
    local anchorOptions = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    for _, anchor in ipairs(anchorOptions) do
        local info = {}
        info.text = anchor
        info.value = anchor
        info.func = function()
            PlayerHoverDisplaySettings.anchor = this.value
            anchorButtonText:SetText(this.value)
            CloseDropDownMenus()
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Anchor point set to: " .. this.value)
            end
        end
        UIDropDownMenu_AddButton(info)
    end
end
UIDropDownMenu_Initialize(anchorMenu, InitializeAnchorMenu)

anchorButton:SetScript("OnClick", function()
    ToggleDropDownMenu(1, nil, anchorMenu, anchorButton, 0, 0)
end)
local anchorText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
anchorText:SetPoint("BOTTOM", anchorButton, "TOP", 0, 5)
anchorText:SetText("Anchor Point")
--###################################
--#### Anchor Dropdown Menu End #####
--###################################

--###################################
--###### X and Y Offset Start #######
--###################################
local xOffsetEditBox = CreateFrame("EditBox", "PHDXOffsetEditBox", settingsFrame, "InputBoxTemplate")
xOffsetEditBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 45, -235)
xOffsetEditBox:SetWidth(30)
xOffsetEditBox:SetHeight(20)
xOffsetEditBox:SetAutoFocus(false)
xOffsetEditBox:SetNumeric(true)
xOffsetEditBox:SetMaxLetters(4)
xOffsetEditBox:SetText(PlayerHoverDisplaySettings.offsetX or 0)
xOffsetEditBox:SetScript("OnEnterPressed", function()
    local value = tonumber(this:GetText()) or 0
    value = math.max(-200, math.min(200, value))
    PlayerHoverDisplaySettings.offsetX = value
    this:SetText(value)
    this:ClearFocus()
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("X Offset set to: " .. value)
    end
    UpdateTextPosition()
end)
xOffsetEditBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
    this:SetText(PlayerHoverDisplaySettings.offsetX or 0)
end)
local xOffsetText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
xOffsetText:SetPoint("LEFT", xOffsetEditBox, "LEFT", -21, 0)
xOffsetText:SetText("X:")

local yOffsetEditBox = CreateFrame("EditBox", "PHDYOffsetEditBox", settingsFrame, "InputBoxTemplate")
yOffsetEditBox:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 100, -235)
yOffsetEditBox:SetWidth(30)
yOffsetEditBox:SetHeight(20)
yOffsetEditBox:SetAutoFocus(false)
yOffsetEditBox:SetNumeric(true)
yOffsetEditBox:SetMaxLetters(4)
yOffsetEditBox:SetText(PlayerHoverDisplaySettings.offsetY or 0)
yOffsetEditBox:SetScript("OnEnterPressed", function()
    local value = tonumber(this:GetText()) or 0
    value = math.max(-200, math.min(200, value))
    PlayerHoverDisplaySettings.offsetY = value
    this:SetText(value)
    this:ClearFocus()
    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Y Offset set to: " .. value)
    end
    UpdateTextPosition()
end)
yOffsetEditBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
    this:SetText(PlayerHoverDisplaySettings.offsetY or 0)
end)
local yOffsetText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
yOffsetText:SetPoint("LEFT", yOffsetEditBox, "LEFT", -20, 0)
yOffsetText:SetText("Y:")

local offsetsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
offsetsTitle:SetPoint("BOTTOM", xOffsetEditBox, "TOP", 20, 5)
offsetsTitle:SetText("Offsets")
--###################################
--###### X and Y Offset End #########
--###################################

--###################################
--##### Font Size Slider Start ######
--###################################
local fontSizeSliderText
local fontSizeSlider = CreateFrame("Slider", "PHDFontSizeSlider", settingsFrame, "OptionsSliderTemplate")
fontSizeSlider:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 170, -236)
fontSizeSlider:SetWidth(100)
fontSizeSlider:SetHeight(20)
fontSizeSlider:SetMinMaxValues(6, 30)
fontSizeSlider:SetValueStep(1)
fontSizeSlider:SetValue(PlayerHoverDisplaySettings.font_size or 12)

local function OnFontSizeChanged()
    local fontSize = tonumber(this:GetValue()) or 12
    fontSize = math.floor(fontSize)
    fontSize = math.max(6, math.min(30, fontSize))

    PlayerHoverDisplaySettings.font_size = fontSize
    if text then
        text:SetFont(PlayerHoverDisplaySettings.font, fontSize, "OUTLINE")
    end

    if fontSizeSliderText then
        fontSizeSliderText:SetText("Font Size: " .. fontSize)
    end

    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Font size changed to: " .. fontSize)
    end
end

fontSizeSlider:SetScript("OnValueChanged", OnFontSizeChanged)
fontSizeSliderText = fontSizeSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontSizeSliderText:SetPoint("BOTTOM", fontSizeSlider, "TOP", 0, 5)
fontSizeSliderText:SetText("Font Size: " .. (PlayerHoverDisplaySettings.font_size or 12))
--###################################
--###### Font Size Slider End #######
--###################################

-- Single UpdateSettingsUI function for all elements
local function UpdateSettingsUI()
    if showLevelCheck then showLevelCheck:SetChecked(PlayerHoverDisplaySettings.showLevel) end
    if showToTCheck then showToTCheck:SetChecked(PlayerHoverDisplaySettings.showToT) end
    if useClassColorsCheck then useClassColorsCheck:SetChecked(PlayerHoverDisplaySettings.useClassColors) end
    if targetBelowCheck then targetBelowCheck:SetChecked(PlayerHoverDisplaySettings.targetBelow) end
    if debugModeCheck then debugModeCheck:SetChecked(PlayerHoverDisplaySettings.debugMode) end

    if fontSizeSliderText then
        fontSizeSliderText:SetText("Font Size: " .. (PlayerHoverDisplaySettings.font_size or 12))
    end
    if fontSizeSlider then
        fontSizeSlider:SetValue(PlayerHoverDisplaySettings.font_size or 12)
    end

    if fontButton then
        fontButtonText:SetText(string.gsub(string.gsub(PlayerHoverDisplaySettings.font, "Fonts\\", ""), ".ttf", ""))
    end

    if anchorButton then
        anchorButtonText:SetText(PlayerHoverDisplaySettings.anchor or "CENTER")
    end

    xOffsetEditBox:SetText(PlayerHoverDisplaySettings.offsetX or 0)
    yOffsetEditBox:SetText(PlayerHoverDisplaySettings.offsetY or 0)
end

-- Reset Button
local resetButton = CreateFrame("Button", nil, settingsFrame, "GameMenuButtonTemplate")
resetButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 22, 17)
resetButton:SetWidth(115)
resetButton:SetHeight(25)
resetButton:SetText("Reset Defaults")
resetButton:SetScript("OnClick", function()
    for k, v in pairs(defaultSettings) do
        PlayerHoverDisplaySettings[k] = v
    end

    UpdateSettingsUI()

    if text then
        text:SetFont(PlayerHoverDisplaySettings.font, PlayerHoverDisplaySettings.font_size, "OUTLINE")
    end

    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("Settings reset to defaults.")
    end
end)

settingsFrame:SetScript("OnShow", UpdateSettingsUI)

--#########################################
--######### Configuration GUI End #########
--#########################################


-- Custom string splitting function
local function splitString(msg)
    if not msg or msg == "" then
        return {}
    end
    local args = {}
    local start = 1
    local first, last = string.find(msg, "%S+", start)
    while first do
        table.insert(args, string.sub(msg, first, last))
        start = last + 1
        first, last = string.find(msg, "%S+", start)
    end
    return args
end

-- Helper: Check if a table contains a value
local function tContains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Slash command for settings
local function HandleSlashCommand(msg)
    local args = splitString(msg)
    local cmd = args[1] and string.lower(args[1]) or ""

    if cmd == "" or cmd == "settings" then
        if settingsFrame then
            if settingsFrame:IsShown() then
                settingsFrame:Hide()
            else
                settingsFrame:Show()
            end
        else
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Settings frame not available.")
            end
        end

    elseif cmd == "offset" then
        PlayerHoverDisplaySettings.offsetX = tonumber(args[2]) or 0
        PlayerHoverDisplaySettings.offsetY = tonumber(args[3]) or 0
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Offset set to X=" .. PlayerHoverDisplaySettings.offsetX .. " Y=" .. PlayerHoverDisplaySettings.offsetY)
        end

    elseif cmd == "fontsize" then
        local size = tonumber(args[2])
        if size then
            size = math.floor(size)
            size = math.max(6, math.min(30, size)) -- Clamp to valid range
    
            -- Update settings and apply font size change
            PlayerHoverDisplaySettings.font_size = size
            if text then
                text:SetFont(PlayerHoverDisplaySettings.font, size, "OUTLINE")
            else
                if PlayerHoverDisplaySettings.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("Error: Text object is nil!")
                end
            end
    
            -- Debug message
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Font size set to: " .. size)
            end
        else
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Invalid font size. Usage: /phd fontsize <size>")
            end
        end

    elseif cmd == "level" then
        PlayerHoverDisplaySettings.showLevel = not PlayerHoverDisplaySettings.showLevel
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Show Level: " .. tostring(PlayerHoverDisplaySettings.showLevel))
        end

    elseif cmd == "tot" then
        PlayerHoverDisplaySettings.showToT = not PlayerHoverDisplaySettings.showToT
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Show Target of Target: " .. tostring(PlayerHoverDisplaySettings.showToT))
        end

    elseif cmd == "classcolors" then
        PlayerHoverDisplaySettings.useClassColors = not PlayerHoverDisplaySettings.useClassColors
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Use Class Colors: " .. tostring(PlayerHoverDisplaySettings.useClassColors))
        end

    elseif cmd == "font" then
        local font = args[2]
        if font and tContains(nativeFonts, font) then
            PlayerHoverDisplaySettings.font = font
            if text then
                text:SetFont(font, PlayerHoverDisplaySettings.font_size, "OUTLINE")
            end
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Font set to: " .. font)
            end
        else
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Invalid font. Use: /phd font <font>")
            end
        end

    elseif cmd == "anchor" then
        local anchorOptions = {
            "TOPLEFT", "TOP", "TOPRIGHT",
            "LEFT", "CENTER", "RIGHT",
            "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"
        }
        local anchor = args[2] and string.upper(args[2])
        if anchor and tContains(anchorOptions, anchor) then
            PlayerHoverDisplaySettings.anchor = anchor
            if anchorButton then
                anchorButtonText:SetText(anchor)
            end
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Anchor set to: " .. anchor)
            end
        else
            if PlayerHoverDisplaySettings.debugMode then
                DEFAULT_CHAT_FRAME:AddMessage("Invalid anchor. Use: TOPLEFT, TOP, TOPRIGHT, LEFT, CENTER, RIGHT, BOTTOMLEFT, BOTTOM, BOTTOMRIGHT")
            end
        end

    else
        if PlayerHoverDisplaySettings.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("Commands: /phd [settings], offset <x> <y>, fontsize <size>, level, tot, classcolors, font <font>, anchor <position>")
        end
    end
end

SLASH_PHD1 = "/phd"
SlashCmdList["PHD"] = HandleSlashCommand

-- Load settings on login
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    if not PlayerHoverDisplaySettings then
        PlayerHoverDisplaySettings = {}
    end

    -- Normalize saved values and apply defaults if nil
    for k, v in pairs(defaultSettings) do
        if PlayerHoverDisplaySettings[k] == nil then
            PlayerHoverDisplaySettings[k] = v
        elseif k == "showLevel" or k == "showToT" or k == "useClassColors" then
            PlayerHoverDisplaySettings[k] = (PlayerHoverDisplaySettings[k] == true or PlayerHoverDisplaySettings[k] == 1) and true or false
        end
    end

    -- Apply font size and font to the text object
    if text then
        text:SetFont(PlayerHoverDisplaySettings.font, PlayerHoverDisplaySettings.font_size, "OUTLINE")
    end

    if showLevelCheck then showLevelCheck:SetChecked(PlayerHoverDisplaySettings.showLevel) end
    if showToTCheck then showToTCheck:SetChecked(PlayerHoverDisplaySettings.showToT) end
    if useClassColorsCheck then useClassColorsCheck:SetChecked(PlayerHoverDisplaySettings.useClassColors) end

    if PlayerHoverDisplaySettings.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("PlayerHoverDisplay Loaded.")
    end
end)