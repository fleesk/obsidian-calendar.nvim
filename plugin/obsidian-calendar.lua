vim.api.nvim_create_user_command("Calendar", function(opts)
  require("obsidian-calendar.calendar"):toggle(opts.fargs[1])
end, { nargs = "?" })
