-- local cal = require("obsidiancalendar.calendar")
vim.api.nvim_create_user_command("Calendar", function(opts)
  require("obsidiancalendar.calendar"):toggle(opts.fargs[1])
end, { nargs = "?" })
