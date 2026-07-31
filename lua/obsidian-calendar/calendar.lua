local M = {}

local config = require("obsidian-calendar.config").config
local ONE_DAY = 86400

local DAYS_IN_MONTH = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

--- open obsidian daily note for the given day in another window
function M:open_daily()
  local pos = vim.api.nvim_win_get_cursor(self.win)
  local month = self.month
  local year = self.year
  if pos[1] < 3 or pos[2] < 3 or (pos[2] - 2) % 3 == 0 then
    return
  end
  local selected = tonumber(vim.fn.expand("<cword>"))
  -- days in previous/next month
  if pos[1] == 3 and selected > 7 then
    month = self.month == 1 and 12 or self.month - 1
    if month == 12 then
      year = year - 1
    end
  elseif pos[1] > 6 and selected < 23 then
    month = self.month == 12 and 1 or self.month + 1
    if month == 1 then
      year = year + 1
    end
  end
  vim.cmd.wincmd("h")
  vim.cmd(string.format("Obsidian today %d-%d-%d", year, month, selected))
end

--- return the table of lines that make up the calendar view
function M:draw_calendar()
  local first_date = os.date("*t", self.first_of_month)

  local month_name = os.date("%B", self.first_of_month)
  local spacing = string.rep(" ", math.ceil((23 - (string.len(month_name) + 5)) / 2))
  local weekdays = config.start_sunday and "   Su Mo Tu We Th Fr Sa" or "   Mo Tu We Th Fr Sa Su"
  local calendar_lines = {
    string.format("%s%s %s", spacing, month_name, self.year),
    weekdays,
  }

  -- zero-indexed weekday = position in calendar matrix
  if config.start_sunday then
    self.month_start = first_date.wday - 1 -- 0 is sunday
  else
    self.month_start = first_date.wday == 1 and 6 or first_date.wday - 2 -- 0 is monday
  end
  self.month_end = self.month_start + DAYS_IN_MONTH[self.month] - 1
  if self.is_leap_feb then
    self.month_end = self.month_end + 1
  end

  -- start at first monday/sunday
  local current_day = self.first_of_month - self.month_start * ONE_DAY

  local calendar_week = os.date("%W", self.first_of_month) + 1

  for _ = 0, 5 do -- weeks
    local week = string.format("%2d ", calendar_week)
    calendar_week = calendar_week + 1
    for i = 0, 6 do -- days
      local day = os.date("%d", current_day)
      week = i == 6 and week .. day or week .. day .. " "
      current_day = current_day + ONE_DAY
    end
    table.insert(calendar_lines, week)
  end
  return calendar_lines
end

--- set up highlight groups
function M:set_highlights()
  vim.fn.clearmatches(self.win)
  vim.api.nvim_win_set_hl_ns(self.win, self.ns_id)
  vim.fn.matchaddpos("CalendarWeek", { { 3, 1, 2 }, { 4, 1, 2 }, { 5, 1, 2 }, { 6, 1, 2 }, { 7, 1, 2 }, { 8, 1, 2 } })

  local last_wday = self.month_end % 7 -- 0 is sunday

  -- length of a match that highlights all days in one week
  local full_line_len = 21
  -- first line
  if self.month_start ~= 0 then
    vim.fn.matchaddpos("AdjacentMonthDay", { { 3, 4, 3 * self.month_start } })
  end

  -- final two lines
  if self.month_end > 34 then -- last day on last line
    vim.fn.matchaddpos("AdjacentMonthDay", { { 8, 7 + 3 * last_wday, full_line_len - (3 * last_wday) } })
  else
    vim.fn.matchaddpos("AdjacentMonthDay", { { 8, 4, full_line_len } })
    if self.month_end > 27 then -- second to last line
      vim.fn.matchaddpos("AdjacentMonthDay", { { 7, 7 + 3 * last_wday, full_line_len - 3 * last_wday } })
    else
      vim.fn.matchaddpos("AdjacentMonthDay", { { 7, 4, full_line_len } })
    end
  end

  local augroup = vim.api.nvim_create_augroup("ObsidianCalendar", { clear = true })
  -- clear hls on buffer switch
  vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function()
      if vim.api.nvim_get_current_win() == self.win then
        vim.fn.clearmatches(self.win)
      end
    end,
    group = augroup,
  })
end

--- update calendar view
function M:refresh()
  self.first_of_month = os.time({ year = self.year, month = self.month, day = 1 })
  self.is_leap_feb = self.year % 4 == 0 and self.month == 2
  local days_in_month = DAYS_IN_MONTH[self.month] -- leap year
  if self.is_leap_feb then
    days_in_month = days_in_month + 1
  end
  self.last_of_month = os.time({ year = self.year, month = self.month, day = days_in_month })
  vim.bo.modifiable = true
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, self:draw_calendar())
  self:set_highlights()
  vim.bo.modifiable = false
end

--- move calendar to previous month
function M:previous()
  if self.month == 1 then
    self.month = 12
    self.year = self.year - 1
  else
    self.month = self.month - 1
  end
  self:refresh()
end

--- move calendar to next month
function M:next()
  if self.month == 12 then
    self.month = 1
    self.year = self.year + 1
  else
    self.month = self.month + 1
  end
  self:refresh()
end

--- set up keymaps for the calendar buffer
function M:set_keymaps()
  vim.keymap.set("n", "<CR>", function()
    self:open_daily()
  end, { desc = "Select entry", buf = self.buf })
  vim.keymap.set("n", "<C-P>", function()
    self:previous()
  end, { desc = "Previous", buf = self.buf })
  vim.keymap.set("n", "<C-N>", function()
    self:next()
  end, { desc = "Next", buf = self.buf })
end

--- open calendar in a side split to the given date
function M:open_cal_win(date)
  date = date or os.time()
  self.buf = vim.api.nvim_create_buf(false, false)
  self.win = vim.api.nvim_open_win(self.buf, true, { split = "right", win = 0, vertical = true })
  vim.api.nvim_win_set_width(self.win, 32)

  self.ns_id = self.ns_id or vim.api.nvim_create_namespace("ObsidianCalendar")
  vim.api.nvim_set_hl(self.ns_id, "AdjacentMonthDay", {
    fg = "#737A94", -- foreground color
  })
  vim.api.nvim_set_hl(self.ns_id, "CalendarWeek", {
    fg = "#9C9DCC", -- foreground color
  })

  M:set_keymaps()
  self:refresh()
end

--- expects YY[YY]-M[M], returns first of that month
function parse_date(datestr)
  local year, month = datestr:match("(%d+)%-(%d+)")
  year = tonumber(year)
  month = tonumber(month)
  if year < 100 then
    year = 2000 + year
  end
  return os.time({ year = year, month = month, day = 1 })
end

function M:open(datestr)
  local date = datestr and parse_date(datestr) or os.time()
  local now = os.date("*t", date)
  self.year = now["year"]
  self.month = now["month"]
  M:open_cal_win(date)
end

--- toggle calendar window
function M:toggle(datestr)
  if
    self.win
    and self.buf
    and vim.api.nvim_win_is_valid(self.win)
    and vim.api.nvim_win_get_buf(self.win) == self.buf
  then
    if datestr then
      vim.api.nvim_set_current_win(self.win)
      local now = os.date("*t", parse_date(datestr))
      self.year = now["year"]
      self.month = now["month"]
      self:refresh()
    else
      vim.api.nvim_win_close(self.win, false)
    end
  else
    M:open(datestr)
  end
end

return M
