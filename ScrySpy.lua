local AddonName="ScrySpy"

local LMP = LibMapPins
local GPS = LibGPS3

client_lang = GetCVar("language.2")
ScrySpy = {}
if ScrySpy_SavedVars == nil then ScrySpy_SavedVars = {} end
if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
ScrySpy_SavedVars.show_pins = ScrySpy_SavedVars.show_pins or true
ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or 30
ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or 25

local dig_sites={
    ["elsweyr/elsweyr_base_0"]={
    {0.682,0.247},{0.685,0.268},{0.438,0.232},{0.445,0.194},{0.416,0.222},{0.356,0.603},{0.348,0.382},
    },
    ["skyrim/westernskryim_base_0"]={
    {0.135,0.360},{0.150,0.340},{0.610,0.288},{0.241,0.641},{0.344,0.268},{0.562,0.644},{0.542,0.654},
    {0.529,0.649},{0.806,0.562},
    },
}

-- ScrySpy
local scryspy_settings = {
    pin_level=30,
    pin_size=25,
    show_pins=true
}

-- Existing Local
local PIN_TYPE = "pinType_Digsite"
local PIN_FILTER_NAME = "Digsite"
local PIN_NAME = "Dig Location"

dig_site_names = {
["en"] = "Dig Site",
["fr"] = "Site De fouilles",
["de"] = "Ausgrabungsstätte",
["ru"] = "Dig Site",
}

loc_index = {
    x_pos  =    1,
    y_pos  =    2,
}

-- Function to check for empty table
local function is_empty_or_nil(t)
    if type(t) == "table" then
        if next(t) == nil then
            return true
        else
            return false
        end
    elseif type(t) == "string" then
        if t == nil then
            return true
        elseif t == "" then
            return true
        else
            return false
        end
    elseif type(t) == "nil" then
        return true
    end
end

local function get_digsite_locations(zone)
    --d(zone)
    if is_empty_or_nil(dig_sites[zone]) then
        return {}
    else
        return dig_sites[zone]
    end
end

local function get_digsite_loc_sv(zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy_SavedVars.location_info[zone]) then
        return {}
    else
        return ScrySpy_SavedVars.location_info[zone]
    end
end

local function save_to_sv(locations_table, location)
    local save_location = true
    for num_entry, digsite_loc in ipairs(locations_table) do
        local distance = zo_round(GPS:GetLocalDistanceInMeters(digsite_loc[loc_index.x_pos], digsite_loc[loc_index.y_pos], location[loc_index.x_pos], location[loc_index.y_pos]))
        --d(distance)
        if distance <= 10 then
            --d("less then 10 to close to me")
            return false
        else
            --d("more then 10, far away, save it")
        end
    end
    return save_location
end

local function save_dig_site_location()
    --d("save_dig_site_location")
    local x_pos, y_pos = GetMapPlayerPosition("player")
    local location = {}
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    location[loc_index.x_pos] = x_pos
    location[loc_index.y_pos] = y_pos

    if dig_sites == nil then dig_sites = {} end
    if dig_sites[zone] == nil then dig_sites[zone] = {} end
    dig_sites_table = get_digsite_locations(zone)

    if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
    if ScrySpy_SavedVars.location_info[zone] == nil then ScrySpy_SavedVars.location_info[zone] = {} end
    dig_sites_sv_table = get_digsite_loc_sv(zone)

    if save_to_sv(dig_sites_table, location) and save_to_sv(dig_sites_sv_table, location) then
        --d("saving location")
        table.insert(ScrySpy_SavedVars.location_info[zone], location)
        LMP:RefreshPins(PIN_TYPE)
    end
end

local function RefreshPinFilters()
    LMP:SetEnabled(PIN_TYPE, ScrySpy_SavedVars.show_pins)
end

local function OnInteract(event_code, client_interact_result, interact_target_name)
    --d(event_code)
    --d(client_interact_result)
    text = zo_strformat(SI_CHAT_MESSAGE_FORMATTER, interact_target_name)
    --d(text)
    --d("OnInteract")
    if text == dig_site_names[client_lang] then
        save_dig_site_location()
    end
end
EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_CLIENT_INTERACT_RESULT, OnInteract)

local function InitializePins()
    local function MapPinAddCallback(pinType)
        local zone = LMP:GetZoneAndSubzone(true, false, true)
        local mapData = dig_sites[zone]
        if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
        if ScrySpy_SavedVars.location_info[zone] == nil then ScrySpy_SavedVars.location_info[zone] = {} end
        dig_sites_sv_table = get_digsite_loc_sv(zone)
        for num_entry, digsite_loc in ipairs(dig_sites_sv_table) do
            if save_to_sv(mapData, digsite_loc) then
                table.insert(mapData, digsite_loc)
            end
        end
        if mapData then
            for index, pinData in pairs(mapData) do
                LMP:CreatePin(PIN_TYPE, pinData, pinData[loc_index.x_pos], pinData[loc_index.y_pos])
            end
        end
    end

    local function PinTypeAddCallback(pinType)
        if GetMapType() <= MAPTYPE_ZONE and LMP:IsEnabled(pinType) then
            MapPinAddCallback(pinType)
        end
    end

    local lmp_pin_layout =
    {
        level = ScrySpy_SavedVars.pin_level,
        texture = "/"..AddonName.."/img/Treasure_3.dds", -- this should be savedVars too...
        size = ScrySpy_SavedVars.pin_size,
    }

    local pinTooltipCreator = {
        creator = function(pin)
            if IsInGamepadPreferredMode() then
                local InformationTooltip = ZO_MapLocationTooltip_Gamepad
                local baseSection = InformationTooltip.tooltip
                InformationTooltip:LayoutIconStringLine(baseSection, nil, AddonName, baseSection:GetStyle("mapLocationTooltipContentHeader"))
                InformationTooltip:LayoutIconStringLine(baseSection, nil, PIN_NAME, baseSection:GetStyle("mapLocationTooltipContentName"))
            else
                SetTooltipText(InformationTooltip, PIN_NAME)
            end
        end,
    }

    LMP:AddPinType(PIN_TYPE, function() PinTypeAddCallback(PIN_TYPE) end, nil, lmp_pin_layout, pinTooltipCreator)
    LMP:AddPinFilter(PIN_TYPE, zo_iconFormat(lmp_pin_layout.texture,24,24).." LMP "..PIN_FILTER_NAME, true, ScrySpy_SavedVars.show_pins)
    RefreshPinFilters()
end

local function reset_info()
    ScrySpy_SavedVars.location_info = {}
end

local function OnLoad(eventCode,addonName)
    if addonName == AddonName then
        EVENT_MANAGER:UnregisterForEvent(AddonName,EVENT_ADD_ON_LOADED)
        --ScrySpy.SavedVars=ZO_SavedVars:NewAccountWide("ScrySpy_SavedVars",1,nil,scryspy_settings)

        InitializePins()

        --SLASH_COMMANDS["/ssreset"] = function() reset_info() end
    end
end
EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ADD_ON_LOADED,OnLoad)
