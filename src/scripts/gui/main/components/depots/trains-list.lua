local train_row = require("scripts.gui.main.components.depots.train-row")

local component = {}

function component.init()
  return {
    active_sort = "composition",
    sort_composition = true,
    sort_status = true
  }
end

function component.update(state, msg, e)
  if msg.action == "update_sort" then
    local sort = msg.sort
    local depots_state = state.depots

    if depots_state.active_sort ~= sort then
      e.element.state = not e.element.state
    end

    depots_state.active_sort = sort
    depots_state["sort_"..sort] = e.element.state
  end
end

local function sort_checkbox(sort_name, depots_state, constants, caption)
  return {
    type = "checkbox",
    style = depots_state.active_sort == sort_name and "ltnm_selected_sort_checkbox" or "ltnm_sort_checkbox",
    width = constants[sort_name],
    caption = {"ltnm-gui."..(caption or sort_name)},
    tooltip = {"ltnm-gui."..(caption or sort_name).."-tooltip"},
    state = depots_state["sort_"..sort_name],
    on_click = {comp = "trains_list", action = "update_sort", sort = sort_name},
  }
end

local function generate_train_rows(state, depots_state, depot_data)
  local trains = state.ltn_data.trains

  -- get train IDs based on active sort
  local active_sort = depots_state.active_sort
  local train_ids
  if active_sort == "composition" then
    train_ids = depot_data.sorted_trains.composition
  else
    train_ids = depot_data.sorted_trains.status[state.player_index]
  end
  local active_sort_state = depots_state["sort_"..depots_state.active_sort]

  -- search
  local search_state = state.search
  local search_query = search_state.query
  local search_surface = search_state.surface

  -- iteration data
  local start = active_sort_state and 1 or #train_ids
  local finish = active_sort_state and #train_ids or 1
  local step = active_sort_state and 1 or -1

  -- build train rows
  local train_rows = {}
  local index = 0
  for i = start, finish, step do
    local train_id = train_ids[i]
    local train_data = trains[train_id]
    local train_status = train_data.status[state.player_index]
    local search_comparator = active_sort == "composition" and train_data.composition or train_status.string

    -- test against search queries
    if
      string.find(string.lower(search_comparator), search_query)
      and (search_surface == -1 or train_data.main_locomotive.surface.index == search_surface)
    then
      index = index + 1
      train_rows[index] = train_row.view(state, train_id, train_data, train_status)
    end
  end

  return train_rows
end

function component.view(state)
  local constants = state.constants.trains_list
  local depots_state = state.depots

  local depot_data = state.ltn_data.depots[depots_state.selected_depot]

  local train_rows

  if depot_data then
    train_rows = generate_train_rows(state, depots_state, depot_data)
  end

  return (
    {
      type = "frame",
      style = "deep_frame_in_shallow_frame",
      direction = "vertical",
      children = {
        {type = "frame", style = "ltnm_table_toolbar_frame", children = {
          sort_checkbox("composition", depots_state, constants),
          sort_checkbox("status", depots_state, constants, "train-status"),
          -- TODO make train contents sortable and searchable
          {
            type = "label",
            style = "caption_label",
            width = constants.shipment,
            caption = {"ltnm-gui.shipment"},
            tooltip = {"ltnm-gui.shipment-tooltip"},
          }
        }},
        {type = "scroll-pane", style = "ltnm_table_scroll_pane", children = train_rows}
      }
    }
  )
end

return component