local M = {}

local ONE_DAY = 86400

local txt = {
  "        July 2026      ",
  "   Mo Tu We Th Fr Sa Su",
  "13 29 30 1  2  3  4  5 ",
  "14 6  7  8  9  10 11 12",
  "15 13 14 15 16 17 18 19",
  "16 20 21 22 23 24 25 26",
  "17 27 28 29 30 31  1  2",
}

months = {
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
}

M.select = function()
  vim.notify(vim.inspect({ M.year, M.month, M.day }))
end

local get_calendarweek = function(day)
  local year = os.date("%Y", day)
  local jan_first = os.time({ year = year, month = 1, day = 1 })
  local wday = os.date("%w", jan_first)
  local first_sunday = wday == 0 and jan_first or jan_first + (7 - wday) * ONE_DAY
  if day <= first_sunday then
    -- we're in the first calendar week
    return 1
  end
  local diff = (day - first_sunday) / ONE_DAY
  local weekdiff = math.floor(diff / 7)
  -- sundays are in the previous week, other days in the next
  local calweek = os.date("%w", day) == 0 and 1 + weekdiff or 2 + weekdiff
  return calweek
end

M.draw_calendar = function()
  local first_of_month = os.time({ year = M.year, month = M.month, day = 1 })
  local tab = os.date("*t", first_of_month)
  -- zero-indexed weekday, 0 is monday
  local wday = tab.wday == 1 and 6 or tab.wday - 2
  -- first monday
  local current_day = first_of_month - wday * ONE_DAY

  local calendar_lines = {
    string.format("    %s %s   ", months[tab.month], tab.year),
    "   Mo Tu We Th Fr Sa Su",
  }
  local calendar_week = get_calendarweek(first_of_month)
  for _i = 1, 5 do
    local week = string.format("%d ", calendar_week)
    calendar_week = calendar_week + 1
    for _i = 1, 7 do
      local day = os.date("%d", current_day)
      week = week .. day .. " "
      current_day = current_day + ONE_DAY
    end
    table.insert(calendar_lines, week)
  end
  return calendar_lines
  -- return txt
end

M.refresh = function()
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, M.draw_calendar())
  vim.bo.modifiable = false
end

M.previous = function()
  if M.month == 1 then
    M.month = 12
    M.year = M.year - 1
  else
    M.month = M.month - 1
  end
  M.refresh()
end

M.next = function()
  if M.month == 12 then
    M.month = 1
    M.year = M.year + 1
  else
    M.month = M.month + 1
  end
  M.refresh()
end

--- open calendar in a side split
M.open = function()
  M.buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_open_win(M.buf, true, { split = "left", win = 0, vertical = true })
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, txt)
  vim.bo.modifiable = false
  local now = os.date("*t", os.time())
  M.year = now["year"]
  M.month = now["month"]
  M.day = now["day"]
  vim.keymap.set("n", "<CR>", M.select, { desc = "Select entry" })
  vim.keymap.set("n", "<C-P>", M.previous, { desc = "Previous" })
  vim.keymap.set("n", "<C-N>", M.next, { desc = "Next" })
end

vim.api.nvim_create_user_command("Calendar", M.open, {})
return M
