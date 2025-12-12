-- TotalPlayed (Turtle WoW, Vanilla 1.12 base, Lua 5.0)
-- Tracks played time, quests completed, and deaths across all characters.

local DB

-- Build a stable key for each character: Realm|Faction|Name
local function GetCharKey()
  local name = UnitName("player") or "Unknown"
  local realm = GetCVar("realmName") or "UnknownRealm"
  local faction = UnitFactionGroup("player") or "Neutral"
  return realm .. "|" .. faction .. "|" .. name
end

-- Format seconds into human-readable string: Dd HH:MM:SS
local function FormatSeconds(sec)
  sec = tonumber(sec) or 0
  if sec <= 0 then return "0d 00:00:00" end

  local days = math.floor(sec / 86400)
  sec = math.mod(sec, 86400)

  local hours = math.floor(sec / 3600)
  sec = math.mod(sec, 3600)

  local mins = math.floor(sec / 60)
  local secs = math.mod(sec, 60)

  return string.format("%dd %02d:%02d:%02d", days, hours, mins, secs)
end

-- Safe table length helper (Lua 5.0)
local function tlen(t)
  if type(t) ~= "table" then return 0 end
  return table.getn(t)
end

-- Helper: return class color hex string for given class
local function ClassColorHex(class)
  local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if col then
    return string.format("|cff%02x%02x%02x", col.r*255, col.g*255, col.b*255)
  end
  return "|cffffffff" -- default white
end

-- Build totals across all realms and characters
local function BuildTotals()
  local total = 0
  local byRealm = {}

  for key, info in pairs(DB.characters) do
    local realm, faction, name = string.match(key, "^(.-)|(.+)|(.+)$")
    local sec = tonumber(info.seconds) or 0
    total = total + sec

    byRealm[realm] = byRealm[realm] or { total = 0, characters = {} }
    byRealm[realm].total = byRealm[realm].total + sec
    table.insert(byRealm[realm].characters, {
      name = name,
      faction = faction,
      class = info.class,
      seconds = sec,
      quests = info.quests,
      deaths = info.deaths
    })
  end

  -- Sort characters by played time descending
  for _, bucket in pairs(byRealm) do
    table.sort(bucket.characters, function(a, b) return a.seconds > b.seconds end)
  end

  return total, byRealm
end

-- Print totals and breakdown to chat
local function PrintTotals()
  if not DB or not DB.characters then return end
  local total, byRealm = BuildTotals()

  -- Header text depending on maxShow
  local header
  if DB.maxShow and DB.maxShow > 0 then
    header = string.format("|cff00ff00[TotalPlayed]|r Total account time: %s (Top %d per realm)", FormatSeconds(total), DB.maxShow)
  else
    header = string.format("|cff00ff00[TotalPlayed]|r Total account time: %s (All characters)", FormatSeconds(total))
  end
  DEFAULT_CHAT_FRAME:AddMessage(header)

  for realm, bucket in pairs(byRealm) do
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  |cffccccff%s|r total: %s", realm, FormatSeconds(bucket.total)))
    local maxShow = DB.maxShow
    local count = (maxShow and math.min(maxShow, tlen(bucket.characters)) or tlen(bucket.characters))
    for i = 1, count do
      local c = bucket.characters[i]
      local hex = ClassColorHex(c.class)
      DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "    %s%s|r: %s | Quests: %s | Deaths: %s",
        hex, c.name, FormatSeconds(c.seconds),
        c.quests or "-", c.deaths or "-"
      ))
    end
  end
end

-- Debounced RequestTimePlayed to avoid spam
local lastRequest = 0
local function RequestPlayed()
  local now = GetTime() or 0
  if (now - lastRequest) < 5 then return end
  lastRequest = now
  if RequestTimePlayed then RequestTimePlayed() end
end

-- Event frame
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("TIME_PLAYED_MSG")
f:RegisterEvent("PLAYER_LOGOUT")

-- One-shot login timer (30s after login, print totals)
local loginTimerStarted = false

f:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    -- Initialize database
    TotalPlayedDB = TotalPlayedDB or {}
    DB = TotalPlayedDB
    DB.characters = DB.characters or {}
    DB.maxShow = DB.maxShow or nil -- remember user preference

    -- Request played time immediately
    RequestPlayed()

    -- Start 30s timer to print totals
    if not loginTimerStarted then
      loginTimerStarted = true
      local delayFrame = CreateFrame("Frame")
      local start = GetTime() or 0
      delayFrame:SetScript("OnUpdate", function()
        local now = GetTime() or start
        if (now - start) >= 30 then
          PrintTotals()
          this:SetScript("OnUpdate", nil) -- stop timer
        end
      end)
    end

    -- Slash command: /totalplayed [number]
    SLASH_TOTALPLAYED1 = "/totalplayed"
    SlashCmdList["TOTALPLAYED"] = function(msg)
      local num = tonumber(msg)
      if num and num > 0 then
        DB.maxShow = num
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TotalPlayed]|r Preference saved: Top " .. num .. " per realm.")
      elseif msg == "" or msg == nil then
        -- no argument: just show with current setting
      else
        DB.maxShow = nil -- reset to show all
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TotalPlayed]|r Preference saved: Showing all characters per realm.")
      end
      RequestPlayed()
      PrintTotals()
    end

  elseif event == "TIME_PLAYED_MSG" then
    -- Update current character data when server responds
    local totalSeconds = arg1
    local key = GetCharKey()
    DB.characters[key] = DB.characters[key] or {}
    DB.characters[key].seconds = tonumber(totalSeconds) or 0
    DB.characters[key].lastUpdated = time()

    -- Store class info
    local _, class = UnitClass("player")
    DB.characters[key].class = class

  elseif event == "PLAYER_LOGOUT" then
    -- Try to refresh before logout
    RequestPlayed()
  end
end)

-- Unified handler: parse quests/deaths and hide played lines
local function HandlePlayedLine(msg)
  if not msg then return false end

  -- Parse quests/deaths from Turtle WoW extra line
  local deaths = string.match(msg, "Death counter:%s*(%d+)")
  local quests = string.match(msg, "Quests completed:%s*(%d+)")
  if deaths or quests then
    local key = GetCharKey()
    DB.characters[key] = DB.characters[key] or {}
    if deaths then DB.characters[key].deaths = tonumber(deaths) end
    if quests then DB.characters[key].quests = tonumber(quests) end
  end

  -- Return true if line should be hidden
  return string.find(msg, "Total time played")
      or string.find(msg, "Time played this level")
      or string.find(msg, "Death counter")
      or string.find(msg, "Quests completed")
end

-- Hook all chatframes to intercept /played output
for i = 1, NUM_CHAT_WINDOWS do
  local cf = getglobal("ChatFrame"..i)
  if cf and not cf.__TotalPlayedHooked then
    local orig = cf.AddMessage
    cf.AddMessage = function(self, msg, r, g, b, id)
      if HandlePlayedLine(msg) then return end
      return orig(self, msg, r, g, b, id)
    end
    cf.__TotalPlayedHooked = true
  end
end
