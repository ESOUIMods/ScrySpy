local LMP = LibMapPins
local GPS = LibGPS3
local Lib3D = Lib3D
local CCP = COMPASS_PINS
local LAM = LibAddonMenu2


---------------------------------------
----- Lib3D Vars                  -----
---------------------------------------



---------------------------------------
----- ScrySpy Vars                -----
---------------------------------------

ScrySpy_SavedVars = ScrySpy_SavedVars or { }
ScrySpy_SavedVars.version = ScrySpy_SavedVars.version or 1 -- This is not the addon version number
ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or ScrySpy.scryspy_defaults.pin_level
ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or ScrySpy.scryspy_defaults.pin_size
ScrySpy_SavedVars.digsite_pin_size = ScrySpy_SavedVars.digsite_pin_size or ScrySpy.scryspy_defaults.digsite_pin_size
ScrySpy_SavedVars.pin_type = ScrySpy_SavedVars.pin_type or ScrySpy.scryspy_defaults.pin_type
ScrySpy_SavedVars.digsite_pin_type = ScrySpy_SavedVars.digsite_pin_type or ScrySpy.scryspy_defaults.digsite_pin_type
ScrySpy_SavedVars.compass_max_distance = ScrySpy_SavedVars.compass_max_distance or ScrySpy.scryspy_defaults.compass_max_distance
ScrySpy_SavedVars.custom_compass_pin = ScrySpy_SavedVars.custom_compass_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin]
ScrySpy_SavedVars.scryspy_map_pin = ScrySpy_SavedVars.scryspy_map_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.scryspy_map_pin]
ScrySpy_SavedVars.dig_site_pin = ScrySpy_SavedVars.dig_site_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.dig_site_pin]
ScrySpy_SavedVars.digsite_spike_color = ScrySpy_SavedVars.digsite_spike_color or ScrySpy.scryspy_defaults.digsite_spike_color

-- Existing Local
local PIN_TYPE = "pinType_Digsite" -- This is changed by LAM now, use ScrySpy.scryspy_map_pin
local PIN_FILTER_NAME = "ScrySpy"
local PIN_NAME = "Dig Location"
local PIN_PRIORITY_OFFSET = 1

-- ScrySpy
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

local function is_in(search_value, search_table)
    for k, v in pairs(search_table) do
        if search_value == v then return true end
        if type(search_value) == "string" then
            if string.find(string.lower(v), string.lower(search_value)) then return true end
        end
    end
    return false
end

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

local function get_digsite_locations(zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy.dig_sites[zone]) then
        return {}
    else
        return ScrySpy.dig_sites[zone]
    end
end

---------------------------------------
----- ScrySpy                     -----
---------------------------------------
ScrySpy.worldControlPool = ZO_ControlPool:New("ScrySpy_WorldPin", ScrySpy_WorldPins)

local function get_digsite_loc_sv(zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy_SavedVars.location_info[zone]) then
        return {}
    else
        return ScrySpy_SavedVars.location_info[zone]
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
    local zone_id, worldX, worldY, worldZ = GetUnitWorldPosition("player")

    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
    -- not needed, because it's already created above
    ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
    ScrySpy_SavedVars.location_info[zone] = ScrySpy_SavedVars.location_info[zone] or { }

    if ScrySpy.dig_sites == nil then ScrySpy.dig_sites = {} end
    if ScrySpy.dig_sites[zone] == nil then ScrySpy.dig_sites[zone] = {} end

    local dig_sites_table = get_digsite_locations(zone)
    if is_empty_or_nil(dig_sites_table) then dig_sites_table = {} end

    local dig_sites_sv_table = get_digsite_loc_sv(zone)
    if is_empty_or_nil(dig_sites_sv_table) then dig_sites_sv_table = {} end

    local location = {
        [loc_index.x_pos] = x_pos,
        [loc_index.y_pos] = y_pos,
        [loc_index.x_gps] = x_gps,
        [loc_index.y_gps] = y_gps,
        [loc_index.worldX] = worldX,
        [loc_index.worldY] = worldY,
        [loc_index.worldZ] = worldZ,
    }
    if save_to_sv(dig_sites_table, location) and save_to_sv(dig_sites_sv_table, location) then
        --d("saving location")
        table.insert(ScrySpy_SavedVars.location_info[zone], location)
        LMP:RefreshPins(ScrySpy.scryspy_map_pin)
        CCP:RefreshPins(ScrySpy.custom_compass_pin)
        ScrySpy.Draw3DPins()
    end
