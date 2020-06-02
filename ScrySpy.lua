local AddonName="ScrySpy"

local LMP = LibMapPins
local GPS = LibGPS3
local Lib3D = Lib3D

---------------------------------------
----- Lib3D Vars                  -----
---------------------------------------

local dig_site_pin, frame, center

---------------------------------------
----- ScrySpy Vars                -----
---------------------------------------

client_lang = GetCVar("language.2")
ScrySpy_SavedVars = ScrySpy_SavedVars or { }
ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
ScrySpy_SavedVars.show_pins = ScrySpy_SavedVars.show_pins or true
ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or 30
ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or 25

-- ScrySpy
local scryspy_settings = {
    pin_level=30,
    pin_size=25,
    show_pins=true
}

-- Existing Local
local PIN_TYPE = "pinType_Digsite"
local PIN_FILTER_NAME = "ScrySpy"
local PIN_NAME = "Dig Location"

dig_site_names = {
["en"] = "Dig Site",
["fr"] = "Site De fouilles",
["de"] = "Ausgrabungsstätte",
["ru"] = "Место раскопок",
}

loc_index = {
    x_pos  = 1,
    y_pos  = 2,
    x_gps  = 3,
    y_gps  = 4,
    worldX = 5,
    worldY = 6,
    worldZ = 7,
}

-- Function to check for empty table
local function is_empty_or_nil(t)
    if not t then return true end
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

local function get_digsite_locations(zone_id, zone)
    d(zone)
    d(zone_id)
    if is_empty_or_nil(ScrySpy.dig_sites[zone_id][zone]) then
        return {}
    else
        return ScrySpy.dig_sites[zone_id][zone]
    end
end

---------------------------------------
----- ScrySpy                     -----
---------------------------------------
ScrySpy.worldControlPool = ZO_ControlPool:New("ScrySpy_WorldPin", ScrySpy_WorldPins)

local function get_digsite_loc_sv(zone_id, zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy_SavedVars.location_info[zone_id][zone]) then
        return {}
    else
        return ScrySpy_SavedVars.location_info[zone_id][zone]
    end
end

local function save_to_sv(locations_table, location)
    --[[
    This should be the table not the Zone like Skyrim or
    the ZoneID

    example ScrySpy.dig_sites[zone_id][zone] where zone might be
    ["skyrim/westernskryim_base_0"] and zone_id is 1160
    ]]--
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
    local x_gps, y_gps = GPS:LocalToGlobal(x_pos, y_pos)
    local zone_id, worldX, worldZ, worldY = GetUnitWorldPosition("player")


    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
    -- not needed, because it's already created above
    ScrySpy_SavedVars.location_info[zone_id] = ScrySpy_SavedVars.location_info[zone_id] or { }
    ScrySpy_SavedVars.location_info[zone_id][zone] = ScrySpy_SavedVars.location_info[zone_id][zone] or { }

    if ScrySpy.dig_sites == nil then ScrySpy.dig_sites = {} end
    if ScrySpy.dig_sites[zone_id] == nil then ScrySpy.dig_sites[zone_id] = {} end
    if ScrySpy.dig_sites[zone_id][zone] == nil then ScrySpy.dig_sites[zone_id][zone] = {} end

    local dig_sites_table = get_digsite_locations(zone_id, zone)
    if is_empty_or_nil(dig_sites_table) then dig_sites_table = {} end


    local dig_sites_sv_table = get_digsite_loc_sv(zone_id, zone)
    if is_empty_or_nil(dig_sites_sv_table) then dig_sites_sv_table = {} end

    local location = {
        loc_index.x_pos = x_pos
        loc_index.y_pos = y_pos
        loc_index.x_gps = x_gps
        loc_index.y_gps = y_gps
        loc_index.worldX = worldX
        loc_index.worldY = worldY
        loc_index.worldZ = worldZ
    }
    if save_to_sv(dig_sites_table, location) and save_to_sv(dig_sites_sv_table, location) then
        --d("saving location")
        table.insert(ScrySpy_SavedVars.location_info[zone_id][zone], location)
        LMP:RefreshPins(PIN_TYPE)
    end
end

local function RefreshPinFilters()
    LMP:SetEnabled(PIN_TYPE, ScrySpy_SavedVars.show_pins)
end

