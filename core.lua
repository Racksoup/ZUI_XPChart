XPC = LibStub("AceAddon-3.0"):NewAddon("ZUI_XPChart")
local L = LibStub("AceLocale-3.0"):GetLocale("ZUI_XPChartLocale")
local XPC_GUI = LibStub("AceGUI-3.0")

local defaults = {
    
}

function XPC:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ZUI_XPChartDB", defaults, true)
end

--get time played on loggin and every 30min, if not lvl 60

--save time played and current xp to realm data under each characters own name

--make display widget