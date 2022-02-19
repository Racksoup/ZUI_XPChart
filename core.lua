XPC = LibStub("AceAddon-3.0"):NewAddon("ZUI_XPChart")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_XPChartLocale")
local XPC_GUI = LibStub("AceGUI-3.0")

local defaults = {
    realm = {
        showGraphLine = {},
        playerLineColor = {},
        data = {
            SampleLevels = {
                {345600, 35, 300, 340000},
                {380000, 45, 200, 400000},
                {420000, 45, 200, 480000},
                {450000, 45, 200, 570000},
                {470000, 45, 200, 710000},
                {550000, 45, 200, 860000},
                {570000, 45, 200, 1010000},
                {600000, 45, 200, 1240000},
                {1200000, 45, 200, 1440000},
            },
            OtherLevels = {
                {245600, 35, 300, 210000},
                {280000, 45, 200, 300000},
                {320000, 45, 200, 380000},
                {350000, 45, 200, 470000},
                {470000, 45, 200, 610000},
                {550000, 45, 200, 760000},
                {570000, 45, 200, 810000},
                {600000, 45, 200, 940000},
                {700000, 45, 200, 1040000},
            },
            lessLevels = {
                {100, 5, 300, 1000},
                {2000, 5, 200, 50000},
                {4000, 5, 200, 100000},
                {8000, 5, 200, 150000},
                {16000, 5, 200, 200000},
                {32000, 5, 200, 250000},
                {64000, 5, 200, 300000},
                {128000, 5, 200, 350000},
                {256000, 30, 200, 400000},
                {512000, 30, 200, 450000},
            },
        },
        XPToLevelClassic = {
            400,    900,    1400,   2100,   2800,   3600,   4500,   5400,   6500,   7600, -- 1-10
            8800,   10100,  11400,  12900,  14400,  16000,  17700,  19400,  21300,  23200, -- 11- 20
            25200,  27300,  29400,  31700,  34000,  36400,  38900,  41400,  44300,  47400, -- 21-30
            50800,  54500,  58600,  62800,  67100,  71600,  76100,  80800,  85700,  90700, -- 31-40
            95800,  101000, 106300, 111800, 117500, 123200, 129100, 135100, 141200, 147500, -- 41-50
            153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800, 217400 -- 51-60
        },
    }
}

SLASH_XPC1 = "/xpc"

SlashCmdList["XPC"] = function()
    XPC:CreateUI()
    XPC_GUI.MainFrame:Show()
end

function XPC:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ZUI_XPChartDB", defaults, true)
    --self.db:ResetDB()
    XPC:SetShowGraphLine()

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
            C_Timer.After(60, function() TimePlayedEvery30() end)
        end
        TimePlayedEvery30()
    end
end

function XPC:OnTimePlayedMsg(self, event, ...)
    if (event == "TIME_PLAYED_MSG") then
        local currXP = UnitXP("player")
        local currLvl = UnitLevel("player")
        local arg1, arg2 = ...
        local totalXP = 0
        for i = 1, currLvl -1 do 
            totalXP = totalXP + XPC.db.realm.XPToLevelClassic[i]
        end

        totalXP = totalXP + currXP
        if (XPC.db.realm.data[XPC.playerName] == nil) then
            XPC.db.realm.data[XPC.playerName] = {}
        end
        table.insert(XPC.db.realm.data[XPC.playerName], {arg1, currLvl, currXP, totalXP})
    end
end

function XPC:CreateUI()
    XPC:BuildChartLayout()
    XPC:BuildSideFrameLayout();
    XPC_GUI.MainFrame:Hide()
    XPC_GUI.MainFrame.SideFrame:Hide()
end

function XPC:BuildChartLayout()
    if (XPC_GUI.MainFrame) then XPC_GUI.MainFrame:Hide() XPC_GUI.MainFrame = {} end
    XPC_GUI.MainFrame = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    local frame = XPC_GUI.MainFrame
    frame:SetFrameStrata("HIGH")
    frame:SetPoint("CENTER")
    frame:SetWidth(1200)
    frame:SetHeight(650)
    local button = CreateFrame("Button", nil, XPC_GUI.MainFrame, "UIPanelButtonTemplate")
    button:SetSize(150, 16)
    button:SetPoint("TOPRIGHT", -100, -3)
    button:SetText("Options")
    button:SetScript("OnClick", function() XPC:BuildSideFrameLayout() end)

    local mostTimePlayed = 0
    local highestLevel = 0
    local XPOnLastLvl = 0
    local XPOfHighestLevel = 0
    local totalXPOfHighest = 0
    -- find and save highest amount of time played on any character, highest level of any character
    for i,v in pairs(XPC.db.realm.data) do
        for l, d in pairs (XPC.db.realm.showGraphLine) do 
            if (l == i) then 
                if (d[1] == true) then
                    for j, k in ipairs(v) do
                        if (k[1] > mostTimePlayed) then mostTimePlayed = k[1] end
                        if (k[2] > highestLevel) then highestLevel = k[2] XPOnLastLvl = k[3] end
                    end
                end
            end
        end 
    end


    -- save total amout of xp in highest lvl
    for i = 2, highestLevel do 
        XPOfHighestLevel = XPOfHighestLevel + XPC.db.realm.XPToLevelClassic[i - 1]
    end
    
    -- save total amout of xp on highest xp character
    totalXPOfHighest = XPOfHighestLevel + XPOnLastLvl

    local frameWidth = 1150
    local frameHeight = 590
    local frameWidthInterval = frameWidth / mostTimePlayed 
    local frameHeightInterval = frameHeight / totalXPOfHighest
    local mostDaysPlayed = math.floor(XPC:StoD(mostTimePlayed))

    XPC:BuildXAxis(mostTimePlayed, mostDaysPlayed, frameWidthInterval, frameHeight)
    XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOHighest, XPOfHighestLevel, frameWidth)
    XPC:BuildAllLines(frameWidthInterval, frameHeightInterval)
    
    XPC_GUI.MainFrame:Show()
