local PitBull4 = _G.PitBull4
if not PitBull4 then
    error("PitBull4_ShieldsText requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------

local EXAMPLE_TEXT = "5.8k"
-----------------------------------------------------------------------------

local L = PitBull4.L

local PitBull4_ShieldsText = PitBull4:NewModule("ShieldsText", "AceEvent-3.0")

PitBull4_ShieldsText:SetModuleType("custom_text")
PitBull4_ShieldsText:SetName(L["Shields text"])
PitBull4_ShieldsText:SetDescription(L["Show information about the size of shields on the unit frame."])
PitBull4_ShieldsText:SetDefaults({
    attach_to = "Shields",
    location = "center",
    position = 1,
    size = 1,
})

function PitBull4_ShieldsText:OnEnable()
    self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
end

function PitBull4_ShieldsText:OnDisable()
    self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
end

function PitBull4_ShieldsText:ClearFrame(frame)
    if not frame.ShieldsText then
        return false
    end

    frame.ShieldsText = frame.ShieldsText:Delete()
    return true
end

PitBull4_ShieldsText.OnHide = PitBull4_ShieldsText.ClearFrame

function PitBull4_ShieldsText:UpdateFrame(frame)
    local font_string = frame.ShieldsText
    local created = not font_string
    if created then
        font_string = PitBull4.Controls.MakeFontString(frame.overlay, "OVERLAY")
        frame.ShieldsText = font_string
        font_string:SetShadowColor(0, 0, 0, 1)
        font_string:SetShadowOffset(0.8, -0.8)
        font_string:SetNonSpaceWrap(false)
    end

    local font, size = self:GetFont(frame)
    font_string:SetFont(font, size)

    if frame.force_show and not frame.guid then
        font_string:SetText(EXAMPLE_TEXT)
    elseif font_string:GetText() == EXAMPLE_TEXT then
        font_string:SetText("")
    end

    return created
end

function PitBull4_ShieldsText:UNIT_ABSORB_AMOUNT_CHANGED(event, unit)
    local amount = UnitGetTotalAbsorbs(unit)
    local text = ""
    if amount and amount > 0 then
        text = string.format("%0.1fk",amount/1000)
    end

    for frame in PitBull4:IterateFramesForUnitID(unit) do
        if amount and amount > 0 then
            local font_string = frame.ShieldsText
            if font_string then
                font_string:SetText(text)
                local font, size = self:GetFont(frame)
                font_string:SetFont(font, size)
                font_string:SetTextColor(1, 1, 1)
            end
        else
            self:ClearFrame(frame)
        end
    end
end
