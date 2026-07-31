## A calendar for obsidian.nvim

This is a neovim plugin that adds a simple calendar window which can be used to open daily notes with [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim).

- Toggle calendar window with `:Calendar`
- Open to a specific year+month with `:Calendar [YY]YY-MM`.
- Move to previous/next month with `<C-p>/<C-n>`
- Open the daily note for the day under the cursor with `<CR>`. Requires `obsidian.nvim` installed

![Calendar buffer](calendar.png)

Does not currently offer many configuration options, and does not consistently respect the user's locale.

### Installation

- with `vim.pack`:
  ```lua
  vim.pack.add({ "https://github.com/fleesk/obsidian-calendar.nvim" })
  ```
- with `lazy.nvim`:
  ```lua
  {
    'fleesk/obsidian-calendar.nvim',
  }
  ```

No `setup()` call required if you don't want to change the default config

### Configuration

pass options that differ from the following defaults to `require("obsidian-calendar").setup()`:

```lua
require("obsidian-calendar").setup({
  start_sunday = false -- start week on sunday instead of monday
})
```