end

function ScrySpy.RefreshPinLayout()
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "size", ScrySpy_SavedVars.pin_size)
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "level", ScrySpy_SavedVars.pin_level+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "texture", ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type])
    LMP:RefreshPins(ScrySpy.scryspy_map_pin)
end

function ScrySpy.RefreshPinFilters()
    LMP:SetEnabled(ScrySpy.scryspy_map_pin, ScrySpy_SavedVars.scryspy_map_pin)
end

---------------------------------------
----- Lib3D                       -----
---------------------------------------

function ScrySpy.Hide3DPins()
    -- remove the on update handler and hide the ScrySpy.dig_site_pin
    EVENT_MANAGER:UnregisterForUpdate("DigSite")
    ScrySpy_WorldPins:SetHidden(true)
    ScrySpy.worldControlPool:ReleaseAllObjects()
end

function ScrySpy.Draw3DPins()
    EVENT_MANAGER:UnregisterForUpdate("DigSite")

    local zone = LMP:GetZoneAndSubzone(true, false, true)

    local mapData = ScrySpy.get_pin_data(zone) or { }
    -- pseudo_pin_location
    if mapData then
        local worldX, worldZ, worldY = WorldPositionToGuiRender3DPosition(0,0,0)
        if not worldX then return end
        ScrySpy_WorldPins:Set3DRenderSpaceOrigin(worldX, worldZ, worldY)
        ScrySpy_WorldPins:SetHidden(false)

        for pin, pinData in ipairs(mapData) do
            local pinControl = ScrySpy.worldControlPool:AcquireObject(pin)
            if not pinControl:Has3DRenderSpace() then
                pinControl:Create3DRenderSpace()
            end
            local size = 1
            for i = 1, pinControl:GetNumChildren() do
                local textureControl = pinControl:GetChild(i)
                if not textureControl:Has3DRenderSpace() then
                    textureControl:Create3DRenderSpace()
                end
                local child_name = textureControl:GetName()
                if is_in("icon", { child_name } ) then
                    textureControl:SetTexture(ScrySpy.pin_textures[ScrySpy_SavedVars.digsite_pin_type])
                    textureControl:Set3DRenderSpaceOrigin(pinData[loc_index.worldX]/100, (pinData[loc_index.worldY]/100) + 2.5, pinData[loc_index.worldZ]/100)
                    textureControl:Set3DLocalDimensions(0.30 * size + 0.6, 0.30 * size + 0.6)
                else
                    textureControl:SetColor(unpack(ScrySpy_SavedVars.digsite_spike_color))
                    textureControl:Set3DRenderSpaceOrigin(pinData[loc_index.worldX]/100, (pinData[loc_index.worldY]/100) + 1.0, pinData[loc_index.worldZ]/100)
                    textureControl:Set3DLocalDimensions(0.25 * size + 0.75, 0.75 * size + 1.25)
                end
                textureControl:Set3DRenderSpaceUsesDepthBuffer(true)
            end
        end

        local activeObjects = ScrySpy.worldControlPool:GetActiveObjects()

        -- don't do that every single frame. it's not necessary
        EVENT_MANAGER:RegisterForUpdate("DigSite", 100, function()
            local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
            for key, pinControl in pairs(activeObjects) do
                for i = 1, pinControl:GetNumChildren() do
                    local textureControl = pinControl:GetChild(i)
                    textureControl:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
                    textureControl:Set3DRenderSpaceRight(rightX, rightY, rightZ)
                    textureControl:Set3DRenderSpaceUp(upX, upY, upZ)
                end
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
    if text == dig_site_names[ScrySpy.client_lang] then
        save_dig_site_location()
    end
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name,EVENT_CLIENT_INTERACT_RESULT, OnInteract)

