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
}

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

-- Event frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("READY_CHECK")

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            FoodPoliceDB = FoodPoliceDB or {}
            FoodPoliceDB.targets = FoodPoliceDB.targets or {}
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
