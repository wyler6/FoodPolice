-- FoodPolice: Yells at group members who skip their food buff
-- Raid leader sets the watch list with /fp add, then /fp push sends it to everyone

local ADDON_NAME = "FoodPolice"
local MSG_PREFIX = "FoodPolice"  -- max 16 chars

local GetMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local ADDON_VERSION = GetMeta(ADDON_NAME, "Version") or "?.?"
local peerVersions = {}  -- [playerName] = versionString

local function ParseVersion(v)
    local major, minor = v:match("^(%d+)%.(%d+)")
    if major then return tonumber(major) * 100 + tonumber(minor) end
    local n = v:match("^(%d+)")
    return n and (tonumber(n) * 100) or 0
end

local YELLS = {
    "EAT YOUR FOOD!",
    "THE FEAST IS FREE!",
    "NO FOOD, NO PULL.",
    "WELL FED. LOOK IT UP.",
    "CHECK YOUR BAGS!",
    "WE ARE NOT STARTING WITHOUT WELL FED!",
    "THE COOK DIED FOR THOSE BUFFS!",
    "DO YOU WANT TO WIPE? BECAUSE THIS IS HOW WE WIPE.",
    "ONE JOB. ONE.",
    "AGAIN?! SERIOUSLY?!",
    "I AM BEGGING YOU. EAT SOMETHING.",
    "FOOD EXISTS. USE IT.",
    "THE RAID BOSS PROBABLY EATS BEFORE A FIGHT.",
    "I WILL WAIT. EAT.",
    "WOULD IT KILL YOU TO EAT SOMETHING?",
    "THIS IS WHY WE WIPE.",
    "EAT OR SIT OUT. YOUR CHOICE.",
    "THE FEAST IS RIGHT THERE! CLICK IT!",
    "HOW IS THIS STILL HAPPENING.",
    "BLESS YOUR HEART, NOW EAT YOUR FOOD.",
    "THE BUFF IS FREE. THE WIPE IS NOT.",
    "I SWEAR ON MY ENCHANTS, EAT THE FOOD.",
    "THERE IS A FEAST ON THE GROUND. IT IS CRYING.",
    "YOUR STATS ARE SAD. EAT.",
    "WE HAVE BEEN STANDING HERE FOR FIVE MINUTES. THE FOOD IS RIGHT THERE.",
    "I MADE THAT FEAST MYSELF. PLEASE.",
    "NOT A REQUEST. EAT.",
    "THE BUFF LASTS AN HOUR. IT TAKES THREE SECONDS. DO THE MATH.",
    "I AM LOOKING AT YOUR BUFF BAR AND I AM DISAPPOINTED.",
    "EAT THE FOOD OR EXPLAIN YOURSELF.",
    "THE BOSS HAS MORE HEALTH THAN YOUR WILLINGNESS TO EAT.",
    "CLICKING THE FEAST IS LITERALLY FREE DPS.",
    "YOUR CHARACTER IS HUNGRY. BE LESS HUNGRY.",
    "I HAVE ASKED NICELY. I AM DONE ASKING NICELY.",
    "FOOD NOW. FEELINGS LATER.",
    "EVERY WIPE IS ON YOU SPECIFICALLY.",
    "I WILL REMEMBER THIS WHEN WE WIPE.",
    "WE HAVE BEEN OVER THIS.",
    "SIT. EAT. COME BACK READY.",
    "SOMEWHERE IN PANDARIA, A CHILD IS STARVING. YOU HAVE A FEAST RIGHT IN FRONT OF YOU. EAT IT.",
}

