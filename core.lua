XPC = LibStub("AceAddon-3.0"):NewAddon("ZUI_XPChart")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_XPChartLocale")
local XPC_GUI = LibStub("AceGUI-3.0")

local defaults = {
    realm = {
        showGraphLine = {},
        playerLineColor = {},
        data = {},
        XPToLevelClassic = {
            250,    655,    1265,   2085,   3240,   4125,   4785,   5865,   7275,   8205,   -- 1-10
            9365,   10715,  12085,  13455,  14810,  16135,  17415,  18635,  19775,  20825,  -- 11-20
            22295,  23745,  25170,  26550,  27885,  30140,  32480,  34910,  37425,  40675,  -- 21-30
            44100,  47705,  51490,  55460,  59625,  63985,  68545,  73305,  78280,  83460,  -- 31-40
            88860,  94485,  100330, 106405, 112715, 119265, 129995, 139665, 154075, 194030, -- 41-50
            212870, 225770, 240255, 255180, 272795, 291495, 311490, 332165, 353410         -- 51-60
        },
    }
}

SLASH_XPC1 = "/xpc"

SlashCmdList["XPC"] = function()
    RequestTimePlayed()
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
            C_Timer.After(900, function() TimePlayedEvery30() end)
        end
        C_Timer.After(150, function() TimePlayedEvery30() end)
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
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
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
                        if (k[2] > highestLevel) then highestLevel = k[2] XPOnLastLvl = 0 end
                        if (k[2] == highestLevel) then 
                            if (k[3] > XPOnLastLvl) then XPOnLastLvl = k[3]  end
                        end
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
    XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOfHighest, XPOfHighestLevel, frameWidth)
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
    XPC_GUI.MainFrame.SideFrame:SetMovable(true)
    XPC_GUI.MainFrame.SideFrame:EnableMouse(true)
    XPC_GUI.MainFrame.SideFrame:RegisterForDrag("LeftButton")
    XPC_GUI.MainFrame.SideFrame:SetScript("OnDragStart", function(self)
        self:StartMoving()
      end)
    XPC_GUI.MainFrame.SideFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
      end)
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
    local offset = 10
    
    line:SetColorTexture(LC[1], LC[2], LC[3], LC[4])
    line:SetStartPoint("BOTTOMLEFT", frameWidthInterval * StartTime + offset, frameHeightInterval * StartXP + offset )
    line:SetEndPoint("BOTTOMLEFT", frameWidthInterval * EndTime + offset, frameHeightInterval * EndXP + offset )
    
end

function XPC:BuildXAxis(mostTimePlayed, mostDaysPlayed, frameWidthInterval, frameHeight)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points
    local mostDaysPlayed = mostDaysPlayed
    if (mostDaysPlayed < 5) then
        mostDaysPlayed = XPC:StoD(mostTimePlayed)

        local numOfTextObjs = 0
        local modNum = 0
        local alignLines = 8
        local offset = 10

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
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(math.floor(10 * (mostDaysPlayed * 24) * (i / numOfTextObjs)) /10)
            fstring:SetPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) - alignLines + offset, 4)
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) + alignLines + offset, 0)
            line:SetEndPoint("TOPLEFT", frameWidthInterval * XPC:DtoS(mostDaysPlayed) * (i / numOfTextObjs) + alignLines + offset, -20)
        end
    else
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
    
end

function XPC:BuildYAxis(highestLevel, frameHeightInterval, totalXPOfHighest, XPOfHighestLevel, frameWidth)
    -- find spacing. we want to divide by 5 then 4 then 3 then 2 trying to find a mod% full remainder value
    -- if mod == division
    -- else go with divide by 4 and decimal points

    local alignLines = 5
    local offset = 6

    if (highestLevel < 60) then
        local numOfTextObjs = 0
        local modNum = 0

        -- mod highestLevel from 15 to 1.
        for i=15, 0, -1 do      
            modNum = highestLevel % i
            -- if modNum is 0 break the loop and set numOfTextObjs to i 
            if (modNum == 0) then
                -- if we reach 1 numOfTextObjs should be 4
                if (i <= 4) then numOfTextObjs = 8 
                else numOfTextObjs = i end
                break
            end 
        end
        
        
        -- make y-axis text
        local x 
        if (highestLevel < 5) then
            x = 1
        elseif (highestLevel < 10) then
            x = 3
        else
            x = 4
        end

        for i = x, numOfTextObjs do 
            local totalXPOfGraphIndex = 0
            local lineLevelPercentage = (i / numOfTextObjs)
            for j = 2, (highestLevel * lineLevelPercentage) do 
                totalXPOfGraphIndex = totalXPOfGraphIndex + XPC.db.realm.XPToLevelClassic[j -1]
            end
            local fstring = XPC_GUI.MainFrame:CreateFontString(nil, "OVERLAY", "GameToolTipText")
            fstring:SetFont("Fonts\\FRIZQT__.TTF", 20, "THINOUTLINE")
            fstring:SetText(highestLevel * lineLevelPercentage)

            fstring:SetPoint("BOTTOMLEFT", 5, frameHeightInterval * totalXPOfGraphIndex -alignLines + offset)
            local line = XPC_GUI.MainFrame:CreateLine()
            line:SetColorTexture(0.7,0.7,0.7,.1)
            line:SetStartPoint("BOTTOMLEFT", 0, frameHeightInterval * totalXPOfGraphIndex +alignLines + offset)
            line:SetEndPoint("BOTTOMRIGHT", 0, frameHeightInterval * totalXPOfGraphIndex +alignLines + offset)
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


-- reset all data button
-- make for tbc and wrath

-- change how often timeout is called