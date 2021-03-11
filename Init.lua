ScrySpy = {}

--[[
Some settings moved to Init.lua to make them global to other files
]]--

--[[ Previous var to toggle map pins
scryspy_defaults = {
    show_pins=true,
}

-- Saved Vars
ScrySpy_SavedVars.show_pins
]]--
ScrySpy.addon_name = "ScrySpy"
ScrySpy.addon_version = "1.28"
ScrySpy.addon_website = "https://www.esoui.com/downloads/info2647-ScrySpy.html"
ScrySpy.custom_compass_pin = "compass_digsite" -- custom compas pin pin type
ScrySpy.scryspy_map_pin = "scryspy_map_pin"
ScrySpy.dig_site_pin = "dig_site_pin"
ScrySpy.client_lang = GetCVar("language.2")
ScrySpy.should_update_digsites = true

ScrySpy.pin_textures = {
    [1] = "ScrySpy/img/spade_shovel_redx_marker.dds",
    [2] = "ScrySpy/img/spade_shovel_marker.dds",
    [3] = "esoui/art/antiquities/digsite_unknown.dds",
    [4] = "esoui/art/antiquities/digging_crystal_full.dds",
    [5] = "esoui/art/antiquities/digging_crystal_empty.dds",
    [6] = "esoui/art/antiquities/digging_crystal_border.dds",
    [7] = "esoui/art/antiquities/keyboard/trackedantiquityicon.dds",
    [8] = "esoui/art/inventory/inventory_icon_visible.dds",
    [9] = "esoui/art/inventory/inventory_quest_tabicon_active.dds",
}

function ScrySpy.unpack_color_table(the_table)
    local col_r, col_g, col_b, col_a = unpack(the_table)
    return col_r, col_g, col_b, col_a
end

function ScrySpy.create_color_table(r, g, b, a)
    local c = {}

    if(type(r) == "string") then
        c[4], c[1], c[2], c[3] = ConvertHTMLColorToFloatValues(r)
    elseif(type(r) == "table") then
        local otherColorDef = r
        c[1] = otherColorDef.r or 1
        c[2] = otherColorDef.g or 1
        c[3] = otherColorDef.b or 1
        c[4] = otherColorDef.a or 1
    else
        c[1] = r or 1
        c[2] = g or 1
        c[3] = b or 1
        c[4] = a or 1
    end

    return c
end

ScrySpy.scryspy_defaults = {
    ["pin_level"] = 30,
    ["pin_size"] = 25,
    ["digsite_pin_size"] = 25,
    ["pin_type"] = 1,
    ["digsite_pin_type"] = 1,
    ["compass_max_distance"] = 0.05,
	["filters"] = {
		[ScrySpy.custom_compass_pin] = true, -- toggle show pin on compass
		[ScrySpy.scryspy_map_pin] = true, -- toggle show pin on world map
		[ScrySpy.dig_site_pin] = true, -- toggle show 3d pin in overland
	},
    ["digsite_spike_color"] = {
        [1] = 1,
        [2] = 1,
        [3] = 1,
        [4] = 1,
    },
}
