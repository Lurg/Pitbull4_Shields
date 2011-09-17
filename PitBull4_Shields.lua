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
            -- Priest stuff
            ["Power Word: Shield"] = { max = {}, cur = {} },
            ["Divine Aegis"] = { max = {}, cur = {} },
            -- DK stuff
            ["Blood Shield"] = { max = {}, cur = {} },
            ["Anti-Magic Shell"] = { max = {}, cur = {} },
            ["Anti-Magic Zone"] = { max = {}, cur = {} },
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
PitBull4_Shields_combatFrame:SetScript("OnEvent", function(self, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)

  local spellID, spellName, spellSchool, auraType, auraAmount, environmentalType, miss_type, miss_amount

   if eventtype == "SPELL_AURA_REFRESH" or
   eventtype == "SPELL_AURA_REMOVED" or eventtype == "SPELL_AURA_APPLIED" then
      spellID,spellName,spellSchool,auraType,auraAmount = select(1,...)


      if self.shields[spellName] then
        if eventtype == "SPELL_AURA_APPLIED" or eventtype == "SPELL_AURA_REFRESH" then
            local bar_db = PitBull4.db.profile.layouts
            if(bar_db.just_mine and not(srcGUID == UnitGUID("player"))) then return end

            if(spellName == 'Anti-Magic Shell') then
                -- AMS gets an auroAmount which is a percentage of the unit's max health
                -- So we need to find that unit, then multiply
                auraAmount = (auraAmount/100) * UnitHealthMax(dstName)
            end

            if eventtype == "SPELL_AURA_APPLIED" then
                self.shields[spellName].max[dstGUID] = auraAmount
            end
            self.shields[spellName].cur[dstGUID] = auraAmount
        elseif eventtype == "SPELL_AURA_REMOVED" then
          -- Try and correct for discrepancies
          local delta = 0
          if auraAmount then delta = auraAmount - (self.shields[spellName].cur[dstGUID] or 0) else print("Spell with nil auraAmount on REMOVE was:",spellID,spellName) end
          self.shields[spellName].max[dstGUID] = nil
          self.shields[spellName].cur[dstGUID] = nil
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
       end
     else
        if auraAmount then
            print("Pitbull4_Shields candidate spell:",spellID,spellName,auraType)
        end
     end

   else
     if eventtype == "SWING_MISSED" then
       miss_type,miss_amount = select(1,...)
     elseif eventtype == "ENVIRONMENTAL_MISSED" then
       environmentalType,miss_type,miss_amount = select(1,...)
     elseif eventtype:find('_MISSED') then
       spellID,spellName,spellSchool,miss_type,miss_amount = select(1,...)
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
            local absorb_for_this_shield = math.min(miss_amount, shields.cur[dstGUID])
            miss_amount = miss_amount - absorb_for_this_shield
            shields.cur[dstGUID] = shields.cur[dstGUID] - absorb_for_this_shield
            if miss_amount <= 0 then break end
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

