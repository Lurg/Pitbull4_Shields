if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Shields requires PitBull4")
end

local EXAMPLE_VALUE = 0.3

local L = PitBull4.L

local PitBull4_Shields = PitBull4:NewModule("Shields")

PitBull4_Shields:SetModuleType("bar_provider")
PitBull4_Shields:SetName(L["Shields"])
PitBull4_Shields:SetDescription(L["Display bars for remaining amount of shielding on the unit"])
PitBull4_Shields:SetDefaults({
	enabled = false,
	first = true,
	hide_empty = true,
	just_mine = false,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
	PitBull4_Shields:UpdateAll()
end)

PitBull4_Shields_combatFrame = CreateFrame("Frame")
PitBull4_Shields_combatFrame:Hide()
PitBull4_Shields_combatFrame.shields = {

            -- DK stuff
            [48707] = { max = {}, cur = {} }, -- Anti-Magic Shell
            [73975] = { max = {}, cur = {} }, -- Necrotic Strike
            [77535] = { max = {}, cur = {} }, -- Blood Shield
            [115635] = { max = {}, cur = {} }, -- Death Barrier
            [116888] = { max = {}, cur = {} }, -- Shroud of Purgatory

            -- Hunter pet
            [53476] = { max = {}, cur = {} }, -- Intervene

            -- Mage
            [543] = { max = {}, cur = {} }, -- Mage Ward
            [11426] = { max = {}, cur = {} }, -- Ice Barrier
            [98864] = { max = {}, cur = {} }, -- Ice Barrier

            -- Paladin stuff
            [65148] = { max = {}, cur = {} }, -- Sacred Shield
            [86273] = { max = {}, cur = {} }, -- Illuminated Healing
            [88063] = { max = {}, cur = {} }, -- Guarded by the Light
            [105801] = { max = {}, cur = {} }, -- Delayed Judgement

            -- Priest stuff
            [17] = { max = {}, cur = {} }, -- Power Word: Shield
            [47753] = { max = {}, cur = {} }, -- Divine Aegis
            [114214] = { max = {}, cur = {} }, -- Angelic Bulwark
            [114908] = { max = {}, cur = {} }, -- Spirit Shell
            [123258] = { max = {}, cur = {} }, -- Power Word: Shield alternative?

            -- Shaman
            [114893] = { max = {}, cur = {} }, -- Stone Bulwark

            -- Warlock
            [1454] = { max = {}, cur = {} }, -- Life Tap (debuff)
            [6229] = { max = {}, cur = {} }, -- Twilight Ward
            [108416] = { max = {}, cur = {} }, -- Sacrificial Pact
            [110913] = { max = {}, cur = {} }, -- Dark Bargain

            -- Warrior
            [105909] = { max = {}, cur = {} }, -- T13 prot 2-piece bonus
            [112048] = { max = {}, cur = {} }, -- Shield Barrier

            -- Trinket
            [108008] = { max = {}, cur = {} }, -- Indomitable Pride
}
PitBull4_Shields_combatFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
PitBull4_Shields_combatFrame:SetScript("OnEvent", function(self, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)

  local spellID, spellName, spellSchool, auraType, auraAmount, environmentalType, miss_type, miss_amount

   if eventtype == "SPELL_AURA_REFRESH" or
   eventtype == "SPELL_AURA_REMOVED" or eventtype == "SPELL_AURA_APPLIED" then
      spellID,spellName,spellSchool,auraType,auraAmount = select(1,...)


      if self.shields[spellID] then
        if eventtype == "SPELL_AURA_APPLIED" or eventtype == "SPELL_AURA_REFRESH" then
--            local db = PitBull4_Shields:GetLayoutDB(self)
--            if(db.just_mine and not(srcGUID == UnitGUID("player"))) then return end

            if(spellID == 73975) then -- Necrotic Strike
                auraAmount = select(6,...)
            end

            self.shields[spellID].max[dstGUID] = math.max(self.shields[spellID].max[dstGUID] or 0,auraAmount or 0)
            self.shields[spellID].cur[dstGUID] = auraAmount
        elseif eventtype == "SPELL_AURA_REMOVED" then
          -- Try and correct for discrepancies
          local delta = 0
          if auraAmount then delta = auraAmount - (self.shields[spellID].cur[dstGUID] or 0) end
          self.shields[spellID].max[dstGUID] = nil
          self.shields[spellID].cur[dstGUID] = nil
          if delta > 0 then
             -- We had over-deducted from this shield.  So now we need to rub down some other random shield
             for shield, shields in pairs(self.shields) do
                if shields.cur[dstGUID] then
                    local absorb_for_this_shield = math.min(delta, shields.cur[dstGUID])
                    delta = delta - absorb_for_this_shield
                    shields.cur[dstGUID] = shields.cur[dstGUID] - absorb_for_this_shield
                    if delta <= 0 then break end
                end
             end
          elseif delta < 0 then
            -- We had under-deducted from this shield.  Which means we over-deducted somewhere else, so we need to top up a bit
            for shield, shields in pairs(self.shields) do
                if shields.cur[dstGUID] then
                    local topup_for_this_shield = math.max( delta, shields.cur[dstGUID] - shields.max[dstGUID] ) -- remember delta is negative
                    delta = delta - topup_for_this_shield
                    shields.cur[dstGUID] = shields.cur[dstGUID] - topup_for_this_shield
                    if delta >= 0 then break end
                end
            end
          end
        elseif eventtype == "SPELL_STOLEN" or eventtype == "SPELL_DISPEL" then
            -- Need to deal with these
            print(eventtype,":",spellID,spellName,...)
        end
     else
        if auraAmount then
            print("Pitbull4_Shields candidate spell (",eventtype,"):",spellID,spellName,auraType,auraAmount)
        end
     end

   else

     if eventtype == "SWING_MISSED" then
       local _
       miss_type,_,miss_amount = select(1,...)
     elseif eventtype == "ENVIRONMENTAL_MISSED" then
       local _
       environmentalType,miss_type,_,miss_amount = select(1,...)
     elseif eventtype:find('_MISSED') then
       local _
       spellID,spellName,spellSchool,miss_type,_,miss_amount = select(1,...)
     else
       return
     end
     -- So if we're here, it was a miss -- check for absorb
     if miss_type ~= "ABSORB" then return end

     -- Ok, now we need to guess which shield took the damage
     -- We really should make an adjustment on SPELL_AURA_REMOVED if the shield had more left then we thought,
     -- because then we need to rub a bit more off one of the other shields, or we'll be over-estimating the remaining shielding
     for shield, shields in pairs(self.shields) do
        if shields.cur[dstGUID] then
            local absorb_for_this_shield = math.min(miss_amount or 0, shields.cur[dstGUID])
            miss_amount = (miss_amount or 0) - absorb_for_this_shield
            shields.cur[dstGUID] = shields.cur[dstGUID] - absorb_for_this_shield
            if (miss_amount or 0) <= 0 then break end
        end
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
		name = L["Hide empty bar"],
		desc = L["Check this to hide the Shields bar if empty"],
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
	}, "just_mine", {
	    type = "toggle",
	    name = L["Only cast by me"],
	    desc = L["Check this to only show shields that you cast, rather than all shields on the unit"],
	    get = function(info)
	        local bar_db = PitBull4.Options.GetBarLayoutDB(self)
			return bar_db and bar_db.just_mine
		end,
		set = function(info, value)
			local bar_db = PitBull4.Options.GetBarLayoutDB(self)
	        bar_db.just_mine = value

	        for frame in PitBull4:IterateFrames() do
	            self:Clear(frame)
	        end
	        self:UpdateAll()
	    end
	}
end)

