local travel = {}

---@param platform LuaSpacePlatform
---@return string
local function platform_caption(platform)
    return platform.name or (platform.surface and platform.surface.name) or ""
end

---@param platform_a LuaSpacePlatform
---@param platform_b LuaSpacePlatform
---@return boolean
local function space_location_is_shared(platform_a, platform_b)
    return (platform_a.space_location and platform_a.space_location.name) == (platform_b.space_location and platform_b.space_location.name)
end

--- Gets the platforms at the same space location as the source hub.
---@param source_hub LuaEntity The platform hub to travel from.
---@return LuaSpacePlatform[] destinations Platforms available as travel destinations.
function travel.available_destinations(source_hub)
    local source_platform = source_hub.surface and source_hub.surface.platform
    local source_index = source_platform.index
    local space_location = source_platform and source_platform.space_location
    if not space_location then return {} end

    local planet = game.planets[space_location.name]

    local available_platforms = {}
    if planet then
        for _, platform in pairs(planet.get_space_platforms(source_hub.force)) do
            if source_index ~= platform.index then
                table.insert(available_platforms, platform)
            end
        end
    else
        for _, platform in pairs(source_hub.force.platforms) do
            if source_index ~= platform.index then
                if platform and platform.space_location and platform.space_location.name == space_location.name then
                    table.insert(available_platforms, platform)
                end
            end
        end
    end

    return available_platforms
end


--- Sends the player from one platform hub to another with a cargo pod.
---@param player LuaPlayer The player to put in the travel pod.
---@param source_hub LuaEntity The hub creating the cargo pod.
---@param destination_hub LuaEntity The destination platform hub.
function travel.move_player(player, source_hub, destination_hub)
    local pod = source_hub.create_cargo_pod()
    if not (pod and pod.valid) then return end
    player.teleport({0,0}, source_hub.surface)
    pod.cargo_pod_destination = {
        type = defines.cargo_destination.station,
        station = destination_hub,
        surface = destination_hub.surface
    }
    pod.set_passenger(player)
end

--- Refreshes the travel panel destination dropdown.
---@param dropdown LuaGuiElement
---@param travel_button LuaGuiElement?
---@param source_hub LuaEntity
function travel.refresh_destinations(dropdown, travel_button, source_hub)
    if not (dropdown and dropdown.valid and source_hub and source_hub.valid) then return end

    local destination_platform_indices = {}
    dropdown.clear_items()

    for _, platform in pairs(travel.available_destinations(source_hub)) do
        table.insert(destination_platform_indices, platform.index)
        dropdown.add_item(platform_caption(platform))
    end

    dropdown.tags = { destination_platform_indices = destination_platform_indices }
    dropdown.selected_index = #destination_platform_indices > 0 and 1 or 0
    dropdown.enabled = #destination_platform_indices > 0

    if travel_button and travel_button.valid then
        travel_button.enabled = #destination_platform_indices > 0
    end
end
---@param dropdown LuaGuiElement
---@return uint?
function travel.selected_destination_platform_index(dropdown)
    if not (dropdown and dropdown.valid and dropdown.selected_index and dropdown.selected_index > 0) then return nil end

    local tags = dropdown.tags or {}
    local destination_platform_indices = tags.destination_platform_indices or {}
    return destination_platform_indices[dropdown.selected_index]
end
---@param source_hub LuaEntity
---@param destination_platform_index uint?
---@return LuaEntity?
function travel.find_destination_hub(source_hub, destination_platform_index)
    if not (source_hub and source_hub.valid and destination_platform_index) then return nil end

    for _, platform in pairs(source_hub.force.platforms) do
        local hub = platform and platform.hub
        if platform.index == destination_platform_index and hub and hub.valid then
            return hub
        end
    end

    return nil
end

return travel
