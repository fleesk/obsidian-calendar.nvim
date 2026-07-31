local M = {}

local defaults = {
  start_sunday = false, -- start week on sunday instead of monday
}

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", defaults, opts)
end

return M
