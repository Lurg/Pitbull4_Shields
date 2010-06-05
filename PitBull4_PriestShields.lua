if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PriestShields requires PitBull4")
end


local function debug (...)
	SSS:Print(...)
end



local L = PitBull4.L

local PitBull4_PriestShields = PitBull4:NewModule("PriestShields")

PitBull4_PriestShields:SetModuleType("bar_provider")
PitBull4_PriestShields:SetName("PriestShields")
PitBull4_PriestShields:SetDescription("Display bars for remaining amount of priest shielding (PW:S and DA) on the unit")
PitBull4_PriestShields:SetDefaults({
	enabled = false,
	first = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
	PitBull4_PriestShields:UpdateAll()
end)

function PitBull4_PriestShields:OnEnable()
	timerFrame:Show()

--  If/when we track the shields ourself instead of using LightMeter, then we'll need to do these, and implement the handlers

--	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
--	self:RegisterEvent("UNIT_SPELLCAST_SENT")
--	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

end


-- Event handlers for the various types
--function PitBull4_PriestShields:UNIT_SPELLCAST_SUCCEEDED(event, ...)
--end
--function PitBull4_PriestShields:UNIT_SPELLCAST_SENT(event, ...)
--end
--function PitBull4_PriestShields:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
--end


function PitBull4_PriestShields:OnDisable()
	timerFrame:Hide()
end


function PitBull4_PriestShields:OnNewLayout(layout)
	local layout_db = self.db.profile.layouts[layout]
	
	if layout_db.first then
		layout_db.first = false
		local default_bar = layout_db.elements[L["Default"]]
		default_bar.exists = true
	end
end


-- Need to return a value between 0 and 1 representing the %age of shield that's left
-- To do this, we need to know what the max vale of the shield was, when it went up, as well as the current value
-- This is mildly trickified because DA can get topped up by subsequent procs, but that's fine
function PitBull4_PriestShields:GetValue(frame, bar_db)
	if not frame.unit then return end
	local unitName = GetUnitName(frame.unit)
	local currentPWS = LightMeter_ShieldTable[unitName]
	local maxPWS = LightMeter_MaxShieldTable[unitName]
	local currentDA = LightMeter_DivineAegisTable[unitName]
	local maxDA = LightMeter_MaxDATable[unitName]

	if (not maxPWS) and (not maxDA) then
		return not bar_db.hide and 0 -- no shields are up, maybe hide when empty
	end

	-- IF we got here, then at least one shield is up

	local currentShield = (currentPWS or 0) + (currentDA or 0)
	local maxShield = (maxPWS or 0) + (maxDA or 0)

	return currentShield / maxShield
end


function PitBull4_PriestShields:GetExampleValue(frame, bar_db)
	return 1
end


function PitBull4_PriestShields:GetColor(frame, bar_db, value)
	return 1, 1, 1
end
 
 
PitBull4_PriestShields:SetLayoutOptionsFunction(function(self)
	return
	
	"hide_empty", {
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

