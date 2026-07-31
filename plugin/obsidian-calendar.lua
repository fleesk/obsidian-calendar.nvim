-- local cal = require("obsidiancalendar.calendar")
vim.api.nvim_create_user_command("Calendar", function(opts)
  if opts.fargs and opts.fargs[1] then
    require("obsidiancalendar.calendar"):open(opts.fargs[1])
  else
    require("obsidiancalendar.calendar"):toggle()
  end
end, { nargs = "?" })
