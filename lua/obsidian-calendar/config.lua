local M = {}

M.defaults = {
  start_sunday = false, -- start week on sunday instead of monday
}

M.config = M.defaults

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