local NOODLE_CART_YELLS = {
    "GET IN HERE BEFORE IT'S GONE!",
    "SOUP'S ON. MOVE YOUR FEET.",
    "FREE NOODLES. NO EXCUSES.",
    "THE CART IS DOWN. GET YOUR BOWL.",
    "HOT FRESH BUFFS ARE WAITING. CLICK THE CART.",
    "NOODLES AVAILABLE. LAZINESS NOT ACCEPTED.",
    "THIS CART DIDN'T DROP ITSELF. WELL, IT DID. GO EAT.",
    "SLURP. NOW.",
    "THAT NOODLE CART COST A LOT OF MATS. RESPECT IT.",
    "THE BUFF IS IN THE BOWL. GET THE BOWL.",
    "THIS CART TRAVELED VERY FAR TO BE IGNORED BY YOU.",
    "ONE CLICK. WELL FED. DO IT.",
    "THE NOODLE CART IS OPEN FOR BUSINESS.",
    "FRESH NOODLES ON THE GROUND. EAT THEM.",
    "MANDATORY SOUP TIME.",
    "THE CART IS UP. THE BUFF IS FREE. YOUR DPS IS NOT.",
    "GET YOUR NOODLES BEFORE THE BOSS EATS THEM.",
    "STEP 1: FIND CART. STEP 2: CLICK CART. STEP 3: WIN.",
    "NOODLES ARE A LOVE LANGUAGE. SHOW THEM LOVE.",
    "IF YOU SKIP THIS CART I WILL KNOW.",
    "THE CART SEES YOU. EAT.",
    "FREE STATS ON THE GROUND. GO GET THEM.",
    "THIS IS YOUR ONLY CHANCE FOR FREE NOODLES. DO NOT WASTE IT.",
    "WELL FED OR BENCH YOURSELF.",
    "THE NOODLE CART IS JUDGING YOU RIGHT NOW.",
    "HONOR THE CART. CLICK THE CART. BECOME WELL FED.",
    "NOODLE TIME IS SACRED. DO NOT DISHONOR IT.",
    "THE CART HAS SPOKEN. IT SAYS EAT.",
    "EVERY SECOND YOU DON'T EAT IS FREE DPS WASTED.",
    "NOODLE CART SPOTTED. EAT OR EXPLAIN YOURSELF.",
    "THE NOODLE CART WILL NOT WAIT FOREVER. MOVE.",
    "EAT FIRST. WIPE LESS.",
    "THERE IS A NOODLE CART. THERE IS NO EXCUSE.",
    "THE CHEF WORKED HARD. EAT THE FOOD.",
    "A NOODLE CART APPEARS! YOUR MOVE.",
    "CLICK THE SHINY CART. GET THE SHINY BUFF.",
    "THE NOODLE CART IS NOT A PROP. EAT FROM IT.",
    "WE DO NOT LEAVE NOODLE CARTS UNEATEN IN THIS RAID.",
    "TODAY WE FEAST. TODAY WE WIN. CLICK THE CART.",
    "IF YOU CAN READ THIS, YOU ARE CLOSE ENOUGH TO CLICK THE CART.",
}

local NOODLE_CART_COOLDOWN = 20
local lastCartTime = 0
local noodleDebug = false

local function AmILeaderOrAssist()
    if not IsInRaid() then return false end
    return UnitIsGroupLeader("player") or UnitIsRaidOfficer("player")
end