end

function  XPC:BuildSideFrameLayout()
    local r,g,b,a = 1, 0, 0, 1;
    

    local function myColorCallback(restore)
        local newR, newG, newB, newA;
        if restore then
         -- The user bailed, we extract the old color from the table created by ShowColorPicker.
         newR, newG, newB, newA = unpack(restore);
        else
         -- Something changed
         newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
        end
        
        -- Update our internal storage.
        r, g, b, a = newR, newG, newB, newA;
        -- And update any UI elements that use this color...
        if (XPC.db.realm.playerLineColor[XPC.CurrColorCharacter] == nil) then XPC.db.realm.playerLineColor[XPC.CurrColorCharacter] = {} end
        XPC.db.realm.playerLineColor[XPC.CurrColorCharacter].r = r
        XPC.db.realm.playerLineColor[XPC.CurrColorCharacter].g = g
        XPC.db.realm.playerLineColor[XPC.CurrColorCharacter].b = b
        XPC.db.realm.playerLineColor[XPC.CurrColorCharacter].a = a
        XPC:CreateUI()
        XPC_GUI.MainFrame:Show()
        XPC_GUI.MainFrame.SideFrame:Show()
    end

    if (XPC_GUI.MainFrame.SideFrame) then XPC_GUI.MainFrame.SideFrame:Hide() end
    XPC_GUI.MainFrame.SideFrame = CreateFrame("Frame", nil, XPC_GUI.MainFrame, "BasicFrameTemplateWithInset")
    XPC_GUI.MainFrame.SideFrame:SetPoint("CENTER", 200, 0);
    XPC_GUI.MainFrame.SideFrame:SetWidth(300)
    XPC_GUI.MainFrame.SideFrame:SetHeight(400) 
    local lastbtn
    local firstLoop = true
    for i, v in pairs(XPC.db.realm.data) do
        local color
        local button

        if (XPC.db.realm.playerLineColor[i]) then
            color = {
                XPC.db.realm.playerLineColor[i].r, 
                XPC.db.realm.playerLineColor[i].g, 
                XPC.db.realm.playerLineColor[i].b, 
                XPC.db.realm.playerLineColor[i].a
            }
        else
            color = {0,0,1,1}
        end

        if (firstLoop) then
            button = CreateFrame("Button", v, XPC_GUI.MainFrame.SideFrame, "UIPanelButtonTemplate")
            button:SetPoint("TOPRIGHT", -16 , -40)
            firstLoop = false;
        else
            button = CreateFrame("Button", v, lastbtn, "UIPanelButtonTemplate")
            button:SetPoint("TOP", 0, -30)
        end
        button:SetWidth(100)
        button:SetHeight(20)
        button:SetText("Pick Color")
        button:SetScript("OnClick", function() 
            XPC.CurrColorCharacter = i
           

            XPC:ShowColorPicker(color[1], color[2], color[3], color[4], myColorCallback) 
        end)
        lastbtn = button

        local buttonLabel = button:CreateFontString(nil, "OVERLAY", "GameToolTipText")
        buttonLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "THINOUTLINE")
        buttonLabel:SetPoint("LEFT", -140, 0)
        local fString = string.format("Show - %s", i)
        buttonLabel:SetText(fString)

        local checkbox = CreateFrame("CheckButton", nil, button, "ChatConfigCheckButtonTemplate")
        checkbox:SetPoint("LEFT", -165, 0)
        checkbox:SetSize(20, 20)
        checkbox:SetChecked(XPC.db.realm.showGraphLine[i][1])
        checkbox:SetScript("OnClick", function() 
            XPC.db.realm.showGraphLine[i][1] = not XPC.db.realm.showGraphLine[i][1] 
            XPC:CreateUI()
            XPC_GUI.MainFrame:Show();
            XPC_GUI.MainFrame.SideFrame:Show()
        end)
    end 
    XPC_GUI.MainFrame.SideFrame:Show();
