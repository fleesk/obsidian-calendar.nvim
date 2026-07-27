-- local cal = require("obsidiancalendar.calendar")
vim.api.nvim_create_user_command("Calendar", function()
  require("obsidiancalendar.calendar").open()
end, {})
