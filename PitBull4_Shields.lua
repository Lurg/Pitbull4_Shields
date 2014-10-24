local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Shields requires PitBull4")
end

local EXAMPLE_VALUE = 5827

local L = PitBull4.L

local PitBull4_Shields = PitBull4:NewModule("Shields", "AceEvent-3.0")

PitBull4_Shields:SetModuleType("bar")
PitBull4_Shields:SetName(L["Shields"])
PitBull4_Shields:SetDescription(L["Display bars for remaining amount of shielding on the unit"])
PitBull4_Shields.allow_animations = true
PitBull4_Shields:SetDefaults({
	enabled = false,
	first = true,
	hide_empty = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local guids_to_update = {}

-- TODO: We are leaking elements in max_shields if there are active shields on a player when you stop receiving events for them; in other words if you miss the "UNIT_ABSORB_AMOUNT_CHANGED" that clears the shield, then that'll be leaked if you don't see subsequent events on that GUID
local max_shields = {} -- Mapping of GUID -> max_shield

timerFrame:SetScript("OnUpdate", function()
    for guid in pairs(guids_to_update) do
        PitBull4_Shields:UpdateForGUID(guid)
    end
    wipe(guids_to_update)
end)

function PitBull4_Shields:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
    local guid = UnitGUID(unit)
    if guid then
        guids_to_update[guid] = true
    end
end

function PitBull4_Shields:OnEnable()
	timerFrame:Show()
    self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
end

function PitBull4_Shields:OnDisable()
	timerFrame:Hide()
    self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
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
function PitBull4_Shields:GetValue(frame)
    local dstGUID = UnitGUID(frame.unit)

    if not dstGUID then return 0 end

    local max = max_shields[dstGUID] or 0
    local cur = UnitGetTotalAbsorbs(frame.unit) or 0

    if cur > max or cur == 0 then
        max = cur
        max_shields[dstGUID] = max
    end

    local db = self:GetLayoutDB(frame)

    if max == 0 then
        max_shields[dstGUID] = nil
        return not db.hide and 0
    end

    return cur / max
end


function PitBull4_Shields:GetExampleValue(frame)
	return EXAMPLE_VALUE
end


function PitBull4_Shields:GetColor(frame, value)
	return 1, 1, 1
end


PitBull4_Shields:SetLayoutOptionsFunction(function(self)
	return "hide_empty", {
		name = L["Hide empty bar"],
		desc = L["Check this to hide the Shields bar if empty"],
        type = "toggle",
		get = function(info)
			local bar_db = PitBull4.Options.GetLayoutDB(self)
			return bar_db and bar_db.hide
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetLayoutDB(self)
			bar_db.hide = value

			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	}
end)