---------------------------------------
----- Lib3D                       -----
---------------------------------------
local function Hide3DPins()
    -- remove the on update handler and hide the mage dig_site_pin
    EVENT_MANAGER:UnregisterForUpdate("DigSite")
    ScrySpy_WorldPins:SetHidden(true)
    ScrySpy.worldControlPool:ReleaseAllObjects()
end

local function Draw3DPins()
    EVENT_MANAGER:UnregisterForUpdate("DigSite")

    local zone_id = GetUnitWorldPosition("player") -- there is a better way to get zone_id
    local zone = LMP:GetZoneAndSubzone(true, false, true)

    local pseudo_pin_location = get_digsite_loc_sv(zone_id, zone)
    if pseudo_pin_location then
        local worldX, worldZ, worldY = WorldPositionToGuiRender3DPosition(0,0,0)
        if not worldX then return end
        ScrySpy_WorldPins:Set3DRenderSpaceOrigin(worldX, worldZ, worldY)
        ScrySpy_WorldPins:SetHidden(false)

        for pin, pinData in ipairs(pseudo_pin_location) do
            local pinControl = ScrySpy.worldControlPool:AcquireObject(pin)
            if not pinControl:Has3DRenderSpace() then
                pinControl:Create3DRenderSpace()
                local size = 1
                pin:Set3DRenderSpaceOrigin(0, size + 0.125 * size + 0.25, 0)
                pin:Set3DLocalDimensions(0.25 * size + 0.5, 0.25 * size + 0.5)
                pin:Set3DRenderSpaceUsesDepthBuffer(true)
            end
        end

        local activeObjects = ScrySpy.worldControlPool:GetActiveObjects()

        -- don't do that every single frame. it's not necessary
        EVENT_MANAGER:RegisterForUpdate("DigSite", 100, function()
            local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
            for key, pinControl in pairs(activeObjects) do
                pinControl:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
                pinControl:Set3DRenderSpaceRight(rightX, rightY, rightZ)
                pinControl:Set3DRenderSpaceUp(upX, upY, upZ)
            end

        end)
    end
end

local function OnInteract(event_code, client_interact_result, interact_target_name)
    --d(event_code)
    --d(client_interact_result)
    local text = zo_strformat(SI_CHAT_MESSAGE_FORMATTER, interact_target_name)
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
        local zone_id = GetUnitWorldPosition("player") -- there is a better way to get zone_id

        ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
        ScrySpy_SavedVars.location_info[zone_id] = ScrySpy_SavedVars.location_info[zone_id] or { }
        ScrySpy_SavedVars.location_info[zone_id][zone] = ScrySpy_SavedVars.location_info[zone_id][zone] or { }

        local mapData = ScrySpy.dig_sites[zone_id][zone] or { }
        local dig_sites_sv_table = get_digsite_loc_sv(zone_id, zone) or { }
        if next(dig_sites_sv_table) then
            for num_entry, digsite_loc in ipairs(dig_sites_sv_table) do
                if save_to_sv(mapData, digsite_loc) then
                    table.insert(mapData, digsite_loc)
                end
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
        texture = "/"..AddonName.."/img/spade-icon.dds", -- this should be savedVars too...
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
    LMP:AddPinFilter(PIN_TYPE, zo_iconFormat(lmp_pin_layout.texture,24,24).." "..PIN_FILTER_NAME, true, ScrySpy_SavedVars.show_pins)
    RefreshPinFilters()
end

local function reset_info()
    ScrySpy_SavedVars.location_info = {}
end

local function OnPlayerActivated(eventCode)
    InitializePins()
    EVENT_MANAGER:UnregisterForEvent(AddonName.."_InitPins", EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(AddonName.."_InitPins", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

local function OnLoad(eventCode,addonName)
    -- turn the top level control into a 3d control
    ScrySpy_WorldPins:Create3DRenderSpace()

    -- make sure the control is only shown, when the player can see the world
    -- i.e. the control is only shown during non-menu scenes
    local fragment = ZO_SimpleSceneFragment:New(ScrySpy_WorldPins)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    -- register a callback, so we know when to start/stop displaying the dig_site_pin
    Lib3D:RegisterWorldChangeCallback("DigSite", function(identifier, zoneIndex, isValidZone, newZone)
        if not newZone then return end

        if isValidZone then
            Draw3DPins()
        else
            Hide3DPins()
        end
    end)

end
EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ADD_ON_LOADED,OnLoad)
