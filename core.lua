XPC = LibStub("AceAddon-3.0"):NewAddon("ZUI_XPChart")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_XPChartLocale")
local XPC_GUI = LibStub("AceGUI-3.0")

local defaults = {
    realm = {

    }
}

SLASH_XPC1 = "/xpc"

SlashCmdList["XPC"] = function()
    XPC:CreateUI()
    XPC_GUI.MainFrame:Show()
end

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

    XPC.playerName = GetUnitName("player")
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
        local currXP = UnitXP("player")
        local currLvl = UnitLevel("player")
        local arg1, arg2 = ...
        local timePlayed = arg1 /60 /60/ 24
        if (XPC.db.realm[XPC.playerName] == nil) then
            XPC.db.realm[XPC.playerName] = {}
        end
        table.insert(XPC.db.realm[XPC.playerName], {arg1, currLvl, currXP})
    end
end

function XPC:CreateUI()
    if (XPC_GUI.MainFrame) then
        XPC_GUI.MainFrame:Release()
    end
    XPC_GUI.MainFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    local frame = XPC_GUI.MainFrame
    frame:SetPoint("CENTER")
    frame:SetWidth(1200)
    frame:SetHeight(650)
    XPC:BuildChartLayout()
    local line = frame:CreateLine()
    line:SetColorTexture(0.7,0.7,0.7,.1)
    line:SetStartPoint("TOPLEFT",10,10)
    line:SetEndPoint("BOTTOMRIGHT",10,10)
    XPC_GUI.MainFrame:Hide()
end

function XPC:BuildChartLayout()
    local mostTimePlayed = 0
    local highestLevel = 0
    for i,v in pairs(XPC.db.realm) do
        for j, k in ipairs(v) do
            if (k[1] > mostTimePlayed) then mostTimePlayed = k[1] end
            if (k[2] > highestLevel) then highestLevel = k[2] end
        end
    end
    local lastTimePoint = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    lastTimePoint:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
    lastTimePoint:SetText(mostTimePlayed /60/60/24)
    lastTimePoint:SetPoint("BOTTOMLEFT", 1200, 0)

    local lastLevelPoint = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    lastLevelPoint:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
    lastLevelPoint:SetText(highestLevel)
    lastLevelPoint:SetPoint("BOTTOMLEFT", 0, 650)

end


--make display widget