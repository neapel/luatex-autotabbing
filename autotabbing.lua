-- 
--  This is file `autotabbing.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  autotabbing.dtx  (with options: `lua')
--  
--  This is a generated file.
--  
--  Copyright (C) 2015 by Pascal Germroth <pascal@germroth.name>
--  
--  This file may be distributed and/or modified under the conditions of
--  the LaTeX Project Public License, either version 1.2 of this license
--  or (at your option) any later version.  The latest version of this
--  license is in:
--  
--     http://www.latex-project.org/lppl.txt
--  
--  and version 1.2 or later is part of all distributions of LaTeX version
--  1999/12/01 or later.
--  
local err, warn, info, log =
  luatexbase.provides_module({name = 'autotabbing'})
autotabbing = autotabbing or {}

local first_tab = 0
local last_tab = 1000
local function get_offsets(rows)
  local offsets = {[first_tab] = 0}
  local index = {}
  for i = 1, #rows do index[i] = 1 end
  local current = first_tab
  repeat
    for i, row in ipairs(rows) do
      local cell = row.cells[index[i]]
      if cell and cell.from == current then
        -- measure from our left edge to the left edge of the next cell
        local next_box = (row.cells[index[i] + 1] or {}).box
        local width = node.dimensions(cell.box, next_box)
        -- there may be content between cells.
        cell.right_margin = width - cell.box.width
        -- move our right tab stop accordingly
        local left = offsets[cell.from]
        local right = left + width
        if right >= (offsets[cell.to] or 0) then
          offsets[cell.to] = right
        end
        -- done with this cell
        index[i] = index[i] + 1
      end
    end
    -- find the next tab ID: it's the smallest,
    -- because tab IDs are topologically ordered.
    current = last_tab
    for i, row in ipairs(rows) do
      local cell = row.cells[index[i]]
      if cell and cell.from < current then
        current = cell.from
      end
    end
  until current == last_tab
  return offsets
end
local function repack_hbox(head, old, ...)
  local new = node.hpack(old.head, ...)
  head = node.insert_before(head, old, new)
  head = node.remove(head, old)
  return head, new
end
local function adjust_widths(head, rows, offsets)
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row.cells) do
      -- recreate the cell at target width
      local col_width = offsets[cell.to] - offsets[cell.from]
      local width = col_width - cell.right_margin
      row.box.head, cell.box =
        repack_hbox(row.box.head, cell.box, width, 'exactly')
    end
    -- recreate the row at its new natural width
    head, row.box = repack_hbox(head, row.box)
  end
  return head
end
local function collect_rows(table_box)
  local rows = {}
  for row_box in node.traverse(table_box.head) do
    -- skip glue, intertext, etc, without explicit row tag.
    if node.has_attribute(row_box, 0, 1) then
      local cells = {}
      for cell_box in node.traverse(row_box.head) do
        -- skip glue etc without explicit cell tag
        if node.has_attribute(cell_box, 0, 2) then
          local cell = {
            box = cell_box,
            from = node.has_attribute(cell_box, 1),
            to = last_tab
          }
          -- previous cell ends where this one starts
          local prev_cell = cells[#cells]
          if prev_cell then
            prev_cell.to = cell.from
          end
          -- cell done
          table.insert(cells, cell)
        end
      end
      -- row done
      table.insert(rows, {
        box = row_box,
        cells = cells
      })
    end
  end
  return rows
end
function autotabbing.adjust()
  local vbox = tex.box[0]
  local rows = collect_rows(vbox)
  local offsets = get_offsets(rows)
  vbox.head = adjust_widths(vbox.head, rows, offsets)
end
-- 
--  End of File `autotabbing.lua'.
