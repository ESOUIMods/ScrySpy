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
if ScrySpy_SavedVars == nil then ScrySpy_SavedVars = {} end
if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
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
    local location = {}
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    location[loc_index.x_pos] = x_pos
    location[loc_index.y_pos] = y_pos
    location[loc_index.x_gps] = x_gps
    location[loc_index.y_gps] = y_gps
    location[loc_index.worldX] = worldX
    location[loc_index.worldY] = worldY
    location[loc_index.worldZ] = worldZ

    if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
    if ScrySpy_SavedVars.location_info[zone_id] == nil then ScrySpy_SavedVars.location_info[zone_id] = {} end
    if ScrySpy_SavedVars.location_info[zone_id][zone] == nil then ScrySpy_SavedVars.location_info[zone_id][zone] = {} end

    if ScrySpy.dig_sites == nil then ScrySpy.dig_sites = {} end
    if ScrySpy.dig_sites[zone_id] == nil then ScrySpy.dig_sites[zone_id] = {} end
    if ScrySpy.dig_sites[zone_id][zone] == nil then ScrySpy.dig_sites[zone_id][zone] = {} end

    dig_sites_table = get_digsite_locations(zone_id, zone)
    if is_empty_or_nil(dig_sites_table) then dig_sites_table = {} end


    dig_sites_sv_table = get_digsite_loc_sv(zone_id, zone)
    if is_empty_or_nil(dig_sites_sv_table) then dig_sites_sv_table = {} end

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
function get_player_3d_position(worldX, worldZ, worldY)
	return worldX/100, worldY/100, worldZ/100
end

function Hide3DPins()
	-- remove the on update handler and hide the mage dig_site_pin
	EVENT_MANAGER:UnregisterForUpdate("DigSite")
	dig_site_pin:SetHidden(true)
	frame:SetHidden(true)
	center:SetHidden(true)
end

function Draw3DPins()
	dig_site_pin:SetHidden(false)
	frame:SetHidden(false)
	center:SetHidden(false)
    local zone_id, worldX, worldZ, worldY = GetUnitWorldPosition("player")
    local zone = LMP:GetZoneAndSubzone(true, false, true)


	EVENT_MANAGER:UnregisterForUpdate("DigSite")
	-- perform the following every single frame
	EVENT_MANAGER:RegisterForUpdate("DigSite", 0, function(time)

		local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()

		-- align the dig_site_pin with the camera's render space so the dig_site_pin is always facing the camera
		dig_site_pin:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
		dig_site_pin:Set3DRenderSpaceRight(rightX, rightY, rightZ)
		dig_site_pin:Set3DRenderSpaceUp(upX, upY, upZ)

        -- local worldX, worldY, worldZ = Lib3D:ComputePlayerRenderSpacePosition()

		-- get the player position, so we can place the dig_site_pin nearby
        pseudo_pin_location = get_digsite_loc_sv(zone_id, zone)
		local worldX = pseudo_pin_location[1][loc_index.worldX]
		local worldY = pseudo_pin_location[1][loc_index.worldY]
		local worldZ = pseudo_pin_location[1][loc_index.worldZ]

        worldX, worldY, worldZ = WorldPositionToGuiRender3DPosition(worldX, worldZ, worldY)

		if not worldX then return end
		-- this creates the circling motion around the player
		--local time = GetFrameTimeSeconds()
		--worldX = worldX + math.sin(time)
		--worldZ = worldZ + math.cos(time)
		--worldY = worldY + 2.0 + 0.5 * math.sin(0.5 * time)
		ScrySpy_WorldPins:Set3DRenderSpaceOrigin(worldX, worldY + 2.0 , worldZ)

		-- add a pulsing animation
		--center:SetAlpha(math.sin(2 * time) * 0.25 + 0.75)
		--frame:Set3DLocalDimensions(time % 1, time % 1)
		--frame:SetAlpha(1 - (time % 1))

	end)
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
        local zone_id, worldX, worldZ, worldY = GetUnitWorldPosition("player")
        local mapData = ScrySpy.dig_sites[zone_id][zone]
        if is_empty_or_nil(mapData) then mapData = {} end
        if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
        if ScrySpy_SavedVars.location_info[zone_id] == nil then ScrySpy_SavedVars.location_info[zone_id] = {} end
        if ScrySpy_SavedVars.location_info[zone_id][zone] == nil then ScrySpy_SavedVars.location_info[zone_id][zone] = {} end
        dig_sites_sv_table = get_digsite_loc_sv(zone_id, zone)
        if is_empty_or_nil(dig_sites_sv_table) then dig_sites_sv_table = {} end
        --d(dig_sites_sv_table)
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
    ScrySpy.worldControlPool = ZO_ControlPool:New("ScrySpy_WorldPin", ScrySpy_WorldPins, "ScrySpy_WorldPin")
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
	-- create the dig_site_pin
	-- we have one parent control (dig_site_pin) which we will move around the player
	-- and two child controls for the dig_site_pin's center and a periodically pulsing sphere
	dig_site_pin = WINDOW_MANAGER:CreateControl(nil, ScrySpy_WorldPins, CT_CONTROL)
	center = WINDOW_MANAGER:CreateControl(nil, dig_site_pin, CT_TEXTURE)
	frame = WINDOW_MANAGER:CreateControl(nil, dig_site_pin, CT_TEXTURE)

	-- make the control 3 dimensional
	dig_site_pin:Create3DRenderSpace()
	frame:Create3DRenderSpace()
	center:Create3DRenderSpace()

	-- set texture, size and enable the depth buffer so the dig_site_pin is hidden behind world objects
	center:SetTexture("ScrySpy/img/spade-icon.dds")
	center:Set3DLocalDimensions(0.5, 0.5)
	center:Set3DRenderSpaceUsesDepthBuffer(true)
	center:Set3DRenderSpaceOrigin(0,0,0.1)

	frame:SetTexture("ScrySpy/img/spade-icon.dds")
	frame:Set3DLocalDimensions(0.5, 0.5)
	frame:Set3DRenderSpaceOrigin(0,0,0)
	frame:Set3DRenderSpaceUsesDepthBuffer(true)

end
EVENT_MANAGER:RegisterForEvent(AddonName,EVENT_ADD_ON_LOADED,OnLoad)