function ScrySpy.get_pin_data(zone)
    ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
    ScrySpy_SavedVars.location_info[zone] = ScrySpy_SavedVars.location_info[zone] or { }

    ScrySpy.dig_sites[zone] = ScrySpy.dig_sites[zone] or { }

    local mapData = ScrySpy.dig_sites[zone] or { }
    local dig_sites_sv_table = get_digsite_loc_sv(zone) or { }
    for num_entry, digsite_loc in ipairs(dig_sites_sv_table) do
        if save_to_sv(mapData, digsite_loc) then
            table.insert(mapData, digsite_loc)
        end
    end
    return mapData
end

local function InitializePins()
    local function MapPinAddCallback(pinType)
        local zone = LMP:GetZoneAndSubzone(true, false, true)
        --[[
        Problem encountered. When standing in the ["skyrim/solitudeoutlawsrefuge_0"]

        The Zone ID for that map is 1178 and the mapname is ["skyrim/solitudeoutlawsrefuge_0"]

        If you have the map open and change maps, then the map might be ["craglorn/craglorn_base_0"]
        but the player, where they are currently standing is still 1178.

        meaning the game will look for 1178 and ["craglorn/craglorn_base_0"] which is invalid
        ]]--
        --d(zone)
        local mapData = ScrySpy.get_pin_data(zone) or { }
        if mapData then
            for index, pinData in pairs(mapData) do
                LMP:CreatePin(ScrySpy.scryspy_map_pin, pinData, pinData[loc_index.x_pos], pinData[loc_index.y_pos])
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
        texture = ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type],
        size = ScrySpy_SavedVars.pin_size,
    }

    local pinlayout_compass = {
        maxDistance = 0.05,
        texture = ScrySpy.pin_textures[ScrySpy_SavedVars.custom_compass_pin],
        sizeCallback = function(pin, angle, normalizedAngle, normalizedDistance)
            if zo_abs(normalizedAngle) > 0.25 then
                pin:SetDimensions(54 - 24 * zo_abs(normalizedAngle), 54 - 24 * zo_abs(normalizedAngle))
            else
                pin:SetDimensions(48, 48)
            end
        end,
    }

    local function compass_callback()
        if GetMapType() <= MAPTYPE_ZONE and ScrySpy_SavedVars.custom_compass_pin then
            local zone = LMP:GetZoneAndSubzone(true, false, true)
            local mapData = ScrySpy.get_pin_data(zone) or { }
            if mapData then
                for _, pinData in ipairs(mapData) do
                    CCP.pinManager:CreatePin(ScrySpy.custom_compass_pin, pinData, pinData[loc_index.x_pos], pinData[loc_index.y_pos])
                end
            end
        end
    end

    local pinTooltipCreator = {
        creator = function(pin)
            if IsInGamepadPreferredMode() then
                local InformationTooltip = ZO_MapLocationTooltip_Gamepad
                local baseSection = InformationTooltip.tooltip
                InformationTooltip:LayoutIconStringLine(baseSection, nil, ScrySpy.addon_name, baseSection:GetStyle("mapLocationTooltipContentHeader"))
                InformationTooltip:LayoutIconStringLine(baseSection, nil, PIN_NAME, baseSection:GetStyle("mapLocationTooltipContentName"))
            else
                SetTooltipText(InformationTooltip, PIN_NAME)
            end
        end
    }

    LMP:AddPinType(ScrySpy.scryspy_map_pin, function() PinTypeAddCallback(ScrySpy.scryspy_map_pin) end, nil, lmp_pin_layout, pinTooltipCreator)
    LMP:AddPinFilter(ScrySpy.scryspy_map_pin, zo_iconFormat(lmp_pin_layout.texture,24,24).." "..PIN_FILTER_NAME, false, ScrySpy_SavedVars, "scryspy_map_pin")
    ScrySpy.RefreshPinFilters()
    CCP:AddCustomPin(ScrySpy.custom_compass_pin, compass_callback, pinlayout_compass)
    CCP:RefreshPins(ScrySpy.custom_compass_pin)
