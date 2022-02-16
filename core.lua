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
XPToLevelClassic = {
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
    if (XPC_GUI.MainFrame) then XPC_GUI.MainFrame:Hide() XPC_GUI.MainFrame = {} end
    XPC_GUI.MainFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    local frame = XPC_GUI.MainFrame
    frame:SetPoint("CENTER")
    frame:SetWidth(1200)
    frame:SetHeight(650)
    XPC:BuildChartLayout()
    XPC_GUI.MainFrame:Hide()
end

function XPC:BuildChartLayout()
    local mostTimePlayed = 0
    local highestLevel = 0
    local XPOnLastLvl = 0
    local XPOfHighestLevel = 0
    local totalXPOfHighest = 0
    -- find and save highest amount of time played on any character, highest level of any character
    for i,v in pairs(XPC.db.realm) do
        for j, k in ipairs(v) do
            if (k[1] > mostTimePlayed) then mostTimePlayed = k[1] end
            if (k[2] > highestLevel) then highestLevel = k[2] XPOnLastLvl = k[3] end
        end
    end

    -- save total amout of xp in highest lvl
    for i = 1, highestLevel do 
        XPOfHighestLevel = XPOfHighestLevel + XPToLevelClassic[i]
    end
    
    -- save total amout of xp on highest xp character
    totalXPOfHighest = XPOfHighestLevel + XPOnLastLvl

    local frameWidth = 1150
    local frameHeight = 600
    local frameWidthInterval = frameWidth / mostTimePlayed 
    local frameHeightInterval = frameHeight / totalXPOfHighest
    local mostDaysPlayed = math.floor(XPC:StoD(mostTimePlayed))
    print(mostDaysPlayed)
    

    XPC:BuildXAxis(mostTimePlayed, mostDaysPlayed, frameWidthInterval, frameHeight)
    XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOHighest, XPOfHighestLevel, frameWidth)
end

function XPC:StoD(val)
    return val / 60 / 60 / 24
end

function XPC:DtoS(val)
    return val * 60 * 60 * 24
end

function XPC:BuildXAxis(mostTimePlayed, mostDaysPlayed, frameWidthInterval, frameHeight)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points
    if (mostDaysPlayed > 5) then
        local numOfTextObjs = 0
        local modNum = 0

        -- mod mostDaysPlayed from 5 to 1.
        for i=5, 0, -1 do      
            modNum = mostDaysPlayed % i
            -- if modNum is 0 break the loop and set numOfTextObjs to i 
            if (modNum == 0) then
                -- if we reach 1 numOfTextObjs should be 4
                if (i == 1) then numOfTextObjs = 4 
                else numOfTextObjs = i end
                break
            end 
        end
        
        -- print x-axis text
        for i=1, numOfTextObjs do 
            local fstring = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameToolTipText")
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(mostDaysPlayed * (i / numOfTextObjs))
            fstring:SetPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs), 0)
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs), 0)
            line:SetEndPoint("TOPLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs), 0)
        end
    end
end

function XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOfHighest, XPOfHighestLevel, frameWidth)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points
    if (highestLevel < 60) then
        local numOfTextObjs = 0
        local modNum = 0

        -- mod highestLevel from 15 to 1.
        for i=15, 0, -1 do      
            modNum = highestLevel % i
            -- if modNum is 0 break the loop and set numOfTextObjs to i 
            if (modNum == 0) then
                -- if we reach 1 numOfTextObjs should be 4
                if (i == 2) then numOfTextObjs = 4 
                else numOfTextObjs = i end
                break
            end 
        end
        
        -- print y-axis text
        for i=1, numOfTextObjs do 
            local fstring = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameToolTipText")
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(highestLevel * (i / numOfTextObjs))
            fstring:SetPoint("BOTTOMLEFT", 0, frameHeightInterval * XPOfHighestLevel* (i / numOfTextObjs))
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", 0, frameHeightInterval * XPOfHighestLevel* (i / numOfTextObjs))
            line:SetEndPoint("BOTTOMRIGHT", 0, frameHeightInterval * XPOfHighestLevel* (i / numOfTextObjs))
        end
    end
end

-- make sample data
-- for each data point in the line, make a line from connecting 2 points (1-2, 2-3, 3-4, 4-5)
--set data lines