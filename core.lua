XPC = LibStub("AceAddon-3.0"):NewAddon("ZUI_XPChart")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_XPChartLocale")
local XPC_GUI = LibStub("AceGUI-3.0")

local defaults = {
    realm = {

    }
}

-- all xp to level 1-60 Classic WoW
local XPToLevelClassic = {
    400,    900,    1400,   2100,   2800,   3600,   4500,   5400,   6500,   7600, -- 1-10
    8800,   10100,  11400,  12900,  14400,  16000,  17700,  19400,  21300,  23200, -- 11- 20
    25200,  27300,  29400,  31700,  34000,  36400,  38900,  41400,  44300,  47400, -- 21-30
    50800,  54500,  58600,  62800,  67100,  71600,  76100,  80800,  85700,  90700, -- 31-40
    95800,  101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500, -- 41-50
    153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800, 217400 -- 51-60
}

function XPC:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ZUI_XPChartDB", defaults, true)
    -- self.db:ResetDB()

    -- only register if the player is less than lvl 60
    local currLvl = UnitLevel("player")
    if (currLvl < 60) then
        -- register timeplayedmsg and a script for its event
        XPC_GUI.scripts = CreateFrame("Frame")
        XPC_GUI.scripts:RegisterEvent("TIME_PLAYED_MSG")
        XPC_GUI.scripts:SetScript("OnEvent", function(self, event, ...) XPC:OnTimePlayedMsg(self, event, ...) end)
        -- requesttimeplayed every 30min, works on login too
        function TimePlayedEvery30()
            RequestTimePlayed() 
            C_Timer.After(1800, function() TimePlayedEvery30() end)
        end
        TimePlayedEvery30()
    end
end

function XPC:OnTimePlayedMsg(self, event, ...)
    if (event == "TIME_PLAYED_MSG") then
        local playerName = GetUnitName("player")
        local currXP = UnitXP("player")
        local currLvl = UnitLevel("player")
        local arg1, arg2 = ...
        local timePlayed = arg1 /60 /60/ 24
        if (XPC.db.realm[playerName] == nil) then
            XPC.db.realm[playerName] = {}
        end
        table.insert(XPC.db.realm[playerName], {arg1, currLvl, currXP})
    end
end

--get time played on loggin and every 30min, if not lvl 60

--save time played and current xp to realm data under each characters own name

--make display widget