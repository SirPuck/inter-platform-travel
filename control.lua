local travel = require("__inter-platform-travel__.travel")

local panel_name = "ipt-travel-panel"

---@param root LuaGuiElement?
---@param name string
---@return LuaGuiElement?
local function find_gui_element(root, name)
    if not (root and root.valid) then return nil end
    if root.name == name then return root end

    for _, child in pairs(root.children) do
        local element = find_gui_element(child, name)
        if element then return element end
    end
end

---@param player LuaPlayer
local function close_travel_gui(player)
    local panel = player.gui.screen[panel_name]
    if panel and panel.valid then panel.destroy() end

end

---@param player LuaPlayer
---@return LuaEntity?
local function source_hub_for_player(player)
    local hub = player.hub
    if hub and hub.valid then return hub end
    return nil
end

---@param player LuaPlayer
local function open_travel_gui(player)
    close_travel_gui(player)

    local source_hub = source_hub_for_player(player)
    if not source_hub then
        player.print({"ipt-message.enter-hub-to-open"})
        return
    end

    local panel = player.gui.screen.add {
        type = "frame",
        name = panel_name,
        caption = "Inter-platform travel",
        direction = "vertical",
        style = "shallow_frame"
    }
    panel.auto_center = true

    local content = panel.add {
        type = "frame",
        name = "ipt-travel-content",
        direction = "vertical",
        style = "deep_frame_in_shallow_frame"
    }

    local destination_frame = content.add {
        type = "frame",
        name = "ipt-travel-destination-frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }
    local destination_flow = destination_frame.add {
        type = "flow",
        name = "ipt-travel-destination-flow",
        direction = "horizontal"
    }
    destination_flow.style.vertical_align = "center"
    destination_flow.add {
        type = "label",
        caption = "Destination"
    }
    local dropdown = destination_flow.add {
        type = "drop-down",
        name = "ipt-travel-destination-dropdown",
        items = {}
    }
    dropdown.style.minimal_width = 260

    local actions_frame = content.add {
        type = "frame",
        name = "ipt-travel-actions-frame",
        direction = "vertical",
        style = "inside_shallow_frame_with_padding"
    }
    local actions = actions_frame.add {
        type = "flow",
        name = "ipt-travel-actions",
        direction = "horizontal"
    }
    actions_frame.style.horizontally_stretchable = true
    actions.style.horizontally_stretchable = true
    actions.style.horizontal_align = "right"
    actions.add {
        type = "sprite-button",
        name = "ipt-travel-refresh-button",
        sprite = "virtual-signal/signal-recycle",
        tooltip = "Refresh destinations",
        style = "tool_button"
    }
    actions.add {
        type = "button",
        name = "ipt-travel-button",
        caption = "Travel"
    }

    travel.refresh_destinations(dropdown, actions["ipt-travel-button"], source_hub)
    player.opened = panel
end

---@param player LuaPlayer
local function refresh_player_gui(player)
    local panel = player.gui.screen[panel_name]
    if not (panel and panel.valid) then
        close_travel_gui(player)
        return
    end

    local dropdown = find_gui_element(panel, "ipt-travel-destination-dropdown")
    local travel_button = find_gui_element(panel, "ipt-travel-button")
    local source_hub = source_hub_for_player(player)
    if not (dropdown and travel_button and source_hub) then
        close_travel_gui(player)
        return
    end

    travel.refresh_destinations(dropdown, travel_button, source_hub)
end
---@param event EventData.CustomInput
local function on_open_travel_gui(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    open_travel_gui(player)
end

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    if event.element and event.element.valid and event.element.name == panel_name then
        local player = game.get_player(event.player_index)
        if player then close_travel_gui(player) end
    end
end

---@param event EventData.on_gui_click
local function on_gui_click(event)
    local player = game.get_player(event.player_index)
    if not player then return end

    local element = event.element
    if not (element and element.valid) then return end

    if element.name == "ipt-travel-refresh-button" then
        refresh_player_gui(player)
        return
    end

    if element.name ~= "ipt-travel-button" then return end

    local panel = player.gui.screen[panel_name]
    if not (panel and panel.valid) then return end

    local source_hub = source_hub_for_player(player)
    if not source_hub then
        player.print({"ipt-message.enter-hub-to-travel"})
        return
    end

    local dropdown = find_gui_element(panel, "ipt-travel-destination-dropdown")
    local destination_platform_index = travel.selected_destination_platform_index(dropdown)
    local destination_hub = travel.find_destination_hub(source_hub, destination_platform_index)
    if not destination_hub then
        player.print({"ipt-message.destination-unavailable"})
        return
    end

    close_travel_gui(player)
    travel.move_player(player, source_hub, destination_hub)
end

---@param event EventData.on_player_changed_surface
local function on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    if player then close_travel_gui(player) end
end

script.on_event("ipt-open-travel-gui", on_open_travel_gui)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_player_changed_surface, on_player_changed_surface)