end

local function reset_info()
    ScrySpy_SavedVars.location_info = {}
end

local function OnPlayerActivated(eventCode)
    InitializePins()
    ScrySpy.RefreshPinLayout()
    CCP.pinLayouts[ScrySpy.custom_compass_pin].texture = ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type]
    CCP:RefreshPins(ScrySpy.custom_compass_pin)
    ScrySpy.digsite_spike_color:SetRGBA( ScrySpy_SavedVars.digsite_spike_color )
    ScrySpy.Draw3DPins()
    EVENT_MANAGER:UnregisterForEvent(ScrySpy.addon_name.."_InitPins", EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name.."_InitPins", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

local function OnLoad(eventCode, addOnName)
    -- turn the top level control into a 3d control
    ScrySpy_WorldPins:Create3DRenderSpace()

    -- make sure the control is only shown, when the player can see the world
    -- i.e. the control is only shown during non-menu scenes
    local fragment = ZO_SimpleSceneFragment:New(ScrySpy_WorldPins)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    -- register a callback, so we know when to start/stop displaying the ScrySpy.dig_site_pin
    Lib3D:RegisterWorldChangeCallback("DigSite", function(identifier, zoneIndex, isValidZone, newZone)
        if not newZone then return end

        if isValidZone then
            ScrySpy.Draw3DPins()
        else
            ScrySpy.Hide3DPins()
        end
    end)

    if ScrySpy_SavedVars.version ~= 3 then
        local temp_locations
        if ScrySpy_SavedVars.version == nil then ScrySpy_SavedVars.version = 1 end
        if ScrySpy_SavedVars.version >= 2 then
            if ScrySpy_SavedVars.location_info then
                temp_locations = ScrySpy_SavedVars.location_info
            end
        end
        ScrySpy_SavedVars = { }
        ScrySpy_SavedVars.version = 3
        ScrySpy_SavedVars.location_info = temp_locations or { }
        ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or ScrySpy.scryspy_defaults.pin_level
        ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or ScrySpy.scryspy_defaults.pin_size
        ScrySpy_SavedVars.digsite_pin_size = ScrySpy_SavedVars.digsite_pin_size or ScrySpy.scryspy_defaults.digsite_pin_size
        ScrySpy_SavedVars.pin_type = ScrySpy_SavedVars.pin_type or ScrySpy.scryspy_defaults.pin_type
        ScrySpy_SavedVars.digsite_pin_type = ScrySpy_SavedVars.digsite_pin_type or ScrySpy.scryspy_defaults.digsite_pin_type
        ScrySpy_SavedVars.compass_max_distance = ScrySpy_SavedVars.compass_max_distance or ScrySpy.scryspy_defaults.compass_max_distance
        ScrySpy_SavedVars.custom_compass_pin = ScrySpy_SavedVars.custom_compass_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin]
        ScrySpy_SavedVars.scryspy_map_pin = ScrySpy_SavedVars.scryspy_map_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.scryspy_map_pin]
        ScrySpy_SavedVars.dig_site_pin = ScrySpy_SavedVars.dig_site_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.dig_site_pin]
        ScrySpy_SavedVars.digsite_spike_color = ScrySpy_SavedVars.digsite_spike_color or ScrySpy.scryspy_defaults.digsite_spike_color
        ScrySpy.RefreshPinFilters()
        ScrySpy.RefreshPinLayout()
        LMP:RefreshPins(ScrySpy.scryspy_map_pin)
    end

end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name, EVENT_ADD_ON_LOADED, OnLoad)