end

function XPC:BuildAllLines(frameWidthInterval, frameHeightInterval)
    for i, v in pairs(XPC.db.realm.data) do
        for j, k in pairs(XPC.db.realm.showGraphLine) do 
            if (i == j) then 
                if(k[1] == true) then 
                    local color
                    if (XPC.db.realm.playerLineColor[i]) then
                        color = {XPC.db.realm.playerLineColor[i].r, XPC.db.realm.playerLineColor[i].g, XPC.db.realm.playerLineColor[i].b, XPC.db.realm.playerLineColor[i].a}
                    else
                        color = {0,0,1,1}
                    end
                    XPC:BuildFullLine(frameWidthInterval, frameHeightInterval, v, color)
                end
            end
        end
    end
end

function XPC:BuildFullLine(frameWidthInterval, frameHeightInterval, DB, lineColor)
    for i, v in ipairs(DB) do
        local StartTime = v[1]
        local StartXP = v[4]
        if (i ~= #DB) then 
            local EndTime = DB[i +1][1]
            local EndXP = DB[i +1][4]
            XPC:BuildALine(frameWidthInterval, frameHeightInterval, StartTime, StartXP, EndTime, EndXP, lineColor)
        end
    end
end

function XPC:BuildALine(frameWidthInterval, frameHeightInterval, StartTime, StartXP, EndTime, EndXP, LC)
    local line = XPC_GUI.MainFrame:CreateLine()
    line:SetColorTexture(LC[1], LC[2], LC[3], LC[4])
    line:SetStartPoint("BOTTOMLEFT", frameWidthInterval * StartTime +10, frameHeightInterval * StartXP +10 )
    line:SetEndPoint("BOTTOMLEFT", frameWidthInterval * EndTime+10, frameHeightInterval * EndXP +10 )
end

function XPC:BuildXAxis(mostTimePlayed, mostDaysPlayed, frameWidthInterval, frameHeight)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points
    local mostDaysPlayed = mostDaysPlayed
    if (mostDaysPlayed < 5) then
        mostDaysPlayed = XPC:StoD(mostTimePlayed)
    end
        local numOfTextObjs = 0
        local modNum = 0

        -- mod mostDaysPlayed from 5 to 1.
        for i=5, 0, -1 do      
            modNum = math.floor(mostDaysPlayed) % i
            -- if modNum is 0 break the loop and set numOfTextObjs to i 
            if (modNum == 0) then
                -- if we reach 1 numOfTextObjs should be 4
                if (i == 1) then numOfTextObjs = 4 
                else numOfTextObjs = i end
                break
            end 
        end

        -- make x-axis text
        for i=1, numOfTextObjs do 
            local fstring = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameToolTipText")
            local offset = 8
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(math.floor(100 * mostDaysPlayed * (i / numOfTextObjs)) /100)
            fstring:SetPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) - offset, 4)
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) + offset, 0)
            line:SetEndPoint("TOPLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) +offset, -20)
        end
    
end

function XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOfHighest, XPOfHighestLevel, frameWidth)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points

    local offset = 5
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
        
        -- make y-axis text
        for i=1, numOfTextObjs do 
            local fstring = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameToolTipText")
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(highestLevel * (i / numOfTextObjs))
            fstring:SetPoint("BOTTOMLEFT", 5, frameHeightInterval * XPOfHighestLevel* (i / numOfTextObjs) -offset)
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", 0, frameHeightInterval * XPOfHighestLevel * (i / numOfTextObjs) +offset)
            line:SetEndPoint("BOTTOMRIGHT", 0, frameHeightInterval * XPOfHighestLevel * (i / numOfTextObjs) +offset)
        end
    end
end

function XPC:SetShowGraphLine() 
    for i, v in pairs (XPC.db.realm.data) do
        local itemFound = false
        for j, k in pairs(XPC.db.realm.showGraphLine) do
            if (i == j) then itemFound = true end
        end
        if (itemFound == false) then 
            XPC.db.realm.showGraphLine[i] = {}
            table.insert(XPC.db.realm.showGraphLine[i], true)
        end
    end
end

function XPC:StoD(val)
    return val / 60 / 60 / 24
end

function XPC:DtoS(val)
    return val * 60 * 60 * 24
end

function XPC:ShowColorPicker(r, g, b, a, changedCallback)
    ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
    ColorPickerFrame.previousValues = {r,g,b,a};
    ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = 
     changedCallback, changedCallback, changedCallback;
    ColorPickerFrame:SetColorRGB(r,g,b);
    ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
    ColorPickerFrame:Show();
end

-- show hours on y-axis under 5days played
-- reset all data button
-- on level expansion bug
-- for tbc and wrath