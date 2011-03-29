if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Shields requires PitBull4")
end

local EXAMPLE_VALUE = 0.3

local L = PitBull4.L

local PitBull4_Shields = PitBull4:NewModule("Shields")

PitBull4_Shields:SetModuleType("bar_provider")
PitBull4_Shields:SetName("Shields")
PitBull4_Shields:SetDescription("Display bars for remaining amount of priest shielding (PW:S and DA) on the unit")
PitBull4_Shields:SetDefaults({
	enabled = false,
	first = true,
	hide_empty = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
	PitBull4_Shields:UpdateAll()
end)


PitBull4_Shields_combatFrame = CreateFrame("Frame")
PitBull4_Shields_combatFrame:Hide()
PitBull4_Shields_combatFrame.shields = {
            -- Priest stuff
            ["Power Word: Shield"] = { max = {}, cur = {} },
            ["Divine Aegis"] = { max = {}, cur = {} },
            -- DK stuff
            ["Blood Shield"] = { max = {}, cur = {} },
            -- Paladin stuff
            ["Illuminated Healing"] = { max = {}, cur = {} },
            ["Sacred Shield"] = { max = {}, cur = {} },
            -- Mage
            ["Mana Shield"] = { max = {}, cur = {} },
            ["Mage Ward"] = { max = {}, cur = {} },
            ["Ice Barrier"] = { max = {}, cur = {} },
            -- Warlock
            ["Shadow Ward"] = { max = {}, cur = {} },
            ["Nether Ward"] = { max = {}, cur = {} },
}
PitBull4_Shields_combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
PitBull4_Shields_combatFrame:SetScript("OnEvent", function(self, event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
--    if(not(srcGUID == UnitGUID("player"))) then return end

   if eventtype == "SPELL_AURA_REFRESH" or
   eventtype == "SPELL_AURA_REMOVED" or eventtype == "SPELL_AURA_APPLIED" then
      spellID,spellName,spellSchool,auraType,auraAmount = select(1,...)
   else
      return
   end
   if self.shields[spellName] then
      if eventtype == "SPELL_AURA_APPLIED" or eventtype == "SPELL_AURA_REFRESH" then
          if eventtype == "SPELL_AURA_APPLIED" then
              self.shields[spellName].max[dstGUID] = auraAmount
          end
          self.shields[spellName].cur[dstGUID] = auraAmount
      elseif eventtype == "SPELL_AURA_REMOVED" then
        self.shields[spellName].max[dstGUID] = nil
        self.shields[spellName].cur[dstGUID] = nil
      end
   end
end)


function PitBull4_Shields:OnEnable()
	timerFrame:Show()
end


function PitBull4_Shields:OnDisable()
	timerFrame:Hide()
end


function PitBull4_Shields:OnNewLayout(layout)
	local layout_db = self.db.profile.layouts[layout]
	
	if layout_db.first then
		layout_db.first = false
		local default_bar = layout_db.elements[L["Default"]]
		default_bar.exists = true
	end
end


-- Need to return a value between 0 and 1 representing the %age of shield that's left
-- To do this, we cycle through all shield types to know what the max vale of the shield was when it went up, as well as the current value
function PitBull4_Shields:GetValue(frame, bar_db)
	if not frame.unit then return end
	local dstGUID = UnitGUID(frame.unit)

    local current=0
    local max = 0
    for shield, shields in pairs(PitBull4_Shields_combatFrame.shields) do
        current = current + (shields.cur[dstGUID] or 0)
        max = max + (shields.max[dstGUID] or 0)
    end

    if(max == 0) then
        return not bar_db.hide and 0 -- no shields are up, maybe hide when empty
    end

	-- IF we got here, then at least one shield is up

	return current / max
end


function PitBull4_Shields:GetExampleValue(frame, bar_db)
	return EXAMPLE_VALUE
end


function PitBull4_Shields:GetColor(frame, bar_db, value)
	return 1, 1, 1
end
 
 
PitBull4_Shields:SetLayoutOptionsFunction(function(self)
	return "hide_empty", {
		type = "toggle",
		name = "Hide empty bar",
		desc = "Check this, to hide the PriestShields if empty.",
		get = function(info)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.hide
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			bar_db.hide = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	}
end)