local function AnnounceNoodleCart(casterName)
    if not FoodPoliceDB.noodleCartEnabled then
        if noodleDebug then Print("[NoodleDebug] feature disabled") end
        return
    end
    if not AmILeaderOrAssist() then
        if noodleDebug then Print("[NoodleDebug] not leader/assist — skipping RW") end
        return
    end
    local now = GetTime()
    if now - lastCartTime < NOODLE_CART_COOLDOWN then
        if noodleDebug then Print("[NoodleDebug] on cooldown") end
        return
    end
    lastCartTime = now
    local saying = NOODLE_CART_YELLS[math.random(#NOODLE_CART_YELLS)]
    local fullMsg = (casterName or "Someone") .. " dropped a Noodle Cart! " .. saying
    C_Timer.After(0, function()
        local ok, err = pcall(SendChatMessage, fullMsg, "RAID_WARNING")
        if not ok then
            Print("RW error: " .. tostring(err))
        end
    end)
end

local YELL_COOLDOWN = 45  -- seconds between yells
local lastYellTime = 0

FoodPoliceDB = FoodPoliceDB or {}

-- MoP Classic runs on a modern client; RegisterAddonMessagePrefix moved to C_ChatInfo
local _RegisterPrefix = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
local _SendAddonMessage = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage

_RegisterPrefix(MSG_PREFIX)

local function Print(msg)
    print("|cffff9900[FoodPolice]|r " .. msg)
end

local function ShortName(name)
    return name and (name:match("^([^%-]+)") or name) or nil
end

local function GetUnitShortName(unit)
    return ShortName(UnitName(unit))
end

local function HasFoodBuff(unit)
    for i = 1, 40 do
        local name = UnitAura(unit, i, "HELPFUL")
        if not name then break end
        if name == "Well Fed" then return true end
    end
    return false
end

local function FindUnitForName(targetName)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local uid = "raid" .. i
            if GetUnitShortName(uid) == targetName then return uid end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local uid = "party" .. i
            if GetUnitShortName(uid) == targetName then return uid end
        end
    end
    return nil
end

local function CheckAndYell(targetName)
    local now = GetTime()
    if now - lastYellTime < YELL_COOLDOWN then return end
    local unit = FindUnitForName(targetName)
    if not unit then return end
    local hasBuff = HasFoodBuff(unit)
    if not hasBuff then
        local msg = YELLS[math.random(#YELLS)]
        local fullMsg = targetName .. "! " .. msg
        lastYellTime = now
        local channel = IsInRaid() and "RAID" or "PARTY"
        C_Timer.After(0, function()
            local eb = DEFAULT_CHAT_FRAME.editBox
            local savedType = eb:GetAttribute("chatType")
            local savedTarget = eb:GetAttribute("chatTarget")
            local ok, err = pcall(SendChatMessage, fullMsg, channel)
            if not ok then
                Print("Chat error: " .. tostring(err))
            else
                pcall(function()
                    eb:SetAttribute("chatType", savedType)
                    eb:SetAttribute("chatTarget", savedTarget)
                end)
            end
        end)
    end
end

local function CheckAll()
    if not FoodPoliceDB.targets then return end
    for name in pairs(FoodPoliceDB.targets) do
        CheckAndYell(name)
        if GetTime() - lastYellTime < YELL_COOLDOWN then break end
    end
end

local function AmILeader()
    return UnitIsGroupLeader("player")
end

local function SenderIsLeader(senderName)
    local short = ShortName(senderName)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name and ShortName(name) == short then
                return rank == 2  -- 2 = raid leader
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local uid = "party" .. i
            if GetUnitShortName(uid) == short then
                return UnitIsGroupLeader(uid)
            end
        end
    end
    return false
end

local function BroadcastVersion()
    if not IsInGroup() then return end
    local channel = IsInRaid() and "RAID" or "PARTY"
    _SendAddonMessage(MSG_PREFIX, "VER:" .. ADDON_VERSION, channel)
end

local function PushToGroup()
    if not AmILeader() then
        Print("Only the raid/party leader can push the watch list.")
        return
    end
    if not IsInGroup() then
        Print("You are not in a group.")
        return
    end
    local channel = IsInRaid() and "RAID" or "PARTY"
    local names = {}
    for name in pairs(FoodPoliceDB.targets) do
        table.insert(names, name)
    end
    if #names == 0 then
        _SendAddonMessage(MSG_PREFIX, "CLEAR", channel)
        Print("Pushed CLEAR to the " .. channel:lower() .. ".")
    else
        _SendAddonMessage(MSG_PREFIX, "SET:" .. table.concat(names, ","), channel)
        Print("Pushed " .. #names .. " target(s) to the " .. channel:lower() .. ".")
    end
end

-- Config window
local configFrame = nil
local rowPool = {}

local function RefreshConfigList()
    if not configFrame then return end
    for _, row in ipairs(rowPool) do row:Hide() end
    local names = {}
    for name in pairs(FoodPoliceDB.targets) do table.insert(names, name) end
    table.sort(names)
    local content = configFrame.listContent
    local ROW_H = 24
    for i, name in ipairs(names) do
        local row = rowPool[i]
        if not row then
            row = CreateFrame("Frame", nil, content)
            row:SetSize(248, ROW_H)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.label:SetPoint("LEFT", 4, 0)
            row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.removeBtn:SetSize(52, 18)
            row.removeBtn:SetPoint("RIGHT", -2, 0)
            row.removeBtn:SetText("Remove")
            rowPool[i] = row
        end
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row.label:SetText(name)
        local n = name
        row.removeBtn:SetScript("OnClick", function()
            FoodPoliceDB.targets[n] = nil
            RefreshConfigList()
        end)
        row:Show()
    end
    content:SetHeight(math.max(#names * ROW_H, 1))
    configFrame.emptyText:SetShown(#names == 0)
end

local aboutFrame = nil

local function ToggleAbout()
    if not aboutFrame then
        local af = CreateFrame("Frame", "FoodPoliceAbout", UIParent, "BackdropTemplate")
        af:SetSize(260, 295)
        af:SetPoint("CENTER")
        af:SetFrameStrata("DIALOG")
        af:SetFrameLevel(20)
        af:SetMovable(true)
        af:EnableMouse(true)
        af:RegisterForDrag("LeftButton")
        af:SetScript("OnDragStart", af.StartMoving)
        af:SetScript("OnDragStop", af.StopMovingOrSizing)
        af:SetBackdrop({
            bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        af:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        af:SetBackdropBorderColor(0.6, 0.4, 0.1, 1)

        local title = af:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Food Police v" .. ADDON_VERSION)

        local closeBtn = CreateFrame("Button", nil, af, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() af:Hide() end)

        local body = af:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        body:SetPoint("TOPLEFT", 14, -36)
        body:SetPoint("BOTTOMRIGHT", af, "BOTTOMRIGHT", -14, 10)
        body:SetJustifyH("LEFT")
        body:SetJustifyV("TOP")
        body:SetSpacing(4)
        body:SetText(
            "Yells at raiders missing Well Fed\n" ..
            "when a Ready Check is called.\n\n" ..
            "|cffff9900HOW TO USE:|r\n" ..
            "1. Add players to the watch list\n" ..
            "2. Leader calls a Ready Check\n" ..
            "3. The unfed get yelled at\n\n" ..
            "|cffff9900COMMANDS:|r\n" ..
            "/fp config  \226\128\148 open this window\n" ..
            "/fp add     \226\128\148 add your target\n" ..
            "/fp push    \226\128\148 sync list to group\n" ..
            "/fp check   \226\128\148 force check now\n" ..
            "/fp who     \226\128\148 version check\n" ..
            "/fp test    \226\128\148 preview a yell"
        )

        aboutFrame = af
    end
    if aboutFrame:IsShown() then aboutFrame:Hide() else aboutFrame:Show() end
end

local function OpenConfig()
    if not configFrame then
        local f = CreateFrame("Frame", "FoodPoliceConfig", UIParent, "BackdropTemplate")
        f:SetSize(300, 432)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("DIALOG")
        f:SetBackdrop({
            bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        f:SetBackdropBorderColor(0.6, 0.4, 0.1, 1)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText("Food Police")

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local listLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        listLabel:SetPoint("TOPLEFT", 12, -36)
        listLabel:SetText("Watch List:")

        local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -52)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 112)

        local content = CreateFrame("Frame", nil, scroll)
        content:SetWidth(248)
        content:SetHeight(1)
        scroll:SetScrollChild(content)
        f.listContent = content

        local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        emptyText:SetPoint("TOPLEFT", 4, -6)
        emptyText:SetText("(empty — use Add below or /fp add <name>)")
        f.emptyText = emptyText

        local addLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        addLabel:SetPoint("BOTTOMLEFT", 12, 88)
        addLabel:SetText("Add Player:")

        local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        editBox:SetSize(158, 20)
        editBox:SetPoint("BOTTOMLEFT", 12, 66)
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(50)

        local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        addBtn:SetSize(46, 22)
        addBtn:SetPoint("LEFT", editBox, "RIGHT", 6, 0)
        addBtn:SetText("Add")

        local targetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        targetBtn:SetSize(68, 22)
        targetBtn:SetPoint("LEFT", addBtn, "RIGHT", 4, 0)
        targetBtn:SetText("Target")
        targetBtn:SetScript("OnClick", function()
            local name = ShortName(UnitName("target"))
            if name then
                FoodPoliceDB.targets[name] = true
                RefreshConfigList()
                Print("Now watching: " .. name)
            else
                Print("No target selected.")
            end
        end)

        local function DoAdd()
            local name = editBox:GetText():match("^%s*(.-)%s*$")
            if name and name ~= "" then
                FoodPoliceDB.targets[name] = true
                editBox:SetText("")
                RefreshConfigList()
            end
        end
        editBox:SetScript("OnEnterPressed", DoAdd)
        addBtn:SetScript("OnClick", DoAdd)

        local ncCheck = CreateFrame("CheckButton", "FoodPoliceNoodleCheck", f, "UICheckButtonTemplate")
        ncCheck:SetSize(24, 24)
        ncCheck:SetPoint("BOTTOMLEFT", 12, 38)
        ncCheck:SetChecked(FoodPoliceDB.noodleCartEnabled)
        ncCheck:SetScript("OnClick", function(self)
            FoodPoliceDB.noodleCartEnabled = self:GetChecked()
        end)
        local ncLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ncLabel:SetPoint("LEFT", ncCheck, "RIGHT", 2, 0)
        ncLabel:SetText("Noodle Cart Alerts (leader/assist)")
        f.noodleCheck = ncCheck

        local pushBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        pushBtn:SetSize(70, 22)
        pushBtn:SetPoint("BOTTOMLEFT", 12, 8)
        pushBtn:SetText("Push")
        pushBtn:SetScript("OnClick", PushToGroup)

        local checkBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        checkBtn:SetSize(60, 22)
        checkBtn:SetPoint("LEFT", pushBtn, "RIGHT", 4, 0)
        checkBtn:SetText("Check")
        checkBtn:SetScript("OnClick", function() lastYellTime = 0; CheckAll() end)

        local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        clearBtn:SetSize(60, 22)
        clearBtn:SetPoint("LEFT", checkBtn, "RIGHT", 4, 0)
        clearBtn:SetText("Clear All")
        clearBtn:SetScript("OnClick", function()
            FoodPoliceDB.targets = {}
            RefreshConfigList()
        end)

        local aboutBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        aboutBtn:SetSize(52, 22)
        aboutBtn:SetPoint("LEFT", clearBtn, "RIGHT", 4, 0)
        aboutBtn:SetText("About")
        aboutBtn:SetScript("OnClick", ToggleAbout)

        configFrame = f
    end
    if configFrame.noodleCheck then
        configFrame.noodleCheck:SetChecked(FoodPoliceDB.noodleCartEnabled)
    end
    RefreshConfigList()
    configFrame:Show()
end

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("READY_CHECK")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            FoodPoliceDB = FoodPoliceDB or {}
            FoodPoliceDB.targets = FoodPoliceDB.targets or {}
            if FoodPoliceDB.noodleCartEnabled == nil then FoodPoliceDB.noodleCartEnabled = true end
            Print("Loaded v" .. ADDON_VERSION .. ". Type /fp for help.")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        peerVersions = {}
        C_Timer.After(5, BroadcastVersion)

    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = arg1, arg2, arg3, arg4
        if prefix ~= MSG_PREFIX then return end

        -- Version broadcast: accept from anyone in the group
        if message:sub(1, 4) == "VER:" then
            local ver = message:sub(5)
            local name = ShortName(sender)
            peerVersions[name] = ver
            if ParseVersion(ver) > ParseVersion(ADDON_VERSION) then
                Print(name .. " has v" .. ver .. " (you have v" .. ADDON_VERSION .. ") — consider updating!")
            end
            return
        end

        -- Only accept SET/CLEAR commands from the raid/party leader
        if not SenderIsLeader(sender) then return end

        if message == "CLEAR" then
            FoodPoliceDB.targets = {}
            Print("Watch list cleared by raid leader.")
        elseif message:sub(1, 4) == "SET:" then
            FoodPoliceDB.targets = {}
            for name in message:sub(5):gmatch("[^,]+") do
                if name ~= "" then
                    FoodPoliceDB.targets[name] = true
                end
            end
            local count = 0
            for _ in pairs(FoodPoliceDB.targets) do count = count + 1 end
            Print("Watch list updated by raid leader (" .. count .. " target(s)).")
        end

    elseif event == "READY_CHECK" then
        lastYellTime = 0
        CheckAll()

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, _, sourceName, _, _, _, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()
        if subevent == "SPELL_CAST_SUCCESS" and spellName then
            if noodleDebug then
                Print("[NoodleDebug] SPELL_CAST_SUCCESS: " .. tostring(spellName) .. " by " .. tostring(sourceName))
            end
            local lower = spellName:lower()
            if lower:find("noodle", 1, true) or lower:find("pandaren banquet", 1, true) or lower:find("grand banquet", 1, true) then
                AnnounceNoodleCart(ShortName(sourceName))
            end
        end
    end
end)

-- Slash commands
SLASH_FOODPOLICE1 = "/foodpolice"
SLASH_FOODPOLICE2 = "/fp"

SlashCmdList["FOODPOLICE"] = function(input)
    local cmd, arg = input:match("^(%S+)%s*(.*)$")
    cmd = cmd and cmd:lower() or ""

    if cmd == "add" and arg ~= "" then
        FoodPoliceDB.targets[arg] = true
        Print("Now watching: " .. arg)
        if configFrame and configFrame:IsShown() then RefreshConfigList() end

    elseif cmd == "add" then
        local name = ShortName(UnitName("target"))
        if name then
            FoodPoliceDB.targets[name] = true
            Print("Now watching: " .. name)
            if configFrame and configFrame:IsShown() then RefreshConfigList() end
        else
            Print("No target selected. Usage: /fp add <name>")
        end

    elseif cmd == "remove" and arg ~= "" then
        FoodPoliceDB.targets[arg] = nil
        Print("Removed: " .. arg)

    elseif cmd == "list" then
        local count = 0
        Print("Watch list:")
        for name in pairs(FoodPoliceDB.targets) do
            print("  - " .. name)
            count = count + 1
        end
        if count == 0 then print("  (empty - use /fp add <name>)") end

    elseif cmd == "push" then
        PushToGroup()

    elseif cmd == "check" then
        lastYellTime = 0
        CheckAll()
        Print("Checked all targets.")

    elseif cmd == "test" then
        local testMsg = YELLS[math.random(#YELLS)]
        Print("Test yell: " .. testMsg)

    elseif cmd == "clear" then
        FoodPoliceDB.targets = {}
        Print("Watch list cleared locally. Use /fp push to clear everyone else's.")

    elseif cmd == "config" or cmd == "ui" then
        OpenConfig()

    elseif cmd == "noodletest" then
        AnnounceNoodleCart(GetUnitShortName("player"))
        Print("Noodle cart test fired (check if you are leader/assist in a raid).")

    elseif cmd == "noodledebug" then
        noodleDebug = not noodleDebug
        Print("Noodle cart debug " .. (noodleDebug and "|cff00ff00ON|r — every SPELL_CAST_SUCCESS will be printed." or "|cffff0000OFF|r"))

    elseif cmd == "who" then
        BroadcastVersion()
        Print("FoodPolice v" .. ADDON_VERSION .. " — group version check:")
        print("  - You: v" .. ADDON_VERSION)
        local count = 0
        for name, ver in pairs(peerVersions) do
            local flag = ParseVersion(ver) > ParseVersion(ADDON_VERSION) and " (newer!)" or ""
            print("  - " .. name .. ": v" .. ver .. flag)
            count = count + 1
        end
        if count == 0 then
            print("  (no responses yet — wait a moment and run /fp who again)")
        end

    else
        Print("Commands:")
        print("  /fp config        - Open the configuration window")
        print("  /fp add <name>    - Add a player to your watch list")
        print("  /fp remove <name> - Remove a player")
        print("  /fp list          - Show current watch list")
        print("  /fp push          - [Leader] Send your list to the whole group")
        print("  /fp check         - Force-check all targets now")
        print("  /fp test          - Preview a random yell")
        print("  /fp clear         - Clear your local list")
        print("  /fp who           - Show which group members have FoodPolice")
    end
end
